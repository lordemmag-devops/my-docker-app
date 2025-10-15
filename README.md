# Multi-Service Docker Application with Blue-Green Deployment

This is a comprehensive multi-service web application built with Docker, Kubernetes, and modern DevOps practices. It showcases a real-world implementation of containerized services, automated deployments, monitoring, and security measures. The application features a React frontend, Node.js backend, MongoDB database, Redis cache, Nginx reverse proxy, and integrated monitoring with Prometheus and Grafana. It supports both local Docker Compose development and Kubernetes production deployments via GitHub Actions CI/CD pipeline.

## 🏗️ Architecture Overview

The application follows a microservices architecture with the following components:

- **Frontend**: React.js single-page application served by Nginx
- **Backend**: Node.js Express API with MongoDB and Redis integration
- **Database**: MongoDB instance for data persistence
- **Cache**: Redis for session management and performance optimization
- **Reverse Proxy**: Nginx load balancer with blue-green deployment support
- **Monitoring**: Prometheus for metrics collection and Grafana for visualization
- **Security**: Containerized secrets management with Docker secrets

The deployment strategy uses blue-green methodology to ensure zero-downtime updates through GitHub Actions automation.

## ✨ Key Features

- **Multi-Stage Docker Builds**: Optimized images for production efficiency
- **Blue-Green Deployment**: Zero-downtime updates via automated CI/CD
- **Comprehensive Monitoring**: Prometheus metrics and Grafana dashboards
- **Security First**: Sensitive data handled via Docker secrets and gitignore
- **Scalable Architecture**: Ready for Kubernetes production deployment
- **Health Checks**: Automated service health monitoring
- **Container Orchestration**: Works with Docker Compose and Kubernetes

## 📋 Prerequisites

Before running the application, ensure you have:

- **Docker Engine** (version 20+ recommended)
- **Docker Compose** (V2 plugin)
- **Node.js** (18+ for development)
- **Git** for version control
- **kubectl** (for Kubernetes deployment)
- **AWS CLI** (if using ECR for image registry)

## 📁 Project Structure

```
my-docker-app/
├── backend/                 # Node.js Express API service
│   ├── Dockerfile
│   ├── index.js
│   ├── config.js
│   ├── package.json
│   └── models/
│       └── User.js
├── frontend/                # React.js SPA application
│   ├── Dockerfile
│   ├── package.json
│   ├── src/
│   │   ├── App.js
│   │   ├── components/
│   │   │   ├── Chat.js
│   │   │   ├── Register.js
│   │   │   └── ...
│   │   └── config.js
│   └── public/
│       └── index.html
├── k8s/                    # Kubernetes manifests
│   ├── kustomization.yaml
│   ├── ingress.yaml
│   ├── secrets.yaml
│   ├── backend.yaml
│   ├── frontend.yaml
│   ├── nginx.yaml
│   ├── db.yaml
│   └── cache.yaml
├── nginx/                  # Nginx reverse proxy configuration
│   ├── Dockerfile
│   └── nginx.conf
├── .github/workflows/      # GitHub Actions CI/CD pipeline
│   └── deploy.yml
├── base-node/              # Custom Node.js base image
│   └── Dockerfile
├── .gitignore              # Excludes sensitive files (passwords, logs)
├── docker-compose.yml      # Local development orchestration
├── prometheus.yml          # Monitoring configuration
├── aws-deployment-policy.json  # AWS IAM policy for deployments
├── db-password.txt         # MongoDB password (local only)
└── README.md
```

## 🚀 Quick Start

### Local Development Setup

1. **Clone the Repository**
   ```bash
   git clone <repository-url>
   cd my-docker-app
   ```

2. **Create Required Secret Files**
   ```bash
   # Database password
   echo "your-strong-mongo-password" > db-password.txt
   ```

3. **Launch Application**
   ```bash
   docker compose up -d --build
   ```

4. **Verify Services**
   ```bash
   docker compose ps
   ```

### Access the Application

- **Frontend**: http://localhost:3001
- **API**: http://localhost/api/
- **Monitoring**:
  - Prometheus: http://localhost:9090
  - Grafana: http://localhost:3000 (admin/admin123 - change immediately!)

## 🔧 Configuration

### Environment Variables

The application uses environment variables for configuration:

```yaml
# Backend Configuration (via docker-compose.yml)
NODE_ENV: production
PORT: 3000
MONGO_URI: mongodb://db:27017/myapp
REDIS_HOST: cache

# Frontend Configuration (via config.js)
REACT_APP_API_URL: /api
```

### Docker Secrets

Sensitive data is managed through Docker secrets:
- `db-password.txt`: MongoDB root password
- `grafana-admin-password.txt`: Grafana admin credentials (create locally, gitignored)

### Service Health Checks

All services include built-in health checks:
- **Sleep Duration**: 30s initial delay, 10s interval
- **Timeout**: 10s
- **Retries**: 3

## 🐳 Docker Compose Deployment

For local development, the application uses `docker-compose.yml`:

