#!/bin/bash

# BIDR Authentication Service Update Script
# This script rebuilds and redeploys the authentication service

set -e

echo "🔄 Updating BIDR Authentication Service..."

# Configuration
RESOURCE_GROUP="bidr-simple-rg"
REGISTRY_NAME="bidrsimpleregistry"
CONTAINER_NAME="bidr-auth-service"
SERVICE_NAME="bidr-auth-service"
IMAGE_NAME="bidr-authentication-service"
SERVICE_PORT=8001

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

# Get the authentication service directory path
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AUTH_SERVICE_DIR="$(dirname "$SCRIPT_DIR")/authentication_service"

# Check if authentication service directory exists
if [ ! -d "$AUTH_SERVICE_DIR" ]; then
    print_error "Authentication service directory not found at: $AUTH_SERVICE_DIR"
    print_error "Please make sure you're running this from the correct location."
    exit 1
fi

print_status "Found authentication service directory: $AUTH_SERVICE_DIR"

# Check if Dockerfile exists
if [ ! -f "$AUTH_SERVICE_DIR/Dockerfile" ]; then
    print_error "Dockerfile not found in authentication service directory."
    exit 1
fi

# Change to authentication service directory
cd "$AUTH_SERVICE_DIR"
print_status "Changed to authentication service directory"

# Step 1: Build and push new image with timestamp tag
TIMESTAMP=$(date +%s)
NEW_TAG="v${TIMESTAMP}"
print_status "Step 1: Building and pushing Docker image with tag: ${NEW_TAG}..."

az acr build \
    --registry $REGISTRY_NAME \
    --image "${IMAGE_NAME}:${NEW_TAG}" \
    --image "${IMAGE_NAME}:latest" \
    .

print_success "New image built and pushed with tag: ${NEW_TAG}"

# Step 2: Get current container information
print_status "Step 2: Getting current container information..."
CURRENT_CONTAINER=$(az container show \
    --resource-group $RESOURCE_GROUP \
    --name $CONTAINER_NAME \
    --query '{ip: ipAddress.ip, fqdn: ipAddress.fqdn}' \
    --output json 2>/dev/null || echo '{}')

if [ "$CURRENT_CONTAINER" = "{}" ]; then
    print_warning "Container not found. This might be the first deployment."
    CURRENT_IP=""
    CURRENT_FQDN=""
else
    CURRENT_IP=$(echo $CURRENT_CONTAINER | jq -r '.ip // ""')
    CURRENT_FQDN=$(echo $CURRENT_CONTAINER | jq -r '.fqdn // ""')
    print_status "Current service IP: $CURRENT_IP"
    print_status "Current service FQDN: $CURRENT_FQDN"
fi

# Step 3: Delete existing container
print_status "Step 3: Stopping existing container..."
az container delete \
    --resource-group $RESOURCE_GROUP \
    --name $CONTAINER_NAME \
    --yes \
    --no-wait 2>/dev/null || print_warning "No existing container to delete"

# Wait a moment for cleanup
sleep 10

# Step 4: Get registry credentials
print_status "Step 4: Getting registry credentials..."
REGISTRY_SERVER="${REGISTRY_NAME}.azurecr.io"
REGISTRY_USERNAME=$(az acr credential show --name $REGISTRY_NAME --query username --output tsv)
REGISTRY_PASSWORD=$(az acr credential show --name $REGISTRY_NAME --query passwords[0].value --output tsv)

# Step 5: Deploy updated container
print_status "Step 5: Deploying updated container..."

# Generate new DNS label to avoid conflicts
DNS_LABEL="bidr-auth-$(date +%s)"

# Generate new secret keys for security
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
        DJANGO_SETTINGS_MODULE=authentication_service.settings \
        JWT_SECRET_KEY="$JWT_SECRET_KEY" \
        CORS_ALLOW_ALL_ORIGINS=True \
    --no-wait

print_success "Container deployment initiated"

# Step 6: Wait for deployment and get new information
print_status "Step 6: Waiting for deployment to complete..."
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

# Step 7: Display results
echo ""
echo "========================================"
echo "🎉 Authentication Service Updated!"
echo "========================================"
echo "Service Name: BIDR Authentication Service"
echo "Image Tag: ${NEW_TAG}"
echo "Container State: $CONTAINER_STATE"
echo "Provisioning State: $PROVISIONING_STATE"
echo "Public IP: $NEW_IP"
echo "FQDN: $NEW_FQDN"
echo "Service URL: http://${NEW_FQDN}:${SERVICE_PORT}"
echo "Admin URL: http://${NEW_FQDN}:${SERVICE_PORT}/admin/"
echo "API URL: http://${NEW_FQDN}:${SERVICE_PORT}/api/"
echo "Health Check: http://${NEW_FQDN}:${SERVICE_PORT}/health/"
echo "========================================"

# Step 8: Test the updated service
print_status "Step 8: Testing updated service..."
echo "⏳ Service is starting up, testing API endpoint..."
sleep 15

MAX_RETRIES=5
RETRY_COUNT=0
while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "http://${NEW_FQDN}:${SERVICE_PORT}/health/" --connect-timeout 10 --max-time 30 || echo "000")
    
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
echo "curl http://${NEW_FQDN}:${SERVICE_PORT}/health/"
echo ""
echo "📋 Check logs with:"
echo "az container logs --resource-group $RESOURCE_GROUP --name $CONTAINER_NAME"
echo ""
echo "🎊 Authentication Service update complete!"
echo "========================================"
