"""
Test cases for Product Request API endpoints.
"""
import json
from datetime import date, timedelta
from decimal import Decimal
# Set up Django environment if not already configured
import os
import django
from django.conf import settings

if not settings.configured:
    os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'product_management_service.settings')
    django.setup()

from django.test import TestCase
from django.contrib.auth import get_user_model
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APIClient
from categories.models import Category
from product_requests.models import (
    ProductRequest, ConsumerElectronics, VehicleSpares, VehicleTyresRims,
    RequestMessage, RequestWatchlist
)

User = get_user_model()


class ProductRequestAPITestCase(TestCase):
    """Base test case for Product Request API tests."""

    def setUp(self):
        """Set up test data."""
        # Create test users
        self.user1 = User.objects.create_user(
            username='testuser1',
            email='user1@test.com',
            password='testpass123'
        )
        self.user2 = User.objects.create_user(
            username='testuser2', 
            email='user2@test.com',
            password='testpass123'
        )
        
        # Create categories
        self.consumer_electronics = Category.objects.create(
            name='Consumer Electronics',
            slug='consumer-electronics'
        )
        
        self.vehicle_spares = Category.objects.create(
            name='Vehicle Spares',
            slug='vehicle-spares'
        )
        
        self.client = APIClient()
        
    def authenticate(self, user):
        """Helper method to authenticate user."""
        self.client.force_authenticate(user=user)


class ProductRequestListCreateAPITest(ProductRequestAPITestCase):
    """Test cases for listing and creating product requests."""

    def setUp(self):
        super().setUp()
        # Create test product requests
        self.product_request1 = ProductRequest.objects.create(
            buyer_id=self.user1,
            category='ELECTRONICS',
            title='Test Product Request 1',
            description='Test description 1',
            product_specifications={'test': 'spec'},
            quantity=10,
            max_budget=Decimal('200.00'),
            buyer_location={'lat': -17.8292, 'lng': 31.0522},
            urgency_timeline='1_WEEK',
            terms_accepted=True,
            contact_consent=True
        )
        
        self.product_request2 = ProductRequest.objects.create(
            buyer_id=self.user2,
            category='VEHICLE_SPARES',
            title='Test Product Request 2',
            description='Test description 2',
            product_specifications={'test': 'spec'},
            quantity=5,
            max_budget=Decimal('1000.00'),
            buyer_location={'lat': -17.8292, 'lng': 31.0522},
            urgency_timeline='ASAP',
            terms_accepted=True,
            contact_consent=True
        )

    def test_list_product_requests_unauthenticated(self):
        """Test listing product requests without authentication."""
        url = reverse('productrequest-list')
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_list_product_requests_authenticated(self):
        """Test listing product requests with authentication."""
        self.authenticate(self.user1)
        url = reverse('productrequest-list')
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data['results']), 2)

    def test_filter_product_requests_by_category(self):
        """Test filtering product requests by category."""
        self.authenticate(self.user1)
        url = reverse('productrequest-list')
        response = self.client.get(url, {'category': self.consumer_electronics.id})
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data['results']), 1)
        self.assertEqual(response.data['results'][0]['title'], 'Test Product Request 1')

    def test_filter_product_requests_by_urgency(self):
        """Test filtering product requests by urgency."""
        self.authenticate(self.user1)
        url = reverse('productrequest-list')
        response = self.client.get(url, {'urgency': 'high'})
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data['results']), 1)
        self.assertEqual(response.data['results'][0]['urgency'], 'high')

    def test_search_product_requests(self):
        """Test searching product requests by title/description."""
        self.authenticate(self.user1)
        url = reverse('productrequest-list')
        response = self.client.get(url, {'search': 'Test Product Request 1'})
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data['results']), 1)
        self.assertEqual(response.data['results'][0]['title'], 'Test Product Request 1')

    def test_order_product_requests(self):
        """Test ordering product requests."""
        self.authenticate(self.user1)
        url = reverse('productrequest-list')
        response = self.client.get(url, {'ordering': '-created_at'})
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data['results']), 2)

    def test_create_product_request(self):
        """Test creating a new product request."""
        self.authenticate(self.user1)
        url = reverse('productrequest-list')
        data = {
            'category': self.consumer_electronics.id,
            'title': 'New Product Request',
            'description': 'New description',
            'quantity_needed': 15,
            'budget_min': '300.00',
            'budget_max': '600.00',
            'urgency': 'low'
        }
        response = self.client.post(url, data)
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(response.data['title'], 'New Product Request')
        self.assertEqual(response.data['user'], self.user1.id)

    def test_create_product_request_invalid_data(self):
        """Test creating product request with invalid data."""
        self.authenticate(self.user1)
        url = reverse('productrequest-list')
        data = {
            'category': self.consumer_electronics.id,
            'title': '',  # Invalid empty title
            'description': 'New description',
            'quantity_needed': 15,
            'budget_min': '300.00',
            'budget_max': '600.00',
            'urgency': 'low'
        }
        response = self.client.post(url, data)
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)


