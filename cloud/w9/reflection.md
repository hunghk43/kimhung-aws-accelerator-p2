# W9 Reflection

## Day 1 — GitOps & CI/CD

- GitOps 4 nguyên tắc: Declarative, Versioned, Pull-based, Reconciled
- GitHub Actions: plan-on-PR + apply-on-merge pattern
- ArgoCD: cài lên minikube, Application CRD, App of Apps, Sync Waves
- ArgoCD vs Flux so sánh
- Rollback: `git revert` (GitOps way) vs `kubectl rollout undo` (emergency)



## Day 2 — Observability: SLO/SLI/OTel

- SLI/SLO/SLA/Error Budget — tính error budget từ SLO 99.9%
- 3 pillars: Metrics + Logs + Traces
- OTel Collector: nhận OTLP → route sang Prometheus/Loki/Jaeger
- Prometheus + Grafana + Loki stack trên minikube
- Multi-window burn rate alert: fast (1h×5min) + slow (6h×30min)
- PromQL queries cho availability và latency SLI



## Day 3 — Progressive Delivery: Canary + Argo Rollouts

- Canary vs RollingUpdate vs Blue/Green so sánh
- Argo Rollouts: Rollout CRD thay thế Deployment
- AnalysisTemplate: Prometheus query làm abort criteria
- Tích hợp burn rate (14.4x) vào AnalysisTemplate
- Steps: 10% → 30% → 50% → auto promote, abort khi metric fail
- 15h–17h: Live Monitoring/Observability với mentor Minh
- 17h–18h: Online Test 1 (scope D1 GitOps + D2 Observability)


