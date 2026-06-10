# W9 Day 3 — Progressive Delivery: Canary + Argo Rollouts

## 1. Progressive Delivery là gì?

Thay vì deploy toàn bộ traffic sang version mới ngay lập tức, Progressive Delivery
đưa traffic dần dần và **tự động abort nếu metric xấu**.

```
Version cũ (stable)  ──────────────────────────────► 100% traffic
                                    │
                             Canary deploy
                                    │
Version mới (canary) ──► 10% → 20% → 50% → 100%
                              ↓ nếu error rate tăng
                           AUTO ABORT → rollback về stable
```

### So sánh các strategy
| Strategy | Mô tả | Downtime | Risk |
|---|---|---|---|
| Recreate | Xóa old → tạo new | Có | Cao |
| RollingUpdate | Thay dần pod | Không | Trung bình |
| Blue/Green | 2 env song song, switch traffic | Không | Thấp |
| Canary | Tăng traffic dần, auto-abort | Không | Rất thấp |

---

## 2. Argo Rollouts

Argo Rollouts mở rộng K8s Deployment với các strategy nâng cao: Canary, Blue/Green.

### Cài Argo Rollouts lên minikube
```bash
kubectl create namespace argo-rollouts
kubectl apply -n argo-rollouts \
  -f https://github.com/argoproj/argo-rollouts/releases/latest/download/install.yaml

# Cài kubectl plugin
# Windows: tải tại https://github.com/argoproj/argo-rollouts/releases
# Lưu vào D:\minikube\kubectl-argo-rollouts.exe

# Verify
kubectl argo rollouts version
```

### Rollout CRD — thay thế Deployment
```yaml
# rollout/web-rollout.yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: web-rollout
spec:
  replicas: 5
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
    spec:
      containers:
        - name: web
          image: nginx:1.25-alpine   # đổi image để trigger canary
          ports:
            - containerPort: 80
          resources:
            requests:
              memory: "64Mi"
              cpu: "100m"
            limits:
              memory: "128Mi"
              cpu: "200m"

  strategy:
    canary:
      # Service riêng cho stable và canary
      stableService: web-stable-svc
      canaryService: web-canary-svc

      # Tăng traffic dần và chạy analysis
      steps:
        - setWeight: 10          # 10% traffic → canary
        - pause: {duration: 2m}  # đợi 2 phút, thu thập metric
        - analysis:
            templates:
              - templateName: success-rate-analysis
        - setWeight: 30
        - pause: {duration: 2m}
        - analysis:
            templates:
              - templateName: success-rate-analysis
        - setWeight: 50
        - pause: {duration: 5m}
        - analysis:
            templates:
              - templateName: success-rate-analysis
        # Nếu tất cả analysis pass → tự động promote 100%

---

## 3. AnalysisTemplate — định nghĩa abort criteria

AnalysisTemplate là CRD định nghĩa **điều kiện để Rollout pass hoặc fail**.

```yaml
# rollout/analysis-template.yaml
apiVersion: argoproj.io/v1alpha1
kind: AnalysisTemplate
metadata:
  name: success-rate-analysis
spec:
  args:
    - name: service-name   # truyền vào từ Rollout

  metrics:
    # Metric 1: Success rate phải >= 95%
    - name: success-rate
      interval: 1m
      count: 5             # chạy 5 lần
      successCondition: result[0] >= 0.95
      failureLimit: 2      # fail 2 lần liên tiếp → abort
      provider:
        prometheus:
          address: http://monitoring-kube-prometheus-prometheus.monitoring:9090
          query: |
            sum(rate(http_requests_total{
              service="{{args.service-name}}",
              status!~"5.."
            }[2m]))
            /
            sum(rate(http_requests_total{
              service="{{args.service-name}}"
            }[2m]))

    # Metric 2: P99 latency phải < 500ms
    - name: latency-p99
      interval: 1m
      count: 5
      successCondition: result[0] < 0.5
      failureLimit: 2
      provider:
        prometheus:
          address: http://monitoring-kube-prometheus-prometheus.monitoring:9090
          query: |
            histogram_quantile(0.99,
              sum(rate(http_request_duration_seconds_bucket{
                service="{{args.service-name}}"
              }[2m])) by (le)
            )
