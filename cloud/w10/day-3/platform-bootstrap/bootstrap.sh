#!/bin/bash
# Platform Bootstrap — deploy full stack từ fresh cluster
# Mục tiêu: < 2 giờ từ repo
# Usage: bash bootstrap.sh

set -e

echo "=== Step 1: Install ArgoCD ==="
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl -n argocd rollout status deploy/argocd-server --timeout=300s

echo "=== Step 2: Apply root app (app-of-apps) ==="
# Thay repo URL theo repo thực tế
kubectl apply -f argocd/root.yaml
echo "Root app applied. ArgoCD sẽ tự tạo tất cả app con."

echo "=== Step 3: Đợi core apps sẵn sàng ==="
kubectl -n argocd wait --for=jsonpath='{.status.health.status}'=Healthy \
  application/kube-prometheus-stack --timeout=300s
kubectl -n argocd wait --for=jsonpath='{.status.health.status}'=Healthy \
  application/argo-rollouts --timeout=300s

echo "=== Step 4: Apply RBAC ==="
kubectl apply -f cloud/w10/day-1/rbac/

echo "=== Step 5: Apply ResourceQuota + LimitRange ==="
kubectl apply -f cloud/w10/day-3/quota/

echo "=== Step 6: Verify ==="
echo "--- ArgoCD apps ---"
kubectl -n argocd get applications

echo "--- RBAC roles ---"
kubectl get role -n demo

echo "--- Quota ---"
kubectl describe quota -n demo

echo "=== Bootstrap hoàn tất ==="
echo "Kiểm tra thêm:"
echo "  kubectl get constraints"
echo "  kubectl get externalsecret -n demo"
echo "  kubectl get rollout -n demo"
