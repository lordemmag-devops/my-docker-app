#!/bin/bash

# AWS EKS Cluster Cleanup Script
set -e

CLUSTER_NAME="my-docker-app-cluster"
REGION="us-east-1"

echo "🧹 Cleaning up AWS EKS cluster: $CLUSTER_NAME"

# Delete the application first
echo "📦 Deleting application resources..."
kubectl delete namespace my-docker-app --ignore-not-found=true

# Delete ingress controller
echo "🌐 Deleting NGINX Ingress Controller..."
kubectl delete -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.2/deploy/static/provider/aws/deploy.yaml --ignore-not-found=true

# Delete AWS Load Balancer Controller
echo "⚖️ Deleting AWS Load Balancer Controller..."
helm uninstall aws-load-balancer-controller -n kube-system --ignore-not-found

# Delete the cluster
echo "🗑️ Deleting EKS cluster..."
eksctl delete cluster --name $CLUSTER_NAME --region $REGION

# Delete IAM policy
echo "🔐 Deleting IAM policy..."
aws iam delete-policy --policy-arn arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):policy/AWSLoadBalancerControllerIAMPolicy --ignore-not-found || echo "Policy not found or already deleted"

echo "✅ Cleanup completed!"