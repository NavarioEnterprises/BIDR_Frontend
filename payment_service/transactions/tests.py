# Set up Django environment if not already configured
import os
import django
from django.conf import settings

if not settings.configured:
    os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'payment_service.settings')
    django.setup()

from django.test import TestCase
from django.urls import reverse
from rest_framework.test import APITestCase
from rest_framework import status
from .models import Transaction, TransactionPIN
import uuid
from decimal import Decimal


class TransactionModelTest(TestCase):
    """Test Transaction model"""
    
    def test_create_transaction(self):
        """Test creating a transaction"""
        transaction = Transaction.objects.create(
            buyer_id=uuid.uuid4(),
            seller_id=uuid.uuid4(),
            amount=Decimal('1000.00'),
            description="Test transaction"
        )
        self.assertEqual(transaction.amount, Decimal('1000.00'))
        self.assertEqual(transaction.status, 'pending')
        self.assertEqual(transaction.transaction_type, 'escrow')


class TransactionAPITest(APITestCase):
    """Test Transaction API endpoints"""
    
    def test_create_transaction_api(self):
        """Test creating transaction via API"""
        url = reverse('transaction-list')
        data = {
            'buyer_id': str(uuid.uuid4()),
            'seller_id': str(uuid.uuid4()),
            'amount': '5000.00',
            'description': 'API test transaction'
        }
        response = self.client.post(url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
    
    def test_list_transactions(self):
        """Test listing transactions"""
        url = reverse('transaction-list')
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
