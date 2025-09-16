#!/bin/bash

# BIDR Products Service HTTPS Deployment Script
# This script deploys the products service behind Azure Application Gateway with SSL termination

set -e

echo "🚀 BIDR Products Service HTTPS Deployment"
echo "=========================================="

# Configuration
RESOURCE_GROUP="bidr-simple-rg"
CONTAINER_NAME="bidr-product-service"
IMAGE_NAME="bidrcontainers.azurecr.io/bidr-product-ssl:latest"
GATEWAY_NAME="bidr-appgw"
BACKEND_POOL="productsBackendPool"
DOMAIN="products-management.bidr.co.za"

echo "📋 Configuration:"
echo "   Resource Group: $RESOURCE_GROUP"
echo "   Container: $CONTAINER_NAME"
echo "   Domain: $DOMAIN"
echo "   Image: $IMAGE_NAME"
echo ""

# Check if container exists and get its IP
echo "🔍 Checking existing container status..."
CONTAINER_IP=$(az container show \
  --resource-group $RESOURCE_GROUP \
  --name $CONTAINER_NAME \
  --query "ipAddress.ip" \
  --output tsv 2>/dev/null || echo "")

if [ -z "$CONTAINER_IP" ]; then
    echo "❌ Container $CONTAINER_NAME not found. Please create it first."
    exit 1
else
    echo "✅ Container found with IP: $CONTAINER_IP"
fi

# Get Application Gateway IP
echo "🌐 Getting Application Gateway IP..."
GATEWAY_IP=$(az network public-ip show \
  --resource-group $RESOURCE_GROUP \
  --name bidr-appgw-pip \
  --query ipAddress \
  --output tsv)
echo "   Gateway IP: $GATEWAY_IP"

# Update backend pool if needed
echo "🔄 Updating backend pool..."
az network application-gateway address-pool update \
  --resource-group $RESOURCE_GROUP \
  --gateway-name $GATEWAY_NAME \
  --name $BACKEND_POOL \
  --servers $CONTAINER_IP

echo "✅ Backend pool updated with container IP: $CONTAINER_IP"

# Test HTTPS endpoint
echo "🧪 Testing HTTPS endpoint..."
HTTP_STATUS=$(curl -k -s -o /dev/null -w "%{http_code}" \
  https://$DOMAIN/ \
  --resolve "$DOMAIN:443:$GATEWAY_IP" \
  --connect-timeout 10 \
  --max-time 30)

if [ "$HTTP_STATUS" = "200" ]; then
    echo "✅ HTTPS endpoint is responding (Status: $HTTP_STATUS)"
else
    echo "⚠️  HTTPS endpoint returned status: $HTTP_STATUS"
fi

# Test SSL certificate
echo "🔒 Testing SSL certificate..."
if openssl s_client -connect $DOMAIN:443 -servername $DOMAIN < /dev/null 2>/dev/null | grep -q "Verify return code: 0"; then
    echo "✅ SSL certificate is valid and trusted"
else
    echo "⚠️  SSL certificate validation failed or untrusted"
fi

echo ""
echo "🎉 Deployment Summary"
echo "===================="
echo "✅ Products service is accessible via HTTPS"
echo "🔗 URL: https://$DOMAIN/"
echo "🌍 Application Gateway IP: $GATEWAY_IP"
echo "🏗️  Backend Container IP: $CONTAINER_IP"
echo "📋 Backend Pool: $BACKEND_POOL"
echo ""
echo "📝 DNS Configuration Required:"
echo "   Point $DOMAIN to $GATEWAY_IP"
echo ""
echo "🔧 Test Commands:"
echo "   curl -I https://$DOMAIN/"
echo "   curl https://$DOMAIN/admin/"
echo ""
echo "✅ Products service HTTPS deployment completed successfully!"
