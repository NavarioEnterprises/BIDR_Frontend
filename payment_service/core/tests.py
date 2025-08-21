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
from .models import PaymentGateway


class PaymentGatewayModelTest(TestCase):
    """Test PaymentGateway model"""
    
    def test_create_payment_gateway(self):
        """Test creating a payment gateway"""
        gateway = PaymentGateway.objects.create(
            name="Test Gateway",
            slug="test-gateway",
            config={"key": "value"}
        )
        self.assertEqual(gateway.name, "Test Gateway")
        self.assertEqual(gateway.slug, "test-gateway")
        self.assertTrue(gateway.is_active)


class PaymentGatewayAPITest(APITestCase):
    """Test PaymentGateway API endpoints"""
    
    def test_create_payment_gateway_api(self):
        """Test creating payment gateway via API"""
        url = reverse('payment-gateway-list')
        data = {
            'name': 'API Test Gateway',
            'slug': 'api-test',
            'config': {'test': True}
        }
        response = self.client.post(url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
    
    def test_health_check(self):
        """Test health check endpoint"""
        url = reverse('health-check')
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['status'], 'healthy')
