# Multi-Service Docker Application

This project demonstrates a multi-service application built with Docker, showcasing advanced features like multi-stage builds, Docker Compose, an automated blue-green deployment pipeline using GitHub Actions, and comprehensive monitoring with Prometheus and Grafana. The application simulates a real-world scenario with interconnected services, optimized for performance, reliability, zero-downtime deployments, and observability.

## Project Overview

The application consists of several services:
- **Web Application**: A React-based frontend served via Nginx.
- **API Service**: A Node.js Express backend handling API requests.
- **Database**: A MongoDB instance for persistent data storage (not included in the blue-green setup for simplicity, but would use a shared, managed database in production).
- **Cache**: A Redis instance for performance optimization.
- **Reverse Proxy**: An Nginx server that routes incoming requests to the active "blue" or "green" environment.
- **Prometheus**: A monitoring system that collects metrics from all services.
- **Grafana**: A visualization tool for the metrics collected by Prometheus.

## Features

- **Docker Compose**: Orchestrates all services with a single configuration file.
- **Custom Base Image**: A lightweight `base-node` image for Node.js services.
- **Multi-Stage Builds**: Optimizes the frontend image size by separating build and runtime environments.
- **Docker Network**: A bridge network (`app-net`) ensures secure communication between services.
- **Volumes**: Persistent storage for MongoDB (`db-data`) and Redis (`cache-data`).
- **Secrets**: Secure handling of sensitive data (e.g., MongoDB password via `db-password.txt`).
- **Blue-Green Deployments**: Automated, zero-downtime deployments orchestrated by GitHub Actions.
- **Monitoring**: Integrated Prometheus for metric collection and Grafana for dashboard visualization.
- **Health Checks**: Monitors service availability to ensure reliability.
- **Optimized Dockerfiles**: Reduces image sizes and build times.
- **Logging**: Configured with log rotation to manage log file sizes.

## Prerequisites

