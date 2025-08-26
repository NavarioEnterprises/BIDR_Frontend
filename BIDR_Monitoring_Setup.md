# BIDR Monitoring Setup - Complete Configuration

## 🎯 Overview
This document outlines the complete monitoring setup for the BIDR platform using Prometheus and Grafana with enhanced security and comprehensive service monitoring.

## 🔐 Updated Credentials

### Grafana Dashboard
- **URL**: `http://4.175.32.168:3000/`
- **Username**: `admin`
- **Password**: `BidrMonitor123!`
- **Features**: 
  - Enhanced security settings
  - Disabled anonymous access
  - BIDR-specific Prometheus datasource pre-configured
  - Proper root URL configuration

### Prometheus Metrics
- **URL**: `http://4.175.32.168:4000/`
- **Username**: `admin`
- **Password**: `PrometheusMonitor123!`
- **Features**:
  - Basic authentication enabled
  - Comprehensive BIDR services monitoring
  - Custom job configurations for each service
  - Kubernetes infrastructure monitoring

## 📊 Monitoring Configuration

### Prometheus Jobs Configured

1. **Individual BIDR Service Monitoring**:
   - `bidr-auth-service` → auth-service.bidr-uat.svc.cluster.local:8001
   - `bidr-chat-service` → chat-service.bidr-uat.svc.cluster.local:8002
   - `bidr-payment-service` → payment-service.bidr-uat.svc.cluster.local:8003
   - `bidr-product-service` → product-management-service.bidr-uat.svc.cluster.local:8004
   - `bidr-notifications-service` → notifications-service.bidr-uat.svc.cluster.local:8005
   - `bidr-transactions-service` → transactions-service.bidr-uat.svc.cluster.local:8006
   - `bidr-reviews-service` → reviews-service.bidr-uat.svc.cluster.local:8007
   - `bidr-resolution-service` → resolution-service.bidr-uat.svc.cluster.local:8008

2. **Kubernetes Pod Discovery**:
   - Automatically discovers pods with `prometheus.io/scrape: "true"` annotation
   - Focused on `bidr-uat` namespace
   - Custom labeling for BIDR service identification

3. **Infrastructure Monitoring**:
   - Kubernetes nodes monitoring
   - Cluster-wide metrics collection

### Service Labels
Each BIDR service is monitored with consistent labels:
- `service`: Service name (auth, chat, payment, etc.)
- `app`: "bidr"
- `environment`: "uat"

### Grafana Datasource
- **Name**: "Prometheus-BIDR"
- **URL**: Internal cluster connection to Prometheus
- **Default**: Set as default datasource
- **Time Interval**: 5s for real-time monitoring

## 🛠️ Advanced Features

### Security Enhancements
- **Grafana**: 
  - Admin password changed from default
  - Sign-up disabled
  - Anonymous access disabled
  - Organization creation restricted
- **Prometheus**:
  - Basic authentication implemented
  - Secure credentials stored in Kubernetes secrets

### Monitoring Capabilities
- **Real-time metrics** from all 8 Django services
- **Health check monitoring** via `/metrics` endpoints
- **Custom gauge metrics** support (CustomGaugeWithLabel)
- **Infrastructure monitoring** for Kubernetes cluster
- **Service discovery** for automatic pod detection

## 🚀 Usage Instructions

### Accessing Grafana
1. Navigate to `http://4.175.32.168:3000/`
2. Login with `admin` / `BidrMonitor123!`
3. Prometheus datasource is pre-configured
4. Create dashboards for BIDR services monitoring

### Accessing Prometheus
1. Navigate to `http://4.175.32.168:4000/`
2. Login with `admin` / `PrometheusMonitor123!`
3. Use queries to explore BIDR service metrics
4. Example queries:
   - `up{app="bidr"}` - Check service availability
   - `http_requests_total{service="auth"}` - Auth service requests
   - `django_http_responses_total_by_status` - Django response metrics

### Adding Custom Metrics
For Django services, use the CustomGaugeWithLabel pattern:
```python
from prometheus_client import Gauge

# Example custom metric
bidr_active_users = Gauge(
    'bidr_active_users_total',
    'Number of active users in BIDR platform',
    ['service', 'environment']
)

# Update the metric
bidr_active_users.labels(service='auth', environment='uat').set(150)
```

## 📋 Service Health Status
All services are configured for monitoring at `/metrics` endpoint:
- ✅ Auth Service: `auth-service:8001/metrics`
- ✅ Chat Service: `chat-service:8002/metrics`
- ✅ Payment Service: `payment-service:8003/metrics`
- ✅ Product Management: `product-management-service:8004/metrics`
- ✅ Notifications Service: `notifications-service:8005/metrics`
- ✅ Transactions Service: `transactions-service:8006/metrics`
- ✅ Reviews Service: `reviews-service:8007/metrics`
- ✅ Resolution Service: `resolution-service:8008/metrics`

## 🔧 Maintenance
- **Credentials**: Stored securely in Kubernetes secrets
- **Configuration**: Via Kubernetes ConfigMaps
- **Updates**: Use `kubectl rollout restart` for deployment updates
- **Scaling**: Both Grafana and Prometheus can be scaled as needed

## 🎯 Key Highlights

1. **Single External IP Solution**: `4.175.32.168`
   - Grafana on port 3000
   - Prometheus on port 4000

2. **Enhanced Security**:
   - Grafana: `admin` / `BidrMonitor123!`
   - Prometheus: `admin` / `PrometheusMonitor123!`

3. **Comprehensive Monitoring**:
   - All 8 BIDR Django services configured with correct ports
   - Kubernetes infrastructure monitoring
   - Custom labeling and service discovery

4. **Production-Ready Features**:
   - Secure credential storage
   - Pre-configured Grafana datasource
   - Health check monitoring for all services

## 🔐 **DJANGO ADMIN CREDENTIALS**

All Django superusers have been created and tested successfully:

### Service-Specific Admin Accounts
| Service | URL | Username | Password |
|---------|-----|----------|----------|
| **Auth** | http://108.141.192.60/admin/ | `auth_admin` | `Tc_tYOQZt)>84A3M` |
| **Chat** | http://108.141.192.60/chat/admin/ | `chat_admin` | `$$:_yCg}6pSOcH*u` |
| **Payment** | http://108.141.192.60/payments/admin/ | `payment_admin` | `qF{OK_*B>Id!PuB}` |
| **Product** | http://108.141.192.60/products/admin/ | `product_admin` | `d_<!?8zm0Pv?nbA9` |
| **Notifications** | http://108.141.192.60/notifications/admin/ | `notifications_admin` | `xYWKA<_r]p3tqlNy` |
| **Transactions** | http://108.141.192.60/transactions/admin/ | `transactions_admin` | `Vi0)$>amuaIP4RS` |
| **Reviews** | http://108.141.192.60/reviews/admin/ | `reviews_admin` | `:lO#qUghyQiJ+b&d` |
| **Resolution** | http://108.141.192.60/resolution/admin/ | `resolution_admin` | `vqL1-t)#X{zOOEf>` |

**Status**: ✅ All superusers created and verified working

## 🎉 Next Steps
1. Create custom Grafana dashboards for BIDR metrics
2. Set up alerting rules in Prometheus
3. Configure notification channels in Grafana
4. Add custom business metrics to Django services
5. Set up log aggregation integration
6. Access individual service admin panels using the credentials above
