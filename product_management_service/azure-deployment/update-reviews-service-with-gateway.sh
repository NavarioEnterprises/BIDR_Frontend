#!/bin/bash

# BIDR Reviews Service Enhanced Update Script with Application Gateway Support
# This script provides flexible deployment options:
# 1. Update container only
# 2. Update container and configure Application Gateway
# 3. Configure Application Gateway only (for existing container)

set -e

echo "🚀 BIDR Reviews Service Enhanced Deployment Manager"
echo "================================================"

# Configuration
RESOURCE_GROUP="bidr-simple-rg"
REGISTRY_NAME="bidrsimpleregistry"
CONTAINER_NAME="bidr-reviews-service"
SERVICE_NAME="bidr-reviews-service"
IMAGE_NAME="bidr-reviews-service"
SERVICE_PORT=8000  # Fixed to match Dockerfile
DOMAIN_NAME="reviews.bidr.co.za"
APPGW_NAME="bidr-appgw"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
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

print_header() {
    echo -e "${CYAN}${BOLD}$1${NC}"
}

# Function to display deployment options
show_deployment_menu() {
    echo ""
    print_header "📋 Deployment Options:"
    echo -e "${YELLOW}1.${NC} Update container only (no gateway changes)"
    echo -e "${YELLOW}2.${NC} Update container + configure Application Gateway (HTTPS)"
    echo -e "${YELLOW}3.${NC} Configure Application Gateway only (existing container)"
    echo -e "${YELLOW}4.${NC} Exit"
    echo ""
}

# Function to get the reviews service directory path
get_service_directory() {
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    BASE_DIR="$(dirname "$(dirname "$SCRIPT_DIR)")"
    REVIEWS_SERVICE_DIR="$BASE_DIR/reviews_and_ratings"
    
    # Check if reviews service directory exists
    if [ ! -d "$REVIEWS_SERVICE_DIR" ]; then
        print_error "Reviews service directory not found at: $REVIEWS_SERVICE_DIR"
        print_error "Please make sure you're running this from the correct location."
        exit 1
    fi
    
    print_status "Found reviews service directory: $REVIEWS_SERVICE_DIR"
    
    # Check if Dockerfile exists
    if [ ! -f "$REVIEWS_SERVICE_DIR/Dockerfile" ]; then
        print_error "Dockerfile not found in reviews service directory."
        exit 1
    fi
}

# Function to build and deploy container
deploy_container() {
    print_header "🐳 Deploying Reviews Service Container"
    
    # Change to reviews service directory
    cd "$REVIEWS_SERVICE_DIR"
    print_status "Changed to reviews service directory"
    
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
    DNS_LABEL="bidr-reviews-$(date +%s)"
    
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
            DJANGO_SETTINGS_MODULE=reviews_and_ratings.settings \
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
    
    # Store container IP for potential gateway configuration
    CONTAINER_IP=$NEW_IP
    
    # Step 7: Display container deployment results
    echo ""
    echo "========================================"
    print_header "🎉 Reviews Service Container Updated!"
    echo "========================================"
    echo "Service Name: BIDR Reviews Service"
    echo "Image Tag: ${NEW_TAG}"
    echo "Container State: $CONTAINER_STATE"
    echo "Provisioning State: $PROVISIONING_STATE"
    echo "Public IP: $NEW_IP"
    echo "FQDN: $NEW_FQDN"
    echo "Service Port: ${SERVICE_PORT}"
    echo "Direct URL: http://${NEW_FQDN}:${SERVICE_PORT}"
    echo "========================================"
    
    # Step 8: Test the updated service
    print_status "Step 8: Testing updated service..."
    echo "⏳ Service is starting up, testing health endpoint..."
    sleep 15
    
    MAX_RETRIES=5
    RETRY_COUNT=0
    while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
        HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "http://${NEW_IP}:${SERVICE_PORT}/health/" --connect-timeout 10 --max-time 30 || echo "000")
        
        if [ "$HTTP_STATUS" = "200" ]; then
            print_success "Container service is healthy and responding!"
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
}

