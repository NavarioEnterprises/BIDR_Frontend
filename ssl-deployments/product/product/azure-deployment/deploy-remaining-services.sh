#!/bin/bash

# BIDR All Remaining Services Deployment Script
# This script deploys chat, payment, resolution, notifications, transactions, and reviews services

set -e

echo "🚀 Deploying All Remaining BIDR Services..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Function to print colored output
print_header() {
    echo -e "${PURPLE}$1${NC}"
}

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

# Configuration
RESOURCE_GROUP="bidr-simple-rg"
REGISTRY_NAME="bidrsimpleregistry"
REGISTRY_SERVER="${REGISTRY_NAME}.azurecr.io"

# Get registry credentials once
print_status "Getting Azure Container Registry credentials..."
REGISTRY_USERNAME=$(az acr credential show --name $REGISTRY_NAME --query username --output tsv)
REGISTRY_PASSWORD=$(az acr credential show --name $REGISTRY_NAME --query passwords[0].value --output tsv)

# Get script directory and base path
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"

# Service configuration array
# Format: service_name:port:directory_name
SERVICES=(
    "chat:8002:chat_service"
    "payment:8003:payment_service"
    "resolution:8004:resolution_service"
    "notifications:8005:notifications_service"
    "transactions:8006:transactions_service"
    "reviews:8007:reviews_and_ratings"
)

# Function to deploy a single service
deploy_service() {
    local SERVICE_NAME=$1
    local SERVICE_PORT=$2
    local SERVICE_DIR_NAME=$3
    
    print_header "🔄 Deploying $SERVICE_NAME Service"
    echo "========================================"
    
    SERVICE_DIR="$BASE_DIR/$SERVICE_DIR_NAME"
    CONTAINER_NAME="bidr-${SERVICE_NAME}-service"
    IMAGE_NAME="bidr-${SERVICE_NAME}-service"
    
    # Check if service directory exists
    if [ ! -d "$SERVICE_DIR" ]; then
        print_error "$SERVICE_NAME service directory not found at: $SERVICE_DIR"
        return 1
    fi
    
    # Check if Dockerfile exists
    if [ ! -f "$SERVICE_DIR/Dockerfile" ]; then
        print_error "Dockerfile not found in $SERVICE_NAME service directory."
        return 1
    fi
    
    print_status "Found $SERVICE_NAME service directory: $SERVICE_DIR"
    
    # Change to service directory
    cd "$SERVICE_DIR"
    
    # Step 1: Build and push image
    print_status "Step 1: Building and pushing Docker image for $SERVICE_NAME..."
    
    az acr build \
        --registry $REGISTRY_NAME \
        --image "${IMAGE_NAME}:latest" \
        . || {
        print_error "Failed to build $SERVICE_NAME service image"
        return 1
    }
    
    print_success "$SERVICE_NAME service image built and pushed"
    
    # Step 2: Deploy to Azure Container Instances
    print_status "Step 2: Deploying $SERVICE_NAME to Azure Container Instances..."
    
    # Generate DNS label
    DNS_LABEL="bidr-${SERVICE_NAME}-$(date +%s)"
    
    # Generate secret keys
    SECRET_KEY=$(python3 -c "import secrets; print(secrets.token_urlsafe(32))")
    JWT_SECRET_KEY=$(python3 -c "import secrets; print(secrets.token_urlsafe(32))")
    
    # Determine Django settings module
    if [ "$SERVICE_NAME" = "reviews" ]; then
        DJANGO_SETTINGS="reviews_and_ratings.settings"
    else
        DJANGO_SETTINGS="${SERVICE_NAME}_service.settings"
    fi
    
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
            DJANGO_SETTINGS_MODULE=$DJANGO_SETTINGS \
            JWT_SECRET_KEY="$JWT_SECRET_KEY" \
            CORS_ALLOW_ALL_ORIGINS=True || {
        print_error "Failed to deploy $SERVICE_NAME service"
        return 1
    }
    
    print_success "$SERVICE_NAME service deployment initiated"
    
    # Step 3: Get deployment information
    print_status "Step 3: Getting deployment information..."
    sleep 10  # Wait a moment for deployment to register
    
    CONTAINER_INFO=$(az container show \
        --resource-group $RESOURCE_GROUP \
        --name $CONTAINER_NAME \
        --query '{
            ip: ipAddress.ip,
            fqdn: ipAddress.fqdn,
            state: instanceView.state,
            provisioningState: provisioningState
        }' \
        --output json 2>/dev/null) || {
        print_warning "Could not get container info immediately, service may still be starting"
        CONTAINER_INFO='{"ip":"N/A","fqdn":"N/A","state":"Unknown","provisioningState":"Unknown"}'
    }
    
    CONTAINER_IP=$(echo $CONTAINER_INFO | jq -r '.ip // "N/A"')
    CONTAINER_FQDN=$(echo $CONTAINER_INFO | jq -r '.fqdn // "N/A"')
    CONTAINER_STATE=$(echo $CONTAINER_INFO | jq -r '.state // "Unknown"')
    PROVISIONING_STATE=$(echo $CONTAINER_INFO | jq -r '.provisioningState // "Unknown"')
    
    # Store service info for final summary
    echo "${SERVICE_NAME}|${CONTAINER_FQDN}|${SERVICE_PORT}|${CONTAINER_IP}" >> "/tmp/bidr_services.txt"
    
    echo ""
    echo "========================================"
    echo "🎉 $SERVICE_NAME Service Deployed!"
    echo "========================================"
    echo "Service Name: BIDR $SERVICE_NAME Service"
    echo "Container State: $CONTAINER_STATE"
    echo "Provisioning State: $PROVISIONING_STATE"
    echo "Public IP: $CONTAINER_IP"
    echo "FQDN: $CONTAINER_FQDN"
    echo "Service URL: http://${CONTAINER_FQDN}:${SERVICE_PORT}"
    echo "Admin URL: http://${CONTAINER_FQDN}:${SERVICE_PORT}/admin/"
    echo "API URL: http://${CONTAINER_FQDN}:${SERVICE_PORT}/api/"
    echo "Health Check: http://${CONTAINER_FQDN}:${SERVICE_PORT}/health/"
    echo "========================================"
    echo ""
    
    return 0
}

