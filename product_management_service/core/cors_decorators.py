"""
CORS decorators for Flutter web compatibility.
"""

from functools import wraps
from django.http import JsonResponse
from django.utils.decorators import method_decorator
from django.views.decorators.csrf import csrf_exempt


def cors_enabled(view_func):
    """
    Decorator to add CORS headers to view responses.
    Specifically designed for Flutter web compatibility.
    """
    @wraps(view_func)
    def _wrapped_view(request, *args, **kwargs):
        # Handle preflight OPTIONS requests
        if request.method == 'OPTIONS':
            response = JsonResponse({})
            response['Access-Control-Allow-Origin'] = '*'
            response['Access-Control-Allow-Methods'] = 'GET, POST, PUT, PATCH, DELETE, OPTIONS'
            response['Access-Control-Allow-Headers'] = (
                'accept, accept-encoding, authorization, content-type, dnt, '
                'origin, user-agent, x-csrftoken, x-requested-with'
            )
            response['Access-Control-Max-Age'] = '86400'
            response['Access-Control-Allow-Credentials'] = 'true'
            return response
        
        # Process normal request
        response = view_func(request, *args, **kwargs)
        
        # Add CORS headers to the response
        response['Access-Control-Allow-Origin'] = '*'
        response['Access-Control-Allow-Credentials'] = 'true'
        response['Access-Control-Expose-Headers'] = 'content-type, x-csrftoken'
        
        return response
    
    return _wrapped_view


def api_cors_enabled(cls):
    """
    Class decorator to add CORS support to all methods of a DRF ViewSet.
    """
    # Apply CSRF exemption and CORS to dispatch method
    cls.dispatch = method_decorator(csrf_exempt)(cls.dispatch)
    cls.dispatch = method_decorator(cors_enabled)(cls.dispatch)
    
    return cls


class CORSMixin:
    """
    Mixin to add CORS headers to DRF ViewSets.
    """
    
    def dispatch(self, request, *args, **kwargs):
        """Override dispatch to add CORS headers."""
        # Handle preflight requests
        if request.method == 'OPTIONS':
            response = JsonResponse({})
            self._add_cors_headers(response, request)
            return response
        
        # Process normal request
        response = super().dispatch(request, *args, **kwargs)
        self._add_cors_headers(response, request)
        return response
    
    def _add_cors_headers(self, response, request):
        """Add CORS headers to response."""
        origin = request.META.get('HTTP_ORIGIN', '*')
        
        # Allow all origins for development
        response['Access-Control-Allow-Origin'] = '*'
        response['Access-Control-Allow-Credentials'] = 'true'
        response['Access-Control-Allow-Methods'] = 'GET, POST, PUT, PATCH, DELETE, OPTIONS'
        response['Access-Control-Allow-Headers'] = (
            'accept, accept-encoding, authorization, content-type, dnt, '
            'origin, user-agent, x-csrftoken, x-requested-with, '
            'access-control-allow-origin, access-control-allow-headers, '
            'access-control-allow-methods'
        )
        response['Access-Control-Expose-Headers'] = 'content-type, x-csrftoken'
        response['Access-Control-Max-Age'] = '86400'
        
        return response
