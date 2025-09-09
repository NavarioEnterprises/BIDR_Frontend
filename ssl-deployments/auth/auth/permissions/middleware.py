import logging
import json

from django.http import JsonResponse
from django.utils.deprecation import MiddlewareMixin
from django.utils import timezone

from import_helper import setup_imports
setup_imports()
from admin.models import AdminActivityLog

logger = logging.getLogger(__name__)


class RoleBasedAccessMiddleware(MiddlewareMixin):
    """
    Middleware to enforce role-based access control across the application
    """

    # Define role-based access rules
    ROLE_PERMISSIONS = {
        'administrator': {
            'can_access_admin': True,
            'can_manage_users': True,
            'can_approve_sellers': True,
            'can_access_financial_data': True,
            'can_moderate_content': True,
            'can_view_audit_logs': True,
        },
        'seller': {
            'can_access_admin': False,
            'can_manage_users': False,
            'can_approve_sellers': False,
            'can_access_financial_data': False,
            'can_moderate_content': False,
            'can_view_audit_logs': False,
        },
        'buyer': {
            'can_access_admin': False,
            'can_manage_users': False,
            'can_approve_sellers': False,
            'can_access_financial_data': False,
            'can_moderate_content': False,
            'can_view_audit_logs': False,
        }
    }

    # Admin-only endpoints
    ADMIN_ONLY_PATHS = [
        '/authentication/admin/document-vetting/<int:vetting_id>/',
        '/authentication/admin/document-vetting/',
    ]

    def process_request(self, request):
        """
        Process incoming requests for role-based access control
        """
        # Skip for unauthenticated requests to public endpoints
        if not request.user.is_authenticated:
            return None

        # Check for admin-only paths
        for admin_path in self.ADMIN_ONLY_PATHS:
            if request.path.startswith(admin_path):
                if not self.has_admin_access(request.user):
                    return JsonResponse({
                        'error': 'Access denied. Administrator privileges required.',
                        'code': 'ADMIN_ACCESS_REQUIRED'
                    }, status=403)

        # Add user permissions to request for easy access in views
        request.user_permissions = self.get_user_permissions(request.user)

        return None

    def has_admin_access(self, user):
        """
        Check if user has administrator access
        """
        return (
                user.is_superuser or
                user.role == 'administrator' or
                user.is_staff
        )

    def get_user_permissions(self, user):
        """
        Get user permissions based on role
        """
        if user.is_superuser:
            # Superusers have all permissions
            return {key: True for key in self.ROLE_PERMISSIONS['administrator'].keys()}

        return self.ROLE_PERMISSIONS.get(user.role, {})


class SecurityMiddleware(MiddlewareMixin):
    """
    Enhanced security middleware for authentication system
    """

    def process_request(self, request):
        """
        Process security checks for incoming requests
        """
        # Add security headers
        self.add_security_headers(request)

        # Check for suspicious activity
        if self.is_suspicious_request(request):
            logger.warning(f"Suspicious request detected: {request.META.get('REMOTE_ADDR')} - {request.path}")

        # Rate limiting check (basic implementation)
        if self.is_rate_limited(request):
            return JsonResponse({
                'error': 'Rate limit exceeded. Please try again later.',
                'code': 'RATE_LIMIT_EXCEEDED'
            }, status=429)

        return None

    def process_response(self, request, response):
        """
        Add security headers to response
        """
        # Add security headers
        response['X-Content-Type-Options'] = 'nosniff'
        response['X-Frame-Options'] = 'DENY'
        response['X-XSS-Protection'] = '1; mode=block'
        response['Referrer-Policy'] = 'strict-origin-when-cross-origin'

        # Add HSTS header for HTTPS
        if request.is_secure():
            response['Strict-Transport-Security'] = 'max-age=31536000; includeSubDomains'

        return response

    def add_security_headers(self, request):
        """
        Add security-related information to request
        """
        request.client_ip = self.get_client_ip(request)
        request.user_agent = request.META.get('HTTP_USER_AGENT', '')

    def get_client_ip(self, request):
        """
        Get client IP address from request
        """
        x_forwarded_for = request.META.get('HTTP_X_FORWARDED_FOR')
        if x_forwarded_for:
            ip = x_forwarded_for.split(',')[0]
        else:
            ip = request.META.get('REMOTE_ADDR')
        return ip

    def is_suspicious_request(self, request):
        """
        Basic suspicious activity detection
        """
        # Check for common attack patterns
        suspicious_patterns = [
            'script', 'javascript:', 'vbscript:', 'onload=', 'onerror=',
            'eval(', 'alert(', 'document.cookie', 'union select',
            'drop table', 'insert into', 'delete from'
        ]

        query_string = request.META.get('QUERY_STRING', '').lower()
        path = request.path.lower()

        for pattern in suspicious_patterns:
            if pattern in query_string or pattern in path:
                return True

        return False

    def is_rate_limited(self, request):
        """
        Basic rate limiting implementation
        """
        # This is a simple implementation - in production, use Redis or similar
        # For now, just return False
        return False


