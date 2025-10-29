#!/bin/bash

CURRENT_ENV=$(docker-compose exec -T app printenv WEB_HOST | cut -d'-' -f2 2>/dev/null || echo "unknown")

echo "📊 Blue-Green Deployment Status"
echo "================================"
echo "🎯 Active Environment: $CURRENT_ENV"
echo ""

# Check environment health
echo "🏥 Environment Health:"
for env in blue green; do
    port=$([ "$env" = "blue" ] && echo "3001" || echo "3002")
    status=$(curl -sf http://localhost:$port/health > /dev/null && echo "✅ Healthy" || echo "❌ Unhealthy")
    active=$([ "$env" = "$CURRENT_ENV" ] && echo " (ACTIVE)" || echo "")
    echo "  $env: $status$active"
done

echo ""
echo "🌐 Access URLs:"
echo "  Main App: http://localhost:80"
echo "  Blue API: http://localhost:3001"
echo "  Green API: http://localhost:3002"
echo "  Prometheus: http://localhost:9090"
echo "  Grafana: http://localhost:3005"