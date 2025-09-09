#!/usr/bin/env python3
"""
Test script for the seller earning history endpoint.

This script demonstrates how to test the seller earning history API endpoint
with various scenarios including authentication and filtering.

Usage:
    python test_earning_history_endpoint.py

Requirements:
    - Django app running on localhost:8000 (adjust BASE_URL if different)
    - Valid authentication token for testing
"""

import requests
import json
from datetime import datetime, timedelta

# Configuration
BASE_URL = "http://localhost:8000"  # Adjust based on your setup
API_ENDPOINT = f"{BASE_URL}/api/v1/payment-transactions/seller-earnings/"

# Test authentication headers (replace with actual token/credentials)
headers = {
    "Authorization": "Bearer YOUR_AUTH_TOKEN_HERE",  # Replace with actual token
    "Content-Type": "application/json",
}

def test_seller_earning_history():
    """Test the seller earning history endpoint with various scenarios."""
    
    print("Testing Seller Earning History Endpoint")
    print("=" * 50)
    
    # Test 1: Basic request without filters
    print("\n1. Testing basic request (no filters):")
    try:
        response = requests.get(API_ENDPOINT, headers=headers)
        print(f"Status Code: {response.status_code}")
        
        if response.status_code == 200:
            data = response.json()
            print(f"Number of earning records: {len(data.get('results', data))}")
            if data.get('results'):
                print("Sample record:")
                print(json.dumps(data['results'][0], indent=2))
        else:
            print(f"Error: {response.text}")
    except requests.RequestException as e:
        print(f"Request failed: {e}")
    
    # Test 2: Filter by date range (last 30 days)
    print("\n2. Testing with date range filter (last 30 days):")
    end_date = datetime.now()
    start_date = end_date - timedelta(days=30)
    
    params = {
        'start_date': start_date.strftime('%Y-%m-%d'),
        'end_date': end_date.strftime('%Y-%m-%d')
    }
    
    try:
        response = requests.get(API_ENDPOINT, headers=headers, params=params)
        print(f"Status Code: {response.status_code}")
        
        if response.status_code == 200:
            data = response.json()
            print(f"Number of earning records in last 30 days: {len(data.get('results', data))}")
        else:
            print(f"Error: {response.text}")
    except requests.RequestException as e:
        print(f"Request failed: {e}")
    
    # Test 3: Filter by status
    print("\n3. Testing with status filter (RELEASED):")
    params = {'status': 'RELEASED'}
    
    try:
        response = requests.get(API_ENDPOINT, headers=headers, params=params)
        print(f"Status Code: {response.status_code}")
        
        if response.status_code == 200:
            data = response.json()
            print(f"Number of released earning records: {len(data.get('results', data))}")
        else:
            print(f"Error: {response.text}")
    except requests.RequestException as e:
        print(f"Request failed: {e}")
    
    # Test 4: Test without authentication (should fail)
    print("\n4. Testing without authentication (should fail):")
    try:
        response = requests.get(API_ENDPOINT)
        print(f"Status Code: {response.status_code}")
        if response.status_code in [401, 403]:
            print("Authentication check working correctly - access denied")
        else:
            print(f"Unexpected response: {response.text}")
    except requests.RequestException as e:
        print(f"Request failed: {e}")

def test_admin_seller_filter():
    """Test admin-specific functionality for filtering by seller."""
    
    print("\n" + "=" * 50)
    print("Testing Admin Seller Filtering (requires admin token)")
    print("=" * 50)
    
    # This test requires admin authentication
    admin_headers = {
        "Authorization": "Bearer YOUR_ADMIN_TOKEN_HERE",  # Replace with admin token
        "Content-Type": "application/json",
    }
    
    print("\n5. Testing admin filter by seller_id:")
    params = {'seller_id': 'SELLER_UUID_HERE'}  # Replace with actual seller UUID
    
    try:
        response = requests.get(API_ENDPOINT, headers=admin_headers, params=params)
        print(f"Status Code: {response.status_code}")
        
        if response.status_code == 200:
            data = response.json()
            print(f"Number of earning records for specific seller: {len(data.get('results', data))}")
        else:
            print(f"Error: {response.text}")
    except requests.RequestException as e:
        print(f"Request failed: {e}")

def display_endpoint_info():
    """Display information about the endpoint."""
    
    print("Seller Earning History API Endpoint Information")
    print("=" * 50)
    print(f"Endpoint: {API_ENDPOINT}")
    print("Method: GET")
    print("Authentication: Required (Bearer token)")
    print("Access: Sellers (own data) and Admins (all data)")
    print("\nSupported Query Parameters:")
    print("- start_date: Filter by start date (YYYY-MM-DD)")
    print("- end_date: Filter by end date (YYYY-MM-DD)")
    print("- status: Filter by payment status (CAPTURED, RELEASED, PAID)")
    print("- seller_id: Filter by seller ID (admin only)")
    print("\nResponse includes:")
    print("- payment_id: Unique payment identifier")
    print("- transaction_id: Associated transaction ID")
    print("- amount: Earning amount")
    print("- currency: Currency code")
    print("- order_date: Original order/transaction date")
    print("- status: Payment status")
    print("- earnings_status: User-friendly status")
    print("- buyer_info: Buyer details")
    print("- product_info: Product/service details")
    print("- actual_release_date: When earnings were released")
    print("- created_at: Payment creation date")

if __name__ == "__main__":
    display_endpoint_info()
    
    print("\n" + "!" * 50)
    print("IMPORTANT: Update the following before running tests:")
    print("1. BASE_URL - Set to your Django server URL")
    print("2. YOUR_AUTH_TOKEN_HERE - Replace with valid auth token")
    print("3. YOUR_ADMIN_TOKEN_HERE - Replace with admin auth token")
    print("4. SELLER_UUID_HERE - Replace with actual seller UUID")
    print("!" * 50)
    
    # Uncomment the lines below after updating the configuration
    # test_seller_earning_history()
    # test_admin_seller_filter()
    
    print("\nTo run the tests, uncomment the test function calls at the bottom of this script.")