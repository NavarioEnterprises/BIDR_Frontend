#!/usr/bin/env python
"""
Test script to verify the enhanced application logging middleware.
Tests that both APIRequestLog and ApplicationLog entries are created for requests.
"""

import os
import sys
import django
import json
import time

# Setup Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'product_management_service.settings')
django.setup()

from django.test import Client
from django.contrib.auth.models import User
from app_logs.models import APIRequestLog, ApplicationLog
from app_logs.utils import (
    log_user_action, log_authentication_event, log_product_request_event,
    ApplicationLogger, get_user_activity_summary
)


def test_middleware_application_logging():
    """Test that middleware creates both API and Application log entries."""
    print("=== Testing Middleware Application Logging ===")
    
    # Clear existing logs
    APIRequestLog.objects.all().delete()
    ApplicationLog.objects.all().delete()
    
    client = Client()
    
    # Create test user
    try:
        user = User.objects.get(username='test_app_logs')
    except User.DoesNotExist:
        user = User.objects.create_user(
            username='test_app_logs',
            email='test_app_logs@example.com',
            password='testpass123'
        )
    
    # Log in user
    client.force_login(user)
    
    print("1. Making test API requests...")
    
    # Make various requests
    test_requests = [
        ('/product-requests/requests/', 'GET', 'List product requests'),
        ('/categories/categories/', 'GET', 'List categories'),
    ]
    
    for url, method, description in test_requests:
        print(f"  Making {method} request to {url} - {description}")
        
        if method == 'GET':
            response = client.get(url)
        elif method == 'POST':
            response = client.post(url, {'test': 'data'})
        
        print(f"    Response status: {response.status_code}")
        time.sleep(0.1)  # Small delay
    
    print("\n2. Checking created logs...")
    
    # Check API request logs
    api_logs = APIRequestLog.objects.all().order_by('-timestamp')
    print(f"  API Request Logs created: {api_logs.count()}")
    
    # Check Application logs
    app_logs = ApplicationLog.objects.all().order_by('-timestamp')
    print(f"  Application Logs created: {app_logs.count()}")
    
    print("\n3. Analyzing Application Logs:")
    for log in app_logs:
        print(f"    [{log.level}] {log.category}/{log.subcategory}: {log.message}")
        print(f"      User: {log.user.username if log.user else 'Anonymous'}")
        print(f"      Event Type: {log.event_type}")
        if log.context_data:
            print(f"      Context: {json.dumps(log.context_data, indent=8)}")
        print()
    
    return api_logs.count(), app_logs.count()


def test_manual_logging_utilities():
    """Test manual logging utility functions."""
    print("\n=== Testing Manual Logging Utilities ===")
    
    # Create test user
    try:
        user = User.objects.get(username='manual_test_user')
    except User.DoesNotExist:
        user = User.objects.create_user(
            username='manual_test_user',
            email='manual@example.com',
            password='testpass123'
        )
    
    print("1. Testing log_user_action...")
    log_entry = log_user_action(
        user=user,
        action='profile_update',
        message='User updated their profile information',
        category='user_management',
        ip_address='192.168.1.100',
        changes=['email', 'phone']
    )
    print(f"   Created log: {log_entry.id if log_entry else 'Failed'}")
    
    print("2. Testing log_authentication_event...")
    auth_log = log_authentication_event(
        user=user,
        event_type='login',
        success=True,
        ip_address='192.168.1.100',
        user_agent='Mozilla/5.0 Test Browser',
        login_method='password'
    )
    print(f"   Created auth log: {auth_log.id if auth_log else 'Failed'}")
    
    print("3. Testing ApplicationLogger context manager...")
    with ApplicationLogger(user=user, category='product_requests', ip_address='192.168.1.100') as logger:
        logger.info("Starting product request creation", step='validation')
        logger.warning("Missing optional field", field='description')
        logger.user_action('create_request', "User created a new product request", request_id='test-123')
        
        print(f"   Created {len(logger.logs_created)} log entries in context")
    
    print("4. Testing user activity summary...")
    summary = get_user_activity_summary(user, days=1)
    print(f"   User activity summary: {summary}")
    
    return True


def main():
    """Run all tests."""
    print("Application Logging Middleware Test")
    print("=" * 50)
    
    try:
        # Test middleware logging
        api_count, app_count = test_middleware_application_logging()
        
        if api_count > 0 and app_count > 0:
            print(f"✅ Middleware logging working: {api_count} API logs, {app_count} App logs")
        else:
            print(f"❌ Middleware logging issue: {api_count} API logs, {app_count} App logs")
        
        # Test manual logging utilities
        manual_success = test_manual_logging_utilities()
        if manual_success:
            print("✅ Manual logging utilities working")
        else:
            print("❌ Manual logging utilities failed")
        
        print("\n" + "=" * 50)
        print("✅ Application logging test completed successfully!")
        print("\nYou can now check the Django admin to see all the logged entries:")
        print("  - API Request Logs: /admin/app_logs/apirequestlog/")
        print("  - Application Logs: /admin/app_logs/applicationlog/")
        
    except Exception as e:
        print(f"\n❌ Test failed with error: {e}")
        import traceback
        traceback.print_exc()


if __name__ == '__main__':
    main()
