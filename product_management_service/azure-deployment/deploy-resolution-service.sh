#!/bin/bash

# BIDR resolution Service Deployment Script
set -e
echo "🚀 Deploying BIDR resolution Service..."

RESOURCE_GROUP="bidr-simple-rg"
REGISTRY_NAME="bidrsimpleregistry"
CONTAINER_NAME="bidr-resolution-service"
IMAGE_NAME="bidr-resolution-service"
resolution_8004=8004

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
resolution_DIR="$(dirname "$SCRIPT_DIR")/resolution_service"

if [ ! -d "$resolution_DIR" ]; then
    echo "❌ resolution service directory not found at: $resolution_DIR"
    exit 1
fi

cd "$resolution_DIR"
echo "Changed to resolution service directory"

echo "Step 1: Building Docker image..."
az acr build --registry $REGISTRY_NAME --image "${IMAGE_NAME}:latest" .

echo "Step 2: Getting registry credentials..."
REGISTRY_SERVER="${REGISTRY_NAME}.azurecr.io"
REGISTRY_USERNAME=$(az acr credential show --name $REGISTRY_NAME --query username --output tsv)
REGISTRY_PASSWORD=$(az acr credential show --name $REGISTRY_NAME --query passwords[0].value --output tsv)

echo "Step 3: Deploying to Azure Container Instances..."
DNS_LABEL="bidr-resolution-$(date +%s)"
SECRET_KEY=$(python3 -c "import secrets; print(secrets.token_urlsafe(32))")
JWT_SECRET_KEY=$(python3 -c "import secrets; print(secrets.token_urlsafe(32))")

az container create \
    --resource-group $RESOURCE_GROUP \
    --name $CONTAINER_NAME \
    --image "${REGISTRY_SERVER}/${IMAGE_NAME}:latest" \
    --registry-login-server $REGISTRY_SERVER \
    --registry-username $REGISTRY_USERNAME \
    --registry-password $REGISTRY_PASSWORD \
    --dns-name-label $DNS_LABEL \
    --ports $resolution_8004 \
    --cpu 1 \
    --memory 1.5 \
    --restart-policy OnFailure \
    --os-type Linux \
    --environment-variables \
        SECRET_KEY="$SECRET_KEY" \
        DEBUG=False \
        ALLOWED_HOSTS="*" \
        DJANGO_SETTINGS_MODULE=resolution_service.settings \
        JWT_SECRET_KEY="$JWT_SECRET_KEY" \
        CORS_ALLOW_ALL_ORIGINS=True

echo "✅ resolution service deployed"

CONTAINER_INFO=$(az container show \
    --resource-group $RESOURCE_GROUP \
    --name $CONTAINER_NAME \
    --query '{ip: ipAddress.ip, fqdn: ipAddress.fqdn}' \
    --output json)

CONTAINER_FQDN=$(echo $CONTAINER_INFO | jq -r '.fqdn // "N/A"')
echo "🎉 resolution Service URL: http://${CONTAINER_FQDN}:${resolution_8004}"
echo "🎯 Health Check: curl http://${CONTAINER_FQDN}:${resolution_8004}/health/"
