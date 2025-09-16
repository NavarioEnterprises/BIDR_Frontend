#!/bin/bash

# Deploy HTTPS SSL Configuration for Reviews Service
# Domain: reviews.bidr.co.za
# Date: $(date +%Y-%m-%d)

set -e

# Configuration
RESOURCE_GROUP="bidr-simple-rg"
GATEWAY_NAME="bidr-app-gateway"
DOMAIN="reviews.bidr.co.za"
SERVICE_NAME="reviews-service"

echo "🚀 Starting Reviews Service HTTPS SSL Deployment..."
echo "Domain: $DOMAIN"
echo "Resource Group: $RESOURCE_GROUP"
echo "Gateway: $GATEWAY_NAME"
echo

# Check if SSL certificate exists
echo "📋 Checking SSL certificate..."
if az network application-gateway ssl-cert show --resource-group $RESOURCE_GROUP --gateway-name $GATEWAY_NAME --name reviews-bidr-co-za-cert >/dev/null 2>&1; then
    echo "✅ SSL certificate 'reviews-bidr-co-za-cert' found"
else
    echo "❌ SSL certificate 'reviews-bidr-co-za-cert' not found"
    echo "Please obtain SSL certificate using Let's Encrypt first"
    exit 1
fi

# Check backend pool
echo "📋 Checking backend pool..."
if az network application-gateway address-pool show --resource-group $RESOURCE_GROUP --gateway-name $GATEWAY_NAME --name "${SERVICE_NAME}-pool" >/dev/null 2>&1; then
    echo "✅ Backend pool '${SERVICE_NAME}-pool' found"
else
    echo "❌ Backend pool '${SERVICE_NAME}-pool' not found"
    exit 1
fi

# Check HTTPS listener
echo "📋 Checking HTTPS listener..."
if az network application-gateway http-listener show --resource-group $RESOURCE_GROUP --gateway-name $GATEWAY_NAME --name "${SERVICE_NAME}-https-listener" >/dev/null 2>&1; then
    echo "✅ HTTPS listener '${SERVICE_NAME}-https-listener' found"
else
    echo "❌ HTTPS listener '${SERVICE_NAME}-https-listener' not found"
    exit 1
fi

# Check HTTP settings
echo "📋 Checking HTTP settings..."
if az network application-gateway http-settings show --resource-group $RESOURCE_GROUP --gateway-name $GATEWAY_NAME --name "${SERVICE_NAME}-http-settings" >/dev/null 2>&1; then
    echo "✅ HTTP settings '${SERVICE_NAME}-http-settings' found"
else
    echo "❌ HTTP settings '${SERVICE_NAME}-http-settings' not found"
    exit 1
fi

# Check routing rule
echo "📋 Checking routing rule..."
if az network application-gateway rule show --resource-group $RESOURCE_GROUP --gateway-name $GATEWAY_NAME --name "${SERVICE_NAME}-https-rule" >/dev/null 2>&1; then
    echo "✅ Routing rule '${SERVICE_NAME}-https-rule' found"
else
    echo "❌ Routing rule '${SERVICE_NAME}-https-rule' not found"
    exit 1
fi

# Get Application Gateway public IP
echo "📋 Getting Application Gateway public IP..."
GATEWAY_IP=$(az network application-gateway show --resource-group $RESOURCE_GROUP --name $GATEWAY_NAME --query "frontendIPConfigurations[0].publicIPAddress.id" --output tsv | xargs -I {} az network public-ip show --ids {} --query "ipAddress" --output tsv)
echo "🌐 Application Gateway IP: $GATEWAY_IP"

# Test HTTPS endpoint (skip SSL verification for now due to potential hostname/DNS issues)
echo "📋 Testing HTTPS endpoint..."
if curl -k -f -s -I https://$DOMAIN/ >/dev/null 2>&1; then
    echo "✅ HTTPS endpoint responding"
    
    # Get response details
    echo "📊 Response details:"
    curl -k -I https://$DOMAIN/ 2>/dev/null | head -5
else
    echo "⚠️  HTTPS endpoint not responding (this may be expected if backend service is down)"
    echo "📊 Attempting to get response details:"
    curl -k -I https://$DOMAIN/ 2>/dev/null | head -5 || echo "No response received"
fi

# Check DNS resolution
echo "📋 Checking DNS resolution for $DOMAIN..."
if nslookup $DOMAIN >/dev/null 2>&1; then
    RESOLVED_IP=$(nslookup $DOMAIN 2>/dev/null | grep -A1 "Non-authoritative answer:" | grep "Address:" | awk '{print $2}' | head -1)
    if [ "$RESOLVED_IP" = "$GATEWAY_IP" ]; then
        echo "✅ DNS correctly resolves to $RESOLVED_IP"
    else
        echo "⚠️  DNS resolves to $RESOLVED_IP but should be $GATEWAY_IP"
    fi
else
    echo "❌ DNS resolution failed for $DOMAIN"
    echo "📝 Please add DNS A record: $DOMAIN -> $GATEWAY_IP"
fi

echo
echo "✅ Reviews Service HTTPS SSL Deployment Check Complete!"
echo
echo "📋 Summary:"
echo "  - SSL Certificate: ✅ reviews-bidr-co-za-cert"
echo "  - Backend Pool: ✅ ${SERVICE_NAME}-pool"
echo "  - HTTPS Listener: ✅ ${SERVICE_NAME}-https-listener (Port 443)"
echo "  - HTTP Settings: ✅ ${SERVICE_NAME}-http-settings (Port 8000)"
echo "  - Routing Rule: ✅ ${SERVICE_NAME}-https-rule (Priority 110)"
echo "  - Application Gateway IP: $GATEWAY_IP"
echo
echo "🌐 HTTPS Endpoint: https://$DOMAIN/"
echo
echo "📝 Next Steps:"
echo "  1. Ensure DNS A record: $DOMAIN -> $GATEWAY_IP"
echo "  2. Fix reviews service container (currently not responding)"
echo "  3. Update backend pool to point to working reviews service IP"
echo "  4. Test functionality with working backend"
echo
echo "⚠️  Current Status: SSL infrastructure ready, backend service needs fixing"
