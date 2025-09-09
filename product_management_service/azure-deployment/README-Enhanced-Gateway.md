# Enhanced Product Management Service Deployment

## Overview

The enhanced deployment script `update-product-service-with-gateway.sh` provides flexible deployment options for the BIDR Product Management Service with optional Application Gateway (HTTPS) integration.

## Features

### 🚀 Three Deployment Options:

1. **Update container only** - Rebuilds and redeploys the container without changing gateway configuration
2. **Update container + link to Application Gateway** - Rebuilds container and configures HTTPS access
3. **Link to Application Gateway only** - Links existing container to HTTPS without rebuilding

### 🔒 HTTPS Integration

- Automatic Application Gateway backend pool updates
- SSL termination via Azure Application Gateway
- Custom domain: `https://products-management.bidr.co.za`
- Health check verification
- Comprehensive endpoint testing

## Usage

### Interactive Mode

```bash
bash update-product-service-with-gateway.sh
```

The script will present three options:

```
📋 Update Options:
1. Update container only (keep existing configuration)
2. Update container + link to Application Gateway (HTTPS)
3. Link to Application Gateway only (no container rebuild)
```

### Via Deployment Manager

```bash
python bidr-deploy-manager.py
```

Select "Deploy/Update Individual Service" → "Product Management Service"

## Option Details

### Option 1: Container Update Only
- Rebuilds Docker image with latest code
- Redeploys container with new version
- Preserves existing networking configuration
- Best for: Code updates without infrastructure changes

### Option 2: Full Update with HTTPS
- Rebuilds Docker image
- Redeploys container
- Updates Application Gateway backend pool
- Configures HTTPS access
- Tests all endpoints
- Best for: New deployments or major updates

### Option 3: Gateway Link Only
- Uses existing running container
- Updates Application Gateway configuration only
- Links container to HTTPS domain
- No container rebuild
- Best for: Infrastructure changes or gateway reconfigurations

## Service Endpoints

### HTTPS Endpoints (Recommended)
- **Main Service**: https://products-management.bidr.co.za/
- **Health Check**: https://products-management.bidr.co.za/health/
- **Admin Panel**: https://products-management.bidr.co.za/admin/
- **API Documentation**: https://products-management.bidr.co.za/swagger/

### Direct Container Access
- **Health Check**: http://[container-fqdn]:8000/health/
- **API Endpoints**: http://[container-fqdn]:8000/api/products/

## Configuration

The script automatically configures:

- **Resource Group**: `bidr-simple-rg`
- **Container Registry**: `bidrsimpleregistry`
- **Application Gateway**: `bidr-appgw`
- **Backend Pool**: `productsBackendPool`
- **HTTPS Domain**: `products-management.bidr.co.za`

## Benefits

### 🔒 Security
- SSL/TLS termination at gateway level
- Encrypted traffic to end users
- Centralized certificate management

### 🚀 Performance
- Load balancing capabilities
- CDN-ready architecture
- Improved caching options

### 🛠 Flexibility
- Multiple update strategies
- No-downtime linking option
- Easy rollback capabilities

### 📊 Monitoring
- Gateway-level metrics
- Health check automation
- Comprehensive logging

## Troubleshooting

### Gateway Link Failed
```bash
# Check current container status
az container show --resource-group bidr-simple-rg --name bidr-product-service

# Verify Application Gateway configuration
az network application-gateway show --resource-group bidr-simple-rg --name bidr-appgw
```

### HTTPS Not Accessible
1. Verify DNS resolution: `nslookup products-management.bidr.co.za`
2. Check backend pool IP: Ensure it matches container IP
3. Test container directly: `curl http://[container-ip]:8000/health/`

### Container Not Found (Option 3)
- Deploy the container first using option 1 or 2
- Ensure container is running: `az container show --resource-group bidr-simple-rg --name bidr-product-service`

## Management Commands

```bash
# View logs
az container logs --resource-group bidr-simple-rg --name bidr-product-service

# Check container status
az container show --resource-group bidr-simple-rg --name bidr-product-service

# Restart container
az container restart --resource-group bidr-simple-rg --name bidr-product-service

# Update gateway only (after container changes)
bash update-product-service-with-gateway.sh  # Select option 3
```

## Integration with Deployment Manager

The enhanced script is automatically integrated with `bidr-deploy-manager.py`:

- Product Management Service now shows 🔒HTTPS badge
- Public URL displayed as `https://products-management.bidr.co.za`
- Update script automatically uses enhanced version

## Next Steps

- Consider implementing similar enhancements for other services
- Set up monitoring and alerting for HTTPS endpoints
- Configure custom error pages via Application Gateway
- Implement API rate limiting through gateway policies
