"""
Security Middleware for Authentication Service

This middleware applies security measures, logging, and API management to all requests.
It ensures that all apps in the authentication service are properly secured and monitored.
"""

import time
import logging
from django.utils.deprecation import MiddlewareMixin
from django.conf import settings
from django.http import HttpResponse, JsonResponse
from django.utils import timezone

# Import the helper and set up the path
import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from import_helper import setup_imports
setup_imports()

# Now we can import from any app in the project
from security.utils import SecurityUtils
from security.models import SecurityAuditLog, APIKey
from auth_logs.models import AuthenticationLog, SecurityEvent, AuditTrail
from api_management.models import APIRequest, RateLimitBucket

logger = logging.getLogger(__name__)

class SecurityMiddleware(MiddlewareMixin):
    """
    Middleware to apply security measures, logging, and API management to all requests.
    """
    
    def __init__(self, get_response):
        self.get_response = get_response
        self.security_utils = SecurityUtils()
        
    def process_request(self, request):
        """
        Process the request before it reaches the view.
        Apply security checks, rate limiting, and logging.
        """
        # Skip security checks for static files and admin
        if request.path.startswith('/static/') or request.path.startswith('/admin/'):
            return None
            
        # Get client IP address
        ip_address = self.get_client_ip(request)
        
        # Check for blocked IPs
        if self.is_ip_blocked(ip_address):
            # Log blocked IP attempt
            self.log_security_event(
                request=request,
                event_type='BLOCKED_IP_ACCESS_ATTEMPT',
                details=f"Access attempt from blocked IP: {ip_address}"
            )
            return JsonResponse({
                'error': 'Access denied from this IP address'
            }, status=403)
            
        # Check for API key if required
        if self.requires_api_key(request.path):
            api_key = request.headers.get('X-API-Key')
            if not api_key or not self.validate_api_key(api_key, request.path, ip_address):
                # Log invalid API key attempt
                self.log_security_event(
                    request=request,
                    event_type='INVALID_API_KEY',
                    details=f"Invalid or missing API key for protected endpoint: {request.path}"
                )
                return JsonResponse({
                    'error': 'Invalid or missing API key'
                }, status=401)
                
        # Check for rate limiting
        if self.is_rate_limited(ip_address):
            # Log rate limiting event
            self.log_security_event(
                request=request,
                event_type='RATE_LIMIT_EXCEEDED',
                details=f"Rate limit exceeded for IP: {ip_address}"
            )
            return JsonResponse({
                'error': 'Rate limit exceeded. Please try again later.'
            }, status=429)
            
        # Log API request
        self.log_api_request(request, ip_address)
        
        # Store request start time for performance monitoring
        request.start_time = time.time()
        
        return None
        
    def process_response(self, request, response):
        """
        Process the response after it leaves the view.
        Update logs and apply additional security headers.
        """
        # Skip processing for static files and admin
        if request.path.startswith('/static/') or request.path.startswith('/admin/'):
            return response
            
        # Add security headers
        response = self.add_security_headers(response)
        
        # Update API request log with response status
        if hasattr(request, 'api_request_id'):
            try:
                api_request = APIRequest.objects.get(id=request.api_request_id)
                api_request.status_code = response.status_code
                api_request.response_time = time.time() - getattr(request, 'start_time', time.time())
                api_request.save()
            except Exception as e:
                logger.error(f"Error updating API request log: {str(e)}")
                
        # Log authentication success/failure if applicable
        if hasattr(request, 'user') and request.user.is_authenticated:
            if request.path.endswith('/login/') and response.status_code == 200:
                self.log_authentication(request, 'SUCCESS')
            elif request.path.endswith('/login/') and response.status_code != 200:
                self.log_authentication(request, 'FAILURE')
                
        return response
        
    def get_client_ip(self, request):
        """Get the client IP address from the request."""
        x_forwarded_for = request.META.get('HTTP_X_FORWARDED_FOR')
        if x_forwarded_for:
            ip = x_forwarded_for.split(',')[0]
        else:
            ip = request.META.get('REMOTE_ADDR', '')
        return ip
        
    def is_ip_blocked(self, ip_address):
        """Check if the IP address is blocked."""
        from security.models import BlockedIP
        try:
            blocked_ip = BlockedIP.objects.filter(ip_address=ip_address, is_active=True).first()
            return blocked_ip is not None and blocked_ip.is_active()
        except Exception as e:
            logger.error(f"Error checking blocked IP: {str(e)}")
            return False
            
    def requires_api_key(self, path):
        """Check if the path requires an API key."""
        # Define paths that require API key
        api_key_paths = [
            '/api/v1/data/',
            '/api/v1/analytics/',
            '/api/v1/export/',
        ]
        return any(path.startswith(p) for p in api_key_paths)
        
    def validate_api_key(self, api_key, path, ip_address):
        """Validate the API key for the given path and IP address."""
        try:
            key_parts = api_key.split('.')
            if len(key_parts) != 2:
                return False
                
            key_id, secret = key_parts
            api_key_obj = APIKey.objects.filter(key_id=key_id, is_active=True).first()
            
            if not api_key_obj:
                return False
                
            # Check if key is expired
            if api_key_obj.is_expired():
                return False
                
            # Check IP restrictions if any
            if not api_key_obj.can_access_ip(ip_address):
                return False
                
            # Verify the key
            if not api_key_obj.verify_key(api_key):
                return False
                
            # Update usage statistics
            api_key_obj.update_usage(ip_address)
            
            return True
        except Exception as e:
            logger.error(f"Error validating API key: {str(e)}")
            return False
            
    def is_rate_limited(self, ip_address):
        """Check if the IP address is rate limited."""
        try:
            rate_limit_bucket, created = RateLimitBucket.objects.get_or_create(
                ip_address=ip_address,
                defaults={'request_count': 0}
            )
            
            # Check if rate limited
            is_limited = rate_limit_bucket.is_rate_limited(100)  # Limit to 100 requests per bucket period
            
            # Add request to bucket
            if not is_limited:
                rate_limit_bucket.add_request()
                
            return is_limited
        except Exception as e:
            logger.error(f"Error checking rate limit: {str(e)}")
            return False
            
    def log_api_request(self, request, ip_address):
        """Log the API request."""
        try:
            # Don't log sensitive data
            request_data = ""
            if request.method in ['POST', 'PUT', 'PATCH']:
                request_data = "Request contained sensitive data - not logged"
                
            api_request = APIRequest.objects.create(
                user=request.user if hasattr(request, 'user') and request.user.is_authenticated else None,
                endpoint=request.path,
                method=request.method,
                ip_address=ip_address,
                user_agent=request.META.get('HTTP_USER_AGENT', ''),
                request_data=request_data,
                status_code=0  # Will be updated in process_response
            )
            
            # Store API request ID on the request object for later use
            request.api_request_id = api_request.id
        except Exception as e:
            logger.error(f"Error logging API request: {str(e)}")
            
    def log_security_event(self, request, event_type, details):
        """Log a security event."""
        try:
            SecurityEvent.objects.create(
                user=request.user if hasattr(request, 'user') and request.user.is_authenticated else None,
                event_type=event_type,
                ip_address=self.get_client_ip(request),
                user_agent=request.META.get('HTTP_USER_AGENT', ''),
                details=details
            )
        except Exception as e:
            logger.error(f"Error logging security event: {str(e)}")
            
    def log_authentication(self, request, status):
        """Log an authentication event."""
        try:
            AuthenticationLog.objects.create(
                user=request.user,
                ip_address=self.get_client_ip(request),
                user_agent=request.META.get('HTTP_USER_AGENT', ''),
                action='LOGIN',
                status=status,
                details=f"User login {status.lower()}"
            )
        except Exception as e:
            logger.error(f"Error logging authentication: {str(e)}")
            
    def add_security_headers(self, response):
        """Add security headers to the response."""
        # Content Security Policy
        response['Content-Security-Policy'] = "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'; img-src 'self' data:;"
        
        # Prevent MIME type sniffing
        response['X-Content-Type-Options'] = 'nosniff'
        
        # Prevent clickjacking
        response['X-Frame-Options'] = 'DENY'
        
        # Enable XSS protection
        response['X-XSS-Protection'] = '1; mode=block'
        
        # HTTP Strict Transport Security - only set when HTTPS is enabled
        if getattr(settings, 'SECURE_SSL_REDIRECT', False):
            response['Strict-Transport-Security'] = 'max-age=31536000; includeSubDomains'
        
        # Referrer Policy
        response['Referrer-Policy'] = 'strict-origin-when-cross-origin'
        
        return response
