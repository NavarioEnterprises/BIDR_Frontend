#!/bin/bash

# Azure Infrastructure Setup for BIDR Microservices
# This script creates the foundational Azure resources for all BIDR services

set -e

# Configuration variables - UPDATE THESE
RESOURCE_GROUP="bidr-microservices-rg"
CONTAINER_REGISTRY="bidrcontainers"
LOCATION="westus"
SUBSCRIPTION_NAME=""  # Leave empty to use current subscription

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}   BIDR Azure Infrastructure Setup     ${NC}"
echo -e "${GREEN}========================================${NC}"

# Step 1: Login and subscription setup
echo -e "${YELLOW}Step 1: Verifying Azure login...${NC}"
if ! az account show &> /dev/null; then
    echo -e "${RED}Not logged in to Azure. Please run: az login${NC}"
    exit 1
fi

if [ ! -z "$SUBSCRIPTION_NAME" ]; then
    echo -e "${YELLOW}Setting subscription to: $SUBSCRIPTION_NAME${NC}"
    az account set --subscription "$SUBSCRIPTION_NAME"
fi

CURRENT_SUB=$(az account show --query "name" --output tsv)
echo -e "${GREEN}Using subscription: $CURRENT_SUB${NC}"

# Step 2: Create Resource Group
echo -e "${YELLOW}Step 2: Creating resource group...${NC}"
if az group show --name $RESOURCE_GROUP &> /dev/null; then
    echo -e "${BLUE}Resource group '$RESOURCE_GROUP' already exists${NC}"
else
    az group create \
        --name $RESOURCE_GROUP \
        --location $LOCATION
    echo -e "${GREEN}Created resource group: $RESOURCE_GROUP${NC}"
fi

# Step 3: Create Azure Container Registry
echo -e "${YELLOW}Step 3: Creating Azure Container Registry...${NC}"
if az acr show --name $CONTAINER_REGISTRY --resource-group $RESOURCE_GROUP &> /dev/null; then
    echo -e "${BLUE}Container registry '$CONTAINER_REGISTRY' already exists${NC}"
else
    az acr create \
        --resource-group $RESOURCE_GROUP \
        --name $CONTAINER_REGISTRY \
        --sku Standard \
        --admin-enabled true
    echo -e "${GREEN}Created container registry: $CONTAINER_REGISTRY${NC}"
fi

# Step 4: Create App Service Plan
echo -e "${YELLOW}Step 4: Creating App Service Plan...${NC}"
APP_SERVICE_PLAN="bidr-app-service-plan"
if az appservice plan show --name $APP_SERVICE_PLAN --resource-group $RESOURCE_GROUP &> /dev/null; then
    echo -e "${BLUE}App Service Plan '$APP_SERVICE_PLAN' already exists${NC}"
else
    az appservice plan create \
        --name $APP_SERVICE_PLAN \
        --resource-group $RESOURCE_GROUP \
        --location $LOCATION \
        --is-linux \
        --sku B1
    echo -e "${GREEN}Created App Service Plan: $APP_SERVICE_PLAN${NC}"
fi

# Step 5: Create Azure Database for PostgreSQL (shared database)
echo -e "${YELLOW}Step 5: Creating PostgreSQL database...${NC}"
DB_SERVER_NAME="bidr-postgres-server"
DB_ADMIN_USER="bidr_admin"
DB_ADMIN_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)

if az postgres server show --name $DB_SERVER_NAME --resource-group $RESOURCE_GROUP &> /dev/null; then
    echo -e "${BLUE}PostgreSQL server '$DB_SERVER_NAME' already exists${NC}"
else
    az postgres server create \
        --resource-group $RESOURCE_GROUP \
        --name $DB_SERVER_NAME \
        --location $LOCATION \
        --admin-user $DB_ADMIN_USER \
        --admin-password $DB_ADMIN_PASSWORD \
        --sku-name GP_Gen5_2 \
        --version 13
    
    echo -e "${GREEN}Created PostgreSQL server: $DB_SERVER_NAME${NC}"
    echo -e "${GREEN}Database admin user: $DB_ADMIN_USER${NC}"
    echo -e "${YELLOW}Database admin password: $DB_ADMIN_PASSWORD${NC}"
    echo -e "${RED}IMPORTANT: Save the database password above!${NC}"
    
    # Save credentials to file
    cat > database-credentials.txt << EOF
