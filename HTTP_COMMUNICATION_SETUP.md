# BIDR Microservices HTTP Communication Setup Guide

This guide shows you how to implement HTTP communication across your BIDR microservices using the provided utilities.

## 🚀 Quick Start

### 1. Add Shared Utils to Your Services

Copy the `shared_utils` folder to each of your microservice directories:

```bash
# For Authentication Service
cp -r shared_utils /path/to/authentication_service/

# For Product Management Service  
cp -r shared_utils /path/to/product_management_service/
```

### 2. Update Service Settings

Add the following to your `settings.py` files in each service:

```python
# Authentication Service settings.py
INSTALLED_APPS = [
    # ... your existing apps
    'shared_utils',
]

MIDDLEWARE = [
    # ... your existing middleware
    'shared_utils.service_middleware.ServiceAuthenticationMiddleware',
]

# Service configuration
SERVICE_NAME = 'authentication'
SERVICE_SECRET_KEY = config('SERVICE_SECRET_KEY', default=SECRET_KEY)

# Service URLs (these will be auto-detected from environment)
AUTH_SERVICE_URL = 'http://bidr-auth-1756988136.westus.azurecontainer.io:8000'
PRODUCT_SERVICE_URL = 'http://bidr-product-1756960567.westus.azurecontainer.io:8000'

# CORS Settings for service communication
CORS_ALLOW_ALL_ORIGINS = True
CORS_ALLOWED_ORIGINS = [
    "http://bidr-auth-1756988136.westus.azurecontainer.io:8000",
    "http://bidr-product-1756960567.westus.azurecontainer.io:8000",
]

CORS_ALLOW_HEADERS = [
    'accept',
    'accept-encoding',
    'authorization',
    'content-type',
    'dnt',
    'origin',
    'user-agent',
    'x-csrftoken',
    'x-requested-with',
    'x-service-token',  # For service authentication
    'x-service-name',   # For service identification
]
```

```python
# Product Management Service settings.py
INSTALLED_APPS = [
    # ... your existing apps
    'shared_utils',
]

MIDDLEWARE = [
    # ... your existing middleware
    'shared_utils.service_middleware.ServiceAuthenticationMiddleware',
]

# Service configuration
SERVICE_NAME = 'product_management'
SERVICE_SECRET_KEY = config('SERVICE_SECRET_KEY', default=SECRET_KEY)

# Same CORS and service URL settings as above
```

### 3. Update URL Patterns

Add internal API endpoints to your `urls.py`:

```python
# authentication_service/urls.py
from django.urls import path, include
from shared_utils.service_api import UserVerificationView, health_check_internal

urlpatterns = [
    # ... your existing URLs
    
    # Internal service APIs
    path('api/v1/internal/verify-token/', UserVerificationView.as_view(), name='verify_token'),
    path('api/v1/internal/health/', health_check_internal, name='internal_health'),
]
```

```python
# product_management_service/urls.py
from django.urls import path, include
from shared_utils.service_api import ProductInfoView, health_check_internal

urlpatterns = [
    # ... your existing URLs
    
    # Internal service APIs
    path('api/v1/internal/products/<int:product_id>/', ProductInfoView.as_view(), name='product_info'),
    path('api/v1/internal/health/', health_check_internal, name='internal_health'),
]
```

## 💡 Usage Examples

### Making HTTP Requests Between Services

#### 1. Basic Service-to-Service Communication

```python
# In your authentication service
from shared_utils.service_api import product_api

def verify_user_and_get_products(request):
    # Get user products from product management service
    try:
        products = product_api.search_products(
            query="user_products",
            filters={'user_id': request.user.id}
        )
        
        if products['success']:
            return JsonResponse({
                'user': request.user.username,
                'products': products['data']
            })
        else:
            return JsonResponse({'error': 'Failed to get products'}, status=500)
            
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)
```

#### 2. Using the HTTP Client Directly

```python
# In any service
from shared_utils.http_client import service_registry
from shared_utils.service_config import ServiceConfig

def get_user_data_from_auth_service(user_id):
    try:
        # Get authenticated HTTP client
        auth_client = service_registry.get_client('authentication')
        
        # Make request with automatic retry and error handling
        response = auth_client.get(f'/api/v1/internal/users/{user_id}/')
        
        return response
        
    except Exception as e:
        logger.error(f"Failed to get user data: {str(e)}")
        return None
```

#### 3. Using Service Helper for Complex Operations

```python
# Broadcasting events to multiple services
from shared_utils.service_api import service_helper

def user_registered_event(user_data):
    # Notify all services about new user registration
    results = service_helper.broadcast_event(
        event_name='user_registered',
        data=user_data,
        services=['product_management', 'notification']
    )
    
    return results
```

### Creating Custom Service APIs

#### 1. Add Internal API Views