# Function to configure Application Gateway
configure_application_gateway() {
    print_header "🌐 Configuring Application Gateway for HTTPS"
    
    # Get container IP if not already set
    if [ -z "$CONTAINER_IP" ]; then
        print_status "Getting current container IP..."
        CONTAINER_IP=$(az container show \
            --resource-group $RESOURCE_GROUP \
            --name $CONTAINER_NAME \
            --query 'ipAddress.ip' \
            --output tsv)
        
        if [ -z "$CONTAINER_IP" ] || [ "$CONTAINER_IP" = "null" ]; then
            print_error "Could not get container IP address. Make sure container is deployed and running."
            return 1
        fi
    fi
    
    print_status "Container IP: $CONTAINER_IP"
    print_status "Configuring gateway for domain: $DOMAIN_NAME"
    
    # Backend pool name
    BACKEND_POOL_NAME="${SERVICE_NAME}-backend-pool"
    
    # Step 1: Create or update backend address pool
    print_status "Step 1: Configuring backend address pool..."
    
    # Check if backend pool exists
    POOL_EXISTS=$(az network application-gateway address-pool show \
        --resource-group $RESOURCE_GROUP \
        --gateway-name $APPGW_NAME \
        --name $BACKEND_POOL_NAME 2>/dev/null || echo "not_found")
    
    if [ "$POOL_EXISTS" = "not_found" ]; then
        print_status "Creating new backend pool..."
        az network application-gateway address-pool create \
            --resource-group $RESOURCE_GROUP \
            --gateway-name $APPGW_NAME \
            --name $BACKEND_POOL_NAME \
            --servers $CONTAINER_IP
    else
        print_status "Updating existing backend pool..."
        az network application-gateway address-pool update \
            --resource-group $RESOURCE_GROUP \
            --gateway-name $APPGW_NAME \
            --name $BACKEND_POOL_NAME \
            --servers $CONTAINER_IP
    fi
    
    print_success "Backend pool configured"
    
    # Step 2: Create or update health probe
    PROBE_NAME="${SERVICE_NAME}-health-probe"
    print_status "Step 2: Configuring health probe..."
    
    PROBE_EXISTS=$(az network application-gateway probe show \
        --resource-group $RESOURCE_GROUP \
        --gateway-name $APPGW_NAME \
        --name $PROBE_NAME 2>/dev/null || echo "not_found")
    
    if [ "$PROBE_EXISTS" = "not_found" ]; then
        print_status "Creating new health probe..."
        az network application-gateway probe create \
            --resource-group $RESOURCE_GROUP \
            --gateway-name $APPGW_NAME \
            --name $PROBE_NAME \
            --protocol Http \
            --host-name-from-http-settings true \
            --path "/health/" \
            --interval 30 \
            --timeout 20 \
            --threshold 3
    else
        print_status "Health probe already exists: $PROBE_NAME"
    fi
    
    print_success "Health probe configured"
    
    # Step 3: Create or update HTTP settings
    HTTP_SETTINGS_NAME="${SERVICE_NAME}-http-settings"
    print_status "Step 3: Configuring HTTP settings..."
    
    HTTP_SETTINGS_EXISTS=$(az network application-gateway http-settings show \
        --resource-group $RESOURCE_GROUP \
        --gateway-name $APPGW_NAME \
        --name $HTTP_SETTINGS_NAME 2>/dev/null || echo "not_found")
    
    if [ "$HTTP_SETTINGS_EXISTS" = "not_found" ]; then
        print_status "Creating new HTTP settings..."
        az network application-gateway http-settings create \
            --resource-group $RESOURCE_GROUP \
            --gateway-name $APPGW_NAME \
            --name $HTTP_SETTINGS_NAME \
            --port $SERVICE_PORT \
            --protocol Http \
            --cookie-based-affinity Disabled \
            --timeout 20 \
            --probe $PROBE_NAME \
            --host-name-from-backend-pool false \
            --host-name $CONTAINER_IP
    else
        print_status "Updating existing HTTP settings..."
        az network application-gateway http-settings update \
            --resource-group $RESOURCE_GROUP \
            --gateway-name $APPGW_NAME \
            --name $HTTP_SETTINGS_NAME \
            --port $SERVICE_PORT \
            --timeout 20 \
            --probe $PROBE_NAME \
            --host-name $CONTAINER_IP
    fi
    
    print_success "HTTP settings configured"
    
    # Step 4: Create HTTPS listener (assuming SSL certificate exists)
    LISTENER_NAME="${SERVICE_NAME}-https-listener"
    print_status "Step 4: Configuring HTTPS listener..."
    
    LISTENER_EXISTS=$(az network application-gateway http-listener show \
        --resource-group $RESOURCE_GROUP \
        --gateway-name $APPGW_NAME \
        --name $LISTENER_NAME 2>/dev/null || echo "not_found")
    
    # Get SSL certificate name (assuming wildcard cert exists)
    SSL_CERT_NAME="bidr-wildcard-cert"
    
    if [ "$LISTENER_EXISTS" = "not_found" ]; then
        print_status "Creating new HTTPS listener..."
        az network application-gateway http-listener create \
            --resource-group $RESOURCE_GROUP \
            --gateway-name $APPGW_NAME \
            --name $LISTENER_NAME \
            --frontend-ip appGatewayFrontendIP \
            --frontend-port appGatewayFrontendPort443 \
            --protocol Https \
            --ssl-cert $SSL_CERT_NAME \
            --host-name $DOMAIN_NAME
    else
        print_status "HTTPS listener already exists: $LISTENER_NAME"
    fi
    
    print_success "HTTPS listener configured"
    
    # Step 5: Create or update routing rule
    RULE_NAME="${SERVICE_NAME}-https-rule"
    print_status "Step 5: Configuring routing rule..."
    
    RULE_EXISTS=$(az network application-gateway rule show \
        --resource-group $RESOURCE_GROUP \
        --gateway-name $APPGW_NAME \
        --name $RULE_NAME 2>/dev/null || echo "not_found")
    
    if [ "$RULE_EXISTS" = "not_found" ]; then
        print_status "Creating new routing rule..."
        az network application-gateway rule create \
            --resource-group $RESOURCE_GROUP \
            --gateway-name $APPGW_NAME \
            --name $RULE_NAME \
            --http-listener $LISTENER_NAME \
            --rule-type Basic \
            --address-pool $BACKEND_POOL_NAME \
            --http-settings $HTTP_SETTINGS_NAME \
            --priority 160
    else
        print_status "Updating existing routing rule..."
        az network application-gateway rule update \
            --resource-group $RESOURCE_GROUP \
            --gateway-name $APPGW_NAME \
            --name $RULE_NAME \
            --address-pool $BACKEND_POOL_NAME \
            --http-settings $HTTP_SETTINGS_NAME
    fi
    
    print_success "Routing rule configured"
    
    # Step 6: Test HTTPS endpoint
    print_status "Step 6: Testing HTTPS endpoint..."
    sleep 10
    
    MAX_RETRIES=3
    RETRY_COUNT=0
    while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
        HTTPS_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "https://${DOMAIN_NAME}/health/" --connect-timeout 15 --max-time 30 || echo "000")
        
        if [ "$HTTPS_STATUS" = "200" ]; then
            print_success "HTTPS endpoint is working correctly!"
            break
        else
            RETRY_COUNT=$((RETRY_COUNT + 1))
            if [ $RETRY_COUNT -lt $MAX_RETRIES ]; then
                print_warning "HTTPS endpoint not ready yet (attempt $RETRY_COUNT/$MAX_RETRIES). Waiting 15 seconds..."
                sleep 15
            else
                print_warning "HTTPS endpoint may still be configuring. Check Application Gateway status."
            fi
        fi
    done
}

