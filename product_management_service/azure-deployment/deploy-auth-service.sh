#!/bin/bash

# Deploy BIDR Authentication Service to existing Azure resources
# Uses the same resource group and container registry as product service

set -e

# Configuration - using existing resources
RESOURCE_GROUP="bidr-simple-rg"
CONTAINER_REGISTRY="bidrsimpleregistry"
CONTAINER_NAME="bidr-auth-service"
IMAGE_NAME="bidr-authentication-service"
# Get the script directory and find the authentication service
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"  # Two levels up from azure-deployment
SERVICE_DIR="$PROJECT_ROOT/authentication_service"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}🚀 Deploying BIDR Authentication Service...${NC}"
echo -e "${YELLOW}⚠️  This script uses the old deployment method.${NC}"
echo -e "${BLUE}For HTTPS support, use: deploy-auth-service-with-gateway.sh${NC}"
echo ""

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

# Step 4: Deploy to Azure Container Instances
echo -e "${YELLOW}Step 3: Deploying to Azure Container Instances...${NC}"
az container create \
    --resource-group $RESOURCE_GROUP \
    --name $CONTAINER_NAME \
    --image $ACR_LOGIN_SERVER/$IMAGE_NAME:latest \
    --dns-name-label bidr-auth-$(date +%s) \
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

# Step 5: Get deployment information
echo -e "${YELLOW}Step 4: Getting deployment information...${NC}"
sleep 10  # Wait for deployment to initialize

FQDN=$(az container show \
    --resource-group $RESOURCE_GROUP \
    --name $CONTAINER_NAME \
    --query "ipAddress.fqdn" \
    --output tsv)

PUBLIC_IP=$(az container show \
    --resource-group $RESOURCE_GROUP \
    --name $CONTAINER_NAME \
    --query "ipAddress.ip" \
    --output tsv)

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}🎉 Authentication Service Deployed!${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Service Name: BIDR Authentication Service${NC}"
echo -e "${GREEN}Public IP: $PUBLIC_IP${NC}"
echo -e "${GREEN}FQDN: $FQDN${NC}"
echo -e "${GREEN}Service URL: http://$FQDN:8000${NC}"
echo -e "${GREEN}Admin URL: http://$FQDN:8000/admin/${NC}"
echo -e "${GREEN}API URL: http://$FQDN:8000/api/${NC}"
echo -e "${GREEN}Health Check: http://$FQDN:8000/health/${NC}"
echo -e "${GREEN}========================================${NC}"

# Step 6: Test the service
echo -e "${YELLOW}Step 5: Testing authentication service...${NC}"
sleep 15  # Additional wait for service to fully start

if curl -f -s "http://$FQDN:8000/health/" > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Authentication service is running and healthy!${NC}"
else
    echo -e "${YELLOW}⏳ Service is starting up, testing API endpoint...${NC}"
    if curl -f -s "http://$FQDN:8000/api/" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Authentication service API is responding!${NC}"
    else
        echo -e "${YELLOW}⚠️  Service may still be starting up. Check logs if needed:${NC}"
        echo -e "${BLUE}az container logs --resource-group $RESOURCE_GROUP --name $CONTAINER_NAME${NC}"
    fi
fi

# Step 7: Show both services
echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}🏢 Your BIDR Microservices Platform${NC}"
echo -e "${CYAN}========================================${NC}"

# Get product service info
PRODUCT_FQDN=$(az container show --resource-group $RESOURCE_GROUP --name bidr-product-service --query "ipAddress.fqdn" --output tsv 2>/dev/null || echo "Not found")
PRODUCT_IP=$(az container show --resource-group $RESOURCE_GROUP --name bidr-product-service --query "ipAddress.ip" --output tsv 2>/dev/null || echo "Not found")

echo -e "${GREEN}📦 Product Management Service:${NC}"
echo -e "${GREEN}   URL: http://$PRODUCT_FQDN:8000${NC}"
echo -e "${GREEN}   IP: $PRODUCT_IP${NC}"
echo ""
echo -e "${BLUE}🔐 Authentication Service:${NC}"
echo -e "${BLUE}   URL: http://$FQDN:8000${NC}"
echo -e "${BLUE}   IP: $PUBLIC_IP${NC}"
echo ""
echo -e "${YELLOW}🎯 Quick Test Commands:${NC}"
echo -e "${YELLOW}curl http://$PRODUCT_FQDN:8000/health/${NC}"
echo -e "${YELLOW}curl http://$FQDN:8000/health/${NC}"
echo ""
echo -e "${GREEN}🎊 Both services are now running in the same resource group!${NC}"
echo -e "${CYAN}========================================${NC}"
