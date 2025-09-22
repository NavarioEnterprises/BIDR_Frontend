# HTTPS Setup Guide for BIDR Microservices

This guide shows you how to add HTTPS support to your BIDR microservices running on Azure Container Instances.

## 🔒 HTTPS Options for Azure Container Instances

### Option 1: Azure Application Gateway (Recommended for Production)
- ✅ **SSL Termination** at the gateway level
- ✅ **Custom Domain** support with SSL certificates
- ✅ **Load Balancing** capabilities
- ✅ **WAF (Web Application Firewall)** protection
- ✅ **Best Performance** and scalability

### Option 2: Nginx Reverse Proxy with Let's Encrypt
- ✅ **Free SSL certificates** from Let's Encrypt
- ✅ **Automatic certificate renewal**
- ✅ **Simple to set up**
- ⚠️ Requires container restart for certificate renewal

### Option 3: Cloudflare SSL Proxy (Quick & Easy)
- ✅ **Instant HTTPS** setup
- ✅ **Free SSL certificates**
- ✅ **CDN benefits**
- ✅ **DDoS protection**
- ⚠️ Traffic goes through Cloudflare

## 🚀 Quick Implementation: Option 2 - Nginx + Let's Encrypt

I'll show you how to implement Nginx with Let's Encrypt for your services.

### Step 1: Create SSL Proxy Container

First, let's create an Nginx SSL proxy that handles HTTPS for all your services.

### Step 2: Domain Configuration

You'll need to:
1. **Purchase a domain** (e.g., `bidr-services.com`)
2. **Point DNS records** to your container IPs:
   - `auth.bidr-services.com` → `40.118.207.135` (your auth service IP)
   - `products.bidr-services.com` → `20.253.249.204` (your product service IP)
   - `api.bidr-services.com` → SSL proxy container IP

## 🔧 Implementation Steps

### Method 1: Simple HTTPS Redirect (Quickest)

Update your service configurations to use HTTPS URLs:

```bash
# Update your service URLs in shared_utils/service_config.py
AUTH_SERVICE_URL=https://bidr-auth-1756988136.westus.azurecontainer.io:443
PRODUCT_SERVICE_URL=https://bidr-product-1756960567.westus.azurecontainer.io:443
```

### Method 2: Azure Application Gateway (Recommended)

Create an Azure Application Gateway to handle SSL termination:

```bash
#!/bin/bash
# Create Application Gateway with SSL

RESOURCE_GROUP="bidr-simple-rg"
LOCATION="westus"
AG_NAME="bidr-app-gateway"
VNET_NAME="bidr-vnet"
SUBNET_NAME="gateway-subnet"
PUBLIC_IP_NAME="bidr-gateway-ip"

# Create virtual network
az network vnet create \
    --resource-group $RESOURCE_GROUP \
    --name $VNET_NAME \
    --location $LOCATION \
    --address-prefix 10.0.0.0/16 \
    --subnet-name $SUBNET_NAME \
    --subnet-prefix 10.0.1.0/24

# Create public IP
az network public-ip create \
    --resource-group $RESOURCE_GROUP \
    --name $PUBLIC_IP_NAME \
    --location $LOCATION \
    --allocation-method Static \
    --sku Standard

# Create Application Gateway
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
    --frontend-port 80 \
    --http-settings-port 8000 \
    --http-settings-protocol Http

# Add HTTPS frontend port
az network application-gateway frontend-port create \
    --resource-group $RESOURCE_GROUP \
    --gateway-name $AG_NAME \
    --name httpsPort \
    --port 443

# Add backend pools for your services
az network application-gateway address-pool create \
    --resource-group $RESOURCE_GROUP \
    --gateway-name $AG_NAME \
    --name auth-backend \
    --servers 40.118.207.135

az network application-gateway address-pool create \
    --resource-group $RESOURCE_GROUP \
    --gateway-name $AG_NAME \
    --name product-backend \
    --servers 20.253.249.204
```

### Method 3: Nginx SSL Proxy Container

Create a dedicated SSL proxy container:

```dockerfile
# Create ssl-proxy/Dockerfile
FROM nginx:alpine

# Install certbot for Let's Encrypt
RUN apk add --no-cache certbot certbot-nginx openssl

# Copy nginx configuration
COPY nginx.conf /etc/nginx/nginx.conf
COPY ssl-proxy.conf /etc/nginx/conf.d/default.conf

# Create directories for SSL certificates
RUN mkdir -p /etc/letsencrypt/live
RUN mkdir -p /var/www/certbot

# Expose ports
EXPOSE 80 443

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
```

```nginx
# Create ssl-proxy/ssl-proxy.conf
server {
    listen 80;
    server_name auth.yourdomain.com;
    
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }
    
    location / {
        return 301 https://$server_name$request_uri;
    }
}

server {
    listen 443 ssl http2;
    server_name auth.yourdomain.com;
    
    ssl_certificate /etc/letsencrypt/live/auth.yourdomain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/auth.yourdomain.com/privkey.pem;
    
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE+AESGCM:ECDHE+AES256:ECDHE+AES128:!aNULL:!SHA1:!AESCCM;
    ssl_prefer_server_ciphers on;
    
    location / {
        proxy_pass http://40.118.207.135:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;
    }
}

server {
    listen 80;
    server_name products.yourdomain.com;
    
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }
    
    location / {
        return 301 https://$server_name$request_uri;
    }
}

server {
    listen 443 ssl http2;
    server_name products.yourdomain.com;
    
    ssl_certificate /etc/letsencrypt/live/products.yourdomain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/products.yourdomain.com/privkey.pem;
    
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE+AESGCM:ECDHE+AES256:ECDHE+AES128:!aNULL:!SHA1:!AESCCM;
    ssl_prefer_server_ciphers on;
    
    location / {
        proxy_pass http://20.253.249.204:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;
    }
}
```

