#!/bin/bash

# Simplified Azure Container Instances Deployment
# This deploys just the product management service to test quota limits

set -e

# Configuration
RESOURCE_GROUP="bidr-simple-rg"
CONTAINER_REGISTRY="bidrsimpleregistry"
LOCATION="westus"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}Starting simple ACI deployment...${NC}"

# Step 1: Create Resource Group
echo -e "${YELLOW}Creating resource group...${NC}"
az group create --name $RESOURCE_GROUP --location $LOCATION

# Step 2: Create Container Registry
echo -e "${YELLOW}Creating container registry...${NC}"
az acr create \
    --resource-group $RESOURCE_GROUP \
    --name $CONTAINER_REGISTRY \
    --sku Basic \
    --admin-enabled true

# Step 3: Build and push image
echo -e "${YELLOW}Building and pushing Docker image...${NC}"
cd ..
az acr build \
    --registry $CONTAINER_REGISTRY \
    --image bidr-product-management:latest \
    .

# Step 4: Get ACR credentials
ACR_LOGIN_SERVER=$(az acr show --name $CONTAINER_REGISTRY --resource-group $RESOURCE_GROUP --query "loginServer" --output tsv)
ACR_USERNAME=$(az acr credential show --name $CONTAINER_REGISTRY --query "username" --output tsv)
ACR_PASSWORD=$(az acr credential show --name $CONTAINER_REGISTRY --query "passwords[0].value" --output tsv)

# Step 5: Deploy to Container Instances
echo -e "${YELLOW}Deploying to Azure Container Instances...${NC}"
az container create \
    --resource-group $RESOURCE_GROUP \
    --name bidr-product-service \
    --image $ACR_LOGIN_SERVER/bidr-product-management:latest \
    --dns-name-label bidr-product-$(date +%s) \
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

# Step 6: Get public IP
FQDN=$(az container show \
    --resource-group $RESOURCE_GROUP \
    --name bidr-product-service \
    --query "ipAddress.fqdn" \
    --output tsv)

PUBLIC_IP=$(az container show \
    --resource-group $RESOURCE_GROUP \
    --name bidr-product-service \
    --query "ipAddress.ip" \
    --output tsv)

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Deployment completed successfully!${NC}"
echo -e "${GREEN}Public IP: $PUBLIC_IP${NC}"
echo -e "${GREEN}FQDN: $FQDN${NC}"
echo -e "${GREEN}Admin URL: http://$FQDN:8000/admin/${NC}"
echo -e "${GREEN}API URL: http://$FQDN:8000/api/${NC}"
echo -e "${GREEN}Health Check: http://$FQDN:8000/health/${NC}"
echo -e "${GREEN}========================================${NC}"

echo "Test the service with:"
echo "curl http://$FQDN:8000/health/"
