# 📊 Complete Monitoring Setup Guide - Prometheus First, Then Grafana

## 🎯 Part 1: Prometheus Setup & Verification

### Step 1: Verify Prometheus is Running
```bash
# Check if Prometheus container is running
docker-compose ps prometheus

# If not running, start it
docker-compose up -d prometheus
```

### Step 2: Access Prometheus UI
1. **Open browser**: http://localhost:9090
2. **You should see**: Prometheus web interface with navigation menu

### Step 3: Verify Prometheus Configuration
1. **Click**: `Status` → `Configuration` (top menu)
2. **Verify**: You should see your scrape configs for:
   - `chat-api-blue`
   - `chat-api-green`
   - `prometheus` (self-monitoring)

### Step 4: Check Targets Status
1. **Click**: `Status` → `Targets` (top menu)
2. **Verify targets are UP**:
   - ✅ `chat-api-blue (api-blue:3000)` - State: UP
   - ✅ `chat-api-green (api-green:3000)` - State: UP
   - ✅ `prometheus (localhost:9090)` - State: UP

### Step 5: Test Queries in Prometheus
1. **Click**: `Graph` (top menu)
2. **Test these queries**:

**Query 1 - Service Health:**
```promql
up{job=~"chat-api-.*"}
```
- **Expected**: Should return `1` for both blue and green APIs

**Query 2 - Memory Usage:**
```promql
node_app_process_resident_memory_bytes
```
- **Expected**: Should show memory usage in bytes

**Query 3 - CPU Usage:**
```promql
rate(node_app_process_cpu_seconds_total[5m])
```
- **Expected**: Should show CPU usage rate

### Step 6: Verify Metrics Collection
```bash
# Test API metrics endpoint directly
curl http://localhost:3001/metrics | head -10

# Should show metrics like:
# node_app_process_cpu_user_seconds_total
# node_app_process_resident_memory_bytes
```

---

## 🎨 Part 2: Grafana Setup (After Prometheus is Working)

### Step 1: Access Grafana
1. **Open browser**: http://localhost:3005
2. **Login**:
   - Username: `admin`
   - Password: `mypassword`

### Step 2: Add Prometheus Data Source
1. **Click**: Hamburger menu `☰` (top-left)
2. **Navigate**: `Administration` → `Data sources`
3. **Click**: `Add new data source`
4. **Select**: `Prometheus` (first option with orange logo)
5. **Configure**:
   - **Name**: `Prometheus`
   - **URL**: `http://prometheus:9090`
   - **Access**: `Server (default)` - should be pre-selected
6. **Scroll down** → **Click**: `Save & test`
7. **Success message**: "✅ Data source is working"

### Step 3: Create New Dashboard
1. **Click**: Hamburger menu `☰`
2. **Navigate**: `Dashboards`
3. **Click**: `New` → `New dashboard`
4. **Click**: `+ Add visualization`

### Step 4: Create First Panel - API Health
1. **Data source**: Select `Prometheus`
2. **Query**: 
   ```promql
   up{job=~"chat-api-.*"}
   ```
3. **Panel options** (right sidebar):
   - **Title**: `API Health Status`
   - **Description**: `Blue and Green API availability`
4. **Visualization**: Change from `Time series` to `Stat`
5. **Value options**:
   - **Show**: `All values`
   - **Fields**: `All fields`
6. **Standard options**:
   - **Unit**: `Short`
   - **Min**: `0`
   - **Max**: `1`
7. **Thresholds**:
   - **Red**: `0` to `0.5`
   - **Green**: `0.5` to `1`
8. **Click**: `Apply`

### Step 5: Add Second Panel - Memory Usage
1. **Click**: `Add` → `Visualization`
2. **Data source**: `Prometheus`
3. **Query**:
   ```promql
   node_app_process_resident_memory_bytes / 1024 / 1024
   ```
4. **Panel options**:
   - **Title**: `Memory Usage`
   - **Description**: `Memory consumption in MB`
