# AWS EKS Deployment Guide

## Prerequisites

1. **AWS CLI** configured with appropriate permissions
2. **Terraform** >= 1.0
3. **kubectl** 
4. **Docker**

## Quick Deploy

```bash
# 1. Deploy infrastructure
./scripts/setup-aws.sh

# 2. Setup GitHub OIDC (optional, for secure CI/CD)
./scripts/setup-github-oidc.sh
```

## GitHub Secrets Required

Add these secrets to your GitHub repository:

### Option 1: Access Keys (Simple)
```
AWS_ACCESS_KEY_ID: <your-access-key-id>
AWS_SECRET_ACCESS_KEY: <your-secret-access-key>
```

### Option 2: OIDC (Recommended)
```
AWS_ROLE_TO_ASSUME: arn:aws:iam::<account-id>:role/my-docker-app-cluster-github-actions
```

## Manual Deployment Steps

### 1. Create AWS Resources

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

### 2. Configure kubectl

```bash
aws eks update-kubeconfig --region us-west-2 --name my-docker-app-cluster
```

### 3. Deploy Applications

```bash
kubectl apply -f k8s/
```

### 4. Verify Deployment

```bash
kubectl get pods -n my-docker-app
kubectl get services -n my-docker-app
```

## Access Applications

```bash
# Get LoadBalancer URL
kubectl get service frontend -n my-docker-app

# Port forward for local access
kubectl port-forward service/frontend 3000:80 -n my-docker-app
```

## Monitoring

```bash
# Install monitoring stack
kubectl apply -f observability/

# Access Grafana
kubectl port-forward service/grafana 3000:80 -n monitoring
```

## Cleanup

```bash
# Delete Kubernetes resources
kubectl delete -f k8s/

# Destroy infrastructure
cd terraform
terraform destroy
```