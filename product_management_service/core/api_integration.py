"""
API integration service for connecting with external services.

This module handles API calls to other services in the BIDR ecosystem,
including the authentication service for seller information.
"""

import requests
import logging
from typing import Optional, Dict, Any
from django.conf import settings
from django.core.cache import cache
from django.utils import timezone
from datetime import timedelta
import json

logger = logging.getLogger(__name__)


class APIIntegrationService:
    """Service for integrating with external APIs."""
    
    def __init__(self):
        self.auth_service_url = getattr(
            settings, 
            'AUTH_SERVICE_URL', 
            'http://localhost:8000'
        )
        self.api_timeout = getattr(settings, 'API_TIMEOUT', 30)
        self.cache_timeout = getattr(settings, 'API_CACHE_TIMEOUT', 300)  # 5 minutes
        
        # Service API keys/tokens
        self.service_api_key = getattr(settings, 'SERVICE_API_KEY', None)
        self.service_token = getattr(settings, 'SERVICE_TOKEN', None)
    
    def _get_headers(self, include_auth=True) -> Dict[str, str]:
        """Get common headers for API requests."""
        headers = {
            'Content-Type': 'application/json',
            'User-Agent': 'BIDR-InventoryService/1.0'
        }
        
        if include_auth and self.service_token:
            headers['Authorization'] = f'Bearer {self.service_token}'
        elif include_auth and self.service_api_key:
            headers['X-API-Key'] = self.service_api_key
        
        return headers
    
    def _make_request(self, method: str, url: str, data: dict = None, 
                     params: dict = None, use_cache: bool = True,
                     cache_key: str = None, cache_timeout: int = None) -> Optional[Dict[str, Any]]:
        """Make HTTP request with error handling and caching."""
        
        # Check cache first for GET requests
        if method.upper() == 'GET' and use_cache and cache_key:
            cached_result = cache.get(cache_key)
            if cached_result:
                logger.info(f"Retrieved cached result for {cache_key}")
                return cached_result
        
        try:
            headers = self._get_headers()
            
            response = requests.request(
                method=method,
                url=url,
                headers=headers,
                json=data,
                params=params,
                timeout=self.api_timeout
            )
            
            response.raise_for_status()
            result = response.json()
            
            # Cache successful GET responses
            if method.upper() == 'GET' and use_cache and cache_key:
                timeout = cache_timeout or self.cache_timeout
                cache.set(cache_key, result, timeout)
                logger.info(f"Cached result for {cache_key} for {timeout} seconds")
            
            return result
            
        except requests.exceptions.RequestException as e:
            logger.error(f"API request failed: {method} {url} - {e}")
            return None
        except json.JSONDecodeError as e:
            logger.error(f"Failed to decode JSON response: {e}")
            return None
        except Exception as e:
            logger.error(f"Unexpected error in API request: {e}")
            return None
    
    def get_seller_info(self, seller_id: str) -> Optional[Dict[str, Any]]:
        """
        Get seller information from the authentication service.
        
        Args:
            seller_id: The seller's user ID
            
        Returns:
            Dictionary containing seller information or None if not found
        """
        cache_key = f"seller_info_{seller_id}"
        url = f"{self.auth_service_url}/api/v1/users/{seller_id}/"
        
        result = self._make_request(
            'GET', 
            url, 
            use_cache=True, 
            cache_key=cache_key,
            cache_timeout=600  # Cache for 10 minutes
        )
        
        if result:
            logger.info(f"Retrieved seller info for {seller_id}")
        else:
            logger.warning(f"Failed to retrieve seller info for {seller_id}")
        
        return result
    
    def get_seller_profile(self, seller_id: str) -> Optional[Dict[str, Any]]:
        """
        Get detailed seller profile from the authentication service.
        
        Args:
            seller_id: The seller's user ID
            
        Returns:
            Dictionary containing seller profile or None if not found
        """
        cache_key = f"seller_profile_{seller_id}"
        url = f"{self.auth_service_url}/api/v1/users/{seller_id}/profile/"
        
        result = self._make_request(
            'GET', 
            url, 
            use_cache=True, 
            cache_key=cache_key,
            cache_timeout=300  # Cache for 5 minutes
        )
        
        return result
    
    def verify_seller_exists(self, seller_id: str) -> bool:
        """
        Verify that a seller exists in the authentication service.
        
        Args:
            seller_id: The seller's user ID
            
        Returns:
            True if seller exists, False otherwise
        """
        seller_info = self.get_seller_info(seller_id)
        return seller_info is not None
    
    def get_multiple_sellers(self, seller_ids: list) -> Dict[str, Any]:
        """
        Get information for multiple sellers.
        
        Args:
            seller_ids: List of seller user IDs
            
        Returns:
            Dictionary mapping seller_id to seller info
        """
        sellers = {}
        
        for seller_id in seller_ids:
            seller_info = self.get_seller_info(seller_id)
            if seller_info:
                sellers[seller_id] = seller_info
        
        return sellers
    
    def notify_seller_activity(self, seller_id: str, activity_type: str, 
                             activity_data: dict) -> bool:
        """
        Notify the authentication service about seller activity.
        
        Args:
            seller_id: The seller's user ID
            activity_type: Type of activity (e.g., 'product_created', 'quote_submitted')
            activity_data: Additional data about the activity
            
        Returns:
            True if notification was successful, False otherwise
        """
        url = f"{self.auth_service_url}/api/v1/users/{seller_id}/activity/"
        
        data = {
            'activity_type': activity_type,
            'activity_data': activity_data,
            'timestamp': timezone.now().isoformat(),
            'service': 'product_management_service'
        }
        
        result = self._make_request('POST', url, data=data, use_cache=False)
        
        if result:
            logger.info(f"Notified seller activity: {seller_id} - {activity_type}")
            return True
        else:
            logger.warning(f"Failed to notify seller activity: {seller_id} - {activity_type}")
            return False
    
    def get_seller_verification_status(self, seller_id: str) -> Optional[str]:
        """
        Get seller verification status from the authentication service.
        
        Args:
            seller_id: The seller's user ID
            
        Returns:
            Verification status string or None if not found
        """
        seller_info = self.get_seller_info(seller_id)
        if seller_info and 'verification_status' in seller_info:
            return seller_info['verification_status']
        return None
    
    def clear_seller_cache(self, seller_id: str):
        """
        Clear cached seller information.
        
        Args:
            seller_id: The seller's user ID
        """
        cache_keys = [
            f"seller_info_{seller_id}",
            f"seller_profile_{seller_id}"
        ]
        
        for key in cache_keys:
            cache.delete(key)
        
        logger.info(f"Cleared cache for seller {seller_id}")
    
    def health_check(self) -> Dict[str, Any]:
        """
        Check the health of connected services.
        
        Returns:
            Dictionary containing health status of services
        """
        services = {}
        
        # Check authentication service
        try:
            url = f"{self.auth_service_url}/health/"
            result = self._make_request('GET', url, use_cache=False)
            services['auth_service'] = {
                'status': 'healthy' if result else 'unhealthy',
                'url': self.auth_service_url,
                'response': result
            }
        except Exception as e:
            services['auth_service'] = {
                'status': 'error',
                'url': self.auth_service_url,
                'error': str(e)
            }
        
        return services