class ProductRequestDetailAPITest(ProductRequestAPITestCase):
    """Test cases for retrieving, updating, and deleting individual product requests."""

    def setUp(self):
        super().setUp()
        self.product_request = ProductRequest.objects.create(
            request_id='PR-DETAIL',
            user=self.user1,
            category=self.consumer_electronics,
            title='Detail Test Request',
            description='Detail test description',
            quantity_needed=10,
            budget_min=Decimal('100.00'),
            budget_max=Decimal('200.00'),
            urgency='medium'
        )

    def test_retrieve_product_request(self):
        """Test retrieving a specific product request."""
        self.authenticate(self.user1)
        url = reverse('productrequest-detail', args=[self.product_request.id])
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['title'], 'Detail Test Request')

    def test_retrieve_product_request_unauthenticated(self):
        """Test retrieving product request without authentication."""
        url = reverse('productrequest-detail', args=[self.product_request.id])
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_update_own_product_request(self):
        """Test updating own product request."""
        self.authenticate(self.user1)
        url = reverse('productrequest-detail', args=[self.product_request.id])
        data = {
            'title': 'Updated Test Request',
            'urgency': 'high'
        }
        response = self.client.patch(url, data)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['title'], 'Updated Test Request')
        self.assertEqual(response.data['urgency'], 'high')

    def test_update_others_product_request(self):
        """Test updating someone else's product request (should fail)."""
        self.authenticate(self.user2)
        url = reverse('productrequest-detail', args=[self.product_request.id])
        data = {
            'title': 'Should Not Update'
        }
        response = self.client.patch(url, data)
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

    def test_delete_own_product_request(self):
        """Test deleting own product request."""
        self.authenticate(self.user1)
        url = reverse('productrequest-detail', args=[self.product_request.id])
        response = self.client.delete(url)
        self.assertEqual(response.status_code, status.HTTP_204_NO_CONTENT)
        self.assertFalse(ProductRequest.objects.filter(id=self.product_request.id).exists())

    def test_delete_others_product_request(self):
        """Test deleting someone else's product request (should fail)."""
        self.authenticate(self.user2)
        url = reverse('productrequest-detail', args=[self.product_request.id])
        response = self.client.delete(url)
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)


