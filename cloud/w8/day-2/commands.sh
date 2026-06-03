#!/bin/bash
# Các lệnh kubectl hay dùng khi học Day 2
# Chạy từng dòng, không chạy cả file

# ── Kiểm tra cluster ──────────────────────────────────────
minikube start
kubectl get nodes
kubectl cluster-info

# ── Pod ───────────────────────────────────────────────────
kubectl apply -f 01-pod.yaml
kubectl get pods
kubectl get pods -o wide              # xem IP + Node
kubectl describe pod web-pod          # chi tiết events, probes
kubectl logs web-pod                  # xem logs
kubectl exec -it web-pod -- sh        # vào trong container

# ── ConfigMap + Secret ────────────────────────────────────
kubectl apply -f 02-configmap-secret.yaml
kubectl get configmap
kubectl describe configmap app-config
kubectl get secret
kubectl get secret app-secret -o jsonpath='{.data.DB_PASSWORD}' | base64 -d

# ── Deployment + Service ──────────────────────────────────
kubectl apply -f 03-deployment-service.yaml
kubectl get deployments
kubectl get pods                      # thấy 3 pod chạy
kubectl get service

# Test service trên minikube
minikube service web-service --url

# Xem rolling update
kubectl set image deployment/web-deployment nginx=nginx:1.26-alpine
kubectl rollout status deployment/web-deployment
kubectl rollout history deployment/web-deployment
kubectl rollout undo deployment/web-deployment   # rollback

# Scale
kubectl scale deployment web-deployment --replicas=5
kubectl get pods -w                   # watch real-time

# ── NetworkPolicy ─────────────────────────────────────────
kubectl apply -f 04-networkpolicy.yaml
kubectl get networkpolicy

# ── Dọn dẹp ──────────────────────────────────────────────
kubectl delete -f 01-pod.yaml
kubectl delete -f 02-configmap-secret.yaml
kubectl delete -f 03-deployment-service.yaml
kubectl delete -f 04-networkpolicy.yaml

# Hoặc xóa tất cả trong namespace default
kubectl delete all --all
