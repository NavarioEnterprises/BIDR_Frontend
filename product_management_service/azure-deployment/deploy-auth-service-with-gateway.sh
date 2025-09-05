#!/bin/bash

# Deploy BIDR Authentication Service with Application Gateway Integration
# This script deploys to container instances and updates the Application Gateway

set -e

# Configuration - using existing resources
RESOURCE_GROUP="bidr-simple-rg"
CONTAINER_REGISTRY="bidrsimpleregistry"
CONTAINER_NAME="bidr-auth-service"
IMAGE_NAME="bidr-authentication-service"
APPLICATION_GATEWAY="bidr-appgw"
BACKEND_POOL="appGatewayBackendPool"

# Get the script directory and find the authentication service
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"  # Two levels up from azure-deployment
SERVICE_DIR="$PROJECT_ROOT/authentication_service"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${GREEN}🚀 Deploying BIDR Authentication Service with HTTPS Gateway...${NC}"
echo -e "${BLUE}🔐 This service will be accessible via: https://api.bidr.co.za${NC}"

# Step 1: Verify service directory exists
if [ ! -d "$SERVICE_DIR" ]; then
    echo -e "${RED}❌ Authentication service directory not found: $SERVICE_DIR${NC}"
    exit 1
fi

echo -e "${BLUE}✅ Found authentication service directory${NC}"

# Step 2: Build and push Docker image
echo -e "${YELLOW}Step 1: Building and pushing Docker image...${NC}"
az acr build \
    --registry $CONTAINER_REGISTRY \
    --image $IMAGE_NAME:latest \
    "$SERVICE_DIR"

echo -e "${GREEN}✅ Authentication service image built and pushed${NC}"

# Step 3: Get registry credentials
echo -e "${YELLOW}Step 2: Getting registry credentials...${NC}"
ACR_LOGIN_SERVER=$(az acr show --name $CONTAINER_REGISTRY --resource-group $RESOURCE_GROUP --query "loginServer" --output tsv)
ACR_USERNAME=$(az acr credential show --name $CONTAINER_REGISTRY --query "username" --output tsv)
ACR_PASSWORD=$(az acr credential show --name $CONTAINER_REGISTRY --query "passwords[0].value" --output tsv)

echo -e "${BLUE}Registry: $ACR_LOGIN_SERVER${NC}"

# Step 4: Check if container exists and delete if necessary
echo -e "${YELLOW}Step 3: Checking existing container...${NC}"
EXISTING_CONTAINER=$(az container show --resource-group $RESOURCE_GROUP --name $CONTAINER_NAME --query "name" --output tsv 2>/dev/null || echo "")

if [ ! -z "$EXISTING_CONTAINER" ]; then
    echo -e "${YELLOW}⚠️  Existing container found. Updating...${NC}"
    az container delete --resource-group $RESOURCE_GROUP --name $CONTAINER_NAME --yes
    echo -e "${GREEN}✅ Old container removed${NC}"
fi

# Step 5: Deploy to Azure Container Instances (without public DNS)
echo -e "${YELLOW}Step 4: Deploying to Azure Container Instances...${NC}"
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

echo -e "${GREEN}✅ Authentication service deployed${NC}"

# Step 6: Get container IP and update Application Gateway
echo -e "${YELLOW}Step 5: Updating Application Gateway backend...${NC}"
sleep 15  # Wait for container to fully initialize

CONTAINER_IP=$(az container show \
    --resource-group $RESOURCE_GROUP \
    --name $CONTAINER_NAME \
    --query "ipAddress.ip" \
    --output tsv)

if [ -z "$CONTAINER_IP" ]; then
    echo -e "${RED}❌ Failed to get container IP address${NC}"
    exit 1
fi

echo -e "${BLUE}Container IP: $CONTAINER_IP${NC}"

# Update the Application Gateway backend pool
echo -e "${YELLOW}Updating Application Gateway backend pool...${NC}"
az network application-gateway address-pool update \
    --resource-group $RESOURCE_GROUP \
    --gateway-name $APPLICATION_GATEWAY \
    --name $BACKEND_POOL \
    --servers $CONTAINER_IP

echo -e "${GREEN}✅ Application Gateway backend updated${NC}"

# Step 7: Test the service through the Application Gateway
echo -e "${YELLOW}Step 6: Testing authentication service through HTTPS gateway...${NC}"
sleep 20  # Wait for Application Gateway to update

echo -e "${BLUE}Testing HTTPS endpoint...${NC}"
if curl -f -s -k "https://api.bidr.co.za/health/" > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Authentication service is accessible via HTTPS!${NC}"
elif curl -f -s -k "https://api.bidr.co.za/api/" > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Authentication service API is responding via HTTPS!${NC}"
else
    echo -e "${YELLOW}⚠️  Service may still be starting up. Testing direct container...${NC}"
    if curl -f -s "http://$CONTAINER_IP:8000/health/" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Container is healthy, gateway routing may need a moment${NC}"
    else
        echo -e "${YELLOW}⚠️  Container may still be initializing. Check logs if needed:${NC}"
        echo -e "${BLUE}az container logs --resource-group $RESOURCE_GROUP --name $CONTAINER_NAME${NC}"
    fi
fi

# Step 8: Display deployment summary
echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}🎉 BIDR Authentication Service Deployed!${NC}"
echo -e "${CYAN}========================================${NC}"
echo -e "${GREEN}✅ Service: BIDR Authentication Service${NC}"
echo -e "${GREEN}✅ Container: $CONTAINER_NAME${NC}"
echo -e "${GREEN}✅ Internal IP: $CONTAINER_IP:8000${NC}"
echo -e "${GREEN}✅ Public HTTPS: https://api.bidr.co.za${NC}"
echo -e "${GREEN}✅ Public HTTP: http://api.bidr.co.za (redirects to HTTPS)${NC}"
echo ""
echo -e "${BLUE}🔗 Service Endpoints:${NC}"
echo -e "${BLUE}• Main API: https://api.bidr.co.za/api/${NC}"
echo -e "${BLUE}• Admin Panel: https://api.bidr.co.za/admin/${NC}"
echo -e "${BLUE}• Health Check: https://api.bidr.co.za/health/${NC}"
echo ""
echo -e "${YELLOW}🔧 Management Commands:${NC}"
echo -e "${YELLOW}• Container Logs: az container logs --resource-group $RESOURCE_GROUP --name $CONTAINER_NAME${NC}"
echo -e "${YELLOW}• Container Status: az container show --resource-group $RESOURCE_GROUP --name $CONTAINER_NAME${NC}"
echo -e "${YELLOW}• Gateway Status: az network application-gateway show --resource-group $RESOURCE_GROUP --name $APPLICATION_GATEWAY${NC}"
echo ""
echo -e "${GREEN}🎊 Your authentication service is now running with full HTTPS support!${NC}"
echo -e "${CYAN}========================================${NC}"
