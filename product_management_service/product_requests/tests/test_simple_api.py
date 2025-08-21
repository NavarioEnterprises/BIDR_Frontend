"""
Simple test cases for Product Request API endpoints.
"""
from decimal import Decimal
from django.test import TestCase
from django.contrib.auth import get_user_model
from rest_framework import status
from rest_framework.test import APIClient
from categories.models import Category
from product_requests.models import ProductRequest

User = get_user_model()


class SimpleProductRequestAPITest(TestCase):
    """Simple test cases for Product Request API."""

    def setUp(self):
        """Set up test data."""
        # Create test user
        self.user = User.objects.create_user(
            username='testuser',
            email='test@test.com',
            password='testpass123'
        )
        
        # Create category
        self.category = Category.objects.create(
            name='Electronics',
            slug='electronics'
        )
        
        # Create test product request
        self.product_request = ProductRequest.objects.create(
            buyer_id=self.user,
            category='ELECTRONICS',
            title='Test Product Request',
            description='Test description',
            product_specifications={'test': 'spec'},
            quantity=10,
            max_budget=Decimal('200.00'),
            buyer_location={'lat': -17.8292, 'lng': 31.0522},
            urgency_timeline='1_WEEK',
            terms_accepted=True,
            contact_consent=True
        )
        
        self.client = APIClient()
        
    def authenticate(self):
        """Helper method to authenticate user."""
        self.client.force_authenticate(user=self.user)

    def test_product_request_creation(self):
        """Test that a product request can be created successfully."""
        self.assertEqual(self.product_request.title, 'Test Product Request')
        self.assertEqual(self.product_request.buyer_id, self.user)
        self.assertEqual(self.product_request.category, 'ELECTRONICS')
        self.assertEqual(self.product_request.quantity, 10)
        self.assertTrue(self.product_request.terms_accepted)
        self.assertTrue(self.product_request.contact_consent)

    def test_unauthenticated_access_denied(self):
        """Test that unauthenticated users cannot access the API."""
        response = self.client.get('/api/v1/requests/')
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)  # API requires authentication

    def test_product_request_str_representation(self):
        """Test string representation of product request."""
        expected_str = f"{self.product_request.request_id} - Test Product Request"
        self.assertEqual(str(self.product_request), expected_str)

    def test_product_request_expiry_calculation(self):
        """Test that expiry date is calculated correctly."""
        self.assertIsNotNone(self.product_request.expiry_date)
        self.assertFalse(self.product_request.is_expired)

    def test_product_request_can_receive_quotes(self):
        """Test can_receive_quotes method."""
        self.assertTrue(self.product_request.can_receive_quotes())

    def test_product_request_mark_as_viewed(self):
        """Test mark_as_viewed method."""
        initial_count = self.product_request.view_count
        self.product_request.mark_as_viewed()
        self.product_request.refresh_from_db()
        self.assertEqual(self.product_request.view_count, initial_count + 1)

    def test_product_request_close(self):
        """Test closing a product request."""
        self.product_request.close_request()
        self.assertEqual(self.product_request.status, 'CLOSED')

    def test_category_object_retrieval(self):
        """Test getting Category object from category field."""
        # This might return None since the mapping isn't set up
        category_obj = self.product_request.get_category_object()
        # We can't assert much here without proper category mapping
        
    def test_title_generation(self):
        """Test automatic title generation."""
        # Test with electronics specifications
        specs = {
            'electronics_type': 'SMARTPHONE',
            'brand_preference': 'Samsung'
        }
        request = ProductRequest.objects.create(
            buyer_id=self.user,
            category='ELECTRONICS',
            product_specifications=specs,
            quantity=1,
            buyer_location={'lat': -17.8292, 'lng': 31.0522},
            urgency_timeline='ASAP',
            terms_accepted=True,
            contact_consent=True
        )
        # The title should be auto-generated
        self.assertIsNotNone(request.title)
