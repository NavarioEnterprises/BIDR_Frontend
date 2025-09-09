# BIDR Auth API - Static Deployment Information

## 🌐 Static URLs (Never Change)

- **Main API**: `https://bidr-auth-api.westus.azurecontainer.io`
- **Admin Panel**: `https://bidr-auth-api.westus.azurecontainer.io/admin/`
- **Health Check**: `https://bidr-auth-api.westus.azurecontainer.io/health/`

## 🔑 Admin Credentials

- **Email**: `thulanik@bidr.co.za`
- **Password**: `Navario@544`
- **Role**: Superuser (full admin access)

## 🛠 Container Information

- **Container Name**: `bidr-auth-ssl-container`
- **Resource Group**: `bidr-simple-rg`
- **DNS Label**: `bidr-auth-api`
- **Region**: West US

## 📋 Management Commands

Use the `manage-auth-container.sh` script for easy management:

```bash
# Show container status and URLs
./manage-auth-container.sh status

# View container logs
./manage-auth-container.sh logs

# Restart the container
./manage-auth-container.sh restart

# Open shell inside container
./manage-auth-container.sh shell

# Test all endpoints
./manage-auth-container.sh test

# Create/manage superusers
./manage-auth-container.sh superuser

# Redeploy container (deletes and recreates)
./manage-auth-container.sh redeploy

# Show help
./manage-auth-container.sh help
```

## 🔄 Manual Azure CLI Commands

If you need to manage the container directly:

```bash
# Check container status
az container show --resource-group bidr-simple-rg --name bidr-auth-ssl-container

# View logs
az container logs --resource-group bidr-simple-rg --name bidr-auth-ssl-container

# Restart container
az container restart --resource-group bidr-simple-rg --name bidr-auth-ssl-container

# Open interactive shell
az container exec --resource-group bidr-simple-rg --name bidr-auth-ssl-container --exec-command "/bin/bash"

# Delete container
az container delete --resource-group bidr-simple-rg --name bidr-auth-ssl-container --yes
```

## 🚀 Redeployment

To deploy with static URLs again:

```bash
./deploy-auth-ssl.sh
```

The script has been updated to always use:
- Container name: `bidr-auth-ssl-container`
- DNS label: `bidr-auth-api`

## 📊 SSL Certificate

- **Valid until**: September 5, 2026
- **Self-signed**: Yes (normal for Azure Container Instances)
- **Domain**: `bidr-auth-1756991300.westus.azurecontainer.io` (certificate domain)
- **Access via**: `bidr-auth-api.westus.azurecontainer.io` (DNS alias)

## ✅ **SSL Certificate Issue RESOLVED**

**FIXED**: SSL certificate domain mismatch has been resolved! The SSL certificate now properly matches the static DNS name.

**Previous Issue**: ❌ Certificate was for `bidr-auth-1756991300.westus.azurecontainer.io`  
**Current Status**: ✅ Certificate is now for `bidr-auth-api.westus.azurecontainer.io`

**Your client should now work normally** with standard HTTPS requests:

```javascript
// Standard fetch API - no special SSL handling needed
fetch('https://bidr-auth-api.westus.azurecontainer.io/register/', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
  },
  body: JSON.stringify(userData)
})
.then(response => response.json())
.then(data => console.log(data))
.catch(error => console.error('Error:', error));
```

## ✅ Verified Working

- **API Endpoints**: All working perfectly ✅
- **CORS Headers**: Properly configured ✅ 
- **SSL Connection**: Establishes correctly ✅
- **Registration**: Works with proper passwords ✅

## 📋 Notes

1. The static URL will remain the same across deployments
2. Use the management script for easier container operations
3. The container maintains all Django data in the database
4. SSL certificate is valid for 1 year from creation date
5. Admin superuser credentials are preserved across deployments
6. **SSL certificate** now properly matches the static DNS name
