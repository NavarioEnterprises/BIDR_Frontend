import time
import json
import logging
from django.utils.deprecation import MiddlewareMixin
from django.contrib.auth.models import AnonymousUser
from django.http import JsonResponse
from django.db import transaction
from .models import APIRequestLog, ErrorLog, ApplicationLog, LogLevel, EventType

logger = logging.getLogger(__name__)


class APILoggingMiddleware(MiddlewareMixin):
    """
    Middleware to automatically log all API requests to the APIRequestLog model.
    Captures request details, response status, timing, and user information.
    """
    
    def __init__(self, get_response):
        self.get_response = get_response
        super().__init__(get_response)
    
    def process_request(self, request):
        """
        Called on each request, before Django decides which view to execute.
        Store the start time for performance measurement.
        """
        request._api_logging_start_time = time.time()
        return None
    
    def process_response(self, request, response):
        """
        Called after the view has been called and response is ready.
        Log the API request details to the database.
        """
        # Only log API endpoints (those that return JSON or have /api/ in path)
        if self._should_log_request(request, response):
            self._log_api_request(request, response)
        
        return response
    
    def process_exception(self, request, exception):
        """
        Called when a view raises an exception.
        Log the error and continue with normal exception handling.
        """
        if self._should_log_request(request, None):
            # Log the exception as an error
            try:
                with transaction.atomic():
                    ErrorLog.objects.create(
                        error_type=type(exception).__name__,
                        error_message=str(exception),
                        stack_trace=self._get_stack_trace(exception),
                        path=request.path,
                        method=request.method,
                        user=request.user if hasattr(request, 'user') and not isinstance(request.user, AnonymousUser) else None,
                        is_resolved=False
                    )
            except Exception as e:
                logger.error(f"Failed to log exception: {e}")
        
        return None  # Let Django handle the exception normally
    
    def _should_log_request(self, request, response):
        """
        Determine if this request should be logged.
        Log API requests, JSON responses, or specific paths.
        """
        # Skip static files and admin media
        if request.path.startswith(('/static/', '/media/', '/admin/jsi18n/')):
            return False
        
        # Skip health check endpoints
        if request.path in ['/health/', '/ping/', '/status/']:
            return False
        
        # Log if path contains 'api' or response is JSON
        is_api_path = '/api/' in request.path or request.path.startswith('/api/')
        is_json_response = response and response.get('Content-Type', '').startswith('application/json')
        
        # Also log our specific app endpoints
        app_endpoints = ['/product-requests/', '/categories/', '/analytics/', '/core/']
        is_app_endpoint = any(request.path.startswith(endpoint) for endpoint in app_endpoints)
        
        return is_api_path or is_json_response or is_app_endpoint
    
    def _log_api_request(self, request, response):
        """
        Create an APIRequestLog entry for this request.
        """
        try:
            with transaction.atomic():
                # Calculate response time
                start_time = getattr(request, '_api_logging_start_time', time.time())
                response_time = time.time() - start_time
                
                # Get request body safely
                request_body = self._get_request_body(request)
                
                # Get response body safely
                response_body = self._get_response_body(response)
                
                # Determine user
                user = None
                if hasattr(request, 'user') and not isinstance(request.user, AnonymousUser):
                    user = request.user
                
                # Create API request log entry
                APIRequestLog.objects.create(
                    path=request.path,
                    full_url=request.build_absolute_uri(),
                    method=request.method,
                    user=user,
                    ip_address=self._get_client_ip(request),
                    user_agent=request.META.get('HTTP_USER_AGENT', ''),
                    request_body=request_body,
                    status_code=response.status_code if response else 500,
                    response_body=response_body,
                    duration_ms=response_time * 1000,  # Convert to milliseconds
                    query_params=dict(request.GET) if request.GET else None,
                    headers=self._get_filtered_headers(request)
                )
                
                # Create application log entry
                self._create_application_log(request, response, user, response_time)
                
        except Exception as e:
            # Log the error but don't break the request
            logger.error(f"Failed to log API request: {e}")
    
    def _get_request_body(self, request):
        """
        Safely extract request body as JSON string.
        """
        try:
            if hasattr(request, 'body') and request.body:
                body = request.body.decode('utf-8')
                # Try to parse as JSON to validate format
                if request.content_type == 'application/json':
                    json.loads(body)  # Validate JSON
                    return body
                else:
                    # For form data, convert to dict representation
                    if hasattr(request, 'POST') and request.POST:
                        return json.dumps(dict(request.POST))
            return None
        except (UnicodeDecodeError, json.JSONDecodeError, Exception):
            return "[Binary or invalid data]"
    
    def _get_response_body(self, response):
        """
        Safely extract response body as JSON string.
        """
        try:
            if response and hasattr(response, 'content'):
                content = response.content.decode('utf-8')
                # Only store if it's JSON and not too large
                if (response.get('Content-Type', '').startswith('application/json') and 
                    len(content) < 10000):  # Limit size to 10KB
                    json.loads(content)  # Validate JSON
                    return content
            return None
        except (UnicodeDecodeError, json.JSONDecodeError, Exception):
            return "[Binary or invalid response data]"
    
    def _get_client_ip(self, request):
        """
        Get the client's IP address from request headers.
        """
        x_forwarded_for = request.META.get('HTTP_X_FORWARDED_FOR')
        if x_forwarded_for:
            ip = x_forwarded_for.split(',')[0].strip()
        else:
            ip = request.META.get('REMOTE_ADDR', '')
        return ip
    
    def _get_stack_trace(self, exception):
        """
        Get stack trace from exception.
        """
        import traceback
        return traceback.format_exc()
    
    def _get_filtered_headers(self, request):
        """
        Get filtered request headers, excluding sensitive information.
        """
        headers = dict(request.META)
        # Filter out sensitive headers
        sensitive_headers = [
            'HTTP_AUTHORIZATION', 'HTTP_COOKIE', 'HTTP_X_FORWARDED_FOR',
            'CSRF_COOKIE', 'SESSION_KEY', 'REMOTE_ADDR'
        ]
        
        filtered_headers = {}
        for key, value in headers.items():
            if key.startswith('HTTP_') and key not in sensitive_headers:
                # Convert HTTP_HEADER_NAME to Header-Name
                header_name = key[5:].replace('_', '-').title()
                filtered_headers[header_name] = value
        
        return filtered_headers
    
    def _create_application_log(self, request, response, user, response_time):
        """
        Create an application log entry for this request.
        """
        try:
            # Determine log level based on response status
            status_code = response.status_code if response else 500
            
            if status_code >= 500:
                level = LogLevel.ERROR
                event_type = EventType.ERROR_EVENT
                message = f"Server error {status_code} for {request.method} {request.path}"
            elif status_code >= 400:
                level = LogLevel.WARNING
                event_type = EventType.USER_ACTION
                message = f"Client error {status_code} for {request.method} {request.path}"
            elif status_code >= 300:
                level = LogLevel.INFO
                event_type = EventType.API_REQUEST
                message = f"Redirect {status_code} for {request.method} {request.path}"
            else:
                level = LogLevel.INFO
                event_type = EventType.API_REQUEST
                message = f"Successful {request.method} request to {request.path}"
            
            # Determine category based on request path
            category = self._get_request_category(request.path)
            
            # Create context data
            context_data = {
                'method': request.method,
                'path': request.path,
                'status_code': status_code,
                'response_time_ms': response_time * 1000,
                'user_agent': request.META.get('HTTP_USER_AGENT', ''),
                'ip_address': self._get_client_ip(request),
            }
            
            # Add query parameters if present
            if request.GET:
                context_data['query_params'] = dict(request.GET)
            
            # Add user information if available
            if user:
                context_data['username'] = user.username
                context_data['user_id'] = user.id
            
            # Create application log
            ApplicationLog.objects.create(
                level=level,
                event_type=event_type,
                message=message,
                category=category,
                subcategory=self._get_request_subcategory(request.path, request.method),
                context_data=context_data,
                user=user,
                ip_address=self._get_client_ip(request),
                session_id=request.session.session_key if hasattr(request, 'session') and request.session.session_key else None,
                execution_time_ms=response_time * 1000
            )
            
        except Exception as e:
            logger.error(f"Failed to create application log: {e}")
    
    def _get_request_category(self, path):
        """
        Determine the category based on the request path.
        """
        if path.startswith('/product-requests/'):
            return 'product_requests'
        elif path.startswith('/categories/'):
            return 'categories'
        elif path.startswith('/analytics/'):
            return 'analytics'
        elif path.startswith('/api/token'):
            return 'authentication'
        elif path.startswith('/admin/'):
            return 'admin'
        elif path.startswith('/api/'):
            return 'api'
        else:
            return 'general'
    
    def _get_request_subcategory(self, path, method):
        """
        Determine the subcategory based on the request path and method.
        """
        if '/requests/' in path:
            if method == 'GET':
                return 'list_requests' if path.endswith('/') else 'retrieve_request'
            elif method == 'POST':
                return 'create_request'
            elif method in ['PUT', 'PATCH']:
                return 'update_request'
            elif method == 'DELETE':
                return 'delete_request'
        elif '/categories/' in path:
            if method == 'GET':
                return 'list_categories' if path.endswith('/') else 'retrieve_category'
            elif method == 'POST':
                return 'create_category'
            elif method in ['PUT', 'PATCH']:
                return 'update_category'
            elif method == 'DELETE':
                return 'delete_category'
        elif '/analytics/' in path:
            return 'analytics_query'
        elif '/token' in path:
            if 'refresh' in path:
                return 'token_refresh'
            elif 'blacklist' in path:
                return 'token_blacklist'
            else:
                return 'token_obtain'
        
        return method.lower()


