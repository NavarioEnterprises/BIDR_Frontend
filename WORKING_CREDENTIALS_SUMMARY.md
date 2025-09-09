# 🔐 BIDR Platform - Complete Working Credentials

## ✅ **VERIFIED WORKING CREDENTIALS**

All credentials below have been tested and verified as working as of August 24, 2025.

---

## 📊 **MONITORING SERVICES**

### Grafana Dashboard
- **URL**: `http://4.175.32.168:3000/`
- **Username**: `admin`
- **Password**: `BidrMonitor123!`
- **Status**: ✅ **WORKING** - Successfully updated and tested
- **Access Method**: Web browser login with JSON authentication

### Prometheus Metrics
- **URL**: `http://4.175.32.168:4000/`
- **Username**: `admin`
- **Password**: `PrometheusMonitor123!`
- **Status**: ✅ **WORKING** - Basic auth enabled and tested
- **Access Method**: HTTP Basic Authentication

---

## 🚀 **DJANGO ADMIN PANELS - ALL SERVICES**

All Django admin panels are accessible via nginx proxy at `http://108.141.192.60/`

### 🔐 Auth Service (Primary)
- **URL**: `http://108.141.192.60/admin/`
- **Username**: `auth_admin`
- **Password**: `Tc_tYOQZt)>84A3M`
- **Email**: `auth.admin@bidr.co.za`
- **Status**: ✅ **WORKING** - Superuser created successfully

### 💬 Chat Service
- **URL**: `http://108.141.192.60/chat/admin/`
- **Username**: `chat_admin`
- **Password**: `$$:_yCg}6pSOcH*u`
- **Email**: `chat.admin@bidr.co.za`
- **Status**: ✅ **WORKING** - Superuser created successfully

### 💳 Payment Service
- **URL**: `http://108.141.192.60/payments/admin/`
- **Username**: `payment_admin`
- **Password**: `qF{OK_*B>Id!PuB}`
- **Email**: `payment.admin@bidr.co.za`
- **Status**: ✅ **WORKING** - Superuser created successfully

### 🛍️ Product Management Service
- **URL**: `http://108.141.192.60/products/admin/`
- **Username**: `product_admin`
- **Password**: `d_<!?8zm0Pv?nbA9`
- **Email**: `product.admin@bidr.co.za`
- **Status**: ✅ **WORKING** - Superuser created successfully

### 🔔 Notifications Service
- **URL**: `http://108.141.192.60/notifications/admin/`
- **Username**: `notifications_admin`
- **Password**: `xYWKA<_r]p3tqlNy`
- **Email**: `notifications.admin@bidr.co.za`
- **Status**: ✅ **WORKING** - Superuser created successfully

### 💰 Transactions Service
- **URL**: `http://108.141.192.60/transactions/admin/`
- **Username**: `transactions_admin`
- **Password**: `Vi0)$>amuaIP4RS`
- **Email**: `transactions.admin@bidr.co.za`
- **Status**: ✅ **WORKING** - Superuser created successfully

### ⭐ Reviews Service
- **URL**: `http://108.141.192.60/reviews/admin/`
- **Username**: `reviews_admin`
- **Password**: `:lO#qUghyQiJ+b&d`
- **Email**: `reviews.admin@bidr.co.za`
- **Status**: ✅ **WORKING** - Superuser created successfully

### ⚖️ Resolution Service
- **URL**: `http://108.141.192.60/resolution/admin/`
- **Username**: `resolution_admin`
- **Password**: `vqL1-t)#X{zOOEf>`
- **Email**: `resolution.admin@bidr.co.za`
- **Status**: ✅ **WORKING** - Superuser created successfully

---

## 🔗 **QUICK ACCESS SUMMARY**

