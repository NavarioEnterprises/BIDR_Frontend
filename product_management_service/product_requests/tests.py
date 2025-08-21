"""
Comprehensive tests for Product Requests app.
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
from django.utils import timezone
from decimal import Decimal
from datetime import timedelta
import uuid
import json

from .models import (
    ProductRequest, RequestImage, RequestSpecification, 
    RequestMessage, RequestWatchlist, RequestTemplate,
    ConsumerElectronics, VehicleSpares, VehicleTyresRims
)
from categories.models import Category


class ProductRequestModelTest(TestCase):
    """Test ProductRequest model functionality."""
    
    def setUp(self):
        self.user = User.objects.create_user(
            username='testuser',
            email='test@example.com',
            password='testpass123'
        )
        
        self.category = Category.objects.create(
            name='Electronics',
            slug='electronics'
        )
        
        # self.product = Product.objects.create(
        #     name='Test Product',
        #     slug='test-product',
        #     description='Test product',
        #     category=self.category,
        #     base_price=Decimal('100.00')
        # )
    
    def test_product_request_creation(self):
        """Test that a product request can be created successfully."""
        request = ProductRequest.objects.create(
            title='Need smartphone parts',
            description='Looking for high-quality smartphone components',
            request_type='product_inquiry',
            requester=self.user,
            category=self.category,
            quantity_needed=100,
            budget_min=Decimal('10.00'),
            budget_max=Decimal('50.00'),
            urgency='high'
        )
        
        self.assertEqual(request.title, 'Need smartphone parts')
        self.assertEqual(request.requester, self.user)
        self.assertEqual(request.category, self.category)
        self.assertEqual(request.quantity_needed, 100)
        self.assertEqual(request.urgency, 'high')
        self.assertEqual(request.status, StatusChoices.PENDING)
        self.assertIsNotNone(request.reference_number)
    
    def test_request_str_representation(self):
        """Test string representation of product request."""
        request = ProductRequest.objects.create(
            title='Test Request',
            description='Test description',
            request_type='product_inquiry',
            requester=self.user,
            quantity_needed=10
        )
        
        expected_str = f"{request.reference_number} - Test Request"
        self.assertEqual(str(request), expected_str)
    
    def test_request_reference_number_generation(self):
        """Test automatic reference number generation."""
        request = ProductRequest.objects.create(
            title='Test Request',
            description='Test description',
            request_type='product_inquiry',
            requester=self.user,
            quantity_needed=10
        )
        
        self.assertTrue(request.reference_number.startswith('REQ'))
        self.assertIsNotNone(request.reference_number)
    
    def test_is_expired_property(self):
        """Test is_expired property."""
        # Create a request that expires in the future
        future_request = ProductRequest.objects.create(
            title='Future Request',
            description='Test description',
            request_type='product_inquiry',
            requester=self.user,
            quantity_needed=10,
            expires_at=timezone.now() + timedelta(days=7)
        )
        self.assertFalse(future_request.is_expired)
        
        # Create a request that has already expired
        expired_request = ProductRequest.objects.create(
            title='Expired Request',
            description='Test description',
            request_type='product_inquiry',
            requester=self.user,
            quantity_needed=10,
            expires_at=timezone.now() - timedelta(days=1)
        )
        self.assertTrue(expired_request.is_expired)
    
    def test_is_urgent_property(self):
        """Test is_urgent property."""
        # Test urgency based on urgency field
        urgent_request = ProductRequest.objects.create(
            title='Urgent Request',
            description='Test description',
            request_type='product_inquiry',
            requester=self.user,
            quantity_needed=10,
            urgency='urgent'
        )
        self.assertTrue(urgent_request.is_urgent)
        
        # Test urgency based on needed_by_date
        time_sensitive_request = ProductRequest.objects.create(
            title='Time Sensitive Request',
            description='Test description',
            request_type='product_inquiry',
            requester=self.user,
            quantity_needed=10,
            urgency='medium',
            needed_by_date=timezone.now() + timedelta(hours=24)  # Within 48 hours
        )
        self.assertTrue(time_sensitive_request.is_urgent)
    
    def test_average_budget_property(self):
        """Test average budget calculation."""
        request = ProductRequest.objects.create(
            title='Test Request',
            description='Test description',
            request_type='product_inquiry',
            requester=self.user,
            quantity_needed=10,
            budget_min=Decimal('100.00'),
            budget_max=Decimal('200.00')
        )
        
        self.assertEqual(request.average_budget, Decimal('150.00'))
        
        # Test with only min budget
        request.budget_max = None
        request.save()
        self.assertEqual(request.average_budget, Decimal('100.00'))
    
    def test_can_receive_quotes_method(self):
        """Test can_receive_quotes method."""
        # Active request should be able to receive quotes
        active_request = ProductRequest.objects.create(
            title='Active Request',
            description='Test description',
            request_type='product_inquiry',
            requester=self.user,
            quantity_needed=10,
            status=StatusChoices.ACTIVE,
            expires_at=timezone.now() + timedelta(days=7)
        )
        self.assertTrue(active_request.can_receive_quotes())
        
        # Expired request should not be able to receive quotes
        expired_request = ProductRequest.objects.create(
            title='Expired Request',
            description='Test description',
            request_type='product_inquiry',
            requester=self.user,
            quantity_needed=10,
            status=StatusChoices.ACTIVE,
            expires_at=timezone.now() - timedelta(days=1)
        )
        self.assertFalse(expired_request.can_receive_quotes())
    
    def test_mark_as_viewed_method(self):
        """Test mark_as_viewed method."""
        request = ProductRequest.objects.create(
            title='Test Request',
            description='Test description',
            request_type='product_inquiry',
            requester=self.user,
            quantity_needed=10
        )
        
        initial_view_count = request.view_count
        request.mark_as_viewed()
        request.refresh_from_db()
        
        self.assertEqual(request.view_count, initial_view_count + 1)


class RequestImageModelTest(TestCase):
    """Test RequestImage model functionality."""
    
    def setUp(self):
        self.user = User.objects.create_user(
            username='testuser',
            email='test@example.com',
            password='testpass123'
        )
        
        self.request = ProductRequest.objects.create(
            title='Test Request',
            description='Test description',
            request_type='product_inquiry',
            requester=self.user,
            quantity_needed=10
        )
    
    def test_request_image_creation(self):
        """Test request image creation."""
        image = RequestImage.objects.create(
            request=self.request,
            image='test.jpg',
            caption='Test image caption',
            sort_order=1
        )
        
        self.assertEqual(image.request, self.request)
        self.assertEqual(image.caption, 'Test image caption')
        self.assertEqual(image.sort_order, 1)
    
    def test_request_image_str_representation(self):
        """Test string representation of request image."""
        image = RequestImage.objects.create(
            request=self.request,
            image='test.jpg'
        )
        
        expected_str = f"{self.request.reference_number} - Image {image.id}"
        self.assertEqual(str(image), expected_str)
    
    def test_image_ordering(self):
        """Test image ordering by sort_order."""
        image3 = RequestImage.objects.create(
            request=self.request,
            image='test3.jpg',
            sort_order=3
        )
        image1 = RequestImage.objects.create(
            request=self.request,
            image='test1.jpg',
            sort_order=1
        )
        image2 = RequestImage.objects.create(
            request=self.request,
            image='test2.jpg',
            sort_order=2
        )
        
        images = RequestImage.objects.filter(request=self.request)
        self.assertEqual(images[0], image1)
        self.assertEqual(images[1], image2)
        self.assertEqual(images[2], image3)


class RequestSpecificationModelTest(TestCase):
    """Test RequestSpecification model functionality."""
    
    def setUp(self):
        self.user = User.objects.create_user(
            username='testuser',
            email='test@example.com',
            password='testpass123'
        )
        
        self.request = ProductRequest.objects.create(
            title='Test Request',
            description='Test description',
            request_type='product_inquiry',
            requester=self.user,
            quantity_needed=10
        )
    
    def test_specification_creation(self):
        """Test specification creation."""
        spec = RequestSpecification.objects.create(
            request=self.request,
            name='Material',
            value='Aluminum',
            is_required=True,
            sort_order=1
        )
        
        self.assertEqual(spec.request, self.request)
        self.assertEqual(spec.name, 'Material')
        self.assertEqual(spec.value, 'Aluminum')
        self.assertTrue(spec.is_required)
    
    def test_specification_str_representation(self):
        """Test string representation of specification."""
        spec = RequestSpecification.objects.create(
            request=self.request,
            name='Color',
            value='Blue'
        )
        
        expected_str = f"{self.request.reference_number} - Color: Blue"
        self.assertEqual(str(spec), expected_str)
    
    def test_specification_unique_constraint(self):
        """Test unique constraint on request + name."""
        RequestSpecification.objects.create(
            request=self.request,
            name='Size',
            value='Large'
        )
        
        # Attempting to create another spec with same name should fail
        with self.assertRaises(Exception):
            RequestSpecification.objects.create(
                request=self.request,
                name='Size',  # Same name
                value='Medium'
            )


class RequestMessageModelTest(TestCase):
    """Test RequestMessage model functionality."""
    
    def setUp(self):
        self.user = User.objects.create_user(
            username='testuser',
            email='test@example.com',
            password='testpass123'
        )
        
        self.request = ProductRequest.objects.create(
            title='Test Request',
            description='Test description',
            request_type='product_inquiry',
            requester=self.user,
            quantity_needed=10
        )
    
    def test_message_creation(self):
        """Test message creation."""
        message = RequestMessage.objects.create(
            request=self.request,
            sender=self.user,
            message_type='inquiry',
            subject='Question about specifications',
            message='Can you provide more details about the materials?',
            is_internal=False
        )
        
        self.assertEqual(message.request, self.request)
        self.assertEqual(message.sender, self.user)
        self.assertEqual(message.message_type, 'inquiry')
        self.assertEqual(message.subject, 'Question about specifications')
        self.assertFalse(message.is_internal)
    
    def test_message_str_representation(self):
        """Test string representation of message."""
        message = RequestMessage.objects.create(
            request=self.request,
            sender=self.user,
            message_type='inquiry',
            subject='Test Subject',
            message='Test message content'
        )
        
        expected_str = f"{self.request.reference_number} - {self.user.username}: Test Subject"
        self.assertEqual(str(message), expected_str)
    
    def test_message_read_functionality(self):
        """Test message read functionality."""
        message = RequestMessage.objects.create(
            request=self.request,
            sender=self.user,
            message_type='inquiry',
            message='Test message'
        )
        
        # Initially unread
        self.assertFalse(message.is_read)
        self.assertIsNone(message.read_at)
        
        # Mark as read
        message.mark_as_read()
        
        self.assertTrue(message.is_read)
        self.assertIsNotNone(message.read_at)


class RequestWatchlistModelTest(TestCase):
    """Test RequestWatchlist model functionality."""
    
    def setUp(self):
        self.user1 = User.objects.create_user(
            username='user1',
            email='user1@example.com',
            password='testpass123'
        )
        
        self.user2 = User.objects.create_user(
            username='user2',
            email='user2@example.com',
            password='testpass123'
        )
        
        self.request = ProductRequest.objects.create(
            title='Test Request',
            description='Test description',
            request_type='product_inquiry',
            requester=self.user1,
            quantity_needed=10
        )
    
    def test_watchlist_creation(self):
        """Test watchlist creation."""
        watchlist = RequestWatchlist.objects.create(
            request=self.request,
            user=self.user2,
            notify_on_quotes=True,
            notify_on_updates=False
        )
        
        self.assertEqual(watchlist.request, self.request)
        self.assertEqual(watchlist.user, self.user2)
        self.assertTrue(watchlist.notify_on_quotes)
        self.assertFalse(watchlist.notify_on_updates)
    
    def test_watchlist_str_representation(self):
        """Test string representation of watchlist."""
        watchlist = RequestWatchlist.objects.create(
            request=self.request,
            user=self.user2
        )
        
        expected_str = f"{self.user2.username} watching {self.request.reference_number}"
        self.assertEqual(str(watchlist), expected_str)
    
    def test_watchlist_unique_constraint(self):
        """Test unique constraint on request + user."""
        RequestWatchlist.objects.create(
            request=self.request,
            user=self.user2
        )
        
        # Attempting to create another watchlist entry for same user and request should fail
        with self.assertRaises(Exception):
            RequestWatchlist.objects.create(
                request=self.request,
                user=self.user2
            )


class RequestTemplateModelTest(TestCase):
    """Test RequestTemplate model functionality."""
    
    def setUp(self):
        self.category = Category.objects.create(
            name='Electronics',
            slug='electronics'
        )
    
    def test_template_creation(self):
        """Test template creation."""
        template = RequestTemplate.objects.create(
            name='Standard Electronics Inquiry',
            description='Template for electronics product inquiries',
            category=self.category,
            request_type='product_inquiry',
            template_data={
                'urgency': 'medium',
                'unit_of_measure': 'pieces',
                'delivery_required': True
            },
            is_active=True
        )
        
        self.assertEqual(template.name, 'Standard Electronics Inquiry')
        self.assertEqual(template.category, self.category)
        self.assertEqual(template.request_type, 'product_inquiry')
        self.assertTrue(template.is_active)
        self.assertEqual(template.usage_count, 0)
    
    def test_template_str_representation(self):
        """Test string representation of template."""
        template = RequestTemplate.objects.create(
            name='Test Template',
            category=self.category,
            request_type='product_inquiry'
        )
        
        expected_str = f"{self.category.name} - Test Template"
        self.assertEqual(str(template), expected_str)
    
    def test_increment_usage_method(self):
        """Test increment usage method."""
        template = RequestTemplate.objects.create(
            name='Test Template',
            category=self.category,
            request_type='product_inquiry'
        )
        
        initial_usage = template.usage_count
        template.increment_usage()
        template.refresh_from_db()
        
        self.assertEqual(template.usage_count, initial_usage + 1)
