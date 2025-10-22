#!/bin/bash

set -e

echo "🔐 Setting up GitHub OIDC provider for AWS..."

# Get AWS account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Create OIDC provider for GitHub Actions
echo "📋 Creating OIDC provider..."
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1 \
  --client-id-list sts.amazonaws.com 2>/dev/null || echo "OIDC provider already exists"

echo "✅ GitHub OIDC provider configured!"
echo ""
echo "🔑 GitHub Secrets Required:"
echo "Add these to your GitHub repository secrets:"
echo ""
echo "AWS_ACCESS_KEY_ID: <your-access-key-id>"
echo "AWS_SECRET_ACCESS_KEY: <your-secret-access-key>"
echo ""
echo "Or use OIDC (recommended):"
echo "AWS_ROLE_TO_ASSUME: arn:aws:iam::$AWS_ACCOUNT_ID:role/my-docker-app-cluster-github-actions"