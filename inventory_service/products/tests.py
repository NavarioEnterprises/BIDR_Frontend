"""
Tests for Products app.
"""

from django.test import TestCase
from django.contrib.auth.models import User
from rest_framework.test import APITestCase, APIClient
from rest_framework import status
from decimal import Decimal

from .models import (
    Product, ProductImage, ProductAttribute, ProductVariant, 
    InventoryLog, ProductReview
)
from categories.models import Category, CategoryAttribute


class ProductModelTest(TestCase):
    """
    Test cases for Product model.
    """
    
    def setUp(self):
        """Set up test data."""
        self.user = User.objects.create_user(
            username='testuser',
            email='test@example.com',
            password='testpass123'
        )
        
        self.category = Category.objects.create(
            name='Test Category',
            slug='test-category',
            description='A test category'
        )
        
        self.product = Product.objects.create(
            name='Test Product',
            slug='test-product',
            description='A test product',
            category=self.category,
            sku='TEST-001',
            base_price=Decimal('99.99'),
            quantity_available=10
        )
    
    def test_product_creation(self):
        """Test product creation."""
        self.assertEqual(self.product.name, 'Test Product')
        self.assertEqual(self.product.slug, 'test-product')
        self.assertEqual(self.product.base_price, Decimal('99.99'))
        self.assertEqual(self.product.category, self.category)
        self.assertTrue(self.product.track_inventory)
        self.assertEqual(self.product.status, 'active')
    
    def test_product_str_representation(self):
        """Test product string representation."""
        self.assertEqual(str(self.product), 'Test Product')
    
    def test_available_quantity_property(self):
        """Test available_quantity property."""
        self.assertEqual(self.product.available_quantity, 10)
        
        # Reserve some quantity
        self.product.quantity_reserved = 3
        self.product.save()
        self.assertEqual(self.product.available_quantity, 7)
    
    def test_is_in_stock_property(self):
        """Test is_in_stock property."""
        self.assertTrue(self.product.is_in_stock)
        
        # Set quantity to 0
        self.product.quantity_available = 0
        self.product.save()
        self.assertFalse(self.product.is_in_stock)
        
        # Test with track_inventory=False
        self.product.track_inventory = False
        self.product.save()
        self.assertTrue(self.product.is_in_stock)
    
    def test_is_low_stock_property(self):
        """Test is_low_stock property."""
        # Set quantity to threshold level
        self.product.quantity_available = 5
        self.product.low_stock_threshold = 5
        self.product.save()
        self.assertTrue(self.product.is_low_stock)
        
        # Set quantity above threshold
        self.product.quantity_available = 10
        self.product.save()
        self.assertFalse(self.product.is_low_stock)
    
    def test_discount_percentage_property(self):
        """Test discount_percentage property."""
        # No compare price
        self.assertEqual(self.product.discount_percentage, 0)
        
        # Set compare price higher than base price
        self.product.compare_price = Decimal('149.99')
        self.product.save()
        expected_discount = round(((Decimal('149.99') - Decimal('99.99')) / Decimal('149.99')) * 100, 2)
        self.assertEqual(self.product.discount_percentage, expected_discount)
    
    def test_profit_margin_property(self):
        """Test profit_margin property."""
        # No cost price
        self.assertEqual(self.product.profit_margin, 0)
        
        # Set cost price lower than base price
        self.product.cost_price = Decimal('49.99')
        self.product.save()
        expected_margin = round(((Decimal('99.99') - Decimal('49.99')) / Decimal('99.99')) * 100, 2)
        self.assertEqual(self.product.profit_margin, expected_margin)
    
    def test_can_fulfill_quantity(self):
        """Test can_fulfill_quantity method."""
        self.assertTrue(self.product.can_fulfill_quantity(5))
        self.assertTrue(self.product.can_fulfill_quantity(10))
        self.assertFalse(self.product.can_fulfill_quantity(15))
        
        # Test with track_inventory=False
        self.product.track_inventory = False
        self.product.save()
        self.assertTrue(self.product.can_fulfill_quantity(100))
    
    def test_reserve_quantity(self):
        """Test reserve_quantity method."""
        initial_reserved = self.product.quantity_reserved
        
        # Reserve valid quantity
        result = self.product.reserve_quantity(5)
        self.assertTrue(result)
        self.assertEqual(self.product.quantity_reserved, initial_reserved + 5)
        
        # Try to reserve more than available
        result = self.product.reserve_quantity(10)
        self.assertFalse(result)
        self.assertEqual(self.product.quantity_reserved, initial_reserved + 5)
    
    def test_release_quantity(self):
        """Test release_quantity method."""
        # Reserve some quantity first
        self.product.quantity_reserved = 5
        self.product.save()
        
        # Release quantity
        self.product.release_quantity(3)
        self.assertEqual(self.product.quantity_reserved, 2)
        
        # Release more than reserved (should not go negative)
        self.product.release_quantity(5)
        self.assertEqual(self.product.quantity_reserved, 0)
    
    def test_adjust_inventory(self):
        """Test adjust_inventory method."""
        initial_quantity = self.product.quantity_available
        
        # Positive adjustment
        self.product.adjust_inventory(5, "Stock received")
        self.assertEqual(self.product.quantity_available, initial_quantity + 5)
        
        # Verify log was created
        log = InventoryLog.objects.filter(product=self.product).first()
        self.assertIsNotNone(log)
        self.assertEqual(log.quantity_change, 5)
        self.assertEqual(log.reason, "Stock received")
        
        # Negative adjustment
        self.product.adjust_inventory(-3, "Damage")
        self.assertEqual(self.product.quantity_available, initial_quantity + 2)
        
        # Adjustment that would make quantity negative (should be set to 0)
        self.product.adjust_inventory(-100, "Loss")
        self.assertEqual(self.product.quantity_available, 0)


