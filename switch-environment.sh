#!/bin/bash

TARGET_ENV=${1:-green}
STATE_FILE=".current_env"

# Get current environment from state file or default to blue
if [ -f "$STATE_FILE" ]; then
    CURRENT_ENV=$(cat "$STATE_FILE")
else
    CURRENT_ENV="blue"
fi

echo "🔄 Switching from $CURRENT_ENV to $TARGET_ENV environment..."

# Health check target environment
echo "🏥 Health checking $TARGET_ENV environment..."
API_PORT=$([ "$TARGET_ENV" = "blue" ] && echo "3001" || echo "3002")
if ! curl -sf http://localhost:$API_PORT/health > /dev/null; then
    echo "❌ $TARGET_ENV environment health check failed. Aborting switch."
    exit 1
fi

# Update nginx configuration
echo "🔧 Updating nginx configuration..."
docker-compose exec -T app sh -c "
    sed -i 's/web-[a-z]*/web-$TARGET_ENV/g' /etc/nginx/conf.d/default.conf
    sed -i 's/api-[a-z]*/api-$TARGET_ENV/g' /etc/nginx/conf.d/default.conf
    nginx -s reload
"

# Save current environment state
echo "$TARGET_ENV" > "$STATE_FILE"

echo "✅ Traffic switched to $TARGET_ENV environment"
echo "🌐 Application: http://localhost:80"