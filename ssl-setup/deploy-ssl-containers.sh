#!/bin/bash

# BIDR SSL-Enabled Container Deployment Script
# This script deploys all BIDR services with SSL certificates and nginx proxies

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
RESOURCE_GROUP="bidr-simple-rg"
LOCATION="westus"
ACR_NAME="bidrcontainers"
CERT_DIR="/tmp/bidr-ssl-certs"
DEPLOYMENT_DIR="./ssl-deployments"

# Service configurations: name:external_port:internal_port:directory
SERVICES=(
    "auth:443:8000:authentication_service"
    "product:443:8000:product_management_service" 
    "chat:443:8002:chat_service"
    "payment:443:8003:payment_service"
    "resolution:443:8004:resolution_service"
    "notifications:443:8005:notifications_service"
    "transactions:443:8006:transactions_service"
    "reviews:443:8007:reviews_and_ratings"
)

print_header() {
    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}============================================${NC}"
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

# Check prerequisites
check_prerequisites() {
    print_header "Checking Prerequisites"
    
    # Check Azure CLI
    if ! command -v az &> /dev/null; then
        print_error "Azure CLI is not installed"
        exit 1
    fi
    print_success "Azure CLI is installed"
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed"
        exit 1
    fi
    print_success "Docker is installed"
    
    # Check if logged into Azure
    if ! az account show &> /dev/null; then
        print_error "Not logged into Azure CLI. Run 'az login' first"
        exit 1
    fi
    print_success "Logged into Azure CLI"
    
    # Check if certificates exist
    if [ ! -d "$CERT_DIR" ]; then
        print_error "SSL certificates not found. Run generate-ssl-certs.sh first"
        exit 1
    fi
    print_success "SSL certificates found"
}

# Setup deployment directory
setup_deployment_dir() {
    print_header "Setting up Deployment Directory"
    
    if [ -d "$DEPLOYMENT_DIR" ]; then
        print_warning "Deployment directory exists, cleaning up..."
        rm -rf "$DEPLOYMENT_DIR"
    fi
    
    mkdir -p "$DEPLOYMENT_DIR"
    print_success "Deployment directory created: $DEPLOYMENT_DIR"
}

# Generate service-specific configurations
generate_service_configs() {
    local service_name=$1
    local external_port=$2
    local internal_port=$3
    local service_dir=$4
    local domain=$5
    
    echo -e "${BLUE}Generating configs for: $service_name${NC}"
    
    # Create service deployment directory
    local deploy_service_dir="$DEPLOYMENT_DIR/$service_name"
    mkdir -p "$deploy_service_dir"
    
    # Generate nginx config
    local nginx_config="$deploy_service_dir/nginx-$service_name.conf"
    sed -e "s/{{SERVICE_NAME}}/$service_name/g" \
        -e "s/{{DOMAIN}}/$domain/g" \
        -e "s/{{BACKEND_PORT}}/$internal_port/g" \
        ssl-setup/nginx-ssl.conf.template > "$nginx_config"
    
    # Generate Dockerfile
    local dockerfile="$deploy_service_dir/Dockerfile"
    sed -e "s/{{SERVICE_NAME}}/$service_name/g" \
        -e "s/{{BACKEND_PORT}}/$internal_port/g" \
        ssl-setup/Dockerfile.ssl.template > "$dockerfile"
    
    # Copy SSL certificates
    local cert_source_dir="$CERT_DIR/$domain"
    local cert_dest_dir="$deploy_service_dir/ssl-certs/$service_name"
    local key_dest_dir="$deploy_service_dir/ssl-keys/$service_name"
    
    mkdir -p "$cert_dest_dir" "$key_dest_dir"
    cp "$cert_source_dir/fullchain.pem" "$cert_dest_dir/"
    cp "$cert_source_dir/privkey.pem" "$key_dest_dir/"
    
    # Copy service source code
    if [ -d "$service_dir" ]; then
        cp -r "$service_dir" "$deploy_service_dir/$service_name"
    else
        print_warning "Service directory $service_dir not found, creating placeholder"
        mkdir -p "$deploy_service_dir/$service_name"
    fi
    
    print_success "Configuration generated for $service_name"
}

# Build and push Docker images
build_and_push_images() {
    print_header "Building and Pushing Docker Images"
    
    # Login to ACR
    az acr login --name $ACR_NAME
    
    for service_config in "${SERVICES[@]}"; do
        IFS=':' read -r service_name external_port internal_port service_dir <<< "$service_config"
        
        echo -e "${BLUE}Building image for: $service_name${NC}"
        
        local deploy_service_dir="$DEPLOYMENT_DIR/$service_name"
        local image_name="$ACR_NAME.azurecr.io/bidr-$service_name-ssl:latest"
        
        # Build image for AMD64 platform (Azure Container Instances requirement)
        docker build --platform linux/amd64 -t "$image_name" "$deploy_service_dir"
        
        # Push image
        docker push "$image_name"
        
        print_success "Image built and pushed: $image_name"
    done
}

