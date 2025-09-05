"""
Service Configuration for BIDR Microservices
============================================

This module manages service discovery and configuration for
inter-service communication in the BIDR platform.
"""

import os
from typing import Dict, Optional
from decouple import config
from .http_client import service_registry
import logging

logger = logging.getLogger(__name__)


class ServiceConfig:
    """Configuration manager for BIDR microservices."""
    
    # Service URLs (can be overridden by environment variables)
    SERVICES = {
        'authentication': {
            'url': config('AUTH_SERVICE_URL', default='https://auth.bidr-gateway-1756992603.westus.cloudapp.azure.com'),
            'api_prefix': '/api/v1',
            'health_endpoint': '/health/'
        },
        'product_management': {
            'url': config('PRODUCT_SERVICE_URL', default='https://product.bidr-gateway-1756992603.westus.cloudapp.azure.com'),
            'api_prefix': '/api/v1',
            'health_endpoint': '/health/'
        },
        'user_management': {
            'url': config('USER_SERVICE_URL', default='https://localhost:8002'),
            'api_prefix': '/api/v1',
            'health_endpoint': '/health/'
        },
        'notification': {
            'url': config('NOTIFICATION_SERVICE_URL', default='https://localhost:8003'),
            'api_prefix': '/api/v1',
            'health_endpoint': '/health/'
        },
        'analytics': {
            'url': config('ANALYTICS_SERVICE_URL', default='https://localhost:8004'),
            'api_prefix': '/api/v1',
            'health_endpoint': '/health/'
        }
    }
    
    # Service tokens for authentication
    SERVICE_TOKENS = {
        'authentication': config('AUTH_SERVICE_TOKEN', default=''),
        'product_management': config('PRODUCT_SERVICE_TOKEN', default=''),
        'user_management': config('USER_SERVICE_TOKEN', default=''),
        'notification': config('NOTIFICATION_SERVICE_TOKEN', default=''),
        'analytics': config('ANALYTICS_SERVICE_TOKEN', default='')
    }
    
    @classmethod
    def get_service_url(cls, service_name: str) -> str:
        """Get full URL for a service."""
        if service_name not in cls.SERVICES:
            raise ValueError(f"Unknown service: {service_name}")
        return cls.SERVICES[service_name]['url']
    
    @classmethod
    def get_service_api_url(cls, service_name: str) -> str:
        """Get API URL for a service."""
        if service_name not in cls.SERVICES:
            raise ValueError(f"Unknown service: {service_name}")
        
        service = cls.SERVICES[service_name]
        return f"{service['url']}{service['api_prefix']}"
    
    @classmethod
    def get_service_token(cls, service_name: str) -> Optional[str]:
        """Get authentication token for a service."""
        return cls.SERVICE_TOKENS.get(service_name)
    
    @classmethod
    def initialize_service_registry(cls):
        """Initialize the global service registry with all services."""
        logger.info("Initializing BIDR service registry...")
        
        for service_name, service_config in cls.SERVICES.items():
            token = cls.get_service_token(service_name)
            service_registry.register_service(
                name=service_name,
                base_url=service_config['url'],
                token=token
            )
        
        logger.info(f"Registered {len(cls.SERVICES)} services in registry")
    
    @classmethod
    def get_current_service_name(cls) -> str:
        """Get the name of the current service based on environment."""
        return config('SERVICE_NAME', default='unknown')
    
    @classmethod
    def is_service_available(cls, service_name: str) -> bool:
        """Check if a service is available."""
        try:
            client = service_registry.get_client(service_name)
            return client.health_check()
        except Exception as e:
            logger.error(f"Service {service_name} unavailable: {str(e)}")
            return False


class ServiceEndpoints:
    """Common API endpoints for BIDR services."""
    
    # Authentication Service Endpoints
    AUTH_ENDPOINTS = {
        'login': '/auth/login/',
        'register': '/auth/register/',
        'verify_token': '/auth/verify/',
        'refresh_token': '/auth/refresh/',
        'user_profile': '/auth/profile/',
        'logout': '/auth/logout/'
    }
    
    # Product Management Service Endpoints
    PRODUCT_ENDPOINTS = {
        'products_list': '/products/',
        'product_detail': '/products/{id}/',
        'categories': '/categories/',
        'search': '/products/search/',
        'featured': '/products/featured/'
    }
    
    # User Management Service Endpoints
    USER_ENDPOINTS = {
        'users_list': '/users/',
        'user_detail': '/users/{id}/',
        'user_preferences': '/users/{id}/preferences/',
        'user_activity': '/users/{id}/activity/'
    }
    
    # Notification Service Endpoints
    NOTIFICATION_ENDPOINTS = {
        'send_notification': '/notifications/send/',
        'user_notifications': '/notifications/user/{user_id}/',
        'mark_read': '/notifications/{id}/read/'
    }
    
    # Analytics Service Endpoints
    ANALYTICS_ENDPOINTS = {
        'track_event': '/analytics/track/',
        'user_stats': '/analytics/users/{user_id}/',
        'product_stats': '/analytics/products/{product_id}/'
    }
    
    @classmethod
    def get_endpoint(cls, service_name: str, endpoint_name: str, **kwargs) -> str:
        """Get formatted endpoint URL."""
        endpoints_map = {
            'authentication': cls.AUTH_ENDPOINTS,
            'product_management': cls.PRODUCT_ENDPOINTS,
            'user_management': cls.USER_ENDPOINTS,
            'notification': cls.NOTIFICATION_ENDPOINTS,
            'analytics': cls.ANALYTICS_ENDPOINTS
        }
        
        if service_name not in endpoints_map:
            raise ValueError(f"Unknown service: {service_name}")
        
        endpoints = endpoints_map[service_name]
        if endpoint_name not in endpoints:
            raise ValueError(f"Unknown endpoint '{endpoint_name}' for service '{service_name}'")
        
        endpoint = endpoints[endpoint_name]
        
        # Format endpoint with provided kwargs
        try:
            return endpoint.format(**kwargs)
        except KeyError as e:
            raise ValueError(f"Missing parameter {e} for endpoint '{endpoint_name}'")


# Initialize the service registry when module is imported
def init_services():
    """Initialize service configuration."""
    try:
        ServiceConfig.initialize_service_registry()
        logger.info("BIDR services initialized successfully")
    except Exception as e:
        logger.error(f"Failed to initialize services: {str(e)}")


# Auto-initialize when imported
init_services()
