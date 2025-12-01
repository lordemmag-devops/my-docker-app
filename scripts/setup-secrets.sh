#!/bin/bash

# Secure secrets setup script
set -e

echo "🔐 Setting up secure secrets..."

# Generate secure passwords
DB_PASSWORD=$(openssl rand -base64 32)
GRAFANA_PASSWORD=$(openssl rand -base64 16)
JWT_SECRET=$(openssl rand -base64 64)

# Create secrets directory if it doesn't exist
mkdir -p secrets

# Write secrets to files with proper permissions
echo "$DB_PASSWORD" > secrets/db-password.txt
echo "$GRAFANA_PASSWORD" > secrets/grafana-admin-password.txt
echo "$JWT_SECRET" > secrets/jwt-secret.txt

# Set restrictive permissions
chmod 600 secrets/*.txt
chmod 700 secrets/

# Update docker-compose to use secrets directory
if [ -f "docker-compose.yml" ]; then
    sed -i.bak 's|./grafana-admin-password.txt|./secrets/grafana-admin-password.txt|g' docker-compose.yml
    echo "✅ Updated docker-compose.yml to use secrets directory"
fi

# Create .env file for environment variables
cat > .env << EOF
# Database Configuration
MONGO_INITDB_ROOT_USERNAME=admin
MONGO_INITDB_ROOT_PASSWORD_FILE=/run/secrets/db-password

# Application Configuration
NODE_ENV=production
JWT_SECRET_FILE=/run/secrets/jwt-secret

# Monitoring
GF_SECURITY_ADMIN_USER=admin
GF_SECURITY_ADMIN_PASSWORD_FILE=/run/secrets/grafana-admin-password
EOF

echo "✅ Secrets generated and configured"
echo "📝 Passwords stored in secrets/ directory with restricted permissions"
echo "⚠️  Add secrets/ to .gitignore to prevent committing sensitive data"

# Add to gitignore if not already present
if ! grep -q "secrets/" .gitignore 2>/dev/null; then
    echo "secrets/" >> .gitignore
    echo "✅ Added secrets/ to .gitignore"
fi