#!/bin/bash

# BIDR Auth API Container Management Script
# This script provides easy management for your static auth container

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Static Configuration
RESOURCE_GROUP="bidr-simple-rg"
CONTAINER_NAME="bidr-auth-ssl-container"
STATIC_URL="https://bidr-auth-api.westus.azurecontainer.io"
ADMIN_URL="${STATIC_URL}/admin/"

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

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

show_help() {
    echo "BIDR Auth API Container Management"
    echo ""
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  status    - Show container status and URL"
    echo "  logs      - Show container logs"
    echo "  restart   - Restart the container"
    echo "  shell     - Open interactive shell in container"
    echo "  redeploy  - Delete and redeploy the container"
    echo "  superuser - Create/update superuser account"
    echo "  test      - Test API endpoints"
    echo "  help      - Show this help message"
    echo ""
    echo "Static URL: $STATIC_URL"
    echo "Admin URL:  $ADMIN_URL"
}

show_status() {
    print_header "Container Status"
    
    if az container show --resource-group "$RESOURCE_GROUP" --name "$CONTAINER_NAME" --query "name" --output tsv > /dev/null 2>&1; then
        local status=$(az container show --resource-group "$RESOURCE_GROUP" --name "$CONTAINER_NAME" --query "instanceView.state" --output tsv)
        local fqdn=$(az container show --resource-group "$RESOURCE_GROUP" --name "$CONTAINER_NAME" --query "ipAddress.fqdn" --output tsv)
        local ip=$(az container show --resource-group "$RESOURCE_GROUP" --name "$CONTAINER_NAME" --query "ipAddress.ip" --output tsv)
        
        echo "Container Name: $CONTAINER_NAME"
        echo "Status: $status"
        echo "FQDN: $fqdn"
        echo "IP Address: $ip"
        echo ""
        echo "🌐 Static URLs:"
        echo "  Main API: $STATIC_URL"
        echo "  Admin Panel: $ADMIN_URL"
        
        if [ "$status" = "Running" ]; then
            print_success "Container is running normally"
        else
            print_warning "Container is not running (Status: $status)"
        fi
    else
        print_error "Container '$CONTAINER_NAME' not found"
        echo "Run '$0 redeploy' to create the container"
    fi
}

show_logs() {
    print_header "Container Logs"
    
    if az container show --resource-group "$RESOURCE_GROUP" --name "$CONTAINER_NAME" > /dev/null 2>&1; then
        az container logs --resource-group "$RESOURCE_GROUP" --name "$CONTAINER_NAME"
    else
        print_error "Container '$CONTAINER_NAME' not found"
    fi
}

restart_container() {
    print_header "Restarting Container"
    
    if az container show --resource-group "$RESOURCE_GROUP" --name "$CONTAINER_NAME" > /dev/null 2>&1; then
        print_info "Restarting container..."
        az container restart --resource-group "$RESOURCE_GROUP" --name "$CONTAINER_NAME"
        print_success "Container restarted successfully"
        
        # Wait a moment and show status
        sleep 5
        show_status
    else
        print_error "Container '$CONTAINER_NAME' not found"
        echo "Run '$0 redeploy' to create the container"
    fi
}

open_shell() {
    print_header "Opening Container Shell"
    
    if az container show --resource-group "$RESOURCE_GROUP" --name "$CONTAINER_NAME" > /dev/null 2>&1; then
        local status=$(az container show --resource-group "$RESOURCE_GROUP" --name "$CONTAINER_NAME" --query "instanceView.state" --output tsv)
        
        if [ "$status" = "Running" ]; then
            print_info "Opening interactive shell..."
            echo "Type 'exit' to leave the container shell"
            az container exec --resource-group "$RESOURCE_GROUP" --name "$CONTAINER_NAME" --exec-command "/bin/bash"
        else
            print_error "Container is not running (Status: $status)"
        fi
    else
        print_error "Container '$CONTAINER_NAME' not found"
    fi
}

redeploy_container() {
    print_header "Redeploying Container"
    
    print_warning "This will delete and recreate the container"
    read -p "Are you sure? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Delete existing container if it exists
        if az container show --resource-group "$RESOURCE_GROUP" --name "$CONTAINER_NAME" > /dev/null 2>&1; then
            print_info "Deleting existing container..."
            az container delete --resource-group "$RESOURCE_GROUP" --name "$CONTAINER_NAME" --yes
        fi
        
        print_info "Running deployment script..."
        ./deploy-auth-ssl.sh
        
        print_success "Container redeployed successfully"
        show_status
    else
        print_info "Deployment cancelled"
    fi
}

create_superuser() {
    print_header "Create/Update Superuser"
    
    if az container show --resource-group "$RESOURCE_GROUP" --name "$CONTAINER_NAME" > /dev/null 2>&1; then
        local status=$(az container show --resource-group "$RESOURCE_GROUP" --name "$CONTAINER_NAME" --query "instanceView.state" --output tsv)
        
        if [ "$status" = "Running" ]; then
            print_info "Opening Django shell for superuser management..."
            echo "You can now run Django management commands."
            echo "For example: python manage.py createsuperuser"
            
            az container exec --resource-group "$RESOURCE_GROUP" --name "$CONTAINER_NAME" --exec-command "/bin/bash"
        else
            print_error "Container is not running (Status: $status)"
        fi
    else
        print_error "Container '$CONTAINER_NAME' not found"
    fi
}

test_endpoints() {
    print_header "Testing API Endpoints"
    
    print_info "Testing main API endpoint..."
    if curl -k -s --connect-timeout 10 "$STATIC_URL" > /dev/null; then
        print_success "Main API is accessible: $STATIC_URL"
    else
        print_error "Main API is not accessible: $STATIC_URL"
    fi
    
    print_info "Testing admin panel..."
    if curl -k -s --connect-timeout 10 "$ADMIN_URL" > /dev/null; then
        print_success "Admin panel is accessible: $ADMIN_URL"
    else
        print_error "Admin panel is not accessible: $ADMIN_URL"
    fi
    
    print_info "Testing SSL certificate..."
    local cert_info=$(echo | openssl s_client -connect "bidr-auth-api.westus.azurecontainer.io:443" -servername "bidr-auth-api.westus.azurecontainer.io" 2>/dev/null | openssl x509 -noout -subject -dates 2>/dev/null || echo "Certificate check failed")
    
    if [ "$cert_info" != "Certificate check failed" ]; then
        print_success "SSL certificate is valid"
        echo "  $cert_info"
    else
        print_warning "SSL certificate check failed"
    fi
}

# Main script logic
case "${1:-help}" in
    "status")
        show_status
        ;;
    "logs")
        show_logs
        ;;
    "restart")
        restart_container
        ;;
    "shell")
        open_shell
        ;;
    "redeploy")
        redeploy_container
        ;;
    "superuser")
        create_superuser
        ;;
    "test")
        test_endpoints
        ;;
    "help"|"--help"|"-h")
        show_help
        ;;
    *)
        print_error "Unknown command: $1"
        echo ""
        show_help
        exit 1
        ;;
esac
