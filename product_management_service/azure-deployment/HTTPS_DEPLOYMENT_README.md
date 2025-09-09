# BIDR HTTPS Deployment Scripts

This directory now contains updated deployment scripts that work with the new **Azure Application Gateway with HTTPS support**.

## 🔒 HTTPS Setup Complete

Your authentication service is now accessible via:
- **HTTPS**: `https://api.bidr.co.za` (secure, trusted certificate)
- **HTTP Redirect**: `http://api.bidr.co.za` → automatically redirects to HTTPS

## 📁 Updated Scripts

### 1. **deploy-auth-service-with-gateway.sh** ✨ NEW
**Use this for new deployments with HTTPS support**
```bash
./deploy-auth-service-with-gateway.sh
```
- Deploys container without public DNS
- Automatically updates Application Gateway backend pool
- Tests HTTPS connectivity
- Full SSL termination support

### 2. **update-auth-service.sh** ✅ UPDATED
**Use this for quick updates of existing auth service**
```bash
./update-auth-service.sh
```
- Rebuilds and redeploys the container
- Updates Application Gateway with new container IP
- Maintains HTTPS connectivity
- Faster than full deployment

### 3. **bidr-deploy-manager.py** ✅ UPDATED
**Interactive deployment manager with HTTPS support**
```bash
python3 bidr-deploy-manager.py
```
- Shows HTTPS status in service list
- Updated authentication service configuration
- Uses new HTTPS deployment scripts

## 🏗️ Architecture

```
Internet → https://api.bidr.co.za
    ↓
Azure Application Gateway (SSL Termination)
    ↓
Container Instance (Internal IP:8000)
```

## ⚡ Quick Commands

### Deploy Auth Service (HTTPS)
```bash
./deploy-auth-service-with-gateway.sh
```

### Update Auth Service
```bash
./update-auth-service.sh
```

### Interactive Manager
```bash
python3 bidr-deploy-manager.py
```

### Test HTTPS
```bash
curl https://api.bidr.co.za/health/
curl https://api.bidr.co.za/api/
```

## 📋 What Changed

### Before (Old Scripts)
- ❌ HTTP only (port 8000)
- ❌ Direct container DNS names
- ❌ No SSL termination
- ❌ Required port numbers in URLs

### After (New Scripts)
- ✅ HTTPS with valid SSL certificate
- ✅ Application Gateway integration
- ✅ Standard ports (80/443)
- ✅ Automatic HTTP → HTTPS redirects
- ✅ Production-ready SSL termination

## 🔧 Configuration Details

### Container Configuration
- **Resource Group**: `bidr-simple-rg`
- **Container Registry**: `bidrsimpleregistry`
- **Container Name**: `bidr-auth-service`
- **Internal Port**: `8000`
- **No Public DNS**: Container is private

### Application Gateway
- **Name**: `bidr-appgw`
- **Public IP**: `20.245.166.78`
- **Backend Pool**: `appGatewayBackendPool`
- **SSL Certificate**: Let's Encrypt production certificate
- **Domain**: `api.bidr.co.za`

## 🚨 Important Notes

1. **DNS**: Ensure `api.bidr.co.za` points to `20.245.166.78` (Application Gateway IP)
2. **SSL Certificate**: Automatically managed by Application Gateway
3. **Container IPs**: Scripts automatically update backend pool when container IP changes
4. **Health Checks**: Scripts test both HTTPS and direct container connectivity

## 🎯 Migration Guide

If you have existing deployments using the old scripts:

1. **Delete old containers** with public DNS names
2. **Use new scripts** for HTTPS deployment
3. **Update DNS** to point to Application Gateway IP
4. **Test HTTPS** endpoints

## 🔍 Troubleshooting

### Check Container Status
```bash
az container show --resource-group bidr-simple-rg --name bidr-auth-service
```

### Check Container Logs
```bash
az container logs --resource-group bidr-simple-rg --name bidr-auth-service
```

### Check Application Gateway
```bash
az network application-gateway show --resource-group bidr-simple-rg --name bidr-appgw
```

### Test Direct Container
```bash
# Get container IP
CONTAINER_IP=$(az container show --resource-group bidr-simple-rg --name bidr-auth-service --query "ipAddress.ip" --output tsv)

# Test direct connection
curl http://$CONTAINER_IP:8000/health/
```

## 🎉 Benefits

- ✅ **Production-ready HTTPS** with trusted certificates
- ✅ **Standard ports** (no :8000 in URLs)
- ✅ **Automatic SSL renewal** via Let's Encrypt
- ✅ **Load balancing** ready for multiple containers
- ✅ **Security headers** and modern SSL configuration
- ✅ **HTTP to HTTPS redirects** for better UX

Your BIDR authentication service is now enterprise-ready with full HTTPS support! 🚀
