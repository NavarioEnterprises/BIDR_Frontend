#!/usr/bin/env python3
"""
Test script to verify that product request endpoints work without authentication.
Run this from the product_management_service directory.
"""

import json
import requests
import sys

# Base URL for the API (adjust if running on different host/port)
BASE_URL = "http://localhost:8000/product-requests"

def test_anonymous_get():
    """Test GET requests without authentication"""
    print("🔍 Testing anonymous GET requests...")
    
    try:
        # Test list endpoint
        response = requests.get(f"{BASE_URL}/requests/")
        print(f"GET /requests/ - Status: {response.status_code}")
        
        if response.status_code == 200:
            data = response.json()
            print(f"✅ SUCCESS: Retrieved {data.get('count', 0)} product requests")
        else:
            print(f"❌ FAILED: {response.text}")
    
    except Exception as e:
        print(f"❌ Error: {e}")

def test_anonymous_post():
    """Test POST request without authentication"""
    print("\n📝 Testing anonymous POST request...")
    
    # Sample product request data
    test_data = {
        "category": "ELECTRONICS",
        "title": "Anonymous Test Request - Gaming Laptop",
        "description": "Need a high-performance gaming laptop for work",
        "quantity": 1,
        "max_budget": "25000.00",
        "currency": "ZAR",
        "condition_preference": "NEW",
        "urgency_timeline": "1_WEEK",
        "buyer_location": {
            "address": "Cape Town, South Africa",
            "lat": -33.9249,
            "lng": 18.4241
        },
        "product_specifications": {
            "cpu": "Intel i7 or AMD Ryzen 7",
            "gpu": "RTX 4060 or better",
            "ram": "16GB minimum",
            "storage": "512GB SSD"
        },
        "terms_accepted": True,
        "contact_consent": True
    }
    
    try:
        response = requests.post(
            f"{BASE_URL}/requests/",
            json=test_data,
            headers={'Content-Type': 'application/json'}
        )
        
        print(f"POST /requests/ - Status: {response.status_code}")
        
        if response.status_code == 201:
            data = response.json()
            print(f"✅ SUCCESS: Created product request")
            print(f"   Request ID: {data.get('request_id', 'N/A')}")
            print(f"   Title: {data.get('title', 'N/A')}")
            print(f"   Category: {data.get('category', 'N/A')}")
            return data.get('request_id')
        else:
            print(f"❌ FAILED: {response.text}")
            return None
            
    except Exception as e:
        print(f"❌ Error: {e}")
        return None

def test_categories():
    """Test categories endpoint"""
    print("\n📊 Testing categories endpoint...")
    
    try:
        response = requests.get(f"{BASE_URL}/requests/categories/")
        print(f"GET /requests/categories/ - Status: {response.status_code}")
        
        if response.status_code == 200:
            data = response.json()
            print(f"✅ SUCCESS: Retrieved {len(data)} categories")
            for category in data:
                print(f"   - {category['name']}: {category['count']} requests")
        else:
            print(f"❌ FAILED: {response.text}")
            
    except Exception as e:
        print(f"❌ Error: {e}")

def test_specific_request(request_id):
    """Test retrieving a specific request"""
    if not request_id:
        return
        
    print(f"\n🔍 Testing specific request retrieval...")
    
    try:
        response = requests.get(f"{BASE_URL}/requests/{request_id}/")
        print(f"GET /requests/{request_id}/ - Status: {response.status_code}")
        
        if response.status_code == 200:
            data = response.json()
            print(f"✅ SUCCESS: Retrieved request details")
            print(f"   Title: {data.get('title', 'N/A')}")
            print(f"   Status: {data.get('status', 'N/A')}")
            print(f"   View Count: {data.get('view_count', 0)}")
        else:
            print(f"❌ FAILED: {response.text}")
            
    except Exception as e:
        print(f"❌ Error: {e}")

def main():
    """Main test function"""
    print("🚀 Testing Anonymous Product Request Submissions")
    print("=" * 50)
    
    # Test GET requests
    test_anonymous_get()
    
    # Test categories
    test_categories()
    
    # Test POST request
    request_id = test_anonymous_post()
    
    # Test specific request retrieval
    test_specific_request(request_id)
    
    print("\n" + "=" * 50)
    if request_id:
        print("🎉 All tests completed! Anonymous submissions are working.")
        print(f"   Created test request: {request_id}")
    else:
        print("⚠️  Tests completed with some failures.")
    print("=" * 50)

if __name__ == "__main__":
    main()
