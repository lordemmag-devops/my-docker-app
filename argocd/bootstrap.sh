#!/bin/bash

# ArgoCD Bootstrap Script
set -e

echo "Installing ArgoCD..."
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "Waiting for ArgoCD to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd

echo "Exposing ArgoCD server..."
kubectl patch svc argocd-server -n argocd -p '{"spec":{"type":"LoadBalancer"}}'

echo "Creating ArgoCD project..."
kubectl apply -f argocd/projects/

echo "Creating ArgoCD applications..."
kubectl apply -f argocd/apps/

echo "Getting ArgoCD admin password..."
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

echo -e "\n\nArgoCD is ready!"
echo "Access ArgoCD UI at: kubectl port-forward svc/argocd-server -n argocd 8080:443"
echo "Username: admin"