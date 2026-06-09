# W9 Day 2 — Observability: SLO/SLI/OTel

## 1. Observability là gì?

Observability = khả năng hiểu **trạng thái bên trong** hệ thống từ **output bên ngoài**.

3 trụ cột (Three Pillars):
```
Metrics   — SỐ LIỆU: CPU 80%, latency p99 = 200ms, error rate 0.1%
Logs      — SỰ KIỆN: "ERROR: DB connection refused at 14:32:01"
Traces    — LUỒNG: request đi qua service A → B → C mất bao lâu mỗi bước
```

---

## 2. SLI / SLO / SLA / Error Budget

### Định nghĩa
| Khái niệm | Là gì | Ví dụ |
|---|---|---|
| **SLI** (Service Level Indicator) | Metric đo thực tế | Availability = 99.95% trong 30 ngày |
| **SLO** (Service Level Objective) | Mục tiêu đặt ra | Availability ≥ 99.9% |
| **SLA** (Service Level Agreement) | Cam kết pháp lý với khách hàng | Nếu < 99.5% → hoàn tiền |
| **Error Budget** | Lượng lỗi được phép | 100% - 99.9% = 0.1% = 43.8 phút/tháng |

### Các SLI phổ biến
```
Availability  = good_requests / total_requests × 100%
Latency       = % requests hoàn thành trong threshold (VD: < 200ms)
Error rate    = error_requests / total_requests × 100%
Throughput    = requests per second
```

### Error Budget
```
SLO = 99.9%  →  Error Budget = 0.1%/tháng = 43.8 phút downtime cho phép

Nếu đã dùng hết error budget → STOP deploy, tập trung fix reliability
Nếu còn nhiều budget → thoải mái deploy feature mới
```

---

## 3. OpenTelemetry (OTel)

OTel = chuẩn mở để thu thập Metrics + Logs + Traces từ ứng dụng.

### Kiến trúc OTel
```
[App với OTel SDK]
       │  gửi telemetry (OTLP)
       ▼
[OTel Collector]  ←── nhận, xử lý, route
       │
       ├──► Prometheus (metrics)
       ├──► Loki (logs)
       └──► Jaeger/Tempo (traces)
```

### OTel Collector config
```yaml
# otel/collector-config.yaml
receivers:
  otlp:
    protocols:
      grpc:
        endpoint: 0.0.0.0:4317
      http:
        endpoint: 0.0.0.0:4318

processors:
  batch:
    timeout: 1s
    send_batch_size: 1024
  memory_limiter:
    limit_mib: 400

exporters:
  prometheus:
    endpoint: "0.0.0.0:8889"
  loki:
    endpoint: http://loki:3100/loki/api/v1/push
  otlp/jaeger:
    endpoint: jaeger:4317
    tls:
      insecure: true

service:
  pipelines:
    metrics:
      receivers: [otlp]
      processors: [memory_limiter, batch]
      exporters: [prometheus]
    logs:
      receivers: [otlp]
      processors: [memory_limiter, batch]
      exporters: [loki]
    traces:
      receivers: [otlp]
      processors: [memory_limiter, batch]
      exporters: [otlp/jaeger]
```

---

## 4. Prometheus + Grafana + Loki Stack

### Deploy lên minikube bằng Helm
```bash
# Thêm helm repos
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# Cài kube-prometheus-stack (Prometheus + Grafana + AlertManager)
helm install monitoring prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --values prometheus/values.yaml

# Cài Loki + Promtail
helm install loki grafana/loki-stack \
  --namespace monitoring \
  --set promtail.enabled=true

# Port-forward Grafana
kubectl port-forward -n monitoring svc/monitoring-grafana 3000:80
# user: admin / password: prom-operator
```

### Prometheus query SLO
```promql
# Availability SLI — % request thành công trong 5 phút
sum(rate(http_requests_total{status!~"5.."}[5m]))
/
sum(rate(http_requests_total[5m]))

# Latency SLI — % request hoàn thành dưới 200ms
sum(rate(http_request_duration_seconds_bucket{le="0.2"}[5m]))
/
sum(rate(http_request_duration_seconds_count[5m]))

# Error rate
sum(rate(http_requests_total{status=~"5.."}[5m]))
/
sum(rate(http_requests_total[5m]))
```

---

## 5. Multi-Window Burn Rate Alert

### Burn Rate là gì?
Tốc độ tiêu thụ Error Budget. Burn rate = 1 nghĩa là tiêu đúng budget, = 2 nghĩa là tiêu gấp đôi.

```
Nếu SLO = 99.9%  →  error budget = 0.1%/tháng (43.8 phút)
Burn rate = 1     →  hết budget sau đúng 1 tháng
Burn rate = 14.4  →  hết budget sau 2 giờ  ← ALERT ngay!
```

### Multi-window Alert (Google SRE pattern)

Dùng 2 cửa sổ thời gian để tránh false positive:
- **Fast window** (1h): phát hiện sự cố nhanh
- **Slow window** (5min): xác nhận sự cố thực sự đang xảy ra

```yaml
# alert-rules/slo-alerts.yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: slo-burn-rate-alerts
  namespace: monitoring
spec:
  groups:
    - name: slo.rules
      rules:
        # Fast burn — phát hiện nhanh (cảnh báo nghiêm trọng)
        - alert: HighErrorBudgetBurnRate
          expr: |
            (
              sum(rate(http_requests_total{status=~"5.."}[1h]))
              /
              sum(rate(http_requests_total[1h]))
            ) > (14.4 * 0.001)
            and
            (
              sum(rate(http_requests_total{status=~"5.."}[5m]))
              /
              sum(rate(http_requests_total[5m]))
            ) > (14.4 * 0.001)
          for: 2m
          labels:
            severity: critical
          annotations:
            summary: "High error budget burn rate — check immediately"
            description: "Burn rate > 14.4x. Error budget will be exhausted in < 2 hours."

        # Slow burn — phát hiện vấn đề âm ỉ
        - alert: MediumErrorBudgetBurnRate
          expr: |
            (
              sum(rate(http_requests_total{status=~"5.."}[6h]))
              /
              sum(rate(http_requests_total[6h]))
            ) > (6 * 0.001)
            and
            (
              sum(rate(http_requests_total{status=~"5.."}[30m]))
              /
              sum(rate(http_requests_total[30m]))
            ) > (6 * 0.001)
          for: 15m
          labels:
            severity: warning
          annotations:
            summary: "Medium error budget burn rate"
            description: "Burn rate > 6x over 6h window."
```

---

## 6. Deploy Observability Stack lên minikube

```bash
# 1. Tạo namespace
kubectl create namespace monitoring

# 2. Apply OTel Collector
kubectl apply -f otel/collector-config.yaml -n monitoring
kubectl apply -f otel/collector-deployment.yaml -n monitoring

# 3. Cài Prometheus stack
helm install monitoring prometheus-community/kube-prometheus-stack \
  -n monitoring -f prometheus/values.yaml

# 4. Apply SLO alert rules
kubectl apply -f alert-rules/slo-alerts.yaml

# 5. Verify
kubectl get pods -n monitoring
kubectl get prometheusrule -n monitoring
```



