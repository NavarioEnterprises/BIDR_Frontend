#!/usr/bin/env python
"""
Test script to verify the Category and CategorySpecification models work correctly.
"""
import os
import sys
import django

# Set up Django environment
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'product_management_service.settings')
django.setup()

from product_management_service.categories.models import Category, CategorySpecification

def test_category_specifications():
    """Test the Category and CategorySpecification models."""
    print("Testing Category and CategorySpecification models...")
    
    # Test case 1: Category without specification
    try:
        category = Category.objects.first()
        if category:
            print(f"\nTest 1: Category without specification")
            print(f"Category: {category.name}")
            print(f"Has specifications: {category.has_specifications()}")
            print(f"Specification type: {category.get_specification_type()}")
            print(f"Specification schema: {category.get_specification_schema()}")
    except Exception as e:
        print(f"Error in Test 1: {e}")
    
    # Test case 2: Create a category with specification
    try:
        print(f"\nTest 2: Create a category with specification")
        # Create a test category if none exists
        test_category, created = Category.objects.get_or_create(
            name="Test Category",
            slug="test-category",
            defaults={
                "description": "Test category for specification testing"
            }
        )
        print(f"Category: {test_category.name} ({'created' if created else 'existing'})")
        
        # Create or update specification
        spec_schema = {
            "type": "object",
            "properties": {
                "brand": {"type": "string"},
                "model": {"type": "string"},
                "year": {"type": "integer"}
            }
        }
        
        spec, spec_created = CategorySpecification.objects.get_or_create(
            category=test_category,
            defaults={
                "category_type": "ELECTRONICS",
                "specification_schema": spec_schema
            }
        )
        
        if not spec_created:
            # Update existing specification
            spec.specification_schema = spec_schema
            spec.save()
            
        print(f"Specification: {spec} ({'created' if spec_created else 'updated'})")
        print(f"Has specifications: {test_category.has_specifications()}")
        print(f"Specification type: {test_category.get_specification_type()}")
        print(f"Specification schema: {test_category.get_specification_schema()}")
    except Exception as e:
        print(f"Error in Test 2: {e}")
    
    # Test case 3: Child category inheriting specification from parent
    try:
        print(f"\nTest 3: Child category inheriting specification from parent")
        # Create a child category
        child_category, child_created = Category.objects.get_or_create(
            name="Child Test Category",
            slug="child-test-category",
            defaults={
                "description": "Child test category inheriting specifications",
                "parent": test_category
            }
        )
        
        if not child_created and not child_category.parent:
            # Update parent if it doesn't have one
            child_category.parent = test_category
            child_category.save()
            
        print(f"Child category: {child_category.name} ({'created' if child_created else 'existing'})")
        print(f"Parent category: {child_category.parent.name if child_category.parent else 'None'}")
        print(f"Has specifications: {child_category.has_specifications()}")
        print(f"Specification type: {child_category.get_specification_type()}")
        print(f"Specification schema: {child_category.get_specification_schema()}")
    except Exception as e:
        print(f"Error in Test 3: {e}")

if __name__ == "__main__":
    test_category_specifications()