# Deploy containers to Azure
deploy_containers() {
    print_header "Deploying SSL-Enabled Containers"
    
    for service_config in "${SERVICES[@]}"; do
        IFS=':' read -r service_name external_port internal_port service_dir <<< "$service_config"
        
        echo -e "${BLUE}Deploying container: bidr-$service_name-service-ssl${NC}"
        
        local image_name="$ACR_NAME.azurecr.io/bidr-$service_name-ssl:latest"
        local container_name="bidr-$service_name-ssl-$(date +%s | tail -c 7)"
        
        # Get domain for this service
        local domain=$(get_service_domain "$service_name")
        
        # Deploy container
        az container create \
            --resource-group "$RESOURCE_GROUP" \
            --name "$container_name" \
            --image "$image_name" \
            --os-type Linux \
            --registry-login-server "$ACR_NAME.azurecr.io" \
            --registry-username $(az acr credential show --name $ACR_NAME --query username --output tsv) \
            --registry-password $(az acr credential show --name $ACR_NAME --query passwords[0].value --output tsv) \
            --dns-name-label "bidr-$service_name-ssl-$(date +%s)" \
            --ports 443 80 \
            --cpu 1 \
            --memory 2 \
            --location "$LOCATION" \
            --environment-variables \
                DJANGO_SETTINGS_MODULE="$service_name.settings" \
                DEBUG="False" \
                ALLOWED_HOSTS="*" \
                SECURE_SSL_REDIRECT="False" \
            --restart-policy Always
        
        if [ $? -eq 0 ]; then
            print_success "Container deployed: $container_name"
            
            # Get container details
            local container_info=$(az container show --resource-group "$RESOURCE_GROUP" --name "$container_name" --query '{fqdn: ipAddress.fqdn, ip: ipAddress.ip, state: containers[0].instanceView.currentState.state}' --output json)
            local fqdn=$(echo "$container_info" | jq -r '.fqdn')
            local ip=$(echo "$container_info" | jq -r '.ip')
            local state=$(echo "$container_info" | jq -r '.state')
            
            echo "  FQDN: $fqdn"
            echo "  IP: $ip"
            echo "  State: $state"
            echo "  HTTPS URL: https://$fqdn/"
            echo ""
        else
            print_error "Failed to deploy container: $container_name"
        fi
    done
}

# Get service domain based on current deployments
get_service_domain() {
    local service_name=$1
    case $service_name in
        "auth") echo "bidr-auth-1756991300.westus.azurecontainer.io" ;;
        "product") echo "bidr-product-1756960567.westus.azurecontainer.io" ;;
        "chat") echo "bidr-chat-1756963149.westus.azurecontainer.io" ;;
        "payment") echo "bidr-payment-1756963524.westus.azurecontainer.io" ;;
        "resolution") echo "bidr-resolution-1756963788.westus.azurecontainer.io" ;;
        "notifications") echo "bidr-notifications-1756964056.westus.azurecontainer.io" ;;
        "transactions") echo "bidr-transactions-1756964308.westus.azurecontainer.io" ;;
        "reviews") echo "bidr-reviews-1756964572.westus.azurecontainer.io" ;;
        *) echo "$service_name.westus.azurecontainer.io" ;;
    esac
}

# Generate updated environment configuration
generate_environment_config() {
    print_header "Generating Updated Environment Configuration"
    
    local config_file="$DEPLOYMENT_DIR/https_environment_config.dart"
    
    cat > "$config_file" << 'EOF'
EnvironmentType.uat: EnvironmentConfig(
      // HTTPS Service URLs with SSL certificates
EOF

    # Get FQDNs of deployed containers
    for service_config in "${SERVICES[@]}"; do
        IFS=':' read -r service_name external_port internal_port service_dir <<< "$service_config"
        
        local container_name="bidr-$service_name-service-ssl"
        local fqdn=$(az container show --resource-group "$RESOURCE_GROUP" --name "$container_name" --query 'ipAddress.fqdn' --output tsv 2>/dev/null || echo "")
        
        if [ -n "$fqdn" ] && [ "$fqdn" != "null" ]; then
            case $service_name in
                "auth") echo "      authServiceUrl: \"https://$fqdn/\"," >> "$config_file" ;;
                "product") echo "      productsServiceUrl: \"https://$fqdn/\"," >> "$config_file" ;;
                "chat") echo "      chatServiceUrl: \"https://$fqdn/\"," >> "$config_file" ;;
                "payment") echo "      paymentServiceUrl: \"https://$fqdn/\"," >> "$config_file" ;;
                "resolution") echo "      resolutionServiceUrl: \"https://$fqdn/\"," >> "$config_file" ;;
                "notifications") echo "      notificationsServiceUrl: \"https://$fqdn/\"," >> "$config_file" ;;
                "transactions") echo "      transactionsServiceUrl: \"https://$fqdn/\"," >> "$config_file" ;;
                "reviews") echo "      reviewsServiceUrl: \"https://$fqdn/\"," >> "$config_file" ;;
            esac
        fi
    done
    
    cat >> "$config_file" << 'EOF'

      // HTTPS Admin URLs