class ProductRequestConsumerElectronicsAPITest(ProductRequestAPITestCase):
    """Test cases for Consumer Electronics product requests with specifications."""

    def test_create_consumer_electronics_request(self):
        """Test creating a consumer electronics product request."""
        self.authenticate(self.user1)
        url = reverse('productrequest-list')
        data = {
            'category': self.consumer_electronics.id,
            'title': 'Smartphone Request',
            'description': 'Need smartphones for office',
            'quantity_needed': 20,
            'budget_min': '200.00',
            'budget_max': '500.00',
            'urgency': 'medium',
            'consumer_electronics_specs': {
                'brand': 'Samsung',
                'model': 'Galaxy S21',
                'screen_size': '6.2 inches',
                'ram': '8GB',
                'storage': '128GB',
                'color': 'Black',
                'warranty_period': 24,
                'energy_rating': 'A+',
                'connectivity': 'WiFi, Bluetooth, 5G'
            }
        }
        response = self.client.post(url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(response.data['title'], 'Smartphone Request')
        self.assertIn('consumer_electronics_specs', response.data)
        self.assertEqual(response.data['consumer_electronics_specs']['brand'], 'Samsung')

    def test_retrieve_consumer_electronics_request_with_specs(self):
        """Test retrieving a consumer electronics request with specifications."""
        # Create a request with specs
        product_request = ProductRequest.objects.create(
            request_id='PR-CE-001',
            user=self.user1,
            category=self.consumer_electronics,
            title='Laptop Request',
            description='Need laptops for team',
            quantity_needed=5,
            budget_min=Decimal('800.00'),
            budget_max=Decimal('1200.00'),
            urgency='high'
        )
        
        ConsumerElectronics.objects.create(
            product_request=product_request,
            brand='Apple',
            model='MacBook Pro',
            screen_size='13 inches',
            ram='16GB',
            storage='512GB',
            color='Silver',
            warranty_period=12
        )
        
        self.authenticate(self.user1)
        url = reverse('productrequest-detail', args=[product_request.id])
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('consumer_electronics_specs', response.data)
        self.assertEqual(response.data['consumer_electronics_specs']['brand'], 'Apple')


class ProductRequestVehicleSparesAPITest(ProductRequestAPITestCase):
    """Test cases for Vehicle Spares product requests with specifications."""

    def test_create_vehicle_spares_request(self):
        """Test creating a vehicle spares product request."""
        self.authenticate(self.user1)
        url = reverse('productrequest-list')
        data = {
            'category': self.vehicle_spares.id,
            'title': 'Brake Pads Request',
            'description': 'Need brake pads for fleet vehicles',
            'quantity_needed': 50,
            'budget_min': '50.00',
            'budget_max': '100.00',
            'urgency': 'high',
            'vehicle_spares_specs': {
                'vehicle_make': 'Toyota',
                'vehicle_model': 'Camry',
                'vehicle_year': 2020,
                'part_number': 'BP-12345',
                'oem_part': True,
                'compatibility': 'Toyota Camry 2018-2022',
                'condition': 'new',
                'warranty_months': 12
            }
        }
        response = self.client.post(url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(response.data['title'], 'Brake Pads Request')
        self.assertIn('vehicle_spares_specs', response.data)
        self.assertEqual(response.data['vehicle_spares_specs']['vehicle_make'], 'Toyota')


class ProductRequestActionAPITest(ProductRequestAPITestCase):
    """Test cases for product request custom actions."""

    def setUp(self):
        super().setUp()
        self.product_request = ProductRequest.objects.create(
            request_id='PR-ACTION',
            user=self.user1,
            category=self.consumer_electronics,
            title='Action Test Request',
            description='Test description',
            quantity_needed=10,
            budget_min=Decimal('100.00'),
            budget_max=Decimal('200.00'),
            urgency='medium'
        )

    def test_close_product_request(self):
        """Test closing a product request."""
        self.authenticate(self.user1)
        url = reverse('productrequest-close', args=[self.product_request.id])
        response = self.client.post(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        # Refresh from database
        self.product_request.refresh_from_db()
        self.assertEqual(self.product_request.status, 'closed')

    def test_close_others_product_request(self):
        """Test closing someone else's product request (should fail)."""
        self.authenticate(self.user2)
        url = reverse('productrequest-close', args=[self.product_request.id])
        response = self.client.post(url)
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

    def test_my_requests(self):
        """Test the my_requests action."""
        # Create another request for user2
        ProductRequest.objects.create(
            request_id='PR-USER2',
            user=self.user2,
            category=self.vehicle_spares,
            title='User2 Request',
            description='User2 description',
            quantity_needed=5,
            budget_min=Decimal('200.00'),
            budget_max=Decimal('400.00'),
            urgency='low'
        )
        
        self.authenticate(self.user1)
        url = reverse('productrequest-my-requests')
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data['results']), 1)
        self.assertEqual(response.data['results'][0]['user'], self.user1.id)


class ProductRequestMessageAPITest(ProductRequestAPITestCase):
    """Test cases for Product Request Messages."""

    def setUp(self):
        super().setUp()
        self.product_request = ProductRequest.objects.create(
            request_id='PR-MSG',
            user=self.user1,
            category=self.consumer_electronics,
            title='Message Test Request',
            description='Test description',
            quantity_needed=10,
            budget_min=Decimal('100.00'),
            budget_max=Decimal('200.00'),
            urgency='medium'
        )

    def test_list_messages(self):
        """Test listing messages for a product request."""
        # Create test messages
        ProductRequestMessage.objects.create(
            product_request=self.product_request,
            sender=self.user1,
            message='Test message 1'
        )
        ProductRequestMessage.objects.create(
            product_request=self.product_request,
            sender=self.user2,
            message='Test message 2'
        )

        self.authenticate(self.user1)
        url = reverse('productrequestmessage-list')
        response = self.client.get(url, {'product_request': self.product_request.id})
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data['results']), 2)

    def test_create_message(self):
        """Test creating a message."""
        self.authenticate(self.user1)
        url = reverse('productrequestmessage-list')
        data = {
            'product_request': self.product_request.id,
            'message': 'New test message'
        }
        response = self.client.post(url, data)
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(response.data['message'], 'New test message')
        self.assertEqual(response.data['sender'], self.user1.id)


