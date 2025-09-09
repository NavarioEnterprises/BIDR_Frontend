from django.test import TestCase
from django.contrib.auth import get_user_model
from django.urls import reverse
from rest_framework.test import APITestCase, APIClient
from rest_framework import status
from unittest.mock import patch
from decimal import Decimal

from .models import PaymentTransaction
from transactions.models import Transaction
from external_models import Seller, Buyer, Quote


class SellerEarningHistoryTestCase(APITestCase):
    """Test cases for the seller earning history endpoint."""
    
    def setUp(self):
        """Set up test data."""
        # Create mock user (assuming User model exists)
        self.user = get_user_model().objects.create_user(
            username='testseller',
            email='seller@test.com',
            password='testpassword'
        )
        self.user.role = 'seller'
        self.user.save()
        
        # Create seller, buyer, and quote instances
        self.seller = Seller.objects.create(
            username='testseller',
            email='seller@test.com'
        )
        
        self.buyer = Buyer.objects.create(
            username='testbuyer',
            email='buyer@test.com'
        )
        
        self.quote = Quote.objects.create(
            amount=Decimal('100.00'),
            currency='USD'
        )
        
        # Create transaction
        self.transaction = Transaction.objects.create(
            quote_id=self.quote,
            buyer_id=self.buyer,
            seller_id=self.seller,
            buyer_pin='123456',
            seller_pin='654321',
            total_amount=Decimal('100.00'),
            currency='USD',
            payment_status='PAID'
        )
        
        # Create payment transactions with different statuses
        self.successful_payment = PaymentTransaction.objects.create(
            transaction_id=self.transaction,
            payment_gateway='PAYFAST',
            amount=Decimal('100.00'),
            currency='USD',
            payment_method='Credit Card',
            status='CAPTURED'
        )
        
        self.released_payment = PaymentTransaction.objects.create(
            transaction_id=self.transaction,
            payment_gateway='STRIPE',
            amount=Decimal('50.00'),
            currency='USD',
            payment_method='Credit Card',
            status='RELEASED'
        )
        
        self.pending_payment = PaymentTransaction.objects.create(
            transaction_id=self.transaction,
            payment_gateway='PAYPAL',
            amount=Decimal('25.00'),
            currency='USD',
            payment_method='PayPal',
            status='PENDING'
        )
        
        # Set up API client
        self.client = APIClient()
        self.client.force_authenticate(user=self.user)
        
        # URL for the earning history endpoint
        self.url = reverse('payment_transactions:payment-transaction-seller-earnings')
    
    def test_seller_can_access_earning_history(self):
        """Test that sellers can access their earning history."""
        response = self.client.get(self.url)
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        data = response.json()
        
        # Should return only successful payments (CAPTURED and RELEASED)
        if isinstance(data, dict) and 'results' in data:
            results = data['results']
        else:
            results = data
        
        self.assertEqual(len(results), 2)  # Only CAPTURED and RELEASED payments
        
        # Check that payments are ordered by most recent first
        statuses = [payment['status'] for payment in results]
        self.assertIn('CAPTURED', statuses)
        self.assertIn('RELEASED', statuses)
        self.assertNotIn('PENDING', statuses)
    
    def test_unauthenticated_access_denied(self):
        """Test that unauthenticated users cannot access earning history."""
        self.client.logout()
        response = self.client.get(self.url)
        
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)
    
    def test_non_seller_access_denied(self):
        """Test that non-sellers cannot access earning history."""
        # Change user role to buyer
        self.user.role = 'buyer'
        self.user.save()
        
        response = self.client.get(self.url)
        
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)
    
    def test_filter_by_status(self):
        """Test filtering earning history by payment status."""
        response = self.client.get(self.url, {'status': 'RELEASED'})
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        data = response.json()
        
        if isinstance(data, dict) and 'results' in data:
            results = data['results']
        else:
            results = data
        
        self.assertEqual(len(results), 1)
        self.assertEqual(results[0]['status'], 'RELEASED')
    
    def test_date_filtering(self):
        """Test filtering earning history by date range."""
        from datetime import datetime, timedelta
        
        # Test with a date range that includes all payments
        start_date = (datetime.now() - timedelta(days=1)).strftime('%Y-%m-%d')
        end_date = (datetime.now() + timedelta(days=1)).strftime('%Y-%m-%d')
        
        response = self.client.get(self.url, {
            'start_date': start_date,
            'end_date': end_date
        })
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        data = response.json()
        
        if isinstance(data, dict) and 'results' in data:
            results = data['results']
        else:
            results = data
        
        # Should still return only successful payments within date range
        self.assertEqual(len(results), 2)
    
    def test_response_structure(self):
        """Test that the response has the expected structure."""
        response = self.client.get(self.url)
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        data = response.json()
        
        if isinstance(data, dict) and 'results' in data:
            payment = data['results'][0]
        else:
            payment = data[0]
        
        # Check required fields are present
        required_fields = [
            'payment_id', 'transaction_id', 'amount', 'currency',
            'order_date', 'status', 'earnings_status', 'buyer_info',
            'product_info', 'created_at'
        ]
        
        for field in required_fields:
            self.assertIn(field, payment)
        
        # Check nested structures
        self.assertIn('buyer_id', payment['buyer_info'])
        self.assertIn('username', payment['buyer_info'])
        self.assertIn('quote_id', payment['product_info'])
        self.assertIn('amount', payment['product_info'])