# Initialize service tracking file
rm -f "/tmp/bidr_services.txt"
touch "/tmp/bidr_services.txt"

# Deploy each service
SUCCESSFUL_DEPLOYMENTS=0
FAILED_DEPLOYMENTS=0

for SERVICE_CONFIG in "${SERVICES[@]}"; do
    IFS=':' read -r SERVICE_NAME SERVICE_PORT SERVICE_DIR_NAME <<< "$SERVICE_CONFIG"
    
    if deploy_service "$SERVICE_NAME" "$SERVICE_PORT" "$SERVICE_DIR_NAME"; then
        SUCCESSFUL_DEPLOYMENTS=$((SUCCESSFUL_DEPLOYMENTS + 1))
        print_success "$SERVICE_NAME service deployed successfully"
    else
        FAILED_DEPLOYMENTS=$((FAILED_DEPLOYMENTS + 1))
        print_error "$SERVICE_NAME service deployment failed"
    fi
    
    echo ""
    echo "=================================================="
    echo ""
done

# Return to original directory
cd "$SCRIPT_DIR"

# Final summary
print_header "📊 Deployment Summary"
echo "========================================"
echo "✅ Successful deployments: $SUCCESSFUL_DEPLOYMENTS"
echo "❌ Failed deployments: $FAILED_DEPLOYMENTS"
echo ""

