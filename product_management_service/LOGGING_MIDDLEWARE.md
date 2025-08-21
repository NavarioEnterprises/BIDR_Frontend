# API Logging Middleware Documentation

## Overview

The API Logging Middleware automatically captures and logs all API requests to your Django application. It provides comprehensive logging for:

- **API Request Logging**: Complete request/response details, timing, and user information
- **Error Logging**: Automatic exception tracking with stack traces
- **Performance Logging**: Slow request detection and performance metrics

## Features

### APILoggingMiddleware

- ✅ Logs all API requests with detailed information
- ✅ Captures request/response bodies (JSON only, with size limits)
- ✅ Measures response times in milliseconds
- ✅ Records user information and IP addresses
- ✅ Filters out sensitive headers for security
- ✅ Selectively logs based on endpoint patterns
- ✅ Handles both authenticated and anonymous users

### PerformanceLoggingMiddleware

- ✅ Monitors slow requests (configurable threshold)
- ✅ Records CPU and memory usage (requires psutil)
- ✅ Logs performance metrics to database
- ✅ Provides detailed metadata for analysis

### Error Logging

- ✅ Automatic exception tracking
- ✅ Stack trace capture
- ✅ Request context for errors
- ✅ Resolution tracking system

## Installation & Setup

### 1. Add to Installed Apps

The middleware is part of the `app_logs` application:

```python
# settings.py
LOCAL_APPS = [
    # ... other apps
    'app_logs',
]
```

### 2. Add Middleware to Settings

```python
# settings.py
MIDDLEWARE = [
    'corsheaders.middleware.CorsMiddleware',
    'django.middleware.security.SecurityMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
    
    # API Logging Middleware - Add at the end
    'app_logs.middleware.APILoggingMiddleware',
    'app_logs.middleware.PerformanceLoggingMiddleware',
]
```

### 3. Run Migrations

```bash
python manage.py makemigrations app_logs
python manage.py migrate app_logs
```

## Configuration

### Logged Endpoints

By default, the middleware logs requests to:

- Any path containing `/api/`
- Paths starting with `/api/`
- JSON responses (detected by Content-Type)
- Specific app endpoints: `/product-requests/`, `/categories/`, `/analytics/`, `/core/`

### Excluded Endpoints

The following are automatically excluded from logging:

- Static files: `/static/`, `/media/`
- Admin JavaScript: `/admin/jsi18n/`
- Health checks: `/health/`, `/ping/`, `/status/`

### Performance Threshold

Slow requests are logged when they exceed the threshold (default: 2 seconds):

```python
# In PerformanceLoggingMiddleware.__init__()
self.slow_request_threshold = 2.0  # seconds
```

### Response Body Size Limit

Response bodies are limited to 10KB to prevent database bloat:

```python
# In APILoggingMiddleware._get_response_body()
if len(content) < 10000:  # 10KB limit
```

## Database Models

### APIRequestLog

Stores detailed information about each API request:

```python
class APIRequestLog(models.Model):
    # Identification
    id = UUIDField(primary_key=True)
    
    # Request details
    method = CharField(max_length=10)
    path = CharField(max_length=500)
    full_url = TextField()
    query_params = JSONField()
    
    # Request/Response bodies
    request_body = TextField()
    response_body = TextField()
    
    # Performance
    status_code = IntegerField()
    duration_ms = DecimalField()
    
    # User context
    user = ForeignKey(User)
    ip_address = GenericIPAddressField()
    user_agent = TextField()
    headers = JSONField()
    
    # Timestamps
    timestamp = DateTimeField(default=timezone.now)
```

### ErrorLog

Captures exceptions and errors:

```python
class ErrorLog(models.Model):
    error_type = CharField(max_length=100)
    error_message = TextField()
    stack_trace = TextField()
    path = CharField(max_length=500)
    method = CharField(max_length=10)
    user = ForeignKey(User)
    is_resolved = BooleanField(default=False)
    timestamp = DateTimeField(default=timezone.now)
```

### PerformanceLog

Records performance metrics:

```python
class PerformanceLog(models.Model):
    metric_name = CharField(max_length=100)
    metric_value = DecimalField()
    metric_unit = CharField(max_length=20)
    operation = CharField(max_length=200)
    endpoint = CharField(max_length=500)
    threshold_exceeded = BooleanField()
    metadata = JSONField()
    timestamp = DateTimeField(default=timezone.now)
```

## Usage Examples

### Viewing Logs in Django Admin

All logs are automatically available in the Django admin:

