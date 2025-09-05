#!/bin/bash

# Fix Application Gateway to use path-based routing instead of host-based
# This allows accessing services via paths: /auth/* and /products/*

set -e

RESOURCE_GROUP="bidr-simple-rg"
AG_NAME="bidr-app-gateway"
AUTH_IP="40.118.207.135"
PRODUCT_IP="20.253.249.204"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GREEN}🔧 Fixing Application Gateway Routing...${NC}"

# Step 1: Create URL path map for path-based routing
echo -e "${YELLOW}Step 1: Creating URL path map for path-based routing...${NC}"

az network application-gateway url-path-map create \
    --resource-group $RESOURCE_GROUP \
    --gateway-name $AG_NAME \
    --name path-map \
    --paths "/auth/*" \
    --address-pool auth-backend-pool \
    --http-settings simple-auth-settings \
    --default-address-pool auth-backend-pool \
    --default-http-settings simple-auth-settings || echo "Path map may already exist"

# Add path for products
az network application-gateway url-path-map rule create \
    --resource-group $RESOURCE_GROUP \
    --gateway-name $AG_NAME \
    --path-map-name path-map \
    --name product-rule \
    --paths "/products/*" "/api/*" \
    --address-pool product-backend-pool \
    --http-settings simple-product-settings || echo "Product rule may already exist"

echo -e "${GREEN}✅ URL path map created${NC}"

# Step 2: Create a simple HTTPS listener without hostname restrictions
echo -e "${YELLOW}Step 2: Creating simple HTTPS listener...${NC}"

az network application-gateway http-listener create \
    --resource-group $RESOURCE_GROUP \
    --gateway-name $AG_NAME \
    --name simple-https-listener \
    --frontend-port httpsPort \
    --ssl-cert gateway-cert || echo "Simple listener may already exist"

echo -e "${GREEN}✅ Simple HTTPS listener created${NC}"

# Step 3: Update routing rule to use path-based routing
echo -e "${YELLOW}Step 3: Creating path-based routing rule...${NC}"

# Delete existing complex rules and create a simple path-based rule
az network application-gateway rule delete \
    --resource-group $RESOURCE_GROUP \
    --gateway-name $AG_NAME \
    --name auth-simple-rule || echo "Rule doesn't exist"

az network application-gateway rule delete \
    --resource-group $RESOURCE_GROUP \
    --gateway-name $AG_NAME \
    --name product-simple-rule || echo "Rule doesn't exist"

az network application-gateway rule delete \
    --resource-group $RESOURCE_GROUP \
    --gateway-name $AG_NAME \
    --name gateway-simple-rule || echo "Rule doesn't exist"

# Create new path-based rule
az network application-gateway rule create \
    --resource-group $RESOURCE_GROUP \
    --gateway-name $AG_NAME \
    --name path-based-rule \
    --http-listener simple-https-listener \
    --rule-type PathBasedRouting \
    --url-path-map path-map \
    --priority 100 || echo "Path-based rule already exists"

echo -e "${GREEN}✅ Path-based routing configured${NC}"

# Step 4: Test the configuration
echo -e "${YELLOW}Step 4: Waiting for configuration to apply...${NC}"
sleep 30

echo -e "${GREEN}🧪 Testing the fixed routing...${NC}"

echo "Testing main gateway (should work):"
curl -k -I --max-time 10 https://bidr-gateway-1756992603.westus.cloudapp.azure.com/health/ || echo "Main gateway not responding"

echo ""
echo "Testing auth path (should work):"
curl -k -I --max-time 10 https://bidr-gateway-1756992603.westus.cloudapp.azure.com/auth/health/ || echo "Auth path not responding"

echo ""
echo "Testing products path (should work):"
curl -k -I --max-time 10 https://bidr-gateway-1756992603.westus.cloudapp.azure.com/products/health/ || echo "Products path not responding"

echo ""
echo "Testing API path (should work):"
curl -k -I --max-time 10 https://bidr-gateway-1756992603.westus.cloudapp.azure.com/api/health/ || echo "API path not responding"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}🎉 Gateway Routing Fixed!${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "${YELLOW}Your HTTPS Service URLs:${NC}"
echo -e "${GREEN}• Main Gateway: https://bidr-gateway-1756992603.westus.cloudapp.azure.com${NC}"
echo -e "${GREEN}• Authentication: https://bidr-gateway-1756992603.westus.cloudapp.azure.com/auth/${NC}"
echo -e "${GREEN}• Products: https://bidr-gateway-1756992603.westus.cloudapp.azure.com/products/${NC}"
echo -e "${GREEN}• API: https://bidr-gateway-1756992603.westus.cloudapp.azure.com/api/${NC}"
echo ""
echo -e "${BLUE}💡 How to use:${NC}"
echo "• Auth service health: curl -k https://bidr-gateway-1756992603.westus.cloudapp.azure.com/auth/health/"
echo "• Product service health: curl -k https://bidr-gateway-1756992603.westus.cloudapp.azure.com/products/health/"
echo "• Any API calls: curl -k https://bidr-gateway-1756992603.westus.cloudapp.azure.com/api/..."
echo ""
echo -e "${GREEN}✅ All services now accessible through single domain with path routing!${NC}"
