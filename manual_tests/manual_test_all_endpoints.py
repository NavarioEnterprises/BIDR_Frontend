#!/usr/bin/env python3
"""
Comprehensive API endpoint testing script for BIDR Product Management Service.
Creates test data and tests all endpoints systematically.
"""

import json
import requests
import sys
from datetime import datetime, timedelta

BASE_URL = "http://localhost:8000"
API_BASE = f"{BASE_URL}/api/v1"

def print_separator(title):
    print(f"\n{'='*60}")
    print(f"  {title}")
    print(f"{'='*60}")

def print_test_result(endpoint, method, status_code, response_data=None):
    status = "✅ PASS" if status_code < 400 else "❌ FAIL"
    print(f"{status} {method} {endpoint} - Status: {status_code}")
    if response_data and isinstance(response_data, dict):
        if 'count' in response_data:
            print(f"   Count: {response_data['count']}")
        if 'results' in response_data and len(response_data['results']) > 0:
            print(f"   First item: {list(response_data['results'][0].keys()) if response_data['results'] else 'Empty'}")
    elif response_data:
        print(f"   Response type: {type(response_data)}")

def test_endpoint(endpoint, method="GET", data=None):
    """Test an API endpoint"""
    url = f"{API_BASE}{endpoint}"
    try:
        if method == "GET":
            response = requests.get(url, timeout=10)
        elif method == "POST":
            response = requests.post(url, json=data, timeout=10)
        elif method == "PUT":
            response = requests.put(url, json=data, timeout=10)
        elif method == "PATCH":
            response = requests.patch(url, json=data, timeout=10)
        elif method == "DELETE":
            response = requests.delete(url, timeout=10)
        
        try:
            response_data = response.json()
        except:
            response_data = response.text
        
        print_test_result(endpoint, method, response.status_code, response_data)
        
        return response.status_code, response_data
    
    except Exception as e:
        print(f"❌ ERROR {method} {endpoint} - {str(e)}")
        return None, str(e)

