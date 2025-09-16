#!/bin/bash

# Let's Encrypt Certificate for Azure Container Instance
# Note: This is experimental and may not work due to Azure's domain restrictions

set -e

DOMAIN="bidr-auth-api.westus.azurecontainer.io"
EMAIL="admin@bidr.com"
CERT_DIR="/tmp/letsencrypt-certs"

echo "🔍 Attempting to get Let's Encrypt certificate for: $DOMAIN"
echo "⚠️  This may not work with Azure Container Instance domains"

# Method 1: DNS Challenge (most likely to work)
echo "📋 Attempting DNS challenge method..."
echo "You'll need to add a TXT record to your DNS when prompted"

mkdir -p "$CERT_DIR"

# Use manual DNS challenge
sudo certbot certonly \
  --manual \
  --preferred-challenges dns \
  --email "$EMAIL" \
  --agree-tos \
  --no-eff-email \
  --config-dir "$CERT_DIR/config" \
  --work-dir "$CERT_DIR/work" \
  --logs-dir "$CERT_DIR/logs" \
  -d "$DOMAIN"

if [ $? -eq 0 ]; then
    echo "✅ Successfully obtained Let's Encrypt certificate!"
    echo "📁 Certificate location: $CERT_DIR/config/live/$DOMAIN/"
    
    # Copy certificates to our standard location
    mkdir -p "/tmp/bidr-ssl-certs/$DOMAIN"
    cp "$CERT_DIR/config/live/$DOMAIN/fullchain.pem" "/tmp/bidr-ssl-certs/$DOMAIN/"
    cp "$CERT_DIR/config/live/$DOMAIN/privkey.pem" "/tmp/bidr-ssl-certs/$DOMAIN/"
    
    echo "✅ Certificates copied to deployment directory"
    echo "🚀 Now run: ./deploy-auth-ssl.sh to redeploy with trusted certificate"
else
    echo "❌ Let's Encrypt certificate generation failed"
    echo "💡 This is expected for Azure Container Instance domains"
    echo "🔄 Consider using a custom domain instead"
fi
