# W10 Day 3 — Platform Integration + Runbook + Cost Guard

## Mục tiêu

Ghép toàn bộ stack W8→W10 thành 1 platform hoàn chỉnh:
- ResourceQuota + LimitRange — ngăn tenant "ăn" hết tài nguyên cluster
- Chaos test — chứng minh hệ thống tự hồi phục
- Runbook template — khi incident xảy ra, ai cũng biết làm gì
- AWS Cost Anomaly Detection — cảnh báo chi phí bất thường

---

## 1. ResourceQuota + LimitRange

### Vấn đề không có quota

Một namespace deploy quá nhiều → ăn hết CPU/RAM → namespace khác bị throttle hoặc pod pending. Không có giới hạn = "noisy neighbor problem".

### ResourceQuota — giới hạn tổng cả namespace

```yaml
# quota/resourcequota-demo.yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: demo-quota
  namespace: demo
spec:
  hard:
    # Compute
    requests.cpu: "2"          # tổng request CPU tất cả pods
    requests.memory: 2Gi
    limits.cpu: "4"
    limits.memory: 4Gi
    # Object count
    pods: "20"
    services: "10"
    persistentvolumeclaims: "5"
```

### LimitRange — giới hạn mặc định từng container

```yaml
# quota/limitrange-demo.yaml
apiVersion: v1
kind: LimitRange
metadata:
  name: demo-limits
  namespace: demo
spec:
  limits:
    - type: Container
      default:          # nếu không khai báo limits thì dùng giá trị này
        cpu: "500m"
        memory: 256Mi
      defaultRequest:   # nếu không khai báo requests thì dùng giá trị này
        cpu: "100m"
        memory: 128Mi
      max:              # không được vượt quá
        cpu: "2"
        memory: 1Gi
      min:              # không được thấp hơn
        cpu: "50m"
        memory: 64Mi
```

**Tại sao cần cả 2?** ResourceQuota chặn tổng. LimitRange đảm bảo từng container phải khai báo đúng → không có container "vô hạn".

---

## 2. Platform Bootstrap — Deploy Full Stack < 2h

Mục tiêu cuối W10: fresh cluster → full platform trong < 2 giờ từ repo.

### Thứ tự deploy

```
1. ArgoCD (kubectl apply 1 lần)
   └── root app → tự tạo tất cả:
       ├── namespace + quota + limitrange
       ├── kube-prometheus-stack
       ├── argo-rollouts
       ├── gatekeeper (OPA)
       ├── external-secrets-operator
       └── api (Rollout + monitoring)
```

### Checklist verify sau bootstrap

```bash
# 1. ArgoCD apps
kubectl -n argocd get applications

# 2. 3 role RBAC
kubectl get role -n demo

# 3. 4 Gatekeeper constraints
kubectl get constraints

# 4. ESO rotate < 60s
kubectl get externalsecret -n demo

# 5. Admission reject unsigned image
kubectl run test --image=nginx:latest -n demo   # bị reject

# 6. Canary pipeline hoạt động
# push commit → ArgoCD sync → Rollout → AnalysisRun pass
```

---

## 3. Chaos Test

### Tại sao cần chaos test

Hệ thống "hoạt động tốt khi không có gì xảy ra" không đủ. Cần chứng minh tự hồi phục khi:
- Pod bị kill đột ngột
- Node mất kết nối
- Secret bị xóa

### Test đơn giản với kubectl

```bash
# Kill random pod — ReplicaSet có tự tạo lại không?
kubectl delete pod -l app=api -n demo --force

# Verify: pod mới được tạo trong < 30s
kubectl get pods -n demo -w

# Kill nhiều pod cùng lúc
kubectl delete pods -l app=api -n demo --all

# Test ESO: xóa K8s Secret — ESO có tạo lại không?
kubectl delete secret api-db-secret -n demo
# ESO phát hiện trong refreshInterval và recreate
```

### Kết quả kỳ vọng

| Test | Hành vi kỳ vọng | SLO ảnh hưởng |
|---|---|---|
| Kill 1 pod | ReplicaSet tạo lại trong < 30s | Không đáng kể |
| Kill tất cả pods | Rollout recover, canary không bị stuck | < 1 phút downtime |
| Xóa Secret | ESO recreate trong refreshInterval (30s) | Không restart pod |

---

## 4. Runbook Template

### Khi nào dùng runbook

Incident xảy ra lúc 3h sáng, người on-call không quen hệ thống → runbook = hướng dẫn từng bước, không cần chuyên gia.

Xem file: `runbooks/api-high-error-rate.md`

---

## 5. AWS Cost Anomaly Detection

### Setup

```
AWS Console → Cost Management → Cost Anomaly Detection
  → Create monitor: Service monitor (theo AWS service)
  → Create alert: threshold $10 hoặc 20% tăng bất thường
  → Notify: SNS → Email
```

### Tại sao quan trọng

Cluster Kubernetes trên EKS + load test không tắt = EC2/EKS cost tăng đột biến. Cost Anomaly Detection phát hiện trong vài giờ thay vì cuối tháng mới biết.

### Kết hợp với ResourceQuota

ResourceQuota giới hạn tài nguyên trong cluster → ngăn pod vô tình scale vô hạn → trực tiếp kiểm soát chi phí.

---

## 6. Tích hợp toàn stack W8 → W10

```
W8 — Foundation
  Terraform → EKS cluster + VPC + IAM
  Kubernetes cơ bản: Pod/Deployment/Service

W9 — Delivery
  GitOps (ArgoCD) + CI/CD
  Observability (Prometheus/Grafana/Alertmanager)
  Canary auto-abort (Argo Rollouts + AnalysisTemplate)

W10 — Secure & Operate
  RBAC: 3 role developer/sre/viewer
  Admission: Gatekeeper 4 constraints
  Secrets: ESO rotate < 60s
  Supply chain: Trivy scan + Cosign sign + Kyverno verify
  Platform: ResourceQuota + LimitRange + Runbook + Cost Guard
```

**Mini platform end-to-end** = tất cả 3 tuần chạy cùng nhau trên 1 cluster.
