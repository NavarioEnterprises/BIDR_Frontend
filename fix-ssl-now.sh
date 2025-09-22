#!/bin/bash

# Quick SSL Certificate Fix for api.bidr.co.za
# This fixes the certificate authority invalid error

set -e

DOMAIN="api.bidr.co.za"
EMAIL="admin@bidr.co.za"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() {
    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}============================================${NC}"
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

print_header "Quick SSL Fix for $DOMAIN"

# Check if we can connect to the domain
print_info "Testing connectivity to $DOMAIN..."
if ! curl -k -s --connect-timeout 10 "https://$DOMAIN" > /dev/null; then
    print_error "Cannot connect to $DOMAIN. Check DNS and container status."
    exit 1
fi

print_success "Domain is accessible"

# Method 1: Try DNS Challenge (safest for Azure containers)
print_info "Getting Let's Encrypt certificate using DNS challenge..."
echo "This will require you to add a DNS TXT record."

sudo certbot certonly \
    --manual \
    --preferred-challenges dns \
    --email "$EMAIL" \
    --agree-tos \
    --no-eff-email \
    --config-dir "/tmp/ssl-fix/config" \
    --work-dir "/tmp/ssl-fix/work" \
    --logs-dir "/tmp/ssl-fix/logs" \
    -d "$DOMAIN"

if [ $? -eq 0 ]; then
    print_success "Certificate obtained successfully!"
    
    # Copy certificates
    mkdir -p "/tmp/bidr-ssl-certs/$DOMAIN"
    sudo cp "/tmp/ssl-fix/config/live/$DOMAIN/fullchain.pem" "/tmp/bidr-ssl-certs/$DOMAIN/"
    sudo cp "/tmp/ssl-fix/config/live/$DOMAIN/privkey.pem" "/tmp/bidr-ssl-certs/$DOMAIN/"
    sudo chown $(whoami) "/tmp/bidr-ssl-certs/$DOMAIN/"*
    
    print_success "Certificates copied"
    
    # Update deployment script
    sed -i.bak "s/bidr-auth-api.westus.azurecontainer.io/$DOMAIN/g" deploy-auth-ssl.sh
    print_success "Updated deployment script"
    
    # Ask to redeploy
    echo ""
    read -p "Redeploy container with trusted certificate now? (Y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        print_info "Redeploying..."
        ./manage-auth-container.sh redeploy
        
        print_success "🎉 SSL certificate fixed!"
        echo ""
        echo "Your site should now show as secure:"
        echo "https://$DOMAIN"
    fi
else
    print_error "Certificate generation failed. Trying alternative method..."
    
    # Alternative: Use existing certificate but update domain
    print_info "Creating certificate with correct domain name..."
    
    # Generate new self-signed cert with correct domain
    mkdir -p "/tmp/bidr-ssl-certs/$DOMAIN"
    
    # Generate private key
    openssl genrsa -out "/tmp/bidr-ssl-certs/$DOMAIN/privkey.pem" 2048
    
    # Generate certificate with correct domain
    openssl req -new -key "/tmp/bidr-ssl-certs/$DOMAIN/privkey.pem" \
        -out "/tmp/bidr-ssl-certs/$DOMAIN/cert.csr" \
        -subj "/C=ZA/ST=Gauteng/L=Johannesburg/O=BIDR/OU=IT/CN=$DOMAIN"
    
    # Generate self-signed certificate
    openssl x509 -req -days 365 \
        -in "/tmp/bidr-ssl-certs/$DOMAIN/cert.csr" \
        -signkey "/tmp/bidr-ssl-certs/$DOMAIN/privkey.pem" \
        -out "/tmp/bidr-ssl-certs/$DOMAIN/fullchain.pem"
    
    # Set permissions
    chmod 600 "/tmp/bidr-ssl-certs/$DOMAIN/privkey.pem"
    chmod 644 "/tmp/bidr-ssl-certs/$DOMAIN/fullchain.pem"
    
    print_success "Generated self-signed certificate for $DOMAIN"
    
    # Update deployment script
    sed -i.bak "s/bidr-auth-api.westus.azurecontainer.io/$DOMAIN/g" deploy-auth-ssl.sh
    print_success "Updated deployment script"
    
    # Ask to redeploy
    echo ""
    read -p "Redeploy with corrected certificate? (Y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        print_info "Redeploying..."
        ./manage-auth-container.sh redeploy
        
        echo ""
        echo "🔧 Certificate updated for correct domain"
        echo "Note: This is still self-signed, so browsers will show a warning"
        echo "But the domain name will match ($DOMAIN)"
        echo ""
        echo "To get a trusted certificate, you'll need to:"
        echo "1. Use Let's Encrypt with proper domain validation"
        echo "2. Or purchase a commercial SSL certificate"
    fi
fi