class PaymentTransactionModelTestCase(TestCase):
    """Test cases for PaymentTransaction model."""
    
    def setUp(self):
        """Set up test data."""
        self.seller = Seller.objects.create(
            username='testseller',
            email='seller@test.com'
        )
        
        self.buyer = Buyer.objects.create(
            username='testbuyer',
            email='buyer@test.com'
        )
        
        self.quote = Quote.objects.create(
            amount=Decimal('100.00'),
            currency='USD'
        )
        
        self.transaction = Transaction.objects.create(
            quote_id=self.quote,
            buyer_id=self.buyer,
            seller_id=self.seller,
            buyer_pin='123456',
            seller_pin='654321',
            total_amount=Decimal('100.00'),
            currency='USD',
            payment_status='PAID'
        )
    
    def test_payment_transaction_creation(self):
        """Test creating a PaymentTransaction instance."""
        payment = PaymentTransaction.objects.create(
            transaction_id=self.transaction,
            payment_gateway='PAYFAST',
            amount=Decimal('100.00'),
            currency='USD',
            payment_method='Credit Card',
            status='CAPTURED'
        )
        
        self.assertEqual(payment.transaction_id, self.transaction)
        self.assertEqual(payment.payment_gateway, 'PAYFAST')
        self.assertEqual(payment.amount, Decimal('100.00'))
        self.assertEqual(payment.status, 'CAPTURED')
        self.assertTrue(payment.is_completed())
        self.assertFalse(payment.is_pending())
    
    def test_payment_status_methods(self):
        """Test payment status check methods."""
        # Test pending payment
        pending_payment = PaymentTransaction.objects.create(
            transaction_id=self.transaction,
            payment_gateway='PAYFAST',
            amount=Decimal('100.00'),
            currency='USD',
            payment_method='Credit Card',
            status='PENDING'
        )
        
        self.assertTrue(pending_payment.is_pending())
        self.assertFalse(pending_payment.is_completed())
        self.assertFalse(pending_payment.is_refunded())
        
        # Test completed payment
        completed_payment = PaymentTransaction.objects.create(
            transaction_id=self.transaction,
            payment_gateway='STRIPE',
            amount=Decimal('50.00'),
            currency='USD',
            payment_method='Credit Card',
            status='CAPTURED'
        )
        
        self.assertFalse(completed_payment.is_pending())
        self.assertTrue(completed_payment.is_completed())
        self.assertFalse(completed_payment.is_refunded())
        
        # Test refunded payment
        refunded_payment = PaymentTransaction.objects.create(
            transaction_id=self.transaction,
            payment_gateway='PAYPAL',
            amount=Decimal('25.00'),
            currency='USD',
            payment_method='PayPal',
            status='REFUNDED'
        )
        
        self.assertFalse(refunded_payment.is_pending())
        self.assertFalse(refunded_payment.is_completed())
        self.assertTrue(refunded_payment.is_refunded())
