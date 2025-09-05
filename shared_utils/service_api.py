"""
Service API Utilities and Examples for BIDR Microservices
========================================================

This module provides utilities and example implementations for
inter-service API communication in the BIDR platform.
"""

from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.views.decorators.http import require_http_methods
from django.utils.decorators import method_decorator
from django.views import View
import json
import logging
from typing import Dict, Any, Optional

from .service_middleware import service_required, service_token_generator
from .service_config import ServiceConfig, ServiceEndpoints, service_registry

logger = logging.getLogger(__name__)


class ServiceAPIResponse:
    """Standardized response format for service APIs."""
    
    @staticmethod
    def success(data: Any = None, message: str = None) -> JsonResponse:
        """Return success response."""
        response_data = {'success': True}
        if data is not None:
            response_data['data'] = data
        if message:
            response_data['message'] = message
        return JsonResponse(response_data)
    
    @staticmethod
    def error(message: str, code: str = None, status: int = 400) -> JsonResponse:
        """Return error response."""
        response_data = {
            'success': False,
            'error': message
        }
        if code:
            response_data['code'] = code
        return JsonResponse(response_data, status=status)


class AuthenticationServiceAPI:
    """API client for Authentication Service."""
    
    def __init__(self):
        self.client = service_registry.get_client('authentication')
        self.service_name = 'authentication'
    
    def verify_user_token(self, token: str) -> Dict[str, Any]:
        """Verify a user JWT token."""
        try:
            response = self.client.post('/api/v1/internal/verify-token/', {
                'token': token
            })
            return response
        except Exception as e:
            logger.error(f"Failed to verify token: {str(e)}")
            return {'success': False, 'error': str(e)}
    
    def get_user_profile(self, user_id: int) -> Dict[str, Any]:
        """Get user profile by ID."""
        try:
            response = self.client.get(f'/api/v1/internal/users/{user_id}/')
            return response
        except Exception as e:
            logger.error(f"Failed to get user profile: {str(e)}")
            return {'success': False, 'error': str(e)}
    
    def create_user_session(self, user_id: int, metadata: Dict = None) -> Dict[str, Any]:
        """Create a user session."""
        try:
            data = {'user_id': user_id}
            if metadata:
                data['metadata'] = metadata
            
            response = self.client.post('/api/v1/internal/sessions/', data)
            return response
        except Exception as e:
            logger.error(f"Failed to create session: {str(e)}")
            return {'success': False, 'error': str(e)}


class ProductManagementServiceAPI:
    """API client for Product Management Service."""
    
    def __init__(self):
        self.client = service_registry.get_client('product_management')
        self.service_name = 'product_management'
    
    def get_product(self, product_id: int) -> Dict[str, Any]:
        """Get product by ID."""
        try:
            response = self.client.get(f'/api/v1/internal/products/{product_id}/')
            return response
        except Exception as e:
            logger.error(f"Failed to get product: {str(e)}")
            return {'success': False, 'error': str(e)}
    
    def search_products(self, query: str, filters: Dict = None) -> Dict[str, Any]:
        """Search for products."""
        try:
            params = {'q': query}
            if filters:
                params.update(filters)
            
            response = self.client.get('/api/v1/internal/products/search/', params=params)
            return response
        except Exception as e:
            logger.error(f"Failed to search products: {str(e)}")
            return {'success': False, 'error': str(e)}
    
    def update_product_views(self, product_id: int, user_id: int = None) -> Dict[str, Any]:
        """Update product view count."""
        try:
            data = {'product_id': product_id}
            if user_id:
                data['user_id'] = user_id
            
            response = self.client.post('/api/v1/internal/products/views/', data)
            return response
        except Exception as e:
            logger.error(f"Failed to update product views: {str(e)}")
            return {'success': False, 'error': str(e)}


# Example Internal API Views (these would be implemented in each service)

@method_decorator(csrf_exempt, name='dispatch')
@method_decorator(service_required(['product_management']), name='dispatch')
class UserVerificationView(View):
    """Internal API endpoint for user verification."""
    
    def post(self, request):
        """Verify user token."""
        try:
            data = json.loads(request.body)
            token = data.get('token')
            
            if not token:
                return ServiceAPIResponse.error('Token is required', 'MISSING_TOKEN')
            
            # Implement your token verification logic here
            # This is just an example
            user_data = {
                'user_id': 123,
                'username': 'testuser',
                'email': 'test@example.com',
                'is_active': True
            }
            
            return ServiceAPIResponse.success({
                'valid': True,
                'user': user_data
            })
            
        except json.JSONDecodeError:
            return ServiceAPIResponse.error('Invalid JSON', 'INVALID_JSON')
        except Exception as e:
            logger.error(f"User verification error: {str(e)}")
            return ServiceAPIResponse.error('Verification failed', 'VERIFICATION_ERROR', 500)


