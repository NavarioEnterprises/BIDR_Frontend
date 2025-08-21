#!/usr/bin/env python3
"""
API test script for BIDR Inventory Service.

This script tests the main API endpoints and functionality.
"""

import requests
import json
import sys
from datetime import datetime

BASE_URL = "http://localhost:8001"

def test_endpoint(method, endpoint, data=None, headers=None, description=""):
    """Test an API endpoint and return results."""
    url = f"{BASE_URL}{endpoint}"
    
    print(f"\n{'='*60}")
    print(f"Testing: {method} {endpoint}")
    if description:
        print(f"Description: {description}")
    print(f"{'='*60}")
    
    try:
        if method.upper() == 'GET':
            response = requests.get(url, headers=headers)
        elif method.upper() == 'POST':
            response = requests.post(url, json=data, headers=headers)
        elif method.upper() == 'PUT':
            response = requests.put(url, json=data, headers=headers)
        elif method.upper() == 'DELETE':
            response = requests.delete(url, headers=headers)
        else:
            print(f"Unsupported method: {method}")
            return None
        
        print(f"Status Code: {response.status_code}")
        print(f"Response Headers: {dict(response.headers)}")
        
        try:
            response_json = response.json()
            print(f"Response Body:")
            print(json.dumps(response_json, indent=2))
        except json.JSONDecodeError:
            print(f"Response Body (text): {response.text}")
        
        return response
        
    except requests.exceptions.RequestException as e:
        print(f"Request failed: {e}")
        return None

def run_tests():
    """Run all API tests."""
    print(f"BIDR Inventory Service API Test Report")
    print(f"Generated at: {datetime.now()}")
    print(f"Base URL: {BASE_URL}")
    
    # Test documentation endpoints
    test_endpoint('GET', '/swagger/', description="Swagger UI documentation")
    test_endpoint('GET', '/redoc/', description="ReDoc documentation")
    test_endpoint('GET', '/swagger.json', description="OpenAPI schema")
    
    # Test Categories API
    test_endpoint('GET', '/api/v1/categories/categories/', 
                  description="List all categories (should be empty initially)")
    
    # Test authentication requirement
    test_endpoint('POST', '/api/v1/categories/categories/', 
                  data={'name': 'Test Category', 'slug': 'test-category', 'status': 'active'},
                  description="Create category without authentication (should fail)")
    
    # Test other app endpoints (should be empty but accessible)
    test_endpoint('GET', '/api/v1/products/', 
                  description="Products endpoint (empty router)")
    test_endpoint('GET', '/api/v1/requests/', 
                  description="Product requests endpoint (empty router)")
    test_endpoint('GET', '/api/v1/quotes/', 
                  description="Quotes endpoint (empty router)")
    test_endpoint('GET', '/api/v1/transactions/', 
                  description="Transactions endpoint (empty router)")
    test_endpoint('GET', '/api/v1/ratings/', 
                  description="Ratings endpoint (empty router)")

if __name__ == '__main__':
    run_tests()
