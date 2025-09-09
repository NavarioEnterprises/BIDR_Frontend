# BIDR Services Access Guide

## 🌐 Public Access Methods

### Option 1: Direct Azure Load Balancer
- **Base URL**: `http://108.141.192.60/`
- **Status**: ✅ Working
- **Access**: All BIDR services accessible via sub-paths

### Option 2: Ngrok Tunnel (Recommended for External Access)
- **Public URL**: `https://f8ce28e3ad69.ngrok-free.app/`
- **Status**: ✅ Working
- **Benefits**: HTTPS, public access, bypasses firewalls
- **Access**: All BIDR services accessible via sub-paths

## 🔐 Service URLs and Credentials

### Django Application Services
| Service | Admin Panel | Health Check | Swagger API | Username/Email | Password |
|---------|-------------|--------------|-------------|----------------|----------|
| Auth Service | `/admin/` | `/health/` | `/swagger/` | admin@bidr.com | AdminPassword123! |
| Chat Service | `/chat/admin/` | `/chat/health/` | `/chat/swagger/` | admin | AdminPassword123! |
| Payment Service | `/payments/admin/` | `/payments/health/` | `/payments/swagger/` | admin | AdminPassword123! |
| Notifications Service | `/notifications/admin/` | `/notifications/health/` | `/notifications/swagger/` | admin | AdminPassword123! |
| Product Management | `/products/admin/` | `/products/health/` | `/products/swagger/` | admin | AdminPassword123! |
| Transactions Service | `/transactions/admin/` | `/transactions/health/` | `/transactions/swagger/` | admin | AdminPassword123! |
| Reviews Service | `/reviews/admin/` | `/reviews/health/` | `/reviews/swagger/` | admin | AdminPassword123! |
| Resolution Service | `/resolution/admin/` | `/resolution/health/` | `/resolution/swagger/` | admin | AdminPassword123! |

### Monitoring Services
| Service | Direct Access Method | Credentials |
|---------|---------------------|-------------|
| Grafana | `kubectl port-forward -n bidr-uat service/grafana-service 3000:3000` | admin:bidr-admin123 |
| Prometheus | `kubectl port-forward -n bidr-uat service/prometheus-service 9090:9090` | No auth required |

## 🛠️ Access Examples

### Access via Direct IP
```bash
# Health check
curl http://108.141.192.60/health

# Auth service admin
open http://108.141.192.60/admin/

# Chat service API
curl http://108.141.192.60/chat/swagger/
```

### Access via Ngrok (Public)
```bash
# Health check
curl https://f8ce28e3ad69.ngrok-free.app/health

# Auth service admin
open https://f8ce28e3ad69.ngrok-free.app/admin/

# Any service API
curl https://f8ce28e3ad69.ngrok-free.app/products/swagger/
```

### Access Monitoring Services
```bash
# Grafana (via port-forward)
kubectl port-forward -n bidr-uat service/grafana-service 3000:3000
open http://localhost:3000/

# Prometheus (via port-forward)
kubectl port-forward -n bidr-uat service/prometheus-service 9090:9090
open http://localhost:9090/
```

## 🔧 Kubernetes Access

### Internal Service Names
- All services accessible within cluster via: `{service-name}.bidr-uat.svc.cluster.local`
- Examples:
  - `auth-service.bidr-uat.svc.cluster.local:8001`
  - `grafana-service.bidr-uat.svc.cluster.local:3000`
  - `prometheus-service.bidr-uat.svc.cluster.local:9090`

### Pod Information
```bash
# List all running pods
kubectl get pods -n bidr-uat

# View logs
kubectl logs -n bidr-uat [pod-name]

# Execute commands in pod
kubectl exec -n bidr-uat [pod-name] -- [command]
```

## 📊 Status Summary
- ✅ **All Django Services**: Working with admin access
- ✅ **Database**: All migrations applied, superusers created
- ✅ **External Access**: Both direct IP and ngrok tunnel working
- ✅ **Monitoring**: Grafana and Prometheus running (port-forward access)
- ⚠️ **Nginx Routing**: Monitoring services routing needs configuration adjustment

## 🎯 Next Steps (Optional)
1. Fix nginx proxy routing for Grafana/Prometheus direct access
2. Set up permanent domain instead of ngrok tunnel
3. Configure SSL certificates for production
4. Set up ingress controller for better routing
