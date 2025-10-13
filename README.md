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

2. **Create Secret Files**:
   - In the main project folder, create `db-password.txt` for the MongoDB password:
     ```bash
     echo "supersecret" > db-password.txt
     ```
   - Create `grafana-admin-password.txt` for the Grafana admin password:
     ```bash
     echo "anothersecret" > grafana-admin-password.txt
     ```
   - **Important**: Replace "supersecret" and "anothersecret" with strong, unique passwords, especially for production environments.

3. **Build and Run the Application**:
   - From the main project folder, execute the following command to build and start all services in the background:
     ```bash
     docker compose up -d --build
     ```
   - The `--build` flag ensures that your Docker images are rebuilt, incorporating any changes you might have made to the Dockerfiles or application code.
   - To view logs for all services:
     ```bash
     docker compose logs
     ```
   - To view logs for a specific service (e.g., `backend`):
     ```bash
     docker compose logs backend
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

## Deployment Troubleshooting and Fixes

During the setup and deployment of this project, several common issues were encountered and resolved within the GitHub Actions workflow (`.github/workflows/deploy.yml`). This section outlines these issues and their solutions.

### 1. SSH Connection Timeout
- **Issue**: Initial deployments failed due to SSH connection timeouts to the remote server.
- **Resolution**: While the root cause was not explicitly identified, adding a diagnostic `nc -vz` command helped confirm connectivity. Subsequent fixes for other issues implicitly resolved this by ensuring a stable SSH environment.

### 2. `docker: command not found`
- **Issue**: The `docker` command was not found on the remote server during script execution.
- **Resolution**: Ensured that `/usr/bin` and `/usr/local/bin` were explicitly added to the `PATH` environment variable within the SSH script, and confirmed `docker.io` was installed via `apt-get`.

### 3. `cd: No such file or directory`
- **Issue**: The `cd` command failed to change into the repository directory on the remote server.
- **Resolution**: Verified that the `REPO_DIR` variable was correctly constructed and used, ensuring the target directory existed before attempting to `cd` into it.

### 4. `docker: unknown command: docker compose`
- **Issue**: The `docker compose` command (Docker Compose V2 syntax) was used, but the remote server had an older `docker-compose` (V1) installed.
- **Resolution**: Initially, commands were adjusted to use `docker-compose` (V1 syntax). The long-term solution involves upgrading `docker-compose` to V2 on the server.

### 5. `Permission denied` for Docker Socket
- **Issue**: `docker-compose` commands failed with `PermissionError: [Errno 13] Permission denied` when trying to access the Docker socket.
- **Resolution**: All `docker-compose` commands were prefixed with `sudo` to ensure they ran with sufficient privileges.

### 6. `no basic auth credentials` for ECR Pull
- **Issue**: `docker-compose pull` failed to authenticate with Amazon ECR, even after `docker login` succeeded. This was due to `sudo` not inheriting the Docker credentials.
- **Resolution**: The `DOCKER_CONFIG` environment variable was explicitly set to point to the user's Docker configuration directory (`/home/${{ secrets.SERVER_USERNAME }}/.docker`) when running `sudo docker-compose` commands.

### 7. Missing `db-password.txt`
- **Issue**: `docker-compose up` failed because the `db-password.txt` file, used as a secret, did not exist on the remote server.
- **Resolution**: A step was added to the deployment script to create this file with a placeholder password if it does not exist.

### 8. `KeyError: 'ContainerConfig'` (Ongoing)
- **Issue**: Encountered a `KeyError: 'ContainerConfig'` during `docker-compose up` when attempting to recreate containers, specifically `my-docker-app_web-blue_1`. This typically indicates an incompatibility between the `docker-compose` version (1.29.2) and the Docker daemon or image configuration.
- **Current Status**: This issue is currently being addressed. The next step is to upgrade the `docker-compose` installation on the remote server to version 2.x (the `docker compose` plugin) to resolve this incompatibility.

## Conclusion

This is an open source project with the link: https://roadmap.sh/projects/multiservice-docker. The project is further updated for blue-green deployment method: https://roadmap.sh/projects/blue-green-deployment.