# Main execution
main() {
    # Initialize
    get_service_directory
    
    # Show menu and get user choice
    while true; do
        show_deployment_menu
        read -p "Select deployment option (1-4): " choice
        
        case $choice in
            1)
                print_header "🐳 Container Update Only"
                deploy_container
                break
                ;;
            2)
                print_header "🚀 Full Deployment - Container and HTTPS Gateway"
                deploy_container
                if [ $? -eq 0 ]; then
                    echo ""
                    configure_application_gateway
                fi
                break
                ;;
            3)
                print_header "🌐 Application Gateway Configuration Only"
                configure_application_gateway
                break
                ;;
            4)
                print_header "👋 Exiting..."
                exit 0
                ;;
            *)
                print_error "Invalid choice. Please select 1-4."
                ;;
        esac
    done
    
    # Final status report
    echo ""
    echo "========================================"
    print_header "🎊 Deployment Summary"
    echo "========================================"
    echo "Service: BIDR Reviews Service"
    echo "Container: $CONTAINER_NAME"
    if [ ! -z "$CONTAINER_IP" ]; then
        echo "Container IP: $CONTAINER_IP"
        echo "Container Port: $SERVICE_PORT"
        echo "Direct Access: http://${CONTAINER_IP}:${SERVICE_PORT}/health/"
    fi
    echo "HTTPS URL: https://${DOMAIN_NAME}"
    echo "Health Check: https://${DOMAIN_NAME}/health/"
    echo "API Endpoint: https://${DOMAIN_NAME}/api/"
    echo "Admin Panel: https://${DOMAIN_NAME}/admin/"
    echo "========================================"
    
    echo ""
    print_header "🔧 Quick Test Commands:"
    echo "# Test HTTPS endpoint:"
    echo "curl https://${DOMAIN_NAME}/health/"
    echo ""
    if [ ! -z "$CONTAINER_IP" ]; then
        echo "# Test direct container access:"
        echo "curl http://${CONTAINER_IP}:${SERVICE_PORT}/health/"
        echo ""
    fi
    echo "# View container logs:"
    echo "az container logs --resource-group $RESOURCE_GROUP --name $CONTAINER_NAME"
    echo ""
    echo "# Check Application Gateway status:"
    echo "az network application-gateway show --resource-group $RESOURCE_GROUP --name $APPGW_NAME --query 'operationalState'"
    echo ""
    
    print_success "Reviews Service deployment completed! 🎉"
}

# Run the main function
main "$@"
