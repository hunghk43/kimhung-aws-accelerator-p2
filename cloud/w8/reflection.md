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

- Terraform State Management: local vs remote (S3 + DynamoDB lock)
- Modules: tái sử dụng code, local module vs registry module
- Best practices: naming, pin version, tag mọi resource, không commit tfstate
- ADR-001: quyết định dùng S3+DynamoDB làm remote backend
- Lab: bootstrap S3 bucket + DynamoDB cho state, backend.tf config
- 15h–17h: Live session với mentor Minh
- 17h–18h: Online Test 1 (scope Terraform D1+D3)
