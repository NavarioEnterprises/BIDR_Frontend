"""
Comprehensive tests for Categories app.
"""

# Set up Django environment if not already configured
import os
import django
from django.conf import settings

if not settings.configured:
    os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'product_management_service.settings')
    django.setup()

from django.test import TestCase
from django.contrib.auth.models import User
from django.core.exceptions import ValidationError
from rest_framework.test import APIClient, APITestCase
from rest_framework import status
from rest_framework_simplejwt.tokens import RefreshToken
from decimal import Decimal
from .models import Category, CategoryAttribute
from core.models import StatusChoices


class CategoryModelTest(TestCase):
    """Test Category model functionality."""
    
    def setUp(self):
        self.category = Category.objects.create(
            name="Electronics",
            slug="electronics",
            description="Electronic products and gadgets",
            status=StatusChoices.ACTIVE
        )
    
    def test_category_creation(self):
        """Test category is created properly."""
        self.assertEqual(self.category.name, "Electronics")
        self.assertEqual(self.category.slug, "electronics")
        self.assertEqual(self.category.status, StatusChoices.ACTIVE)
        self.assertIsNotNone(self.category.id)
        self.assertTrue(self.category.show_in_menu)
        self.assertFalse(self.category.is_featured)
    
    def test_category_str_representation(self):
        """Test string representation of category."""
        self.assertEqual(str(self.category), "Electronics")
    
    def test_full_name_property(self):
        """Test full_name property for nested categories."""
        # Test root category
        self.assertEqual(self.category.full_name, "Electronics")
        
        # Test child category
        child_category = Category.objects.create(
            name="Smartphones",
            slug="smartphones",
            parent=self.category,
            status=StatusChoices.ACTIVE
        )
        self.assertEqual(child_category.full_name, "Electronics > Smartphones")
        
        # Test deeply nested category
        grandchild_category = Category.objects.create(
            name="Android Phones",
            slug="android-phones",
            parent=child_category,
            status=StatusChoices.ACTIVE
        )
        self.assertEqual(grandchild_category.full_name, "Electronics > Smartphones > Android Phones")
    
    def test_breadcrumbs_property(self):
        """Test breadcrumbs property."""
        child_category = Category.objects.create(
            name="Smartphones",
            slug="smartphones",
            parent=self.category,
            status=StatusChoices.ACTIVE
        )
        
        breadcrumbs = child_category.breadcrumbs
        self.assertEqual(len(breadcrumbs), 2)
        self.assertEqual(breadcrumbs[0]['name'], "Electronics")
        self.assertEqual(breadcrumbs[1]['name'], "Smartphones")
    
    def test_get_active_children(self):
        """Test get_active_children method."""
        # Create active child
        active_child = Category.objects.create(
            name="Smartphones",
            slug="smartphones",
            parent=self.category,
            status=StatusChoices.ACTIVE
        )
        
        # Create inactive child
        Category.objects.create(
            name="Tablets",
            slug="tablets",
            parent=self.category,
            status=StatusChoices.INACTIVE
        )
        
        active_children = self.category.get_active_children()
        self.assertEqual(active_children.count(), 1)
        self.assertEqual(active_children.first(), active_child)
    
    def test_commission_rate_validation(self):
        """Test commission rate validation."""
        # Test valid commission rate
        category = Category.objects.create(
            name="Test Category",
            slug="test-category",
            commission_rate=Decimal('10.50')
        )
        self.assertEqual(category.commission_rate, Decimal('10.50'))
        
    def test_category_ordering(self):
        """Test category ordering by sort_order and name."""
        category_b = Category.objects.create(
            name="B Category",
            slug="b-category",
            sort_order=2
        )
        category_a = Category.objects.create(
            name="A Category",
            slug="a-category",
            sort_order=1
        )
        
        categories = Category.objects.all()
        self.assertEqual(categories[0], category_a)
        self.assertEqual(categories[1], category_b)
    
    def test_category_meta_fields(self):
        """Test SEO meta fields."""
        category = Category.objects.create(
            name="SEO Category",
            slug="seo-category",
            meta_title="SEO Title",
            meta_description="SEO Description"
        )
        self.assertEqual(category.meta_title, "SEO Title")
        self.assertEqual(category.meta_description, "SEO Description")


