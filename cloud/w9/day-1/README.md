# W9 Day 1 — GitOps & CI/CD

## 1. GitOps là gì?

GitOps = dùng **Git làm source of truth** cho toàn bộ hạ tầng và ứng dụng.

```
Developer push code
      ↓
Git repo (desired state)
      ↓
GitOps agent (ArgoCD/Flux) phát hiện thay đổi
      ↓
Tự động sync xuống cluster (actual state)
```

### 4 nguyên tắc GitOps (OpenGitOps)
1. **Declarative** — toàn bộ system được mô tả bằng code
2. **Versioned & Immutable** — mọi thay đổi qua Git, có history
3. **Pulled Automatically** — agent tự pull từ Git, không push vào cluster
4. **Continuously Reconciled** — agent liên tục đảm bảo actual = desired

### GitOps vs DevOps truyền thống
| | DevOps truyền thống | GitOps |
|---|---|---|
| Deploy | CI push vào cluster | Agent pull từ Git |
| Rollback | Chạy lại pipeline | `git revert` |
| Audit | CI logs | Git history |
| Drift | Không phát hiện được | Agent tự detect + fix |

---

## 2. GitHub Actions — CI/CD Pipeline

### Workflow cơ bản cho Terraform
```yaml
# .github/workflows/terraform.yml
name: Terraform CI/CD

on:
  pull_request:
    branches: [main]
  push:
    branches: [main]

jobs:
  terraform-plan:
    name: Terraform Plan (PR)
    runs-on: ubuntu-latest
    if: github.event_name == 'pull_request'

    steps:
      - uses: actions/checkout@v4

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: "1.9.8"

      - name: Terraform Init
        run: terraform init
        working-directory: ./cloud/w8/day-1

      - name: Terraform Plan
        run: terraform plan -no-color
        working-directory: ./cloud/w8/day-1
        env:
          AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
          AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}

  terraform-apply:
    name: Terraform Apply (merge to main)
    runs-on: ubuntu-latest
    if: github.event_name == 'push' && github.ref == 'refs/heads/main'

    steps:
      - uses: actions/checkout@v4

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: "1.9.8"

      - name: Terraform Init
        run: terraform init
        working-directory: ./cloud/w8/day-1

      - name: Terraform Apply
        run: terraform apply -auto-approve
        working-directory: ./cloud/w8/day-1
        env:
          AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
          AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
```

### Pattern: Plan on PR, Apply on merge
```
feature-branch  →  PR  →  terraform plan (comment kết quả lên PR)
PR approved     →  merge to main  →  terraform apply tự động
```

---

## 3. ArgoCD

ArgoCD là GitOps agent cho Kubernetes — tự động sync manifest từ Git xuống cluster.

### Cài ArgoCD lên minikube
```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Đợi pods ready
kubectl wait --for=condition=Ready pods --all -n argocd --timeout=300s

# Port-forward để truy cập UI
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Lấy password admin
kubectl get secret argocd-initial-admin-secret -n argocd \
  -o jsonpath="{.data.password}" | base64 -d
```

Truy cập: https://localhost:8080 (user: `admin`)

### Application manifest
```yaml
# argocd/application.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: w8-platform
  namespace: argocd
spec:
  project: default

  source:
    repoURL: https://github.com/hunghk43/kimhung-aws-accelerator-p2
    targetRevision: main
    path: cloud/w8/lab          # thư mục chứa K8s manifests

  destination:
    server: https://kubernetes.default.svc
    namespace: default

  syncPolicy:
    automated:
      prune: true       # xóa resource không còn trong Git
      selfHeal: true    # tự fix khi ai đó sửa tay trên cluster
    syncOptions:
      - CreateNamespace=true
```

### App of Apps pattern
```
argocd/
  root-app.yaml          ← App "root" quản lý tất cả app bên dưới
  apps/
    web-app.yaml
    monitoring.yaml
    canary.yaml
```

```yaml
# root-app.yaml — App quản lý folder apps/
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: root
  namespace: argocd
spec:
  source:
    path: argocd/apps      # ArgoCD sẽ apply tất cả yaml trong folder này
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

### Sync Waves — kiểm soát thứ tự deploy
```yaml
# Annotation để deploy theo thứ tự
metadata:
  annotations:
    argocd.argoproj.io/sync-wave: "1"   # deploy trước
---
    argocd.argoproj.io/sync-wave: "2"   # deploy sau wave 1 xong
```

Ví dụ: wave 1 = namespace + configmap, wave 2 = deployment, wave 3 = ingress

---

## 4. ArgoCD vs Flux

| | ArgoCD | Flux |
|---|---|---|
| UI | Có UI đẹp | Chủ yếu CLI |
| Cài đặt | Phức tạp hơn | Đơn giản hơn |
| Multi-tenancy | Tốt | Tốt |
| Pull secret | Không cần | Không cần |
| Phổ biến | Rất phổ biến | Phổ biến trong enterprise |

---

## 5. Rollback

### Cách 1: `git revert` (GitOps way — khuyến nghị)
```bash
# Revert commit deploy version lỗi
git revert <commit-hash>
git push origin main
# ArgoCD tự detect → sync lại về version trước
```

### Cách 2: `kubectl rollout undo` (emergency)
```bash
kubectl rollout undo deployment/web-deployment
kubectl rollout undo deployment/web-deployment --to-revision=2
kubectl rollout history deployment/web-deployment
```

Lưu ý: `kubectl rollout undo` tạo drift giữa Git và cluster — ArgoCD sẽ phát hiện và sync lại. Dùng khi cần rollback khẩn cấp, sau đó phải update lại Git.

---

