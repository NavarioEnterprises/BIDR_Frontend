"""
HTTP Client Utility for BIDR Microservices Communication
========================================================

This module provides a reusable HTTP client for communication between
BIDR microservices with built-in authentication, retry logic, and error handling.
"""

import requests
import logging
from typing import Dict, Any, Optional, Union
from urllib.parse import urljoin
import time
import json
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry

logger = logging.getLogger(__name__)


class ServiceHTTPClient:
    """HTTP client for inter-service communication in BIDR microservices."""
    
    def __init__(
        self, 
        base_url: str, 
        service_token: Optional[str] = None,
        timeout: int = 30,
        max_retries: int = 3
    ):
        """
        Initialize the HTTP client.
        
        Args:
            base_url: Base URL of the target service
            service_token: JWT token for service authentication
            timeout: Request timeout in seconds
            max_retries: Maximum number of retry attempts
        """
        self.base_url = base_url.rstrip('/')
        self.service_token = service_token
        self.timeout = timeout
        
        # Create session with retry strategy
        self.session = requests.Session()
        
        # Configure retry strategy
        retry_strategy = Retry(
            total=max_retries,
            status_forcelist=[429, 500, 502, 503, 504],
            backoff_factor=1,
            allowed_methods=["HEAD", "GET", "PUT", "DELETE", "OPTIONS", "TRACE", "POST"]
        )
        
        adapter = HTTPAdapter(max_retries=retry_strategy)
        self.session.mount("http://", adapter)
        self.session.mount("https://", adapter)
        
        # Set default headers
        self.session.headers.update({
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'User-Agent': 'BIDR-Service-Client/1.0'
        })
        
        # Add authorization header if token provided
        if self.service_token:
            self.session.headers.update({
                'Authorization': f'Bearer {self.service_token}'
            })
    
    def _make_request(
        self, 
        method: str, 
        endpoint: str, 
        data: Optional[Dict] = None,
        params: Optional[Dict] = None,
        headers: Optional[Dict] = None
    ) -> requests.Response:
        """
        Make HTTP request with error handling.
        
        Args:
            method: HTTP method (GET, POST, PUT, DELETE)
            endpoint: API endpoint
            data: Request body data
            params: Query parameters
            headers: Additional headers
            
        Returns:
            Response object
            
        Raises:
            requests.RequestException: For HTTP errors
        """
        url = urljoin(f"{self.base_url}/", endpoint.lstrip('/'))
        
        # Merge additional headers
        request_headers = self.session.headers.copy()
        if headers:
            request_headers.update(headers)
        
        try:
            logger.info(f"Making {method} request to {url}")
            
            response = self.session.request(
                method=method,
                url=url,
                json=data if data else None,
                params=params,
                headers=request_headers,
                timeout=self.timeout
            )
            
            # Log response details
            logger.info(f"Response: {response.status_code} from {url}")
            
            # Raise exception for bad status codes
            response.raise_for_status()
            
            return response
            
        except requests.exceptions.Timeout:
            logger.error(f"Request timeout for {method} {url}")
            raise
        except requests.exceptions.ConnectionError:
            logger.error(f"Connection error for {method} {url}")
            raise
        except requests.exceptions.HTTPError as e:
            logger.error(f"HTTP error {response.status_code} for {method} {url}: {response.text}")
            raise
        except Exception as e:
            logger.error(f"Unexpected error for {method} {url}: {str(e)}")
            raise
    
    def get(
        self, 
        endpoint: str, 
        params: Optional[Dict] = None,
        headers: Optional[Dict] = None
    ) -> Dict[str, Any]:
        """Make GET request."""
        response = self._make_request('GET', endpoint, params=params, headers=headers)
        return response.json() if response.content else {}
    
    def post(
        self, 
        endpoint: str, 
        data: Optional[Dict] = None,
        params: Optional[Dict] = None,
        headers: Optional[Dict] = None
    ) -> Dict[str, Any]:
        """Make POST request."""
        response = self._make_request('POST', endpoint, data=data, params=params, headers=headers)
        return response.json() if response.content else {}
    
    def put(
        self, 
        endpoint: str, 
        data: Optional[Dict] = None,
        headers: Optional[Dict] = None
    ) -> Dict[str, Any]:
        """Make PUT request."""
        response = self._make_request('PUT', endpoint, data=data, headers=headers)
        return response.json() if response.content else {}
    
    def delete(
        self, 
        endpoint: str,
        headers: Optional[Dict] = None
    ) -> Dict[str, Any]:
        """Make DELETE request."""
        response = self._make_request('DELETE', endpoint, headers=headers)
        return response.json() if response.content else {}
    
    def health_check(self) -> bool:
        """Check if the service is healthy."""
        try:
            response = self.get('/health/')
            return response.get('status') == 'healthy'
        except Exception as e:
            logger.error(f"Health check failed: {str(e)}")
            return False


class BIDRServiceRegistry:
    """Service registry for BIDR microservices."""
    
    def __init__(self):
        self.services = {}
    
    def register_service(self, name: str, base_url: str, token: Optional[str] = None):
        """Register a service."""
        self.services[name] = {
            'base_url': base_url,
            'token': token,
            'client': ServiceHTTPClient(base_url, token)
        }
        logger.info(f"Registered service: {name} at {base_url}")
    
    def get_client(self, service_name: str) -> ServiceHTTPClient:
        """Get HTTP client for a service."""
        if service_name not in self.services:
            raise ValueError(f"Service '{service_name}' not registered")
        return self.services[service_name]['client']
    
    def get_service_url(self, service_name: str) -> str:
        """Get base URL for a service."""
        if service_name not in self.services:
            raise ValueError(f"Service '{service_name}' not registered")
        return self.services[service_name]['base_url']
    
    def health_check_all(self) -> Dict[str, bool]:
        """Check health of all registered services."""
        results = {}
        for name, service_info in self.services.items():
            results[name] = service_info['client'].health_check()
        return results


# Global service registry instance
service_registry = BIDRServiceRegistry()
