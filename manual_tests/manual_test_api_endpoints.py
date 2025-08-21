#!/usr/bin/env python
"""
API Testing Script for Product Request System

This script demonstrates how to use the API endpoints to:
1. List existing product requests
2. Get category statistics
3. Create new product requests for all categories
4. Filter and search requests
"""

import requests
import json
import os
import sys

# Base URL for API
BASE_URL = "http://localhost:8000"
API_BASE = f"{BASE_URL}/product-requests"


def print_header(title):
    """Print a formatted header."""
    print(f"\n{'=' * 60}")
    print(f"🔥 {title}")
    print('=' * 60)


def print_success(message):
    """Print success message."""
    print(f"✅ {message}")


def print_error(message):
    """Print error message."""
    print(f"❌ {message}")


def make_request(method, endpoint, data=None, params=None):
    """Make HTTP request and return response."""
    url = f"{API_BASE}{endpoint}"
    
    try:
        if method.upper() == 'GET':
            response = requests.get(url, params=params)
        elif method.upper() == 'POST':
            response = requests.post(url, json=data, headers={'Content-Type': 'application/json'})
        else:
            raise ValueError(f"Unsupported method: {method}")
        
        response.raise_for_status()
        return response.json(), response.status_code
    
    except requests.exceptions.RequestException as e:
        print_error(f"Request failed: {e}")
        if hasattr(e, 'response') and e.response is not None:
            try:
                error_detail = e.response.json()
                print(f"Error details: {json.dumps(error_detail, indent=2)}")
            except:
                print(f"Response text: {e.response.text}")
        return None, getattr(e.response, 'status_code', 0) if hasattr(e, 'response') else 0


def test_list_requests():
    """Test listing all product requests."""
    print_header("Testing List Product Requests")
    
    data, status = make_request('GET', '/requests/')
    if data:
        print_success(f"Retrieved {len(data.get('results', []))} product requests")
        
        # Show sample request
        if data.get('results'):
            sample = data['results'][0]
            print(f"\nSample Request:")
            print(f"  ID: {sample['request_id']}")
            print(f"  Title: {sample['title']}")
            print(f"  Category: {sample['category']}")
            print(f"  Buyer: {sample['buyer_id']['username']}")
            print(f"  Budget: {sample['max_budget']} {sample['currency']}")
            print(f"  Status: {sample['status']}")
        
        return True
    return False


def test_category_stats():
    """Test getting category statistics."""
    print_header("Testing Category Statistics")
    
    data, status = make_request('GET', '/requests/categories/')
    if data:
        print_success("Category breakdown:")
        for category in data:
            print(f"  📊 {category['name']}: {category['count']} requests")
        return True
    return False


def test_urgent_requests():
    """Test getting urgent requests."""
    print_header("Testing Urgent Requests")
    
    data, status = make_request('GET', '/requests/urgent_requests/')
    if data:
        urgent_count = len(data.get('results', []))
        print_success(f"Found {urgent_count} urgent requests")
        
        if data.get('results'):
            for request in data['results'][:3]:  # Show first 3
                print(f"  🚨 {request['title']} - {request['urgency_timeline']}")
        return True
    return False


def test_filter_requests():
    """Test filtering requests by category."""
    print_header("Testing Request Filtering")
    
    # Test filtering by category
    for category in ['ELECTRONICS', 'VEHICLE_SPARES', 'TYRES_RIMS']:
        data, status = make_request('GET', '/requests/', params={'category': category})
        if data:
            count = len(data.get('results', []))
            print_success(f"{category}: {count} requests")
    
    return True


