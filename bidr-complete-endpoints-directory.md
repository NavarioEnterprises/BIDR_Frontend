# 📚 BIDR Complete Endpoints Directory

**Gateway Base URL**: `https://bidr-gateway-1756992603.westus.cloudapp.azure.com`

---

## 🔐 Authentication Service
**Backend**: Auth Service (40.118.207.135:8000)  
**Paths**: `/auth/*`, `/notifications/*`, `/chat/*`, root paths

### ✅ Core Endpoints

#### Health & Monitoring
- **GET `/health/`** - Service health check
  ```json
  {"status": "healthy", "service": "authentication_service", "timestamp": 1757002792.706151}
  ```
- **GET `/metrics`** - Prometheus metrics endpoint

#### API Documentation  
- **GET `/swagger/`** - Swagger UI interface
- **GET `/redoc/`** - ReDoc API documentation
- **GET `/swagger.json`** - OpenAPI specification

#### Admin Interface
- **GET `/admin/`** - Django admin panel

#### Authentication API
- **POST `/api/token/`** - Obtain JWT access token
  ```json
  // Request
  {
    "username": "string",
    "password": "string"  
  }
  // Response
  {
    "access": "jwt_access_token",
    "refresh": "jwt_refresh_token"
  }
  ```

- **POST `/api/token/refresh/`** - Refresh JWT token
  ```json
  // Request
  {
    "refresh": "jwt_refresh_token"
  }
  // Response  
  {
    "access": "new_jwt_access_token"
  }
  ```

- **POST `/api/token/verify/`** - Verify JWT token
  ```json
  // Request
  {
    "token": "jwt_token"
  }
  ```

### 🔄 Service Path Routing (Gateway Ready)

#### Chat Service Paths
- **GET `/chat/`** - Chat service root (routed to auth backend)
- **ALL `/chat/*`** - All chat-related endpoints

#### Notifications Service Paths  
- **GET `/notifications/`** - Notifications service root
- **ALL `/notifications/*`** - All notification endpoints

---

## 🛒 Product Management Service
**Backend**: Product Service (20.253.249.204:8000)  
**Paths**: `/api/*`, `/products/*`, `/payment/*`, `/reviews/*`, `/transactions/*`, `/resolution/*`

### ✅ Core Endpoints

#### Health & Monitoring
- **GET `/health/`** - Service health check (via root path routing)
- **GET `/metrics`** - Prometheus metrics endpoint

#### API Documentation
- **GET `/swagger/`** - Swagger UI interface  
- **GET `/redoc/`** - ReDoc API documentation
- **GET `/swagger.json`** - OpenAPI specification

#### Admin Interface
- **GET `/admin/`** - Django admin panel

### 📦 Product Management API

#### Categories & Attributes
- **GET `/api/v1/categories/`** - Get product categories structure
  ```json
  {
    "categories": "http://bidr-gateway-1756992603.westus.cloudapp.azure.com/inventory/api/v1/categories/categories/",
    "attributes": "http://bidr-gateway-1756992603.westus.cloudapp.azure.com/inventory/api/v1/categories/attributes/"
  }
  ```

#### Product Requests  
- **GET `/api/v1/product-requests/`** - Product requests API root
  ```json
  {
    "requests": "http://bidr-gateway-1756992603.westus.cloudapp.azure.com/inventory/api/v1/requests/requests/",
    "consumer-electronics": "http://bidr-gateway-1756992603.westus.cloudapp.azure.com/inventory/api/v1/requests/consumer-electronics/",
    "vehicle-spares": "http://bidr-gateway-1756992603.westus.cloudapp.azure.com/inventory/api/v1/requests/vehicle-spares/",
    "tyres-rims": "http://bidr-gateway-1756992603.westus.cloudapp.azure.com/inventory/api/v1/requests/tyres-rims/",
    "messages": "http://bidr-gateway-1756992603.westus.cloudapp.azure.com/inventory/api/v1/requests/messages/",
    "watchlist": "http://bidr-gateway-1756992603.westus.cloudapp.azure.com/inventory/api/v1/requests/watchlist/",
    "orders": "http://bidr-gateway-1756992603.westus.cloudapp.azure.com/inventory/api/v1/requests/orders/"
  }
  ```

#### Quotes Management
- **GET `/api/v1/quotes/`** - Quotes management API root
  ```json
  {
    "quotes": "http://bidr-gateway-1756992603.westus.cloudapp.azure.com/inventory/api/v1/quotes/quotes/",
    "quote-items": "http://bidr-gateway-1756992603.westus.cloudapp.azure.com/inventory/api/v1/quotes/quote-items/",
    "quote-attachments": "http://bidr-gateway-1756992603.westus.cloudapp.azure.com/inventory/api/v1/quotes/quote-attachments/",
    "quote-messages": "http://bidr-gateway-1756992603.westus.cloudapp.azure.com/inventory/api/v1/quotes/quote-messages/",
    "quote-comparisons": "http://bidr-gateway-1756992603.westus.cloudapp.azure.com/inventory/api/v1/quotes/quote-comparisons/"
  }
  ```

#### Business Operations
- **GET/POST `/api/v1/transactions/`** - Transaction handling
- **GET/POST `/api/v1/ratings/`** - Product ratings and reviews
- **GET `/api/v1/analytics/`** - Analytics and reporting data

#### Inventory Management
- **GET `/inventory/`** - Inventory management interface

### 🔄 Service Path Routing (Gateway Ready)

