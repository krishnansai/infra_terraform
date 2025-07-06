#!/bin/bash

set -e

echo "#### Kube config update ######"
aws eks update-kubeconfig --region us-east-1 --name staging-env
kubectl get pods -A

echo "### Install ArgoCD #####"
kubectl create namespace argocd || true
kubectl config set-context --current --namespace=argocd
kubectl apply -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "#### Adding LoadBalancer for ArgoCD ####"
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'

echo "Waiting for LoadBalancer to become ready..."
sleep 60s

ARGOCD_SERVER=$(kubectl get svc argocd-server -n argocd -o json | jq -r '.status.loadBalancer.ingress[0].hostname')
echo "ArgoCD URL: http://$ARGOCD_SERVER"

ARGO_PWD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
echo "ArgoCD admin password: $ARGO_PWD"

kubectl create secret generic argocd-github-secret --from-literal=token=${ARGOCD_HTTPS_SYNC} --namespace=argocd

echo "#### Deploy Prometheus and Grafana #####"
kubectl apply --filename https://raw.githubusercontent.com/giantswarm/prometheus/master/manifests-all.yaml
echo "Waiting for Prometheus pods to be ready..."
kubectl wait --for=condition=Ready pods --all --timeout=300s -n monitoring || true

echo "#### Done! ####"