class ProductRequestWatchlistAPITest(ProductRequestAPITestCase):
    """Test cases for Product Request Watchlist."""

    def setUp(self):
        super().setUp()
        self.product_request = ProductRequest.objects.create(
            request_id='PR-WATCH',
            user=self.user1,
            category=self.consumer_electronics,
            title='Watchlist Test Request',
            description='Test description',
            quantity_needed=10,
            budget_min=Decimal('100.00'),
            budget_max=Decimal('200.00'),
            urgency='medium'
        )

    def test_add_to_watchlist(self):
        """Test adding a product request to watchlist."""
        self.authenticate(self.user2)
        url = reverse('productrequestwatchlist-list')
        data = {
            'product_request': self.product_request.id
        }
        response = self.client.post(url, data)
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(response.data['product_request'], self.product_request.id)
        self.assertEqual(response.data['user'], self.user2.id)

    def test_list_watchlist(self):
        """Test listing user's watchlist."""
        # Add to watchlist
        ProductRequestWatchlist.objects.create(
            user=self.user2,
            product_request=self.product_request
        )

        self.authenticate(self.user2)
        url = reverse('productrequestwatchlist-list')
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data['results']), 1)

    def test_remove_from_watchlist(self):
        """Test removing a product request from watchlist."""
        # Add to watchlist first
        watchlist_item = ProductRequestWatchlist.objects.create(
            user=self.user2,
            product_request=self.product_request
        )

        self.authenticate(self.user2)
        url = reverse('productrequestwatchlist-detail', args=[watchlist_item.id])
        response = self.client.delete(url)
        self.assertEqual(response.status_code, status.HTTP_204_NO_CONTENT)
        self.assertFalse(
            ProductRequestWatchlist.objects.filter(id=watchlist_item.id).exists()
        )


class ProductRequestPermissionsTest(ProductRequestAPITestCase):
    """Test cases for permissions on product request endpoints."""

    def setUp(self):
        super().setUp()
        self.product_request = ProductRequest.objects.create(
            request_id='PR-PERM',
            user=self.user1,
            category=self.consumer_electronics,
            title='Permission Test Request',
            description='Test description',
            quantity_needed=10,
            budget_min=Decimal('100.00'),
            budget_max=Decimal('200.00'),
            urgency='medium'
        )

    def test_unauthenticated_access(self):
        """Test that unauthenticated users cannot access protected endpoints."""
        url = reverse('productrequest-list')
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

        response = self.client.post(url, {})
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_authenticated_read_access(self):
        """Test that authenticated users can read product requests."""
        self.authenticate(self.user2)
        url = reverse('productrequest-list')
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)

    def test_owner_permissions(self):
        """Test that only owners can modify their requests."""
        # Owner should be able to update
        self.authenticate(self.user1)
        url = reverse('productrequest-detail', args=[self.product_request.id])
        response = self.client.patch(url, {'title': 'Updated Title'})
        self.assertEqual(response.status_code, status.HTTP_200_OK)

        # Non-owner should not be able to update
        self.authenticate(self.user2)
        response = self.client.patch(url, {'title': 'Should Not Update'})
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)


class ProductRequestPaginationTest(ProductRequestAPITestCase):
    """Test cases for pagination of product requests."""

    def setUp(self):
        super().setUp()
        # Create multiple product requests for pagination testing
        for i in range(25):
            ProductRequest.objects.create(
                request_id=f'PR-{i:03d}',
                user=self.user1,
                category=self.consumer_electronics,
                title=f'Test Request {i}',
                description=f'Test description {i}',
                quantity_needed=i + 1,
                budget_min=Decimal('100.00'),
                budget_max=Decimal('200.00'),
                urgency='medium'
            )

    def test_pagination_first_page(self):
        """Test first page of paginated results."""
        self.authenticate(self.user1)
        url = reverse('productrequest-list')
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('results', response.data)
        self.assertIn('count', response.data)
        self.assertEqual(response.data['count'], 25)
        
    def test_pagination_page_size(self):
        """Test custom page size."""
        self.authenticate(self.user1)
        url = reverse('productrequest-list')
        response = self.client.get(url, {'page_size': 10})
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data['results']), 10)