# Global API integration service instance
api_integration = APIIntegrationService()


# Convenience functions
def get_seller_info(seller_id: str) -> Optional[Dict[str, Any]]:
    """Get seller information."""
    return api_integration.get_seller_info(seller_id)


def verify_seller_exists(seller_id: str) -> bool:
    """Verify seller exists."""
    return api_integration.verify_seller_exists(seller_id)


def notify_seller_activity(seller_id: str, activity_type: str, activity_data: dict) -> bool:
    """Notify seller activity."""
    return api_integration.notify_seller_activity(seller_id, activity_type, activity_data)


def clear_seller_cache(seller_id: str):
    """Clear seller cache."""
    api_integration.clear_seller_cache(seller_id)


class SellerIntegrationMixin:
    """
    Mixin for models that reference sellers from the authentication service.
    """
    
    def get_seller_info(self):
        """Get seller information for this instance."""
        if hasattr(self, 'seller_id') and self.seller_id:
            return get_seller_info(str(self.seller_id))
        elif hasattr(self, 'seller') and self.seller:
            return get_seller_info(str(self.seller.id))
        return None
    
    def verify_seller(self):
        """Verify that the seller exists."""
        if hasattr(self, 'seller_id') and self.seller_id:
            return verify_seller_exists(str(self.seller_id))
        elif hasattr(self, 'seller') and self.seller:
            return verify_seller_exists(str(self.seller.id))
        return False
    
    def notify_activity(self, activity_type: str, activity_data: dict = None):
        """Notify seller activity."""
        if activity_data is None:
            activity_data = {}
        
        seller_id = None
        if hasattr(self, 'seller_id') and self.seller_id:
            seller_id = str(self.seller_id)
        elif hasattr(self, 'seller') and self.seller:
            seller_id = str(self.seller.id)
        
        if seller_id:
            # Add model information to activity data
            activity_data.update({
                'model': self.__class__.__name__,
                'object_id': str(self.id) if hasattr(self, 'id') else None,
            })
            
            return notify_seller_activity(seller_id, activity_type, activity_data)
        
        return False
