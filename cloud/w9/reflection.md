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



## Day 3