class CategoryAttributeModelTest(TestCase):
    """Test CategoryAttribute model functionality."""
    
    def setUp(self):
        self.category = Category.objects.create(
            name="Electronics",
            slug="electronics",
            status=StatusChoices.ACTIVE
        )
        self.attribute = CategoryAttribute.objects.create(
            category=self.category,
            name="brand",
            attribute_type="text",
            is_required=True
        )
    
    def test_attribute_creation(self):
        """Test category attribute is created properly."""
        self.assertEqual(self.attribute.name, "brand")
        self.assertEqual(self.attribute.attribute_type, "text")
        self.assertTrue(self.attribute.is_required)
        self.assertEqual(self.attribute.category, self.category)
        self.assertTrue(self.attribute.is_filterable)
        self.assertFalse(self.attribute.is_searchable)
    
    def test_display_label_property(self):
        """Test display_label property."""
        self.assertEqual(self.attribute.display_label, "Brand")
        
        # Test with custom label
        self.attribute.label = "Product Brand"
        self.attribute.save()
        self.assertEqual(self.attribute.display_label, "Product Brand")
    
    def test_attribute_types(self):
        """Test different attribute types."""
        # Number attribute
        number_attr = CategoryAttribute.objects.create(
            category=self.category,
            name="price",
            attribute_type="number",
            min_value=0,
            max_value=10000
        )
        self.assertEqual(number_attr.attribute_type, "number")
        self.assertEqual(number_attr.min_value, 0)
        self.assertEqual(number_attr.max_value, 10000)
        
        # Choice attribute
        choice_attr = CategoryAttribute.objects.create(
            category=self.category,
            name="color",
            attribute_type="choice",
            choices=["Red", "Blue", "Green"]
        )
        self.assertEqual(choice_attr.attribute_type, "choice")
        self.assertEqual(choice_attr.choices, ["Red", "Blue", "Green"])
    
    def test_attribute_validation_constraints(self):
        """Test attribute validation constraints."""
        # Text length constraints
        text_attr = CategoryAttribute.objects.create(
            category=self.category,
            name="description",
            attribute_type="text",
            min_length=10,
            max_length=500
        )
        self.assertEqual(text_attr.min_length, 10)
        self.assertEqual(text_attr.max_length, 500)
    
    def test_attribute_unique_constraint(self):
        """Test unique constraint on category + name."""
        with self.assertRaises(Exception):
            CategoryAttribute.objects.create(
                category=self.category,
                name="brand",  # Same name as existing attribute
                attribute_type="text"
            )
    
    def test_attribute_ordering(self):
        """Test attribute ordering."""
        attr_b = CategoryAttribute.objects.create(
            category=self.category,
            name="attr_b",
            attribute_type="text",
            sort_order=2
        )
        attr_a = CategoryAttribute.objects.create(
            category=self.category,
            name="attr_a",
            attribute_type="text",
            sort_order=1
        )
        
        attributes = CategoryAttribute.objects.filter(category=self.category)
        # First should be brand (sort_order=0), then attr_a, then attr_b
        self.assertEqual(attributes[0], self.attribute)
        self.assertEqual(attributes[1], attr_a)
        self.assertEqual(attributes[2], attr_b)


class CategoryAPITest(APITestCase):
    """Test Category API endpoints."""
    
    def setUp(self):
        self.user = User.objects.create_user(
            username='testuser',
            email='test@example.com',
            password='testpass123'
        )
        self.client = APIClient()
        
        # Create test categories
        self.parent_category = Category.objects.create(
            name="Electronics",
            slug="electronics",
            description="Electronic products",
            status=StatusChoices.ACTIVE
        )
        
        self.child_category = Category.objects.create(
            name="Smartphones",
            slug="smartphones",
            parent=self.parent_category,
            status=StatusChoices.ACTIVE
        )
    
    def get_jwt_token(self, user):
        """Get JWT token for user."""
        refresh = RefreshToken.for_user(user)
        return str(refresh.access_token)
    
    def test_list_categories_anonymous(self):
        """Test listing categories without authentication."""
        url = '/api/v1/categories/categories/'
        response = self.client.get(url)
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('results', response.data)
        self.assertEqual(len(response.data['results']), 2)
    
    def test_create_category_authenticated(self):
        """Test creating category with authentication."""
        token = self.get_jwt_token(self.user)
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {token}')
        
        url = '/api/v1/categories/categories/'
        data = {
            'name': 'New Category',
            'slug': 'new-category',
            'description': 'A new test category',
            'status': StatusChoices.ACTIVE
        }
        
        response = self.client.post(url, data, format='json')
        
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(response.data['name'], 'New Category')
        self.assertEqual(response.data['slug'], 'new-category')
    
    def test_create_category_unauthenticated(self):
        """Test creating category without authentication fails."""
        url = '/api/v1/categories/categories/'
        data = {
            'name': 'New Category',
            'slug': 'new-category'
        }
        
        response = self.client.post(url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)
    
    def test_retrieve_category(self):
        """Test retrieving a specific category."""
        url = f'/api/v1/categories/categories/{self.parent_category.id}/'
        response = self.client.get(url)
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['name'], 'Electronics')
        self.assertEqual(response.data['slug'], 'electronics')
    
    def test_update_category(self):
        """Test updating a category."""
        token = self.get_jwt_token(self.user)
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {token}')
        
        url = f'/api/v1/categories/categories/{self.parent_category.id}/'
        data = {
            'name': 'Updated Electronics',
            'slug': 'electronics',
            'description': 'Updated description'
        }
        
        response = self.client.patch(url, data, format='json')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['name'], 'Updated Electronics')
        self.assertEqual(response.data['description'], 'Updated description')
    
    def test_delete_category(self):
        """Test deleting a category."""
        token = self.get_jwt_token(self.user)
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {token}')
        
        # Create a category to delete
        category_to_delete = Category.objects.create(
            name="Delete Me",
            slug="delete-me"
        )
        
        url = f'/api/v1/categories/categories/{category_to_delete.id}/'
        response = self.client.delete(url)
        
        self.assertEqual(response.status_code, status.HTTP_204_NO_CONTENT)
        self.assertFalse(Category.objects.filter(id=category_to_delete.id).exists())
    
    def test_category_search(self):
        """Test category search functionality."""
        url = '/api/v1/categories/categories/?search=Electronics'
        response = self.client.get(url)
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data['results']), 1)
        self.assertEqual(response.data['results'][0]['name'], 'Electronics')
    
    def test_category_filtering(self):
        """Test category filtering."""
        # Filter by status
        url = f'/api/v1/categories/categories/?status={StatusChoices.ACTIVE}'
        response = self.client.get(url)
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        for category in response.data['results']:
            self.assertEqual(category['status'], StatusChoices.ACTIVE)
        
        # Filter by parent
        url = f'/api/v1/categories/categories/?parent={self.parent_category.id}'
        response = self.client.get(url)
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data['results']), 1)
        self.assertEqual(response.data['results'][0]['name'], 'Smartphones')


