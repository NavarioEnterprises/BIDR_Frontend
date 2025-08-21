#!/usr/bin/env python
"""
Test module to verify that security, logging, and API management components
are properly integrated across all apps in the authentication_service.

These tests:
1. Make requests to various endpoints
2. Verify that security measures are applied
3. Check that activities are properly logged
4. Confirm that API management is working
"""

import os
import sys
import requests
import json
import time
from datetime import datetime
import pytest

# Set up Django environment
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'authentication_service.settings')
import django
django.setup()

# Import models after Django setup
from django.contrib.auth import get_user_model
from auth_logs.models import AuthenticationLog, SecurityEvent, AuditTrail
from api_management.models import APIRequest, RateLimitBucket
from security.models import SecurityAuditLog

User = get_user_model()

# Base URL for API requests
BASE_URL = 'http://localhost:8000'

def print_header(message):
    """Print a formatted header."""
    print("\n" + "=" * 80)
    print(f" {message} ".center(80, "="))
    print("=" * 80)

def print_result(test_name, success, message=""):
    """Print a formatted test result."""
    status = "PASSED" if success else "FAILED"
    color = "\033[92m" if success else "\033[91m"  # Green for pass, red for fail
    reset = "\033[0m"
    print(f"{color}{status}{reset}: {test_name}")
    if message:
        print(f"       {message}")

def make_request(endpoint, method='GET', data=None, headers=None):
    """Make an HTTP request to the specified endpoint."""
    url = f"{BASE_URL}{endpoint}"
    print(f"Making {method} request to {url}")
    
    if method == 'GET':
        response = requests.get(url, headers=headers)
    elif method == 'POST':
        response = requests.post(url, json=data, headers=headers)
    elif method == 'PUT':
        response = requests.put(url, json=data, headers=headers)
    elif method == 'DELETE':
        response = requests.delete(url, headers=headers)
    else:
        raise ValueError(f"Unsupported HTTP method: {method}")
    
    print(f"Response status: {response.status_code}")
    try:
        print(f"Response body: {json.dumps(response.json(), indent=2)}")
    except:
        print(f"Response body: {response.text}")
    
    return response

def test_security_headers():
    """Test that security headers are properly set."""
    print_header("Testing Security Headers")
    
    response = make_request('/api/v1/seller/profiles/')
    
    # Check for security headers
    headers_to_check = [
        'Content-Security-Policy',
        'X-Content-Type-Options',
        'X-Frame-Options',
        'X-XSS-Protection',
        'Strict-Transport-Security',
        'Referrer-Policy'
    ]
    
    all_headers_present = True
    missing_headers = []
    
    for header in headers_to_check:
        if header not in response.headers:
            all_headers_present = False
            missing_headers.append(header)
    
    print_result(
        "Security Headers Check", 
        all_headers_present, 
        f"Missing headers: {', '.join(missing_headers)}" if missing_headers else "All security headers present"
    )
    
    return all_headers_present

def test_rate_limiting():
    """Test that rate limiting is properly applied."""
    print_header("Testing Rate Limiting")
    
    # Make multiple requests in quick succession
    endpoint = '/api/v1/seller/register/'
    success = False
    
    for i in range(15):  # Should trigger rate limiting
        print(f"Request {i+1}/15")
        response = make_request(endpoint, method='POST', data={
            'email': f'test{i}@example.com',
            'password': 'TestPassword123!',
            'first_name': 'Test',
            'last_name': 'User'
        })
        
        if response.status_code == 429:  # Too Many Requests
            success = True
            print_result(
                "Rate Limiting Check", 
                True, 
                f"Rate limiting triggered after {i+1} requests"
            )
            break
    
    if not success:
        print_result(
            "Rate Limiting Check", 
            False, 
            "Rate limiting was not triggered after 15 requests"
        )
    
    # Check if rate limit bucket was created
    rate_limit_bucket = RateLimitBucket.objects.filter(ip_address='127.0.0.1').first()
    bucket_exists = rate_limit_bucket is not None
    
    print_result(
        "Rate Limit Bucket Creation", 
        bucket_exists,
        f"Rate limit bucket {'was' if bucket_exists else 'was not'} created"
    )
    
    return success and bucket_exists

