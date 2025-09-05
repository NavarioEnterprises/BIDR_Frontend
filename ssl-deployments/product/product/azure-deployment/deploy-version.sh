#!/bin/bash

# Deploy Specific Version Script
# This script allows you to deploy specific versions with rollback capability

set -e

# Configuration
RESOURCE_GROUP="bidr-simple-rg"
CONTAINER_REGISTRY="bidrsimpleregistry"
CONTAINER_NAME="bidr-product-service"
IMAGE_NAME="bidr-product-management"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# Get version tag (current timestamp or provided argument)
VERSION=${1:-$(date +"%Y%m%d-%H%M%S")}

echo -e "${GREEN}🚀 Deploying BIDR Service Version: $VERSION${NC}"

# Step 1: Build and tag image with version
echo -e "${YELLOW}Step 1: Building version $VERSION...${NC}"
cd ..
az acr build \
    --registry $CONTAINER_REGISTRY \
    --image $IMAGE_NAME:$VERSION \
    --image $IMAGE_NAME:latest \
    .

echo -e "${GREEN}✅ Built and pushed version: $VERSION${NC}"

# Step 2: Get current container info
echo -e "${YELLOW}Step 2: Backing up current deployment info...${NC}"
CURRENT_VERSION=$(az container show --resource-group $RESOURCE_GROUP --name $CONTAINER_NAME --query "containers[0].image" --output tsv 2>/dev/null | cut -d':' -f2 || echo "none")
CURRENT_FQDN=$(az container show --resource-group $RESOURCE_GROUP --name $CONTAINER_NAME --query "ipAddress.fqdn" --output tsv 2>/dev/null || echo "")

echo -e "${BLUE}Previous version: $CURRENT_VERSION${NC}"

# Create rollback info
cat > azure-deployment/rollback-$VERSION.sh << EOF
#!/bin/bash
# Rollback script for version $VERSION
# Previous version: $CURRENT_VERSION
# Generated: $(date)

echo "Rolling back from version $VERSION to $CURRENT_VERSION..."

az container delete --resource-group $RESOURCE_GROUP --name $CONTAINER_NAME --yes

az container create \\
    --resource-group $RESOURCE_GROUP \\
    --name $CONTAINER_NAME \\
    --image bidrsimpleregistry.azurecr.io/$IMAGE_NAME:$CURRENT_VERSION \\
    --dns-name-label $(echo $CURRENT_FQDN | cut -d'.' -f1) \\
    --ports 8000 \\
    --os-type Linux \\
    --registry-login-server bidrsimpleregistry.azurecr.io \\
    --registry-username \$(az acr credential show --name $CONTAINER_REGISTRY --query "username" --output tsv) \\
    --registry-password \$(az acr credential show --name $CONTAINER_REGISTRY --query "passwords[0].value" --output tsv) \\
    --environment-variables \\
        SECRET_KEY="\$(openssl rand -base64 32)" \\
        DEBUG=False \\
        ALLOWED_HOSTS="*" \\
    --cpu 1 \\
    --memory 1.5 \\
    --restart-policy OnFailure

echo "Rollback completed!"
EOF

chmod +x azure-deployment/rollback-$VERSION.sh

# Step 3: Deploy new version
echo -e "${YELLOW}Step 3: Deploying version $VERSION...${NC}"

# Delete old container
if [ ! -z "$CURRENT_FQDN" ]; then
    az container delete --resource-group $RESOURCE_GROUP --name $CONTAINER_NAME --yes
    DNS_LABEL=$(echo $CURRENT_FQDN | cut -d'.' -f1)
else
    DNS_LABEL="bidr-product-$(date +%s)"
fi

# Get registry credentials
ACR_LOGIN_SERVER=$(az acr show --name $CONTAINER_REGISTRY --resource-group $RESOURCE_GROUP --query "loginServer" --output tsv)
ACR_USERNAME=$(az acr credential show --name $CONTAINER_REGISTRY --query "username" --output tsv)
ACR_PASSWORD=$(az acr credential show --name $CONTAINER_REGISTRY --query "passwords[0].value" --output tsv)

# Deploy new container
az container create \
    --resource-group $RESOURCE_GROUP \
    --name $CONTAINER_NAME \
    --image $ACR_LOGIN_SERVER/$IMAGE_NAME:$VERSION \
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
        VERSION_TAG=$VERSION \
    --cpu 1 \
    --memory 1.5 \
    --restart-policy OnFailure

# Step 4: Verify deployment
echo -e "${YELLOW}Step 4: Verifying deployment...${NC}"
sleep 15

FQDN=$(az container show --resource-group $RESOURCE_GROUP --name $CONTAINER_NAME --query "ipAddress.fqdn" --output tsv)
PUBLIC_IP=$(az container show --resource-group $RESOURCE_GROUP --name $CONTAINER_NAME --query "ipAddress.ip" --output tsv)

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}🎉 Version $VERSION Deployed!${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Version: $VERSION${NC}"
echo -e "${GREEN}Public IP: $PUBLIC_IP${NC}"
echo -e "${GREEN}FQDN: $FQDN${NC}"
echo -e "${GREEN}Service URL: http://$FQDN:8000${NC}"
echo -e "${GREEN}========================================${NC}"

# Test deployment
echo -e "${YELLOW}Testing deployment...${NC}"
if curl -f -s "http://$FQDN:8000/health/" > /dev/null; then
    echo -e "${GREEN}✅ Deployment successful and healthy!${NC}"
    echo -e "${BLUE}Rollback script created: azure-deployment/rollback-$VERSION.sh${NC}"
else
    echo -e "${RED}❌ Health check failed! Consider rolling back.${NC}"
    echo -e "${YELLOW}To rollback: ./azure-deployment/rollback-$VERSION.sh${NC}"
fi

echo -e "${GREEN}✨ Deployment completed!${NC}"