def main():
    print("🚀 Starting comprehensive API endpoint testing...")
    
    # Test documentation endpoints first
    print_separator("DOCUMENTATION ENDPOINTS")
    
    # Test root swagger
    try:
        response = requests.get(BASE_URL, timeout=10)
        print_test_result("/", "GET", response.status_code)
    except Exception as e:
        print(f"❌ ERROR GET / - {str(e)}")
    
    # Test swagger endpoints
    for endpoint in ["/swagger/", "/redoc/", "/swagger.json"]:
        try:
            response = requests.get(f"{BASE_URL}{endpoint}", timeout=10)
            print_test_result(endpoint, "GET", response.status_code)
        except Exception as e:
            print(f"❌ ERROR GET {endpoint} - {str(e)}")

    # Test Categories endpoints
    print_separator("CATEGORIES ENDPOINTS")
    
    # List categories
    test_endpoint("/categories/")
    test_endpoint("/categories/categories/")
    
    # Create a test category
    category_data = {
        "name": "Electronics",
        "slug": "electronics",
        "description": "Electronic devices and components",
        "icon": "💻",
        "color": "#3B82F6",
        "sort_order": 1,
        "is_featured": True,
        "show_in_menu": True,
        "meta_title": "Electronics Category",
        "meta_description": "Find all electronic devices and components here",
        "commission_rate": 7.50
    }
    
    status, response = test_endpoint("/categories/categories/", "POST", category_data)
    category_id = None
    if status and status < 400 and isinstance(response, dict):
        category_id = response.get('id')
        print(f"   Created category ID: {category_id}")
    
    # Create another category for testing
    category_data_2 = {
        "name": "Vehicle Parts",
        "slug": "vehicle-parts",
        "description": "Auto parts and accessories",
        "icon": "🚗",
        "color": "#EF4444",
        "sort_order": 2,
        "parent": category_id  # Make it a subcategory if first one was created
    }
    
    status, response = test_endpoint("/categories/categories/", "POST", category_data_2)
    category_id_2 = None
    if status and status < 400 and isinstance(response, dict):
        category_id_2 = response.get('id')
        print(f"   Created category ID: {category_id_2}")
    
    # Test category attributes
    test_endpoint("/categories/attributes/")
    
    if category_id:
        attribute_data = {
            "category": category_id,
            "name": "brand",
            "attribute_type": "text",
            "label": "Brand",
            "is_required": True,
            "is_filterable": True,
            "help_text": "Product brand name",
            "sort_order": 1
        }
        test_endpoint("/categories/attributes/", "POST", attribute_data)

    # Test Product Requests endpoints
    print_separator("PRODUCT REQUESTS ENDPOINTS")
    
    test_endpoint("/product-requests/")
    test_endpoint("/product-requests/requests/")
    
    # Create test product request
    product_request_data = {
        "buyer_id": 14,  # Using test user ID from earlier
        "category": "ELECTRONICS",
        "title": "Gaming Desktop PC",
        "description": "High-performance gaming desktop computer",
        "quantity": 1,
        "condition_preference": "NEW",
        "max_budget": "35000.00",
        "currency": "ZAR",
        "buyer_location": {
            "address": "Cape Town, South Africa",
            "lat": -33.9249,
            "lng": 18.4241
        },
        "urgency_timeline": "1_WEEK",
        "terms_accepted": True,
        "contact_consent": True,
        "product_specifications": {
            "electronics_type": "DESKTOP",
            "brand_preference": "ASUS, MSI",
            "required_features": "RTX 4070 GPU, Intel i7, 32GB RAM, 1TB SSD"
        }
    }
    
    status, response = test_endpoint("/product-requests/requests/", "POST", product_request_data)
    request_id = None
    if status and status < 400 and isinstance(response, dict):
        request_id = response.get('request_id')
        print(f"   Created product request ID: {request_id}")
    
    # Test specific category endpoints
    test_endpoint("/product-requests/consumer-electronics/")
    test_endpoint("/product-requests/vehicle-spares/")
    test_endpoint("/product-requests/tyres-rims/")
    test_endpoint("/product-requests/messages/")
    test_endpoint("/product-requests/watchlist/")

    # Test Quotes endpoints
    print_separator("QUOTES ENDPOINTS")
    
    test_endpoint("/quotes/")
    test_endpoint("/quotes/quotes/")
    
    # Create test quote (if we have a product request)
    if request_id:
        quote_data = {
            "request": request_id,
            "seller_id": 15,  # Another test user
            "total_amount": "32000.00",
            "currency": "ZAR",
            "validity_days": 7,
            "notes": "High-quality gaming PC as per your specifications",
            "terms_conditions": "Standard warranty applies"
        }
        
        status, response = test_endpoint("/quotes/quotes/", "POST", quote_data)
        quote_id = None
        if status and status < 400 and isinstance(response, dict):
            quote_id = response.get('quote_id')
            print(f"   Created quote ID: {quote_id}")
            
            # Test quote items
            if quote_id:
                quote_item_data = {
                    "quote": quote_id,
                    "item_name": "Gaming Desktop PC",
                    "description": "Custom built gaming PC",
                    "quantity": 1,
                    "unit_price": "32000.00",
                    "total_price": "32000.00"
                }
                test_endpoint("/quotes/quote-items/", "POST", quote_item_data)
    
    test_endpoint("/quotes/quote-items/")
    test_endpoint("/quotes/quote-attachments/")
    test_endpoint("/quotes/quote-messages/")
    test_endpoint("/quotes/quote-comparisons/")

    # Test Transactions endpoints
    print_separator("TRANSACTIONS ENDPOINTS")
    test_endpoint("/transactions/")

    # Test Ratings endpoints
    print_separator("RATINGS ENDPOINTS")
    test_endpoint("/ratings/")

    # Test Analytics endpoints
    print_separator("ANALYTICS ENDPOINTS")
    test_endpoint("/analytics/")
    test_endpoint("/analytics/product-request-analytics/")
    test_endpoint("/analytics/category-analytics/")
    test_endpoint("/analytics/user-behavior-analytics/")
    test_endpoint("/analytics/search-analytics/")
    test_endpoint("/analytics/sales-analytics/")
    test_endpoint("/analytics/inventory-analytics/")
    test_endpoint("/analytics/reports/")
    test_endpoint("/analytics/dashboard/")

    # Test Authentication endpoints
    print_separator("AUTHENTICATION ENDPOINTS")
    
    # Test token endpoints (these might fail without proper setup)
    auth_data = {
        "username": "testuser1",
        "password": "testpass123"
    }
    
    try:
        response = requests.post(f"{BASE_URL}/api/token/", json=auth_data, timeout=10)
        print_test_result("/api/token/", "POST", response.status_code)
    except Exception as e:
        print(f"❌ ERROR POST /api/token/ - {str(e)}")

    print_separator("TESTING COMPLETE")
    print("🏁 All endpoint tests completed!")
    print("\nNote: Some endpoints may show errors if they require specific data")
    print("or if the models/views are not fully implemented yet.")

if __name__ == "__main__":
    main()