class AuditLoggingMiddleware(MiddlewareMixin):
    """
    Middleware for comprehensive audit logging
    """

    # Actions that should be logged
    LOGGED_ACTIONS = [
        'POST', 'PUT', 'PATCH', 'DELETE'
    ]

    # Sensitive paths that should always be logged
    SENSITIVE_PATHS = [
        '/authentication/login/',
        '/authentication/logout/',
        '/authentication/admin/document-vetting/',
    ]

    def process_request(self, request):
        """
        Log request details for audit purposes
        """
        # Store request start time
        request._audit_start_time = timezone.now()

        # Log sensitive operations
        if self.should_log_request(request):
            self.log_request(request)

        return None

    def process_response(self, request, response):
        """
        Log response details for audit purposes
        """
        if self.should_log_request(request):
            self.log_response(request, response)

        return response

    def should_log_request(self, request):
        """
        Determine if request should be logged
        """
        # Log all authenticated user actions
        if request.user.is_authenticated:
            # Always log admin actions
            if request.user.role == 'administrator':
                return True

            # Log specific HTTP methods
            if request.method in self.LOGGED_ACTIONS:
                return True

            # Log sensitive paths
            for path in self.SENSITIVE_PATHS:
                if request.path.startswith(path):
                    return True

        return False

    def log_request(self, request):
        """
        Log request details
        """
        try:
            log_data = {
                'timestamp': timezone.now().isoformat(),
                'user': request.user.email if request.user.is_authenticated else 'anonymous',
                'method': request.method,
                'path': request.path,
                'ip_address': getattr(request, 'client_ip', 'unknown'),
                'user_agent': getattr(request, 'user_agent', 'unknown'),
                'query_params': dict(request.GET),
            }

            # Log to file or external service
            logger.info(f"AUDIT_REQUEST: {json.dumps(log_data)}")

            # Store in database for admin user
            if (request.user.is_authenticated and
                    request.user.role == 'administrator' and
                    hasattr(request.user, 'admin_profile')):
                self.create_admin_activity_log(request, 'request_logged')

        except Exception as e:
            logger.error(f"Failed to log request: {e}")

    def log_response(self, request, response):
        """
        Log response details
        """
        try:
            duration = None
            if hasattr(request, '_audit_start_time'):
                duration = (timezone.now() - request._audit_start_time).total_seconds()

            log_data = {
                'timestamp': timezone.now().isoformat(),
                'user': request.user.email if request.user.is_authenticated else 'anonymous',
                'method': request.method,
                'path': request.path,
                'status_code': response.status_code,
                'duration_seconds': duration,
            }

            logger.info(f"AUDIT_RESPONSE: {json.dumps(log_data)}")

        except Exception as e:
            logger.error(f"Failed to log response: {e}")

    def create_admin_activity_log(self, request, action):
        """
        Create admin activity log entry
        """
        try:
            if hasattr(request.user, 'admin_profile'):
                AdminActivityLog.objects.create(
                    admin=request.user.admin_profile,
                    action=action,
                    description=f"{request.method} {request.path}",
                    ip_address=getattr(request, 'client_ip', 'unknown'),
                    user_agent=getattr(request, 'user_agent', 'unknown'),
                    additional_data={
                        'query_params': dict(request.GET),
                        'timestamp': timezone.now().isoformat(),
                    }
                )
        except Exception as e:
            logger.error(f"Failed to create admin activity log: {e}")


class GeographicSecurityMiddleware(MiddlewareMixin):
    """
    Middleware for geographic-based security features
    """

    def process_request(self, request):
        """
        Add geographic context to request
        """
        # Add geographic information for location-based features
        request.geographic_context = self.get_geographic_context(request)

        return None

    def get_geographic_context(self, request):
        """
        Extract geographic context from request
        """
        # This could integrate with IP geolocation services
        return {
            'ip_address': getattr(request, 'client_ip', 'unknown'),
            'country': 'unknown',  # Would be populated by geolocation service
            'region': 'unknown',  # Would be populated by geolocation service
            'city': 'unknown',  # Would be populated by geolocation service
        }

