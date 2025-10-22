#!/bin/bash

set -e

echo "🚀 Setting up AWS infrastructure for my-docker-app..."

# Check prerequisites
command -v terraform >/dev/null 2>&1 || { echo "❌ Terraform is required but not installed."; exit 1; }
command -v aws >/dev/null 2>&1 || { echo "❌ AWS CLI is required but not installed."; exit 1; }
command -v kubectl >/dev/null 2>&1 || { echo "❌ kubectl is required but not installed."; exit 1; }

# Get AWS account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION=${AWS_REGION:-us-west-2}

echo "📋 AWS Account ID: $AWS_ACCOUNT_ID"
echo "🌍 AWS Region: $AWS_REGION"

# Create S3 bucket for Terraform state
BUCKET_NAME="my-docker-app-terraform-state-$AWS_ACCOUNT_ID"
echo "🪣 Creating S3 bucket: $BUCKET_NAME"

aws s3api create-bucket \
  --bucket $BUCKET_NAME \
  --region $AWS_REGION \
  --create-bucket-configuration LocationConstraint=$AWS_REGION 2>/dev/null || echo "Bucket already exists"

aws s3api put-bucket-versioning \
  --bucket $BUCKET_NAME \
  --versioning-configuration Status=Enabled

aws s3api put-bucket-encryption \
  --bucket $BUCKET_NAME \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'

# Create DynamoDB table for Terraform locks
echo "🔒 Creating DynamoDB table for Terraform locks..."
aws dynamodb create-table \
  --table-name terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
  --region $AWS_REGION 2>/dev/null || echo "Table already exists"

# Update Terraform backend configuration
sed -i.bak "s/my-docker-app-terraform-state/$BUCKET_NAME/g" terraform/main.tf
sed -i.bak "s/us-west-2/$AWS_REGION/g" terraform/main.tf

# Initialize and apply Terraform
cd terraform
echo "🏗️ Initializing Terraform..."
terraform init

echo "📋 Planning Terraform deployment..."
terraform plan

echo "🚀 Applying Terraform configuration..."
terraform apply -auto-approve

# Get cluster info
CLUSTER_NAME=$(terraform output -raw cluster_name)
ECR_URL=$(terraform output -raw ecr_repository_url)

echo "✅ Infrastructure deployed successfully!"
echo "🎯 EKS Cluster: $CLUSTER_NAME"
echo "📦 ECR Repository: $ECR_URL"

# Update kubeconfig
echo "⚙️ Updating kubeconfig..."
aws eks update-kubeconfig --region $AWS_REGION --name $CLUSTER_NAME

echo "🎉 Setup complete! Your EKS cluster is ready."
echo ""
echo "Next steps:"
echo "1. Add these secrets to your GitHub repository:"
echo "   - AWS_ACCESS_KEY_ID"
echo "   - AWS_SECRET_ACCESS_KEY"
echo "2. Push your code to trigger the CI/CD pipeline"
echo "3. Monitor deployment in GitHub Actions"