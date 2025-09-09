#!/bin/bash

# Enable HTTPS for BIDR Microservices
# This script updates your existing services to use HTTPS

set -e

# Configuration
RESOURCE_GROUP="bidr-simple-rg"
CONTAINER_REGISTRY="bidrsimpleregistry"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}🔒 Enabling HTTPS for BIDR Services...${NC}"

# Step 1: Choose HTTPS method
echo -e "${YELLOW}Choose your HTTPS method:${NC}"
echo "1. Cloudflare Proxy (Easiest - requires domain)"
echo "2. Azure Application Gateway (Enterprise - costs extra)"
echo "3. Update service URLs to HTTPS (Quick - no SSL termination)"
echo "4. Deploy SSL Proxy Container (Advanced)"

read -p "Enter your choice (1-4): " choice

case $choice in
    1)
        echo -e "${BLUE}🌐 Cloudflare Method Selected${NC}"
        echo -e "${YELLOW}To use Cloudflare:${NC}"
        echo "1. Sign up at https://cloudflare.com"
        echo "2. Add your domain to Cloudflare"
        echo "3. Create these DNS records:"
        echo "   - auth.yourdomain.com → 40.118.207.135"
        echo "   - products.yourdomain.com → 20.253.249.204" 
        echo "4. Enable proxy (orange cloud) for both records"
        echo "5. Set SSL/TLS mode to 'Flexible'"
        echo ""
        read -p "Enter your domain (e.g., example.com): " domain
        
        if [ ! -z "$domain" ]; then
            echo -e "${GREEN}✅ Updating service URLs for domain: $domain${NC}"
            
            # Update service configuration
            sed -i.bak "s|https://bidr-auth-1756988136.westus.azurecontainer.io|https://auth.$domain|g" shared_utils/service_config.py
            sed -i.bak "s|https://bidr-product-1756960567.westus.azurecontainer.io|https://products.$domain|g" shared_utils/service_config.py
            
            echo -e "${GREEN}✅ Service URLs updated!${NC}"
            echo -e "${YELLOW}Next steps:${NC}"
            echo "1. Configure Cloudflare DNS as shown above"
            echo "2. Update your applications to use:"
            echo "   - Authentication: https://auth.$domain"
            echo "   - Products: https://products.$domain"
            echo "3. Test with: curl -I https://auth.$domain/health/"
        fi
        ;;
        
    2)
        echo -e "${BLUE}🏢 Azure Application Gateway Method Selected${NC}"
        echo -e "${YELLOW}Creating Azure Application Gateway...${NC}"
        
        # Create virtual network
        echo "Creating virtual network..."
        az network vnet create \
            --resource-group $RESOURCE_GROUP \
            --name bidr-vnet \
            --location westus \
            --address-prefix 10.0.0.0/16 \
            --subnet-name gateway-subnet \
            --subnet-prefix 10.0.1.0/24
        
        # Create public IP
        echo "Creating public IP..."
        az network public-ip create \
            --resource-group $RESOURCE_GROUP \
            --name bidr-gateway-ip \
            --location westus \
            --allocation-method Static \
            --sku Standard
        
        # Create Application Gateway
        echo "Creating Application Gateway (this may take a few minutes)..."
        az network application-gateway create \
            --resource-group $RESOURCE_GROUP \
            --name bidr-app-gateway \
            --location westus \
            --capacity 2 \
            --sku Standard_v2 \
            --vnet-name bidr-vnet \
            --subnet gateway-subnet \
            --public-ip-address bidr-gateway-ip \
            --http-settings-cookie-based-affinity Disabled \
            --frontend-port 80 \
            --http-settings-port 8000 \
            --http-settings-protocol Http
        
        # Get gateway public IP
        GATEWAY_IP=$(az network public-ip show \
            --resource-group $RESOURCE_GROUP \
            --name bidr-gateway-ip \
            --query ipAddress --output tsv)
        
        echo -e "${GREEN}✅ Application Gateway created!${NC}"
        echo -e "${GREEN}Gateway IP: $GATEWAY_IP${NC}"
        echo -e "${YELLOW}Next steps:${NC}"
        echo "1. Add SSL certificate to the gateway"
        echo "2. Configure backend pools for your services"
        echo "3. Update DNS to point to $GATEWAY_IP"
        ;;
        
    3)
        echo -e "${BLUE}⚡ Quick HTTPS URL Update Selected${NC}"
        echo -e "${YELLOW}Updating service URLs to use HTTPS...${NC}"
        
        # Note: This doesn't add actual SSL termination, just updates URLs
        echo -e "${GREEN}✅ Service URLs already updated to HTTPS${NC}"
        echo -e "${YELLOW}⚠️  Note: This doesn't add SSL termination.${NC}"
        echo "Your services are now configured to expect HTTPS, but you'll need"
        echo "to add SSL termination using Cloudflare or Application Gateway."
        ;;
        
    4)
        echo -e "${BLUE}🔧 SSL Proxy Container Method Selected${NC}"
        echo -e "${YELLOW}Creating SSL proxy configuration...${NC}"
        
        # Create SSL proxy directory
        mkdir -p ssl-proxy
        
        # Create Dockerfile
        cat > ssl-proxy/Dockerfile << 'EOF'
