"""
Comprehensive tests for Transactions app.
"""

from django.test import TestCase
from django.contrib.auth.models import User
from django.utils import timezone
from decimal import Decimal
from datetime import timedelta
from .models import (
    Transaction, TransactionItem, Payment, Delivery, TransactionMessage
)
from categories.models import Category
from products.models import Product
from core.models import StatusChoices


class TransactionModelTest(TestCase):
    """Test Transaction model functionality."""
    
    def setUp(self):
        self.buyer = User.objects.create_user(
            username='buyer',
            email='buyer@example.com',
            password='testpass123'
        )
        
        self.seller = User.objects.create_user(
            username='seller',
            email='seller@example.com',
            password='testpass123'
        )
        
        self.category = Category.objects.create(
            name='Electronics',
            slug='electronics'
        )
        
        self.product = Product.objects.create(
            name='Test Product',
            slug='test-product',
            description='Test product',
            category=self.category,
            base_price=Decimal('100.00')
        )
    
    def test_transaction_creation(self):
        """Test that a transaction can be created successfully."""
        transaction = Transaction.objects.create(
            transaction_type='purchase',
            buyer=self.buyer,
            seller=self.seller,
            subtotal=Decimal('500.00'),
            shipping_cost=Decimal('25.00'),
            tax_amount=Decimal('52.50'),
            platform_fee=Decimal('15.00'),
            total_amount=Decimal('592.50')
        )
        
        self.assertEqual(transaction.buyer, self.buyer)
        self.assertEqual(transaction.seller, self.seller)
        self.assertEqual(transaction.subtotal, Decimal('500.00'))
        self.assertEqual(transaction.total_amount, Decimal('592.50'))
        self.assertEqual(transaction.status, StatusChoices.ACTIVE)
        self.assertEqual(transaction.payment_status, 'pending')
        self.assertEqual(transaction.fulfillment_status, 'pending')
        self.assertIsNotNone(transaction.reference_number)
    
    def test_transaction_str_representation(self):
        """Test string representation of transaction."""
        transaction = Transaction.objects.create(
            buyer=self.buyer,
            seller=self.seller,
            subtotal=Decimal('100.00'),
            total_amount=Decimal('100.00')
        )
        
        expected_str = f"{transaction.reference_number} - {self.buyer.username} to {self.seller.username}"
        self.assertEqual(str(transaction), expected_str)
    
    def test_transaction_reference_number_generation(self):
        """Test automatic reference number generation."""
        transaction = Transaction.objects.create(
            buyer=self.buyer,
            seller=self.seller,
            subtotal=Decimal('100.00'),
            total_amount=Decimal('100.00')
        )
        
        self.assertTrue(transaction.reference_number.startswith('TXN'))
        self.assertIsNotNone(transaction.reference_number)
    
    def test_is_completed_property(self):
        """Test is_completed property."""
        transaction = Transaction.objects.create(
            buyer=self.buyer,
            seller=self.seller,
            subtotal=Decimal('100.00'),
            total_amount=Decimal('100.00'),
            payment_status='paid',
            fulfillment_status='completed'
        )
        
        self.assertTrue(transaction.is_completed)
        
        # Test incomplete transaction
        incomplete_transaction = Transaction.objects.create(
            buyer=self.buyer,
            seller=self.seller,
            subtotal=Decimal('100.00'),
            total_amount=Decimal('100.00'),
            payment_status='pending',
            fulfillment_status='pending'
        )
        
        self.assertFalse(incomplete_transaction.is_completed)
    
    def test_is_overdue_property(self):
        """Test is_overdue property."""
        overdue_transaction = Transaction.objects.create(
            buyer=self.buyer,
            seller=self.seller,
            subtotal=Decimal('100.00'),
            total_amount=Decimal('100.00'),
            payment_status='overdue'
        )
        
        self.assertTrue(overdue_transaction.is_overdue)
    
    def test_days_since_order_property(self):
        """Test days_since_order property."""
        transaction = Transaction.objects.create(
            buyer=self.buyer,
            seller=self.seller,
            subtotal=Decimal('100.00'),
            total_amount=Decimal('100.00')
        )
        
        # Should be 0 for newly created transaction
        self.assertEqual(transaction.days_since_order, 0)
    
    def test_estimated_profit_property(self):
        """Test estimated profit calculation."""
        transaction = Transaction.objects.create(
            buyer=self.buyer,
            seller=self.seller,
            subtotal=Decimal('500.00'),
            platform_fee=Decimal('25.00'),
            total_amount=Decimal('500.00')
        )
        
        self.assertEqual(transaction.estimated_profit, Decimal('475.00'))
    
    def test_mark_as_paid_method(self):
        """Test mark_as_paid method."""
        transaction = Transaction.objects.create(
            buyer=self.buyer,
            seller=self.seller,
            subtotal=Decimal('100.00'),
            total_amount=Decimal('100.00')
        )
        
        transaction.mark_as_paid()
        self.assertEqual(transaction.payment_status, 'paid')
    
    def test_mark_as_delivered_method(self):
        """Test mark_as_delivered method."""
        transaction = Transaction.objects.create(
            buyer=self.buyer,
            seller=self.seller,
            subtotal=Decimal('100.00'),
            total_amount=Decimal('100.00')
        )
        
        transaction.mark_as_delivered()
        self.assertEqual(transaction.fulfillment_status, 'delivered')
        self.assertIsNotNone(transaction.actual_delivery_date)
    
    def test_mark_as_completed_method(self):
        """Test mark_as_completed method."""
        transaction = Transaction.objects.create(
            buyer=self.buyer,
            seller=self.seller,
            subtotal=Decimal('100.00'),
            total_amount=Decimal('100.00')
        )
        
        transaction.mark_as_completed()
        self.assertEqual(transaction.fulfillment_status, 'completed')
        self.assertEqual(transaction.payment_status, 'paid')
        self.assertIsNotNone(transaction.completion_date)


