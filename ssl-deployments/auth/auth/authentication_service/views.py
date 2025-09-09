"""
Main views for the authentication service.
"""
from django.http import JsonResponse
from django.db import connection
import logging
import time

logger = logging.getLogger(__name__)

def health_check(request):
    """
    Basic health check endpoint.
    Returns 200 if the service is running.
    """
    return JsonResponse({
        'status': 'healthy',
        'service': 'authentication_service',
        'timestamp': time.time()
    })

def readiness_check(request):
    """
    Readiness check endpoint.
    Returns 200 if the service is ready to accept requests.
    Checks database connectivity and other dependencies.
    """
    checks = {
        'database': False,
        'status': 'not_ready'
    }
    
    try:
        # Check database connection
        with connection.cursor() as cursor:
            cursor.execute("SELECT 1")
            checks['database'] = True
            
        # All checks passed
        checks['status'] = 'ready'
        status_code = 200
        
    except Exception as e:
        logger.error(f"Readiness check failed: {str(e)}")
        status_code = 503
        
    checks['timestamp'] = time.time()
    return JsonResponse(checks, status=status_code)

def liveness_check(request):
    """
    Liveness check endpoint.
    Returns 200 if the service is alive.
    """
    return JsonResponse({
        'status': 'alive',
        'service': 'authentication_service',
        'timestamp': time.time()
    })

# Import views from individual apps for centralized routing
from user.views import *
# from buyer.views import *  # Commented out due to dependencies
# from seller.views import *  # Commented out due to GDAL dependency
from otp.views import *
