#!/bin/bash

# Update Deployed BIDR Service Script
# This script rebuilds and redeploys your service with updated code

set -e

# Configuration - these should match your deployment
RESOURCE_GROUP="bidr-simple-rg"
CONTAINER_REGISTRY="bidrsimpleregistry"
CONTAINER_NAME="bidr-product-service"
IMAGE_NAME="bidr-product-management"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GREEN}🚀 Updating BIDR Product Management Service...${NC}"

# Step 1: Build and push new image
echo -e "${YELLOW}Step 1: Building and pushing updated Docker image...${NC}"
cd ..
az acr build \
    --registry $CONTAINER_REGISTRY \
    --image $IMAGE_NAME:latest \
    .

echo -e "${GREEN}✅ New image built and pushed successfully!${NC}"

# Step 2: Get current container details
echo -e "${YELLOW}Step 2: Getting current container configuration...${NC}"
ACR_LOGIN_SERVER=$(az acr show --name $CONTAINER_REGISTRY --resource-group $RESOURCE_GROUP --query "loginServer" --output tsv)
ACR_USERNAME=$(az acr credential show --name $CONTAINER_REGISTRY --query "username" --output tsv)
ACR_PASSWORD=$(az acr credential show --name $CONTAINER_REGISTRY --query "passwords[0].value" --output tsv)

# Get current environment variables and other settings
CURRENT_ENV_VARS=$(az container show --resource-group $RESOURCE_GROUP --name $CONTAINER_NAME --query "containers[0].environmentVariables" --output json)
CURRENT_FQDN=$(az container show --resource-group $RESOURCE_GROUP --name $CONTAINER_NAME --query "ipAddress.fqdn" --output tsv)

echo -e "${BLUE}Current FQDN: $CURRENT_FQDN${NC}"

# Step 3: Delete old container
echo -e "${YELLOW}Step 3: Removing old container...${NC}"
az container delete \
    --resource-group $RESOURCE_GROUP \
    --name $CONTAINER_NAME \
    --yes

echo -e "${GREEN}✅ Old container removed${NC}"

# Step 4: Deploy new container with updated image
echo -e "${YELLOW}Step 4: Deploying updated container...${NC}"

# Extract the DNS name label from the current FQDN
DNS_LABEL=$(echo $CURRENT_FQDN | cut -d'.' -f1)

az container create \
    --resource-group $RESOURCE_GROUP \
    --name $CONTAINER_NAME \
    --image $ACR_LOGIN_SERVER/$IMAGE_NAME:latest \
    --dns-name-label $DNS_LABEL \
    --ports 8000 \
    --os-type Linux \
    --registry-login-server $ACR_LOGIN_SERVER \
    --registry-username $ACR_USERNAME \
    --registry-password $ACR_PASSWORD \
    --environment-variables \
        SECRET_KEY="$(openssl rand -base64 32)" \
        DEBUG=False \
        ALLOWED_HOSTS="*" \
    --cpu 1 \
    --memory 1.5 \
    --restart-policy OnFailure

# Step 5: Get new deployment info
echo -e "${YELLOW}Step 5: Getting deployment information...${NC}"
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
echo -e "${GREEN}🎉 Service Updated Successfully!${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Public IP: $PUBLIC_IP${NC}"
echo -e "${GREEN}FQDN: $FQDN${NC}"
echo -e "${GREEN}Admin URL: http://$FQDN:8000/admin/${NC}"
echo -e "${GREEN}API URL: http://$FQDN:8000/api/${NC}"
echo -e "${GREEN}Health Check: http://$FQDN:8000/health/${NC}"
echo -e "${GREEN}========================================${NC}"

# Step 6: Test the updated service
echo -e "${YELLOW}Testing updated service...${NC}"
sleep 10  # Wait for container to start
curl -f "http://$FQDN:8000/health/" && echo -e "${GREEN}✅ Service is running and healthy!${NC}" || echo -e "${RED}❌ Service health check failed${NC}"

echo -e "${GREEN}✨ Update completed successfully!${NC}"
