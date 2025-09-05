#!/bin/bash

echo "============================================"
echo "SSL Certificate Setup for api.bidr.co.za"
echo "Using DNS-01 challenge method"
echo "============================================"

# Check if DNS has propagated correctly
echo "🔍 Checking DNS propagation..."
CURRENT_IP=$(dig api.bidr.co.za +short | head -1)
EXPECTED_IP="40.86.164.8"

echo "Current DNS IP: $CURRENT_IP"
echo "Expected IP: $EXPECTED_IP"

if [ "$CURRENT_IP" != "$EXPECTED_IP" ]; then
    echo "❌ DNS not yet propagated. Current: $CURRENT_IP, Expected: $EXPECTED_IP"
    echo "Please wait for DNS propagation and try again."
    exit 1
fi

echo "✅ DNS propagation confirmed!"

# Test connectivity
echo "🔍 Testing connectivity to api.bidr.co.za:8000..."
if curl -s -I http://api.bidr.co.za:8000 >/dev/null 2>&1; then
    echo "✅ Server is responding on port 8000"
else
    echo "❌ Server not responding on port 8000"
    echo "Please check that your container is running"
    exit 1
fi

# Create directories
mkdir -p /tmp/ssl-setup/{config,work,logs}

echo "🔑 Getting SSL certificate using DNS-01 challenge..."
echo "⚠️  You will need to manually add DNS TXT records when prompted"

# Use staging environment first for testing
certbot certonly \
    --manual \
    --preferred-challenges dns \
    --server https://acme-staging-v02.api.letsencrypt.org/directory \
    --config-dir /tmp/ssl-setup/config \
    --work-dir /tmp/ssl-setup/work \
    --logs-dir /tmp/ssl-setup/logs \
    -d api.bidr.co.za \
    --agree-tos \
    --no-eff-email \
    --register-unsafely-without-email \
    --manual-public-ip-logging-ok

echo "============================================"
echo "Next Steps:"
echo "1. If the staging certificate worked, run this script with --production flag"
echo "2. Configure your application to use the certificates"
echo "3. Set up reverse proxy for HTTPS on port 443"
echo "============================================"