def create_consumer_electronics_request():
    """Create a new consumer electronics request via API."""
    print_header("Creating Consumer Electronics Request via API")
    
    # Get a user ID first
    users_data, _ = make_request('GET', '/requests/')
    if not users_data or not users_data.get('results'):
        print_error("No existing users found to use as buyer")
        return False
    
    buyer_id = users_data['results'][0]['buyer_id']['id']
    
    # Consumer Electronics Request Data
    request_data = {
        "buyer_id": buyer_id,
        "category": "ELECTRONICS",
        "title": "Gaming Desktop PC Setup",
        "description": "Need high-performance gaming desktop for competitive gaming and streaming",
        "quantity": 1,
        "condition_preference": "NEW",
        "max_budget": "35000.00",
        "currency": "ZAR",
        "buyer_location": {
            "address": "Cape Town, Western Cape, South Africa",
            "lat": -33.9249,
            "lng": 18.4241
        },
        "max_travel_distance": 30,
        "urgency_timeline": "1_WEEK",
        "terms_accepted": True,
        "contact_consent": True,
        "consumer_electronics_data": {
            "electronics_type": "DESKTOP",
            "brand_preference": "ASUS, MSI, Custom Build",
            "model_series": "Gaming Series",
            "quantity_needed": 1,
            "max_price": "35000.00",
            "currency": "ZAR",
            "urgency": "WITHIN_WEEK",
            "condition_preference": "NEW",
            "purpose_of_purchase": "PERSONAL_USE",
            "required_features": "RTX 4070 GPU minimum, Intel i7 or AMD Ryzen 7, 32GB RAM, 1TB NVMe SSD, RGB lighting",
            "warranty_required": "YES",
            "warranty_duration": "3 years",
            "additional_comments": "Need assembly service and Windows installation"
        }
    }
    
    data, status = make_request('POST', '/requests/', data=request_data)
    if data and status == 201:
        print_success(f"Created Electronics Request: {data['title']}")
        print(f"  Request ID: {data['request_id']}")
        print(f"  Electronics Summary: {data.get('consumer_electronics_summary', 'N/A')}")
        return data['request_id']
    else:
        print_error(f"Failed to create electronics request (Status: {status})")
        return None


def create_vehicle_spares_request():
    """Create a new vehicle spares request via API."""
    print_header("Creating Vehicle Spares Request via API")
    
    # Get a user ID
    users_data, _ = make_request('GET', '/requests/')
    buyer_id = users_data['results'][1]['buyer_id']['id'] if users_data and len(users_data['results']) > 1 else 1
    
    # Vehicle Spares Request Data
    request_data = {
        "buyer_id": buyer_id,
        "category": "VEHICLE_SPARES",
        "title": "Mercedes-Benz C200 Headlight Assembly",
        "description": "Left headlight assembly damaged in parking incident. Need OEM or equivalent replacement.",
        "quantity": 1,
        "condition_preference": "NEW",
        "max_budget": "4500.00",
        "currency": "ZAR",
        "buyer_location": {
            "address": "Sandton, Johannesburg, South Africa",
            "lat": -26.1076,
            "lng": 28.0567
        },
        "max_travel_distance": 40,
        "urgency_timeline": "1_WEEK",
        "terms_accepted": True,
        "contact_consent": True,
        "vehicle_spares_data": {
            "vehicle_make": "Mercedes-Benz",
            "vehicle_model": "C200",
            "vehicle_year": 2019,
            "vehicle_type": "PASSENGER_CAR",
            "engine_size": "2.0L",
            "part_name": "Left Headlight Assembly",
            "part_category": "BODY",
            "part_number": "A2059067203",
            "quantity": 1,
            "condition_preference": "NEW",
            "urgency": "1_WEEK",
            "description": "LED headlight assembly with DRL and turn signals",
            "preferred_brand": "Mercedes OEM, Hella, Bosch",
            "installation_required": "YES",
            "warranty_required": "YES",
            "max_budget": "4500.00",
            "currency": "ZAR"
        }
    }
    
    data, status = make_request('POST', '/requests/', data=request_data)
    if data and status == 201:
        print_success(f"Created Vehicle Spares Request: {data['title']}")
        print(f"  Request ID: {data['request_id']}")
        print(f"  Vehicle Summary: {data.get('vehicle_spares_summary', 'N/A')}")
        return data['request_id']
    else:
        print_error(f"Failed to create vehicle spares request (Status: {status})")
        return None


def create_tyres_rims_request():
    """Create a new tyres and rims request via API."""
    print_header("Creating Tyres & Rims Request via API")
    
    # Get a user ID
    users_data, _ = make_request('GET', '/requests/')
    buyer_id = users_data['results'][2]['buyer_id']['id'] if users_data and len(users_data['results']) > 2 else 1
    
    # Tyres & Rims Request Data
    request_data = {
        "buyer_id": buyer_id,
        "category": "TYRES_RIMS",
        "title": "215/60R16 Tyres for Toyota Camry",
        "description": "Need replacement tyres for family sedan. Priority on comfort and fuel efficiency.",
        "quantity": 4,
        "condition_preference": "NEW",
        "max_budget": "6000.00",
        "currency": "ZAR",
        "buyer_location": {
            "address": "Durban, KwaZulu-Natal, South Africa",
            "lat": -29.8587,
            "lng": 31.0218
        },
        "max_travel_distance": 20,
        "urgency_timeline": "1_WEEK",
        "terms_accepted": True,
        "contact_consent": True,
        "vehicle_tyres_rims_data": {
            "tyre_width": 215,
            "sidewall_profile": "60",
            "wheel_rim_diameter": "16",
            "select_tyres_rims": "TYRES",
            "quantity": 4,
            "urgency": "WITHIN_WEEK",
            "description": "Touring tyres with good fuel economy and comfortable ride",
            "vehicle_type": "PASSENGER_CAR",
            "preferred_brand": "Michelin, Continental, Goodyear",
            "tyre_construction_type": "RADIAL",
            "balancing_required": "YES",
            "fitment_required": "YES"
        }
    }
    
    data, status = make_request('POST', '/requests/', data=request_data)
    if data and status == 201:
        print_success(f"Created Tyres & Rims Request: {data['title']}")
        print(f"  Request ID: {data['request_id']}")
        print(f"  Tyre Summary: {data.get('tyres_rims_summary', 'N/A')}")
        return data['request_id']
    else:
        print_error(f"Failed to create tyres & rims request (Status: {status})")
        return None


