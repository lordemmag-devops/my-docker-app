#!/bin/bash

TARGET_ENV=${1:-green}
CURRENT_ENV=$(docker-compose exec -T app printenv WEB_HOST | cut -d'-' -f2)

echo "🔄 Switching from $CURRENT_ENV to $TARGET_ENV environment..."

# Health check target environment
echo "🏥 Health checking $TARGET_ENV environment..."
if ! curl -sf http://localhost:300$([ "$TARGET_ENV" = "blue" ] && echo "1" || echo "2")/health > /dev/null; then
    echo "❌ $TARGET_ENV environment health check failed. Aborting switch."
    exit 1
fi

# Update environment variables and reload nginx
docker-compose exec -T app sh -c "
    export WEB_HOST=web-$TARGET_ENV
    export API_HOST=api-$TARGET_ENV
    envsubst '\$WEB_HOST \$API_HOST' < /etc/nginx/templates/default.conf.template > /etc/nginx/conf.d/default.conf
    nginx -s reload
"

echo "✅ Traffic switched to $TARGET_ENV environment"
echo "🌐 Application: http://localhost:80"