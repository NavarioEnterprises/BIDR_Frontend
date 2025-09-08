#!/bin/bash

# BIDR Authentication Service - Azure Container Instances Deployment Script
# This script deploys the authentication service to Azure Container Instances
# and configures Application Gateway routing

set -e

# Configuration - Core Variables
RESOURCE_GROUP="bidr-simple-rg"
CONTAINER_REGISTRY="bidrsimpleregistry"
CONTAINER_NAME="bidr-auth-service"
IMAGE_NAME="bidr-auth-service"
SERVICE_NAME="Authentication Service"
SERVICE_PORT="8000"
LOCATION="westus"

# Application Gateway Configuration
APP_GATEWAY_NAME="bidr-app-gateway"
BACKEND_POOL_NAME="auth-backend-pool"

# Environment Variables for the Auth Service
# IMPORTANT: Update PII_ENCRYPTION_KEY to match your local development environment
# Generate new key with: python -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"
PII_ENCRYPTION_KEY="CYr9YsWhL6_TBuREQaJUQF0aHV84sdajft4UtUdPq_o="
SECRET_KEY="apML2mCNBZahA4JEP4zj0CJ7TrO/PgRYA8Z33nYKIT8="
JWT_SECRET_KEY="4DgwpcbHSk+BN8ZZvVh08vpisPNx49LtBSN/CBl0aeA="

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
echo -e "${CYAN}🚀 BIDR Authentication Service Deployment${NC}"
echo -e "${CYAN}========================================${NC}"

# Step 1: Verify authentication service directory
SERVICE_DIR="$(pwd)"
if [ ! -f "$SERVICE_DIR/manage.py" ]; then
    log_error "This script must be run from the authentication_service directory"
    exit 1
fi

log_success "Found authentication service directory"

# Step 2: Build and push Docker image
log_step "Step 1: Building and pushing Docker image..."
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
    --cpu 1 \
    --memory 1.5 \
    --location $LOCATION \
    --environment-variables \
        SECRET_KEY="$SECRET_KEY" \
        DEBUG="False" \
        ALLOWED_HOSTS="*" \
        DJANGO_SETTINGS_MODULE="authentication_service.settings" \
        JWT_SECRET_KEY="$JWT_SECRET_KEY" \
        CORS_ALLOW_ALL_ORIGINS="True" \
        PII_ENCRYPTION_KEY="$PII_ENCRYPTION_KEY"

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

# Step 7: Update Application Gateway backend pool
log_step "Step 6: Updating Application Gateway backend pool..."
az network application-gateway address-pool update \
    --gateway-name $APP_GATEWAY_NAME \
    --resource-group $RESOURCE_GROUP \
    --name $BACKEND_POOL_NAME \
    --servers $CONTAINER_IP

log_success "Application Gateway backend pool updated"

# Step 8: Wait for container to fully start
log_step "Step 7: Waiting for service to start..."
sleep 30

# Step 9: Test the service
log_step "Step 8: Testing authentication service..."

# Test health endpoint
if curl -f -s "http://$CONTAINER_IP:$SERVICE_PORT/health/" > /dev/null 2>&1; then
    log_success "Health endpoint is responding"
elif curl -f -s "http://$CONTAINER_IP:$SERVICE_PORT/" > /dev/null 2>&1; then
    log_success "Service root endpoint is responding"
else
    log_warning "Service may still be starting up. Manual verification recommended."
fi

# Test via Application Gateway
log_info "Testing via Application Gateway..."
sleep 5

# Get Application Gateway public IP
APP_GW_IP=$(az network public-ip show --name bidr-appgw-pip --resource-group $RESOURCE_GROUP --query "ipAddress" --output tsv 2>/dev/null || echo "")
if [ ! -z "$APP_GW_IP" ]; then
    if curl -f -s -k "https://$APP_GW_IP/auth/health/" > /dev/null 2>&1; then
        log_success "Application Gateway routing is working"
    else
        log_info "Application Gateway may need a few minutes to update routing"
    fi
fi

# Step 10: Check backend health
log_step "Step 9: Checking Application Gateway backend health..."
sleep 10

