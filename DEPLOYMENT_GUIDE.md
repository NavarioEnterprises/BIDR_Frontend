# BIDR Deployment Guide

This guide explains how to deploy your local code changes to the Kubernetes cluster using the provided deployment tools.

## 🛠️ Deployment Tools

### 1. Interactive Python Script (Recommended)
**File:** `deploy_to_k8s.py`
- Interactive menu-driven interface
- Service selection with status display
- Automatic backup creation
- Error handling and rollback
- Prerequisites checking

### 2. Quick Shell Script
**File:** `quick_deploy.sh`
- Command-line deployment
- Fast execution for single services
- Suitable for automation and CI/CD

## 🚀 Getting Started

### Prerequisites
- `kubectl` configured and connected to your cluster
- `docker` installed (for future container builds)
- Python 3.6+ (for the Python script)

### Method 1: Interactive Python Script

```bash
# Navigate to project directory
cd "/Users/thulanimoyo/MEGA downloads/new downloads/BIDR_Backend"

# Run the interactive deployment manager
python deploy_to_k8s.py
```

**Features:**
- ✅ Prerequisites checking
- ✅ Service status display
- ✅ Interactive menu
- ✅ Automatic backups
- ✅ Progress tracking
- ✅ Error handling

**Menu Options:**
```
0. UPDATE ALL SERVICES
1. auth-service
2. product-management-service  
3. reviews-service
4. chat-service
5. payment-service
6. notifications-service
7. transactions-service
8. resolution-service
9. nginx-proxy
99. Exit
```

### Method 2: Quick Shell Script

```bash
# Deploy all services
./quick_deploy.sh all

# Deploy specific service
./quick_deploy.sh products
./quick_deploy.sh reviews
./quick_deploy.sh nginx

# See available options
./quick_deploy.sh
```

## 📦 Service Mapping

| Short Name | Service Name | Local Directory | Description |
|------------|--------------|-----------------|-------------|
| `auth` | auth-service | authentication_service | User authentication |
| `products` | product-management-service | product_management_service | Product management |
| `reviews` | reviews-service | reviews_and_ratings | Reviews and ratings |
| `chat` | chat-service | chat_service | Real-time messaging |
| `payments` | payment-service | payment_service | Payment processing |
| `notifications` | notifications-service | notifications_service | Push notifications |
| `transactions` | transactions-service | transactions_service | Transaction management |
| `resolution` | resolution-service | resolution_service | Dispute resolution |
| `nginx` | nginx-proxy | nginx | Reverse proxy configuration |

## 🔄 Deployment Process

### What Happens When You Deploy:

1. **Backup Creation** - Current deployment is backed up
2. **Configuration Apply** - Updated deployment files are applied
3. **Service Restart** - Deployment is restarted to pick up changes
4. **Rollout Wait** - Script waits for successful rollout
5. **Status Check** - Deployment status is verified

### For Django Services (products, reviews, auth, etc.):
- Applies updated deployment YAML with your local code structure
- Restarts the service to rebuild with new inline code
- Verifies the service comes up healthy

### For Nginx:
- Backs up current configuration
- Applies new nginx configuration with URL prefixes
- Restarts nginx proxy
- Tests endpoints

## 📂 File Structure

```
BIDR_Backend/
├── deploy_to_k8s.py              # Interactive deployment script
├── quick_deploy.sh               # Quick command-line deployment
├── DEPLOYMENT_GUIDE.md          # This guide
├── backups/                     # Automatic backups
│   └── deployment-TIMESTAMP/
├── nginx/                       # Nginx configuration
│   ├── nginx-k8s.conf
│   ├── backup-nginx-config.sh
│   └── apply-django-url-prefixes.sh
└── k8s/overlays/uat/           # Kubernetes deployment files
    ├── product-django-real.yaml
    ├── reviews-service-real.yaml
    └── ...
```

## 🧪 Testing Your Deployment

After deployment, test your services:

### Service URLs:
- **Auth:** http://20.241.197.87/auth/admin/
- **Products:** http://20.241.197.87/products/admin/
- **Reviews:** http://20.241.197.87/reviews/admin/
- **Health Checks:** http://20.241.197.87/{service}/health/

### Quick Status Check:
```bash
# Check all pods
kubectl get pods -n bidr

# Check specific service
kubectl get deployment product-management-service -n bidr
kubectl logs deployment/product-management-service -n bidr --tail=20
```

## 🔧 Troubleshooting

### Common Issues:

1. **Service Won't Start**
   ```bash
   # Check pod logs
   kubectl describe pod <pod-name> -n bidr
   kubectl logs <pod-name> -n bidr
   ```

2. **Deployment Stuck**
   ```bash
   # Force restart
   kubectl rollout restart deployment <service-name> -n bidr
   kubectl rollout status deployment <service-name> -n bidr
   ```

3. **Configuration Issues**
   ```bash
   # Restore from backup
   kubectl apply -f backups/deployment-TIMESTAMP/service-deployment.yaml
   ```

### Rollback Process:
```bash
# Find backup files
ls -la backups/

# Apply backup
kubectl apply -f backups/deployment-TIMESTAMP/service-deployment.yaml

# Restart service
kubectl rollout restart deployment <service-name> -n bidr
```

## 🚨 Important Notes

### Before Deploying:
- ✅ Ensure your local changes are tested
- ✅ Check that kubectl is connected to the correct cluster
- ✅ Verify you have the necessary permissions

### During Deployment:
- 🔄 Deployments may take 2-5 minutes to complete
- 📊 Monitor the output for any errors
- ⚠️ Don't interrupt the process once started

### After Deployment:
- 🧪 Test your endpoints to ensure they work
- 📋 Check service logs for any issues
- 💾 Keep backup files for potential rollbacks

## 📋 Examples

### Example 1: Deploy Products Service
```bash
# Interactive method
python deploy_to_k8s.py
# Select option 2 (products)

# Quick method
./quick_deploy.sh products
```

### Example 2: Deploy All Services
```bash
# Interactive method
python deploy_to_k8s.py
# Select option 0 (all services)

# Quick method
./quick_deploy.sh all
```

### Example 3: Update Nginx Only
```bash
# Interactive method
python deploy_to_k8s.py
# Select nginx option

# Quick method
./quick_deploy.sh nginx
```

## 🔒 Security Considerations

- Scripts create backups automatically for safety
- All operations are logged for audit purposes
- Deployments are applied to the UAT environment
- Always test changes before deploying to production

## 🆘 Getting Help

If you encounter issues:

1. **Check the logs** in the deployment output
2. **Use kubectl** to investigate pod status
3. **Restore from backup** if needed
4. **Check this guide** for troubleshooting steps

## 📈 Advanced Usage

### Custom Deployment Files:
You can modify the deployment YAML files in `k8s/overlays/uat/` to customize your deployments.

### Environment Variables:
Set these environment variables for custom behavior:
```bash
export BIDR_NAMESPACE="bidr"           # Default namespace
export BIDR_TIMEOUT="300s"            # Rollout timeout
```

### CI/CD Integration:
Use the quick_deploy.sh script in your CI/CD pipelines:
```bash
./quick_deploy.sh products    # Deploy products service
```

This deployment system provides a robust, safe, and efficient way to deploy your local code changes to the Kubernetes cluster!