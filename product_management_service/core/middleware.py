"""
Custom middleware for BIDR Core application.
"""
from django.conf import settings
from django.utils.deprecation import MiddlewareMixin


class CSPMiddleware(MiddlewareMixin):
    """
    Middleware to add Content Security Policy headers.
    """
    
    def process_response(self, request, response):
        """Add CSP headers to response."""
        if hasattr(settings, 'CSP_DEFAULT_SRC'):
            # Add CSP headers to allow localhost connections
            csp_policy = f"default-src {settings.CSP_DEFAULT_SRC}; " \
                        f"connect-src {settings.CSP_CONNECT_SRC}; " \
                        f"script-src {settings.CSP_SCRIPT_SRC}; " \
                        f"style-src {settings.CSP_STYLE_SRC}; " \
                        f"img-src {settings.CSP_IMG_SRC}; " \
                        f"font-src {settings.CSP_FONT_SRC}; " \
                        f"frame-src {settings.CSP_FRAME_SRC}; " \
                        f"worker-src {settings.CSP_WORKER_SRC};"
            
            response['Content-Security-Policy'] = csp_policy
        
        return response


class CORSMiddleware(MiddlewareMixin):
    """
    Enhanced CORS middleware for development.
    """
    
    def process_response(self, request, response):
        """Add CORS headers for development."""
        if settings.DEBUG:
            response['Access-Control-Allow-Origin'] = '*'
            response['Access-Control-Allow-Methods'] = 'GET, POST, PUT, DELETE, OPTIONS, PATCH'
            response['Access-Control-Allow-Headers'] = 'Accept, Authorization, Content-Type, X-Requested-With, X-CSRFToken'
            response['Access-Control-Allow-Credentials'] = 'true'
            response['Access-Control-Max-Age'] = '3600'
            
        return response
