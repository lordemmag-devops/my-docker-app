#!/bin/bash
set -e

echo "🚀 Installing Enterprise DevOps Stack..."

# 1. Deploy infrastructure with Terraform
echo "📦 Deploying infrastructure..."
cd terraform
terraform init
terraform plan -var="environment=prod"
terraform apply -auto-approve -var="environment=prod"
cd ..

# 2. Install ArgoCD
echo "🔄 Installing ArgoCD..."
./argocd/bootstrap.sh

# 3. Install security tools
echo "🔒 Installing security tools..."
# Falco
helm repo add falcosecurity https://falcosecurity.github.io/charts
helm install falco falcosecurity/falco --namespace falco-system --create-namespace

# OPA Gatekeeper
kubectl apply -f https://raw.githubusercontent.com/open-policy-agent/gatekeeper/release-3.14/deploy/gatekeeper.yaml
kubectl apply -f security/opa/

# Sealed Secrets
kubectl apply -f https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.24.0/controller.yaml

# 4. Install observability stack
echo "📊 Installing observability stack..."
kubectl create namespace logging --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -f observability/elk/
kubectl apply -f observability/fluentd/

# 5. Install backup tools
echo "💾 Installing backup tools..."
velero install \
    --provider aws \
    --plugins velero/velero-plugin-for-aws:v1.8.0 \
    --bucket my-docker-app-velero-backups \
    --backup-location-config region=us-west-2

kubectl apply -f backup/velero/
kubectl apply -f backup/mongodb/

# 6. Deploy applications
echo "🎯 Deploying applications..."
kubectl apply -f argocd/apps/

echo "✅ Installation complete!"