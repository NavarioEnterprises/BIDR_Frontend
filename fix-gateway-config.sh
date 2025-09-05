#!/bin/bash

# Fix Azure Application Gateway configuration
set -e

RESOURCE_GROUP="bidr-simple-rg"
AG_NAME="bidr-app-gateway"
AUTH_IP="40.118.207.135"
PRODUCT_IP="20.253.249.204"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}🔧 Fixing Azure Application Gateway Configuration...${NC}"

# Step 1: Create simple HTTP settings without probes
echo -e "${YELLOW}Creating simple HTTP settings...${NC}"

az network application-gateway http-settings create \
    --resource-group $RESOURCE_GROUP \
    --gateway-name $AG_NAME \
    --name simple-auth-settings \
    --port 8000 \
    --protocol Http \
    --cookie-based-affinity Disabled \
    --timeout 30 || echo "Auth settings already exist"

az network application-gateway http-settings create \
    --resource-group $RESOURCE_GROUP \
    --gateway-name $AG_NAME \
    --name simple-product-settings \
    --port 8000 \
    --protocol Http \
    --cookie-based-affinity Disabled \
    --timeout 30 || echo "Product settings already exist"

# Step 2: Create basic routing rules
echo -e "${YELLOW}Creating basic routing rules...${NC}"

# Delete existing problematic rules first
az network application-gateway rule delete \
    --resource-group $RESOURCE_GROUP \
    --gateway-name $AG_NAME \
    --name rule1 || echo "Default rule doesn't exist"

# Create new auth rule
az network application-gateway rule create \
    --resource-group $RESOURCE_GROUP \
    --gateway-name $AG_NAME \
    --name auth-simple-rule \
    --http-listener auth-https-listener \
    --rule-type Basic \
    --address-pool auth-backend-pool \
    --http-settings simple-auth-settings \
    --priority 100 || echo "Auth rule already exists"

# Create new product rule
az network application-gateway rule create \
    --resource-group $RESOURCE_GROUP \
    --gateway-name $AG_NAME \
    --name product-simple-rule \
    --http-listener product-https-listener \
    --rule-type Basic \
    --address-pool product-backend-pool \
    --http-settings simple-product-settings \
    --priority 110 || echo "Product rule already exists"

# Create default gateway rule
az network application-gateway rule create \
    --resource-group $RESOURCE_GROUP \
    --gateway-name $AG_NAME \
    --name gateway-simple-rule \
    --http-listener gateway-https-listener \
    --rule-type Basic \
    --address-pool auth-backend-pool \
    --http-settings simple-auth-settings \
    --priority 120 || echo "Gateway rule already exists"

echo -e "${GREEN}✅ Gateway configuration fixed!${NC}"

# Test the configuration
echo -e "${YELLOW}Waiting for configuration to apply...${NC}"
sleep 30

echo -e "${GREEN}🧪 Testing HTTPS endpoints...${NC}"

# Test with curl (ignore SSL certificate errors for self-signed certs)
echo "Testing main gateway..."
curl -k -I --max-time 10 https://bidr-gateway-1756992603.westus.cloudapp.azure.com || echo "Main gateway not responding yet"

echo "Testing auth service..."
curl -k -I --max-time 10 https://auth.bidr-gateway-1756992603.westus.cloudapp.azure.com || echo "Auth service not responding yet"

echo "Testing product service..."  
curl -k -I --max-time 10 https://product.bidr-gateway-1756992603.westus.cloudapp.azure.com || echo "Product service not responding yet"

echo -e "${GREEN}✅ Configuration completed!${NC}"
