#!/bin/bash

# BIDR SSL Certificate Generation Script
# This script generates Let's Encrypt SSL certificates for all BIDR services

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
CERT_DIR="/tmp/bidr-ssl-certs"
DOMAIN_BASE="westus.azurecontainer.io"

# Service domains (static DNS names for consistent SSL certificates)
SERVICES=(
    "bidr-auth-api.westus.azurecontainer.io"
    "bidr-product-api.westus.azurecontainer.io" 
    "bidr-chat-api.westus.azurecontainer.io"
    "bidr-payment-api.westus.azurecontainer.io"
    "bidr-resolution-api.westus.azurecontainer.io"
    "bidr-notifications-api.westus.azurecontainer.io"
    "bidr-transactions-api.westus.azurecontainer.io"
    "bidr-reviews-api.westus.azurecontainer.io"
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

# Check if certbot is installed
check_certbot() {
    if ! command -v certbot &> /dev/null; then
        print_error "certbot is not installed"
        echo "Please install certbot first:"
        echo "  macOS: brew install certbot"
        echo "  Ubuntu: sudo apt-get install certbot"
        echo "  CentOS: sudo yum install certbot"
        exit 1
    fi
    print_success "certbot is installed"
}

# Create certificate directory
setup_cert_directory() {
    print_header "Setting up certificate directory"
    
    if [ -d "$CERT_DIR" ]; then
        print_warning "Certificate directory already exists, cleaning up..."
        rm -rf "$CERT_DIR"
    fi
    
    mkdir -p "$CERT_DIR"
    print_success "Certificate directory created: $CERT_DIR"
}

# Generate self-signed certificates for testing
generate_self_signed_certs() {
    print_header "Generating Self-Signed Certificates"
    print_warning "Using self-signed certificates for testing purposes"
    
    for domain in "${SERVICES[@]}"; do
        echo -e "${BLUE}Generating certificate for: $domain${NC}"
        
        # Create domain-specific directory
        domain_dir="$CERT_DIR/$domain"
        mkdir -p "$domain_dir"
        
        # Generate private key
        openssl genrsa -out "$domain_dir/privkey.pem" 2048
        
        # Generate certificate signing request
        openssl req -new -key "$domain_dir/privkey.pem" -out "$domain_dir/cert.csr" \
            -subj "/C=US/ST=WA/L=Seattle/O=BIDR/OU=IT/CN=$domain"
        
        # Generate self-signed certificate
        openssl x509 -req -days 365 -in "$domain_dir/cert.csr" \
            -signkey "$domain_dir/privkey.pem" -out "$domain_dir/fullchain.pem"
        
        # Set proper permissions
        chmod 600 "$domain_dir/privkey.pem"
        chmod 644 "$domain_dir/fullchain.pem"
        
        print_success "Certificate generated for $domain"
    done
}

# Generate Let's Encrypt certificates (requires domain validation)
generate_letsencrypt_certs() {
    print_header "Generating Let's Encrypt Certificates"
    print_warning "This requires domain validation and may not work with Azure Container Instance domains"
    
    for domain in "${SERVICES[@]}"; do
        echo -e "${BLUE}Attempting Let's Encrypt certificate for: $domain${NC}"
        
        # Create domain-specific directory
        domain_dir="$CERT_DIR/$domain"
        mkdir -p "$domain_dir"
        
        # Use manual mode for Azure Container Instances
        if certbot certonly --manual --preferred-challenges dns \
            --email admin@bidr.com \
            --agree-tos --no-eff-email \
            --cert-path "$domain_dir/fullchain.pem" \
            --key-path "$domain_dir/privkey.pem" \
            -d "$domain"; then
            print_success "Let's Encrypt certificate generated for $domain"
        else
            print_error "Failed to generate Let's Encrypt certificate for $domain"
            print_warning "Falling back to self-signed certificate"
            
            # Generate self-signed as fallback
            openssl genrsa -out "$domain_dir/privkey.pem" 2048
            openssl req -new -key "$domain_dir/privkey.pem" -out "$domain_dir/cert.csr" \
                -subj "/C=US/ST=WA/L=Seattle/O=BIDR/OU=IT/CN=$domain"
            openssl x509 -req -days 365 -in "$domain_dir/cert.csr" \
                -signkey "$domain_dir/privkey.pem" -out "$domain_dir/fullchain.pem"
            
            chmod 600 "$domain_dir/privkey.pem"
            chmod 644 "$domain_dir/fullchain.pem"
        fi
    done
}

# Create certificate bundle for deployment
create_cert_bundle() {
    print_header "Creating Certificate Bundle"
    
    bundle_dir="$CERT_DIR/bundle"
    mkdir -p "$bundle_dir"
    
    for domain in "${SERVICES[@]}"; do
        domain_clean=$(echo "$domain" | sed 's/\./-/g')
        cp "$CERT_DIR/$domain/fullchain.pem" "$bundle_dir/${domain_clean}-cert.pem"
        cp "$CERT_DIR/$domain/privkey.pem" "$bundle_dir/${domain_clean}-key.pem"
    done
    
    # Create tarball
    cd "$CERT_DIR"
    tar -czf "bidr-ssl-certificates.tar.gz" bundle/
    
    print_success "Certificate bundle created: $CERT_DIR/bidr-ssl-certificates.tar.gz"
}

# Display certificate information
display_cert_info() {
    print_header "Certificate Information"
    
    for domain in "${SERVICES[@]}"; do
        echo -e "${BLUE}Certificate for: $domain${NC}"
        cert_file="$CERT_DIR/$domain/fullchain.pem"
        
        if [ -f "$cert_file" ]; then
            echo "  Subject: $(openssl x509 -noout -subject -in "$cert_file" | cut -d= -f2-)"
            echo "  Issuer: $(openssl x509 -noout -issuer -in "$cert_file" | cut -d= -f2-)"
            echo "  Valid from: $(openssl x509 -noout -startdate -in "$cert_file" | cut -d= -f2-)"
            echo "  Valid until: $(openssl x509 -noout -enddate -in "$cert_file" | cut -d= -f2-)"
            echo ""
        fi
    done
}

# Main execution
main() {
    print_header "BIDR SSL Certificate Generator"
    
    # Check prerequisites
    check_certbot
    
    # Setup
    setup_cert_directory
    
    # Ask user preference
    echo -e "${YELLOW}Choose certificate type:${NC}"
    echo "1) Self-signed certificates (recommended for testing)"
    echo "2) Let's Encrypt certificates (requires domain validation)"
    read -p "Enter choice [1-2]: " choice
    
    case $choice in
        1)
            generate_self_signed_certs
            ;;
        2)
            generate_letsencrypt_certs
            ;;
        *)
            print_warning "Invalid choice, using self-signed certificates"
            generate_self_signed_certs
            ;;
    esac
    
    # Create bundle
    create_cert_bundle
    
    # Display information
    display_cert_info
    
    print_success "SSL certificate generation completed!"
    echo -e "${GREEN}Certificates location: $CERT_DIR${NC}"
    echo -e "${GREEN}Certificate bundle: $CERT_DIR/bidr-ssl-certificates.tar.gz${NC}"
}

# Run main function
main "$@"
