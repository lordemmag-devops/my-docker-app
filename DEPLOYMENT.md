# AWS EKS Deployment Guide

This guide walks you through deploying the multi-service Docker application to AWS EKS (Elastic Kubernetes Service) with blue-green deployment strategy.

## Prerequisites

- AWS CLI configured with appropriate permissions
- Docker installed locally
- kubectl installed
- eksctl installed (will be installed by setup script if missing)
- GitHub repository with the required secrets

## Required GitHub Secrets

Ensure your GitHub repository has these secrets configured:

- `AWS_ACCESS_KEY_ID` - AWS access key with EKS permissions
- `AWS_SECRET_ACCESS_KEY` - AWS secret access key
- `DB_PASSWORD` - MongoDB password (optional, defaults to 'supersecret')
- `GRAFANA_ADMIN_PASSWORD` - Grafana admin password (optional, defaults to 'admin123')

## AWS Permissions Required

Your AWS user/role needs these permissions:
- EKS full access
- EC2 full access
- IAM permissions for creating roles and policies
- ECR full access
- CloudFormation access

## Step 1: Set Up AWS EKS Cluster

Run the setup script to create your EKS cluster:

```bash
chmod +x aws-setup.sh
./aws-setup.sh
```

This script will:
- Create an EKS cluster named `my-docker-app-cluster`
- Set up managed node groups with t3.medium instances
- Install AWS Load Balancer Controller
- Install NGINX Ingress Controller
- Configure kubectl

## Step 2: Verify Cluster Setup

```bash
# Check cluster status
kubectl cluster-info

# Check nodes
kubectl get nodes

# Check ingress controller
kubectl get svc -n ingress-nginx
```

## Step 3: Deploy Application

### Option A: Automatic Deployment via GitHub Actions

Push your code to the `master` or `main` branch. The GitHub Actions workflow will:
1. Build and push Docker images to ECR
2. Deploy to the inactive environment (blue/green)
3. Perform health checks
4. Switch traffic to the new environment
5. Scale down the old environment

### Option B: Manual Deployment

```bash
# Deploy using kubectl
kubectl apply -k k8s/

# Or use the deployment script
cd k8s
chmod +x deploy.sh
./deploy.sh
```

## Step 4: Access Your Application

Get the ingress URL:

```bash
kubectl get ingress -n my-docker-app
```

Access your services:
- **Frontend**: `http://<ingress-url>/`
- **API**: `http://<ingress-url>/api/`
- **Prometheus**: `http://<ingress-url>/prometheus`
- **Grafana**: `http://<ingress-url>/grafana`

## Blue-Green Deployment

### Manual Blue-Green Deployment

Use the blue-green deployment script:

```bash
cd k8s
chmod +x blue-green-deploy.sh

# Deploy latest images
./blue-green-deploy.sh

# Deploy specific version
./blue-green-deploy.sh v1.2.3

# Check current status
./blue-green-deploy.sh --help
```

### How Blue-Green Works

1. **Current State**: One environment (blue or green) serves traffic
2. **New Deployment**: Deploy to the inactive environment
3. **Health Check**: Verify the new deployment is healthy
4. **Traffic Switch**: Update service selectors to route traffic to new environment
5. **Cleanup**: Scale down the old environment

## Monitoring

### Prometheus Metrics

Access Prometheus at `http://<ingress-url>/prometheus` to view:
- Application metrics
- Kubernetes cluster metrics
- Custom business metrics

### Grafana Dashboards

Access Grafana at `http://<ingress-url>/grafana`:
- Username: `admin`
- Password: Value from `GRAFANA_ADMIN_PASSWORD` secret

## Scaling

### Manual Scaling

```bash
# Scale backend
kubectl scale deployment backend-blue --replicas=5 -n my-docker-app

# Scale frontend
kubectl scale deployment frontend-blue --replicas=3 -n my-docker-app
```

### Auto Scaling

Enable Horizontal Pod Autoscaler:

```bash
# Backend autoscaling
kubectl autoscale deployment backend-blue --cpu-percent=70 --min=2 --max=10 -n my-docker-app

# Frontend autoscaling
kubectl autoscale deployment frontend-blue --cpu-percent=70 --min=2 --max=8 -n my-docker-app
```

## Troubleshooting

### Common Issues

1. **Pods not starting**
   ```bash
   kubectl describe pod <pod-name> -n my-docker-app
   kubectl logs <pod-name> -n my-docker-app
   ```

2. **Ingress not working**
   ```bash
   kubectl get ingress -n my-docker-app
   kubectl describe ingress my-docker-app-ingress -n my-docker-app
   ```

3. **Health checks failing**
   ```bash
   kubectl exec -n my-docker-app <backend-pod> -- curl http://localhost:3000/health
   ```

### Useful Commands

```bash
# View all resources
kubectl get all -n my-docker-app

# Check events
kubectl get events -n my-docker-app --sort-by='.lastTimestamp'

# Port forward for local testing
kubectl port-forward svc/backend-active 3000:3000 -n my-docker-app
kubectl port-forward svc/frontend-active 8080:80 -n my-docker-app

# View logs
kubectl logs -f deployment/backend-blue -n my-docker-app
kubectl logs -f deployment/frontend-blue -n my-docker-app
```

## Cost Optimization

### Cluster Costs
- **t3.medium nodes**: ~$30/month per node
- **Load Balancer**: ~$18/month
- **EBS volumes**: ~$10/month per 100GB

### Optimization Tips
1. Use spot instances for non-production
2. Enable cluster autoscaler
3. Set resource requests and limits
4. Use smaller instance types for development

## Cleanup

To delete all AWS resources:

```bash
chmod +x aws-cleanup.sh
./aws-cleanup.sh
```

This will:
- Delete the application namespace
- Remove ingress controllers
- Delete the EKS cluster
- Clean up IAM policies

## Security Best Practices

1. **Network Security**
   - Use security groups to restrict access
   - Enable VPC flow logs
   - Use private subnets for worker nodes

2. **RBAC**
   - Implement role-based access control
   - Use service accounts with minimal permissions

3. **Secrets Management**
   - Use Kubernetes secrets for sensitive data
   - Consider AWS Secrets Manager integration
   - Rotate secrets regularly

4. **Image Security**
   - Scan images for vulnerabilities
   - Use minimal base images
   - Keep images updated

## Next Steps

1. Set up monitoring alerts
2. Implement backup strategies
3. Configure log aggregation
4. Set up disaster recovery
5. Implement security scanning
6. Add performance testing

For more information, refer to the main [README.md](README.md) file.