from django.test import TestCase
from django.contrib.auth.models import User
from django.utils import timezone
from datetime import timedelta
from decimal import Decimal
from product_requests.models import ProductRequest
from categories.models import Category
from .models import Quote, QuoteItem, QuoteAttachment, QuoteMessage, QuoteComparison


class QuoteModelTest(TestCase):
    """Test cases for Quote model."""
    
    def setUp(self):
        """Set up test data."""
        # Create users
        self.buyer = User.objects.create_user(
            username='buyer',
            email='buyer@test.com',
            password='testpass123'
        )
        self.seller = User.objects.create_user(
            username='seller',
            email='seller@test.com',
            password='testpass123'
        )
        
        # Create category
        self.category, created = Category.objects.get_or_create(
            slug='electronics-test-1',
            defaults={
                'name': 'Electronics-Test-1',
                'description': 'Electronic devices for testing'
            }
        )
        
        # Create product request
        self.product_request = ProductRequest.objects.create(
            title='Need laptop',
            description='Looking for a gaming laptop',
            category='ELECTRONICS',
            product_specifications={'electronics_type': 'LAPTOP', 'brand_preference': 'Dell'},
            max_budget=1200.00,
            quantity=1,
            urgency_timeline='1_WEEK',
            buyer_location={'latitude': 40.7128, 'longitude': -74.0060, 'address': 'New York'},
            buyer_id=self.buyer,
            terms_accepted=True,
            contact_consent=True
        )
    
    def test_quote_creation(self):
        """Test creating a quote."""
        quote = Quote.objects.create(
            request_id=self.product_request,
            seller_id=self.seller,
            total_amount=Decimal('1000.00'),
            currency='USD',
            valid_until=timezone.now() + timedelta(days=7)
        )
        
        self.assertEqual(quote.request_id, self.product_request)
        self.assertEqual(quote.seller_id, self.seller)
        self.assertEqual(quote.total_amount, Decimal('1000.00'))
        self.assertEqual(quote.currency, 'USD')
        self.assertEqual(quote.status, 'PENDING')
        self.assertIsNotNone(quote.quote_id)
        self.assertIsNotNone(quote.created_at)
        self.assertIsNotNone(quote.updated_at)
    
    def test_quote_string_representation(self):
        """Test quote string representation."""
        quote = Quote.objects.create(
            request_id=self.product_request,
            seller_id=self.seller,
            total_amount=Decimal('1000.00'),
            currency='USD',
            valid_until=timezone.now() + timedelta(days=7)
        )
        
        expected_str = f"Quote {quote.quote_id} - {self.seller.username}"
        self.assertEqual(str(quote), expected_str)
    
    def test_quote_is_expired_property(self):
        """Test quote expiration check."""
        # Create expired quote
        expired_quote = Quote.objects.create(
            request_id=self.product_request,
            seller_id=self.seller,
            total_amount=Decimal('1000.00'),
            currency='USD',
            valid_until=timezone.now() - timedelta(days=1)
        )
        self.assertTrue(expired_quote.is_expired)
        
        # Create valid quote
        valid_quote = Quote.objects.create(
            request_id=self.product_request,
            seller_id=self.seller,
            total_amount=Decimal('1000.00'),
            currency='USD',
            valid_until=timezone.now() + timedelta(days=1)
        )
        self.assertFalse(valid_quote.is_expired)
    
    def test_quote_is_valid_property(self):
        """Test quote validity check."""
        # Create pending and non-expired quote (valid)
        valid_quote = Quote.objects.create(
            request_id=self.product_request,
            seller_id=self.seller,
            total_amount=Decimal('1000.00'),
            currency='USD',
            status='PENDING',
            valid_until=timezone.now() + timedelta(days=1)
        )
        self.assertTrue(valid_quote.is_valid)
        
        # Create accepted quote (not valid for new acceptance)
        accepted_quote = Quote.objects.create(
            request_id=self.product_request,
            seller_id=self.seller,
            total_amount=Decimal('1000.00'),
            currency='USD',
            status='ACCEPTED',
            valid_until=timezone.now() + timedelta(days=1)
        )
        self.assertFalse(accepted_quote.is_valid)
        
        # Create expired quote (not valid)
        expired_quote = Quote.objects.create(
            request_id=self.product_request,
            seller_id=self.seller,
            total_amount=Decimal('1000.00'),
            currency='USD',
            status='PENDING',
            valid_until=timezone.now() - timedelta(days=1)
        )
        self.assertFalse(expired_quote.is_valid)


