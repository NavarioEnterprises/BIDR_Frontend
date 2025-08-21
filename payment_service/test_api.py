#!/usr/bin/env python3
"""
BIDR Payment Service API Test Suite
Comprehensive testing of all API endpoints with sample data
"""

import requests
import json
import uuid
from datetime import date, datetime
import time

BASE_URL = "http://localhost:8002"

def test_endpoint(method, endpoint, data=None, description=""):
    """Test an API endpoint and return result"""
    url = f"{BASE_URL}{endpoint}"
    
    print(f"\n🧪 Testing: {description}")
    print(f"📍 {method} {endpoint}")
    
    try:
        if method == "GET":
            response = requests.get(url, timeout=10)
        elif method == "POST":
            response = requests.post(url, json=data, timeout=10)
        elif method == "PUT":
            response = requests.put(url, json=data, timeout=10)
        elif method == "DELETE":
            response = requests.delete(url, timeout=10)
        
        print(f"✅ Status: {response.status_code}")
        
        if response.headers.get('content-type', '').startswith('application/json'):
            result = response.json()
            print(f"📄 Response: {json.dumps(result, indent=2)}")
            return response.status_code, result
        else:
            print(f"📄 Response: {response.text}")
            return response.status_code, response.text
            
    except requests.RequestException as e:
        print(f"❌ Error: {e}")
        return None, str(e)

