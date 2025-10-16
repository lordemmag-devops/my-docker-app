#!/bin/bash

# Deployment Verification Script
set -e

NAMESPACE="my-docker-app"

echo "🔍 Verifying deployment status..."

# Check if namespace exists
if ! kubectl get namespace $NAMESPACE >/dev/null 2>&1; then
    echo "❌ Namespace $NAMESPACE does not exist"
    exit 1
fi

echo "✅ Namespace $NAMESPACE exists"

# Check deployments
echo "📊 Checking deployments..."
kubectl get deployments -n $NAMESPACE

# Check services
echo "🌐 Checking services..."
kubectl get services -n $NAMESPACE

# Check ingress
echo "🚪 Checking ingress..."
kubectl get ingress -n $NAMESPACE

# Check pods status
echo "🏃 Checking pod status..."
kubectl get pods -n $NAMESPACE

# Health check
echo "🏥 Performing health checks..."

# Get active backend pod
BACKEND_POD=$(kubectl get pods -n $NAMESPACE -l app=backend -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)

if [ -n "$BACKEND_POD" ]; then
    echo "Testing backend health endpoint..."
    if kubectl exec -n $NAMESPACE $BACKEND_POD -- curl -f http://localhost:3000/health >/dev/null 2>&1; then
        echo "✅ Backend health check passed"
    else
        echo "❌ Backend health check failed"
    fi
else
    echo "⚠️ No backend pods found"
fi

# Get ingress URL
INGRESS_URL=$(kubectl get ingress -n $NAMESPACE -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}' 2>/dev/null)

if [ -n "$INGRESS_URL" ]; then
    echo ""
    echo "🌐 Application URLs:"
    echo "  Frontend: http://$INGRESS_URL/"
    echo "  API: http://$INGRESS_URL/api/"
    echo "  Prometheus: http://$INGRESS_URL/prometheus"
    echo "  Grafana: http://$INGRESS_URL/grafana"
else
    echo "⚠️ Ingress URL not available yet"
fi

echo ""
echo "✅ Deployment verification completed!"