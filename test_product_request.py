#!/usr/bin/env python
"""
Test script to verify the ProductRequest model works correctly with category specifications.
"""
import os
import sys
import django
import json

# Set up Django environment
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'product_management_service.settings')
try:
    django.setup()
except ModuleNotFoundError:
    # Try alternative settings module
    os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'settings')
    try:
        django.setup()
    except ModuleNotFoundError:
        print("Could not find Django settings module. Please ensure the settings module exists.")
        sys.exit(1)

from product_management_service.product_requests.models import ProductRequest
from product_management_service.categories.models import Category, CategorySpecification
from django.contrib.auth.models import User

def test_product_request_with_specifications():
    """Test the ProductRequest model with category specifications."""
    print("Testing ProductRequest model with category specifications...")
    
    # Get or create a test user
    user, created = User.objects.get_or_create(
        username="testuser",
        defaults={
            "email": "test@example.com",
            "is_active": True
        }
    )
    print(f"Test user: {user.username} ({'created' if created else 'existing'})")
    
    # Test case 1: Get a category with specifications
    try:
        print("\nTest 1: Get a category with specifications")
        # Find a category with specifications
        category_spec = CategorySpecification.objects.first()
        if category_spec:
            category = category_spec.category
            print(f"Found category: {category.name}")
            print(f"Specification type: {category.get_specification_type()}")
            print(f"Specification schema: {json.dumps(category.get_specification_schema(), indent=2)}")
        else:
            print("No categories with specifications found. Please run setup_categories command first.")
            return
    except Exception as e:
        print(f"Error in Test 1: {e}")
        return
    
    # Test case 2: Create a product request for the category
    try:
        print("\nTest 2: Create a product request for the category")
        
        # Create sample specifications based on the category type
        spec_type = category.get_specification_type()
        if spec_type == 'VEHICLE_SPARES':
            sample_specs = {
                "manufacturer": "Toyota",
                "make_model": "Corolla 2018",
                "year": "2018",
                "part_name": "Oil Filter",
                "part_condition": "New"
            }
        elif spec_type == 'ELECTRONICS':
            sample_specs = {
                "electronics_type": "Washing Machine",
                "brand_preference": "Samsung",
                "model_series": "EcoBubble",
                "features_required": ["Energy Efficient", "Quick Wash"]
            }
        elif spec_type == 'TYRES_RIMS':
            sample_specs = {
                "tyre_width": "205",
                "sidewall_profile": "55",
                "rim_diameter": "16",
                "select_type": "Tyres",
                "vehicle_type": "Passenger Car"
            }
        else:
            sample_specs = {"generic_field": "Test value"}
        
        # Create the product request
        product_request = ProductRequest(
            buyer_id=user,
            category=spec_type,
            product_specifications=sample_specs,
            quantity=1,
            condition_preference="NEW",
            buyer_location={"latitude": -33.9249, "longitude": 18.4241, "address": "Cape Town, South Africa"},
            urgency_timeline="1_WEEK",
            terms_accepted=True,
            contact_consent=True
        )
        
        # Save without validation first to test auto-title generation
        product_request.save(validate_specs=False)
        print(f"Created product request: {product_request}")
        print(f"Auto-generated title: {product_request.title}")
        
        # Test the helper functions
        print(f"Specification type: {product_request.get_specification_type()}")
        print(f"Has valid specifications: {product_request.validate_specifications()[0]}")
        
        # Test generating title from specifications
        generated_title = product_request.generate_title_from_specifications()
        print(f"Generated title: {generated_title}")
        
    except Exception as e:
        print(f"Error in Test 2: {e}")
    
    # Test case 3: Validate specifications against schema
    try:
        print("\nTest 3: Validate specifications against schema")
        
        # Get the schema
        schema = product_request.get_specification_schema()
        print(f"Schema for {spec_type}: {json.dumps(schema, indent=2) if schema else 'None'}")
        
        # Validate the specifications
        is_valid, message = product_request.validate_specifications()
        print(f"Specifications valid: {is_valid}")
        print(f"Validation message: {message}")
        
        # Test with invalid specifications
        invalid_specs = {}
        product_request.product_specifications = invalid_specs
        is_valid, message = product_request.validate_specifications()
        print(f"Empty specifications valid: {is_valid}")
        print(f"Validation message: {message}")
        
    except Exception as e:
        print(f"Error in Test 3: {e}")

if __name__ == "__main__":
    test_product_request_with_specifications()