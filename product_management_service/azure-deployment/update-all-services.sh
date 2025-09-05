#!/bin/bash

# BIDR Platform Update Script
# This script updates all BIDR microservices

set -e

echo "🚀 Updating BIDR Platform Services..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
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
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check if update scripts exist
PRODUCT_UPDATE_SCRIPT="$SCRIPT_DIR/update-product-service.sh"
AUTH_UPDATE_SCRIPT="$SCRIPT_DIR/update-auth-service.sh"

if [ ! -f "$PRODUCT_UPDATE_SCRIPT" ]; then
    print_error "Product service update script not found: $PRODUCT_UPDATE_SCRIPT"
    exit 1
fi

if [ ! -f "$AUTH_UPDATE_SCRIPT" ]; then
    print_error "Authentication service update script not found: $AUTH_UPDATE_SCRIPT"
    exit 1
fi

# Make scripts executable
chmod +x "$PRODUCT_UPDATE_SCRIPT"
chmod +x "$AUTH_UPDATE_SCRIPT"

print_status "Update scripts found and ready"

echo ""
echo "========================================"
print_header "🌟 BIDR Platform Update Process"
echo "========================================"
echo "This will update the following services:"
echo "1. 📦 Product Management Service"
echo "2. 🔐 Authentication Service"
echo ""
echo "Each service will be rebuilt, redeployed, and tested."
echo "The process takes approximately 5-10 minutes per service."
echo ""

# Ask for confirmation
read -p "Do you want to proceed with updating all services? (y/N): " -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_warning "Update cancelled by user"
    exit 0
fi

# Start timer
START_TIME=$(date +%s)

# Store original directory
ORIGINAL_DIR=$(pwd)

echo ""
print_header "📋 Pre-Update Status Check"
echo "========================================"

# Check current services status
print_status "Checking current service status..."

PRODUCT_STATUS=$(az container show --resource-group $RESOURCE_GROUP --name bidr-product-service --query 'instanceView.state' --output tsv 2>/dev/null || echo "NotFound")
AUTH_STATUS=$(az container show --resource-group $RESOURCE_GROUP --name bidr-auth-service --query 'instanceView.state' --output tsv 2>/dev/null || echo "NotFound")

echo "Product Management Service: $PRODUCT_STATUS"
echo "Authentication Service: $AUTH_STATUS"
echo ""

# Update 1: Product Management Service
print_header "🔄 Step 1: Updating Product Management Service"
echo "========================================"
print_status "Starting product management service update..."

if bash "$PRODUCT_UPDATE_SCRIPT"; then
    print_success "Product Management Service updated successfully!"
    PRODUCT_UPDATE_SUCCESS=true
else
    print_error "Product Management Service update failed!"
    PRODUCT_UPDATE_SUCCESS=false
fi

echo ""

# Update 2: Authentication Service  
print_header "🔄 Step 2: Updating Authentication Service"
echo "========================================"
print_status "Starting authentication service update..."

if bash "$AUTH_UPDATE_SCRIPT"; then
    print_success "Authentication Service updated successfully!"
    AUTH_UPDATE_SUCCESS=true
else
    print_error "Authentication Service update failed!"
    AUTH_UPDATE_SUCCESS=false
fi

# Return to original directory
cd "$ORIGINAL_DIR"

# Calculate total time
END_TIME=$(date +%s)
TOTAL_TIME=$((END_TIME - START_TIME))
MINUTES=$((TOTAL_TIME / 60))
SECONDS=$((TOTAL_TIME % 60))

echo ""
print_header "📊 Update Summary"
echo "========================================"

# Display results
if [ "$PRODUCT_UPDATE_SUCCESS" = true ]; then
    print_success "Product Management Service: Updated ✅"
else
    print_error "Product Management Service: Failed ❌"
fi

if [ "$AUTH_UPDATE_SUCCESS" = true ]; then
    print_success "Authentication Service: Updated ✅"
else
    print_error "Authentication Service: Failed ❌"
fi

echo ""
echo "⏱️  Total update time: ${MINUTES}m ${SECONDS}s"
echo ""

# Final status check
print_status "Final status check..."
sleep 5

NEW_PRODUCT_INFO=$(az container show --resource-group $RESOURCE_GROUP --name bidr-product-service --query '{fqdn: ipAddress.fqdn, state: instanceView.state, ip: ipAddress.ip}' --output json 2>/dev/null || echo '{}')
NEW_AUTH_INFO=$(az container show --resource-group $RESOURCE_GROUP --name bidr-auth-service --query '{fqdn: ipAddress.fqdn, state: instanceView.state, ip: ipAddress.ip}' --output json 2>/dev/null || echo '{}')

echo ""
print_header "🏢 Updated BIDR Platform Status"
echo "========================================"

if [ "$NEW_PRODUCT_INFO" != "{}" ]; then
    PRODUCT_FQDN=$(echo $NEW_PRODUCT_INFO | jq -r '.fqdn // "N/A"')
    PRODUCT_STATE=$(echo $NEW_PRODUCT_INFO | jq -r '.state // "Unknown"')
    PRODUCT_IP=$(echo $NEW_PRODUCT_INFO | jq -r '.ip // "N/A"')
    
    echo "📦 Product Management Service:"
    echo "   Status: $PRODUCT_STATE"
    echo "   URL: http://$PRODUCT_FQDN:8000"
    echo "   IP: $PRODUCT_IP"
else
    print_error "Could not get product service information"
fi

echo ""

if [ "$NEW_AUTH_INFO" != "{}" ]; then
    AUTH_FQDN=$(echo $NEW_AUTH_INFO | jq -r '.fqdn // "N/A"')
    AUTH_STATE=$(echo $NEW_AUTH_INFO | jq -r '.state // "Unknown"')
    AUTH_IP=$(echo $NEW_AUTH_INFO | jq -r '.ip // "N/A"')
    
    echo "🔐 Authentication Service:"
    echo "   Status: $AUTH_STATE"
    echo "   URL: http://$AUTH_FQDN:8001"
    echo "   IP: $AUTH_IP"
else
    print_error "Could not get authentication service information"
fi

echo ""
print_header "🎯 Quick Test Commands"
echo "========================================"
if [ "$NEW_PRODUCT_INFO" != "{}" ] && [ "$PRODUCT_FQDN" != "N/A" ]; then
    echo "curl http://$PRODUCT_FQDN:8000/health/"
fi
if [ "$NEW_AUTH_INFO" != "{}" ] && [ "$AUTH_FQDN" != "N/A" ]; then
    echo "curl http://$AUTH_FQDN:8001/health/"
fi

echo ""

# Overall success check
if [ "$PRODUCT_UPDATE_SUCCESS" = true ] && [ "$AUTH_UPDATE_SUCCESS" = true ]; then
    print_success "🎊 All services updated successfully!"
    echo "Your BIDR platform is now running the latest code."
    exit 0
elif [ "$PRODUCT_UPDATE_SUCCESS" = true ] || [ "$AUTH_UPDATE_SUCCESS" = true ]; then
    print_warning "⚠️  Partial update completed. Some services may need manual attention."
    exit 1
else
    print_error "❌ Update failed for all services. Please check the logs and try again."
    exit 1
fi