class PerformanceLoggingMiddleware(MiddlewareMixin):
    """
    Middleware to log slow requests for performance monitoring.
    """
    
    def __init__(self, get_response):
        self.get_response = get_response
        self.slow_request_threshold = 2.0  # Log requests taking more than 2 seconds
        super().__init__(get_response)
    
    def process_request(self, request):
        request._perf_logging_start_time = time.time()
        return None
    
    def process_response(self, request, response):
        if hasattr(request, '_perf_logging_start_time'):
            response_time = time.time() - request._perf_logging_start_time
            
            # Log slow requests
            if response_time > self.slow_request_threshold:
                self._log_slow_request(request, response, response_time)
        
        return response
    
    def _log_slow_request(self, request, response, response_time):
        """
        Log slow requests to PerformanceLog model.
        """
        try:
            from .models import PerformanceLog
            
            with transaction.atomic():
                PerformanceLog.objects.create(
                    metric_name='response_time',
                    metric_value=response_time * 1000,  # Convert to milliseconds
                    metric_unit='ms',
                    operation=f"{request.method} {request.path}",
                    endpoint=request.path,
                    threshold_exceeded=True,  # Since we only log slow requests
                    severity='WARNING',
                    metadata={
                        'endpoint': request.path,
                        'method': request.method,
                        'status_code': response.status_code if response else 500,
                        'user': str(request.user) if hasattr(request, 'user') else 'Anonymous',
                        'memory_usage_mb': self._get_memory_usage(),
                        'cpu_usage_percent': self._get_cpu_usage(),
                        'threshold_seconds': self.slow_request_threshold
                    }
                )
        except Exception as e:
            logger.error(f"Failed to log slow request: {e}")
    
    def _get_memory_usage(self):
        """
        Get current memory usage in MB.
        """
        try:
            import psutil
            import os
            process = psutil.Process(os.getpid())
            return round(process.memory_info().rss / 1024 / 1024, 2)  # MB
        except ImportError:
            return 0.0
    
    def _get_cpu_usage(self):
        """
        Get current CPU usage percentage.
        """
        try:
            import psutil
            return psutil.cpu_percent(interval=0.1)
        except ImportError:
            return 0.0
