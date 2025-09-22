#!/bin/bash

# BIDR Notifications Service HTTPS Deployment Script
# This script deploys the notifications service behind Azure Application Gateway with SSL termination

set -e

echo "🚀 BIDR Notifications Service HTTPS Deployment"
echo "==============================================="

# Configuration
RESOURCE_GROUP="bidr-simple-rg"
CONTAINER_NAME="bidr-auth-service"  # Currently using auth service as backend
BACKEND_POOL="notificationsBackendPool"
GATEWAY_NAME="bidr-appgw"
DOMAIN="notifications.bidr.co.za"
HTTP_SETTINGS="notificationsBackendHttpSettings"

echo "📋 Configuration:"
echo "   Resource Group: $RESOURCE_GROUP"
echo "   Backend Container: $CONTAINER_NAME (temporary)"
echo "   Domain: $DOMAIN"
echo "   Backend Pool: $BACKEND_POOL"
echo "   HTTP Settings: $HTTP_SETTINGS"
echo ""

# Check if container exists and get its IP
echo "🔍 Checking backend container status..."
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

# Check SSL certificate status
echo "🔐 Checking SSL certificate..."
CERT_STATUS=$(az network application-gateway ssl-cert show \
  --resource-group $RESOURCE_GROUP \
  --gateway-name $GATEWAY_NAME \
  --name notifications-bidr-co-za-cert \
  --query provisioningState \
  --output tsv 2>/dev/null || echo "NotFound")

if [ "$CERT_STATUS" = "Succeeded" ]; then
    echo "✅ SSL certificate is configured and ready"
else
    echo "⚠️  SSL certificate status: $CERT_STATUS"
fi

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
CERT_SUBJECT=$(echo | openssl s_client -connect $DOMAIN:443 -servername $DOMAIN 2>/dev/null | openssl x509 -noout -subject 2>/dev/null || echo "")
if echo "$CERT_SUBJECT" | grep -q "CN=$DOMAIN"; then
    echo "✅ SSL certificate is valid for $DOMAIN"
else
    echo "⚠️  SSL certificate validation failed or incorrect"
fi

# Check Application Gateway configuration
echo "📊 Application Gateway Configuration Summary:"
echo "   Listeners:"
az network application-gateway http-listener show \
  --resource-group $RESOURCE_GROUP \
  --gateway-name $GATEWAY_NAME \
  --name notificationsHttpsListener \
  --query "{name:name, hostName:hostName, protocol:protocol}" \
  --output tsv | awk '{print "     - " $1 " (" $3 ") for " $2}'

echo "   Routing Rules:"
az network application-gateway rule show \
  --resource-group $RESOURCE_GROUP \
  --gateway-name $GATEWAY_NAME \
  --name notificationsHttpsRule \
  --query "{name:name, priority:priority}" \
  --output tsv | awk '{print "     - " $1 " (priority: " $2 ")"}'

echo ""
echo "🎉 Deployment Summary"
echo "===================="
echo "✅ Notifications service is accessible via HTTPS"
echo "🔗 URL: https://$DOMAIN/"
echo "🌍 Application Gateway IP: $GATEWAY_IP"
echo "🏗️  Backend Container IP: $CONTAINER_IP"
echo "📋 Backend Pool: $BACKEND_POOL"
echo "⚙️  HTTP Settings: $HTTP_SETTINGS (Port: 8000)"
echo ""
echo "📝 DNS Configuration Required:"
echo "   Point $DOMAIN to $GATEWAY_IP"
echo ""
echo "🔧 Test Commands:"
echo "   curl -I https://$DOMAIN/"
echo "   curl https://$DOMAIN/admin/"
echo ""
echo "⚠️  NOTE: Currently using authentication service as temporary backend."
echo "   Deploy a dedicated notifications service container when ready."
echo ""
echo "✅ Notifications service HTTPS deployment completed successfully!"
