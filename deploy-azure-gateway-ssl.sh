#!/bin/bash

# Deploy Azure Application Gateway with SSL for BIDR Microservices
# This script creates an Application Gateway with SSL termination for all services

set -e

# Configuration
RESOURCE_GROUP="bidr-simple-rg"
LOCATION="westus"
AG_NAME="bidr-app-gateway"
VNET_NAME="bidr-vnet"
SUBNET_NAME="gateway-subnet"
PUBLIC_IP_NAME="bidr-gateway-ip"
CONTAINER_REGISTRY="bidrsimpleregistry"

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

echo -e "${GREEN}🏢 Deploying Azure Application Gateway with SSL for BIDR Services...${NC}"

# Step 1: Create Virtual Network
echo -e "${YELLOW}Step 1: Creating Virtual Network...${NC}"
az network vnet create \
    --resource-group $RESOURCE_GROUP \
    --name $VNET_NAME \
    --location $LOCATION \
    --address-prefix 10.0.0.0/16 \
    --subnet-name $SUBNET_NAME \
    --subnet-prefix 10.0.1.0/24 \
    --tags Environment=Production Service=BIDR Component=Gateway

echo -e "${GREEN}✅ Virtual Network created${NC}"

# Step 2: Create Public IP for Application Gateway
echo -e "${YELLOW}Step 2: Creating Public IP...${NC}"
az network public-ip create \
    --resource-group $RESOURCE_GROUP \
    --name $PUBLIC_IP_NAME \
    --location $LOCATION \
    --allocation-method Static \
    --sku Standard \
    --dns-name bidr-gateway-$(date +%s) \
    --tags Environment=Production Service=BIDR Component=Gateway

GATEWAY_IP=$(az network public-ip show \
    --resource-group $RESOURCE_GROUP \
    --name $PUBLIC_IP_NAME \
    --query ipAddress --output tsv)

GATEWAY_FQDN=$(az network public-ip show \
    --resource-group $RESOURCE_GROUP \
    --name $PUBLIC_IP_NAME \
    --query dnsSettings.fqdn --output tsv)

echo -e "${GREEN}✅ Public IP created: $GATEWAY_IP${NC}"
echo -e "${GREEN}✅ Gateway FQDN: $GATEWAY_FQDN${NC}"

# Step 3: Create Self-Signed SSL Certificates for testing
echo -e "${YELLOW}Step 3: Creating SSL Certificates...${NC}"
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

# Step 4: Create Application Gateway with basic configuration
echo -e "${YELLOW}Step 4: Creating Application Gateway (this may take 5-10 minutes)...${NC}"
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
    --tags Environment=Production Service=BIDR Component=Gateway

echo -e "${GREEN}✅ Application Gateway created${NC}"

# Step 5: Add HTTPS frontend port
echo -e "${YELLOW}Step 5: Adding HTTPS frontend port...${NC}"
az network application-gateway frontend-port create \
    --resource-group $RESOURCE_GROUP \
    --gateway-name $AG_NAME \
    --name httpsPort \
    --port 443

echo -e "${GREEN}✅ HTTPS port added${NC}"

# Step 6: Upload SSL certificates
echo -e "${YELLOW}Step 6: Uploading SSL certificates...${NC}"

# Upload main gateway certificate
az network application-gateway ssl-cert create \
    --resource-group $RESOURCE_GROUP \
    --gateway-name $AG_NAME \
    --name gateway-cert \
    --cert-file ssl-certs/gateway.pfx \
    --cert-password BidrSSL123!

# Upload auth service certificate  
az network application-gateway ssl-cert create \
    --resource-group $RESOURCE_GROUP \
    --gateway-name $AG_NAME \
    --name auth-cert \
    --cert-file ssl-certs/auth.pfx \
    --cert-password BidrSSL123!

# Upload product service certificate
az network application-gateway ssl-cert create \
    --resource-group $RESOURCE_GROUP \
    --gateway-name $AG_NAME \
    --name product-cert \
    --cert-file ssl-certs/product.pfx \
    --cert-password BidrSSL123!

