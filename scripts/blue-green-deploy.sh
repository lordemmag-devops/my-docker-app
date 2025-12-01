#!/bin/bash

# Blue-Green Deployment Script
set -e

STATE_FILE=".current_env"
BACKUP_FILE=".previous_env"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Get current environment
get_current_env() {
    if [ -f "$STATE_FILE" ]; then
        cat "$STATE_FILE"
    else
        echo "blue"
    fi
}

# Get target environment
get_target_env() {
    current=$(get_current_env)
    if [ "$current" = "blue" ]; then
        echo "green"
    else
        echo "blue"
    fi
}

# Health check function
health_check() {
    local env=$1
    local port=$([ "$env" = "blue" ] && echo "3001" || echo "3002")
    local max_attempts=30
    local attempt=1

    log "Performing health check for $env environment (port $port)..."
    
    while [ $attempt -le $max_attempts ]; do
        if curl -sf "http://localhost:$port/health" > /dev/null 2>&1; then
            success "$env environment is healthy"
            return 0
        fi
        
        log "Attempt $attempt/$max_attempts failed, retrying in 5 seconds..."
        sleep 5
        ((attempt++))
    done
    
    error "$env environment failed health check after $max_attempts attempts"
    return 1
}

# Deploy to target environment
deploy() {
    local target_env=$(get_target_env)
    local current_env=$(get_current_env)
    
    log "Starting blue-green deployment..."
    log "Current environment: $current_env"
    log "Target environment: $target_env"
    
    # Update target environment
    log "Updating $target_env environment..."
    docker compose up -d web-$target_env api-$target_env
    
    # Wait for services to start
    sleep 10
    
    # Health check
    if ! health_check "$target_env"; then
        error "Deployment failed - $target_env environment is not healthy"
        return 1
    fi
    
    # Switch traffic
    log "Switching traffic to $target_env environment..."
    
    # Update nginx configuration to point to new environment
    sed -i.bak "s/web-$current_env/web-$target_env/g" nginx/nginx.conf
    sed -i.bak "s/api-$current_env/api-$target_env/g" nginx/nginx.conf
    
    # Reload nginx
    docker compose restart app
    sleep 5
    
    # Final health check
    if curl -sf "http://localhost:80" > /dev/null; then
        # Save previous environment for rollback
        echo "$current_env" > "$BACKUP_FILE"
        echo "$target_env" > "$STATE_FILE"
        
        success "Blue-green deployment completed successfully!"
        success "Active environment: $target_env"
        log "Previous environment ($current_env) kept running for rollback"
        
        return 0
    else
        error "Final health check failed - rolling back"
        rollback
        return 1
    fi
}

# Rollback function
rollback() {
    local current_env=$(get_current_env)
    local previous_env
    
    if [ -f "$BACKUP_FILE" ]; then
        previous_env=$(cat "$BACKUP_FILE")
    else
        previous_env=$([ "$current_env" = "blue" ] && echo "green" || echo "blue")
    fi
    
    warn "Rolling back to $previous_env environment..."
    
    # Restore nginx configuration
    sed -i.bak "s/web-$current_env/web-$previous_env/g" nginx/nginx.conf
    sed -i.bak "s/api-$current_env/api-$previous_env/g" nginx/nginx.conf
    
    # Reload nginx
    docker compose restart app
    sleep 5
    
    # Update state
    echo "$previous_env" > "$STATE_FILE"
    
    if curl -sf "http://localhost:80" > /dev/null; then
        success "Rollback completed successfully!"
        success "Active environment: $previous_env"
    else
        error "Rollback failed - manual intervention required"
        return 1
    fi
}

# Main execution
case "${1:-deploy}" in
    "deploy")
        deploy
        ;;
    "rollback")
        rollback
        ;;
    "status")
        bash status.sh
        ;;
    *)
        echo "Usage: $0 {deploy|rollback|status}"
        echo "  deploy  - Deploy to inactive environment and switch traffic"
        echo "  rollback - Rollback to previous environment"
        echo "  status  - Show current deployment status"
        exit 1
        ;;
esac