def test_individual_category_endpoints():
    """Test individual category endpoints."""
    print_header("Testing Individual Category Endpoints")
    
    endpoints = [
        ('/consumer-electronics/', 'Consumer Electronics'),
        ('/vehicle-spares/', 'Vehicle Spares'),
        ('/tyres-rims/', 'Tyres & Rims')
    ]
    
    for endpoint, name in endpoints:
        data, status = make_request('GET', endpoint)
        if data:
            count = len(data.get('results', []))
            print_success(f"{name} endpoint: {count} items")
    
    return True


def main():
    """Main function to run all API tests."""
    print("🚀 Product Request API Testing Suite")
    print("=" * 60)
    print("Testing comprehensive API functionality for all product categories")
    
    # Test existing functionality
    success_count = 0
    total_tests = 0
    
    # Read operations tests
    tests = [
        ("List Requests", test_list_requests),
        ("Category Stats", test_category_stats),
        ("Urgent Requests", test_urgent_requests),
        ("Filter Requests", test_filter_requests),
        ("Category Endpoints", test_individual_category_endpoints),
    ]
    
    for test_name, test_func in tests:
        total_tests += 1
        try:
            if test_func():
                success_count += 1
        except Exception as e:
            print_error(f"Test '{test_name}' failed with error: {e}")
    
    # Create new requests tests
    print_header("Testing Request Creation via API")
    
    created_requests = []
    
    # Test creating requests for each category
    creation_tests = [
        ("Electronics Request", create_consumer_electronics_request),
        ("Vehicle Spares Request", create_vehicle_spares_request),
        ("Tyres & Rims Request", create_tyres_rims_request),
    ]
    
    for test_name, test_func in creation_tests:
        total_tests += 1
        try:
            request_id = test_func()
            if request_id:
                success_count += 1
                created_requests.append(request_id)
        except Exception as e:
            print_error(f"Creation test '{test_name}' failed with error: {e}")
    
    # Final summary
    print_header("API Testing Summary")
    print_success(f"Passed: {success_count}/{total_tests} tests")
    
    if created_requests:
        print_success(f"Successfully created {len(created_requests)} new requests:")
        for request_id in created_requests:
            print(f"  📝 {request_id}")
    
    # Final verification
    print_header("Final System State")
    data, _ = make_request('GET', '/requests/categories/')
    if data:
        total_requests = sum(cat['count'] for cat in data)
        print_success(f"Total requests in system: {total_requests}")
        for category in data:
            print(f"  📊 {category['name']}: {category['count']} requests")
    
    print("\n🎉 API testing completed!")
    print("\n📖 Available API Endpoints:")
    print("  - GET    /product-requests/requests/           - List all requests")
    print("  - POST   /product-requests/requests/           - Create new request") 
    print("  - GET    /product-requests/requests/{id}/      - Get specific request")
    print("  - GET    /product-requests/requests/categories/ - Category statistics")
    print("  - GET    /product-requests/requests/urgent_requests/ - Urgent requests")
    print("  - GET    /product-requests/consumer-electronics/ - Electronics list")
    print("  - GET    /product-requests/vehicle-spares/      - Vehicle spares list")
    print("  - GET    /product-requests/tyres-rims/         - Tyres & rims list")


if __name__ == '__main__':
    # Check if server is running
    try:
        response = requests.get(f"{BASE_URL}/admin/", timeout=5)
        print("✅ Server is running, starting API tests...")
        main()
    except requests.exceptions.RequestException:
        print("❌ Server is not running. Please start the Django server first:")
        print("   python manage.py runserver 0.0.0.0:8000")
        sys.exit(1)