```yaml
version: '3.8'
services:
  web:
    build: ./frontend
    ports:
      - "80:80"
  api:
    build: ./backend
    environment:
      - NODE_ENV=production
  prometheus:
    image: prom/prometheus:latest
    ports:
      - "9090:9090"
```

Run with:
```bash
docker compose up -d --build
docker compose logs -f  # Optional: tail logs
docker compose down     # Stop services
```

## ☸️ Kubernetes Deployment

For production, deploy using Kubernetes manifests:

### Prerequisites
- Kubernetes cluster (EKS, GKE, or self-managed)
- AWS ECR access (if using AWS)
- kubectl configured

### Deployment Steps

1. **Apply Kustomization**
   ```bash
   kubectl apply -k k8s/
   ```

2. **Verify Deployment**
   ```bash
   kubectl get pods
   kubectl get services
   kubectl get ingress
   ```

3. **Access Application**
   ```bash
   kubectl get ingress
   # Use the EXTERNAL-IP from output
   ```

### Kustomization Features

The `kustomization.yaml` includes:
- Environment-specific overlays
- Secret management via Sealed Secrets
- Resource requests and limits
- Health check configurations

## 🔄 CI/CD Pipeline

Automated deployments using GitHub Actions:

### Pipeline Flow
1. **Trigger**: Push to main branch or PR merge
2. **Build**: Multi-stage Docker builds for frontend and backend
3. **Test**: Run linting and unit tests (if implemented)
4. **Security**: Scan images for vulnerabilities
5. **Deploy**: Blue-green deployment to production
6. **Monitor**: Update monitoring alerts

### Blue-Green Strategy
- **Active Environment**: Serves live traffic
- **Inactive Environment**: Receives new deployment
- **Traffic Switch**: Only switches after health checks pass
- **Rollback**: Automatic rollback on deployment failure

### Deployment States
- **Blue Environment**: Currently serving traffic
- **Green Environment**: Ready to be promoted
- **Traffic Direction**: Controlled via Nginx configuration

## 📊 Monitoring & Observability

### Prometheus Metrics
Scrapes metrics from all services:
- Container resource usage
- Application performance
- Custom business metrics
- Health check status

### Grafana Dashboards
Pre-configured dashboards for:
- System metrics (CPU, memory, disk)
- Application metrics (requests, errors, latency)
- Business metrics (user registrations, chat interactions)

Access monitoring stack:
- Prometheus: http://your-domain:9090
- Grafana: http://your-domain:3000
- Metrics endpoint: /metrics on each service

## 🔒 Security Considerations

### Docker Security
- **Non-root users**: Services run under application user
- **Minimal images**: Alpine-based images for smaller attack surface
- **Secret management**: Docker secrets for database credentials

### Network Security
- **Internal networks**: Services communicate via Docker networks
- **Port exposure**: Only necessary ports exposed
- **Reverse proxy**: Nginx filters external requests

### Git Security
- **Gitignored secrets**: Password files excluded from version control
- **Branch protection**: Main branch requires PR approval
- **Code scanning**: Automated security checks

## 🐛 Troubleshooting

### Common Issues

#### Connection Refused
```bash
# Check service health
docker compose ps
kubectl get pods --all-namespaces

# View logs
docker compose logs <service-name>
kubectl logs <pod-name>
```

#### Database Connection Issues
- Verify `db-password.txt` exists
- Check MongoDB service status
- Confirm network connectivity

#### Deployment Failures
- Review GitHub Actions logs
- Check ECR permissions
- Verify Kubernetes cluster access

#### Monitoring Issues
- Ensure Grafana password file exists
- Check Prometheus configuration
- Verify scraping endpoints

### Useful Commands

```bash
# Development
docker compose build --no-cache  # Fresh build
docker compose exec api bash     # Access container
docker system df                 # Disk usage

# Production
kubectl describe pod <pod-name>  # Debug pods
kubectl logs -f <pod-name>       # Follow logs
kubectl scale deployment api --replicas=2  # Scaling

# Monitoring
curl localhost:9090/-/healthy    # Prometheus health
```

## 🤝 Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/new-feature`)
3. Commit changes (`git commit -m 'Add new feature'`)
4. Push to branch (`git push origin feature/new-feature`)
5. Create Pull Request

### Development Guidelines
- Follow existing code style
- Add tests for new features
- Update documentation
- Run `docker compose` for testing

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🔗 Resources

- [Docker Documentation](https://docs.docker.com)
- [Kubernetes Documentation](https://kubernetes.io/docs)
- [Blue-Green Deployment Guide](https://roadmap.sh/projects/blue-green-deployment)
- [Multi-Service Docker Setup](https://roadmap.sh/projects/multiservice-docker)

## 🎯 Future Enhancements

- [ ] Dynamic service discovery
- [ ] Auto-scaling policies
- [ ] Advanced monitoring dashboards
- [ ] API gateway integration
- [ ] Multi-region deployment
- [ ] Automated testing pipeline

---

Built with ❤️ using Docker, Kubernetes, and modern DevOps practices.