class ProductAPITest(APITestCase):
    """
    Test cases for Product API endpoints.
    """
    
    def setUp(self):
        """Set up test data."""
        self.client = APIClient()
        
        # Create users
        self.user = User.objects.create_user(
            username='testuser',
            email='test@example.com',
            password='testpass123'
        )
        
        self.supplier = User.objects.create_user(
            username='supplier',
            email='supplier@example.com',
            password='supplierpass123'
        )
        
        # Create category
        self.category = Category.objects.create(
            name='Electronics',
            slug='electronics',
            description='Electronic devices'
        )
        
        # Create products
        self.product1 = Product.objects.create(
            name='Laptop',
            slug='laptop',
            description='A powerful laptop',
            short_description='Powerful laptop for work',
            category=self.category,
            sku='LAPTOP-001',
            base_price=Decimal('999.99'),
            compare_price=Decimal('1199.99'),
            quantity_available=5,
            is_featured=True,
            supplier=self.supplier
        )
        
        self.product2 = Product.objects.create(
            name='Mouse',
            slug='mouse',
            description='Wireless mouse',
            category=self.category,
            sku='MOUSE-001',
            base_price=Decimal('29.99'),
            quantity_available=0  # Out of stock
        )
    
    def test_list_products_unauthenticated(self):
        """Test listing products without authentication."""
        url = '/api/v1/products/products/'
        response = self.client.get(url)
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        data = response.json()
        self.assertEqual(data['count'], 2)
        
        # Check that only active products are returned
        self.product1.status = 'inactive'
        self.product1.save()
        
        response = self.client.get(url)
        data = response.json()
        self.assertEqual(data['count'], 1)
    
    def test_list_products_with_filters(self):
        """Test listing products with filters."""
        url = '/api/v1/products/products/'
        
        # Filter by category
        response = self.client.get(url, {'category': self.category.id})
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        data = response.json()
        self.assertEqual(data['count'], 2)
        
        # Filter by featured
        response = self.client.get(url, {'is_featured': 'true'})
        data = response.json()
        self.assertEqual(data['count'], 1)
        
        # Filter by stock status
        response = self.client.get(url, {'in_stock': 'true'})
        data = response.json()
        self.assertEqual(data['count'], 1)  # Only laptop is in stock
    
    def test_search_products(self):
        """Test searching products."""
        url = '/api/v1/products/products/'
        
        # Search by name
        response = self.client.get(url, {'search': 'laptop'})
        data = response.json()
        self.assertEqual(data['count'], 1)
        self.assertEqual(data['results'][0]['name'], 'Laptop')
        
        # Search by description
        response = self.client.get(url, {'search': 'wireless'})
        data = response.json()
        self.assertEqual(data['count'], 1)
        self.assertEqual(data['results'][0]['name'], 'Mouse')
    
    def test_retrieve_product(self):
        """Test retrieving a single product."""
        url = f'/api/v1/products/products/{self.product1.slug}/'
        response = self.client.get(url)
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        data = response.json()
        self.assertEqual(data['name'], 'Laptop')
        self.assertEqual(data['slug'], 'laptop')
        self.assertEqual(str(data['base_price']), '999.99')
        
        # Check computed properties
        self.assertEqual(data['available_quantity'], 5)
        self.assertTrue(data['is_in_stock'])
        self.assertAlmostEqual(data['discount_percentage'], 16.67, places=1)
    
    def test_create_product_authenticated(self):
        """Test creating a product with authentication."""
        self.client.force_authenticate(user=self.user)
        
        url = '/api/v1/products/products/'
        data = {
            'name': 'New Product',
            'slug': 'new-product',
            'description': 'A new test product',
            'category': self.category.id,
            'base_price': '49.99',
            'quantity_available': 10
        }
        
        response = self.client.post(url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        
        # Verify product was created
        product = Product.objects.get(slug='new-product')
        self.assertEqual(product.name, 'New Product')
        self.assertEqual(product.base_price, Decimal('49.99'))
    
    def test_create_product_unauthenticated(self):
        """Test creating a product without authentication."""
        url = '/api/v1/products/products/'
        data = {
            'name': 'New Product',
            'slug': 'new-product',
            'description': 'A new test product',
            'category': self.category.id,
            'base_price': '49.99'
        }
        
        response = self.client.post(url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)
    
    def test_update_product(self):
        """Test updating a product."""
        self.client.force_authenticate(user=self.user)
        
        url = f'/api/v1/products/products/{self.product1.slug}/'
        data = {
            'name': 'Gaming Laptop',
            'base_price': '1299.99'
        }
        
        response = self.client.patch(url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        # Verify product was updated
        self.product1.refresh_from_db()
        self.assertEqual(self.product1.name, 'Gaming Laptop')
        self.assertEqual(self.product1.base_price, Decimal('1299.99'))
    
    def test_featured_products_endpoint(self):
        """Test the featured products endpoint."""
        url = '/api/v1/products/products/featured/'
        response = self.client.get(url)
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        data = response.json()
        self.assertEqual(len(data), 1)
        self.assertEqual(data[0]['name'], 'Laptop')
    
    def test_adjust_inventory_endpoint(self):
        """Test the inventory adjustment endpoint."""
        self.client.force_authenticate(user=self.user)
        
        url = f'/api/v1/products/products/{self.product1.slug}/adjust_inventory/'
        data = {
            'quantity_change': 10,
            'reason': 'Stock received'
        }
        
        initial_quantity = self.product1.quantity_available
        response = self.client.post(url, data, format='json')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        response_data = response.json()
        self.assertEqual(response_data['old_quantity'], initial_quantity)
        self.assertEqual(response_data['new_quantity'], initial_quantity + 10)
        
        # Verify inventory log was created
        log = InventoryLog.objects.filter(
            product=self.product1,
            reason='Stock received'
        ).first()
        self.assertIsNotNone(log)
        self.assertEqual(log.quantity_change, 10)
        self.assertEqual(log.created_by, self.user)


class ProductSerializerValidationTest(TestCase):
    """
    Test cases for product serializer validation.
    """
    
    def setUp(self):
        """Set up test data."""
        self.category = Category.objects.create(
            name='Test Category',
            slug='test-category'
        )
    
    def test_base_price_validation(self):
        """Test base price validation."""
        from .serializers import ProductCreateUpdateSerializer
        
        # Valid price
        data = {
            'name': 'Test Product',
            'slug': 'test-product',
            'description': 'Test description',
            'category': self.category.id,
            'base_price': '99.99'
        }
        serializer = ProductCreateUpdateSerializer(data=data)
        self.assertTrue(serializer.is_valid())
        
        # Invalid price (zero)
        data['base_price'] = '0.00'
        serializer = ProductCreateUpdateSerializer(data=data)
        self.assertFalse(serializer.is_valid())
        self.assertIn('Ensure this value is greater than or equal to 0.01', str(serializer.errors))
        
        # Invalid price (negative)
        data['base_price'] = '-10.00'
        serializer = ProductCreateUpdateSerializer(data=data)
        self.assertFalse(serializer.is_valid())
    
    def test_compare_price_validation(self):
        """Test compare price validation."""
        from .serializers import ProductCreateUpdateSerializer
        
        data = {
            'name': 'Test Product',
            'slug': 'test-product',
            'description': 'Test description',
            'category': self.category.id,
            'base_price': '99.99',
            'compare_price': '149.99'
        }
        
        # Valid compare price (higher than base)
        serializer = ProductCreateUpdateSerializer(data=data)
        self.assertTrue(serializer.is_valid())
        
        # Invalid compare price (lower than base)
        data['compare_price'] = '49.99'
        serializer = ProductCreateUpdateSerializer(data=data)
        self.assertFalse(serializer.is_valid())
        self.assertIn('Compare price should be higher', str(serializer.errors))
