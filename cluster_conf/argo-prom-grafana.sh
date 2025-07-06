#!/usr/bin/env bash

set -euo pipefail

# Ensure environment variables
: "${ARGOCD_HTTPS_SYNC:?Environment variable ARGOCD_HTTPS_SYNC must be set}"

echo "#### Kube config update ######"
aws eks update-kubeconfig --region us-east-1 --name staging-env
kubectl get pods -A

echo "### Install ArgoCD #####"
kubectl create namespace argocd || true
kubectl config set-context --current --namespace=argocd
kubectl apply -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "#### Adding LoadBalancer for ArgoCD ####"
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'

echo "🔹 Waiting for ArgoCD LoadBalancer external IP..."
while true; do
  ARGOCD_SERVER=$(kubectl get svc argocd-server -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || true)
  if [ -n "$ARGOCD_SERVER" ]; then
    break
  fi
  sleep 5
done

echo "ArgoCD URL: http://$ARGOCD_SERVER"

export ARGO_PWD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
echo "ArgoCD admin password: $ARGO_PWD"

kubectl create secret generic argocd-github-secret --from-literal=token=${ARGOCD_HTTPS_SYNC}
sleep 10s
# ========== CONFIGURATION ==========
NAMESPACE="monitoring"
RELEASE_NAME="prometheus"
GRAFANA_PASSWORD="admin1234"

# ========== INSTALL HELM REPOS ==========
echo "🔹 Adding Helm repositories..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# ========== CREATE NAMESPACE ==========
echo "🔹 Creating namespace $NAMESPACE if not exists..."
kubectl get namespace "$NAMESPACE" >/dev/null 2>&1 || kubectl create namespace "$NAMESPACE"

# ========== CREATE TEMP VALUES FILE ==========
echo "🔹 Creating custom values file..."
cat <<EOF > /tmp/kube-prometheus-values.yaml
grafana:
  adminPassword: "$GRAFANA_PASSWORD"
  service:
    type: LoadBalancer
EOF

# ========== INSTALL KUBE-PROMETHEUS-STACK ==========
echo "🔹 Installing Prometheus + Grafana Helm chart..."
helm install "$RELEASE_NAME" prometheus-community/kube-prometheus-stack \
  --namespace "$NAMESPACE" \
  -f /tmp/kube-prometheus-values.yaml

# ========== WAIT FOR GRAFANA LOADBALANCER IP ==========
echo "🔹 Waiting for Grafana LoadBalancer external IP..."
while true; do
  EXTERNAL_IP=$(kubectl get svc "$RELEASE_NAME"-grafana \
    --namespace "$NAMESPACE" \
    --output jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || true)
  if [ -n "$EXTERNAL_IP" ]; then
    break
  fi
  sleep 5
done

echo "✅ Installation complete!"
echo ""
echo "🌐 Grafana LoadBalancer endpoint: http://$EXTERNAL_IP"
echo "👤 Username: admin"
echo "🔑 Password: $GRAFANA_PASSWORD"
echo "🔗 ArgoCD URL: http://$ARGOCD_SERVER"
echo "ArgoCD admin password: $ARGO_PWD"
