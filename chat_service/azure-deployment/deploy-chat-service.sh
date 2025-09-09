#!/bin/bash

# BIDR Chat Service - Azure Container Instances Deployment Script
# This script builds and deploys the chat service to Azure Container Instances
# and updates the Application Gateway backend pool for routing.

set -e  # Exit on any error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
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
    echo -e "${BLUE}🔄 $1${NC}"
}

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVICE_DIR="$(dirname "$SCRIPT_DIR")"
CONFIG_FILE="$SCRIPT_DIR/chat-service-config.env"

# Check if config file exists
if [ ! -f "$CONFIG_FILE" ]; then
    log_error "Configuration file not found: $CONFIG_FILE"
    exit 1
fi

# Load configuration
source "$CONFIG_FILE"
log_success "Configuration loaded from $CONFIG_FILE"

# Display deployment information
echo "========================================"
echo "🚀 BIDR Chat Service Deployment"
echo "========================================"
echo "Resource Group: $RESOURCE_GROUP"
echo "Container Registry: $CONTAINER_REGISTRY"
echo "Container Name: $CONTAINER_NAME"
echo "Production URL: $PRODUCTION_URL"
echo "========================================"

# Verify we're in the chat service directory
if [ ! -f "$SERVICE_DIR/manage.py" ]; then
    log_error "manage.py not found in $SERVICE_DIR. Are you in the correct directory?"
    exit 1
fi

log_success "Found chat service directory: $SERVICE_DIR"

# Step 1: Build and push Docker image
log_step "Step 1: Building and pushing Docker image..."
cd "$SERVICE_DIR"
az acr build --registry $CONTAINER_REGISTRY \
    --image ${IMAGE_NAME}:latest \
    --file Dockerfile \
    .

log_success "Docker image built and pushed to registry"

# Step 2: Get registry credentials
log_step "Step 2: Getting registry credentials..."
REGISTRY_SERVER="${CONTAINER_REGISTRY}.azurecr.io"
log_info "Registry: $REGISTRY_SERVER"

# Step 3: Check for existing container
log_step "Step 3: Checking for existing container..."
if az container show --resource-group $RESOURCE_GROUP --name $CONTAINER_NAME &>/dev/null; then
    log_warning "Existing container found. Deleting..."
    az container delete --resource-group $RESOURCE_GROUP --name $CONTAINER_NAME --yes
    log_success "Old container removed"
fi

# Step 4: Deploy to Azure Container Instances
log_step "Step 4: Deploying to Azure Container Instances..."

# Evaluate dynamic variables
BIDR_VERSION="v$(date +%s)"
DEPLOYMENT_TIMESTAMP="$(date)"

az container create \
    --resource-group $RESOURCE_GROUP \
    --name $CONTAINER_NAME \
    --image "${REGISTRY_SERVER}/${IMAGE_NAME}:latest" \
    --registry-login-server $REGISTRY_SERVER \
    --registry-username $CONTAINER_REGISTRY \
    --registry-password $(az acr credential show --name $CONTAINER_REGISTRY --query passwords[0].value -o tsv) \
    --dns-name-label $DNS_LABEL \
    --ports $SERVICE_PORT \
    --cpu $CPU_CORES \
    --memory $MEMORY_GB \
    --restart-policy $RESTART_POLICY \
    --location $LOCATION \
    --os-type Linux \
    --environment-variables \
        SECRET_KEY="$SECRET_KEY" \
        DEBUG="$DEBUG" \
        ALLOWED_HOSTS="$ALLOWED_HOSTS" \
        DJANGO_SETTINGS_MODULE="$DJANGO_SETTINGS_MODULE" \
        CORS_ALLOW_ALL_ORIGINS="$CORS_ALLOW_ALL_ORIGINS" \
        CHAT_ENCRYPTION_KEY="$CHAT_ENCRYPTION_KEY" \
        WEBSOCKET_ENABLED="$WEBSOCKET_ENABLED" \
        MAX_MESSAGE_LENGTH="$MAX_MESSAGE_LENGTH" \
        MAX_FILE_SIZE_MB="$MAX_FILE_SIZE_MB" \
        NOTIFICATIONS_SERVICE_URL="$NOTIFICATIONS_SERVICE_URL" \
        PUSH_NOTIFICATIONS_ENABLED="$PUSH_NOTIFICATIONS_ENABLED" \
        ENABLE_CONTENT_MODERATION="$ENABLE_CONTENT_MODERATION" \
        AUTO_MODERATION="$AUTO_MODERATION" \
        PROFANITY_FILTER="$PROFANITY_FILTER" \
        USE_SQLITE="$USE_SQLITE" \
        SERVICE_NAME_DISPLAY="$SERVICE_NAME_DISPLAY" \
        BIDR_VERSION="$BIDR_VERSION" \
        DEPLOYMENT_TIMESTAMP="$DEPLOYMENT_TIMESTAMP"

