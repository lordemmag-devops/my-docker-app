#!/bin/bash

# Automated Blue-Green Deployment Script
set -e

CURRENT=$(docker-compose exec -T app printenv WEB_HOST | cut -d'-' -f2 2>/dev/null || echo "blue")
TARGET=$([ "$CURRENT" = "blue" ] && echo "green" || echo "blue")

echo "🤖 Automated Blue-Green Deployment"
echo "📍 Current: $CURRENT → Target: $TARGET"

# Build target environment
echo "🔨 Building $TARGET environment..."
docker-compose build web-$TARGET api-$TARGET

# Deploy to target
echo "🚀 Deploying to $TARGET..."
docker-compose up -d web-$TARGET api-$TARGET

# Wait for startup
echo "⏳ Waiting for $TARGET to initialize..."
sleep 15

# Health check with retries
echo "🏥 Health checking $TARGET..."
PORT=$([ "$TARGET" = "blue" ] && echo "3001" || echo "3002")

for i in {1..10}; do
    if curl -sf http://localhost:$PORT/health > /dev/null; then
        echo "✅ $TARGET environment healthy"
        break
    fi
    if [ $i -eq 10 ]; then
        echo "❌ Health check failed after 10 attempts"
        docker-compose logs api-$TARGET
        exit 1
    fi
    echo "⏳ Attempt $i/10 - waiting..."
    sleep 5
done

# Switch traffic
echo "🔄 Switching traffic to $TARGET..."
bash switch-environment.sh $TARGET

# Verify deployment
echo "🧪 Verifying deployment..."
if curl -sf http://localhost:80 > /dev/null; then
    echo "✅ Deployment successful - $TARGET is active"
    
    # Auto-cleanup old environment
    echo "🗑️ Stopping old $CURRENT environment..."
    docker-compose stop web-$CURRENT api-$CURRENT
    
    echo "🎉 Automated deployment complete!"
else
    echo "❌ Deployment verification failed - rolling back..."
    bash rollback.sh
    exit 1
fi