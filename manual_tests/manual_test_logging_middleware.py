#!/usr/bin/env python
"""
Test script to verify the API logging middleware is working correctly.
This script makes various API requests to test different scenarios.
"""

import os
import sys
import django
import requests
import json
import time

# Setup Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'product_management_service.settings')
django.setup()

from django.contrib.auth.models import User
from django.test import Client
from app_logs.models import APIRequestLog, ErrorLog, PerformanceLog


def test_middleware_with_django_client():
    """Test the middleware using Django's test client."""
    print("=== Testing with Django Test Client ===")
    
    client = Client()
    
    # Create a test user
    try:
        user = User.objects.get(username='test_user')
    except User.DoesNotExist:
        user = User.objects.create_user(username='test_user', password='test_password')
    
    print("1. Testing API request logging...")
    
    # Log in the user
    client.force_login(user)
    
    # Test different endpoints
    test_endpoints = [
        ('/product-requests/requests/', 'GET', 'Product Requests List'),
        ('/categories/categories/', 'GET', 'Categories List'),
        ('/analytics/product-request-analytics/', 'GET', 'Analytics'),
        ('/admin/login/', 'GET', 'Admin Login (should not be logged)'),
        ('/nonexistent-endpoint/', 'GET', 'Non-existent endpoint'),
    ]
    
    for endpoint, method, description in test_endpoints:
        print(f"  Making {method} request to {endpoint} - {description}")
        
        try:
            if method == 'GET':
                response = client.get(endpoint)
            elif method == 'POST':
                response = client.post(endpoint, data={'test': 'data'})
            
            print(f"    Response status: {response.status_code}")
        except Exception as e:
            print(f"    Error: {e}")
        
        time.sleep(0.1)  # Small delay
    
    print("\n2. Checking logged requests...")
    
    # Check if requests were logged
    logs = APIRequestLog.objects.all().order_by('-timestamp')
    print(f"  Total API requests logged: {logs.count()}")
    
    for log in logs[:5]:  # Show last 5 logs
        print(f"    {log.method} {log.path} - Status: {log.status_code} - Duration: {log.duration_ms}ms")
        if log.user:
            print(f"      User: {log.user.username}")
        else:
            print(f"      User: Anonymous")
    
    print("\n3. Checking error logs...")
    
    error_logs = ErrorLog.objects.all().order_by('-timestamp')
    print(f"  Total errors logged: {error_logs.count()}")
    
    for error in error_logs[:3]:  # Show last 3 errors
        print(f"    {error.error_type}: {error.error_message[:100]}...")
    
    print("\n4. Testing slow request logging...")
    
    # Create a view that takes a long time (simulate by checking performance logs)
    performance_logs = PerformanceLog.objects.all().order_by('-timestamp')
    print(f"  Total performance logs: {performance_logs.count()}")
    
    for perf in performance_logs[:3]:
        print(f"    {perf.metric_name}: {perf.metric_value} {perf.metric_unit} - {perf.operation}")


def test_middleware_statistics():
    """Show statistics about logged requests."""
    print("\n=== Middleware Statistics ===")
    
    # API Request statistics
    total_requests = APIRequestLog.objects.count()
    successful_requests = APIRequestLog.objects.filter(status_code__lt=400).count()
    client_errors = APIRequestLog.objects.filter(status_code__gte=400, status_code__lt=500).count()
    server_errors = APIRequestLog.objects.filter(status_code__gte=500).count()
    
    print(f"Total API Requests: {total_requests}")
    print(f"Successful Requests (2xx-3xx): {successful_requests}")
    print(f"Client Errors (4xx): {client_errors}")
    print(f"Server Errors (5xx): {server_errors}")
    
    if total_requests > 0:
        # Average response time
        from django.db.models import Avg
        avg_duration = APIRequestLog.objects.aggregate(avg_duration=Avg('duration_ms'))
        print(f"Average Response Time: {avg_duration['avg_duration']:.2f}ms")
    
    # Error statistics
    total_errors = ErrorLog.objects.count()
    resolved_errors = ErrorLog.objects.filter(is_resolved=True).count()
    unresolved_errors = ErrorLog.objects.filter(is_resolved=False).count()
    
    print(f"\nError Logs:")
    print(f"Total Errors: {total_errors}")
    print(f"Resolved Errors: {resolved_errors}")
    print(f"Unresolved Errors: {unresolved_errors}")
    
    # Performance statistics
    slow_requests = PerformanceLog.objects.filter(metric_name='response_time').count()
    print(f"\nPerformance Logs:")
    print(f"Slow Requests (>2s): {slow_requests}")


def clear_logs():
    """Clear all log entries for fresh testing."""
    print("\n=== Clearing Existing Logs ===")
    
    api_count = APIRequestLog.objects.count()
    error_count = ErrorLog.objects.count()
    perf_count = PerformanceLog.objects.count()
    
    APIRequestLog.objects.all().delete()
    ErrorLog.objects.all().delete()
    PerformanceLog.objects.all().delete()
    
    print(f"Cleared {api_count} API request logs")
    print(f"Cleared {error_count} error logs")
    print(f"Cleared {perf_count} performance logs")


def create_sample_post_request():
    """Test POST request logging with JSON data."""
    print("\n=== Testing POST Request with JSON Data ===")
    
    client = Client()
    
    # Create a test user
    try:
        user = User.objects.get(username='test_user')
    except User.DoesNotExist:
        user = User.objects.create_user(username='test_user', password='test_password')
    
    client.force_login(user)
    
    # Sample JSON data for product request
    test_data = {
        'title': 'Test Product Request',
        'description': 'This is a test product request created by the logging middleware test',
        'category': 1,
        'urgency': 'medium',
        'location': 'Test Location'
    }
    
    print("Making POST request with JSON data...")
    response = client.post(
        '/product-requests/requests/',
        data=json.dumps(test_data),
        content_type='application/json'
    )
    
    print(f"Response status: {response.status_code}")
    
    # Check if the request was logged with the JSON body
    latest_log = APIRequestLog.objects.filter(method='POST', path='/product-requests/requests/').first()
    if latest_log:
        print("✓ POST request was logged successfully")
        print(f"  Request body captured: {latest_log.request_body is not None}")
        print(f"  Response time: {latest_log.duration_ms}ms")
        if latest_log.request_body:
            print(f"  Request body preview: {latest_log.request_body[:100]}...")
    else:
        print("✗ POST request was not logged")


if __name__ == '__main__':
    print("API Logging Middleware Test")
    print("=" * 50)
    
    # Clear existing logs for clean testing
    clear_logs()
    
    # Run tests
    test_middleware_with_django_client()
    create_sample_post_request()
    test_middleware_statistics()
    
    print("\n" + "=" * 50)
    print("Test completed! Check the Django admin to see logged requests.")
    print("You can also check the database directly to see the logging data.")
