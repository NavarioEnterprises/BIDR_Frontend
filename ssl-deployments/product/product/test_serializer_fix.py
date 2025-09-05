#!/usr/bin/env python
"""
Test script to verify that the serializer fix works with the exact data format
that the frontend is sending.
"""

import os
import sys
import django
import json

# Set up Django environment
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'product_management_service.settings')
django.setup()

from product_requests.serializers import ProductRequestCreateSerializer
from django.contrib.auth.models import User


def test_frontend_data_format():
    """Test with the exact data format from the frontend."""
    print("Testing frontend data format...")
    
    # Get or create a test user
    user, created = User.objects.get_or_create(
        username='test_user', 
        defaults={'email': 'test@example.com'}
    )
    
    # This is the exact data format your frontend is sending
    frontend_data = {
        "category": "VEHICLE_SPARES",
        "buyer_id": user.id,
        "title": "Test Frontend Format",
        "description": "Testing frontend JSON format",
        "product_specifications": {
            "vehicle_make": "Toyota",
            "vehicle_model": "Corolla",
            "vehicle_year": 2024,
            "vehicle_type": "PASSENGER_CAR",
            "engine_size": "",
            "vin_number": "",
            "part_name": "gjh",
            "part_category": "OTHER",
            "part_number": "hhk",
            "quantity": 2,
            "condition_preference": "NEW",
            "urgency": "12_HOURS",
            "description": "uikk",
            "compatible_models": "",
            "preferred_brand": "",
            "avoid_brands": "",
            "installation_required": "NO",
            "warranty_required": "NO",
            "warranty_duration": "",
            "energy_efficiency_required": "NO",
            "currency": "ZAR",
            "location_info": {
                "address": "Selected Location: -26.2041, 28.0473",
                "lat": -26.2041,
                "lng": 28.0473
            }
        },
        "quantity": 2,
        "condition_preference": "NEW",
        "max_budget": "1000.00",
        "currency": "ZAR",
        "buyer_location": {
            "address": "Selected Location: -26.2041, 28.0473",
            "lat": -26.2041,
            "lng": 28.0473
        },
        "urgency_timeline": "12_HOURS",
        "terms_accepted": True,
        "contact_consent": True,
        "vehicle_spares_data": {
            "vehicle_make": "Toyota",
            "vehicle_model": "Corolla",
            "vehicle_year": 2024,
            "vehicle_type": "PASSENGER_CAR",
            "engine_size": "",
            "vin_number": "",
            "part_name": "gjh",
            "part_category": "OTHER",
            "part_number": "hhk",
            "quantity": 2,
            "condition_preference": "NEW",
            "urgency": "12_HOURS",
            "description": "uikk",
            "compatible_models": "",
            "preferred_brand": "",
            "avoid_brands": "",
            "installation_required": "NO",
            "warranty_required": "NO",
            "warranty_duration": "",
            "energy_efficiency_required": "NO",
            "currency": "ZAR",
            "location_info": {
                "address": "Selected Location: -26.2041, 28.0473",
                "lat": -26.2041,
                "lng": 28.0473
            }
        }
    }
    
    # Test with the current serializer
    serializer = ProductRequestCreateSerializer(data=frontend_data)
    
    print(f"Is valid: {serializer.is_valid()}")
    
    if not serializer.is_valid():
        print(f"Validation errors: {serializer.errors}")
        return False
    else:
        print("Validation successful!")
        print(f"Validated data keys: {list(serializer.validated_data.keys())}")
        
        # Try to create the object
        try:
            product_request = serializer.save()
            print(f"Successfully created product request: {product_request.request_id}")
            return True
        except Exception as e:
            print(f"Error creating product request: {e}")
            return False


def test_string_data_format():
    """Test with data where JSON fields are strings (multipart form data format)."""
    print("\nTesting string data format...")
    
    # Get or create a test user
    user, created = User.objects.get_or_create(
        username='test_user', 
        defaults={'email': 'test@example.com'}
    )
    
    # This simulates multipart form data where JSON objects are sent as strings
    string_data = {
        "category": "VEHICLE_SPARES",
        "buyer_id": user.id,
        "title": "Test String Format",
        "description": "Testing string JSON format",
        "product_specifications": json.dumps({
            "vehicle_make": "Toyota",
            "vehicle_model": "Corolla",
            "vehicle_year": 2024,
            "part_name": "Test Part"
        }),
        "quantity": 2,
        "condition_preference": "NEW",
        "max_budget": "1000.00",
        "currency": "ZAR",
        "buyer_location": json.dumps({
            "address": "Selected Location: -26.2041, 28.0473",
            "lat": -26.2041,
            "lng": 28.0473
        }),
        "urgency_timeline": "12_HOURS",
        "terms_accepted": True,
        "contact_consent": True,
        "vehicle_spares_data": json.dumps({
            "vehicle_make": "Toyota",
            "vehicle_model": "Corolla",
            "vehicle_year": 2024,
            "vehicle_type": "PASSENGER_CAR",
            "part_name": "Test Part",
            "part_category": "OTHER",
            "quantity": 2,
            "condition_preference": "NEW",
            "urgency": "12_HOURS",
            "description": "Test description"
        })
    }
    
    # Test with the current serializer
    serializer = ProductRequestCreateSerializer(data=string_data)
    
    print(f"Is valid: {serializer.is_valid()}")
    
    if not serializer.is_valid():
        print(f"Validation errors: {serializer.errors}")
        return False
    else:
        print("Validation successful!")
        print(f"Validated data keys: {list(serializer.validated_data.keys())}")
        
        # Try to create the object
        try:
            product_request = serializer.save()
            print(f"Successfully created product request: {product_request.request_id}")
            return True
        except Exception as e:
            print(f"Error creating product request: {e}")
            return False


if __name__ == "__main__":
    print("=" * 50)
    print("Testing ProductRequestCreateSerializer Fix")
    print("=" * 50)
    
    # Test both formats
    frontend_success = test_frontend_data_format()
    string_success = test_string_data_format()
    
    print("\n" + "=" * 50)
    print("Test Results:")
    print(f"Frontend format (dict): {'✓ PASS' if frontend_success else '✗ FAIL'}")
    print(f"String format (form): {'✓ PASS' if string_success else '✗ FAIL'}")
    
    if frontend_success and string_success:
        print("🎉 All tests passed! The serializer fix is working correctly.")
    else:
        print("❌ Some tests failed. Need to investigate further.")
