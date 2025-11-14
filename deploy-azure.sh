#!/bin/bash
set -e

RESOURCE_GROUP="my-docker-app-rg"
CLUSTER_NAME="my-docker-app-aks"
LOCATION="eastus"
ACR_NAME="mydockerappcr$(date +%s)"

echo "🚀 Deploying to Azure"

# 1. Login to Azure
az login

# 2. Create resource group
az group create --name $RESOURCE_GROUP --location $LOCATION

# 3. Create ACR
az acr create --resource-group $RESOURCE_GROUP --name $ACR_NAME --sku Basic

# 4. Create AKS cluster (free tier)
az aks create \
  --resource-group $RESOURCE_GROUP \
  --name $CLUSTER_NAME \
  --node-count 1 \
  --node-vm-size Standard_B1s \
  --attach-acr $ACR_NAME \
  --generate-ssh-keys \
  --tier free

# 5. Get credentials
az aks get-credentials --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME

# 6. Login to ACR
az acr login --name $ACR_NAME

# 7. Build and push images
docker build -t $ACR_NAME.azurecr.io/backend:latest ./backend
docker build -t $ACR_NAME.azurecr.io/frontend:latest ./frontend
docker build -t $ACR_NAME.azurecr.io/nginx:latest ./nginx

docker push $ACR_NAME.azurecr.io/backend:latest
docker push $ACR_NAME.azurecr.io/frontend:latest
docker push $ACR_NAME.azurecr.io/nginx:latest

# 8. Update manifests
sed -i.bak "s|ACR_NAME|$ACR_NAME|g" k8s/azure/*.yaml

# 9. Deploy to AKS
kubectl apply -k k8s/azure/

# 10. Wait for deployment
kubectl wait --for=condition=available --timeout=300s deployment --all -n my-docker-app

# 11. Get external IP
kubectl get service nginx -n my-docker-app

echo "✅ Deployment complete!"
echo "Resource Group: $RESOURCE_GROUP"
echo "ACR: $ACR_NAME"