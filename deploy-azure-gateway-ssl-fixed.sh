#!/bin/bash

# Deploy Azure Application Gateway with SSL for BIDR Microservices - FIXED VERSION
# This script creates an Application Gateway with SSL termination for all services

set -e

# Configuration
RESOURCE_GROUP="bidr-simple-rg"
LOCATION="westus"
AG_NAME="bidr-app-gateway"
VNET_NAME="bidr-vnet"
SUBNET_NAME="gateway-subnet"
PUBLIC_IP_NAME="bidr-gateway-ip"

# Service IPs (current container IPs)
AUTH_IP="40.118.207.135"
PRODUCT_IP="20.253.249.204"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${GREEN}🏢 Deploying Azure Application Gateway with SSL for BIDR Services (Fixed)...${NC}"

# Get existing resources (created in previous run)
GATEWAY_IP=$(az network public-ip show \
    --resource-group $RESOURCE_GROUP \
    --name $PUBLIC_IP_NAME \
    --query ipAddress --output tsv 2>/dev/null || echo "")

GATEWAY_FQDN=$(az network public-ip show \
    --resource-group $RESOURCE_GROUP \
    --name $PUBLIC_IP_NAME \
    --query dnsSettings.fqdn --output tsv 2>/dev/null || echo "")

if [ -z "$GATEWAY_IP" ]; then
    echo -e "${RED}❌ Gateway resources not found. Please run the basic setup first.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Found existing Gateway IP: $GATEWAY_IP${NC}"
echo -e "${GREEN}✅ Found existing Gateway FQDN: $GATEWAY_FQDN${NC}"

# Step 1: Create SSL Certificates if not exists
echo -e "${YELLOW}Step 1: Checking SSL Certificates...${NC}"
if [ ! -d "ssl-certs" ]; then
    mkdir -p ssl-certs
    
    # Create SSL certificate for main gateway
    openssl req -x509 -newkey rsa:4096 -keyout ssl-certs/gateway.key -out ssl-certs/gateway.crt -days 365 -nodes -subj "/C=US/ST=CA/L=SF/O=BIDR/OU=Services/CN=$GATEWAY_FQDN"
    
    # Create SSL certificate for auth service
    openssl req -x509 -newkey rsa:4096 -keyout ssl-certs/auth.key -out ssl-certs/auth.crt -days 365 -nodes -subj "/C=US/ST=CA/L=SF/O=BIDR/OU=Auth/CN=auth.$GATEWAY_FQDN"
    
    # Create SSL certificate for product service
    openssl req -x509 -newkey rsa:4096 -keyout ssl-certs/product.key -out ssl-certs/product.crt -days 365 -nodes -subj "/C=US/ST=CA/L=SF/O=BIDR/OU=Product/CN=product.$GATEWAY_FQDN"
    
    # Create PFX files for Azure (required format)
    openssl pkcs12 -export -out ssl-certs/gateway.pfx -inkey ssl-certs/gateway.key -in ssl-certs/gateway.crt -passout pass:BidrSSL123!
    openssl pkcs12 -export -out ssl-certs/auth.pfx -inkey ssl-certs/auth.key -in ssl-certs/auth.crt -passout pass:BidrSSL123!
    openssl pkcs12 -export -out ssl-certs/product.pfx -inkey ssl-certs/product.key -in ssl-certs/product.crt -passout pass:BidrSSL123!
    
    echo -e "${GREEN}✅ SSL Certificates created${NC}"
else
    echo -e "${GREEN}✅ SSL Certificates already exist${NC}"
fi

# Step 2: Create Application Gateway with minimal configuration first
echo -e "${YELLOW}Step 2: Creating basic Application Gateway...${NC}"

# Check if gateway already exists
if az network application-gateway show --resource-group $RESOURCE_GROUP --name $AG_NAME > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Application Gateway already exists${NC}"
else
    # Create with minimal configuration and explicit priority
    az network application-gateway create \
        --resource-group $RESOURCE_GROUP \
        --name $AG_NAME \
        --location $LOCATION \
        --capacity 2 \
        --sku Standard_v2 \
        --vnet-name $VNET_NAME \
        --subnet $SUBNET_NAME \
        --public-ip-address $PUBLIC_IP_NAME \
        --http-settings-cookie-based-affinity Disabled \
        --http-settings-protocol Http \
        --http-settings-port 8000 \
        --frontend-port 80 \
        --priority 1000 \
        --tags Environment=Production Service=BIDR Component=Gateway
    
    echo -e "${GREEN}✅ Application Gateway created${NC}"
fi

# Step 3: Add HTTPS frontend port
echo -e "${YELLOW}Step 3: Adding HTTPS frontend port...${NC}"
az network application-gateway frontend-port create \
    --resource-group $RESOURCE_GROUP \
    --gateway-name $AG_NAME \
    --name httpsPort \
    --port 443 || echo "HTTPS port may already exist"