EOF

    for service_config in "${SERVICES[@]}"; do
        IFS=':' read -r service_name external_port internal_port service_dir <<< "$service_config"
        
        local container_name="bidr-$service_name-service-ssl"
        local fqdn=$(az container show --resource-group "$RESOURCE_GROUP" --name "$container_name" --query 'ipAddress.fqdn' --output tsv 2>/dev/null || echo "")
        
        if [ -n "$fqdn" ] && [ "$fqdn" != "null" ]; then
            case $service_name in
                "auth") echo "      authAdminUrl: \"https://$fqdn/admin/\"," >> "$config_file" ;;
                "product") echo "      productsAdminUrl: \"https://$fqdn/admin/\"," >> "$config_file" ;;
                "chat") echo "      chatAdminUrl: \"https://$fqdn/admin/\"," >> "$config_file" ;;
                "payment") echo "      paymentAdminUrl: \"https://$fqdn/admin/\"," >> "$config_file" ;;
                "resolution") echo "      resolutionAdminUrl: \"https://$fqdn/admin/\"," >> "$config_file" ;;
                "notifications") echo "      notificationsAdminUrl: \"https://$fqdn/admin/\"," >> "$config_file" ;;
                "transactions") echo "      transactionsAdminUrl: \"https://$fqdn/admin/\"," >> "$config_file" ;;
                "reviews") echo "      reviewsAdminUrl: \"https://$fqdn/admin/\"," >> "$config_file" ;;
            esac
        fi
    done
    
    cat >> "$config_file" << 'EOF'
      
      grafanaUrl: '',
      prometheusUrl: '',
    ),
EOF

    print_success "Environment configuration generated: $config_file"
}

# Test HTTPS endpoints
test_https_endpoints() {
    print_header "Testing HTTPS Endpoints"
    
    for service_config in "${SERVICES[@]}"; do
        IFS=':' read -r service_name external_port internal_port service_dir <<< "$service_config"
        
        local container_name="bidr-$service_name-service-ssl"
        local fqdn=$(az container show --resource-group "$RESOURCE_GROUP" --name "$container_name" --query 'ipAddress.fqdn' --output tsv 2>/dev/null || echo "")
        
        if [ -n "$fqdn" ] && [ "$fqdn" != "null" ]; then
            echo -e "${BLUE}Testing: $service_name ($fqdn)${NC}"
            
            # Test HTTPS endpoint
            if curl -k -s --connect-timeout 10 "https://$fqdn/health/" > /dev/null 2>&1; then
                print_success "HTTPS endpoint is accessible: https://$fqdn/health/"
            else
                print_warning "HTTPS endpoint not responding: https://$fqdn/health/"
            fi
            
            # Test certificate
            local cert_info=$(echo | openssl s_client -connect "$fqdn:443" -servername "$fqdn" 2>/dev/null | openssl x509 -noout -subject -dates 2>/dev/null)
            if [ -n "$cert_info" ]; then
                echo "  Certificate info: $cert_info"
            fi
            echo ""
        fi
    done
}

# Main execution
main() {
    print_header "BIDR SSL Container Deployment"
    
    # Check prerequisites
    check_prerequisites
    
    # Setup deployment directory
    setup_deployment_dir
    
    # Generate configurations for each service
    print_header "Generating Service Configurations"
    for service_config in "${SERVICES[@]}"; do
        IFS=':' read -r service_name external_port internal_port service_dir <<< "$service_config"
        local domain=$(get_service_domain "$service_name")
        generate_service_configs "$service_name" "$external_port" "$internal_port" "$service_dir" "$domain"
    done
    
    # Ask user for confirmation
    echo -e "${YELLOW}Ready to build and deploy SSL-enabled containers. Continue? [y/N]${NC}"
    read -r confirmation
    if [[ ! "$confirmation" =~ ^[Yy]$ ]]; then
        echo "Deployment cancelled."
        exit 0
    fi
    
    # Build and push images
    build_and_push_images
    
    # Deploy containers
    deploy_containers
    
    # Generate environment configuration
    generate_environment_config
    
    # Wait a bit for containers to start
    print_header "Waiting for containers to initialize..."
    sleep 30
    
    # Test endpoints
    test_https_endpoints
    
    print_success "🎉 SSL deployment completed!"
    echo -e "${GREEN}Your BIDR services are now running with SSL certificates!${NC}"
    echo -e "${GREEN}Environment configuration: $DEPLOYMENT_DIR/https_environment_config.dart${NC}"
}

# Run main function
main "$@"