# Display all service URLs
if [ -f "/tmp/bidr_services.txt" ] && [ -s "/tmp/bidr_services.txt" ]; then
    print_header "🌐 All BIDR Service URLs"
    echo "========================================"
    
    # Get existing services
    print_status "Getting existing service information..."
    PRODUCT_INFO=$(az container show --resource-group $RESOURCE_GROUP --name bidr-product-service --query '{fqdn: ipAddress.fqdn, ip: ipAddress.ip}' --output json 2>/dev/null || echo '{"fqdn":"N/A","ip":"N/A"}')
    AUTH_INFO=$(az container show --resource-group $RESOURCE_GROUP --name bidr-auth-service --query '{fqdn: ipAddress.fqdn, ip: ipAddress.ip}' --output json 2>/dev/null || echo '{"fqdn":"N/A","ip":"N/A"}')
    
    PRODUCT_FQDN=$(echo $PRODUCT_INFO | jq -r '.fqdn // "N/A"')
    PRODUCT_IP=$(echo $PRODUCT_INFO | jq -r '.ip // "N/A"')
    AUTH_FQDN=$(echo $AUTH_INFO | jq -r '.fqdn // "N/A"')
    AUTH_IP=$(echo $AUTH_INFO | jq -r '.ip // "N/A"')
    
    echo ""
    echo "📦 Product Management Service:"
    echo "   URL: http://$PRODUCT_FQDN:8000"
    echo "   IP: $PRODUCT_IP"
    echo ""
    echo "🔐 Authentication Service:"
    echo "   URL: http://$AUTH_FQDN:8001"
    echo "   IP: $AUTH_IP"
    echo ""
    
    # Display new services
    while IFS='|' read -r SERVICE_NAME FQDN PORT IP; do
        case $SERVICE_NAME in
            "chat") ICON="💬" DISPLAY_NAME="Chat Service" ;;
            "payment") ICON="💳" DISPLAY_NAME="Payment Service" ;;
            "resolution") ICON="⚖️" DISPLAY_NAME="Resolution Service" ;;
            "notifications") ICON="🔔" DISPLAY_NAME="Notifications Service" ;;
            "transactions") ICON="💰" DISPLAY_NAME="Transactions Service" ;;
            "reviews") ICON="⭐" DISPLAY_NAME="Reviews Service" ;;
            *) ICON="🔧" DISPLAY_NAME="${SERVICE_NAME^} Service" ;;
        esac
        
        echo "$ICON $DISPLAY_NAME:"
        echo "   URL: http://$FQDN:$PORT"
        echo "   IP: $IP"
        echo ""
    done < "/tmp/bidr_services.txt"
    
    print_header "🎯 Environment Configuration Format"
    echo "========================================"
    echo ""
    echo "For your Flutter/Dart configuration:"
    echo ""
    echo "EnvironmentType.uat: EnvironmentConfig("
    echo "  // Service URLs"
    echo "  authServiceUrl: \"http://$AUTH_FQDN:8001/\","
    
    while IFS='|' read -r SERVICE_NAME FQDN PORT IP; do
        case $SERVICE_NAME in
            "chat") echo "  chatServiceUrl: \"http://$FQDN:$PORT/\"," ;;
            "payment") echo "  paymentServiceUrl: \"http://$FQDN:$PORT/\"," ;;
            "resolution") echo "  resolutionServiceUrl: \"http://$FQDN:$PORT/\"," ;;
            "notifications") echo "  notificationsServiceUrl: \"http://$FQDN:$PORT/\"," ;;
            "transactions") echo "  transactionsServiceUrl: \"http://$FQDN:$PORT/\"," ;;
            "reviews") echo "  reviewsServiceUrl: \"http://$FQDN:$PORT/\"," ;;
        esac
    done < "/tmp/bidr_services.txt"
    
    echo "  productsServiceUrl: \"http://$PRODUCT_FQDN:8000/\","
    echo ""
    echo "  // Admin URLs"
    echo "  authAdminUrl: \"http://$AUTH_FQDN:8001/admin/\","
    
    while IFS='|' read -r SERVICE_NAME FQDN PORT IP; do
        case $SERVICE_NAME in
            "chat") echo "  chatAdminUrl: \"http://$FQDN:$PORT/admin/\"," ;;
            "payment") echo "  paymentAdminUrl: \"http://$FQDN:$PORT/admin/\"," ;;
            "resolution") echo "  resolutionAdminUrl: \"http://$FQDN:$PORT/admin/\"," ;;
            "notifications") echo "  notificationsAdminUrl: \"http://$FQDN:$PORT/admin/\"," ;;
            "transactions") echo "  transactionsAdminUrl: \"http://$FQDN:$PORT/admin/\"," ;;
            "reviews") echo "  reviewsAdminUrl: \"http://$FQDN:$PORT/admin/\"," ;;
        esac
    done < "/tmp/bidr_services.txt"
    
    echo "  productsAdminUrl: \"http://$PRODUCT_FQDN:8000/admin/\","
    echo "),"
    echo ""
fi

print_header "🎯 Quick Health Check Commands"
echo "========================================"
if [ -f "/tmp/bidr_services.txt" ] && [ -s "/tmp/bidr_services.txt" ]; then
    echo "# Test all services:"
    echo "curl http://$PRODUCT_FQDN:8000/health/"
    echo "curl http://$AUTH_FQDN:8001/health/"
    
    while IFS='|' read -r SERVICE_NAME FQDN PORT IP; do
        echo "curl http://$FQDN:$PORT/health/"
    done < "/tmp/bidr_services.txt"
fi

echo ""

if [ $FAILED_DEPLOYMENTS -eq 0 ]; then
    print_success "🎊 All services deployed successfully!"
    echo "Your complete BIDR platform is now running on Azure!"
else
    print_warning "⚠️  Some services failed to deploy. Check the logs above for details."
fi

echo "========================================"

# Cleanup
rm -f "/tmp/bidr_services.txt"
