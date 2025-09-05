#!/bin/bash

# Azure App Service Deployment Script
# This script deploys the BIDR Product Management Service to Azure App Service with custom domain support

set -e

# Configuration variables - UPDATE THESE
RESOURCE_GROUP="bidr-prod-rg"
CONTAINER_REGISTRY="bidrregistry"
APP_SERVICE_PLAN="bidr-app-plan"
WEB_APP_NAME="bidr-product-management"
LOCATION="eastus"
IMAGE_TAG="latest"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Starting Azure App Service deployment...${NC}"

# Step 1: Create Resource Group
echo -e "${YELLOW}Creating resource group...${NC}"
az group create \
    --name $RESOURCE_GROUP \
    --location $LOCATION

# Step 2: Create Azure Container Registry (if it doesn't exist)
echo -e "${YELLOW}Creating/updating Azure Container Registry...${NC}"
az acr create \
    --resource-group $RESOURCE_GROUP \
    --name $CONTAINER_REGISTRY \
    --sku Standard \
    --admin-enabled true

# Step 3: Build and push Docker image
echo -e "${YELLOW}Building and pushing Docker image...${NC}"
ACR_LOGIN_SERVER=$(az acr show --name $CONTAINER_REGISTRY --resource-group $RESOURCE_GROUP --query "loginServer" --output tsv)
az acr build \
    --registry $CONTAINER_REGISTRY \
    --image bidr-product-management:$IMAGE_TAG \
    .

# Step 4: Create App Service Plan (Linux with containers)
echo -e "${YELLOW}Creating App Service Plan...${NC}"
az appservice plan create \
    --name $APP_SERVICE_PLAN \
    --resource-group $RESOURCE_GROUP \
    --location $LOCATION \
    --is-linux \
    --sku B2

# Step 5: Get ACR credentials
ACR_USERNAME=$(az acr credential show --name $CONTAINER_REGISTRY --query "username" --output tsv)
ACR_PASSWORD=$(az acr credential show --name $CONTAINER_REGISTRY --query "passwords[0].value" --output tsv)

# Step 6: Create Web App
echo -e "${YELLOW}Creating Web App...${NC}"
az webapp create \
    --resource-group $RESOURCE_GROUP \
    --plan $APP_SERVICE_PLAN \
    --name $WEB_APP_NAME \
    --deployment-container-image-name $ACR_LOGIN_SERVER/bidr-product-management:$IMAGE_TAG

# Step 7: Configure container registry credentials
echo -e "${YELLOW}Configuring container registry...${NC}"
az webapp config container set \
    --name $WEB_APP_NAME \
    --resource-group $RESOURCE_GROUP \
    --container-image-name $ACR_LOGIN_SERVER/bidr-product-management:$IMAGE_TAG \
    --container-registry-url https://$ACR_LOGIN_SERVER \
    --container-registry-user $ACR_USERNAME \
    --container-registry-password $ACR_PASSWORD

# Step 8: Configure application settings
echo -e "${YELLOW}Setting application configuration...${NC}"
az webapp config appsettings set \
    --resource-group $RESOURCE_GROUP \
    --name $WEB_APP_NAME \
    --settings \
        DJANGO_SETTINGS_MODULE=product_management_service.settings \
        SECRET_KEY="$(openssl rand -base64 32)" \
        DEBUG=False \
        ALLOWED_HOSTS="$WEB_APP_NAME.azurewebsites.net" \
        WEBSITES_ENABLE_APP_SERVICE_STORAGE=false \
        WEBSITES_PORT=8000

# Step 9: Enable logging
echo -e "${YELLOW}Enabling application logging...${NC}"
az webapp log config \
    --resource-group $RESOURCE_GROUP \
    --name $WEB_APP_NAME \
    --application-logging filesystem \
    --level information

# Step 10: Configure health check
echo -e "${YELLOW}Setting up health check...${NC}"
az webapp config set \
    --resource-group $RESOURCE_GROUP \
    --name $WEB_APP_NAME \
    --health-check-path "/health/"

# Step 11: Get deployment information
echo -e "${YELLOW}Getting deployment information...${NC}"
WEBAPP_URL="https://$WEB_APP_NAME.azurewebsites.net"

# Step 12: Restart the web app to ensure everything is loaded
echo -e "${YELLOW}Restarting web app...${NC}"
az webapp restart \
    --resource-group $RESOURCE_GROUP \
    --name $WEB_APP_NAME

echo -e "${GREEN}Deployment completed successfully!${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Web App URL: $WEBAPP_URL${NC}"
echo -e "${GREEN}Admin URL: $WEBAPP_URL/admin/${NC}"
echo -e "${GREEN}API URL: $WEBAPP_URL/api/${NC}"
echo -e "${GREEN}Health Check: $WEBAPP_URL/health/${NC}"
echo -e "${GREEN}========================================${NC}"

# Step 13: Show how to run database migrations
echo -e "${YELLOW}To run database migrations, execute:${NC}"
echo -e "${GREEN}az webapp ssh --resource-group $RESOURCE_GROUP --name $WEB_APP_NAME${NC}"
echo -e "${GREEN}Then run: python product_management_service/manage.py migrate${NC}"

echo -e "${GREEN}App Service deployment completed!${NC}"