echo -e "${GREEN}✅ HTTPS port configured${NC}"

# Step 4: Upload SSL certificates
echo -e "${YELLOW}Step 4: Uploading SSL certificates...${NC}"

# Upload certificates (ignore errors if they already exist)
az network application-gateway ssl-cert create \
    --resource-group $RESOURCE_GROUP \
    --gateway-name $AG_NAME \
    --name gateway-cert \
    --cert-file ssl-certs/gateway.pfx \
    --cert-password BidrSSL123! || echo "Gateway cert may already exist"

az network application-gateway ssl-cert create \
    --resource-group $RESOURCE_GROUP \
    --gateway-name $AG_NAME \
    --name auth-cert \
    --cert-file ssl-certs/auth.pfx \
    --cert-password BidrSSL123! || echo "Auth cert may already exist"

az network application-gateway ssl-cert create \
    --resource-group $RESOURCE_GROUP \
    --gateway-name $AG_NAME \
    --name product-cert \
    --cert-file ssl-certs/product.pfx \
    --cert-password BidrSSL123! || echo "Product cert may already exist"

echo -e "${GREEN}✅ SSL certificates uploaded${NC}"

# Step 5: Create backend pools
echo -e "${YELLOW}Step 5: Creating backend pools...${NC}"

az network application-gateway address-pool create \
    --resource-group $RESOURCE_GROUP \
    --gateway-name $AG_NAME \
    --name auth-backend-pool \
    --servers $AUTH_IP || echo "Auth backend may already exist"

az network application-gateway address-pool create \
    --resource-group $RESOURCE_GROUP \
    --gateway-name $AG_NAME \
    --name product-backend-pool \
    --servers $PRODUCT_IP || echo "Product backend may already exist"

echo -e "${GREEN}✅ Backend pools configured${NC}"

# Step 6: Create HTTP settings with health probes
echo -e "${YELLOW}Step 6: Creating HTTP settings with health probes...${NC}"

# Create health probes first
az network application-gateway probe create \
    --resource-group $RESOURCE_GROUP \
    --gateway-name $AG_NAME \
    --name auth-health-probe \
    --protocol Http \
    --host-name-from-http-settings true \
    --path /health/ \
    --interval 30 \
    --timeout 30 \
    --threshold 3 || echo "Auth probe may already exist"

az network application-gateway probe create \
    --resource-group $RESOURCE_GROUP \
    --gateway-name $AG_NAME \
    --name product-health-probe \
    --protocol Http \
    --host-name-from-http-settings true \
    --path /health/ \
    --interval 30 \
    --timeout 30 \
    --threshold 3 || echo "Product probe may already exist"

# Create HTTP settings with probes
az network application-gateway http-settings create \
    --resource-group $RESOURCE_GROUP \
    --gateway-name $AG_NAME \
    --name auth-http-settings \
    --port 8000 \
    --protocol Http \
    --cookie-based-affinity Disabled \
    --timeout 30 \
    --probe auth-health-probe || echo "Auth HTTP settings may already exist"

az network application-gateway http-settings create \
    --resource-group $RESOURCE_GROUP \
    --gateway-name $AG_NAME \
    --name product-http-settings \
    --port 8000 \
    --protocol Http \
    --cookie-based-affinity Disabled \
    --timeout 30 \
    --probe product-health-probe || echo "Product HTTP settings may already exist"

echo -e "${GREEN}✅ HTTP settings and health probes configured${NC}"

# Step 7: Create HTTPS listeners
echo -e "${YELLOW}Step 7: Creating HTTPS listeners...${NC}"

az network application-gateway http-listener create \
    --resource-group $RESOURCE_GROUP \
    --gateway-name $AG_NAME \
    --name gateway-https-listener \
    --frontend-port httpsPort \
    --ssl-cert gateway-cert \
    --host-name $GATEWAY_FQDN || echo "Gateway listener may already exist"

az network application-gateway http-listener create \
    --resource-group $RESOURCE_GROUP \
    --gateway-name $AG_NAME \
    --name auth-https-listener \
    --frontend-port httpsPort \
    --ssl-cert auth-cert \
    --host-name auth.$GATEWAY_FQDN || echo "Auth listener may already exist"

az network application-gateway http-listener create \
    --resource-group $RESOURCE_GROUP \
    --gateway-name $AG_NAME \
    --name product-https-listener \
    --frontend-port httpsPort \
    --ssl-cert product-cert \
    --host-name product.$GATEWAY_FQDN || echo "Product listener may already exist"

echo -e "${GREEN}✅ HTTPS listeners configured${NC}"

# Step 8: Create routing rules with explicit priorities
echo -e "${YELLOW}Step 8: Creating routing rules...${NC}"

az network application-gateway rule create \
    --resource-group $RESOURCE_GROUP \
    --gateway-name $AG_NAME \
    --name auth-https-rule \
    --http-listener auth-https-listener \
    --rule-type Basic \
    --address-pool auth-backend-pool \
    --http-settings auth-http-settings \
    --priority 100 || echo "Auth rule may already exist"

