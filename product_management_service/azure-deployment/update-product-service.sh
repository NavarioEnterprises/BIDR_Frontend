#!/bin/bash

# BIDR Product Management Service Update Script
# This script rebuilds and redeploys the product management service with enhanced features
set -e

# Configuration
RESOURCE_GROUP="bidr-simple-rg"
CONTAINER_REGISTRY="bidrsimpleregistry"
CONTAINER_NAME="bidr-product-service"
IMAGE_NAME="bidr-product-service"
SERVICE_NAME="Product Management Service"
SERVICE_PORT=8000
SERVICE_DIR="/Users/thulanimoyo/MEGA downloads/new downloads/BIDR_Backend/product_management_service"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${GREEN}🚀 Updating BIDR ${SERVICE_NAME}...${NC}"

# Step 1: Verify service directory exists
if [ ! -d "$SERVICE_DIR" ]; then
    echo -e "${RED}❌ ${SERVICE_NAME} directory not found: $SERVICE_DIR${NC}"
    exit 1
fi

echo -e "${BLUE}✅ Found ${SERVICE_NAME} directory${NC}"

# Step 2: Build and push Docker image with timestamp tag
TIMESTAMP=$(date +%s)
NEW_TAG="v${TIMESTAMP}"

echo -e "${YELLOW}Step 1: Building and pushing Docker image with tag: ${NEW_TAG}...${NC}"
az acr build \
    --registry $CONTAINER_REGISTRY \
    --image "${IMAGE_NAME}:${NEW_TAG}" \
    --image "${IMAGE_NAME}:latest" \
    "$SERVICE_DIR"

echo -e "${GREEN}✅ ${SERVICE_NAME} image built and pushed with tags: latest, ${NEW_TAG}${NC}"

# Step 3: Get current container information
echo -e "${YELLOW}Step 2: Getting current container information...${NC}"
CURRENT_CONTAINER=$(az container show \
    --resource-group $RESOURCE_GROUP \
    --name $CONTAINER_NAME \
    --query '{ip: ipAddress.ip, fqdn: ipAddress.fqdn}' \
    --output json 2>/dev/null || echo '{}')

if [ "$CURRENT_CONTAINER" = "{}" ]; then
    echo -e "${YELLOW}⚠️  Container not found. This might be the first deployment.${NC}"
    CURRENT_IP=""
    CURRENT_FQDN=""
else
    CURRENT_IP=$(echo $CURRENT_CONTAINER | jq -r '.ip // ""')
    CURRENT_FQDN=$(echo $CURRENT_CONTAINER | jq -r '.fqdn // ""')
    echo -e "${BLUE}Current service IP: $CURRENT_IP${NC}"
    echo -e "${BLUE}Current service FQDN: $CURRENT_FQDN${NC}"

    # Optional: Backup current container logs before deletion
    echo -e "${YELLOW}Saving current container logs for reference...${NC}"
    LOGS_DIR="./logs"
    mkdir -p $LOGS_DIR
    az container logs \
        --resource-group $RESOURCE_GROUP \
        --name $CONTAINER_NAME > "$LOGS_DIR/product-service-logs-$(date +%Y%m%d-%H%M%S).txt" || true
    echo -e "${GREEN}✅ Logs saved (if available)${NC}"
fi

# Step 4: Delete existing container
echo -e "${YELLOW}Step 3: Stopping existing container...${NC}"
az container delete \
    --resource-group $RESOURCE_GROUP \
    --name $CONTAINER_NAME \
    --yes \
    --no-wait 2>/dev/null || echo -e "${YELLOW}⚠️  No existing container to delete${NC}"

# Wait for container deletion to complete
echo -e "${BLUE}Waiting for container deletion to complete...${NC}"
sleep 15

# Step 5: Get registry credentials
echo -e "${YELLOW}Step 4: Getting registry credentials...${NC}"
ACR_LOGIN_SERVER=$(az acr show --name $CONTAINER_REGISTRY --resource-group $RESOURCE_GROUP --query "loginServer" --output tsv)
ACR_USERNAME=$(az acr credential show --name $CONTAINER_REGISTRY --query "username" --output tsv)
ACR_PASSWORD=$(az acr credential show --name $CONTAINER_REGISTRY --query "passwords[0].value" --output tsv)