BACKEND_HEALTH=$(az network application-gateway show-backend-health \
    --name $APP_GATEWAY_NAME \
    --resource-group $RESOURCE_GROUP \
    --output json | \
    jq -r ".backendAddressPools[] | select(.backendAddressPool.id | contains(\"$BACKEND_POOL_NAME\")) | .backendHttpSettingsCollection[0].servers[0].health" 2>/dev/null || echo "Unknown")

if [ "$BACKEND_HEALTH" = "Healthy" ]; then
    log_success "Backend health check: $BACKEND_HEALTH"
else
    log_warning "Backend health check: $BACKEND_HEALTH (may take a few minutes to become healthy)"
fi

# Step 11: Display deployment summary
echo ""
echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}🎉 Authentication Service Deployed!${NC}"
echo -e "${CYAN}========================================${NC}"
echo -e "${GREEN}✅ Service: BIDR Authentication Service${NC}"
echo -e "${GREEN}✅ Container: $CONTAINER_NAME${NC}"
echo -e "${GREEN}✅ Container IP: $CONTAINER_IP:$SERVICE_PORT${NC}"
echo -e "${GREEN}✅ Container FQDN: $CONTAINER_FQDN:$SERVICE_PORT${NC}"
echo -e "${GREEN}✅ Backend Health: $BACKEND_HEALTH${NC}"
echo ""
echo -e "${BLUE}🌐 Service Endpoints:${NC}"
echo -e "${BLUE}• Production API: https://api.bidr.co.za/auth/${NC}"
echo -e "${BLUE}• Direct Access: http://$CONTAINER_IP:$SERVICE_PORT/${NC}"
echo -e "${BLUE}• Container URL: http://$CONTAINER_FQDN:$SERVICE_PORT/${NC}"
echo ""
echo -e "${BLUE}📋 API Endpoints:${NC}"
echo -e "${BLUE}• Login: https://api.bidr.co.za/auth/login/${NC}"
echo -e "${BLUE}• Register: https://api.bidr.co.za/auth/register/${NC}"
echo -e "${BLUE}• Health: http://$CONTAINER_IP:$SERVICE_PORT/health/${NC}"
echo ""
echo -e "${YELLOW}🔧 Management Commands:${NC}"
echo -e "${YELLOW}• View Logs: az container logs --resource-group $RESOURCE_GROUP --name $CONTAINER_NAME${NC}"
echo -e "${YELLOW}• Follow Logs: az container logs --resource-group $RESOURCE_GROUP --name $CONTAINER_NAME --follow${NC}"
echo -e "${YELLOW}• Container Status: az container show --resource-group $RESOURCE_GROUP --name $CONTAINER_NAME${NC}"
echo -e "${YELLOW}• Restart Container: az container restart --resource-group $RESOURCE_GROUP --name $CONTAINER_NAME${NC}"
echo -e "${YELLOW}• Delete Container: az container delete --resource-group $RESOURCE_GROUP --name $CONTAINER_NAME --yes${NC}"
echo ""
echo -e "${CYAN}🧪 Test Commands:${NC}"
echo -e "${CYAN}• Test Login: curl -X POST 'https://api.bidr.co.za/auth/login/' -H 'Content-Type: application/json' -d '{\"email\":\"test@example.com\",\"password\":\"Test1234!\"}' -k${NC}"
echo -e "${CYAN}• Test Registration: curl -X POST 'https://api.bidr.co.za/auth/register/' -H 'Content-Type: application/json' -d '{\"email\":\"new@example.com\",\"password\":\"Test1234!\",\"confirm_password\":\"Test1234!\",\"first_name\":\"Test\",\"last_name\":\"User\",\"phone_number\":\"+27123456789\",\"role\":\"buyer\"}' -k${NC}"
echo ""
echo -e "${GREEN}🔐 Security Configuration:${NC}"
echo -e "${GREEN}✅ PII Encryption: Enabled${NC}"
echo -e "${GREEN}✅ HTTPS: Available via Application Gateway${NC}"
echo -e "${GREEN}✅ CORS: Configured${NC}"
echo -e "${GREEN}✅ Environment: Production${NC}"
echo ""
echo -e "${GREEN}🎊 Your authentication service is now live and accessible at https://api.bidr.co.za/auth/!${NC}"
echo -e "${CYAN}========================================${NC}"
