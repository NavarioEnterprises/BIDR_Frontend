from django.test import TestCase, Client
from django.contrib.auth.models import User
from django.urls import reverse
from rest_framework.test import APITestCase
from rest_framework import status
from decimal import Decimal
from .models import (
    UserProfile, SystemConfiguration, ServiceHealth,
    APIKey, TransactionReference
)


class UserProfileModelTest(TestCase):
    """Test UserProfile model"""
    
    def setUp(self):
        self.user = User.objects.create_user(
            username='testuser',
            email='test@example.com',
            password='testpass123'
        )
    
    def test_user_profile_creation(self):
        profile = UserProfile.objects.create(
            user=self.user,
            phone_number='+1234567890',
            is_verified=True,
            total_transactions=10,
            successful_transactions=8
        )
        self.assertEqual(profile.user, self.user)
        self.assertEqual(profile.phone_number, '+1234567890')
        self.assertEqual(profile.success_rate, 80.0)
        self.assertEqual(str(profile), 'testuser - Profile')
    
    def test_success_rate_calculation(self):
        profile = UserProfile.objects.create(
            user=self.user,
            total_transactions=0,
            successful_transactions=0
        )
        self.assertEqual(profile.success_rate, 0)
        
        profile.total_transactions = 20
        profile.successful_transactions = 18
        profile.save()
        self.assertEqual(profile.success_rate, 90.0)


class SystemConfigurationModelTest(TestCase):
    """Test SystemConfiguration model"""
    
    def test_system_configuration_creation(self):
        config = SystemConfiguration.objects.create(
            key='test_setting',
            value='test_value',
            description='Test configuration setting'
        )
        self.assertEqual(config.key, 'test_setting')
        self.assertTrue(config.is_active)
        self.assertIn('test_setting', str(config))


class ServiceHealthModelTest(TestCase):
    """Test ServiceHealth model"""
    
    def test_service_health_creation(self):
        health = ServiceHealth.objects.create(
            service_name='test_service',
            status='healthy',
            response_time=150.5
        )
        self.assertEqual(health.service_name, 'test_service')
        self.assertEqual(health.status, 'healthy')
        self.assertEqual(health.response_time, 150.5)
        self.assertEqual(str(health), 'test_service: healthy')


class APIKeyModelTest(TestCase):
    """Test APIKey model"""
    
    def setUp(self):
        self.user = User.objects.create_user(
            username='apiuser',
            email='api@example.com',
            password='apipass123'
        )
    
    def test_api_key_creation(self):
        api_key = APIKey.objects.create(
            name='Test API Key',
            key='test-key-12345',
            created_by=self.user,
            permissions=['read', 'write'],
            rate_limit=5000
        )
        self.assertEqual(api_key.name, 'Test API Key')
        self.assertTrue(api_key.is_active)
        self.assertEqual(api_key.rate_limit, 5000)
        self.assertIn('Test API Key', str(api_key))


class TransactionReferenceModelTest(TestCase):
    """Test TransactionReference model"""
    
    def test_transaction_reference_creation(self):
        transaction = TransactionReference.objects.create(
            transaction_id='TXN12345',
            service_name='payment_service',
            buyer_id='buyer123',
            seller_id='seller456',
            amount=Decimal('299.99'),
            currency='USD',
            status='completed'
        )
        self.assertEqual(transaction.transaction_id, 'TXN12345')
        self.assertEqual(transaction.amount, Decimal('299.99'))
        self.assertEqual(str(transaction), 'Transaction TXN12345 - completed')


class CoreAPITest(APITestCase):
    """Test Core API endpoints"""
    
    def setUp(self):
        self.user = User.objects.create_user(
            username='testuser',
            email='test@example.com',
            password='testpass123'
        )
        self.client.force_authenticate(user=self.user)
    
    def test_health_check_endpoint(self):
        """Test health check endpoint (no authentication required)"""
        self.client.force_authenticate(user=None)  # Remove authentication
        url = reverse('health_check')
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['status'], 'healthy')
        self.assertEqual(response.data['service'], 'resolution_service')
    
    def test_service_info_endpoint(self):
        """Test service info endpoint (no authentication required)"""
        self.client.force_authenticate(user=None)  # Remove authentication
        url = reverse('service_info')
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['service_name'], 'BIDR Resolution Service')
        self.assertIn('endpoints', response.data)
    
    def test_service_statistics_endpoint(self):
        """Test service statistics endpoint (authentication required)"""
        url = reverse('service_statistics')
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('users', response.data)
        self.assertIn('transactions', response.data)
    
    def test_service_statistics_unauthorized(self):
        """Test service statistics endpoint without authentication"""
        self.client.force_authenticate(user=None)
        url = reverse('service_statistics')
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)


class UserProfileAPITest(APITestCase):
    """Test UserProfile API endpoints"""
    
    def setUp(self):
        self.admin_user = User.objects.create_superuser(
            username='admin',
            email='admin@example.com',
            password='adminpass123'
        )
        self.regular_user = User.objects.create_user(
            username='regular',
            email='regular@example.com',
            password='regularpass123'
        )
        self.client.force_authenticate(user=self.admin_user)
    
    def test_create_user_profile(self):
        """Test creating a user profile via API"""
        url = reverse('userprofile-list')
        data = {
            'user': self.regular_user.id,
            'phone_number': '+1234567890',
            'is_verified': True
        }
        response = self.client.post(url, data)
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(UserProfile.objects.count(), 1)
        profile = UserProfile.objects.get()
        self.assertEqual(profile.user, self.regular_user)
    
    def test_list_user_profiles(self):
        """Test listing user profiles"""
        UserProfile.objects.create(user=self.regular_user)
        url = reverse('userprofile-list')
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data['results']), 1)


class SystemConfigurationAPITest(APITestCase):
    """Test SystemConfiguration API endpoints"""
    
    def setUp(self):
        self.admin_user = User.objects.create_superuser(
            username='admin',
            email='admin@example.com',
            password='adminpass123'
        )
        self.client.force_authenticate(user=self.admin_user)
    
    def test_create_system_configuration(self):
        """Test creating system configuration"""
        url = reverse('systemconfiguration-list')
        data = {
            'key': 'test_config',
            'value': 'test_value',
            'description': 'Test configuration'
        }
        response = self.client.post(url, data)
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(SystemConfiguration.objects.count(), 1)
    
    def test_list_system_configurations(self):
        """Test listing system configurations"""
        SystemConfiguration.objects.create(
            key='config1',
            value='value1',
            description='Config 1'
        )
        url = reverse('systemconfiguration-list')
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data['results']), 1)
