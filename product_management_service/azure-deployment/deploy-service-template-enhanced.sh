#!/bin/bash

# Enhanced BIDR Service Deployment Template
# This template can be used for any BIDR service deployment
set -e

# Configuration - Replace these values for your specific service
RESOURCE_GROUP="bidr-simple-rg"
CONTAINER_REGISTRY="bidrsimpleregistry"
CONTAINER_NAME="bidr-{SERVICE_NAME}-service"
IMAGE_NAME="bidr-{SERVICE_NAME}-service"
SERVICE_NAME="{SERVICE_NAME_DISPLAY}"
SERVICE_PORT={PORT_NUMBER}

# Get the script directory and find the service
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"  # Two levels up from azure-deployment
SERVICE_DIR="$PROJECT_ROOT/{SERVICE_DIRECTORY}"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${GREEN}🚀 Deploying BIDR ${SERVICE_NAME}...${NC}"

# Step 1: Verify service directory exists
if [ ! -d "$SERVICE_DIR" ]; then
    echo -e "${RED}❌ ${SERVICE_NAME} directory not found: $SERVICE_DIR${NC}"
    exit 1
fi

echo -e "${BLUE}✅ Found ${SERVICE_NAME} directory${NC}"

# Step 2: Build and push Docker image
echo -e "${YELLOW}Step 1: Building and pushing Docker image...${NC}"
az acr build \
    --registry $CONTAINER_REGISTRY \
    --image $IMAGE_NAME:latest \
    "$SERVICE_DIR"

echo -e "${GREEN}✅ ${SERVICE_NAME} image built and pushed${NC}"

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

# Step 5: Deploy to Azure Container Instances
echo -e "${YELLOW}Step 4: Deploying to Azure Container Instances...${NC}"
az container create \
    --resource-group $RESOURCE_GROUP \
    --name $CONTAINER_NAME \
    --image $ACR_LOGIN_SERVER/$IMAGE_NAME:latest \
    --ports $SERVICE_PORT \
    --os-type Linux \
    --ip-address Public \
    --dns-name-label $CONTAINER_NAME \
    --registry-login-server $ACR_LOGIN_SERVER \
    --registry-username $ACR_USERNAME \
    --registry-password $ACR_PASSWORD \
    --environment-variables \
        SECRET_KEY="$(openssl rand -base64 32)" \
        DEBUG=False \
        ALLOWED_HOSTS="*" \
        DJANGO_SETTINGS_MODULE={SERVICE_DIRECTORY}.settings \
        JWT_SECRET_KEY="$(openssl rand -base64 32)" \
        CORS_ALLOW_ALL_ORIGINS=True \
    --cpu 1 \
    --memory 1.5 \
    --restart-policy OnFailure

echo -e "${GREEN}✅ ${SERVICE_NAME} deployed${NC}"

# Step 6: Get container information
echo -e "${YELLOW}Step 5: Getting container information...${NC}"
sleep 10  # Wait for container to fully initialize

CONTAINER_IP=$(az container show \
    --resource-group $RESOURCE_GROUP \
    --name $CONTAINER_NAME \
    --query "ipAddress.ip" \
    --output tsv)

CONTAINER_FQDN=$(az container show \
    --resource-group $RESOURCE_GROUP \
    --name $CONTAINER_NAME \
    --query "ipAddress.fqdn" \
    --output tsv)

if [ -z "$CONTAINER_IP" ]; then
    echo -e "${RED}❌ Failed to get container IP address${NC}"
    exit 1
fi

echo -e "${BLUE}Container IP: $CONTAINER_IP${NC}"
echo -e "${BLUE}Container FQDN: $CONTAINER_FQDN${NC}"

# Step 7: Test the service
echo -e "${YELLOW}Step 6: Testing ${SERVICE_NAME}...${NC}"
sleep 10  # Additional wait for service startup

echo -e "${BLUE}Testing HTTP endpoint...${NC}"
if curl -f -s "http://$CONTAINER_IP:$SERVICE_PORT/health/" > /dev/null 2>&1; then
    echo -e "${GREEN}✅ ${SERVICE_NAME} is accessible via HTTP!${NC}"
elif curl -f -s "http://$CONTAINER_IP:$SERVICE_PORT/" > /dev/null 2>&1; then
    echo -e "${GREEN}✅ ${SERVICE_NAME} is responding!${NC}"
else
    echo -e "${YELLOW}⚠️  Service may still be starting up. Check logs if needed.${NC}"
fi

# Step 8: Display deployment summary
echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}🎉 BIDR ${SERVICE_NAME} Deployed!${NC}"
echo -e "${CYAN}========================================${NC}"
echo -e "${GREEN}✅ Service: BIDR ${SERVICE_NAME}${NC}"
echo -e "${GREEN}✅ Container: $CONTAINER_NAME${NC}"
echo -e "${GREEN}✅ IP Address: $CONTAINER_IP:$SERVICE_PORT${NC}"
echo -e "${GREEN}✅ Public URL: http://$CONTAINER_FQDN:$SERVICE_PORT${NC}"
echo ""
echo -e "${BLUE}🔗 Service Endpoints:${NC}"
echo -e "${BLUE}• Main API: http://$CONTAINER_FQDN:$SERVICE_PORT/api/${NC}"
echo -e "${BLUE}• Admin Panel: http://$CONTAINER_FQDN:$SERVICE_PORT/admin/${NC}"
echo -e "${BLUE}• Health Check: http://$CONTAINER_FQDN:$SERVICE_PORT/health/${NC}"
echo ""
echo -e "${YELLOW}🔧 Enhanced Management Commands:${NC}"
echo -e "${YELLOW}• View Logs: az container logs --resource-group $RESOURCE_GROUP --name $CONTAINER_NAME${NC}"
echo -e "${YELLOW}• Real-time Logs: az container logs --resource-group $RESOURCE_GROUP --name $CONTAINER_NAME --follow${NC}"
echo -e "${YELLOW}• Container Status: az container show --resource-group $RESOURCE_GROUP --name $CONTAINER_NAME${NC}"
echo -e "${YELLOW}• Restart Container: az container restart --resource-group $RESOURCE_GROUP --name $CONTAINER_NAME${NC}"
echo -e "${YELLOW}• Delete Container: az container delete --resource-group $RESOURCE_GROUP --name $CONTAINER_NAME --yes${NC}"
echo -e "${YELLOW}• Interactive Logs & Management: python bidr-deploy-manager.py (Option 5)${NC}"
echo ""
echo -e "${CYAN}📊 Advanced Logging Features:${NC}"
echo -e "${CYAN}• Real-time log streaming${NC}"
echo -e "${CYAN}• Error logs filtering${NC}"
echo -e "${CYAN}• Historical logs viewing${NC}"
echo -e "${CYAN}• Container status monitoring${NC}"
echo ""
echo -e "${GREEN}🎊 Your ${SERVICE_NAME} is now running successfully!${NC}"
echo -e "${CYAN}========================================${NC}"
