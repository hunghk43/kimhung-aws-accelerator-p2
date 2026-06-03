# W8 Day 2 — Kubernetes Fundamentals

## 1. Container & Orchestration Overview

### Container là gì?
Container đóng gói app + dependencies vào 1 unit chạy được ở bất kỳ đâu.

```
[App Code] + [Runtime] + [Libraries] + [Config]  →  Container Image
```

Khác VM ở chỗ: container share OS kernel → nhẹ hơn, start nhanh hơn.

### Tại sao cần Orchestration?
Chạy 1 container thủ công với `docker run` ổn. Nhưng production có 100+ container thì:

| Vấn đề | K8s giải quyết |
|---|---|
| Container crash → chết luôn | Auto restart (self-healing) |
| Traffic tăng → cần scale | Auto scaling (HPA) |
| Deploy version mới → downtime | Rolling update / Canary |
| Nhiều node → schedule ở đâu? | Scheduler tự chọn node phù hợp |
| Service discovery | DNS nội bộ, Service object |

### Docker vs Kubernetes
| | Docker | Kubernetes |
|---|---|---|
| Role | Build + run container | Orchestrate nhiều container |
| Scope | 1 host | Multi-node cluster |
| Scaling | Thủ công | Tự động |
| Self-healing | Không | Có |

K8s **dùng Docker** (hoặc containerd) để chạy container — chúng bổ sung cho nhau, không thay thế.

---

## 2. Kubernetes Architecture

```
                    [ Control Plane ]
                   ┌─────────────────┐
  kubectl ──────►  │   API Server    │
                   │   Scheduler     │
                   │   etcd (state)  │
                   │   Controller    │
                   └────────┬────────┘
                            │
              ┌─────────────┼─────────────┐
         [ Node 1 ]    [ Node 2 ]    [ Node 3 ]
         ┌─────────┐  ┌─────────┐  ┌─────────┐
         │ kubelet │  │ kubelet │  │ kubelet │
         │  Pods   │  │  Pods   │  │  Pods   │
         └─────────┘  └─────────┘  └─────────┘
```

- **API Server** — cổng vào duy nhất, nhận request từ kubectl
- **etcd** — database lưu toàn bộ cluster state
- **Scheduler** — quyết định Pod chạy trên Node nào
- **Controller Manager** — loop liên tục đảm bảo actual state = desired state
- **kubelet** — agent trên mỗi Node, nhận lệnh từ API Server và chạy Pod

---

## 3. Pod

Unit nhỏ nhất trong K8s. 1 Pod = 1+ container chia sẻ network và storage.

### Đặc điểm
- Pod có IP riêng trong cluster
- Container trong cùng Pod giao tiếp qua `localhost`
- Pod là **ephemeral** — có thể bị xóa/tạo lại bất cứ lúc nào
- Thường không tạo Pod trực tiếp — dùng Deployment để quản lý

### Pod lifecycle
```
Pending → Running → Succeeded/Failed
```

---

## 4. Probes

K8s dùng probe để kiểm tra sức khỏe container.

### Liveness Probe
"Container còn sống không?" → Nếu fail → **restart container**

### Readiness Probe
"Container sẵn sàng nhận traffic chưa?" → Nếu fail → **remove khỏi Service endpoints** (không restart)

### Startup Probe
"App đã khởi động xong chưa?" → Dùng cho app khởi động chậm, disable liveness trong thời gian này

### Các loại probe
- `httpGet` — gọi HTTP endpoint, thành công nếu 200-399
- `tcpSocket` — check port có mở không
- `exec` — chạy command trong container, thành công nếu exit code 0

---

## 5. Service

Pod có IP động (thay đổi khi restart) → cần Service làm stable endpoint.

### Các loại Service
| Type | Mô tả | Use case |
|---|---|---|
| `ClusterIP` | IP nội bộ cluster (default) | Internal microservices |
| `NodePort` | Expose qua port của Node | Dev/test local |
| `LoadBalancer` | Tạo cloud LB (AWS ELB...) | Production |
| `ExternalName` | Map tới DNS external | Point tới service ngoài cluster |

Service dùng **label selector** để tìm Pod:
```yaml
selector:
  app: web   # match tất cả Pod có label app=web
```

---

## 6. ConfigMap & Secret

### ConfigMap — lưu config không nhạy cảm
```yaml
# Inject vào Pod dưới dạng env var hoặc file
```

### Secret — lưu data nhạy cảm (password, token, key)
- Encode base64 (không phải encrypt — cần kết hợp RBAC + encryption at rest)
- Không hardcode secret trong image

---

## 7. NetworkPolicy

Mặc định tất cả Pod có thể giao tiếp với nhau. NetworkPolicy cho phép whitelist traffic.

```
Không có NetworkPolicy → mọi Pod nói chuyện được với nhau
Có NetworkPolicy     → chỉ traffic được allow mới qua
```

---

## Câu hỏi tự kiểm tra

1. Tại sao không nên tạo Pod trực tiếp mà dùng Deployment?
2. Sự khác nhau giữa liveness và readiness probe?
3. ClusterIP vs NodePort — dùng khi nào?
4. Secret có thực sự "secure" không? Cần thêm gì?
5. NetworkPolicy mặc định là allow hay deny?
