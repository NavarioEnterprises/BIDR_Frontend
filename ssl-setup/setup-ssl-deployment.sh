#!/bin/bash

# BIDR SSL Setup Script
# This script sets up the SSL deployment environment and makes scripts executable

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

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_header "BIDR SSL Deployment Setup"

# Make scripts executable
print_info "Making scripts executable..."
chmod +x ssl-setup/*.sh
print_success "Scripts are now executable"

# Check if certbot is available
if command -v certbot &> /dev/null; then
    print_success "certbot is available"
else
    echo -e "${YELLOW}⚠️  certbot is not installed. Installing via homebrew...${NC}"
    if command -v brew &> /dev/null; then
        brew install certbot
        print_success "certbot installed"
    else
        echo -e "${RED}❌ homebrew not found. Please install certbot manually:${NC}"
        echo "  macOS: brew install certbot"
        echo "  Ubuntu: sudo apt-get install certbot"
        echo "  CentOS: sudo yum install certbot"
    fi
fi

print_header "SSL Deployment Ready!"
echo ""
echo "Next steps:"
echo "1. Generate SSL certificates:"
echo "   ./ssl-setup/generate-ssl-certs.sh"
echo ""
echo "2. Deploy SSL-enabled containers:"
echo "   ./ssl-setup/deploy-ssl-containers.sh"
echo ""
echo "This will:"
echo "  • Generate SSL certificates for all services"
echo "  • Build Docker images with nginx SSL proxy"
echo "  • Deploy containers with HTTPS endpoints"
echo "  • Generate updated Flutter/Dart configuration"
echo ""
print_success "Setup completed!"
