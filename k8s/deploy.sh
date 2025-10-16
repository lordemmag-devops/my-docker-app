#!/bin/bash

# Kubernetes Deployment Script for Multi-Service Docker App
set -e

NAMESPACE="my-docker-app"
KUBECTL_CMD="kubectl"

echo "🚀 Starting Kubernetes deployment..."

# Create namespace if it doesn't exist
echo "📦 Creating namespace..."
$KUBECTL_CMD apply -f namespace.yaml

# Apply all resources using kustomization
echo "🔧 Applying Kubernetes resources..."
$KUBECTL_CMD apply -k .

# Wait for deployments to be ready
echo "⏳ Waiting for deployments to be ready..."
$KUBECTL_CMD wait --for=condition=available --timeout=300s deployment/db -n $NAMESPACE
$KUBECTL_CMD wait --for=condition=available --timeout=300s deployment/cache -n $NAMESPACE
$KUBECTL_CMD wait --for=condition=available --timeout=300s deployment/backend-blue -n $NAMESPACE
$KUBECTL_CMD wait --for=condition=available --timeout=300s deployment/frontend-blue -n $NAMESPACE
$KUBECTL_CMD wait --for=condition=available --timeout=300s deployment/prometheus -n $NAMESPACE
$KUBECTL_CMD wait --for=condition=available --timeout=300s deployment/grafana -n $NAMESPACE

# Display deployment status
echo "📊 Deployment Status:"
$KUBECTL_CMD get pods -n $NAMESPACE
$KUBECTL_CMD get services -n $NAMESPACE
$KUBECTL_CMD get ingress -n $NAMESPACE

echo "✅ Deployment completed successfully!"
echo ""
echo "🌐 Access your application:"
echo "  - Frontend: http://your-ingress-ip/"
echo "  - API: http://your-ingress-ip/api/"
echo "  - Prometheus: http://your-ingress-ip/prometheus"
echo "  - Grafana: http://your-ingress-ip/grafana (admin/admin123)"
echo ""
echo "📝 To get ingress IP:"
echo "  kubectl get ingress -n $NAMESPACE"