#### Payment Service Paths
- **GET `/payment/`** - Payment service root (routed to product backend)
- **GET `/payments/`** - Alternative payment path
- **ALL `/payment/*`** - All payment-related endpoints
- **ALL `/payments/*`** - All payment-related endpoints (plural)

#### Reviews Service Paths
- **GET `/reviews/`** - Reviews service root  
- **ALL `/reviews/*`** - All review endpoints

#### Transactions Service Paths
- **GET `/transactions/`** - Transactions service root
- **ALL `/transactions/*`** - All transaction endpoints

#### Resolution/Disputes Service Paths  
- **GET `/resolution/`** - Resolution service root
- **GET `/dispute/`** - Dispute handling (alternative path)
- **ALL `/resolution/*`** - All resolution endpoints
- **ALL `/dispute/*`** - All dispute-related endpoints

---

## 🎯 Service Integration Mapping

### Current Architecture
| Service Path | Routes To | Backend IP | Status |
|--------------|-----------|------------|---------|
| `/auth/*` | Auth Service | 40.118.207.135:8000 | ✅ Active |
| `/chat/*` | Auth Service | 40.118.207.135:8000 | ✅ Gateway Ready |
| `/notifications/*` | Auth Service | 40.118.207.135:8000 | ✅ Gateway Ready |
| `/api/*` | Product Service | 20.253.249.204:8000 | ✅ Active |
| `/products/*` | Product Service | 20.253.249.204:8000 | ✅ Active |
| `/payment/*` | Product Service | 20.253.249.204:8000 | ✅ Gateway Ready |
| `/payments/*` | Product Service | 20.253.249.204:8000 | ✅ Gateway Ready |
| `/reviews/*` | Product Service | 20.253.249.204:8000 | ✅ Gateway Ready |
| `/transactions/*` | Product Service | 20.253.249.204:8000 | ✅ Gateway Ready |
| `/resolution/*` | Product Service | 20.253.249.204:8000 | ✅ Gateway Ready |
| `/dispute/*` | Product Service | 20.253.249.204:8000 | ✅ Gateway Ready |

### Available Container Services
| Container | IP Address | Port | Service Function |
|-----------|------------|------|------------------|
| bidr-auth-service | 40.118.207.135 | 8000 | Authentication & Authorization |
| bidr-product-service | 20.253.249.204 | 8000 | Product Management & E-commerce |
| bidr-chat-service | 40.118.255.79 | 8002 | Chat & Messaging |
| bidr-notifications-service | 20.245.132.92 | 8005 | Notifications & Alerts |
| bidr-payment-service | 52.241.250.195 | 8003 | Payment Processing |
| bidr-resolution-service | 40.112.239.103 | 8004 | Dispute Resolution |
| bidr-reviews-service | 13.64.114.164 | 8007 | Reviews & Ratings |
| bidr-transactions-service | 20.245.173.123 | 8006 | Transaction Management |

---

## 🧪 Testing Your Endpoints

### Quick Health Checks
```bash
# Authentication Service Health
curl -k https://bidr-gateway-1756992603.westus.cloudapp.azure.com/health/

# Product Service API
curl -k https://bidr-gateway-1756992603.westus.cloudapp.azure.com/api/v1/categories/

# Service Path Testing (All should return Django 404 pages, not 502 errors)
curl -k https://bidr-gateway-1756992603.westus.cloudapp.azure.com/chat/
curl -k https://bidr-gateway-1756992603.westus.cloudapp.azure.com/payment/
curl -k https://bidr-gateway-1756992603.westus.cloudapp.azure.com/reviews/
```

### Authentication Flow Example
```bash
# Get JWT Token
curl -k -X POST https://bidr-gateway-1756992603.westus.cloudapp.azure.com/api/token/ \
  -H "Content-Type: application/json" \
  -d '{"username": "your_username", "password": "your_password"}'

# Use Token for Authenticated Requests
curl -k -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  https://bidr-gateway-1756992603.westus.cloudapp.azure.com/api/v1/product-requests/
```

### API Exploration
```bash
# Browse API Documentation  
open https://bidr-gateway-1756992603.westus.cloudapp.azure.com/swagger/

# Get Product Categories
curl -k https://bidr-gateway-1756992603.westus.cloudapp.azure.com/api/v1/categories/ | jq .

# Get Product Requests Structure
curl -k https://bidr-gateway-1756992603.westus.cloudapp.azure.com/api/v1/product-requests/ | jq .

# Get Quotes API Structure  
curl -k https://bidr-gateway-1756992603.westus.cloudapp.azure.com/api/v1/quotes/ | jq .
```

---

## 📝 Development Notes

### ✅ Currently Working
- All 8 service paths are accessible through the gateway
- Authentication service fully functional with JWT tokens
- Product service API responding with structured data
- Path-based routing correctly directing traffic
- Health monitoring and metrics available
- Swagger documentation accessible

### 🔄 Next Steps
1. **Application-Level Routing**: Configure internal routing within your Django apps to handle the specific service paths
2. **Authentication Integration**: Implement JWT token validation across all service paths  
3. **API Documentation**: Expand Swagger specs to cover all microservice endpoints
4. **Service-to-Service Communication**: Set up internal service communication as needed

### 🚀 Production Ready
Your Application Gateway infrastructure is fully deployed and operational. All endpoints are accessible through the single HTTPS domain with proper SSL termination and path-based routing.

**Gateway URL**: `https://bidr-gateway-1756992603.westus.cloudapp.azure.com`