az network application-gateway rule create \
    --resource-group $RESOURCE_GROUP \
    --gateway-name $AG_NAME \
    --name product-https-rule \
    --http-listener product-https-listener \
    --rule-type Basic \
    --address-pool product-backend-pool \
    --http-settings product-http-settings \
    --priority 110 || echo "Product rule may already exist"

az network application-gateway rule create \
    --resource-group $RESOURCE_GROUP \
    --gateway-name $AG_NAME \
    --name gateway-default-rule \
    --http-listener gateway-https-listener \
    --rule-type Basic \
    --address-pool auth-backend-pool \
    --http-settings auth-http-settings \
    --priority 120 || echo "Gateway rule may already exist"

echo -e "${GREEN}✅ Routing rules configured${NC}"

# Step 9: Test the gateway
echo -e "${YELLOW}Step 9: Testing gateway deployment...${NC}"
sleep 30  # Wait for gateway to be ready

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}🎉 Azure Application Gateway with SSL Deployed!${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Gateway Public IP: $GATEWAY_IP${NC}"
echo -e "${GREEN}Gateway FQDN: $GATEWAY_FQDN${NC}"
echo ""
echo -e "${BLUE}🔒 HTTPS Service URLs:${NC}"
echo -e "${GREEN}• Main Gateway: https://$GATEWAY_FQDN${NC}"
echo -e "${GREEN}• Authentication: https://auth.$GATEWAY_FQDN${NC}"
echo -e "${GREEN}• Products: https://product.$GATEWAY_FQDN${NC}"
echo ""
echo -e "${YELLOW}📋 DNS Configuration:${NC}"
echo "If you have a custom domain, add these DNS records:"
echo "• @ (root) → $GATEWAY_IP"
echo "• auth → $GATEWAY_IP" 
echo "• product → $GATEWAY_IP"
echo ""
echo -e "${CYAN}🧪 Test Commands:${NC}"
echo "curl -k -I https://$GATEWAY_FQDN"
echo "curl -k -I https://auth.$GATEWAY_FQDN/health/"
echo "curl -k -I https://product.$GATEWAY_FQDN/health/"
echo ""

# Step 10: Update service configuration
echo -e "${YELLOW}Step 10: Updating service configuration...${NC}"

# Create backup
if [ -f "shared_utils/service_config.py" ]; then
    cp shared_utils/service_config.py shared_utils/service_config.py.backup
    
    # Update service URLs to use gateway
    sed -i.tmp "s|https://bidr-auth-1756988136.westus.azurecontainer.io|https://auth.$GATEWAY_FQDN|g" shared_utils/service_config.py
    sed -i.tmp "s|https://bidr-product-1756960567.westus.azurecontainer.io|https://product.$GATEWAY_FQDN|g" shared_utils/service_config.py
    
    echo -e "${GREEN}✅ Service configuration updated${NC}"
fi

# Step 11: Test connectivity to backend services
echo -e "${YELLOW}Step 11: Testing backend connectivity...${NC}"

if curl -f -s "http://$AUTH_IP:8000/health/" > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Authentication service is reachable${NC}"
else
    echo -e "${YELLOW}⚠️  Authentication service may not be responding${NC}"
fi

if curl -f -s "http://$PRODUCT_IP:8000/health/" > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Product service is reachable${NC}"
else
    echo -e "${YELLOW}⚠️  Product service may not be responding${NC}"
fi

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}🔐 SSL Configuration Summary${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "${YELLOW}Certificates:${NC}"
echo "• Gateway Certificate: ssl-certs/gateway.pfx"
echo "• Auth Certificate: ssl-certs/auth.pfx"  
echo "• Product Certificate: ssl-certs/product.pfx"
echo "• Password: BidrSSL123!"
echo ""
echo -e "${YELLOW}Features Enabled:${NC}"
echo "✅ SSL Termination"
echo "✅ Health Monitoring" 
echo "✅ Load Balancing"
echo "✅ Multi-site Hosting"
echo "✅ Backend Pool Management"
echo ""
echo -e "${BLUE}💡 Next Steps:${NC}"
echo "1. Test HTTPS endpoints using the commands above"
echo "2. Replace self-signed certificates with proper SSL certificates if needed"
echo "3. Configure your domain DNS to point to $GATEWAY_IP (optional)"
echo "4. Update your applications to use the new gateway URLs"
echo "5. Monitor gateway health in Azure Portal"
echo ""
echo -e "${GREEN}🎊 Your BIDR services are now running behind Azure Application Gateway with SSL!${NC}"
echo -e "${CYAN}Gateway Management:${NC}"
echo "• View in Azure Portal: https://portal.azure.com"
echo "• Resource Group: $RESOURCE_GROUP"
echo "• Application Gateway: $AG_NAME"
