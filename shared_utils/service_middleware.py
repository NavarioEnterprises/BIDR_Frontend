"""
Service Authentication Middleware for BIDR Microservices
========================================================

This middleware handles authentication for service-to-service communication
and ensures secure inter-service API calls.
"""

import jwt
import logging
from django.http import JsonResponse
from django.conf import settings
from django.utils.deprecation import MiddlewareMixin
from typing import Optional, Dict, Any
from functools import wraps
import time
from decouple import config

logger = logging.getLogger(__name__)


class ServiceAuthenticationMiddleware(MiddlewareMixin):
    """
    Middleware for authenticating service-to-service requests.
    
    This middleware validates JWT tokens for requests coming from other
    BIDR microservices and provides service-level authentication.
    """
    
    # Service authentication header
    SERVICE_AUTH_HEADER = 'HTTP_X_SERVICE_TOKEN'
    SERVICE_NAME_HEADER = 'HTTP_X_SERVICE_NAME'
    
    # Paths that require service authentication
    SERVICE_AUTH_PATHS = [
        '/api/v1/internal/',  # Internal API endpoints
        '/service/',          # Service-specific endpoints
    ]
    
    # Paths that should be excluded from service auth
    EXCLUDED_PATHS = [
        '/health/',
        '/admin/',
        '/api/auth/login/',
        '/api/auth/register/',
    ]
    
    def __init__(self, get_response):
        self.get_response = get_response
        self.service_secret = config('SERVICE_SECRET_KEY', default=settings.SECRET_KEY)
        super().__init__(get_response)
    
    def process_request(self, request):
        """Process incoming request for service authentication."""
        
        # Skip authentication for excluded paths
        if self._is_excluded_path(request.path):
            return None
        
        # Check if this path requires service authentication
        if not self._requires_service_auth(request.path):
            return None
        
        # Extract service token from headers
        service_token = request.META.get(self.SERVICE_AUTH_HEADER)
        service_name = request.META.get(self.SERVICE_NAME_HEADER)
        
        if not service_token:
            logger.warning(f"Missing service token for path: {request.path}")
            return JsonResponse({
                'error': 'Service authentication required',
                'code': 'SERVICE_AUTH_REQUIRED'
            }, status=401)
        
        # Validate service token
        try:
            payload = self._validate_service_token(service_token)
            
            # Add service information to request
            request.service_name = payload.get('service_name', service_name)
            request.service_user = payload.get('user_id')
            request.is_service_request = True
            
            logger.info(f"Authenticated service request from: {request.service_name}")
            
        except jwt.InvalidTokenError as e:
            logger.error(f"Invalid service token: {str(e)}")
            return JsonResponse({
                'error': 'Invalid service token',
                'code': 'INVALID_SERVICE_TOKEN'
            }, status=401)
        except Exception as e:
            logger.error(f"Service authentication error: {str(e)}")
            return JsonResponse({
                'error': 'Service authentication failed',
                'code': 'SERVICE_AUTH_ERROR'
            }, status=500)
        
        return None
    
    def _is_excluded_path(self, path: str) -> bool:
        """Check if path is excluded from service authentication."""
        return any(path.startswith(excluded) for excluded in self.EXCLUDED_PATHS)
    
    def _requires_service_auth(self, path: str) -> bool:
        """Check if path requires service authentication."""
        return any(path.startswith(service_path) for service_path in self.SERVICE_AUTH_PATHS)
    
    def _validate_service_token(self, token: str) -> Dict[str, Any]:
        """Validate service JWT token."""
        try:
            # Decode JWT token
            payload = jwt.decode(
                token,
                self.service_secret,
                algorithms=['HS256']
            )
            
            # Check token expiration
            if 'exp' in payload and payload['exp'] < time.time():
                raise jwt.ExpiredSignatureError('Service token expired')
            
            # Validate required fields
            required_fields = ['service_name', 'iat']
            for field in required_fields:
                if field not in payload:
                    raise jwt.InvalidTokenError(f'Missing required field: {field}')
            
            return payload
            
        except jwt.ExpiredSignatureError:
            raise jwt.InvalidTokenError('Service token expired')
        except jwt.InvalidTokenError:
            raise
        except Exception as e:
            raise jwt.InvalidTokenError(f'Token validation error: {str(e)}')


class ServiceTokenGenerator:
    """Generate JWT tokens for service-to-service authentication."""
    
    def __init__(self, secret_key: str = None):
        self.secret_key = secret_key or config('SERVICE_SECRET_KEY', default=settings.SECRET_KEY)
    
    def generate_service_token(
        self,
        service_name: str,
        user_id: Optional[int] = None,
        expires_in: int = 3600  # 1 hour default
    ) -> str:
        """
        Generate a JWT token for service authentication.
        
        Args:
            service_name: Name of the service making the request
            user_id: Optional user ID if request is on behalf of a user
            expires_in: Token expiration time in seconds
            
        Returns:
            JWT token string
        """
        now = time.time()
        payload = {
            'service_name': service_name,
            'iat': now,
            'exp': now + expires_in,
            'type': 'service_token'
        }
        
        if user_id:
            payload['user_id'] = user_id
        
        return jwt.encode(payload, self.secret_key, algorithm='HS256')
    
    def validate_token(self, token: str) -> Dict[str, Any]:
        """Validate a service token."""
        try:
            payload = jwt.decode(token, self.secret_key, algorithms=['HS256'])
            
            # Check if it's a service token
            if payload.get('type') != 'service_token':
                raise jwt.InvalidTokenError('Invalid token type')
            
            return payload
            
        except jwt.InvalidTokenError:
            raise
        except Exception as e:
            raise jwt.InvalidTokenError(f'Token validation error: {str(e)}')


def service_required(service_names: Optional[list] = None):
    """
    Decorator to require service authentication for API endpoints.
    
    Args:
        service_names: List of allowed service names. If None, any authenticated service is allowed.
    """
    def decorator(view_func):
        @wraps(view_func)
        def wrapper(request, *args, **kwargs):
            # Check if request is authenticated as a service
            if not hasattr(request, 'is_service_request') or not request.is_service_request:
                return JsonResponse({
                    'error': 'Service authentication required',
                    'code': 'SERVICE_AUTH_REQUIRED'
                }, status=401)
            
            # Check if service is allowed
            if service_names and request.service_name not in service_names:
                return JsonResponse({
                    'error': f'Service {request.service_name} not authorized',
                    'code': 'SERVICE_NOT_AUTHORIZED'
                }, status=403)
            
            return view_func(request, *args, **kwargs)
        
        return wrapper
    return decorator


def with_service_auth(service_name: str):
    """
    Decorator to add service authentication headers to HTTP requests.
    
    This is used when making requests TO other services.
    """
    def decorator(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            # Generate service token
            token_generator = ServiceTokenGenerator()
            service_token = token_generator.generate_service_token(service_name)
            
            # Add service authentication to headers
            if 'headers' not in kwargs:
                kwargs['headers'] = {}
            
            kwargs['headers'].update({
                'X-Service-Token': service_token,
                'X-Service-Name': service_name
            })
            
            return func(*args, **kwargs)
        
        return wrapper
    return decorator


# Global token generator instance
service_token_generator = ServiceTokenGenerator()
