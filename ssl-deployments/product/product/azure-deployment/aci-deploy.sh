#!/bin/bash

# Azure Container Instances Deployment Script
# This script deploys the BIDR Product Management Service to Azure Container Instances

set -e

# Configuration variables - UPDATE THESE
RESOURCE_GROUP="bidr-rg"
CONTAINER_REGISTRY="bidrregistry"
CONTAINER_NAME="bidr-product-service"
LOCATION="eastus"
IMAGE_TAG="latest"
ADMIN_PASSWORD="admin123"  # Change this to a secure password

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Starting Azure Container Instances deployment...${NC}"

# Step 1: Create Resource Group
echo -e "${YELLOW}Creating resource group...${NC}"
az group create \
    --name $RESOURCE_GROUP \
    --location $LOCATION

# Step 2: Create Azure Container Registry
echo -e "${YELLOW}Creating Azure Container Registry...${NC}"
az acr create \
    --resource-group $RESOURCE_GROUP \
    --name $CONTAINER_REGISTRY \
    --sku Basic \
    --admin-enabled true

# Step 3: Get ACR login server
ACR_LOGIN_SERVER=$(az acr show --name $CONTAINER_REGISTRY --resource-group $RESOURCE_GROUP --query "loginServer" --output tsv)
echo -e "${GREEN}ACR Login Server: $ACR_LOGIN_SERVER${NC}"

# Step 4: Build and push Docker image
echo -e "${YELLOW}Building and pushing Docker image...${NC}"
az acr build \
    --registry $CONTAINER_REGISTRY \
    --image bidr-product-management:$IMAGE_TAG \
    .

# Step 5: Get ACR credentials
ACR_USERNAME=$(az acr credential show --name $CONTAINER_REGISTRY --query "username" --output tsv)
ACR_PASSWORD=$(az acr credential show --name $CONTAINER_REGISTRY --query "passwords[0].value" --output tsv)

# Step 6: Deploy to Container Instances
echo -e "${YELLOW}Deploying to Azure Container Instances...${NC}"
az container create \
    --resource-group $RESOURCE_GROUP \
    --name $CONTAINER_NAME \
    --image $ACR_LOGIN_SERVER/bidr-product-management:$IMAGE_TAG \
    --dns-name-label bidr-product-$(date +%s) \
    --ports 8000 \
    --registry-login-server $ACR_LOGIN_SERVER \
    --registry-username $ACR_USERNAME \
    --registry-password $ACR_PASSWORD \
    --environment-variables \
        DJANGO_SETTINGS_MODULE=product_management_service.settings \
        SECRET_KEY="your-secret-key-here-change-me" \
        DEBUG=False \
        ALLOWED_HOSTS="*" \
    --cpu 2 \
    --memory 4 \
    --restart-policy OnFailure

# Step 7: Get public IP
echo -e "${YELLOW}Getting deployment information...${NC}"
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

echo -e "${GREEN}Deployment completed successfully!${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Public IP: $PUBLIC_IP${NC}"
echo -e "${GREEN}FQDN: $FQDN${NC}"
echo -e "${GREEN}Admin URL: http://$FQDN:8000/admin/${NC}"
echo -e "${GREEN}API URL: http://$FQDN:8000/api/${NC}"
echo -e "${GREEN}Health Check: http://$FQDN:8000/health/${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "${YELLOW}Admin Credentials:${NC}"
echo -e "${YELLOW}Username: bidr_admin${NC}"
echo -e "${YELLOW}Password: $ADMIN_PASSWORD${NC}"

# Step 8: Run migrations and create superuser
echo -e "${YELLOW}Running database migrations...${NC}"
az container exec \
    --resource-group $RESOURCE_GROUP \
    --name $CONTAINER_NAME \
    --exec-command "python product_management_service/manage.py migrate"

echo -e "${GREEN}Deployment script completed!${NC}"
