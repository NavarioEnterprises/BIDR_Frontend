#!/bin/bash

# Custom Domain SSL Certificate Setup for api.bidr.co.za
# This script sets up trusted SSL certificates for your BIDR API

set -e

# Configuration
CUSTOM_DOMAIN="api.bidr.co.za"
CONTAINER_IP="20.66.102.242"
EMAIL="admin@bidr.co.za"  # Change this to your email

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

main() {
    print_header "SSL Setup for api.bidr.co.za"
    
    echo "Domain: $CUSTOM_DOMAIN"
    echo "Container IP: $CONTAINER_IP"
    echo "Email: $EMAIL"
    echo ""
    
    # Step 1: DNS Check
    print_header "Step 1: Checking DNS Configuration"
    
    print_info "Checking if $CUSTOM_DOMAIN points to $CONTAINER_IP..."
    RESOLVED_IP=$(dig +short "$CUSTOM_DOMAIN" | tail -n1)
    
    if [ -z "$RESOLVED_IP" ]; then
        print_error "DNS not configured yet!"
        echo ""
        echo "Please add this A record to your DNS:"
        echo "  Type: A"
        echo "  Name: api"
        echo "  Value: $CONTAINER_IP"
        echo "  TTL: 300"
        echo ""
        echo "Then wait 5-15 minutes and run this script again."
        exit 1
    elif [ "$RESOLVED_IP" = "$CONTAINER_IP" ]; then
        print_success "DNS is correctly configured! $CUSTOM_DOMAIN → $CONTAINER_IP"
    else
        print_warning "DNS is configured but pointing to wrong IP"
        echo "Expected: $CONTAINER_IP"
        echo "Got: $RESOLVED_IP"
        echo ""
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Please update your DNS A record and try again."
            exit 1
        fi
    fi
    
    # Step 2: Test HTTP connectivity
    print_header "Step 2: Testing HTTP Connectivity"
    
    print_info "Testing if $CUSTOM_DOMAIN is accessible via HTTP..."
    if curl -s --connect-timeout 10 "http://$CUSTOM_DOMAIN" > /dev/null; then
        print_success "HTTP connectivity works!"
    else
        print_error "Cannot connect to http://$CUSTOM_DOMAIN"
        echo "Make sure your DNS is propagated and try again."
        exit 1
    fi
    
    # Step 3: Let's Encrypt Certificate
    print_header "Step 3: Getting Let's Encrypt SSL Certificate"
    
    CERT_DIR="/tmp/bidr-custom-certs"
    mkdir -p "$CERT_DIR"
    
    print_info "Requesting certificate for: $CUSTOM_DOMAIN"
    print_warning "This may take a few minutes..."
    
    # Try HTTP challenge first (webroot method)
    if sudo certbot certonly \
        --standalone \
        --preferred-challenges http \
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
        
        # Step 4: Update deployment configuration
        print_header "Step 4: Updating Deployment Configuration"
        
        # Backup current deployment script
        cp deploy-auth-ssl.sh deploy-auth-ssl.sh.backup
        print_success "Created backup of deployment script"
        
        # Update domain in deployment script
        sed -i.bak "s/bidr-auth-api.westus.azurecontainer.io/$CUSTOM_DOMAIN/g" deploy-auth-ssl.sh
        print_success "Updated deployment script for domain: $CUSTOM_DOMAIN"
        
        # Update SSL certificate generation script
        cp ssl-setup/generate-ssl-certs.sh ssl-setup/generate-ssl-certs.sh.backup
        sed -i.bak "s/bidr-auth-api.westus.azurecontainer.io/$CUSTOM_DOMAIN/g" ssl-setup/generate-ssl-certs.sh
        print_success "Updated SSL generation script"
        
        # Update management script
        cp manage-auth-container.sh manage-auth-container.sh.backup
        sed -i.bak "s/bidr-auth-api.westus.azurecontainer.io/$CUSTOM_DOMAIN/g" manage-auth-container.sh
        print_success "Updated management script"
        
        # Step 5: Redeploy with trusted certificate
        print_header "Step 5: Redeploying with Trusted Certificate"
        
        echo ""
        read -p "Redeploy now with trusted SSL certificate? (Y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Nn]$ ]]; then
            echo "Skipping redeployment. To redeploy later, run:"
            echo "  ./manage-auth-container.sh redeploy"
        else
            print_info "Redeploying container with trusted SSL certificate..."
            
            # Delete current container
            print_info "Deleting current container..."
            az container delete --resource-group bidr-simple-rg --name bidr-auth-ssl-container --yes
            
            # Deploy with new configuration
            print_info "Deploying with trusted certificate..."
            ./deploy-auth-ssl.sh
            
            # Wait for deployment
            sleep 10
            
            # Test the new deployment
            print_header "Step 6: Testing Trusted SSL"
            
            print_info "Testing HTTPS with trusted certificate..."
            if curl -s --connect-timeout 15 "https://$CUSTOM_DOMAIN" > /dev/null; then
                print_success "HTTPS is working with trusted certificate!"
                
                # Check certificate
                print_info "Certificate details:"
                echo "$(openssl s_client -connect "$CUSTOM_DOMAIN:443" -servername "$CUSTOM_DOMAIN" 2>/dev/null | openssl x509 -noout -subject -dates 2>/dev/null)"
                
                echo ""
                print_success "🎉 Setup Complete!"
                echo ""
                echo "Your API is now available with trusted SSL:"
                echo "  🌐 Main API: https://$CUSTOM_DOMAIN"
                echo "  🔐 Admin Panel: https://$CUSTOM_DOMAIN/admin/"
                echo "  📝 Registration: https://$CUSTOM_DOMAIN/register/"
                echo ""
                echo "✅ No more 'Not Secure' warnings!"
                echo "✅ Flutter Web will work without SSL issues!"
                echo "✅ All browsers will show secure lock icon!"
                
            else
                print_warning "HTTPS not responding yet. This may be normal during deployment."
                echo "Wait a few minutes and test manually:"
                echo "  https://$CUSTOM_DOMAIN"
            fi
        fi
        
    else
        print_error "Failed to obtain Let's Encrypt certificate"
        echo ""
        echo "Common issues and solutions:"
        echo "1. Port 80 blocked - try DNS challenge instead:"
        echo "   sudo certbot certonly --manual --preferred-challenges dns -d $CUSTOM_DOMAIN"
        echo ""
        echo "2. DNS not fully propagated - wait longer and retry"
        echo ""
        echo "3. Firewall blocking - check Azure Network Security Group"
        
        # Offer DNS challenge as alternative
        echo ""
        read -p "Try DNS challenge method instead? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_info "Starting DNS challenge..."
            sudo certbot certonly \
                --manual \
                --preferred-challenges dns \
                --email "$EMAIL" \
                --agree-tos \
                --no-eff-email \
                --config-dir "$CERT_DIR/config" \
                --work-dir "$CERT_DIR/work" \
                --logs-dir "$CERT_DIR/logs" \
                -d "$CUSTOM_DOMAIN"
        fi
    fi
}

# Check prerequisites
check_prerequisites() {
    local missing_tools=()
    
    if ! command -v certbot &> /dev/null; then
        missing_tools+=("certbot")
    fi
    
    if ! command -v dig &> /dev/null; then
        missing_tools+=("dig")
    fi
    
    if ! command -v az &> /dev/null; then
        missing_tools+=("azure-cli")
    fi
    
    if [ ${#missing_tools[@]} -ne 0 ]; then
        print_error "Missing required tools: ${missing_tools[*]}"
        echo ""
        echo "Install missing tools:"
        for tool in "${missing_tools[@]}"; do
            case $tool in
                "certbot")
                    echo "  brew install certbot (macOS)"
                    echo "  sudo apt install certbot (Ubuntu)"
                    ;;
                "dig")
                    echo "  brew install bind (macOS)"
                    echo "  sudo apt install dnsutils (Ubuntu)"
                    ;;
                "azure-cli")
                    echo "  brew install azure-cli (macOS)"
                    echo "  curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash (Ubuntu)"
                    ;;
            esac
        done
        exit 1
    fi
}

# Run checks and main function
check_prerequisites
main "$@"
