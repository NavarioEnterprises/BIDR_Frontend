"""
Simple API Integration Test for BIDR Chat Service

This test checks basic API functionality without full REST framework setup.
"""

import django
import os
import sys

# Add current directory to Python path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

# Set Django settings
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'settings')
django.setup()

from django.test import TestCase, Client
from django.contrib.auth.models import User
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase, APIClient
from chat_core.models import UserProfile, SystemConfig
import json


class ChatServiceIntegrationTest(TestCase):
    """Basic integration tests for chat service components."""
    
    def setUp(self):
        """Set up test data."""
        self.client = Client()
        
        # Create test users
        self.user1 = User.objects.create_user(
            username='testuser1',
            email='user1@example.com',
            password='testpass123'
        )
        self.user2 = User.objects.create_user(
            username='testuser2',
            email='user2@example.com',
            password='testpass123'
        )
        
        # Create user profiles
        self.profile1 = UserProfile.objects.create(
            user=self.user1,
            role='buyer',
            display_name='Test User 1'
        )
        self.profile2 = UserProfile.objects.create(
            user=self.user2,
            role='seller',
            display_name='Test User 2'
        )
        
        # Create system config
        self.config = SystemConfig.objects.create(
            category='translation',
            key='default_provider',
            value='google',
            description='Default translation provider'
        )
    
    def test_user_profile_creation(self):
        """Test user profile creation and retrieval."""
        # Test profile exists
        self.assertIsNotNone(self.profile1)
        self.assertEqual(self.profile1.user, self.user1)
        self.assertEqual(self.profile1.role, 'buyer')
        
        # Test display name method
        self.assertEqual(self.profile1.get_display_name(), 'Test User 1')
        
        # Test messaging capability
        self.assertTrue(self.profile1.can_send_messages())
    
    def test_system_configuration(self):
        """Test system configuration functionality."""
        # Test config retrieval
        config_value = SystemConfig.get_config('translation', 'default_provider')
        self.assertEqual(config_value, 'google')
        
        # Test default value
        default_value = SystemConfig.get_config('nonexistent', 'key', 'default')
        self.assertEqual(default_value, 'default')
    
    def test_user_authentication(self):
        """Test basic user authentication."""
        # Test login
        login_result = self.client.login(username='testuser1', password='testpass123')
        self.assertTrue(login_result)
        
        # Test logout
        self.client.logout()
    
    def test_model_relationships(self):
        """Test model relationships work correctly."""
        # Test user profile relationship
        self.assertEqual(self.user1.chat_profile, self.profile1)
        
        # Test profile user relationship
        self.assertEqual(self.profile1.user, self.user1)
    
    def test_model_methods(self):
        """Test custom model methods."""
        # Test online status
        self.assertTrue(self.profile1.is_online())  # Should be online (just created)
        
        # Test can send messages
        self.assertTrue(self.profile1.can_send_messages())
        
        # Test banned user cannot send messages
        self.profile1.is_banned = True
        self.profile1.save()
        self.assertFalse(self.profile1.can_send_messages())
    
    def test_database_transactions(self):
        """Test database transactions work correctly."""
        initial_count = User.objects.count()
        
        # Create new user
        new_user = User.objects.create_user(
            username='testuser3',
            email='user3@example.com',
            password='testpass123'
        )
        
        # Verify count increased
        self.assertEqual(User.objects.count(), initial_count + 1)
        
        # Verify user exists
        self.assertTrue(User.objects.filter(username='testuser3').exists())


def run_tests():
    """Run the integration tests manually."""
    print("Running Chat Service Integration Tests...")
    
    # Create test instance
    test_instance = ChatServiceIntegrationTest()
    test_instance.setUp()
    
    # Run tests
    tests = [
        'test_user_profile_creation',
        'test_system_configuration', 
        'test_user_authentication',
        'test_model_relationships',
        'test_model_methods',
        'test_database_transactions'
    ]
    
    passed = 0
    failed = 0
    
    for test_name in tests:
        try:
            print(f"Running {test_name}...")
            test_method = getattr(test_instance, test_name)
            test_method()
            print(f"✓ {test_name} PASSED")
            passed += 1
        except Exception as e:
            print(f"✗ {test_name} FAILED: {e}")
            failed += 1
    
    print(f"\nTest Results: {passed} passed, {failed} failed")
    return failed == 0


if __name__ == '__main__':
    success = run_tests()
    sys.exit(0 if success else 1)