def test_api_request_logging():
    """Test that API requests are properly logged."""
    print_header("Testing API Request Logging")
    
    # Make a request
    endpoint = '/api/v1/seller/profiles/'
    response = make_request(endpoint)
    
    # Check if request was logged
    time.sleep(1)  # Give time for async logging
    api_request = APIRequest.objects.filter(endpoint=endpoint).order_by('-created_at').first()
    request_logged = api_request is not None
    
    print_result(
        "API Request Logging", 
        request_logged,
        f"API request {'was' if request_logged else 'was not'} logged"
    )
    
    return request_logged

def test_security_event_logging():
    """Test that security events are properly logged."""
    print_header("Testing Security Event Logging")
    
    # Trigger a security event (e.g., invalid API key)
    endpoint = '/api/v1/data/export/'  # Endpoint that requires API key
    headers = {'X-API-Key': 'invalid.key'}
    response = make_request(endpoint, headers=headers)
    
    # Check if security event was logged
    time.sleep(1)  # Give time for async logging
    security_event = SecurityEvent.objects.filter(
        event_type='INVALID_API_KEY'
    ).order_by('-created_at').first()
    
    event_logged = security_event is not None
    
    print_result(
        "Security Event Logging", 
        event_logged,
        f"Security event {'was' if event_logged else 'was not'} logged"
    )
    
    return event_logged

def test_authentication_logging():
    """Test that authentication events are properly logged."""
    print_header("Testing Authentication Logging")
    
    # Attempt login
    endpoint = '/api/v1/auth/login/'
    response = make_request(
        endpoint, 
        method='POST', 
        data={'email': 'admin@example.com', 'password': 'wrong_password'}
    )
    
    # Check if authentication attempt was logged
    time.sleep(1)  # Give time for async logging
    auth_log = AuthenticationLog.objects.filter(
        action='LOGIN'
    ).order_by('-created_at').first()
    
    auth_logged = auth_log is not None
    
    print_result(
        "Authentication Logging", 
        auth_logged,
        f"Authentication attempt {'was' if auth_logged else 'was not'} logged"
    )
    
    return auth_logged

def test_audit_trail():
    """Test that audit trail is properly maintained."""
    print_header("Testing Audit Trail")
    
    # Create a test user to trigger audit trail
    username = f"testuser_{int(time.time())}"
    user = User.objects.create_user(
        email=f"{username}@example.com",
        password="TestPassword123!",
        first_name="Test",
        last_name="User"
    )
    
    # Check if audit trail was created
    time.sleep(1)  # Give time for async logging
    audit_trail = AuditTrail.objects.filter(
        user=user
    ).order_by('-created_at').first()
    
    audit_logged = audit_trail is not None
    
    print_result(
        "Audit Trail Creation", 
        audit_logged,
        f"Audit trail {'was' if audit_logged else 'was not'} created"
    )
    
    # Clean up
    user.delete()
    
    return audit_logged

def run_all_tests():
    """Run all tests and report results."""
    print_header("SECURITY INTEGRATION TEST SUITE")
    print(f"Started at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    
    tests = [
        test_security_headers,
        test_rate_limiting,
        test_api_request_logging,
        test_security_event_logging,
        test_authentication_logging,
        test_audit_trail
    ]
    
    results = []
    for test in tests:
        try:
            result = test()
            results.append(result)
        except Exception as e:
            print(f"Error running test {test.__name__}: {str(e)}")
            results.append(False)
    
    # Print summary
    print_header("TEST SUMMARY")
    passed = results.count(True)
    total = len(results)
    print(f"Passed: {passed}/{total} ({passed/total*100:.1f}%)")
    
    if passed == total:
        print("\n✅ All tests passed! Security, logging, and API management are properly integrated.")
    else:
        print("\n❌ Some tests failed. Please review the results above.")

if __name__ == "__main__":
    run_all_tests()