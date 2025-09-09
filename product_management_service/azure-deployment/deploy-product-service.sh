#!/bin/bash

# BIDR Product Management Service - Configurable Deployment Script
# This script reads from product-service-config.env for configuration

set -e

# Get the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/product-service-config.env"

# Load configuration
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
    echo "✅ Configuration loaded from $CONFIG_FILE"
else
    echo "❌ Configuration file not found: $CONFIG_FILE"
    echo "Please ensure product-service-config.env exists in the same directory as this script."
    exit 1
fi

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

# Functions
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

log_step() {
    echo -e "${YELLOW}🔄 $1${NC}"
}

# Start deployment
echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}🚀 BIDR Product Management Service Deployment${NC}"
echo -e "${CYAN}========================================${NC}"
echo -e "${BLUE}Resource Group: $RESOURCE_GROUP${NC}"
echo -e "${BLUE}Container Registry: $CONTAINER_REGISTRY${NC}"
echo -e "${BLUE}Container Name: $CONTAINER_NAME${NC}"
echo -e "${BLUE}Production URL: https://$PRODUCTION_DOMAIN$SERVICE_PATH${NC}"
echo -e "${CYAN}========================================${NC}"

# Step 1: Verify product service directory
SERVICE_DIR="$(dirname "$SCRIPT_DIR")"
if [ ! -f "$SERVICE_DIR/manage.py" ]; then
    log_error "Product service directory not found. Expected: $SERVICE_DIR"
    exit 1
fi

log_success "Found product service directory: $SERVICE_DIR"

# Step 2: Build and push Docker image
log_step "Step 1: Building and pushing Docker image..."
cd "$SERVICE_DIR"

az acr build \
    --registry $CONTAINER_REGISTRY \
    --image $IMAGE_NAME:latest \
    --file Dockerfile . \
    --timeout 1800

log_success "Docker image built and pushed to registry"

# Step 3: Get registry credentials
log_step "Step 2: Getting registry credentials..."
ACR_LOGIN_SERVER=$(az acr show --name $CONTAINER_REGISTRY --resource-group $RESOURCE_GROUP --query "loginServer" --output tsv)
ACR_USERNAME=$(az acr credential show --name $CONTAINER_REGISTRY --query "username" --output tsv)
ACR_PASSWORD=$(az acr credential show --name $CONTAINER_REGISTRY --query "passwords[0].value" --output tsv)

log_info "Registry: $ACR_LOGIN_SERVER"

# Step 4: Delete existing container if it exists
log_step "Step 3: Checking for existing container..."
EXISTING_CONTAINER=$(az container show --resource-group $RESOURCE_GROUP --name $CONTAINER_NAME --query "name" --output tsv 2>/dev/null || echo "")

if [ ! -z "$EXISTING_CONTAINER" ]; then
    log_warning "Existing container found. Deleting..."
    az container delete --resource-group $RESOURCE_GROUP --name $CONTAINER_NAME --yes
    log_success "Old container removed"
else
    log_info "No existing container found"
fi

# Step 5: Deploy new container
log_step "Step 4: Deploying to Azure Container Instances..."
az container create \
    --resource-group $RESOURCE_GROUP \
    --name $CONTAINER_NAME \
    --image $ACR_LOGIN_SERVER/$IMAGE_NAME:latest \
    --dns-name-label $CONTAINER_NAME \
    --ports $SERVICE_PORT \
    --os-type Linux \
    --registry-login-server $ACR_LOGIN_SERVER \
    --registry-username $ACR_USERNAME \
    --registry-password "$ACR_PASSWORD" \
    --cpu $CPU_CORES \
    --memory $MEMORY_GB \
    --location $LOCATION \
    --restart-policy $RESTART_POLICY \
    --environment-variables \
        SECRET_KEY="$SECRET_KEY" \
        DEBUG="$DEBUG" \
        ALLOWED_HOSTS="$ALLOWED_HOSTS" \
        DJANGO_SETTINGS_MODULE="$DJANGO_SETTINGS_MODULE" \
        CORS_ALLOW_ALL_ORIGINS="$CORS_ALLOW_ALL_ORIGINS"

log_success "Container deployed successfully"

# Step 6: Get container IP
log_step "Step 5: Getting container information..."
sleep 10  # Wait for container to initialize

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
    log_error "Failed to get container IP address"
    exit 1
fi

log_info "Container IP: $CONTAINER_IP"
log_info "Container FQDN: $CONTAINER_FQDN"

# Step 7: Check if backend pool exists, create if not
log_step "Step 6: Checking/Creating Application Gateway backend pool..."