class TransactionItemModelTest(TestCase):
    """Test TransactionItem model functionality."""
    
    def setUp(self):
        self.buyer = User.objects.create_user(
            username='buyer',
            email='buyer@example.com',
            password='testpass123'
        )
        
        self.seller = User.objects.create_user(
            username='seller',
            email='seller@example.com',
            password='testpass123'
        )
        
        self.category = Category.objects.create(
            name='Electronics',
            slug='electronics'
        )
        
        self.product = Product.objects.create(
            name='Test Product',
            slug='test-product',
            description='Test product',
            category=self.category,
            base_price=Decimal('100.00'),
            quantity_available=50
        )
        
        self.transaction = Transaction.objects.create(
            buyer=self.buyer,
            seller=self.seller,
            subtotal=Decimal('200.00'),
            total_amount=Decimal('200.00')
        )
    
    def test_transaction_item_creation(self):
        """Test transaction item creation."""
        item = TransactionItem.objects.create(
            transaction=self.transaction,
            product=self.product,
            name='Test Product',
            unit_price=Decimal('100.00'),
            quantity=2
        )
        
        self.assertEqual(item.transaction, self.transaction)
        self.assertEqual(item.product, self.product)
        self.assertEqual(item.name, 'Test Product')
        self.assertEqual(item.unit_price, Decimal('100.00'))
        self.assertEqual(item.quantity, 2)
        self.assertEqual(item.line_total, Decimal('200.00'))
    
    def test_transaction_item_str_representation(self):
        """Test string representation of transaction item."""
        item = TransactionItem.objects.create(
            transaction=self.transaction,
            product=self.product,
            name='Test Product',
            unit_price=Decimal('100.00'),
            quantity=1
        )
        
        expected_str = f"{self.transaction.reference_number} - Test Product"
        self.assertEqual(str(item), expected_str)
    
    def test_line_total_calculation(self):
        """Test automatic line total calculation on save."""
        item = TransactionItem.objects.create(
            transaction=self.transaction,
            product=self.product,
            name='Test Product',
            unit_price=Decimal('50.00'),
            quantity=3
        )
        
        self.assertEqual(item.line_total, Decimal('150.00'))
        
        # Test updating quantity
        item.quantity = 5
        item.save()
        self.assertEqual(item.line_total, Decimal('250.00'))


class PaymentModelTest(TestCase):
    """Test Payment model functionality."""
    
    def setUp(self):
        self.buyer = User.objects.create_user(
            username='buyer',
            email='buyer@example.com',
            password='testpass123'
        )
        
        self.seller = User.objects.create_user(
            username='seller',
            email='seller@example.com',
            password='testpass123'
        )
        
        self.transaction = Transaction.objects.create(
            buyer=self.buyer,
            seller=self.seller,
            subtotal=Decimal('500.00'),
            total_amount=Decimal('500.00')
        )
    
    def test_payment_creation(self):
        """Test payment creation."""
        payment = Payment.objects.create(
            transaction=self.transaction,
            amount=Decimal('500.00'),
            payment_method='credit_card',
            payment_type='full'
        )
        
        self.assertEqual(payment.transaction, self.transaction)
        self.assertEqual(payment.amount, Decimal('500.00'))
        self.assertEqual(payment.payment_method, 'credit_card')
        self.assertEqual(payment.payment_type, 'full')
        self.assertEqual(payment.status, StatusChoices.PENDING)
        self.assertIsNotNone(payment.reference_number)
    
    def test_payment_str_representation(self):
        """Test string representation of payment."""
        payment = Payment.objects.create(
            transaction=self.transaction,
            amount=Decimal('250.00'),
            payment_method='paypal'
        )
        
        expected_str = f"{payment.reference_number} - $250.00"
        self.assertEqual(str(payment), expected_str)
    
    def test_payment_reference_number_generation(self):
        """Test automatic reference number generation."""
        payment = Payment.objects.create(
            transaction=self.transaction,
            amount=Decimal('100.00'),
            payment_method='bank_transfer'
        )
        
        self.assertTrue(payment.reference_number.startswith('PAY'))
        self.assertIsNotNone(payment.reference_number)
    
    def test_mark_as_processed_method(self):
        """Test mark_as_processed method."""
        user = User.objects.create_user(
            username='processor',
            email='processor@example.com',
            password='testpass123'
        )
        
        payment = Payment.objects.create(
            transaction=self.transaction,
            amount=Decimal('100.00'),
            payment_method='credit_card'
        )
        
        payment.mark_as_processed(user)
        
        self.assertEqual(payment.status, StatusChoices.COMPLETED)
        self.assertEqual(payment.processed_by, user)
        self.assertIsNotNone(payment.processed_date)