def main():
    """Run comprehensive API tests"""
    print("🚀 BIDR Payment Service API Test Suite")
    print("=" * 50)
    
    test_results = []
    
    # 1. Health and Info Tests
    print("\n" + "="*20 + " HEALTH & INFO TESTS " + "="*20)
    
    status, result = test_endpoint("GET", "/api/v1/health/", description="Health Check")
    test_results.append(("Health Check", status == 200, status))
    
    status, result = test_endpoint("GET", "/api/v1/info/", description="Service Info")
    test_results.append(("Service Info", status == 200, status))
    
    # 2. Payment Gateway Tests
    print("\n" + "="*20 + " PAYMENT GATEWAY TESTS " + "="*20)
    
    # Create payment gateway
    gateway_data = {
        "name": "Test Paystack Gateway",
        "slug": "test-paystack",
        "config": {
            "public_key": "pk_test_sample_key",
            "secret_key": "sk_test_sample_key"
        }
    }
    
    status, gateway_result = test_endpoint("POST", "/api/v1/payment-gateways/", 
                                         gateway_data, "Create Payment Gateway")
    test_results.append(("Create Payment Gateway", status == 201, status))
    
    # List payment gateways
    status, result = test_endpoint("GET", "/api/v1/payment-gateways/", description="List Payment Gateways")
    test_results.append(("List Payment Gateways", status == 200, status))
    
    # 3. Transaction Tests
    print("\n" + "="*20 + " TRANSACTION TESTS " + "="*20)
    
    # Create transaction
    transaction_data = {
        "buyer_id": str(uuid.uuid4()),
        "seller_id": str(uuid.uuid4()),
        "amount": 15000.00,
        "transaction_type": "escrow",
        "description": "Test transaction for API testing"
    }
    
    status, transaction_result = test_endpoint("POST", "/api/v1/transactions/", 
                                             transaction_data, "Create Transaction")
    test_results.append(("Create Transaction", status == 201, status))
    
    if status == 201:
        transaction_id = transaction_result.get('id')
        
        # Generate PIN
        status, pin_result = test_endpoint("POST", f"/api/v1/transactions/{transaction_id}/generate_pin/", 
                                         {}, "Generate Transaction PIN")
        test_results.append(("Generate PIN", status == 201, status))
        
        if status == 201:
            pin_code = pin_result.get('pin_code')
            
            # Verify PIN
            pin_verify_data = {
                "transaction_id": transaction_id,
                "pin_code": pin_code
            }
            status, verify_result = test_endpoint("POST", f"/api/v1/transactions/{transaction_id}/verify_pin/", 
                                                pin_verify_data, "Verify Transaction PIN")
            test_results.append(("Verify PIN", status == 200, status))
        
        # Get transaction logs
        status, logs_result = test_endpoint("GET", f"/api/v1/transactions/{transaction_id}/logs/", 
                                          description="Get Transaction Logs")
        test_results.append(("Get Transaction Logs", status == 200, status))
    
    # List transactions
    status, result = test_endpoint("GET", "/api/v1/transactions/", description="List Transactions")
    test_results.append(("List Transactions", status == 200, status))
    
    # 4. Escrow Tests
    print("\n" + "="*20 + " ESCROW TESTS " + "="*20)
    
    # Create escrow account (if we have a transaction)
    if 'transaction_id' in locals():
        escrow_data = {
            "transaction_id": transaction_id,
            "amount": 15000.00,
            "category": "electronics"
        }
        
        status, escrow_result = test_endpoint("POST", "/api/v1/escrow/", 
                                            escrow_data, "Create Escrow Account")
        test_results.append(("Create Escrow Account", status == 201, status))
        
        if status == 201:
            escrow_id = escrow_result.get('id')
            
            # Request early release
            early_release_data = {
                "release_type": "early",
                "reason": "Testing early release functionality"
            }
            status, result = test_endpoint("POST", f"/api/v1/escrow/{escrow_id}/request_early_release/", 
                                         early_release_data, "Request Early Release")
            test_results.append(("Request Early Release", status == 200, status))
    
    # List escrow accounts
    status, result = test_endpoint("GET", "/api/v1/escrow/", description="List Escrow Accounts")
    test_results.append(("List Escrow Accounts", status == 200, status))
    
    # Get expired escrows
    status, result = test_endpoint("GET", "/api/v1/escrow/expired/", description="Get Expired Escrows")
    test_results.append(("Get Expired Escrows", status == 200, status))
    
    # Get escrows expiring soon
    status, result = test_endpoint("GET", "/api/v1/escrow/expiring_soon/", description="Get Expiring Soon")
    test_results.append(("Get Expiring Soon", status == 200, status))
    
    # 5. Analytics Tests
    print("\n" + "="*20 + " ANALYTICS TESTS " + "="*20)
    
    status, result = test_endpoint("GET", "/api/v1/analytics/daily_summary/", description="Daily Summary")
    test_results.append(("Daily Analytics", status == 200, status))
    
    status, result = test_endpoint("GET", "/api/v1/analytics/weekly_summary/", description="Weekly Summary")
    test_results.append(("Weekly Analytics", status == 200, status))
    
    status, result = test_endpoint("GET", "/api/v1/analytics/monthly_summary/", description="Monthly Summary")
    test_results.append(("Monthly Analytics", status == 200, status))
    
    status, result = test_endpoint("GET", "/api/v1/analytics/transaction_analytics/", description="Transaction Analytics")
    test_results.append(("Transaction Analytics", status == 200, status))
    
    status, result = test_endpoint("GET", "/api/v1/analytics/escrow_analytics/", description="Escrow Analytics")
    test_results.append(("Escrow Analytics", status == 200, status))
    
    # Custom date range analytics
    custom_range_data = {
        "start_date": "2025-01-01",
        "end_date": "2025-12-31"
    }
    status, result = test_endpoint("POST", "/api/v1/analytics/custom_range/", 
                                 custom_range_data, "Custom Range Analytics")
    test_results.append(("Custom Range Analytics", status == 200, status))
    
    # 6. Notification Tests
    print("\n" + "="*20 + " NOTIFICATION TESTS " + "="*20)
    
    status, result = test_endpoint("GET", "/api/v1/notifications_service/info/", description="Notifications Info")
    test_results.append(("Notifications Info", status == 200, status))
    
    notification_data = {
        "channel": "sms",
        "recipient": "+2348012345678",
        "message": "Test notification message"
    }
    status, result = test_endpoint("POST", "/api/v1/notifications_service/send/",
                                 notification_data, "Send Notification")
    test_results.append(("Send Notification", status == 200, status))
    
    # 7. Print Test Summary
    print("\n" + "="*20 + " TEST RESULTS SUMMARY " + "="*20)
    
    passed = sum(1 for _, success, _ in test_results if success)
    failed = len(test_results) - passed
    
    print(f"\n📊 Total Tests: {len(test_results)}")
    print(f"✅ Passed: {passed}")
    print(f"❌ Failed: {failed}")
    print(f"📈 Success Rate: {(passed/len(test_results)*100):.1f}%")
    
    print("\n📋 Detailed Results:")
    for test_name, success, status in test_results:
        status_icon = "✅" if success else "❌"
        print(f"{status_icon} {test_name}: HTTP {status}")
    
    if failed == 0:
        print(f"\n🎉 All tests passed! The BIDR Payment Service API is working correctly.")
    else:
        print(f"\n⚠️  {failed} test(s) failed. Please check the detailed output above.")

if __name__ == "__main__":
    main()
