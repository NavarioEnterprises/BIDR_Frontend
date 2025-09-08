# BIDR Enhanced Deployment Template

This directory contains an enhanced deployment template system for BIDR microservices with comprehensive logging and management capabilities.

## Files Overview

### 1. `deploy-service-template-enhanced.sh`
The master template that can be customized for any BIDR service deployment.

### 2. `deploy-example-product-service.sh`
An example implementation showing how to use the template for the Product Service.

### 3. `bidr-deploy-manager.py`
Interactive deployment manager with advanced logging capabilities (Option 5).

## How to Use the Template

### Step 1: Copy the Template
```bash
cp deploy-service-template-enhanced.sh deploy-your-service.sh
```

### Step 2: Customize Configuration Variables
Edit the following variables in your new script:

```bash
# Replace these placeholders with your service-specific values:
CONTAINER_NAME="bidr-{SERVICE_NAME}-service"        # e.g., "bidr-auth-service"
IMAGE_NAME="bidr-{SERVICE_NAME}-service"            # e.g., "bidr-auth-service"  
SERVICE_NAME="{SERVICE_NAME_DISPLAY}"               # e.g., "Authentication Service"
SERVICE_PORT={PORT_NUMBER}                          # e.g., 8001
SERVICE_DIR="$PROJECT_ROOT/{SERVICE_DIRECTORY}"     # e.g., "$PROJECT_ROOT/authentication_service"

# Update Django settings module:
DJANGO_SETTINGS_MODULE={SERVICE_DIRECTORY}.settings # e.g., authentication_service.settings
```

### Step 3: Customize Service Endpoints (Optional)
Update the service endpoints section to reflect your service's specific API routes:

```bash
echo -e "${BLUE}🔗 Service Endpoints:${NC}"
echo -e "${BLUE}• Main API: http://$CONTAINER_FQDN:$SERVICE_PORT/api/${NC}"
echo -e "${BLUE}• Admin Panel: http://$CONTAINER_FQDN:$SERVICE_PORT/admin/${NC}"
echo -e "${BLUE}• Health Check: http://$CONTAINER_FQDN:$SERVICE_PORT/health/${NC}"
```

## Template Substitution Examples

### Authentication Service
```bash
CONTAINER_NAME="bidr-auth-service"
IMAGE_NAME="bidr-auth-service"
SERVICE_NAME="Authentication Service"
SERVICE_PORT=8001
SERVICE_DIR="$PROJECT_ROOT/authentication_service"
DJANGO_SETTINGS_MODULE=authentication_service.settings
```

### Product Service
```bash
CONTAINER_NAME="bidr-product-service"
IMAGE_NAME="bidr-product-service"
SERVICE_NAME="Product Service"
SERVICE_PORT=8002
SERVICE_DIR="$PROJECT_ROOT/product_management_service"
DJANGO_SETTINGS_MODULE=product_management_service.settings
```

### Notifications Service
```bash
CONTAINER_NAME="bidr-notifications-service"
IMAGE_NAME="bidr-notifications-service"
SERVICE_NAME="Notifications Service"
SERVICE_PORT=8005
SERVICE_DIR="$PROJECT_ROOT/notifications_service"
DJANGO_SETTINGS_MODULE=notifications_service.settings
```

## Enhanced Features

### 🚀 Deployment Features
- ✅ Automated Docker image building and pushing
- ✅ Container registry credential management
- ✅ Existing container cleanup
- ✅ Public IP and DNS assignment
- ✅ Environment variable configuration
- ✅ Service health testing
- ✅ Colored output for better visibility

### 📊 Logging & Monitoring
- ✅ Real-time log streaming
- ✅ Historical logs viewing (last hour, 30 minutes, custom range)
- ✅ Error/warning log filtering with color coding
- ✅ Container status monitoring
- ✅ Interactive deployment manager integration

### 🔧 Management Commands
After deployment, use these commands for ongoing management:

```bash
# View recent logs
az container logs --resource-group bidr-simple-rg --name your-container-name

# Stream real-time logs
az container logs --resource-group bidr-simple-rg --name your-container-name --follow

# Check container status
az container show --resource-group bidr-simple-rg --name your-container-name

# Restart container
az container restart --resource-group bidr-simple-rg --name your-container-name

# Delete container
az container delete --resource-group bidr-simple-rg --name your-container-name --yes

# Interactive management interface
python bidr-deploy-manager.py  # Select Option 5: View Service Logs
```

## Advanced Logging Interface

The enhanced template integrates with the interactive deployment manager (`bidr-deploy-manager.py`) which provides:

### Option 5: View Service Logs
1. **Real-time Logs**: Stream live logs from any service
2. **Recent Logs**: View logs from the last hour or 30 minutes
3. **Custom Time Range**: View logs from a specific time period
4. **Error Logs Only**: Filter for errors, warnings, and exceptions with color coding
5. **Container Status**: Check deployment status and resource usage

### Color-Coded Error Filtering
- 🔴 **ERROR** and **CRITICAL** logs in red
- 🟡 **WARNING** logs in yellow
- 🔵 **Exception** logs in blue
- ⚪ **INFO** and **DEBUG** logs in standard color

## Environment Variables

The template automatically sets these environment variables:

```bash
SECRET_KEY="$(openssl rand -base64 32)"        # Random Django secret key
DEBUG=False                                     # Production mode
ALLOWED_HOSTS="*"                              # Allow all hosts
DJANGO_SETTINGS_MODULE=service_name.settings   # Service-specific settings
JWT_SECRET_KEY="$(openssl rand -base64 32)"    # Random JWT secret
CORS_ALLOW_ALL_ORIGINS=True                    # Enable CORS
```

## Resource Configuration

Each deployment uses:
- **CPU**: 1 vCPU
- **Memory**: 1.5 GB
- **Restart Policy**: OnFailure
- **IP Address**: Public (with DNS label)
- **OS**: Linux

## Service Health Testing

The template includes automatic health checks:
1. Tries `/health/` endpoint first
2. Falls back to root `/` endpoint
3. Provides appropriate feedback for startup delays

## Best Practices

1. **Always test deployment** with a single service first
2. **Monitor logs** during initial deployment using the interactive manager
3. **Use descriptive service names** for easy identification
4. **Keep port numbers consistent** across environments
5. **Regularly check container status** for resource usage

## Troubleshooting

### Common Issues
- **502 Bad Gateway**: Check if container has public IP assigned
- **Service not responding**: Allow time for service startup (Django takes 10-30 seconds)
- **OTP/SMS issues**: Verify service-to-service communication and environment variables
- **Database connection**: Ensure database services are deployed and accessible

### Debug Steps
1. Check container logs: `python bidr-deploy-manager.py` → Option 5 → Option 1
2. Verify container status: Option 5 → Option 4
3. Test HTTP endpoints manually using curl
4. Check Azure Application Gateway backend pools
5. Verify environment variables in container settings

## Next Steps

After deploying your service:
1. Test all API endpoints
2. Verify service-to-service communication
3. Update Application Gateway routing if needed
4. Monitor logs for any startup issues
5. Consider setting up automated health checks

---

**Happy Deploying! 🚀**

For issues or questions, refer to the conversation history or check container logs using the enhanced logging interface.
