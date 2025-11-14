#!/bin/bash

STATE_FILE=".current_env"

# Get current environment from state file or default to blue
if [ -f "$STATE_FILE" ]; then
    CURRENT_ENV=$(cat "$STATE_FILE")
else
    CURRENT_ENV="blue"
fi

TARGET_ENV=$([ "$CURRENT_ENV" = "blue" ] && echo "green" || echo "blue")

echo "🚀 Blue-Green Deployment Started"
echo "📍 Current: $CURRENT_ENV → Target: $TARGET_ENV"

# Build new images for target environment
echo "🔨 Building $TARGET_ENV environment..."
docker-compose build web-$TARGET_ENV api-$TARGET_ENV

# Start target environment
echo "▶️  Starting $TARGET_ENV environment..."
docker-compose up -d web-$TARGET_ENV api-$TARGET_ENV

# Wait for target environment to be ready
echo "⏳ Waiting for $TARGET_ENV to be ready..."
sleep 10

# Health check
echo "🏥 Health checking $TARGET_ENV..."
API_PORT=$([ "$TARGET_ENV" = "blue" ] && echo "3001" || echo "3002")
if ! curl -sf http://localhost:$API_PORT/health > /dev/null; then
    echo "❌ Deployment failed - $TARGET_ENV unhealthy"
    exit 1
fi

# Switch traffic
echo "🔄 Switching traffic to $TARGET_ENV..."
./switch-environment.sh $TARGET_ENV

# Stop old environment (optional)
read -p "🗑️  Stop $CURRENT_ENV environment? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    docker-compose stop web-$CURRENT_ENV api-$CURRENT_ENV
    echo "🛑 $CURRENT_ENV environment stopped"
fi

echo "✅ Deployment complete - $TARGET_ENV is now active"