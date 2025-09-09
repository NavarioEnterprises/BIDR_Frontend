#!/usr/bin/env python3
"""
Test script to verify CORS setup for Flutter web compatibility.
This simulates the exact requests Flutter web would make.
"""

import requests
import json
import sys
from urllib.parse import urljoin

# API base URL
BASE_URL = "http://108.141.192.60/products/api/v1/product-requests/"

def test_cors_preflight():
    """Test CORS preflight request (OPTIONS)"""
    print("🔍 Testing CORS Preflight Request...")
    
    url = urljoin(BASE_URL, "requests/")
    headers = {
        'Origin': 'http://localhost:8080',
        'Access-Control-Request-Method': 'GET',
        'Access-Control-Request-Headers': 'content-type'
    }
    
    try:
        response = requests.options(url, headers=headers)
        print(f"   Status: {response.status_code}")
        print(f"   Headers:")
        for key, value in response.headers.items():
            if 'access-control' in key.lower() or 'cors' in key.lower():
                print(f"     {key}: {value}")
        
        if response.status_code == 200:
            print("   ✅ CORS Preflight: SUCCESS")
            return True
        else:
            print("   ❌ CORS Preflight: FAILED")
            return False
            
    except Exception as e:
        print(f"   ❌ CORS Preflight ERROR: {e}")
        return False

def test_cors_get_request():
    """Test actual GET request with CORS headers"""
    print("\n📡 Testing GET Request with CORS...")
    
    url = urljoin(BASE_URL, "requests/")
    headers = {
        'Origin': 'http://localhost:8080',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
    }
    
    try:
        response = requests.get(url, headers=headers)
        print(f"   Status: {response.status_code}")
        print(f"   Response Headers:")
        for key, value in response.headers.items():
            if 'access-control' in key.lower():
                print(f"     {key}: {value}")
        
        if response.status_code == 200:
            data = response.json()
            print(f"   ✅ GET Request: SUCCESS")
            print(f"   Found {data.get('count', 0)} product requests")
            return True
        else:
            print(f"   ❌ GET Request: FAILED - {response.text}")
            return False
            
    except Exception as e:
        print(f"   ❌ GET Request ERROR: {e}")
        return False

def test_flutter_web_simulation():
    """Simulate the exact sequence Flutter web would perform"""
    print("\n🦋 Testing Flutter Web Simulation...")
    
    # First, Flutter web sends a preflight request
    preflight_success = test_cors_preflight()
    
    if not preflight_success:
        print("   ❌ Flutter Web Simulation: FAILED at preflight")
        return False
    
    # Then Flutter web sends the actual request
    get_success = test_cors_get_request()
    
    if get_success:
        print("   ✅ Flutter Web Simulation: SUCCESS")
        return True
    else:
        print("   ❌ Flutter Web Simulation: FAILED at GET request")
        return False

def test_various_origins():
    """Test with various common Flutter web origins"""
    print("\n🌐 Testing Various Origins...")
    
    origins = [
        'http://localhost:8080',  # Common Flutter web port
        'http://localhost:5000',  # Alternative Flutter web port
        'http://localhost:4200',  # Angular port (similar to Flutter web)
        'http://127.0.0.1:8080',  # IP version
    ]
    
    for origin in origins:
        print(f"\n   Testing origin: {origin}")
        headers = {
            'Origin': origin,
            'Access-Control-Request-Method': 'GET'
        }
        
        try:
            response = requests.options(urljoin(BASE_URL, "requests/"), headers=headers)
            if response.status_code == 200:
                print(f"     ✅ {origin}: SUCCESS")
            else:
                print(f"     ❌ {origin}: FAILED ({response.status_code})")
                
        except Exception as e:
            print(f"     ❌ {origin}: ERROR - {e}")

def main():
    print("🚀 CORS Testing for Flutter Web Compatibility")
    print("=" * 60)
    
    # Test individual components
    preflight_ok = test_cors_preflight()
    get_ok = test_cors_get_request()
    
    # Test Flutter web simulation
    flutter_ok = test_flutter_web_simulation()
    
    # Test various origins
    test_various_origins()
    
    print("\n" + "=" * 60)
    print("📊 SUMMARY:")
    print(f"   CORS Preflight: {'✅ PASS' if preflight_ok else '❌ FAIL'}")
    print(f"   GET Request: {'✅ PASS' if get_ok else '❌ FAIL'}")
    print(f"   Flutter Web Simulation: {'✅ PASS' if flutter_ok else '❌ FAIL'}")
    
    if preflight_ok and get_ok and flutter_ok:
        print("\n🎉 All tests passed! Flutter web should work correctly.")
        return 0
    else:
        print("\n⚠️  Some tests failed. Check the Django server configuration.")
        return 1

if __name__ == "__main__":
    sys.exit(main())
