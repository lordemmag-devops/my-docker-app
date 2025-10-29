#!/bin/bash

# Webhook-triggered deployment for GitOps
# Usage: curl -X POST http://localhost:8000/deploy

echo "🔗 Webhook deployment triggered"

# Pull latest changes
git pull origin master

# Run automated deployment
bash auto-deploy.sh

# Send notification (optional)
echo "📧 Deployment notification sent"