#!/bin/bash

# AWS EKS Cluster Setup Script
set -e

CLUSTER_NAME="my-docker-app-cluster"
REGION="us-east-1"
NODE_GROUP_NAME="my-docker-app-nodes"
INSTANCE_TYPE="t3.medium"
MIN_NODES=2
MAX_NODES=4
DESIRED_NODES=2

echo "🚀 Setting up AWS EKS cluster for my-docker-app..."

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI is not installed. Please install it first."
    exit 1
fi

# Check if eksctl is installed
if ! command -v eksctl &> /dev/null; then
    echo "📦 Installing eksctl..."
    curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
    sudo mv /tmp/eksctl /usr/local/bin
fi

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo "📦 Installing kubectl..."
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    chmod +x kubectl
    sudo mv kubectl /usr/local/bin/
fi

echo "🏗️ Creating EKS cluster: $CLUSTER_NAME"
eksctl create cluster \
  --name $CLUSTER_NAME \
  --region $REGION \
  --nodegroup-name $NODE_GROUP_NAME \
  --node-type $INSTANCE_TYPE \
  --nodes $DESIRED_NODES \
  --nodes-min $MIN_NODES \
  --nodes-max $MAX_NODES \
  --managed \
  --with-oidc \
  --ssh-access \
  --ssh-public-key ~/.ssh/id_rsa.pub

echo "🔧 Configuring kubectl..."
aws eks update-kubeconfig --region $REGION --name $CLUSTER_NAME

echo "📦 Installing AWS Load Balancer Controller..."
# Create IAM policy for AWS Load Balancer Controller
curl -o iam_policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.5.4/docs/install/iam_policy.json

aws iam create-policy \
    --policy-name AWSLoadBalancerControllerIAMPolicy \
    --policy-document file://iam_policy.json || echo "Policy already exists"

# Create service account
eksctl create iamserviceaccount \
  --cluster=$CLUSTER_NAME \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --role-name AmazonEKSLoadBalancerControllerRole \
  --attach-policy-arn=arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):policy/AWSLoadBalancerControllerIAMPolicy \
  --approve

# Install AWS Load Balancer Controller
helm repo add eks https://aws.github.io/eks-charts
helm repo update
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=$CLUSTER_NAME \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller

echo "📊 Installing metrics server..."
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

echo "🎯 Installing NGINX Ingress Controller..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.2/deploy/static/provider/aws/deploy.yaml

echo "⏳ Waiting for ingress controller to be ready..."
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=300s

echo "✅ EKS cluster setup completed!"
echo ""
echo "📋 Cluster Information:"
kubectl cluster-info
echo ""
echo "🔍 Nodes:"
kubectl get nodes
echo ""
echo "🌐 Ingress Controller:"
kubectl get svc -n ingress-nginx
echo ""
echo "🚀 Your cluster is ready for deployment!"
echo "Run: kubectl apply -k k8s/ to deploy your application"

# Clean up
rm -f iam_policy.json