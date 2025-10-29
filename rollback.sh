#!/bin/bash

CURRENT_ENV=$(docker-compose exec -T app printenv WEB_HOST | cut -d'-' -f2 2>/dev/null || echo "blue")
ROLLBACK_ENV=$([ "$CURRENT_ENV" = "blue" ] && echo "green" || echo "blue")

echo "🔙 Rolling back from $CURRENT_ENV to $ROLLBACK_ENV"

# Check if rollback environment is running
if ! docker-compose ps | grep -q "web-$ROLLBACK_ENV.*Up"; then
    echo "▶️  Starting $ROLLBACK_ENV environment..."
    docker-compose up -d web-$ROLLBACK_ENV api-$ROLLBACK_ENV
    sleep 10
fi

# Health check rollback environment
API_PORT=$([ "$ROLLBACK_ENV" = "blue" ] && echo "3001" || echo "3002")
if ! curl -sf http://localhost:$API_PORT/health > /dev/null; then
    echo "❌ Rollback failed - $ROLLBACK_ENV unhealthy"
    exit 1
fi

# Switch traffic back
./switch-environment.sh $ROLLBACK_ENV

echo "✅ Rollback complete - $ROLLBACK_ENV is now active"