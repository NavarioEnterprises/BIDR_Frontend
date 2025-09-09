# BIDR Nginx Configuration Management

This directory contains nginx configuration files and scripts for managing the BIDR nginx proxy in Kubernetes.

## Files

- **nginx.conf** - Original nginx configuration template
- **nginx-k8s.conf** - Kubernetes-specific nginx configuration with proper service names and admin routing
- **update-nginx-config.sh** - Script to update nginx configuration in the running cluster
- **backup-nginx-config.sh** - Script to backup current nginx configuration before making changes

## Usage

### 1. Backup Current Configuration (Recommended)

Before making any changes, backup the current configuration:

```bash
./backup-nginx-config.sh
```

This will create timestamped backups in the `backups/` directory.

### 2. Update Nginx Configuration

To apply the new nginx configuration to the cluster:

```bash
./update-nginx-config.sh
```

This script will:
- Create/update a ConfigMap with the new configuration
- Update the nginx-proxy deployment to use the new ConfigMap
- Restart the nginx pods
- Test the endpoints to verify they're working

### 3. Verify Changes

After updating, you can verify the configuration:

```bash
# View current nginx configuration
kubectl exec -n bidr deployment/nginx-proxy -- cat /etc/nginx/conf.d/default.conf

# Check nginx logs
kubectl logs -n bidr deployment/nginx-proxy

# Test endpoints
curl http://20.241.197.87/auth/admin/
curl http://20.241.197.87/products/admin/
curl http://20.241.197.87/reviews/admin/
```

## Key Features of the Configuration

### Service Routes
- Each service is accessible at `/<service-name>/`
- Admin interfaces are at `/<service-name>/admin/`
- API endpoints are at both `/api/v1/<service>/ and `/<service>/api/`

### Admin Routing
Each service has its own admin interface that properly handles redirects:
- Auth: `/auth/admin/`
- Products: `/products/admin/`
- Reviews: `/reviews/admin/`
- Chat: `/chat/admin/`
- Payments: `/payments/admin/`
- Notifications: `/notifications/admin/`
- Transactions: `/transactions/admin/`
- Resolution: `/resolution/admin/`

### Path Rewriting
Services that expect to run at root (/) have path rewriting enabled:
- `/products/` → `/` (for product service)
- `/reviews/` → `/` (for reviews service)
- etc.

## Troubleshooting

### If something goes wrong

1. Check pod status:
```bash
kubectl get pods -n bidr -l app=nginx-proxy
```

2. View logs:
```bash
kubectl logs -n bidr deployment/nginx-proxy
```

3. Restore from backup:
```bash
# Find your backup files
ls backups/

# Apply the backed up ConfigMap
kubectl apply -f backups/nginx-configmap-TIMESTAMP.yaml

# Restart nginx
kubectl rollout restart deployment nginx-proxy -n bidr
```

## Making Configuration Changes

1. Edit `nginx-k8s.conf` with your changes
2. Run `./backup-nginx-config.sh` to backup current config
3. Run `./update-nginx-config.sh` to apply changes
4. Test your endpoints to ensure everything works

## Service Endpoints Reference

| Service | Main URL | Admin URL | Health Check |
|---------|----------|-----------|--------------|
| Auth | http://20.241.197.87/auth/ | http://20.241.197.87/auth/admin/ | http://20.241.197.87/auth/health/ |
| Products | http://20.241.197.87/products/ | http://20.241.197.87/products/admin/ | http://20.241.197.87/products/health/ |
| Reviews | http://20.241.197.87/reviews/ | http://20.241.197.87/reviews/admin/ | http://20.241.197.87/reviews/health/ |
| Chat | http://20.241.197.87/chat/ | http://20.241.197.87/chat/admin/ | http://20.241.197.87/chat/health/ |
| Payments | http://20.241.197.87/payments/ | http://20.241.197.87/payments/admin/ | http://20.241.197.87/payments/health/ |
| Notifications | http://20.241.197.87/notifications/ | http://20.241.197.87/notifications/admin/ | http://20.241.197.87/notifications/health/ |
| Transactions | http://20.241.197.87/transactions/ | http://20.241.197.87/transactions/admin/ | http://20.241.197.87/transactions/health/ |
| Resolution | http://20.241.197.87/resolution/ | http://20.241.197.87/resolution/admin/ | http://20.241.197.87/resolution/health/ |