5. **Visualization**: Keep as `Time series`
6. **Standard options**:
   - **Unit**: `Data` → `bytes(SI)`
7. **Click**: `Apply`

### Step 6: Add Third Panel - CPU Usage
1. **Click**: `Add` → `Visualization`
2. **Data source**: `Prometheus`
3. **Query**:
   ```promql
   rate(node_app_process_cpu_seconds_total[5m]) * 100
   ```
4. **Panel options**:
   - **Title**: `CPU Usage`
   - **Description**: `CPU utilization percentage`
5. **Standard options**:
   - **Unit**: `Misc` → `percent (0-100)`
6. **Click**: `Apply`

### Step 7: Add Fourth Panel - Request Rate
1. **Click**: `Add` → `Visualization`
2. **Data source**: `Prometheus`
3. **Query**:
   ```promql
   rate(node_app_http_requests_total[5m])
   ```
4. **Panel options**:
   - **Title**: `HTTP Request Rate`
   - **Description**: `Requests per second`
5. **Standard options**:
   - **Unit**: `Throughput` → `requests/sec (rps)`
6. **Click**: `Apply`

### Step 8: Save Dashboard
1. **Click**: `Save dashboard` (💾 icon in top bar)
2. **Dashboard settings**:
   - **Title**: `Chat App Monitoring`
   - **Description**: `Blue-Green Chat Application Metrics`
   - **Folder**: `General` (default)
   - **Tags**: `chat`, `nodejs`, `blue-green`
3. **Click**: `Save`

### Step 9: Configure Auto-Refresh
1. **Click**: Time range dropdown (top-right, shows "Last 6 hours")
2. **Set refresh interval**: `5s` or `10s`
3. **Set time range**: `Last 1 hour`
4. **Click**: `Apply time range`

### Step 10: Arrange Dashboard Layout
1. **Drag panels** to rearrange
2. **Resize panels** by dragging corners
3. **Suggested layout**:
   - Top row: API Health (left), Request Rate (right)
   - Bottom row: Memory Usage (left), CPU Usage (right)

---

## 🔍 Verification Checklist

### ✅ Prometheus Checklist:
- [ ] Prometheus UI accessible at http://localhost:9090
- [ ] All targets showing as UP in Status → Targets
- [ ] Queries return data in Graph tab
- [ ] Metrics endpoint responding: `curl http://localhost:3001/metrics`

### ✅ Grafana Checklist:
- [ ] Grafana UI accessible at http://localhost:3005
- [ ] Prometheus data source connected successfully
- [ ] Dashboard created with 4 panels
- [ ] All panels showing data (not "No data")
- [ ] Auto-refresh working
- [ ] Dashboard saved successfully

---

## 🚨 Troubleshooting

### Prometheus Issues:
```bash
# Check Prometheus logs
docker-compose logs prometheus

# Restart Prometheus
docker-compose restart prometheus

# Verify config syntax
docker-compose exec prometheus promtool check config /etc/prometheus/prometheus.yml
```

### Grafana Issues:
```bash
# Check Grafana logs
docker-compose logs grafana

# Reset Grafana password
docker-compose exec grafana grafana-cli admin reset-admin-password mypassword

# Restart Grafana
docker-compose restart grafana
```

### No Data in Panels:
1. **Check time range** - Set to "Last 1 hour"
2. **Verify Prometheus connection** - Data sources → Prometheus → Save & test
3. **Check query syntax** - Test queries in Prometheus UI first
4. **Wait for data** - Allow 1-2 minutes for metrics collection

---

## 🎉 Success!

You now have a complete monitoring setup:
- **Prometheus**: Collecting metrics from your chat application
- **Grafana**: Visualizing the metrics in real-time dashboards
- **Blue-Green Monitoring**: Track both environments
- **Real-time Updates**: Auto-refreshing every 5-10 seconds

**Access URLs:**
- **Prometheus**: http://localhost:9090
- **Grafana**: http://localhost:3005 (admin/mypassword)