class DeliveryModelTest(TestCase):
    """Test Delivery model functionality."""
    
    def setUp(self):
        self.buyer = User.objects.create_user(
            username='buyer',
            email='buyer@example.com',
            password='testpass123'
        )
        
        self.seller = User.objects.create_user(
            username='seller',
            email='seller@example.com',
            password='testpass123'
        )
        
        self.transaction = Transaction.objects.create(
            buyer=self.buyer,
            seller=self.seller,
            subtotal=Decimal('300.00'),
            total_amount=Decimal('300.00')
        )
    
    def test_delivery_creation(self):
        """Test delivery creation."""
        delivery = Delivery.objects.create(
            transaction=self.transaction,
            delivery_method='courier',
            carrier='DHL',
            tracking_number='DHL123456789',
            delivery_address='123 Main St, City, Country',
            delivery_contact_name='John Doe',
            delivery_contact_phone='+1234567890',
            delivery_cost=Decimal('25.00')
        )
        
        self.assertEqual(delivery.transaction, self.transaction)
        self.assertEqual(delivery.delivery_method, 'courier')
        self.assertEqual(delivery.carrier, 'DHL')
        self.assertEqual(delivery.tracking_number, 'DHL123456789')
        self.assertEqual(delivery.delivery_cost, Decimal('25.00'))
        self.assertEqual(delivery.status, 'scheduled')
    
    def test_delivery_str_representation(self):
        """Test string representation of delivery."""
        delivery = Delivery.objects.create(
            transaction=self.transaction,
            delivery_method='pickup',
            delivery_address='123 Main St',
            delivery_contact_name='Jane Doe'
        )
        
        expected_str = f"Delivery for {self.transaction.reference_number}"
        self.assertEqual(str(delivery), expected_str)
    
    def test_is_delivered_property(self):
        """Test is_delivered property."""
        delivery = Delivery.objects.create(
            transaction=self.transaction,
            delivery_method='courier',
            delivery_address='123 Main St',
            delivery_contact_name='John Doe',
            status='delivered'
        )
        
        self.assertTrue(delivery.is_delivered)
        
        # Test not delivered
        delivery.status = 'in_transit'
        delivery.save()
        self.assertFalse(delivery.is_delivered)
    
    def test_mark_as_delivered_method(self):
        """Test mark_as_delivered method."""
        delivery = Delivery.objects.create(
            transaction=self.transaction,
            delivery_method='courier',
            delivery_address='123 Main St',
            delivery_contact_name='John Doe'
        )
        
        delivery.mark_as_delivered(
            signature_name='John Doe',
            notes='Delivered successfully'
        )
        
        self.assertEqual(delivery.status, 'delivered')
        self.assertEqual(delivery.signature_name, 'John Doe')
        self.assertEqual(delivery.delivery_notes, 'Delivered successfully')
        self.assertIsNotNone(delivery.delivery_date)
        
        # Check that transaction was also updated
        self.transaction.refresh_from_db()
        self.assertEqual(self.transaction.fulfillment_status, 'delivered')


class TransactionMessageModelTest(TestCase):
    """Test TransactionMessage model functionality."""
    
    def setUp(self):
        self.buyer = User.objects.create_user(
            username='buyer',
            email='buyer@example.com',
            password='testpass123'
        )
        
        self.seller = User.objects.create_user(
            username='seller',
            email='seller@example.com',
            password='testpass123'
        )
        
        self.transaction = Transaction.objects.create(
            buyer=self.buyer,
            seller=self.seller,
            subtotal=Decimal('200.00'),
            total_amount=Decimal('200.00')
        )
    
    def test_transaction_message_creation(self):
        """Test transaction message creation."""
        message = TransactionMessage.objects.create(
            transaction=self.transaction,
            sender=self.buyer,
            message_type='inquiry',
            subject='Delivery Question',
            message='When will my order be shipped?',
            is_internal=False
        )
        
        self.assertEqual(message.transaction, self.transaction)
        self.assertEqual(message.sender, self.buyer)
        self.assertEqual(message.message_type, 'inquiry')
        self.assertEqual(message.subject, 'Delivery Question')
        self.assertFalse(message.is_internal)
    
    def test_transaction_message_str_representation(self):
        """Test string representation of transaction message."""
        message = TransactionMessage.objects.create(
            transaction=self.transaction,
            sender=self.seller,
            message_type='update',
            subject='Order Update',
            message='Your order has been processed.'
        )
        
        expected_str = f"{self.transaction.reference_number} - {self.seller.username}: Order Update"
        self.assertEqual(str(message), expected_str)
    
    def test_message_read_functionality(self):
        """Test message read functionality."""
        message = TransactionMessage.objects.create(
            transaction=self.transaction,
            sender=self.buyer,
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
