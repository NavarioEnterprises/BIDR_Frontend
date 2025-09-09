#!/bin/bash

# Enhanced BIDR Notifications Service Update Script with Application Gateway Integration
set -e

# Service Configuration
RESOURCE_GROUP="bidr-simple-rg"
REGISTRY_NAME="bidrsimpleregistry" 
CONTAINER_NAME="bidr-notifications-service"
IMAGE_NAME="bidr-notifications-service"
SERVICE_PORT=8000
SERVICE_DOMAIN="notifications.bidr.co.za"

# Application Gateway Configuration
GATEWAY_NAME="bidr-appgw"
BACKEND_POOL_NAME="notifications-backend-pool"
HTTP_SETTING_NAME="notifications-http-settings"
LISTENER_NAME="notifications-https-listener"
RULE_NAME="notifications-routing-rule"
PROBE_NAME="notifications-health-probe"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory and notifications service path
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NOTIFICATIONS_DIR="/Users/thulanimoyo/MEGA downloads/new downloads/BIDR_Backend/notifications_service"

print_header() {
    echo -e "${BLUE}===================================================${NC}"
    echo -e "${BLUE}🔔 Enhanced BIDR Notifications Service Deployment${NC}"
    echo -e "${BLUE}===================================================${NC}"
}

print_step() {
    echo -e "${YELLOW}$1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

show_deployment_options() {
    echo ""
    echo -e "${YELLOW}Select deployment option:${NC}"
    echo "1) Update container only (existing behavior)"
    echo "2) Update container + link to Application Gateway (HTTPS setup)"
    echo "3) Link existing container to Application Gateway only"
    echo ""
    read -p "Enter your choice (1-3): " DEPLOYMENT_OPTION
}

validate_notifications_directory() {
    if [ ! -d "$NOTIFICATIONS_DIR" ]; then
        print_error "Notifications service directory not found at: $NOTIFICATIONS_DIR"
        exit 1
    fi
    print_success "Found notifications service directory"
}

build_and_deploy_container() {
    print_step "Step 1: Building and deploying notifications service container..."
    
    cd "$NOTIFICATIONS_DIR"
    print_info "Working in notifications service directory: $(pwd)"
    
    # Generate timestamp and keys
    TIMESTAMP=$(date +%s)
    NEW_TAG="v$TIMESTAMP"
    SECRET_KEY=$(python3 -c "import secrets; print(secrets.token_urlsafe(32))")
    JWT_SECRET_KEY=$(python3 -c "import secrets; print(secrets.token_urlsafe(32))")
    
    # Build container image
    print_step "Building Docker image with tag: $NEW_TAG..."
    az acr build --registry $REGISTRY_NAME --image "${IMAGE_NAME}:${NEW_TAG}" --image "${IMAGE_NAME}:latest" .
    
    # Stop existing container
    print_step "Stopping existing container..."
    az container delete --resource-group $RESOURCE_GROUP --name $CONTAINER_NAME --yes --no-wait 2>/dev/null || print_info "No existing container to delete"
    sleep 10
    
    # Get registry credentials
    print_step "Getting registry credentials..."
    REGISTRY_SERVER="${REGISTRY_NAME}.azurecr.io"
    REGISTRY_USERNAME=$(az acr credential show --name $REGISTRY_NAME --query username --output tsv)
    REGISTRY_PASSWORD=$(az acr credential show --name $REGISTRY_NAME --query passwords[0].value --output tsv)
    
    # Deploy new container
    print_step "Deploying updated container..."
    DNS_LABEL="bidr-notifications-$(date +%s)"
    
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
            DJANGO_SETTINGS_MODULE=notifications.settings \
            JWT_SECRET_KEY="$JWT_SECRET_KEY" \
            CORS_ALLOW_ALL_ORIGINS=True \
        --no-wait
    
    print_success "Container deployment initiated"
    
    print_step "Waiting for deployment to complete..."
    sleep 30
}

get_container_info() {
    print_step "Getting container information..."
    
    CONTAINER_INFO=$(az container show \
        --resource-group $RESOURCE_GROUP \
        --name $CONTAINER_NAME \
        --query '{ip: ipAddress.ip, fqdn: ipAddress.fqdn, state: instanceView.state}' \
        --output json)
    
    CONTAINER_IP=$(echo $CONTAINER_INFO | jq -r '.ip // "N/A"')
    CONTAINER_FQDN=$(echo $CONTAINER_INFO | jq -r '.fqdn // "N/A"')
    CONTAINER_STATE=$(echo $CONTAINER_INFO | jq -r '.state // "Unknown"')
    
    if [ "$CONTAINER_IP" = "N/A" ] || [ "$CONTAINER_STATE" != "Running" ]; then
        print_error "Container is not running properly. State: $CONTAINER_STATE"
        exit 1
    fi
    
    print_success "Container is running at IP: $CONTAINER_IP"
    return 0
}

setup_application_gateway() {
    print_step "Step 2: Setting up Application Gateway for HTTPS access..."
    
    # Check if Application Gateway exists
    if ! az network application-gateway show --name $GATEWAY_NAME --resource-group $RESOURCE_GROUP >/dev/null 2>&1; then
        print_error "Application Gateway '$GATEWAY_NAME' not found in resource group '$RESOURCE_GROUP'"
        exit 1
    fi
    
    print_success "Found Application Gateway: $GATEWAY_NAME"
    
    # Create or update backend pool
    print_step "Setting up backend pool..."
    az network application-gateway address-pool create \
        --resource-group $RESOURCE_GROUP \
        --gateway-name $GATEWAY_NAME \
        --name $BACKEND_POOL_NAME \
        --servers $CONTAINER_IP 2>/dev/null || \
    az network application-gateway address-pool update \
        --resource-group $RESOURCE_GROUP \
        --gateway-name $GATEWAY_NAME \
        --name $BACKEND_POOL_NAME \
        --servers $CONTAINER_IP
    
    print_success "Backend pool configured with container IP: $CONTAINER_IP"
    
    # Create health probe
    print_step "Setting up health probe..."
    az network application-gateway probe create \
        --resource-group $RESOURCE_GROUP \
        --gateway-name $GATEWAY_NAME \
        --name $PROBE_NAME \
        --protocol Http \
        --path "/health/" \
        --interval 30 \
        --timeout 30 \
        --threshold 3 \
        --from-http-settings true 2>/dev/null || \
    az network application-gateway probe update \
        --resource-group $RESOURCE_GROUP \
        --gateway-name $GATEWAY_NAME \
        --name $PROBE_NAME \
        --protocol Http \
        --path "/health/" \
        --interval 30 \
        --timeout 30 \
        --threshold 3 \
        --from-http-settings true
    
    print_success "Health probe configured"
    
    # Create HTTP settings
    print_step "Setting up HTTP settings..."
    az network application-gateway http-settings create \
        --resource-group $RESOURCE_GROUP \
        --gateway-name $GATEWAY_NAME \
        --name $HTTP_SETTING_NAME \
        --port $SERVICE_PORT \
        --protocol Http \
        --cookie-based-affinity Disabled \
        --timeout 60 \
        --host-name-from-backend-pool true \
        --probe $PROBE_NAME 2>/dev/null || \
    az network application-gateway http-settings update \
        --resource-group $RESOURCE_GROUP \
        --gateway-name $GATEWAY_NAME \
        --name $HTTP_SETTING_NAME \
        --port $SERVICE_PORT \
        --protocol Http \
        --cookie-based-affinity Disabled \
        --timeout 60 \
        --host-name-from-backend-pool true \
        --probe $PROBE_NAME
    
    print_success "HTTP settings configured"
    
    # Check if HTTPS listener exists (it should already be configured)
    print_step "Verifying HTTPS listener..."
    if az network application-gateway http-listener show --resource-group $RESOURCE_GROUP --gateway-name $GATEWAY_NAME --name notificationsHttpsListener >/dev/null 2>&1; then
        print_success "Found existing HTTPS listener: notificationsHttpsListener"
        LISTENER_NAME="notificationsHttpsListener"
    else
        print_step "Creating HTTPS listener..."
        az network application-gateway http-listener create \
            --resource-group $RESOURCE_GROUP \
            --gateway-name $GATEWAY_NAME \
            --name $LISTENER_NAME \
            --frontend-port httpsPort \
            --ssl-cert notifications-bidr-co-za-cert \
            --host-name $SERVICE_DOMAIN
        print_success "Created HTTPS listener: $LISTENER_NAME"
    fi
        --host-name $SERVICE_DOMAIN
    
    print_success "HTTPS listener configured for domain: $SERVICE_DOMAIN"
    
    # Update routing rule to use our backend pool and settings
    print_step "Setting up routing rule..."
    if az network application-gateway rule show --resource-group $RESOURCE_GROUP --gateway-name $GATEWAY_NAME --name notificationsHttpsRule >/dev/null 2>&1; then
        print_step "Updating existing routing rule: notificationsHttpsRule"
        az network application-gateway rule update \
            --resource-group $RESOURCE_GROUP \
            --gateway-name $GATEWAY_NAME \
            --name notificationsHttpsRule \
            --address-pool $BACKEND_POOL_NAME \
            --http-settings $HTTP_SETTING_NAME
        print_success "Updated existing routing rule: notificationsHttpsRule"
    else
        print_step "Creating new routing rule: $RULE_NAME"
        # Find next available priority
        NEXT_PRIORITY=$(az network application-gateway rule list --resource-group $RESOURCE_GROUP --gateway-name $GATEWAY_NAME --query 'max([].priority)' --output tsv)
        NEXT_PRIORITY=$((NEXT_PRIORITY + 10))
        
        az network application-gateway rule create \
            --resource-group $RESOURCE_GROUP \
            --gateway-name $GATEWAY_NAME \
            --name $RULE_NAME \
            --http-listener $LISTENER_NAME \
            --rule-type Basic \
            --address-pool $BACKEND_POOL_NAME \
            --http-settings $HTTP_SETTING_NAME \
            --priority $NEXT_PRIORITY
        print_success "Created routing rule: $RULE_NAME with priority $NEXT_PRIORITY"
    fi
    
    print_success "Routing rule configured"
}

test_https_endpoint() {
    print_step "Step 3: Testing HTTPS endpoint..."
    
    sleep 10 # Allow gateway to propagate changes
    
    print_info "Testing HTTPS health endpoint..."
    if curl -f -s "https://$SERVICE_DOMAIN/health/" > /dev/null; then
        print_success "HTTPS health endpoint is responding"
    else
        print_error "HTTPS health endpoint test failed - this may be normal if DNS hasn't propagated yet"
    fi
}

print_deployment_summary() {
    echo ""
    echo -e "${BLUE}===================================================${NC}"
    echo -e "${GREEN}🎉 Notifications Service Deployment Complete!${NC}"
    echo -e "${BLUE}===================================================${NC}"
    echo ""
    echo -e "${YELLOW}📋 Deployment Summary:${NC}"
    echo -e "   Service: Notifications Service"
    echo -e "   Container: $CONTAINER_NAME"
    echo -e "   Image: $IMAGE_NAME:latest"
    echo -e "   Container State: $CONTAINER_STATE"
    echo -e "   Container IP: $CONTAINER_IP"
    if [ "$CONTAINER_FQDN" != "N/A" ]; then
        echo -e "   Container URL: http://$CONTAINER_FQDN:$SERVICE_PORT"
    fi
    echo ""
    
    if [ "$DEPLOYMENT_OPTION" = "2" ] || [ "$DEPLOYMENT_OPTION" = "3" ]; then
        echo -e "${YELLOW}🌐 HTTPS Configuration:${NC}"
        echo -e "   Domain: $SERVICE_DOMAIN"
        echo -e "   HTTPS URL: https://$SERVICE_DOMAIN"
        echo -e "   Backend Pool: $BACKEND_POOL_NAME"
        echo -e "   Health Probe: $PROBE_NAME"
        echo ""
        echo -e "${YELLOW}🧪 Quick Tests:${NC}"
        echo -e "   Health Check (HTTPS): curl https://$SERVICE_DOMAIN/health/"
        echo -e "   Health Check (Direct): curl http://$CONTAINER_IP:$SERVICE_PORT/health/"
        if [ "$CONTAINER_FQDN" != "N/A" ]; then
            echo -e "   Health Check (FQDN): curl http://$CONTAINER_FQDN:$SERVICE_PORT/health/"
        fi
    else
        echo -e "${YELLOW}🧪 Quick Tests:${NC}"
        echo -e "   Health Check: curl http://$CONTAINER_IP:$SERVICE_PORT/health/"
        if [ "$CONTAINER_FQDN" != "N/A" ]; then
            echo -e "   Health Check (FQDN): curl http://$CONTAINER_FQDN:$SERVICE_PORT/health/"
        fi
    fi
    echo ""
}

# Main execution
main() {
    print_header
    validate_notifications_directory
    show_deployment_options
    
    case $DEPLOYMENT_OPTION in
        1)
            print_info "Selected: Container update only"
            build_and_deploy_container
            get_container_info
            ;;
        2)
            print_info "Selected: Container update + Application Gateway setup"
            build_and_deploy_container
            get_container_info
            setup_application_gateway
            test_https_endpoint
            ;;
        3)
            print_info "Selected: Application Gateway setup only"
            get_container_info
            setup_application_gateway
            test_https_endpoint
            ;;
        *)
            print_error "Invalid option selected. Exiting."
            exit 1
            ;;
    esac
    
    print_deployment_summary
}

# Execute main function
main "$@"