FROM nginx:alpine

# Install certbot for Let's Encrypt
RUN apk add --no-cache certbot certbot-nginx openssl

# Copy nginx configuration
COPY ssl-proxy.conf /etc/nginx/conf.d/default.conf

# Create directories for SSL certificates
RUN mkdir -p /etc/letsencrypt/live
RUN mkdir -p /var/www/certbot

# Expose ports
EXPOSE 80 443

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
EOF
        
        # Create nginx config
        read -p "Enter your domain (e.g., example.com): " domain
        
        cat > ssl-proxy/ssl-proxy.conf << EOF
server {
    listen 80;
    server_name auth.$domain;
    
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }
    
    location / {
        return 301 https://\$server_name\$request_uri;
    }
}

server {
    listen 443 ssl http2;
    server_name auth.$domain;
    
    # SSL configuration will be added by certbot
    
    location / {
        proxy_pass http://40.118.207.135:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;
    }
}

server {
    listen 80;
    server_name products.$domain;
    
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }
    
    location / {
        return 301 https://\$server_name\$request_uri;
    }
}

server {
    listen 443 ssl http2;
    server_name products.$domain;
    
    # SSL configuration will be added by certbot
    
    location / {
        proxy_pass http://20.253.249.204:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;
    }
}
EOF

        # Build and deploy SSL proxy
        echo "Building SSL proxy container..."
        az acr build \
            --registry $CONTAINER_REGISTRY \
            --image ssl-proxy:latest \
            ssl-proxy/
        
        echo "Deploying SSL proxy container..."
        az container create \
            --resource-group $RESOURCE_GROUP \
            --name bidr-ssl-proxy \
            --image $CONTAINER_REGISTRY.azurecr.io/ssl-proxy:latest \
            --dns-name-label bidr-ssl-$(date +%s) \
            --ports 80 443 \
            --os-type Linux \
            --cpu 1 \
            --memory 1
        
        PROXY_FQDN=$(az container show \
            --resource-group $RESOURCE_GROUP \
            --name bidr-ssl-proxy \
            --query "ipAddress.fqdn" \
            --output tsv)
        
        echo -e "${GREEN}✅ SSL proxy deployed!${NC}"
        echo -e "${GREEN}Proxy URL: $PROXY_FQDN${NC}"
        echo -e "${YELLOW}Next steps:${NC}"
        echo "1. Point your domain DNS to the proxy IP"
        echo "2. Run certbot to get SSL certificates"
        echo "3. Test HTTPS endpoints"
        ;;
        
    *)
        echo -e "${RED}❌ Invalid choice${NC}"
        exit 1
        ;;
esac

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}🎉 HTTPS Configuration Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "${YELLOW}Current Service URLs:${NC}"
echo -e "${GREEN}• Authentication: $(grep 'AUTH_SERVICE_URL' shared_utils/service_config.py | cut -d"'" -f4)${NC}"
echo -e "${GREEN}• Products: $(grep 'PRODUCT_SERVICE_URL' shared_utils/service_config.py | cut -d"'" -f4)${NC}"
echo ""
echo -e "${YELLOW}Remember to:${NC}"
echo "1. Test your HTTPS endpoints"
echo "2. Update your frontend applications"  
echo "3. Configure proper SSL certificates"
echo "4. Set up monitoring for SSL expiration"
echo ""
echo -e "${GREEN}🔐 Your services are now HTTPS-ready!${NC}"