PostgreSQL Server: $DB_SERVER_NAME.postgres.database.azure.com
Admin User: $DB_ADMIN_USER@$DB_SERVER_NAME
Admin Password: $DB_ADMIN_PASSWORD
Connection String: postgresql://$DB_ADMIN_USER:$DB_ADMIN_PASSWORD@$DB_SERVER_NAME.postgres.database.azure.com:5432/
EOF
    echo -e "${GREEN}Database credentials saved to: database-credentials.txt${NC}"
fi

# Step 6: Configure database firewall
echo -e "${YELLOW}Step 6: Configuring database firewall...${NC}"
az postgres server firewall-rule create \
    --resource-group $RESOURCE_GROUP \
    --server $DB_SERVER_NAME \
    --name "AllowAzureServices" \
    --start-ip-address 0.0.0.0 \
    --end-ip-address 0.0.0.0 || true

# Step 7: Create individual databases for each service
echo -e "${YELLOW}Step 7: Creating databases for each service...${NC}"
SERVICES=("authentication" "products" "notifications" "payments" "resolution" "reviews" "transactions" "chat")

for service in "${SERVICES[@]}"; do
    DB_NAME="bidr_${service}"
    if az postgres db show --name $DB_NAME --server-name $DB_SERVER_NAME --resource-group $RESOURCE_GROUP &> /dev/null; then
        echo -e "${BLUE}Database '$DB_NAME' already exists${NC}"
    else
        az postgres db create \
            --resource-group $RESOURCE_GROUP \
            --server-name $DB_SERVER_NAME \
            --name $DB_NAME
        echo -e "${GREEN}Created database: $DB_NAME${NC}"
    fi
done

# Step 8: Get ACR credentials
echo -e "${YELLOW}Step 8: Getting ACR credentials...${NC}"
ACR_LOGIN_SERVER=$(az acr show --name $CONTAINER_REGISTRY --resource-group $RESOURCE_GROUP --query "loginServer" --output tsv)
ACR_USERNAME=$(az acr credential show --name $CONTAINER_REGISTRY --query "username" --output tsv)
ACR_PASSWORD=$(az acr credential show --name $CONTAINER_REGISTRY --query "passwords[0].value" --output tsv)

# Step 9: Create configuration file for services
echo -e "${YELLOW}Step 9: Creating deployment configuration...${NC}"
cat > deployment-config.env << EOF
# Azure Infrastructure Configuration
RESOURCE_GROUP=$RESOURCE_GROUP
CONTAINER_REGISTRY=$CONTAINER_REGISTRY
ACR_LOGIN_SERVER=$ACR_LOGIN_SERVER
ACR_USERNAME=$ACR_USERNAME
ACR_PASSWORD=$ACR_PASSWORD
LOCATION=$LOCATION
APP_SERVICE_PLAN=$APP_SERVICE_PLAN

# Database Configuration
DB_SERVER_NAME=$DB_SERVER_NAME
DB_ADMIN_USER=$DB_ADMIN_USER
DB_ADMIN_PASSWORD=$DB_ADMIN_PASSWORD
DB_HOST=$DB_SERVER_NAME.postgres.database.azure.com

# Service URLs (will be populated after deployment)
AUTH_SERVICE_URL=
PRODUCT_SERVICE_URL=
NOTIFICATION_SERVICE_URL=
PAYMENT_SERVICE_URL=
RESOLUTION_SERVICE_URL=
REVIEWS_SERVICE_URL=
TRANSACTIONS_SERVICE_URL=
CHAT_SERVICE_URL=
EOF

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}   Infrastructure Setup Complete!     ${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Resource Group: $RESOURCE_GROUP${NC}"
echo -e "${GREEN}Container Registry: $ACR_LOGIN_SERVER${NC}"
echo -e "${GREEN}App Service Plan: $APP_SERVICE_PLAN${NC}"
echo -e "${GREEN}PostgreSQL Server: $DB_SERVER_NAME.postgres.database.azure.com${NC}"
echo -e "${GREEN}Location: $LOCATION${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "${YELLOW}Next Steps:${NC}"
echo -e "${YELLOW}1. Run individual service deployment scripts${NC}"
echo -e "${YELLOW}2. Configure service-to-service communication${NC}"
echo -e "${YELLOW}3. Set up monitoring and alerts${NC}"
echo -e "${GREEN}========================================${NC}"