echo -e "${BLUE}Registry: $ACR_LOGIN_SERVER${NC}"

# Step 6: Deploy updated container
echo -e "${YELLOW}Step 5: Deploying updated container...${NC}"

# Generate new DNS label to avoid conflicts
DNS_LABEL="bidr-prod-$(date +%s)"

# Generate new secret keys for security
SECRET_KEY=$(python3 -c "import secrets; print(secrets.token_urlsafe(32))")
JWT_SECRET_KEY=$(python3 -c "import secrets; print(secrets.token_urlsafe(32))")

# Deploy with public IP to avoid 502 errors
az container create \
    --resource-group $RESOURCE_GROUP \
    --name $CONTAINER_NAME \
    --image "$ACR_LOGIN_SERVER/$IMAGE_NAME:latest" \
    --registry-login-server $ACR_LOGIN_SERVER \
    --registry-username $ACR_USERNAME \
    --registry-password $ACR_PASSWORD \
    --dns-name-label $DNS_LABEL \
    --ports $SERVICE_PORT \
    --cpu 1 \
    --memory 1.5 \
    --restart-policy OnFailure \
    --os-type Linux \
    --ip-address Public \
    --environment-variables \
        SECRET_KEY="$SECRET_KEY" \
        DEBUG=False \
        ALLOWED_HOSTS="*" \
        DJANGO_SETTINGS_MODULE=product_management_service.settings \
        JWT_SECRET_KEY="$JWT_SECRET_KEY" \
        CORS_ALLOW_ALL_ORIGINS=True \
        SERVICE_NAME_DISPLAY="$SERVICE_NAME" \
        BIDR_VERSION="$NEW_TAG" \
        DEPLOYMENT_TIMESTAMP="$(date)"

echo -e "${GREEN}✅ ${SERVICE_NAME} deployment initiated${NC}"

# Step 7: Wait for deployment and get new information
echo -e "${YELLOW}Step 6: Waiting for deployment to complete...${NC}"
echo -e "${BLUE}⌜ This may take 30-60 seconds...${NC}"
sleep 30

# Get new container information
NEW_CONTAINER_INFO=$(az container show \
    --resource-group $RESOURCE_GROUP \
    --name $CONTAINER_NAME \
    --query '{
        ip: ipAddress.ip,
        fqdn: ipAddress.fqdn,
        state: instanceView.state,
        provisioningState: provisioningState
    }' \
    --output json)

NEW_IP=$(echo $NEW_CONTAINER_INFO | jq -r '.ip // "N/A"')
NEW_FQDN=$(echo $NEW_CONTAINER_INFO | jq -r '.fqdn // "N/A"')
CONTAINER_STATE=$(echo $NEW_CONTAINER_INFO | jq -r '.state // "Unknown"')
PROVISIONING_STATE=$(echo $NEW_CONTAINER_INFO | jq -r '.provisioningState // "Unknown"')

# Step 9: Display deployment summary with color-coded sections
echo ""
echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}🎉 BIDR ${SERVICE_NAME} Updated!${NC}"
echo -e "${CYAN}========================================${NC}"
echo -e "${GREEN}✅ Service: BIDR ${SERVICE_NAME}${NC}"
echo -e "${GREEN}✅ Version: ${NEW_TAG}${NC}"
echo -e "${GREEN}✅ Container: $CONTAINER_NAME${NC}"
echo -e "${GREEN}✅ State: $CONTAINER_STATE / $PROVISIONING_STATE${NC}"
echo -e "${GREEN}✅ IP Address: $NEW_IP:$SERVICE_PORT${NC}"
echo -e "${GREEN}✅ Public URL: http://$NEW_FQDN:$SERVICE_PORT${NC}"
echo ""
echo -e "${BLUE}🔗 Service Endpoints:${NC}"
echo -e "${BLUE}• Product API: http://$NEW_FQDN:$SERVICE_PORT/api/products/${NC}"
echo -e "${BLUE}• Categories API: http://$NEW_FQDN:$SERVICE_PORT/api/categories/${NC}"
echo -e "${BLUE}• Admin Panel: http://$NEW_FQDN:$SERVICE_PORT/admin/${NC}"
echo -e "${BLUE}• Health Check: http://$NEW_FQDN:$SERVICE_PORT/health/${NC}"
echo ""

