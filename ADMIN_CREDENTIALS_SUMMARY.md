# BIDR Backend - Complete Admin Access Guide

## 🔐 STANDARD ADMIN CREDENTIALS
**Use these credentials for all Django admin interfaces:**
- **Username:** `admin`
- **Email:** `admin@bidr.local`
- **Password:** `bidr_admin_2024`

---

## 🌐 SERVICE ACCESS URLs

### Direct Service Access (Port-based)
| Service | URL | Status |
|---------|-----|--------|
| **Authentication** | http://localhost:8001/admin/ | ⚠️ Restarting |
| **Chat** | http://localhost:8002/admin/ | ⚠️ Not running |
| **Payment** | http://localhost:8003/admin/ | ⚠️ Unhealthy |
| **Resolution** | http://localhost:8004/admin/ | ⚠️ Unhealthy |
| **Products** | http://localhost:8005/admin/ | ⚠️ Restarting |
| **Notifications** | http://localhost:8006/admin/ | ✅ Healthy |
| **Transactions** | http://localhost:8007/admin/ | ⚠️ Restarting |
| **Reviews** | http://localhost:8008/admin/ | ⚠️ Unhealthy |

### Via NGINX Gateway (when nginx container is running)
| Service | URL |
|---------|-----|
| **Authentication** | http://localhost/admin/auth/ |
| **Chat** | http://localhost/admin/chat/ |
| **Payment** | http://localhost/admin/payment/ |
| **Resolution** | http://localhost/admin/resolution/ |
| **Products** | http://localhost/admin/products/ |
| **Notifications** | http://localhost/admin/notifications/ |
| **Transactions** | http://localhost/admin/transactions/ |
| **Reviews** | http://localhost/admin/reviews/ |

---

## 📊 MONITORING SERVICES

### Grafana Dashboard
- **URL:** http://localhost:3000
- **Username:** `admin`
- **Password:** `bidr_admin_password_2024`
- **Status:** ✅ Running

### Prometheus
- **URL:** http://localhost:9090
- **Authentication:** None required
- **Status:** ✅ Running

---

## 💽 DATABASE ACCESS

### PostgreSQL
- **Host:** localhost
- **Port:** 5432
- **Username:** `bidruser`
- **Password:** `bidr_secure_password_2024`
- **Status:** ✅ Healthy

**Individual Databases:**
- `auth_db` - Authentication service
- `chat_db` - Chat service
- `payment_db` - Payment service
- `resolution_db` - Resolution service
- `product_db` - Product management service
- `notifications_db` - Notifications service
- `transactions_db` - Transactions service
- `reviews_db` - Reviews and ratings service

### Redis Cache
- **Host:** localhost
- **Port:** 6379
- **Password:** `bidr_redis_password_2024`
- **Status:** ✅ Healthy

---

## 🔍 LEGACY/ALTERNATIVE CREDENTIALS

### From Individual Service Files:

#### Product Management Service
- **URL:** http://localhost:8005/admin/
- **Username:** `bidr_admin`
- **Password:** `5rAv9W67g^kg`
- **Email:** admin@bidr.com

#### Resolution Service
- **URL:** http://localhost:8004/admin/
- **Username:** `admin`
- **Password:** `admin123`
- **Email:** admin@bidr.com

#### Chat Service
- **URL:** http://localhost:8002/admin/
- **Username:** `chatadmin`
- **Password:** `ChatService@2025`
- **Email:** admin@bidr-chat.com

---

## 🚀 GETTING STARTED

### 1. Access Working Services
Currently, only the **Notifications Service** is fully healthy:
- **URL:** http://localhost:8006/admin/
- **Username:** `admin`
- **Password:** `bidr_admin_2024`

### 2. Monitor Service Status
```bash
docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
```

### 3. Check Service Logs
```bash
# Example: Check auth service logs
docker logs bidr-auth-service

# Check all services
docker logs bidr-notifications-service
docker logs bidr-payment-service
docker logs bidr-resolution-service
```

### 4. Start Additional Services
```bash
# Restart all services
docker compose -f docker-compose.full.yml restart

# Or start specific services
docker compose -f docker-compose.full.yml up -d bidr-auth-service
```

---

## 🔧 TROUBLESHOOTING

### Service Health Issues
Most services are showing "unhealthy" status due to dependency issues (primarily missing Python packages like `rest_framework_simplejwt`).

### Quick Fixes
1. **Check container logs** for specific errors
2. **Restart containers** that are stuck restarting
3. **Verify database connectivity** - PostgreSQL and Redis are healthy
4. **Check for missing dependencies** in container logs

### Working Infrastructure
✅ **Healthy Services:**
- PostgreSQL database
- Redis cache  
- Prometheus monitoring
- Grafana dashboards
- Notifications service

---

## 📝 NOTES

- **Docker Infrastructure:** Fully resolved - no more image pull failures
- **Database Setup:** Complete with all required databases
- **Monitoring:** Grafana and Prometheus are operational
- **Remaining Issues:** Application-level dependency problems in some services
- **Recommended:** Start with the Notifications service (fully working) and gradually fix other services

---

*Last Updated: August 10, 2025*
*Generated after resolving Docker image pull failures*
