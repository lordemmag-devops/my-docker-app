# EC2 Kubernetes Deployment Guide

Deploy the multi-service Docker application to EC2 with Kubernetes using kubeadm.

## Prerequisites

- AWS EC2 instance (t3.medium or larger recommended)
- Ubuntu 20.04+ or similar Linux distribution
- At least 2 CPU cores and 4GB RAM
- Security group allowing ports: 22, 80, 443, 30080, 6443

## Required GitHub Secrets

- `AWS_ACCESS_KEY_ID` - AWS access key with ECR permissions
- `AWS_SECRET_ACCESS_KEY` - AWS secret access key
- `SERVER_HOST` - EC2 instance public IP
- `SERVER_USERNAME` - EC2 username (usually `ubuntu`)
- `SERVER_SSH_KEY` - Private SSH key for EC2 access
- `DB_PASSWORD` - MongoDB password (optional)
- `GRAFANA_ADMIN_PASSWORD` - Grafana password (optional)

## Step 1: Launch EC2 Instance

1. Launch Ubuntu 20.04+ instance (t3.medium minimum)
2. Configure security group:
   ```
   SSH (22) - Your IP
   HTTP (80) - 0.0.0.0/0
   HTTPS (443) - 0.0.0.0/0
   Custom (30080) - 0.0.0.0/0  # NodePort for ingress
   Custom (6443) - Your IP      # Kubernetes API
   ```

## Step 2: Setup Kubernetes on EC2

SSH to your EC2 instance and run:

```bash
# Copy setup script to EC2
scp -i your-key.pem ec2-k8s-setup.sh ubuntu@your-ec2-ip:~/

# SSH to EC2 and run setup
ssh -i your-key.pem ubuntu@your-ec2-ip
chmod +x ec2-k8s-setup.sh
./ec2-k8s-setup.sh

# Logout and login again for docker group changes
exit
ssh -i your-key.pem ubuntu@your-ec2-ip
```

## Step 3: Deploy Application

### Option A: Automatic via GitHub Actions

Push code to `master` branch. The workflow will:
1. Build and push images to ECR
2. SSH to EC2 and deploy to Kubernetes
3. Perform blue-green deployment

### Option B: Manual Deployment

```bash
# Clone repository
git clone https://github.com/your-username/my-docker-app.git
cd my-docker-app

# Deploy
kubectl apply -f k8s/namespace.yaml
kubectl apply -k k8s/

# Check status
kubectl get pods -n my-docker-app
```

## Step 4: Access Application

Access via EC2 public IP on NodePort:

- **Frontend**: `http://your-ec2-ip:30080/`
- **API**: `http://your-ec2-ip:30080/api/`

## Monitoring Access

Port forward to access monitoring:

```bash
# Prometheus
kubectl port-forward svc/prometheus 9090:9090 -n my-docker-app

# Grafana  
kubectl port-forward svc/grafana 3000:3000 -n my-docker-app
```

Then access via `http://your-ec2-ip:9090` and `http://your-ec2-ip:3000`

## Blue-Green Deployment

Use the deployment script:

```bash
cd k8s
./blue-green-deploy.sh
```

## Troubleshooting

### Common Issues

1. **Pods stuck in Pending**
   ```bash
   kubectl describe pod <pod-name> -n my-docker-app
   ```

2. **Ingress not working**
   ```bash
   kubectl get svc -n ingress-nginx
   kubectl logs -n ingress-nginx deployment/ingress-nginx-controller
   ```

3. **Node not ready**
   ```bash
   kubectl get nodes
   kubectl describe node
   ```

### Useful Commands

```bash
# Check cluster status
kubectl cluster-info

# View all resources
kubectl get all -n my-docker-app

# Check logs
kubectl logs -f deployment/backend-blue -n my-docker-app

# Port forward for testing
kubectl port-forward svc/backend-active 3000:3000 -n my-docker-app
```

## Cost Optimization

- Use t3.medium for development (~$30/month)
- Use spot instances for cost savings
- Stop instance when not in use

## Security

1. Restrict security group access
2. Use IAM roles instead of access keys when possible
3. Keep Kubernetes and Docker updated
4. Use network policies for pod-to-pod communication

## Cleanup

To remove everything:

```bash
kubectl delete namespace my-docker-app
sudo kubeadm reset
sudo rm -rf /etc/kubernetes/
```