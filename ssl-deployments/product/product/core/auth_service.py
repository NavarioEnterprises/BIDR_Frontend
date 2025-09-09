"""
Authentication Service API Client

This module provides utilities to communicate with the authentication service
to fetch seller details and other authentication-related data.
"""

import requests
import logging
from django.conf import settings
from django.core.cache import cache
from typing import Optional, Dict, Any
import uuid


logger = logging.getLogger(__name__)


class AuthenticationServiceClient:
    """
    Client for communicating with the authentication service API.
    """
    
    def __init__(self):
        self.base_url = getattr(settings, 'AUTHENTICATION_SERVICE_URL', 'http://localhost:8001')
        self.timeout = getattr(settings, 'AUTH_SERVICE_TIMEOUT', 10)
        self.cache_timeout = getattr(settings, 'AUTH_SERVICE_CACHE_TIMEOUT', 300)  # 5 minutes
    
    def _make_request(self, endpoint: str, method: str = 'GET', data: Optional[Dict] = None) -> Optional[Dict[str, Any]]:
        """
        Make HTTP request to authentication service.
        
        Args:
            endpoint: API endpoint path
            method: HTTP method (GET, POST, etc.)
            data: Request data for POST/PUT requests
            
        Returns:
            Response data or None if request fails
        """
        url = f"{self.base_url.rstrip('/')}/{endpoint.lstrip('/')}"
        
        try:
            # Prepare headers for service-to-service communication
            headers = {
                'Content-Type': 'application/json',
                'User-Agent': 'ProductManagementService/1.0',
                'X-Service-Name': 'product-management-service'
            }
            
            # Add API key if available
            api_key = getattr(settings, 'BIDR_API_KEY', None)
            if api_key:
                headers['X-API-Key'] = api_key
            
            response = requests.request(
                method=method,
                url=url,
                json=data,
                timeout=self.timeout,
                headers=headers
            )
            response.raise_for_status()
            return response.json()
        except requests.exceptions.RequestException as e:
            logger.error(f"Authentication service request failed: {str(e)}")
            return None
        except Exception as e:
            logger.error(f"Unexpected error in auth service request: {str(e)}")
            return None
    
    def get_seller_details(self, seller_id: str) -> Optional[Dict[str, Any]]:
        """
        Fetch seller details from authentication service.
        
        Args:
            seller_id: Seller UUID or user ID
            
        Returns:
            Seller details dict or None if not found
        """
        # Handle both UUID and seller_{uuid} format
        if isinstance(seller_id, str) and seller_id.startswith('seller_'):
            # Extract UUID from seller_{uuid} format
            seller_id = seller_id.replace('seller_', '')
        
        # Validate seller_id is a valid UUID
        try:
            uuid.UUID(str(seller_id))
        except (ValueError, TypeError):
            logger.error(f"Invalid seller_id format: {seller_id}")
            return None
        
        # Check cache first
        cache_key = f"seller_details:{seller_id}"
        cached_data = cache.get(cache_key)
        if cached_data:
            return cached_data
        
        # Use the by-auth-user-uid endpoint since we have UUIDs
        seller_data = self._make_request(f"api/seller/profiles/by-auth-user-uid/{seller_id}/")
        
        if seller_data:
            # Cache the result
            cache.set(cache_key, seller_data, self.cache_timeout)
            return seller_data
        
        # Try alternative endpoint structure (keeping for backward compatibility)
        seller_data = self._make_request(f"api/seller/profiles/{seller_id}/")
        
        if seller_data:
            cache.set(cache_key, seller_data, self.cache_timeout)
            return seller_data
        
        logger.warning(f"Seller not found in authentication service: {seller_id}")
        return None
    
    def get_seller_by_auth_user_uid(self, auth_user_uid: str) -> Optional[Dict[str, Any]]:
        """
        Fetch seller details by authentication user UID.
        
        Args:
            auth_user_uid: Authentication user UUID
            
        Returns:
            Seller details dict or None if not found
        """
        try:
            uuid.UUID(str(auth_user_uid))
        except (ValueError, TypeError):
            logger.error(f"Invalid auth_user_uid format: {auth_user_uid}")
            return None
        
        cache_key = f"seller_by_auth_uid:{auth_user_uid}"
        cached_data = cache.get(cache_key)
        if cached_data:
            return cached_data
        
        # Use the correct endpoint for auth_user_uid lookup
        seller_data = self._make_request(f"api/seller/profiles/by-auth-user-uid/{auth_user_uid}/")
        
        if seller_data:
            # The endpoint returns the seller data directly, not paginated
            cache.set(cache_key, seller_data, self.cache_timeout)
            return seller_data
        
        logger.warning(f"Seller not found by auth_user_uid: {auth_user_uid}")
        return None
    
    def get_multiple_sellers(self, seller_ids: list) -> Dict[str, Dict[str, Any]]:
        """
        Fetch multiple seller details at once.
        
        Args:
            seller_ids: List of seller IDs
            
        Returns:
            Dict mapping seller_id to seller details
        """
        result = {}
        uncached_ids = []
        
        # Check cache for each seller
        for seller_id in seller_ids:
            cache_key = f"seller_details:{seller_id}"
            cached_data = cache.get(cache_key)
            if cached_data:
                result[str(seller_id)] = cached_data
            else:
                uncached_ids.append(seller_id)
        
        # Fetch uncached sellers
        for seller_id in uncached_ids:
            seller_data = self.get_seller_details(seller_id)
            if seller_data:
                result[str(seller_id)] = seller_data
        
        return result
    
    def validate_seller_exists(self, seller_id: str) -> bool:
        """
        Check if a seller exists in the authentication service.
        
        Args:
            seller_id: Seller UUID
            
        Returns:
            True if seller exists, False otherwise
        """
        seller_data = self.get_seller_details(seller_id)
        return seller_data is not None
    
    def get_seller_basic_info(self, seller_id: str) -> Dict[str, Any]:
        """
        Get basic seller information for display purposes.
        
        Args:
            seller_id: Seller UUID
            
        Returns:
            Basic seller info dict with fallback values
        """
        seller_data = self.get_seller_details(seller_id)
        
        if seller_data:
            return {
                'seller_id': seller_id,
                'seller_name': (
                    seller_data.get('display_name') or 
                    seller_data.get('trading_name') or
                    seller_data.get('registered_company_name') or
                    seller_data.get('seller', {}).get('trading_name') or
                    seller_data.get('seller', {}).get('registered_company_name') or
                    seller_data.get('seller_email', 'Unknown Seller')
                ),
                'seller_email': seller_data.get('seller_email'),
                'vendor_id': seller_data.get('vendor_id'),
                'approval_status': seller_data.get('approval_status', 'unknown'),
                'average_rating': seller_data.get('average_rating'),
                'is_verified': seller_data.get('seller', {}).get('user', {}).get('is_verified', False)
            }
        
        # Fallback for when seller is not found
        return {
            'seller_id': seller_id,
            'seller_name': f'Seller {seller_id}',
            'seller_email': None,
            'vendor_id': None,
            'approval_status': 'unknown',
            'average_rating': None,
            'is_verified': False
        }
    
    def clear_seller_cache(self, seller_id: str) -> None:
        """
        Clear cached seller data.
        
        Args:
            seller_id: Seller UUID
        """
        cache_key = f"seller_details:{seller_id}"
        cache.delete(cache_key)


# Global client instance
auth_client = AuthenticationServiceClient()


# Utility functions for easy access
def get_seller_details(seller_id: str) -> Optional[Dict[str, Any]]:
    """Get seller details from authentication service."""
    return auth_client.get_seller_details(seller_id)


def get_seller_basic_info(seller_id: str) -> Dict[str, Any]:
    """Get basic seller information with fallbacks."""
    return auth_client.get_seller_basic_info(seller_id)


def validate_seller_exists(seller_id: str) -> bool:
    """Check if seller exists in authentication service."""
    return auth_client.validate_seller_exists(seller_id)


def get_multiple_sellers(seller_ids: list) -> Dict[str, Dict[str, Any]]:
    """Get multiple seller details at once."""
    return auth_client.get_multiple_sellers(seller_ids)


def get_seller_by_auth_user_uid(auth_user_uid: str) -> Optional[Dict[str, Any]]:
    """Get seller details by authentication user UID."""
    return auth_client.get_seller_by_auth_user_uid(auth_user_uid)