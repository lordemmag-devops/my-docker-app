#!/bin/bash

# Blue-Green Deployment Script
set -e

NAMESPACE="my-docker-app"
KUBECTL_CMD="kubectl"

# Function to get current active version
get_active_version() {
    $KUBECTL_CMD get service backend-active -n $NAMESPACE -o jsonpath='{.spec.selector.version}' 2>/dev/null || echo "blue"
}

# Function to get inactive version
get_inactive_version() {
    local active=$(get_active_version)
    if [ "$active" = "blue" ]; then
        echo "green"
    else
        echo "blue"
    fi
}

# Function to switch traffic
switch_traffic() {
    local new_version=$1
    echo "🔄 Switching traffic to $new_version environment..."
    
    # Update backend service selector
    $KUBECTL_CMD patch service backend-active -n $NAMESPACE -p '{"spec":{"selector":{"version":"'$new_version'"}}}'
    
    # Update frontend service selector
    $KUBECTL_CMD patch service frontend-active -n $NAMESPACE -p '{"spec":{"selector":{"version":"'$new_version'"}}}'
    
    echo "✅ Traffic switched to $new_version environment"
}

# Function to scale deployment
scale_deployment() {
    local version=$1
    local replicas=$2
    
    echo "📈 Scaling $version environment to $replicas replicas..."
    $KUBECTL_CMD scale deployment backend-$version -n $NAMESPACE --replicas=$replicas
    $KUBECTL_CMD scale deployment frontend-$version -n $NAMESPACE --replicas=$replicas
    
    if [ $replicas -gt 0 ]; then
        echo "⏳ Waiting for $version environment to be ready..."
        $KUBECTL_CMD wait --for=condition=available --timeout=300s deployment/backend-$version -n $NAMESPACE
        $KUBECTL_CMD wait --for=condition=available --timeout=300s deployment/frontend-$version -n $NAMESPACE
    fi
}

# Function to health check
health_check() {
    local version=$1
    echo "🏥 Performing health check on $version environment..."
    
    # Get a pod from the version to test
    local backend_pod=$($KUBECTL_CMD get pods -n $NAMESPACE -l app=backend,version=$version -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
    
    if [ -z "$backend_pod" ]; then
        echo "❌ No backend pods found for $version environment"
        return 1
    fi
    
    # Test health endpoint
    if $KUBECTL_CMD exec -n $NAMESPACE $backend_pod -- curl -f http://localhost:3000/health >/dev/null 2>&1; then
        echo "✅ Health check passed for $version environment"
        return 0
    else
        echo "❌ Health check failed for $version environment"
        return 1
    fi
}

# Main deployment logic
main() {
    local new_image_tag=${1:-latest}
    
    echo "🚀 Starting Blue-Green Deployment..."
    echo "📋 New image tag: $new_image_tag"
    
    local active_version=$(get_active_version)
    local inactive_version=$(get_inactive_version)
    
    echo "🔵 Current active version: $active_version"
    echo "🟢 Deploying to inactive version: $inactive_version"
    
    # Update image tags for inactive environment
    echo "🏗️ Updating images for $inactive_version environment..."
    $KUBECTL_CMD set image deployment/backend-$inactive_version -n $NAMESPACE backend=471112825200.dkr.ecr.us-east-1.amazonaws.com/my-docker-app-backend:$new_image_tag
    $KUBECTL_CMD set image deployment/frontend-$inactive_version -n $NAMESPACE frontend=471112825200.dkr.ecr.us-east-1.amazonaws.com/my-docker-app-frontend:$new_image_tag
    
    # Scale up inactive environment
    scale_deployment $inactive_version 2
    
    # Perform health check
    if health_check $inactive_version; then
        # Switch traffic to new version
        switch_traffic $inactive_version
        
        # Scale down old version
        echo "📉 Scaling down $active_version environment..."
        scale_deployment $active_version 0
        
        echo "🎉 Blue-Green deployment completed successfully!"
        echo "🔄 Active environment is now: $inactive_version"
    else
        echo "💥 Health check failed! Rolling back..."
        scale_deployment $inactive_version 0
        echo "🔙 Rollback completed. Active environment remains: $active_version"
        exit 1
    fi
}

# Script usage
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo "Usage: $0 [IMAGE_TAG]"
    echo "  IMAGE_TAG: Docker image tag to deploy (default: latest)"
    echo ""
    echo "Examples:"
    echo "  $0                    # Deploy latest tag"
    echo "  $0 v1.2.3            # Deploy specific version"
    echo ""
    echo "Current status:"
    echo "  Active version: $(get_active_version)"
    echo "  Inactive version: $(get_inactive_version)"
    exit 0
fi

# Run main function
main "$@"