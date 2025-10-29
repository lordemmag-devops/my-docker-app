#!/bin/bash

echo "🔧 Complete Monitoring Setup - Prometheus First, Then Grafana"
echo "============================================================="

# Step 1: Ensure Prometheus is running
echo "📊 Step 1: Starting Prometheus..."
docker-compose up -d prometheus
sleep 5

# Step 2: Verify Prometheus
echo "🎯 Step 2: Verifying Prometheus targets..."
PROMETHEUS_STATUS=$(curl -s http://localhost:9090/-/healthy)
if [[ "$PROMETHEUS_STATUS" == "Prometheus Server is Healthy." ]]; then
    echo "✅ Prometheus is healthy"
else
    echo "❌ Prometheus is not responding"
    exit 1
fi

# Step 3: Check targets
echo "🔍 Step 3: Checking Prometheus targets..."
curl -s "http://localhost:9090/api/v1/query?query=up" | jq -r '.data.result[] | "  \(.metric.job): \(if .value[1] == "1" then "✅ UP" else "❌ DOWN" end)"'

# Step 4: Start Grafana
echo ""
echo "🎨 Step 4: Starting Grafana..."
docker-compose up -d grafana
sleep 10

# Step 5: Verify Grafana
echo "🌐 Step 5: Verifying Grafana..."
GRAFANA_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3005/api/health)
if [[ "$GRAFANA_STATUS" == "200" ]]; then
    echo "✅ Grafana is healthy"
else
    echo "❌ Grafana is not responding"
    exit 1
fi

echo ""
echo "🎉 Setup Complete!"
echo "=================="
echo "📊 Prometheus: http://localhost:9090"
echo "   - Check Status → Targets to verify all services are UP"
echo "   - Test queries in Graph tab"
echo ""
echo "🎨 Grafana: http://localhost:3005"
echo "   - Login: admin / mypassword"
echo "   - Add Prometheus data source: http://prometheus:9090"
echo "   - Create dashboards with the provided queries"
echo ""
echo "📖 Follow the complete guide: MONITORING-COMPLETE-SETUP.md"