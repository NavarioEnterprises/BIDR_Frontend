#!/bin/bash

# Quick Update BIDR Authentication Service with HTTPS Gateway
# This script rebuilds and redeploys the auth service with Application Gateway integration

set -e

# Configuration
RESOURCE_GROUP="bidr-simple-rg"
CONTAINER_REGISTRY="bidrsimpleregistry"
CONTAINER_NAME="bidr-auth-service"
IMAGE_NAME="bidr-authentication-service"
APPLICATION_GATEWAY="bidr-appgw"
BACKEND_POOL="appGatewayBackendPool"

# Get service directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"  # Two levels up from azure-deployment
SERVICE_DIR="$PROJECT_ROOT/authentication_service"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}🔄 Quick Update: BIDR Authentication Service${NC}"
echo -e "${BLUE}🔐 Updating: https://api.bidr.co.za${NC}"

# Step 1: Build new image
echo -e "${YELLOW}Step 1: Building updated image...${NC}"
az acr build \
    --registry $CONTAINER_REGISTRY \
    --image $IMAGE_NAME:latest \
    "$SERVICE_DIR"

echo -e "${GREEN}✅ New image built${NC}"

# Step 2: Get current container IP to preserve it
OLD_IP=$(az container show \
    --resource-group $RESOURCE_GROUP \
    --name $CONTAINER_NAME \
    --query "ipAddress.ip" \
    --output tsv 2>/dev/null || echo "")

# Step 3: Delete and recreate container
echo -e "${YELLOW}Step 2: Redeploying container...${NC}"

# Get registry credentials
ACR_LOGIN_SERVER=$(az acr show --name $CONTAINER_REGISTRY --resource-group $RESOURCE_GROUP --query "loginServer" --output tsv)
ACR_USERNAME=$(az acr credential show --name $CONTAINER_REGISTRY --query "username" --output tsv)
ACR_PASSWORD=$(az acr credential show --name $CONTAINER_REGISTRY --query "passwords[0].value" --output tsv)

# Delete old container
az container delete --resource-group $RESOURCE_GROUP --name $CONTAINER_NAME --yes 2>/dev/null || echo "No existing container"

# Create new container
az container create \
    --resource-group $RESOURCE_GROUP \
    --name $CONTAINER_NAME \
    --image $ACR_LOGIN_SERVER/$IMAGE_NAME:latest \
    --ports 8000 \
    --os-type Linux \
    --registry-login-server $ACR_LOGIN_SERVER \
    --registry-username $ACR_USERNAME \
    --registry-password $ACR_PASSWORD \
    --environment-variables \
        SECRET_KEY="$(openssl rand -base64 32)" \
        DEBUG=False \
        ALLOWED_HOSTS="*" \
        DJANGO_SETTINGS_MODULE=authentication_service.settings \
        JWT_SECRET_KEY="$(openssl rand -base64 32)" \
        CORS_ALLOW_ALL_ORIGINS=True \
    --cpu 1 \
    --memory 1.5 \
    --restart-policy OnFailure

echo -e "${GREEN}✅ Container redeployed${NC}"

# Step 4: Update Application Gateway with new IP
echo -e "${YELLOW}Step 3: Updating Application Gateway...${NC}"
sleep 15

NEW_IP=$(az container show \
    --resource-group $RESOURCE_GROUP \
    --name $CONTAINER_NAME \
    --query "ipAddress.ip" \
    --output tsv)

if [ ! -z "$NEW_IP" ]; then
    echo -e "${BLUE}New container IP: $NEW_IP${NC}"
    if [ ! -z "$OLD_IP" ] && [ "$OLD_IP" != "$NEW_IP" ]; then
        echo -e "${YELLOW}IP changed from $OLD_IP to $NEW_IP${NC}"
    fi
    
    # Update backend pool
    az network application-gateway address-pool update \
        --resource-group $RESOURCE_GROUP \
        --gateway-name $APPLICATION_GATEWAY \
        --name $BACKEND_POOL \
        --servers $NEW_IP
    
    echo -e "${GREEN}✅ Application Gateway updated${NC}"
else
    echo -e "${RED}❌ Failed to get new container IP${NC}"
    exit 1
fi

# Step 5: Quick health check
echo -e "${YELLOW}Step 4: Health check...${NC}"
sleep 20

if curl -f -s "https://api.bidr.co.za/health/" > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Service is healthy and accessible via HTTPS!${NC}"
elif curl -f -s "http://$NEW_IP:8000/health/" > /dev/null 2>&1; then
    echo -e "${YELLOW}⚠️  Container is healthy, gateway may need more time${NC}"
    echo -e "${BLUE}ℹ️  Try https://api.bidr.co.za in a minute${NC}"
else
    echo -e "${YELLOW}⚠️  Service starting up. Check logs if issues persist:${NC}"
    echo -e "${BLUE}az container logs --resource-group $RESOURCE_GROUP --name $CONTAINER_NAME${NC}"
fi

echo -e "${GREEN}🎉 Authentication Service Update Complete!${NC}"
echo -e "${BLUE}🔗 Service URL: https://api.bidr.co.za${NC}"