@method_decorator(csrf_exempt, name='dispatch')
@method_decorator(service_required(['authentication']), name='dispatch')
class ProductInfoView(View):
    """Internal API endpoint for product information."""
    
    def get(self, request, product_id):
        """Get product information."""
        try:
            # Implement your product lookup logic here
            # This is just an example
            product_data = {
                'id': product_id,
                'name': 'Example Product',
                'price': 99.99,
                'category': 'Electronics',
                'available': True
            }
            
            return ServiceAPIResponse.success(product_data)
            
        except Exception as e:
            logger.error(f"Product lookup error: {str(e)}")
            return ServiceAPIResponse.error('Product lookup failed', 'PRODUCT_ERROR', 500)
    
    def post(self, request):
        """Update product information."""
        try:
            data = json.loads(request.body)
            product_id = data.get('product_id')
            
            if not product_id:
                return ServiceAPIResponse.error('Product ID is required', 'MISSING_PRODUCT_ID')
            
            # Implement your product update logic here
            return ServiceAPIResponse.success({'updated': True})
            
        except json.JSONDecodeError:
            return ServiceAPIResponse.error('Invalid JSON', 'INVALID_JSON')
        except Exception as e:
            logger.error(f"Product update error: {str(e)}")
            return ServiceAPIResponse.error('Product update failed', 'UPDATE_ERROR', 500)


@csrf_exempt
@require_http_methods(["GET", "POST"])
@service_required()
def health_check_internal(request):
    """Internal health check endpoint for service monitoring."""
    
    if request.method == 'GET':
        # Return detailed health status
        health_data = {
            'status': 'healthy',
            'service': ServiceConfig.get_current_service_name(),
            'timestamp': int(time.time()),
            'request_from': getattr(request, 'service_name', 'unknown')
        }
        return ServiceAPIResponse.success(health_data)
    
    elif request.method == 'POST':
        # Handle health check requests to other services
        try:
            data = json.loads(request.body)
            target_service = data.get('service')
            
            if not target_service:
                return ServiceAPIResponse.error('Target service required', 'MISSING_SERVICE')
            
            is_healthy = ServiceConfig.is_service_available(target_service)
            
            return ServiceAPIResponse.success({
                'service': target_service,
                'healthy': is_healthy
            })
            
        except json.JSONDecodeError:
            return ServiceAPIResponse.error('Invalid JSON', 'INVALID_JSON')
        except Exception as e:
            logger.error(f"Health check error: {str(e)}")
            return ServiceAPIResponse.error('Health check failed', 'HEALTH_CHECK_ERROR', 500)


class ServiceCommunicationHelper:
    """Helper class for common service communication patterns."""
    
    @staticmethod
    def broadcast_event(event_name: str, data: Dict, services: list = None):
        """Broadcast an event to multiple services."""
        results = {}
        target_services = services or ['authentication', 'product_management']
        
        for service_name in target_services:
            try:
                client = service_registry.get_client(service_name)
                response = client.post('/api/v1/internal/events/', {
                    'event': event_name,
                    'data': data
                })
                results[service_name] = {'success': True, 'response': response}
            except Exception as e:
                logger.error(f"Failed to broadcast to {service_name}: {str(e)}")
                results[service_name] = {'success': False, 'error': str(e)}
        
        return results
    
    @staticmethod
    def get_service_status_all():
        """Get status of all registered services."""
        return service_registry.health_check_all()
    
    @staticmethod
    def make_authenticated_request(
        service_name: str, 
        method: str, 
        endpoint: str, 
        data: Dict = None,
        current_service: str = 'unknown'
    ):
        """Make an authenticated request to another service."""
        try:
            # Generate service token
            token = service_token_generator.generate_service_token(current_service)
            
            # Prepare headers
            headers = {
                'X-Service-Token': token,
                'X-Service-Name': current_service
            }
            
            # Get client and make request
            client = service_registry.get_client(service_name)
            
            if method.upper() == 'GET':
                response = client.get(endpoint, headers=headers)
            elif method.upper() == 'POST':
                response = client.post(endpoint, data=data, headers=headers)
            elif method.upper() == 'PUT':
                response = client.put(endpoint, data=data, headers=headers)
            elif method.upper() == 'DELETE':
                response = client.delete(endpoint, headers=headers)
            else:
                raise ValueError(f"Unsupported HTTP method: {method}")
            
            return {'success': True, 'data': response}
            
        except Exception as e:
            logger.error(f"Service request failed: {str(e)}")
            return {'success': False, 'error': str(e)}


# Global API instances
auth_api = AuthenticationServiceAPI()
product_api = ProductManagementServiceAPI()
service_helper = ServiceCommunicationHelper()