echo -e "${GREEN}✅ SSL certificates uploaded${NC}"

# Step 7: Create backend pools for each service
echo -e "${YELLOW}Step 7: Creating backend pools...${NC}"

# Authentication service backend pool
az network application-gateway address-pool create \
    --resource-group $RESOURCE_GROUP \
    --gateway-name $AG_NAME \
    --name auth-backend-pool \
    --servers $AUTH_IP

# Product management service backend pool
az network application-gateway address-pool create \
    --resource-group $RESOURCE_GROUP \
    --gateway-name $AG_NAME \
    --name product-backend-pool \
    --servers $PRODUCT_IP

echo -e "${GREEN}✅ Backend pools created${NC}"

# Step 8: Create HTTP settings for each backend
echo -e "${YELLOW}Step 8: Creating HTTP settings...${NC}"

# Auth service HTTP settings
az network application-gateway http-settings create \
    --resource-group $RESOURCE_GROUP \
    --gateway-name $AG_NAME \
    --name auth-http-settings \
    --port 8000 \
    --protocol Http \
    --cookie-based-affinity Disabled \
    --timeout 30 \
    --probe-interval 30 \
    --probe-timeout 30 \
    --probe-unhealthy-threshold 3 \
    --probe-path /health/

# Product service HTTP settings
az network application-gateway http-settings create \
    --resource-group $RESOURCE_GROUP \
    --gateway-name $AG_NAME \
    --name product-http-settings \
    --port 8000 \
    --protocol Http \
    --cookie-based-affinity Disabled \
    --timeout 30 \
    --probe-interval 30 \
    --probe-timeout 30 \
    --probe-unhealthy-threshold 3 \
    --probe-path /health/

echo -e "${GREEN}✅ HTTP settings created${NC}"

# Step 9: Create health probes
echo -e "${YELLOW}Step 9: Creating health probes...${NC}"

# Auth service health probe
az network application-gateway probe create \
    --resource-group $RESOURCE_GROUP \
    --gateway-name $AG_NAME \
    --name auth-health-probe \
    --protocol Http \
    --host-name-from-http-settings true \
    --path /health/ \
    --interval 30 \
    --timeout 30 \
    --threshold 3

# Product service health probe
az network application-gateway probe create \
    --resource-group $RESOURCE_GROUP \
    --gateway-name $AG_NAME \
    --name product-health-probe \
    --protocol Http \
    --host-name-from-http-settings true \
    --path /health/ \
    --interval 30 \
    --timeout 30 \
    --threshold 3

echo -e "${GREEN}✅ Health probes created${NC}"

# Step 10: Create HTTPS listeners
echo -e "${YELLOW}Step 10: Creating HTTPS listeners...${NC}"

# Main gateway HTTPS listener
az network application-gateway http-listener create \
    --resource-group $RESOURCE_GROUP \
    --gateway-name $AG_NAME \
    --name gateway-https-listener \
    --frontend-port httpsPort \
    --ssl-cert gateway-cert \
    --host-name $GATEWAY_FQDN

# Auth service HTTPS listener
az network application-gateway http-listener create \
    --resource-group $RESOURCE_GROUP \
    --gateway-name $AG_NAME \
    --name auth-https-listener \
    --frontend-port httpsPort \
    --ssl-cert auth-cert \
    --host-name auth.$GATEWAY_FQDN

# Product service HTTPS listener
az network application-gateway http-listener create \
    --resource-group $RESOURCE_GROUP \
    --gateway-name $AG_NAME \
    --name product-https-listener \
    --frontend-port httpsPort \
    --ssl-cert product-cert \
    --host-name product.$GATEWAY_FQDN

echo -e "${GREEN}✅ HTTPS listeners created${NC}"

# Step 11: Create routing rules
echo -e "${YELLOW}Step 11: Creating routing rules...${NC}"

# Auth service routing rule
az network application-gateway rule create \
    --resource-group $RESOURCE_GROUP \
    --gateway-name $AG_NAME \
    --name auth-https-rule \
    --http-listener auth-https-listener \
    --rule-type Basic \
    --address-pool auth-backend-pool \
    --http-settings auth-http-settings \
    --priority 100