# Check if backend pool exists
POOL_EXISTS=$(az network application-gateway address-pool show \
    --gateway-name $APP_GATEWAY_NAME \
    --resource-group $RESOURCE_GROUP \
    --name $BACKEND_POOL_NAME \
    --query "name" --output tsv 2>/dev/null || echo "")

if [ -z "$POOL_EXISTS" ]; then
    log_info "Backend pool does not exist. Creating..."
    az network application-gateway address-pool create \
        --gateway-name $APP_GATEWAY_NAME \
        --resource-group $RESOURCE_GROUP \
        --name $BACKEND_POOL_NAME \
        --servers $CONTAINER_IP
    log_success "Backend pool created"
else
    log_info "Backend pool exists. Updating..."
    az network application-gateway address-pool update \
        --gateway-name $APP_GATEWAY_NAME \
        --resource-group $RESOURCE_GROUP \
        --name $BACKEND_POOL_NAME \
        --servers $CONTAINER_IP
    log_success "Backend pool updated"
fi

# Step 8: Wait for container to fully start
log_step "Step 7: Waiting for service to start..."
sleep 30

# Step 9: Test the service
log_step "Step 8: Testing product management service..."

# Test health endpoint
if curl -f -s "http://$CONTAINER_IP:$SERVICE_PORT/health/" > /dev/null 2>&1; then
    log_success "Health endpoint is responding"
elif curl -f -s "http://$CONTAINER_IP:$SERVICE_PORT/" > /dev/null 2>&1; then
    log_success "Service root endpoint is responding"
else
    log_warning "Service may still be starting up. Manual verification recommended."
fi

# Step 10: Display deployment summary
echo ""
echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}🎉 Product Management Service Deployed!${NC}"
echo -e "${CYAN}========================================${NC}"
echo -e "${GREEN}✅ Service: BIDR Product Management Service${NC}"
echo -e "${GREEN}✅ Container: $CONTAINER_NAME${NC}"
echo -e "${GREEN}✅ Container IP: $CONTAINER_IP:$SERVICE_PORT${NC}"
echo -e "${GREEN}✅ Container FQDN: $CONTAINER_FQDN:$SERVICE_PORT${NC}"
echo ""
echo -e "${BLUE}🌐 Service Endpoints:${NC}"
echo -e "${BLUE}• Production API: https://$PRODUCTION_DOMAIN$SERVICE_PATH${NC}"
echo -e "${BLUE}• Direct Access: http://$CONTAINER_IP:$SERVICE_PORT/${NC}"
echo -e "${BLUE}• Container URL: http://$CONTAINER_FQDN:$SERVICE_PORT/${NC}"
echo ""
echo -e "${BLUE}📋 API Endpoints (when gateway routing is configured):${NC}"
echo -e "${BLUE}• Products: https://$PRODUCTION_DOMAIN$SERVICE_PATH${NC}"
echo -e "${BLUE}• Health: http://$CONTAINER_IP:$SERVICE_PORT/health/${NC}"
echo ""
echo -e "${YELLOW}🔧 Management Commands:${NC}"
echo -e "${YELLOW}• View Logs: az container logs --resource-group $RESOURCE_GROUP --name $CONTAINER_NAME${NC}"
echo -e "${YELLOW}• Follow Logs: az container logs --resource-group $RESOURCE_GROUP --name $CONTAINER_NAME --follow${NC}"
echo -e "${YELLOW}• Container Status: az container show --resource-group $RESOURCE_GROUP --name $CONTAINER_NAME${NC}"
echo -e "${YELLOW}• Restart Container: az container restart --resource-group $RESOURCE_GROUP --name $CONTAINER_NAME${NC}"
echo -e "${YELLOW}• Delete Container: az container delete --resource-group $RESOURCE_GROUP --name $CONTAINER_NAME --yes${NC}"
echo ""
echo -e "${GREEN}🔐 Security Configuration:${NC}"
echo -e "${GREEN}✅ Environment: Production${NC}"
echo -e "${GREEN}✅ CORS: $CORS_ALLOW_ALL_ORIGINS${NC}"
echo -e "${GREEN}✅ Debug Mode: $DEBUG${NC}"
echo ""
echo -e "${CYAN}⚠️  Next Steps:${NC}"
echo -e "${CYAN}1. Configure Application Gateway routing rules to point https://$PRODUCTION_DOMAIN to this backend pool${NC}"
echo -e "${CYAN}2. Set up DNS for $PRODUCTION_DOMAIN to point to the Application Gateway${NC}"
echo -e "${CYAN}3. Test the service via the production domain${NC}"
echo ""
echo -e "${GREEN}🎊 Your product management service is now deployed and ready for gateway configuration!${NC}"
echo -e "${CYAN}========================================${NC}"