```python
# In your views.py
from shared_utils.service_api import ServiceAPIResponse
from shared_utils.service_middleware import service_required
from django.views.decorators.csrf import csrf_exempt
import json

@csrf_exempt
@service_required(['authentication'])  # Only allow auth service to call this
def update_product_analytics(request):
    if request.method == 'POST':
        try:
            data = json.loads(request.body)
            product_id = data.get('product_id')
            action = data.get('action')  # 'view', 'purchase', etc.
            user_id = data.get('user_id')
            
            # Update analytics logic here
            # ... your business logic ...
            
            return ServiceAPIResponse.success({
                'product_id': product_id,
                'analytics_updated': True
            })
            
        except json.JSONDecodeError:
            return ServiceAPIResponse.error('Invalid JSON', 'INVALID_JSON')
        except Exception as e:
            return ServiceAPIResponse.error(str(e), 'UPDATE_ERROR', 500)
    
    return ServiceAPIResponse.error('Method not allowed', 'METHOD_NOT_ALLOWED', 405)
```

#### 2. Service Authentication in Views

```python
# Protect specific endpoints for specific services
from shared_utils.service_middleware import service_required

@service_required(['product_management', 'analytics'])
def get_user_purchase_history(request, user_id):
    # Only product management and analytics services can access this
    purchases = UserPurchase.objects.filter(user_id=user_id)
    
    return ServiceAPIResponse.success({
        'user_id': user_id,
        'purchases': [p.to_dict() for p in purchases]
    })
```

### Health Monitoring

#### Check Service Health

```python
# Check if other services are healthy
from shared_utils.service_config import ServiceConfig

def check_dependencies():
    health_status = {
        'authentication': ServiceConfig.is_service_available('authentication'),
        'product_management': ServiceConfig.is_service_available('product_management'),
    }
    
    all_healthy = all(health_status.values())
    
    return {
        'status': 'healthy' if all_healthy else 'degraded',
        'services': health_status
    }
```

## 🔧 Configuration Options

### Environment Variables

Set these environment variables in your deployment:

```bash
# Service identification
SERVICE_NAME=authentication
SERVICE_SECRET_KEY=your-secret-key-for-service-auth

# Service URLs (auto-detected but can be overridden)
AUTH_SERVICE_URL=http://bidr-auth-1756988136.westus.azurecontainer.io:8000
PRODUCT_SERVICE_URL=http://bidr-product-1756960567.westus.azurecontainer.io:8000

# Service tokens (optional, for extra security)
AUTH_SERVICE_TOKEN=optional-bearer-token
PRODUCT_SERVICE_TOKEN=optional-bearer-token
```

### Custom Service Registration

```python
# In your Django app's ready() method or startup
from shared_utils.service_config import ServiceConfig
from shared_utils.http_client import service_registry

# Register custom service
service_registry.register_service(
    name='custom_service',
    base_url='http://custom-service.example.com:8000',
    token='optional-auth-token'
)
```

## 🎯 Common Patterns

### 1. User Authentication Flow

```python
# Authentication service validates token and calls product service
def login_user_and_sync_data(request):
    # Authenticate user
    user = authenticate_user(request)
    
    if user:
        # Sync user data with product service
        sync_result = product_api.update_user_data(user.id, {
            'last_login': timezone.now().isoformat(),
            'preferences': user.preferences
        })
        
        if sync_result['success']:
            return JsonResponse({'token': generate_token(user)})
    
    return JsonResponse({'error': 'Invalid credentials'}, status=401)
```

### 2. Product Recommendation with User Data

```python
# Product service gets user preferences from auth service
def get_personalized_products(request, user_id):
    # Get user data from authentication service
    user_data = auth_api.get_user_profile(user_id)
    
    if user_data['success']:
        preferences = user_data['data'].get('preferences', {})
        
        # Filter products based on preferences
        products = Product.objects.filter(
            category__in=preferences.get('categories', [])
        )
        
        return JsonResponse({
            'products': [p.to_dict() for p in products],
            'personalized': True
        })
    
    return JsonResponse({'error': 'Failed to get user data'}, status=500)
```

### 3. Event Broadcasting

```python
# When a product is purchased, notify multiple services
def process_purchase(request):
    purchase_data = process_payment(request.data)
    
    if purchase_data['success']:
        # Broadcast purchase event to all relevant services
        service_helper.broadcast_event(
            event_name='product_purchased',
            data={
                'user_id': request.user.id,
                'product_id': purchase_data['product_id'],
                'amount': purchase_data['amount'],
                'timestamp': timezone.now().isoformat()
            },
            services=['authentication', 'analytics', 'notification']
        )
        
        return JsonResponse(purchase_data)
```

## 🔒 Security Best Practices

1. **Always use service tokens** for internal API calls
2. **Validate request sources** using the service middleware
3. **Log all inter-service communications** for debugging
4. **Use HTTPS in production** for all service communications
5. **Implement rate limiting** for internal endpoints
6. **Monitor service health** regularly

## 🚨 Error Handling

The HTTP client includes automatic:
- **Retry logic** for failed requests
- **Timeout handling** for slow services  
- **Circuit breaker pattern** for degraded services
- **Structured error logging** for debugging

## 📊 Monitoring

Use the built-in health check endpoints:

```bash
# Check individual service health
curl http://your-service:8000/health/

# Check internal service communication
curl -X POST http://your-service:8000/api/v1/internal/health/ \
  -H "X-Service-Token: your-service-token" \
  -H "X-Service-Name: monitoring" \
  -H "Content-Type: application/json" \
  -d '{"service": "authentication"}'
```

This completes your HTTP communication setup between BIDR microservices! 🎉