1. Go to `/admin/`
2. Navigate to **App Logs** section
3. View **API Request Logs**, **Error Logs**, or **Performance Logs**

### Querying Logs Programmatically

```python
from app_logs.models import APIRequestLog, ErrorLog, PerformanceLog

# Get recent API requests
recent_requests = APIRequestLog.objects.filter(
    timestamp__gte=timezone.now() - timedelta(hours=24)
).order_by('-timestamp')

# Get error logs for specific user
user_errors = ErrorLog.objects.filter(
    user=user,
    is_resolved=False
).order_by('-timestamp')

# Get slow requests
slow_requests = PerformanceLog.objects.filter(
    metric_name='response_time',
    threshold_exceeded=True
).order_by('-timestamp')
```

### Analytics Queries

```python
from django.db.models import Count, Avg
from datetime import timedelta

# Request statistics
stats = APIRequestLog.objects.aggregate(
    total_requests=Count('id'),
    avg_response_time=Avg('duration_ms'),
    successful_requests=Count('id', filter=Q(status_code__lt=400)),
    errors=Count('id', filter=Q(status_code__gte=400))
)

# Popular endpoints
popular_endpoints = APIRequestLog.objects.values('path').annotate(
    request_count=Count('id')
).order_by('-request_count')[:10]

# User activity
user_activity = APIRequestLog.objects.filter(
    user__isnull=False
).values('user__username').annotate(
    request_count=Count('id')
).order_by('-request_count')
```

## Security Considerations

### Sensitive Headers Filtered

The following headers are automatically excluded from logging:

- `HTTP_AUTHORIZATION`
- `HTTP_COOKIE`
- `HTTP_X_FORWARDED_FOR`
- `CSRF_COOKIE`
- `SESSION_KEY`
- `REMOTE_ADDR`

### Request Body Handling

- Only JSON request bodies are logged
- Binary data is replaced with `[Binary or invalid data]`
- Form data is converted to JSON representation
- Size limits prevent database bloat

### IP Address Privacy

- IP addresses are stored for security monitoring
- Consider data retention policies for GDPR compliance
- Implement IP anonymization if required

## Performance Considerations

### Database Impact

- Uses efficient database indexes for common queries
- Response body logging is size-limited
- Consider partitioning large log tables
- Implement log rotation/cleanup procedures

### Memory Usage

- Minimal memory overhead per request
- Headers and bodies are processed on-demand
- Performance monitoring uses psutil when available

### Recommended Cleanup

Implement regular log cleanup to prevent database growth:

```python
# Example cleanup task (add to celery/cron)
from datetime import timedelta
from django.utils import timezone

# Keep logs for 90 days
cutoff_date = timezone.now() - timedelta(days=90)

APIRequestLog.objects.filter(timestamp__lt=cutoff_date).delete()
ErrorLog.objects.filter(timestamp__lt=cutoff_date).delete()
PerformanceLog.objects.filter(timestamp__lt=cutoff_date).delete()
```

## Testing

A test script is provided to verify middleware functionality:

```bash
python test_logging_middleware.py
```

This script will:
- Clear existing logs
- Make various API requests
- Verify logging functionality
- Display statistics
- Test different request types

## Troubleshooting

### Common Issues

1. **Middleware not logging requests**
   - Check middleware order in settings
   - Verify app_logs is in INSTALLED_APPS
   - Check endpoint patterns match your URLs

2. **Performance issues**
   - Review log cleanup policies
   - Check database indexes
   - Consider disabling body logging for high-traffic endpoints

3. **Missing request bodies**
   - Ensure Content-Type is application/json
   - Check request body size limits
   - Verify JSON is valid

### Debug Information

Enable debug logging to see middleware activity:

```python
# settings.py
LOGGING = {
    'loggers': {
        'app_logs.middleware': {
            'level': 'DEBUG',
            'handlers': ['console'],
        },
    },
}
```

## API Integration

### Custom Logging

You can extend the middleware for custom logging needs:

```python
from app_logs.models import ApplicationLog

# Custom application event logging
ApplicationLog.objects.create(
    level='INFO',
    event_type='BUSINESS_LOGIC',
    message='User performed important action',
    category='user_actions',
    user=request.user,
    context_data={'action': 'data_export', 'records': 100}
)
```

### Monitoring Integration

The logs can be integrated with monitoring systems:

- Export to ELK stack for analysis
- Create alerts for error patterns
- Monitor performance trends
- Generate usage reports

## Support

For issues or questions about the logging middleware:

1. Check the Django admin for logged data
2. Review the test script output
3. Enable debug logging for detailed information
4. Verify middleware configuration and order