if [ "$API_AVAILABLE" = true ]; then
    echo -e "${GREEN}🎊 API Test Status: SUCCESS${NC}"
else
    echo -e "${YELLOW}⚠️  API Test Status: PENDING${NC}"
    echo -e "${YELLOW}   Service may still be starting up. Try manual tests in a few moments.${NC}"
fi

echo ""
echo -e "${YELLOW}🔧 Enhanced Management Commands:${NC}"
echo -e "${YELLOW}• View Logs: az container logs --resource-group $RESOURCE_GROUP --name $CONTAINER_NAME${NC}"
echo -e "${YELLOW}• Real-time Logs: az container logs --resource-group $RESOURCE_GROUP --name $CONTAINER_NAME --follow${NC}"
echo -e "${YELLOW}• Container Status: az container show --resource-group $RESOURCE_GROUP --name $CONTAINER_NAME${NC}"
echo -e "${YELLOW}• Restart Container: az container restart --resource-group $RESOURCE_GROUP --name $CONTAINER_NAME${NC}"
echo -e "${YELLOW}• Delete Container: az container delete --resource-group $RESOURCE_GROUP --name $CONTAINER_NAME --yes${NC}"
echo -e "${YELLOW}• Interactive Logs & Management: python bidr-deploy-manager.py (Option 5)${NC}"
echo ""

echo -e "${CYAN}📈 Quick Test Commands:${NC}"
echo -e "${CYAN}curl http://${NEW_FQDN}:${SERVICE_PORT}/health/${NC}"
echo -e "${CYAN}curl http://${NEW_FQDN}:${SERVICE_PORT}/api/products/${NC}"

echo ""
echo -e "${GREEN}🎊 ${SERVICE_NAME} has been updated successfully!${NC}"
echo -e "${CYAN}========================================${NC}"
while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    # Try health check endpoint first
    HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "http://${NEW_FQDN}:${SERVICE_PORT}/health/" --connect-timeout 10 --max-time 30 || echo "000")
    
    if [ "$HTTP_STATUS" = "200" ]; then
        echo -e "${GREEN}✅ Service is healthy and responding!${NC}"
        API_AVAILABLE=true
        break
    else
        # Try root endpoint as fallback
        HTTP_STATUS_ROOT=$(curl -s -o /dev/null -w "%{http_code}" "http://${NEW_FQDN}:${SERVICE_PORT}/" --connect-timeout 10 --max-time 30 || echo "000")
        
        if [ "$HTTP_STATUS_ROOT" != "000" ] && [ "$HTTP_STATUS_ROOT" != "502" ]; then
            echo -e "${GREEN}✅ Service is responding on root endpoint (status: $HTTP_STATUS_ROOT)!${NC}"
            API_AVAILABLE=true
            break
        else
            RETRY_COUNT=$((RETRY_COUNT + 1))
            if [ $RETRY_COUNT -lt $MAX_RETRIES ]; then
                echo -e "${YELLOW}⚠️  Service not ready yet (attempt $RETRY_COUNT/$MAX_RETRIES). Waiting 15 seconds...${NC}"
                sleep 15
            else
                echo -e "${YELLOW}⚠️  Service may still be starting up. Check logs if needed.${NC}"
            fi
        fi
    fi
done

echo ""
echo "🎯 Quick Test Command:"
echo "curl http://${NEW_FQDN}:${SERVICE_PORT}/health/"
echo ""
echo "📋 Check logs with:"
echo "az container logs --resource-group $RESOURCE_GROUP --name $CONTAINER_NAME"
echo ""
echo "🎊 Product Management Service update complete!"
echo "========================================"
