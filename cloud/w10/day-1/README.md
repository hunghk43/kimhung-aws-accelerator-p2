# W10 Day 1 — RBAC + Admission Policy (OPA/Gatekeeper)

## Mục tiêu

Hardening cluster ở tầng **authorization** và **admission** — không dựa vào "developer tự hứa" mà enforce tại cluster level.

- RBAC: ai được làm gì trên resource nào
- OPA/Gatekeeper: resource có đúng policy không trước khi được tạo

---

## 1. RBAC — Role-Based Access Control

### Khái niệm

```
Subject (ai)  →  RoleBinding  →  Role (quyền gì)  →  Resource (trên gì)
```

| Object | Scope | Dùng khi |
|---|---|---|
| `Role` | 1 namespace | Giới hạn quyền trong namespace |
| `ClusterRole` | Toàn cluster | Quyền cluster-wide hoặc dùng lại nhiều namespace |
| `RoleBinding` | 1 namespace | Gán Role/ClusterRole cho subject trong namespace |
| `ClusterRoleBinding` | Toàn cluster | Gán ClusterRole cho subject trên toàn cluster |

**Subject** có thể là: `User`, `Group`, `ServiceAccount`

### 3 Role chuẩn trong platform

```yaml
# Developer — chỉ deploy, không xóa
# SRE       — đọc tất cả, restart pod, xem log
# Viewer    — chỉ đọc (get/list/watch)
```

Xem file: `rbac/roles.yaml`

### ServiceAccount

Pod mặc định dùng `default` ServiceAccount — có quyền rộng không cần thiết. Best practice: tạo ServiceAccount riêng cho mỗi workload, chỉ cấp quyền tối thiểu (Principle of Least Privilege).

```bash
# Kiểm tra quyền
kubectl auth can-i get pods --as=system:serviceaccount:demo:api-sa -n demo
kubectl auth can-i delete deployments --as=developer -n demo
```

---

## 2. OPA / Gatekeeper — Admission Policy

### Luồng request vào cluster

```
kubectl apply
    │
    ▼
API Server
    │
    ├── Authentication (ai gửi?)
    ├── Authorization (RBAC — được làm không?)
    └── Admission Controllers
            ├── Mutating  (sửa resource trước khi lưu)
            └── Validating (chặn nếu vi phạm policy)  ← OPA/Gatekeeper ở đây
```

### Gatekeeper — 2 object cần biết

**ConstraintTemplate** — định nghĩa "luật" bằng Rego:
```yaml
kind: ConstraintTemplate
metadata:
  name: k8srequiredlabels
spec:
  crd:
    spec:
      names:
        kind: K8sRequiredLabels   # tên CRD sẽ được tạo
  targets:
    - target: admission.k8s.gatekeeper.sh
      rego: |
        package k8srequiredlabels
        violation[{"msg": msg}] {
          not input.review.object.metadata.labels["app"]
          msg := "Missing required label: app"
        }
```

**Constraint** — áp dụng "luật" vào resource cụ thể:
```yaml
kind: K8sRequiredLabels         # kind từ ConstraintTemplate
metadata:
  name: require-app-label
spec:
  enforcementAction: deny       # deny | warn | dryrun
  match:
    kinds:
      - apiGroups: ["apps"]
        kinds: ["Deployment"]
  parameters:
    labels: ["app"]
```

### enforcement modes

| Mode | Hành vi |
|---|---|
| `deny` | Block request, trả lỗi ngay |
| `warn` | Cho qua nhưng warning |
| `dryrun` | Audit mode — log vi phạm, không block |

Best practice: bắt đầu `dryrun` để kiểm tra vi phạm hiện có, sau đó chuyển `deny`.

### ValidatingAdmissionPolicy (native K8s 1.30+)

Không cần cài Gatekeeper, dùng CEL expression trực tiếp:
```yaml
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingAdmissionPolicy
metadata:
  name: require-app-label
spec:
  matchConstraints:
    resourceRules:
      - apiGroups: ["apps"]
        apiVersions: ["v1"]
        operations: ["CREATE", "UPDATE"]
        resources: ["deployments"]
  validations:
    - expression: "has(object.metadata.labels.app)"
      message: "Deployment must have label 'app'"
```

---

## 3. Thực hành

Xem folder `rbac/` và `policies/`:

```
day-1/
├── rbac/
│   ├── roles.yaml           # Role: developer, sre, viewer
│   ├── clusterroles.yaml    # ClusterRole cho sre (cross-namespace)
│   ├── bindings.yaml        # RoleBinding gán role cho user/SA
│   └── serviceaccount.yaml  # ServiceAccount cho api workload
└── policies/
    ├── constraint-template-required-labels.yaml
    ├── constraint-template-no-latest-tag.yaml
    ├── constraint-required-labels.yaml
    └── constraint-no-latest-tag.yaml
```

### Commands kiểm tra

```bash
# Xem quyền của một subject
kubectl auth can-i --list --as=system:serviceaccount:demo:api-sa -n demo

# Xem tất cả RoleBinding trong namespace
kubectl get rolebinding -n demo -o wide

# Kiểm tra Gatekeeper constraint violations
kubectl get constraints
kubectl describe k8srequiredlabels require-app-label

# Audit violations hiện có
kubectl get k8srequiredlabels -o jsonpath='{.items[*].status.violations}'
```

---

## 4. Tóm tắt — Khi nào dùng gì

| Vấn đề | Giải pháp |
|---|---|
| Developer xóa nhầm production resource | RBAC: Role không có `delete` verb |
| Pod chạy với quyền root | Gatekeeper: constraint `runAsNonRoot` |
| Image không có tag cụ thể (`latest`) | Gatekeeper: constraint no-latest-tag |
| Deployment thiếu label bắt buộc | Gatekeeper: constraint required-labels |
| ServiceAccount mặc định có quyền rộng | Tạo dedicated SA + RBAC tối thiểu |
