# Runbook: API High Error Rate

**Alert:** `ApiFastBurnRate` firing  
**Severity:** Critical  
**Owner:** SRE team  
**Last updated:** 2026-06-15

---

## Triệu chứng

- Alert `ApiFastBurnRate` firing trên Prometheus / email
- Error rate > 7.2% trên window 5m + 1h
- User báo lỗi 500 từ API

---

## Bước 1 — Triage (2 phút)

```bash
# Kiểm tra pod health
kubectl get pods -n demo -l app=api

# Xem error rate thực tế
# Mở: localhost:9090
# Query: sum(rate(flask_http_request_total{namespace="demo",status=~"5.."}[5m])) / clamp_min(sum(rate(flask_http_request_total{namespace="demo"}[5m])),1)

# Xem logs pod lỗi
kubectl logs -n demo -l app=api --tail=50 | grep -i error
```

**Quyết định nhanh:**
- Có pod `CrashLoopBackOff`? → sang Bước 3
- Tất cả pod Running nhưng vẫn lỗi? → sang Bước 2

---

## Bước 2 — Kiểm tra Rollout (canary đang chạy?)

```bash
kubectl get rollout api -n demo
kubectl get analysisrun -n demo

# Nếu Rollout đang Progressing với canary xấu → abort thủ công
kubectl patch rollout api -n demo --subresource=status \
  --type=merge --patch '{"status":{"abort":true}}'
```

Nếu rollout abort thành công → stable pod nhận lại 100% traffic → error rate tụt.

---

## Bước 3 — Rollback qua Git

```bash
# Xem commit gần nhất
git log --oneline -5

# Revert commit lỗi
git revert HEAD --no-edit
git push

# Theo dõi ArgoCD sync (~2-3 phút)
kubectl -n argocd get applications -w
```

---

## Bước 4 — Verify hệ thống ổn định

```bash
# Error rate về 0
# Query Prometheus: flask_http_request_total{status=~"5.."}

# Rollout Healthy
kubectl get rollout api -n demo

# Alert resolved
# Mở: localhost:9093 → Alerts
```

---

## Bước 5 — Post-mortem (trong 24h)

- Commit nào gây ra lỗi?
- AnalysisTemplate có abort đúng không hay cần điều chỉnh ngưỡng?
- Cần thêm test gì trong CI để bắt lỗi này sớm hơn?
- Cập nhật runbook nếu cần.

---

## Liên hệ

- SRE on-call: `#phase2-cloud-help`
- Escalate: DM mentor Kiệt hoặc Vương
