#!/bin/bash

# BIDR Chat Service Deployment Script
# This script builds and deploys the chat service to Azure Container Instances

set -e

echo "🚀 Deploying BIDR Chat Service..."

# Configuration
RESOURCE_GROUP="bidr-simple-rg"
REGISTRY_NAME="bidrsimpleregistry"
CONTAINER_NAME="bidr-chat-service"
SERVICE_NAME="bidr-chat-service"
IMAGE_NAME="bidr-chat-service"
SERVICE_PORT=8002

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}$1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Get the chat service directory path
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHAT_SERVICE_DIR="$(dirname "$SCRIPT_DIR")/chat_service"

# Check if chat service directory exists
if [ ! -d "$CHAT_SERVICE_DIR" ]; then
    print_error "Chat service directory not found at: $CHAT_SERVICE_DIR"
    print_error "Please make sure you're running this from the correct location."
    exit 1
fi

print_status "Found chat service directory: $CHAT_SERVICE_DIR"

# Check if Dockerfile exists
if [ ! -f "$CHAT_SERVICE_DIR/Dockerfile" ]; then
    print_error "Dockerfile not found in chat service directory."
    exit 1
fi

# Change to chat service directory
cd "$CHAT_SERVICE_DIR"
print_status "Changed to chat service directory"

# Step 1: Build and push new image
print_status "Step 1: Building and pushing Docker image..."

az acr build \
    --registry $REGISTRY_NAME \
    --image "${IMAGE_NAME}:latest" \
    .

print_success "Chat service image built and pushed"

# Step 2: Get registry credentials
print_status "Step 2: Getting registry credentials..."
REGISTRY_SERVER="${REGISTRY_NAME}.azurecr.io"
REGISTRY_USERNAME=$(az acr credential show --name $REGISTRY_NAME --query username --output tsv)
REGISTRY_PASSWORD=$(az acr credential show --name $REGISTRY_NAME --query passwords[0].value --output tsv)

# Step 3: Deploy to Azure Container Instances
print_status "Step 3: Deploying to Azure Container Instances..."

# Generate DNS label
DNS_LABEL="bidr-chat-$(date +%s)"

# Generate secret keys for security
SECRET_KEY=$(python3 -c "import secrets; print(secrets.token_urlsafe(32))")
JWT_SECRET_KEY=$(python3 -c "import secrets; print(secrets.token_urlsafe(32))")

az container create \
    --resource-group $RESOURCE_GROUP \
    --name $CONTAINER_NAME \
    --image "${REGISTRY_SERVER}/${IMAGE_NAME}:latest" \
    --registry-login-server $REGISTRY_SERVER \
    --registry-username $REGISTRY_USERNAME \
    --registry-password $REGISTRY_PASSWORD \
    --dns-name-label $DNS_LABEL \
    --ports $SERVICE_PORT \
    --cpu 1 \
    --memory 1.5 \
    --restart-policy OnFailure \
    --os-type Linux \
    --environment-variables \
        SECRET_KEY="$SECRET_KEY" \
        DEBUG=False \
        ALLOWED_HOSTS="*" \
        DJANGO_SETTINGS_MODULE=chat_service.settings \
        JWT_SECRET_KEY="$JWT_SECRET_KEY" \
        CORS_ALLOW_ALL_ORIGINS=True

print_success "Chat service deployed"

# Step 4: Get deployment information
print_status "Step 4: Getting deployment information..."
CONTAINER_INFO=$(az container show \
    --resource-group $RESOURCE_GROUP \
    --name $CONTAINER_NAME \
    --query '{
        ip: ipAddress.ip,
        fqdn: ipAddress.fqdn,
        state: instanceView.state,
        provisioningState: provisioningState
    }' \
    --output json)

CONTAINER_IP=$(echo $CONTAINER_INFO | jq -r '.ip // "N/A"')
CONTAINER_FQDN=$(echo $CONTAINER_INFO | jq -r '.fqdn // "N/A"')
CONTAINER_STATE=$(echo $CONTAINER_INFO | jq -r '.state // "Unknown"')
PROVISIONING_STATE=$(echo $CONTAINER_INFO | jq -r '.provisioningState // "Unknown"')

echo ""
echo "========================================"
echo "🎉 Chat Service Deployed!"
echo "========================================"
echo "Service Name: BIDR Chat Service"
echo "Container State: $CONTAINER_STATE"
echo "Provisioning State: $PROVISIONING_STATE"
echo "Public IP: $CONTAINER_IP"
echo "FQDN: $CONTAINER_FQDN"
echo "Service URL: http://${CONTAINER_FQDN}:${SERVICE_PORT}"
echo "Admin URL: http://${CONTAINER_FQDN}:${SERVICE_PORT}/admin/"
echo "API URL: http://${CONTAINER_FQDN}:${SERVICE_PORT}/api/"
echo "Health Check: http://${CONTAINER_FQDN}:${SERVICE_PORT}/health/"
echo "========================================"

# Step 5: Test the service
print_status "Step 5: Testing chat service..."
echo "⏳ Service is starting up, testing API endpoint..."
sleep 15

MAX_RETRIES=5
RETRY_COUNT=0
while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "http://${CONTAINER_FQDN}:${SERVICE_PORT}/health/" --connect-timeout 10 --max-time 30 || echo "000")
    
    if [ "$HTTP_STATUS" = "200" ]; then
        print_success "Service is healthy and responding!"
        break
    else
        RETRY_COUNT=$((RETRY_COUNT + 1))
        if [ $RETRY_COUNT -lt $MAX_RETRIES ]; then
            print_warning "Service not ready yet (attempt $RETRY_COUNT/$MAX_RETRIES). Waiting 15 seconds..."
            sleep 15
        else
            print_warning "Service may still be starting up. Check logs if needed:"
            echo "az container logs --resource-group $RESOURCE_GROUP --name $CONTAINER_NAME"
        fi
    fi
done

echo ""
echo "🎯 Quick Test Command:"
echo "curl http://${CONTAINER_FQDN}:${SERVICE_PORT}/health/"
echo ""
echo "🎊 Chat Service deployment complete!"
echo "========================================"