## 🔄 Method 4: Cloudflare Proxy (Easiest)

1. **Sign up for Cloudflare** (free plan available)
2. **Add your domain** to Cloudflare
3. **Create DNS records**:
   - `auth` → `40.118.207.135`
   - `products` → `20.253.249.204`
4. **Enable "Proxy" (orange cloud)** for SSL termination
5. **Set SSL/TLS mode** to "Flexible" or "Full"

## 📝 Update Service Configuration for HTTPS

Update your `shared_utils/service_config.py`:

```python
# Service URLs with HTTPS
SERVICES = {
    'authentication': {
        'url': config('AUTH_SERVICE_URL', default='https://auth.yourdomain.com'),
        'api_prefix': '/api/v1',
        'health_endpoint': '/health/'
    },
    'product_management': {
        'url': config('PRODUCT_SERVICE_URL', default='https://products.yourdomain.com'),
        'api_prefix': '/api/v1',
        'health_endpoint': '/health/'
    },
    # ... other services
}
```

## 🚀 Deploy HTTPS-enabled Deployment Script

Create an updated deployment script:

```bash
#!/bin/bash
# deploy-https-services.sh

set -e

# Configuration
RESOURCE_GROUP="bidr-simple-rg"
CONTAINER_REGISTRY="bidrsimpleregistry"
DOMAIN="yourdomain.com"  # Replace with your actual domain

# Deploy services with HTTPS configuration
echo "🔒 Deploying BIDR services with HTTPS support..."

# Update environment variables for HTTPS
HTTPS_ENV_VARS="\
    SECRET_KEY=\"$(openssl rand -base64 32)\" \
    DEBUG=False \
    ALLOWED_HOSTS=\"auth.$DOMAIN,products.$DOMAIN,*\" \
    DJANGO_SETTINGS_MODULE=authentication_service.settings \
    JWT_SECRET_KEY=\"$(openssl rand -base64 32)\" \
    CORS_ALLOW_ALL_ORIGINS=True \
    SECURE_SSL_REDIRECT=True \
    SECURE_PROXY_SSL_HEADER=\"HTTP_X_FORWARDED_PROTO,https\" \
    AUTH_SERVICE_URL=https://auth.$DOMAIN \
    PRODUCT_SERVICE_URL=https://products.$DOMAIN"

# Deploy authentication service
echo "Deploying authentication service..."
az container create \
    --resource-group $RESOURCE_GROUP \
    --name bidr-auth-https \
    --image $CONTAINER_REGISTRY.azurecr.io/bidr-authentication-service:latest \
    --dns-name-label auth-$(date +%s) \
    --ports 8000 443 \
    --os-type Linux \
    --environment-variables $HTTPS_ENV_VARS \
    --cpu 1 \
    --memory 1.5

# Deploy product service
echo "Deploying product management service..."
az container create \
    --resource-group $RESOURCE_GROUP \
    --name bidr-product-https \
    --image $CONTAINER_REGISTRY.azurecr.io/bidr-product-service:latest \
    --dns-name-label products-$(date +%s) \
    --ports 8000 443 \
    --os-type Linux \
    --environment-variables $HTTPS_ENV_VARS \
    --cpu 1 \
    --memory 1.5

echo "✅ HTTPS-enabled services deployed!"
```

## 🔧 Update Django Settings for HTTPS

Add to your Django `settings.py`:

```python
# HTTPS Configuration
SECURE_SSL_REDIRECT = config('SECURE_SSL_REDIRECT', default=False, cast=bool)
SECURE_PROXY_SSL_HEADER = ('HTTP_X_FORWARDED_PROTO', 'https')
SECURE_BROWSER_XSS_FILTER = True
SECURE_CONTENT_TYPE_NOSNIFF = True
SECURE_HSTS_MAX_AGE = 31536000  # 1 year
SECURE_HSTS_INCLUDE_SUBDOMAINS = True
SECURE_HSTS_PRELOAD = True

# Session cookies
SESSION_COOKIE_SECURE = True
CSRF_COOKIE_SECURE = True

# CORS for HTTPS
CORS_ALLOWED_ORIGINS = [
    "https://auth.yourdomain.com",
    "https://products.yourdomain.com",
]

# Trust proxy headers
USE_TZ = True
SECURE_REFERRER_POLICY = 'strict-origin-when-cross-origin'
```

## 🧪 Testing HTTPS

```bash
# Test HTTPS endpoints
curl -I https://auth.yourdomain.com/health/
curl -I https://products.yourdomain.com/health/

# Test service-to-service HTTPS communication
curl -X POST https://auth.yourdomain.com/api/v1/internal/health/ \
  -H "Content-Type: application/json" \
  -H "X-Service-Token: your-service-token" \
  -d '{"service": "product_management"}'
```

## 📋 Next Steps

1. **Choose your HTTPS method** (Cloudflare is easiest, Application Gateway is most robust)
2. **Purchase a domain** if you don't have one
3. **Update DNS records** to point to your container IPs
4. **Deploy HTTPS-enabled containers** with updated environment variables
5. **Test all endpoints** to ensure HTTPS is working
6. **Update your frontend applications** to use HTTPS URLs

## 🔍 Monitoring HTTPS

- **SSL Certificate expiration** monitoring
- **HTTPS redirect** testing
- **Security headers** verification
- **Performance impact** assessment

Choose the method that best fits your needs. Cloudflare is the quickest to set up, while Azure Application Gateway offers the most enterprise features.
