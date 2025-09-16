#!/bin/bash

# Custom Domain SSL Certificate Setup for BIDR Auth API
# This script helps set up SSL certificates for your custom domain

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Get current container IP
get_container_ip() {
    local ip=$(az container show --resource-group bidr-simple-rg --name bidr-auth-ssl-container --query "ipAddress.ip" --output tsv 2>/dev/null || echo "")
    echo "$ip"
}

main() {
    print_header "Custom Domain SSL Setup for BIDR Auth API"
    
    # Get custom domain from user
    echo "Please enter your custom domain (e.g., auth.yourdomain.com):"
    read -p "Domain: " CUSTOM_DOMAIN
    
    if [ -z "$CUSTOM_DOMAIN" ]; then
        print_error "Domain cannot be empty"
        exit 1
    fi
    
    echo "Please enter your email for Let's Encrypt certificate:"
    read -p "Email: " EMAIL
    
    if [ -z "$EMAIL" ]; then
        print_error "Email cannot be empty"
        exit 1
    fi
    
    # Get container IP
    CONTAINER_IP=$(get_container_ip)
    if [ -z "$CONTAINER_IP" ]; then
        print_error "Could not get container IP. Make sure the container is running."
        exit 1
    fi
    
    print_info "Container IP: $CONTAINER_IP"
    
    # DNS Setup Instructions
    print_header "Step 1: DNS Configuration"
    echo "You need to point your domain to the Azure Container IP:"
    echo ""
    echo "In your DNS provider (GoDaddy, Cloudflare, etc.), create:"
    echo "  Type: A"
    echo "  Name: ${CUSTOM_DOMAIN}"
    echo "  Value: ${CONTAINER_IP}"
    echo "  TTL: 300 (or default)"
    echo ""
    echo "If using a subdomain like 'auth.yourdomain.com':"
    echo "  Type: A"
    echo "  Name: auth"
    echo "  Value: ${CONTAINER_IP}"
    echo ""
    print_warning "Wait for DNS propagation (5-15 minutes) before continuing!"
    echo ""
    
    # DNS Check
    echo "Press Enter when you've configured DNS and want to check propagation..."
    read -p ""
    
    print_info "Checking DNS propagation..."
    RESOLVED_IP=$(dig +short "$CUSTOM_DOMAIN" | tail -n1)
    
    if [ "$RESOLVED_IP" = "$CONTAINER_IP" ]; then
        print_success "DNS is correctly configured! $CUSTOM_DOMAIN → $CONTAINER_IP"
    else
        print_warning "DNS not fully propagated yet."
        echo "Expected: $CONTAINER_IP"
        echo "Got: $RESOLVED_IP"
        echo ""
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Please wait for DNS propagation and try again."
            exit 1
        fi
    fi
    
    # Let's Encrypt Certificate
    print_header "Step 2: Let's Encrypt SSL Certificate"
    
    CERT_DIR="/tmp/custom-domain-certs"
    mkdir -p "$CERT_DIR"
    
    print_info "Attempting to get Let's Encrypt certificate for: $CUSTOM_DOMAIN"
    
    # Use HTTP challenge since we have a working web server
    if sudo certbot certonly \
        --webroot \
        --webroot-path /var/www/html \
        --email "$EMAIL" \
        --agree-tos \
        --no-eff-email \
        --config-dir "$CERT_DIR/config" \
        --work-dir "$CERT_DIR/work" \
        --logs-dir "$CERT_DIR/logs" \
        -d "$CUSTOM_DOMAIN"; then
        
        print_success "Successfully obtained Let's Encrypt certificate!"
        
        # Copy certificates to deployment directory
        mkdir -p "/tmp/bidr-ssl-certs/$CUSTOM_DOMAIN"
        cp "$CERT_DIR/config/live/$CUSTOM_DOMAIN/fullchain.pem" "/tmp/bidr-ssl-certs/$CUSTOM_DOMAIN/"
        cp "$CERT_DIR/config/live/$CUSTOM_DOMAIN/privkey.pem" "/tmp/bidr-ssl-certs/$CUSTOM_DOMAIN/"
        
        print_success "Certificates copied to deployment directory"
        
        # Update deployment script
        print_header "Step 3: Update Deployment Configuration"
        
        # Create backup of current deployment script
        cp deploy-auth-ssl.sh deploy-auth-ssl.sh.backup
        
        # Update domain in deployment script
        sed -i.bak "s/bidr-auth-api.westus.azurecontainer.io/$CUSTOM_DOMAIN/g" deploy-auth-ssl.sh
        
        print_success "Updated deployment script for custom domain: $CUSTOM_DOMAIN"
        
        # Ask to redeploy
        echo ""
        read -p "Would you like to redeploy with the new trusted certificate? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_header "Step 4: Redeploying with Trusted Certificate"
            
            # Redeploy
            ./manage-auth-container.sh redeploy
            
            print_success "Deployment complete!"
            echo ""
            echo "🎉 Your API is now available with a trusted SSL certificate:"
            echo "   https://$CUSTOM_DOMAIN"
            echo "   https://$CUSTOM_DOMAIN/admin/"
            echo ""
            echo "✅ No more 'Not Secure' warnings!"
        else
            echo ""
            echo "To redeploy later, run: ./manage-auth-container.sh redeploy"
        fi
        
    else
        print_error "Failed to obtain Let's Encrypt certificate"
        echo ""
        echo "Common issues:"
        echo "1. DNS not fully propagated - wait longer and try again"
        echo "2. Port 80 not accessible for validation"
        echo "3. Domain not pointing to correct IP"
        echo ""
        echo "You can try manual DNS challenge instead:"
        echo "sudo certbot certonly --manual --preferred-challenges dns -d $CUSTOM_DOMAIN"
    fi
}

# Check prerequisites
if ! command -v certbot &> /dev/null; then
    print_error "certbot is not installed"
    echo "Install it with: brew install certbot (macOS) or sudo apt install certbot (Linux)"
    exit 1
fi

if ! command -v dig &> /dev/null; then
    print_error "dig is not installed"
    echo "Install it with: brew install bind (macOS) or sudo apt install dnsutils (Linux)"
    exit 1
fi

# Run main function
main "$@"