Before running the project, ensure you have the following installed:
- **Docker**: Download and install [Docker Desktop](https://www.docker.com/products/docker-desktop) for your operating system (Windows, Mac, or Linux).
- **Docker Compose**: Included with Docker Desktop. Verify with `docker compose version`.
- **Git** (optional): For cloning or managing the project. Install from [git-scm.com](https://git-scm.com).

## Project Structure

```plaintext
my-docker-app/
├── .github/
│   └── workflows/
│       └── deploy.yml
├── backend/
│   ├── Dockerfile
│   ├── index.js
│   ├── package.json
│   └── ...
├── base-node/
│   ├── Dockerfile
├── frontend/
│   ├── Dockerfile
│   ├── src/
│   ├── package.json
│   └── ...
├── nginx/
│   ├── Dockerfile
│   ├── nginx.conf
├── docker-compose.yml
├── db-password.txt
├── grafana-admin-password.txt
├── prometheus.yml
└── README.md
```

- `backend/`: Node.js Express API service.
- `base-node/`: Custom Node.js base image.
- `frontend/`: React frontend served by Nginx.
- `nginx/`: Nginx reverse proxy configuration.
- `docker-compose.yml`: Defines and orchestrates all services.
- `db-password.txt`: Contains the MongoDB password (secret).
- `grafana-admin-password.txt`: Contains the Grafana admin password (secret).
- `prometheus.yml`: Prometheus configuration for scraping metrics.
- `.github/workflows/deploy.yml`: GitHub Actions workflow for blue-green deployments.

## Setup Instructions

1. **Clone the Project**:
   ```bash
   git clone <repository-url>
   cd my-docker-app
   ```

2. **Create the MongoDB Password Secret**:
   - In the main project folder, create `db-password.txt`:
     ```bash
     echo "supersecret" > db-password.txt
     ```
   - Replace "supersecret" with a secure password for production.

3. **Build and Run the Application**:
   - From the main project folder:
     ```bash
     docker compose up -d
     ```
   - This builds and starts all services in the background.
   - To view logs:
     ```bash
     docker compose logs
     ```

4. **Access the Application**:
   - Open a browser and visit:
     - Frontend: `http://localhost`
     - API: `http://localhost/api/`
   - The API should respond with "Hello from API!".

5. **Access Monitoring Dashboards**:
   - Prometheus: `http://localhost:9090`
   - Grafana: `http://localhost:3000` (Login with `admin` and the password from `grafana-admin-password.txt`)

6. **Stop the Application**:
   ```bash
   docker compose down
   ```

## Configuration Details

### Docker Compose
The `docker-compose.yml` defines the services for the application, including separate services for blue and green environments to enable zero-downtime deployments.
- `base-node`: Custom Node.js base image.
- `web-blue` / `web-green`: React frontend instances.
- `api-blue` / `api-green`: Node.js Express backend instances.
- `db`: MongoDB database.
- `cache`: Redis cache.
- `proxy-blue` / `proxy-green`: Nginx reverse proxy instances that control which environment is live.
- `prometheus`: Prometheus server for collecting and storing metrics.
- `grafana`: Grafana server for visualizing metrics.

Key features:
- **Networks**: All services use the `app-net` bridge network for communication.
- **Volumes**: `db-data` and `cache-data` ensure persistent storage. Prometheus and Grafana also use volumes for persistent data.
- **Secrets**: MongoDB password is securely passed via `db-password.txt`, and Grafana admin password via `grafana-admin-password.txt`.
- **Health Checks**: Each service has a health check to monitor status.
- **Logging**: Configured with `json-file` driver and log rotation (`max-size: "10m"`, `max-file: "3"`).

### Backend Code
Example `backend/index.js`:
```javascript
const express = require('express');
const mongoose = require('mongoose');
const redis = require('redis');

const app = express();
app.get('/', (req, res) => res.send('Hello from API!'));

mongoose.connect('mongodb://db:27017/mydb', { useNewUrlParser: true });
const client = redis.createClient({ host: 'cache' });
client.on('error', err => console.error('Redis error:', err));
client.connect();

app.listen(3000, () => console.log('API running'));
```

### Nginx Configuration
The `nginx/nginx.conf` routes traffic:
- `/` → `web` service (frontend).
- `/api/` → `api` service (backend).

Example:
```nginx
events {}
http {
    server {
        listen 80;
        location / {
            proxy_pass http://web:80;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
        }
        location /api/ {
            proxy_pass http://api:3000/;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_connect_timeout 10s;
            proxy_read_timeout 10s;
        }
    }
}
```

## Monitoring with Prometheus and Grafana

The project includes Prometheus for collecting metrics and Grafana for visualizing them.

- **Prometheus (`prometheus.yml`)**: Configured to scrape metrics from all application services (web, api, db, cache, proxy) in both blue and green environments.
- **Grafana (`grafana-admin-password.txt`)**: Provides a dashboard interface to visualize the data collected by Prometheus. The admin password is stored in `grafana-admin-password.txt`.

To access:
- Prometheus UI: `http://localhost:9090`
- Grafana UI: `http://localhost:3000` (Login with `admin` and the password from `grafana-admin-password.txt`)

## Automated Blue-Green Deployments with GitHub Actions

This project utilizes GitHub Actions for automated blue-green deployments, ensuring zero-downtime updates. The workflow is defined in `.github/workflows/deploy.yml`.

**Workflow Steps:**
1.  **Checkout Code**: Fetches the repository content.
2.  **Set up Docker Buildx**: Configures Docker Buildx for efficient image building.
3.  **Configure AWS Credentials & Login to ECR**: Sets up AWS access and logs into Amazon Elastic Container Registry (ECR).
4.  **Determine Active/Inactive Environments**: Identifies which of the "blue" or "green" environments is currently serving live traffic on the remote server.
5.  **Build, Tag, and Push Images to ECR**: Builds Docker images for the backend and frontend, tags them with the commit SHA and `latest`, and pushes them to ECR.
6.  **Deploy to Server**: Connects to the remote server via SSH and performs the following:
    *   Installs AWS CLI if not already present.
    *   Logs into ECR on the server.
    *   Pulls the latest code from the repository.
    *   Deploys the new versions of the `web` and `api` services to the *inactive* environment.
    *   Builds the `proxy` for the inactive environment locally on the server.
    *   Performs health checks on the newly deployed inactive environment.
    *   If health checks pass, traffic is switched by stopping the `proxy` of the *active* environment and starting the `proxy` of the *inactive* environment, making the new version live.
    *   If health checks fail, the deployment is aborted, and the active environment continues to serve traffic.

## Best Practices Demonstrated

- **Image Optimization**: Multi-stage builds for the frontend reduce image size.
- **Security**: Docker secrets for sensitive data like database passwords and Grafana admin password.
- **Reliability**: Health checks ensure services are operational and blue-green deployments provide zero-downtime updates.
- **Scalability**: Docker Compose and networks enable easy scaling.
- **Maintainability**: Log rotation prevents disk space issues.
- **Observability**: Integrated monitoring with Prometheus and Grafana.

## Conclusion

This is an open source project with the link: https://roadmap.sh/projects/multiservice-docker. The project is further updated for blue-green deployment method: https://roadmap.sh/projects/blue-green-deployment.