### Monitoring Dashboard Access
```bash
# Grafana (Visual dashboards)
curl -X POST -H "Content-Type: application/json" \
  -d '{"user":"admin","password":"BidrMonitor123!"}' \
  http://4.175.32.168:3000/login

# Prometheus (Metrics API)
curl -u admin:PrometheusMonitor123! http://4.175.32.168:4000/query
```

### Service Health Check
All BIDR services are monitored by Prometheus at:
- Auth: `auth-service.bidr-uat.svc.cluster.local:8001/metrics`
- Chat: `chat-service.bidr-uat.svc.cluster.local:8002/metrics`
- Payment: `payment-service.bidr-uat.svc.cluster.local:8003/metrics`
- Product: `product-management-service.bidr-uat.svc.cluster.local:8004/metrics`
- Notifications: `notifications-service.bidr-uat.svc.cluster.local:8005/metrics`
- Transactions: `transactions-service.bidr-uat.svc.cluster.local:8006/metrics`
- Reviews: `reviews-service.bidr-uat.svc.cluster.local:8007/metrics`
- Resolution: `resolution-service.bidr-uat.svc.cluster.local:8008/metrics`

---

## 🛡️ **SECURITY NOTES**

### Production-Ready Security Features ✅
- **Grafana**: Anonymous access disabled, sign-up disabled, enhanced admin password
- **Prometheus**: Basic authentication with secure credentials stored in Kubernetes secrets
- **Django Services**: Individual superuser accounts per service with complex passwords
- **Network Security**: Services accessible only via nginx proxy with proper routing

### Credential Storage
- **Grafana**: Environment variables in Kubernetes deployment
- **Prometheus**: Kubernetes secrets (`prometheus-auth-secret`)
- **Django**: Database-stored user accounts with hashed passwords

---

## 🚀 **USAGE INSTRUCTIONS**

### Accessing Django Admin Panels
1. Navigate to the appropriate service URL
2. Login with the service-specific credentials
3. Access all Django admin functionality

### Monitoring Services
1. **Grafana**: Access via web browser for visual dashboards
2. **Prometheus**: Use for metrics queries and API access
3. **Service Metrics**: All 8 BIDR services are actively monitored

### Troubleshooting
- All services are running in `bidr-uat` namespace
- Pod IPs are automatically managed by Kubernetes endpoints
- Use `kubectl logs` for service debugging
- Prometheus targets page shows service health status

---

## 📋 **DEPLOYMENT INFORMATION**

- **Kubernetes Namespace**: `bidr-uat`
- **External IP**: `4.175.32.168` (Grafana:3000, Prometheus:4000)
- **Nginx Proxy**: `108.141.192.60` (All Django admin panels)
- **Database**: PostgreSQL with individual databases per service
- **Container Registry**: Azure Container Registry
- **Environment**: UAT (User Acceptance Testing)

---

## ✅ **VERIFICATION STATUS**

| Service | Admin Panel | Superuser | Login Test | Status |
|---------|-------------|-----------|------------|--------|
| Auth | ✅ Accessible | ✅ Created | ✅ Working | 🟢 READY |
| Chat | ✅ Accessible | ✅ Created | ✅ Working | 🟢 READY |
| Payment | ✅ Accessible | ✅ Created | ✅ Working | 🟢 READY |
| Product | ✅ Accessible | ✅ Created | ✅ Working | 🟢 READY |
| Notifications | ✅ Accessible | ✅ Created | ✅ Working | 🟢 READY |
| Transactions | ✅ Accessible | ✅ Created | ✅ Working | 🟢 READY |
| Reviews | ✅ Accessible | ✅ Created | ✅ Working | 🟢 READY |
| Resolution | ✅ Accessible | ✅ Created | ✅ Working | 🟢 READY |
| Grafana | ✅ Accessible | ✅ Updated | ✅ Working | 🟢 READY |
| Prometheus | ✅ Accessible | ✅ Working | ✅ Working | 🟢 READY |

---

*Last Updated: August 24, 2025*  
*All credentials verified and tested in UAT environment*
