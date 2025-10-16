#!/bin/bash

# EC2 Kubernetes Setup Script
set -e

echo "🚀 Setting up Kubernetes on EC2..."

# Update system
sudo apt-get update -y

# Install Docker
if ! command -v docker &> /dev/null; then
    echo "📦 Installing Docker..."
    sudo apt-get install -y docker.io
    sudo systemctl enable docker
    sudo systemctl start docker
    sudo usermod -aG docker $USER
fi

# Install kubeadm, kubelet, kubectl
if ! command -v kubectl &> /dev/null; then
    echo "📦 Installing Kubernetes components..."
    sudo apt-get update
    sudo apt-get install -y apt-transport-https ca-certificates curl
    
    curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-archive-keyring.gpg
    echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
    
    sudo apt-get update
    sudo apt-get install -y kubelet kubeadm kubectl
    sudo apt-mark hold kubelet kubeadm kubectl
fi

# Disable swap
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# Initialize Kubernetes cluster
if [ ! -f /etc/kubernetes/admin.conf ]; then
    echo "🏗️ Initializing Kubernetes cluster..."
    sudo kubeadm init --pod-network-cidr=10.244.0.0/16
    
    # Setup kubectl for regular user
    mkdir -p $HOME/.kube
    sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
    sudo chown $(id -u):$(id -g) $HOME/.kube/config
fi

# Install Flannel CNI
echo "🌐 Installing Flannel CNI..."
kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml

# Allow scheduling on master node (single node cluster)
kubectl taint nodes --all node-role.kubernetes.io/control-plane-

# Install NGINX Ingress Controller
echo "🚪 Installing NGINX Ingress Controller..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.2/deploy/static/provider/baremetal/deploy.yaml

# Wait for ingress controller
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=300s

# Install AWS CLI
if ! command -v aws &> /dev/null; then
    echo "☁️ Installing AWS CLI..."
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install
    rm -rf awscliv2.zip aws
fi

echo "✅ Kubernetes setup completed!"
echo ""
echo "📋 Cluster Information:"
kubectl cluster-info
echo ""
echo "🔍 Nodes:"
kubectl get nodes
echo ""
echo "🌐 Ingress Controller:"
kubectl get svc -n ingress-nginx