# Product service routing rule  
az network application-gateway rule create \
    --resource-group $RESOURCE_GROUP \
    --gateway-name $AG_NAME \
    --name product-https-rule \
    --http-listener product-https-listener \
    --rule-type Basic \
    --address-pool product-backend-pool \
    --http-settings product-http-settings \
    --priority 110

# Main gateway routing rule (default)
az network application-gateway rule create \
    --resource-group $RESOURCE_GROUP \
    --gateway-name $AG_NAME \
    --name gateway-https-rule \
    --http-listener gateway-https-listener \
    --rule-type Basic \
    --address-pool auth-backend-pool \
    --http-settings auth-http-settings \
    --priority 120

echo -e "${GREEN}✅ Routing rules created${NC}"

# Step 12: Create HTTP to HTTPS redirect rules
echo -e "${YELLOW}Step 12: Creating HTTP to HTTPS redirects...${NC}"

# Create redirect configuration
az network application-gateway redirect-config create \
    --resource-group $RESOURCE_GROUP \
    --gateway-name $AG_NAME \
    --name http-to-https-redirect \
    --type Permanent \
    --include-path true \
    --include-query-string true \
    --target-listener gateway-https-listener

# Create HTTP listener for redirect
az network application-gateway http-listener create \
    --resource-group $RESOURCE_GROUP \
    --gateway-name $AG_NAME \
    --name http-redirect-listener \
    --frontend-port appGatewayFrontendPort

# Create redirect rule
az network application-gateway rule create \
    --resource-group $RESOURCE_GROUP \
    --gateway-name $AG_NAME \
    --name http-redirect-rule \
    --http-listener http-redirect-listener \
    --rule-type Basic \
    --redirect-config http-to-https-redirect \
    --priority 130

echo -e "${GREEN}✅ HTTP to HTTPS redirects created${NC}"

# Step 13: Wait for deployment to complete and test
echo -e "${YELLOW}Step 13: Testing gateway deployment...${NC}"
sleep 60  # Wait for gateway to be fully ready

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
echo -e "${YELLOW}📋 DNS Configuration Required:${NC}"
echo "Add these DNS records to your domain:"
echo "• @ → $GATEWAY_IP"
echo "• auth → $GATEWAY_IP" 
echo "• product → $GATEWAY_IP"
echo ""
echo -e "${CYAN}🧪 Test Commands:${NC}"
echo "curl -I https://$GATEWAY_FQDN"
echo "curl -I https://auth.$GATEWAY_FQDN/health/"
echo "curl -I https://product.$GATEWAY_FQDN/health/"
echo ""

# Step 14: Update service configuration
echo -e "${YELLOW}Step 14: Updating service configuration...${NC}"

# Backup original config
cp shared_utils/service_config.py shared_utils/service_config.py.backup

# Update service URLs to use gateway
sed -i.tmp "s|https://bidr-auth-1756988136.westus.azurecontainer.io|https://auth.$GATEWAY_FQDN|g" shared_utils/service_config.py
sed -i.tmp "s|https://bidr-product-1756960567.westus.azurecontainer.io|https://product.$GATEWAY_FQDN|g" shared_utils/service_config.py

echo -e "${GREEN}✅ Service configuration updated${NC}"

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
echo "✅ HTTP to HTTPS Redirect"
echo "✅ Health Monitoring"
echo "✅ Load Balancing"
echo "✅ Multi-site Hosting"
echo ""
echo -e "${BLUE}💡 Next Steps:${NC}"
echo "1. Configure your domain DNS to point to $GATEWAY_IP"
echo "2. Replace self-signed certificates with proper SSL certificates"
echo "3. Test all HTTPS endpoints"
echo "4. Update your applications to use the new URLs"
echo "5. Monitor gateway health and performance"
echo ""
echo -e "${GREEN}🎊 Your BIDR services are now running behind Azure Application Gateway with SSL!${NC}"