log_success "Container deployed successfully"

# Step 5: Get container information
log_step "Step 5: Getting container information..."
CONTAINER_INFO=$(az container show --resource-group $RESOURCE_GROUP --name $CONTAINER_NAME)
CONTAINER_IP=$(echo "$CONTAINER_INFO" | jq -r '.ipAddress.ip')
CONTAINER_FQDN=$(echo "$CONTAINER_INFO" | jq -r '.ipAddress.fqdn')

log_info "Container IP: $CONTAINER_IP"
log_info "Container FQDN: $CONTAINER_FQDN"

# Step 6: Check/Update Application Gateway backend pool
log_step "Step 6: Checking/Creating Application Gateway backend pool..."

# Check if backend pool exists, create if it doesn't
if ! az network application-gateway address-pool show \
    --resource-group $RESOURCE_GROUP \
    --gateway-name $APP_GATEWAY_NAME \
    --name $BACKEND_POOL_NAME &>/dev/null; then
    
    log_info "Backend pool doesn't exist. Creating..."
    az network application-gateway address-pool create \
        --resource-group $RESOURCE_GROUP \
        --gateway-name $APP_GATEWAY_NAME \
        --name $BACKEND_POOL_NAME \
        --servers $CONTAINER_IP
    log_success "Backend pool created"
else
    log_info "Backend pool exists. Updating..."
    az network application-gateway address-pool update \
        --resource-group $RESOURCE_GROUP \
        --gateway-name $APP_GATEWAY_NAME \
        --name $BACKEND_POOL_NAME \
        --servers $CONTAINER_IP
    log_success "Backend pool updated"
fi

# Step 7: Wait for service to start
log_step "Step 7: Waiting for service to start..."
sleep 20

# Step 8: Test chat service
log_step "Step 8: Testing chat service..."
if curl -f http://$CONTAINER_IP:$SERVICE_PORT/health/ &>/dev/null; then
    log_success "Health endpoint is responding"
elif curl -f http://$CONTAINER_IP:$SERVICE_PORT/ &>/dev/null; then
    log_success "Service is responding (health endpoint may not be available)"
else
    log_warning "Service not responding, but it may still be starting"
fi

# Deployment complete
echo ""
echo "========================================"
echo "🎉 Chat Service Deployed!"
echo "========================================"
log_success "Service: $SERVICE_NAME_DISPLAY"
log_success "Container: $CONTAINER_NAME"
log_success "Container IP: $CONTAINER_IP:$SERVICE_PORT"
log_success "Container FQDN: $CONTAINER_FQDN:$SERVICE_PORT"

echo ""
echo "🌐 Service Endpoints:"
echo "• Production API: $PRODUCTION_URL"
echo "• Direct Access: http://$CONTAINER_IP:$SERVICE_PORT/"
echo "• Container URL: http://$CONTAINER_FQDN:$SERVICE_PORT/"

echo ""
echo "📋 API Endpoints (when gateway routing is configured):"
echo "• WebSocket: wss://chat-service.bidr.co.za/ws/chat/"
echo "• REST API: $PRODUCTION_URL/api/v1/"
echo "• Health: http://$CONTAINER_IP:$SERVICE_PORT/health/"
echo "• Admin: http://$CONTAINER_IP:$SERVICE_PORT/admin/"

echo ""
echo "🔧 Management Commands:"
echo "• View Logs: az container logs --resource-group $RESOURCE_GROUP --name $CONTAINER_NAME"
echo "• Follow Logs: az container logs --resource-group $RESOURCE_GROUP --name $CONTAINER_NAME --follow"
echo "• Container Status: az container show --resource-group $RESOURCE_GROUP --name $CONTAINER_NAME"
echo "• Restart Container: az container restart --resource-group $RESOURCE_GROUP --name $CONTAINER_NAME"
echo "• Delete Container: az container delete --resource-group $RESOURCE_GROUP --name $CONTAINER_NAME --yes"

echo ""
echo "🔐 Security Configuration:"
log_success "Environment: Production"
log_success "CORS: $CORS_ALLOW_ALL_ORIGINS"
log_success "Debug Mode: $DEBUG"
log_success "WebSocket: $WEBSOCKET_ENABLED"
log_success "Content Moderation: $ENABLE_CONTENT_MODERATION"

echo ""
echo "⚠️  Next Steps:"
echo "1. Configure Application Gateway routing rules to point $PRODUCTION_URL to this backend pool"
echo "2. Set up DNS for $DOMAIN_NAME to point to the Application Gateway"
echo "3. Test WebSocket connections via the production domain"
echo "4. Configure SSL certificate for secure WebSocket connections (WSS)"
echo "5. Test the chat functionality end-to-end"

echo ""
echo "🎊 Your chat service is now deployed and ready for gateway configuration!"
echo "========================================"

cd "$SCRIPT_DIR"