```

---

## 4. Tích hợp Burn Rate vào Abort Criteria

Kết hợp SLO burn rate từ Day 2 vào AnalysisTemplate để auto-abort khi burn rate cao:

```yaml
# rollout/analysis-burn-rate.yaml
apiVersion: argoproj.io/v1alpha1
kind: AnalysisTemplate
metadata:
  name: burn-rate-analysis
spec:
  metrics:
    # Abort nếu burn rate > 14.4x (error budget cạn trong 2h)
    - name: error-budget-burn-rate
      interval: 1m
      count: 3
      # pass = burn rate thấp (< 14.4x SLO threshold)
      successCondition: result[0] < (14.4 * 0.001)
      failureLimit: 1   # chỉ cần fail 1 lần → abort ngay
      provider:
        prometheus:
          address: http://monitoring-kube-prometheus-prometheus.monitoring:9090
          query: |
            sum(rate(http_requests_total{status=~"5.."}[1h]))
            /
            sum(rate(http_requests_total[1h]))
```

---

## 5. Service cho Canary (stable + canary routing)

```yaml
# rollout/services.yaml
# Stable service — nhận 100% traffic bình thường
apiVersion: v1
kind: Service
metadata:
  name: web-stable-svc
spec:
  selector:
    app: web
  ports:
    - port: 80
      targetPort: 80
---
# Canary service — nhận % traffic được set trong Rollout steps
apiVersion: v1
kind: Service
metadata:
  name: web-canary-svc
spec:
  selector:
    app: web
  ports:
    - port: 80
      targetPort: 80
```

---

## 6. Workflow thực tế

```bash
# 1. Cài Argo Rollouts
kubectl create namespace argo-rollouts
kubectl apply -n argo-rollouts \
  -f https://github.com/argoproj/argo-rollouts/releases/latest/download/install.yaml

# 2. Apply services + rollout + analysis templates
kubectl apply -f rollout/services.yaml
kubectl apply -f rollout/analysis-template.yaml
kubectl apply -f rollout/analysis-burn-rate.yaml
kubectl apply -f rollout/web-rollout.yaml

# 3. Xem trạng thái rollout
kubectl argo rollouts get rollout web-rollout --watch

# 4. Trigger canary bằng cách đổi image
kubectl argo rollouts set image web-rollout web=nginx:1.26-alpine

# 5. Theo dõi
kubectl argo rollouts get rollout web-rollout

# 6. Manual promote (nếu muốn skip pause)
kubectl argo rollouts promote web-rollout

# 7. Manual abort
kubectl argo rollouts abort web-rollout

# 8. Rollback về stable
kubectl argo rollouts undo web-rollout
```

---

## 7. Abort Criteria Flow

```
Deploy canary (10%)
      ↓
AnalysisRun chạy Prometheus query mỗi 1 phút
      ↓
   success rate >= 95%?
   ├── YES → tiếp tục tăng weight
   └── NO (fail 2 lần) → AUTO ABORT
              ↓
         Traffic về 100% stable
         AnalysisRun = Failed
         Rollout status = Degraded
```

---

## Câu hỏi tự kiểm tra

1. Khác nhau giữa `pause: {}` (vô thời hạn) và `pause: {duration: 2m}`?
2. `failureLimit: 2` trong AnalysisTemplate nghĩa là gì?
3. Khi Rollout auto-abort, traffic đi đâu?
4. Tại sao cần 2 service (stable + canary) thay vì 1?
5. AnalysisRun khác AnalysisTemplate ở điểm nào?