class QuoteItemModelTest(TestCase):
    """Test cases for QuoteItem model."""
    
    def setUp(self):
        """Set up test data."""
        # Create users
        self.buyer = User.objects.create_user(
            username='buyer',
            email='buyer@test.com',
            password='testpass123'
        )
        self.seller = User.objects.create_user(
            username='seller',
            email='seller@test.com',
            password='testpass123'
        )
        
        # Create category
        self.category, created = Category.objects.get_or_create(
            slug='electronics-item-test-2',
            defaults={
                'name': 'Electronics-ItemTest-2',
                'description': 'Electronic devices for item testing'
            }
        )
        
        # Create product request
        self.product_request = ProductRequest.objects.create(
            title='Need laptop',
            description='Looking for a gaming laptop',
            category='ELECTRONICS',
            product_specifications={'electronics_type': 'LAPTOP', 'brand_preference': 'Dell'},
            max_budget=1200.00,
            quantity=1,
            urgency_timeline='1_WEEK',
            buyer_location={'latitude': 40.7128, 'longitude': -74.0060, 'address': 'New York'},
            buyer_id=self.buyer,
            terms_accepted=True,
            contact_consent=True
        )
        
        # Create quote
        self.quote = Quote.objects.create(
            request_id=self.product_request,
            seller_id=self.seller,
            total_amount=Decimal('1000.00'),
            currency='USD',
            valid_until=timezone.now() + timedelta(days=7)
        )
    
    def test_quote_item_creation(self):
        """Test creating a quote item."""
        quote_item = QuoteItem.objects.create(
            quote=self.quote,
            name='Gaming Laptop',
            description='High-performance gaming laptop',
            unit_price=Decimal('1000.00'),
            quantity=1
        )
        
        self.assertEqual(quote_item.quote, self.quote)
        self.assertEqual(quote_item.name, 'Gaming Laptop')
        self.assertEqual(quote_item.unit_price, Decimal('1000.00'))
        self.assertEqual(quote_item.quantity, 1)
        self.assertEqual(quote_item.line_total, Decimal('1000.00'))
    
    def test_quote_item_line_total_calculation(self):
        """Test line total calculation on save."""
        quote_item = QuoteItem.objects.create(
            quote=self.quote,
            name='Gaming Laptop',
            unit_price=Decimal('500.00'),
            quantity=2
        )
        
        # Line total should be calculated automatically
        self.assertEqual(quote_item.line_total, Decimal('1000.00'))


class QuoteAttachmentModelTest(TestCase):
    """Test cases for QuoteAttachment model."""
    
    def setUp(self):
        """Set up test data."""
        # Create users
        self.buyer = User.objects.create_user(
            username='buyer',
            email='buyer@test.com',
            password='testpass123'
        )
        self.seller = User.objects.create_user(
            username='seller',
            email='seller@test.com',
            password='testpass123'
        )
        
        # Create category
        self.category, created = Category.objects.get_or_create(
            slug='electronics-attachment-test-3',
            defaults={
                'name': 'Electronics-AttachmentTest-3',
                'description': 'Electronic devices for attachment testing'
            }
        )
        
        # Create product request
        self.product_request = ProductRequest.objects.create(
            title='Need laptop',
            description='Looking for a gaming laptop',
            category='ELECTRONICS',
            product_specifications={'electronics_type': 'LAPTOP', 'brand_preference': 'Dell'},
            max_budget=1200.00,
            quantity=1,
            urgency_timeline='1_WEEK',
            buyer_location={'latitude': 40.7128, 'longitude': -74.0060, 'address': 'New York'},
            buyer_id=self.buyer,
            terms_accepted=True,
            contact_consent=True
        )
        
        # Create quote
        self.quote = Quote.objects.create(
            request_id=self.product_request,
            seller_id=self.seller,
            total_amount=Decimal('1000.00'),
            currency='USD',
            valid_until=timezone.now() + timedelta(days=7)
        )
    
    def test_file_size_formatted_property(self):
        """Test formatted file size display."""
        attachment = QuoteAttachment(
            quote=self.quote,
            filename='spec.pdf',
            file_size=1024,
            content_type='application/pdf'
        )
        
        # Test different file sizes
        attachment.file_size = 1024
        self.assertEqual(attachment.file_size_formatted, '1.0 KB')
        
        attachment.file_size = 1048576  # 1 MB
        self.assertEqual(attachment.file_size_formatted, '1.0 MB')
        
        attachment.file_size = 500
        self.assertEqual(attachment.file_size_formatted, '500.0 B')