class CategoryAttributeAPITest(APITestCase):
    """Test CategoryAttribute API endpoints."""
    
    def setUp(self):
        self.user = User.objects.create_user(
            username='testuser',
            email='test@example.com',
            password='testpass123'
        )
        self.client = APIClient()
        
        self.category = Category.objects.create(
            name="Electronics",
            slug="electronics",
            status=StatusChoices.ACTIVE
        )
        
        self.attribute = CategoryAttribute.objects.create(
            category=self.category,
            name="brand",
            attribute_type="text",
            is_required=True
        )
    
    def get_jwt_token(self, user):
        """Get JWT token for user."""
        refresh = RefreshToken.for_user(user)
        return str(refresh.access_token)
    
    def test_list_attributes_requires_auth(self):
        """Test listing attributes requires authentication."""
        url = '/api/v1/categories/attributes/'
        response = self.client.get(url)
        
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)
    
    def test_list_attributes_authenticated(self):
        """Test listing attributes with authentication."""
        token = self.get_jwt_token(self.user)
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {token}')
        
        url = '/api/v1/categories/attributes/'
        response = self.client.get(url)
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data['results']), 1)
        self.assertEqual(response.data['results'][0]['name'], 'brand')
    
    def test_create_attribute(self):
        """Test creating a category attribute."""
        token = self.get_jwt_token(self.user)
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {token}')
        
        url = '/api/v1/categories/attributes/'
        data = {
            'category': self.category.id,
            'name': 'color',
            'attribute_type': 'choice',
            'choices': ['Red', 'Blue', 'Green'],
            'is_required': False,
            'is_filterable': True
        }
        
        response = self.client.post(url, data, format='json')
        
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(response.data['name'], 'color')
        self.assertEqual(response.data['attribute_type'], 'choice')
        self.assertEqual(response.data['choices'], ['Red', 'Blue', 'Green'])
    
    def test_attribute_filtering(self):
        """Test attribute filtering."""
        token = self.get_jwt_token(self.user)
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {token}')
        
        # Create another attribute
        CategoryAttribute.objects.create(
            category=self.category,
            name="price",
            attribute_type="number",
            is_required=False
        )
        
        # Filter by category
        url = f'/api/v1/categories/attributes/?category={self.category.id}'
        response = self.client.get(url)
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data['results']), 2)
        
        # Filter by attribute type
        url = '/api/v1/categories/attributes/?attribute_type=text'
        response = self.client.get(url)
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data['results']), 1)
        self.assertEqual(response.data['results'][0]['attribute_type'], 'text')
    
    def test_attribute_search(self):
        """Test attribute search functionality."""
        token = self.get_jwt_token(self.user)
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {token}')
        
        url = '/api/v1/categories/attributes/?search=brand'
        response = self.client.get(url)
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data['results']), 1)
        self.assertEqual(response.data['results'][0]['name'], 'brand')
    
    def test_update_attribute(self):
        """Test updating an attribute."""
        token = self.get_jwt_token(self.user)
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {token}')
        
        url = f'/api/v1/categories/attributes/{self.attribute.id}/'
        data = {
            'label': 'Product Brand',
            'help_text': 'Enter the brand name of the product'
        }
        
        response = self.client.patch(url, data, format='json')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['label'], 'Product Brand')
        self.assertEqual(response.data['help_text'], 'Enter the brand name of the product')
    
    def test_delete_attribute(self):
        """Test deleting an attribute."""
        token = self.get_jwt_token(self.user)
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {token}')
        
        # Create an attribute to delete
        attr_to_delete = CategoryAttribute.objects.create(
            category=self.category,
            name="temp_attr",
            attribute_type="text"
        )
        
        url = f'/api/v1/categories/attributes/{attr_to_delete.id}/'
        response = self.client.delete(url)
        
        self.assertEqual(response.status_code, status.HTTP_204_NO_CONTENT)
        self.assertFalse(CategoryAttribute.objects.filter(id=attr_to_delete.id).exists())
