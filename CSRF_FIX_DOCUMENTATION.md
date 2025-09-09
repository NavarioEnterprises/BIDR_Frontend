# CSRF Verification Fix for Reviews Service

## Problem
The Django admin interface for the reviews service was throwing CSRF verification errors when users tried to log in via HTTPS at `https://reviews.bidr.co.za/admin/`:

```
Forbidden (403)
CSRF verification failed. Request aborted.
More information is available with DEBUG=True.
```

## Root Cause
The CSRF verification failure occurred because the Django application was not properly configured to handle HTTPS requests when deployed behind a proxy (Azure Application Gateway). The key issues were:

1. Missing `CSRF_TRUSTED_ORIGINS` configuration for HTTPS domains
2. Missing `SECURE_PROXY_SSL_HEADER` setting to detect HTTPS through proxy
3. Inadequate security settings for production HTTPS deployment

## Solution
Updated the Django settings (`reviews_and_ratings/settings.py`) with proper CSRF and security configurations:

### 1. CSRF Configuration for HTTPS Behind Proxy
```python
# CSRF Configuration for HTTPS behind proxy
CSRF_TRUSTED_ORIGINS = [
    "https://reviews.bidr.co.za",
    "https://*.bidr.co.za",
    "https://*.azurecontainer.io",
    "http://localhost:8000",
    "http://127.0.0.1:8000",
]

# Session and Security Settings for HTTPS
SECURE_PROXY_SSL_HEADER = ('HTTP_X_FORWARDED_PROTO', 'https')
```

### 2. Production HTTPS Security Settings
```python
# HTTPS Security Settings (only in production)
if not DEBUG:
    SECURE_SSL_REDIRECT = False  # Application Gateway handles this
    SESSION_COOKIE_SECURE = True
    CSRF_COOKIE_SECURE = True
    SECURE_BROWSER_XSS_FILTER = True
    SECURE_CONTENT_TYPE_NOSNIFF = True
```

### 3. Updated CORS Configuration
```python
# CORS Configuration
CORS_ALLOWED_ORIGINS = [
    "https://reviews.bidr.co.za",
    "https://*.bidr.co.za",
    "http://localhost:3000",  # React app
    "http://127.0.0.1:3000",
    "http://localhost:8000",  # Django admin
    "http://127.0.0.1:8000",
]
```

## Implementation Steps
1. **Updated Django Settings**: Modified `reviews_and_ratings/settings.py` with CSRF and security configurations
2. **Rebuilt Docker Image**: Built new container image `bidr-reviews-service:v4-csrf-fix`
3. **Deployed Updated Container**: Replaced the running container with the fixed version
4. **Updated Application Gateway**: Updated backend pool to point to new container IP
5. **Tested CSRF Functionality**: Verified that login form loads with proper CSRF tokens

## Verification
After implementing the fix:

✅ **Login Page Loads**: `https://reviews.bidr.co.za/admin/login/` returns 200 OK
✅ **CSRF Cookie Set**: Secure CSRF cookie is set with proper flags
✅ **CSRF Token in Form**: CSRF token is properly embedded in login form
✅ **HTTPS Security**: All security headers and settings are configured correctly

## Container Details
- **New Image**: `bidrsimpleregistry.azurecr.io/bidr-reviews-service:v4-csrf-fix`
- **Container IP**: `20.237.46.87`
- **Status**: Running and healthy
- **Backend Pool**: Updated in Azure Application Gateway

## Configuration Summary
The fix ensures that Django properly recognizes HTTPS requests when deployed behind Azure Application Gateway and correctly validates CSRF tokens for secure form submissions. The `CSRF_TRUSTED_ORIGINS` setting is crucial for allowing CSRF tokens from the `reviews.bidr.co.za` domain, while the security settings ensure that cookies are only transmitted over HTTPS connections.
