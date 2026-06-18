# W10 Day 2 — Secrets Rotation + Supply Chain Security

## Mục tiêu

- Không hardcode secret trong Git hay image
- Secret tự rotate, app không cần restart
- Image được scan và ký — admission chỉ cho qua image đã verify

---

## 1. AWS Secrets Manager + External Secrets Operator (ESO)

### Vấn đề với Secret thông thường

```yaml
# ❌ Sai — hardcode trong YAML, lưu vào Git
apiVersion: v1
kind: Secret
data:
  password: c3VwZXJzZWNyZXQ=   # base64, ai cũng decode được
```

Base64 không phải encrypt. Secret YAML trong Git = lộ credential.

### Giải pháp: ESO kéo từ AWS Secrets Manager

```
AWS Secrets Manager (nguồn thật)
        │
        │  ESO poll mỗi refreshInterval
        ▼
ExternalSecret (CRD)
        │
        │  ESO tạo/cập nhật
        ▼
Kubernetes Secret (trong cluster, không lưu Git)
        │
        ▼
Pod mount secret → app đọc
```

### Cài ESO qua Helm

```bash
helm repo add external-secrets https://charts.external-secrets.io
helm install external-secrets external-secrets/external-secrets \
  -n external-secrets --create-namespace
```

### Config ESO

Xem file: `eso/secretstore.yaml` và `eso/externalsecret.yaml`

### Rotate secret < 60s no-restart

```yaml
# externalsecret.yaml
spec:
  refreshInterval: 30s   # ESO poll AWS mỗi 30s
```

Khi AWS Secrets Manager xoay key → ESO phát hiện trong 30s → cập nhật K8s Secret → app đọc file mount tự nhận giá trị mới mà không cần restart pod.

---

## 2. Trivy — Image Scan trong CI

### Trivy là gì

Tool scan CVE (lỗ hổng bảo mật) trong:
- Container image
- Filesystem
- Git repo
- IaC (Terraform, Kubernetes YAML)

### Tích hợp vào GitHub Actions

```yaml
# .github/workflows/trivy-scan.yml
- name: Scan image with Trivy
  uses: aquasecurity/trivy-action@master
  with:
    image-ref: w9-api:1
    format: table
    exit-code: 1              # fail CI nếu có lỗ hổng
    severity: HIGH,CRITICAL   # chỉ fail khi HIGH hoặc CRITICAL
    ignore-unfixed: true      # bỏ qua CVE chưa có fix
```

**`exit-code: 1`** — quan trọng nhất. Không có dòng này thì scan xong nhưng CI vẫn pass dù có lỗ hổng.

### Exception policy

Khi có CVE chưa có fix nhưng cần deploy gấp → tạo ADR có thời hạn:

```yaml
# trivy-ignore.yaml — ghi rõ lý do và ngày hết hạn
# CVE-2024-1234 — libssl, chưa có fix, review lại 2026-07-01
CVE-2024-1234
```

---

## 3. Cosign — Image Signing

### Tại sao cần ký image

Build ra image `w9-api:2` → push lên registry → ai đó thay image bằng version độc hại → cluster pull về → **không biết image đã bị tamper**.

Cosign ký image bằng private key → admission controller verify trước khi cho pull → image giả bị chặn.

### Keyless OIDC (khuyến nghị cho CI)

Không cần quản lý key — dùng OIDC token từ GitHub Actions:

```yaml
# .github/workflows/sign.yml
- name: Sign image with Cosign (keyless)
  env:
    COSIGN_EXPERIMENTAL: 1    # bật keyless mode
  run: |
    cosign sign --yes \
      ghcr.io/${{ github.repository }}/w9-api:${{ github.sha }}
```

Cosign liên hệ Sigstore Fulcio (CA) + Rekor (transparency log) → không cần lưu private key.

### Key-based signing

```bash
# Tạo key pair
cosign generate-key-pair

# Ký
cosign sign --key cosign.key ghcr.io/hunghk43/w9-api:1

# Verify
cosign verify --key cosign.pub ghcr.io/hunghk43/w9-api:1
```

### Verify ở đâu là đúng nhất?

| Layer | Tool | Trade-off |
|---|---|---|
| CI | cosign verify trong pipeline | Chỉ bảo vệ trong CI, bypass được |
| Registry | Registry policy | Phụ thuộc registry hỗ trợ |
| **Admission** ⭐ | Kyverno / Gatekeeper | **Bắt buộc ở cluster level** — không bypass được |

### Kyverno verify image (admission)

```yaml
# policies/verify-image-signature.yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: verify-image-signature
spec:
  validationFailureAction: Enforce
  rules:
    - name: check-image-signature
      match:
        resources:
          kinds: ["Pod"]
      verifyImages:
        - imageReferences:
            - "ghcr.io/hunghk43/*"
          attestors:
            - entries:
                - keys:
                    publicKeys: |-
                      -----BEGIN PUBLIC KEY-----
                      <cosign.pub content>
                      -----END PUBLIC KEY-----
```

---

## 4. Supply Chain Security — SLSA

### SLSA Levels

| Level | Yêu cầu |
|---|---|
| L0 | Không có gì |
| L1 | Build script tạo ra provenance (ghi lại build từ source nào) |
| L2 | Build trên hosted CI, provenance ký bởi CI |
| L3 | Build isolated, không thể tamper, source verified |

Dự án này đạt **L1-L2**: build trên GitHub Actions (hosted), có Cosign ký image.

---

## 5. Tóm tắt pipeline bảo mật

```
Developer push code
      │
      ▼
GitHub Actions CI:
  ├── kubeconform validate YAML
  ├── trivy scan image (fail nếu HIGH/CRITICAL)
  └── cosign sign image sau khi build
      │
      ▼
Push image lên registry (đã ký)
      │
      ▼
ArgoCD sync → Rollout deploy
      │
      ▼
Admission Controller (Kyverno):
  ├── verify image signature ← reject nếu chưa ký
  ├── no-latest-tag          ← reject nếu :latest
  └── required-labels        ← reject nếu thiếu label
      │
      ▼
Pod running — secret từ ESO (không hardcode)
```
