# W8 Reflection

## Day 1 — Terraform IaC Basics

- IaC overview: declarative vs imperative, Terraform vs CloudFormation
- HCL syntax: provider, resource, variable, output, locals, data source
- Workflow: init → plan → apply → destroy
- Demo: tạo S3 bucket với variable, locals, output, public access block
- Hiểu state file và tại sao không commit `.tfstate`


## Day 2 — Kubernetes Fundamentals

- Container vs VM, tại sao cần Orchestration
- K8s architecture: Control Plane (API Server, etcd, Scheduler) + Node (kubelet)
- Pod, Deployment, Service (ClusterIP/NodePort)
- Liveness probe vs Readiness probe
- ConfigMap (config) + Secret (sensitive data), inject env/volume
- NetworkPolicy: default-deny + whitelist pattern
- Cài Docker Desktop + minikube + kubectl, verify `minikube start`


## Day 3 — Terraform Advanced + Live Session

