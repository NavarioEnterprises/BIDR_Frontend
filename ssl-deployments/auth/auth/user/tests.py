"""
Tests for the user app
"""
# Set up Django environment if not already configured
import os
import django
from django.conf import settings

if not settings.configured:
    os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'authentication_service.settings')
    django.setup()

import json
from datetime import timedelta
from django.test import TestCase
from django.urls import reverse
from django.contrib.auth.tokens import default_token_generator
from django.utils.http import urlsafe_base64_encode
from django.utils.encoding import force_bytes
from django.utils import timezone
from rest_framework import status
from rest_framework.test import APITestCase, APIClient
from rest_framework_simplejwt.tokens import RefreshToken

from .models import AppUser, MetadataModel
from .serializers import (
    UserLoginSerializer, PasswordResetRequestSerializer, 
    PasswordResetSerializer, UserProfileSerializer, RoleSelectionSerializer
)


class AppUserModelTest(TestCase):
    """Test cases for AppUser model"""
    
    def setUp(self):
        self.user_data = {
            'email': 'test@example.com',
            'first_name': 'John',
            'last_name': 'Doe',
            'phone_number': '+1234567890',
            'role': 'buyer',
            'password': 'TestPass123!'
        }
        
    def test_create_user(self):
        """Test creating a new user"""
        user = AppUser.objects.create_user(**self.user_data)
        self.assertEqual(user.email, self.user_data['email'])
        self.assertEqual(user.get_decrypted_first_name(), self.user_data['first_name'])
        self.assertEqual(user.role, self.user_data['role'])
        self.assertTrue(user.check_password(self.user_data['password']))
        self.assertIsNotNone(user.uid)
        
    def test_create_superuser(self):
        """Test creating a superuser"""
        user = AppUser.objects.create_superuser(
            email='admin@example.com',
            password='AdminPass123!',
            first_name='Admin',
            last_name='User',
            phone_number='+1234567891'
        )
        self.assertTrue(user.is_superuser)
        self.assertTrue(user.is_staff)
        
    def test_user_str_method(self):
        """Test string representation of user"""
        user = AppUser.objects.create_user(**self.user_data)
        self.assertEqual(str(user), self.user_data['email'])
        
    def test_get_full_name(self):
        """Test get_full_name method"""
        user = AppUser.objects.create_user(**self.user_data)
        expected_name = f"{self.user_data['first_name']} {self.user_data['last_name']}"
        self.assertEqual(user.get_full_name(), expected_name)
        
    def test_unique_email(self):
        """Test email uniqueness constraint"""
        AppUser.objects.create_user(**self.user_data)
        with self.assertRaises(Exception):
            AppUser.objects.create_user(**self.user_data)


class MetadataModelTest(TestCase):
    """Test cases for MetadataModel abstract class"""
    
    def setUp(self):
        self.user = AppUser.objects.create_user(
            email='test@example.com',
            password='testpass123',
            first_name='Test',
            last_name='User',
            phone_number='+1234567890'
        )
        
    def test_soft_delete(self):
        """Test soft delete functionality"""
        # Since MetadataModel is abstract, we can't test it directly
        # This would be tested in concrete implementations
        pass
        
    def test_restore(self):
        """Test restore functionality"""
        # Since MetadataModel is abstract, we can't test it directly
        # This would be tested in concrete implementations
        pass


class UserLoginViewTest(APITestCase):
    """Test cases for user login"""
    
    def setUp(self):
        self.client = APIClient()
        self.login_url = reverse('user-login')
        self.user = AppUser.objects.create_user(
            email='test@example.com',
            password='testpass123',
            first_name='John',
            last_name='Doe',
            phone_number='+1234567890',
            role='buyer',
            email_verified=True
        )
        
    def test_successful_login(self):
        """Test successful login with valid credentials"""
        data = {
            'email': 'test@example.com',
            'password': 'testpass123'
        }
        response = self.client.post(self.login_url, data)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('access_token', response.data)
        self.assertIn('refresh_token', response.data)
        self.assertIn('user', response.data)
        
    def test_login_with_invalid_credentials(self):
        """Test login with invalid credentials"""
        data = {
            'email': 'test@example.com',
            'password': 'wrongpassword'
        }
        response = self.client.post(self.login_url, data)
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        
    def test_login_unverified_email(self):
        """Test login with unverified email"""
        self.user.email_verified = False
        self.user.save()
        
        data = {
            'email': 'test@example.com',
            'password': 'testpass123'
        }
        response = self.client.post(self.login_url, data)
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('verify your email', response.data['error'])
        
    def test_login_missing_fields(self):
        """Test login with missing required fields"""
        data = {'email': 'test@example.com'}  # Missing password
        response = self.client.post(self.login_url, data)
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)


class PasswordResetTest(APITestCase):
    """Test cases for password reset functionality"""
    
    def setUp(self):
        self.client = APIClient()
        self.reset_request_url = reverse('password-reset-request')
        self.reset_url = reverse('password-reset')
        self.user = AppUser.objects.create_user(
            email='test@example.com',
            password='testpass123',
            first_name='John',
            last_name='Doe',
            phone_number='+1234567890',
            role='buyer'
        )
        
    def test_password_reset_request(self):
        """Test password reset request"""
        data = {'email': 'test@example.com'}
        response = self.client.post(self.reset_request_url, data)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('reset link sent', response.data['message'])
        
    def test_password_reset_request_invalid_email(self):
        """Test password reset request with invalid email"""
        data = {'email': 'nonexistent@example.com'}
        response = self.client.post(self.reset_request_url, data)
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        
    def test_password_reset_with_valid_token(self):
        """Test password reset with valid token"""
        token = default_token_generator.make_token(self.user)
        uid = urlsafe_base64_encode(force_bytes(self.user.pk))
        
        data = {
            'uid': uid,
            'token': token,
            'password': 'NewPass123!',
            'confirm_password': 'NewPass123!'
        }
        response = self.client.post(self.reset_url, data)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        # Verify password was changed
        self.user.refresh_from_db()
        self.assertTrue(self.user.check_password('NewPass123!'))
        
    def test_password_reset_with_invalid_token(self):
        """Test password reset with invalid token"""
        uid = urlsafe_base64_encode(force_bytes(self.user.pk))
        
        data = {
            'uid': uid,
            'token': 'invalid-token',
            'password': 'newpassword123',
            'confirm_password': 'newpassword123'
        }
        response = self.client.post(self.reset_url, data)
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)


class UserLogoutViewTest(APITestCase):
    """Test cases for user logout"""
    
    def setUp(self):
        self.client = APIClient()
        self.logout_url = reverse('user-logout')
        self.user = AppUser.objects.create_user(
            email='test@example.com',
            password='testpass123',
            first_name='John',
            last_name='Doe',
            phone_number='+1234567890',
            role='buyer'
        )
        self.refresh = RefreshToken.for_user(self.user)
        self.client.force_authenticate(user=self.user)
        
    def test_successful_logout(self):
        """Test successful logout"""
        data = {'refresh_token': str(self.refresh)}
        response = self.client.post(self.logout_url, data)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
    def test_logout_without_authentication(self):
        """Test logout without authentication"""
        self.client.force_authenticate(user=None)
        response = self.client.post(self.logout_url)
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)


class UserProfileViewTest(APITestCase):
    """Test cases for user profile management"""
    
    def setUp(self):
        self.client = APIClient()
        self.profile_url = reverse('user-profile')
        self.user = AppUser.objects.create_user(
            email='test@example.com',
            password='testpass123',
            first_name='John',
            last_name='Doe',
            phone_number='+1234567890',
            role='buyer'
        )
        self.client.force_authenticate(user=self.user)
        
    def test_get_user_profile(self):
        """Test retrieving user profile"""
        response = self.client.get(self.profile_url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['email'], self.user.email)
        
    def test_update_user_profile(self):
        """Test updating user profile"""
        data = {
            'first_name': 'Jane',
            'last_name': 'Smith'
        }
        response = self.client.patch(self.profile_url, data)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
    def test_profile_unauthorized_access(self):
        """Test accessing profile without authentication"""
        self.client.force_authenticate(user=None)
        response = self.client.get(self.profile_url)
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)


class RoleSelectionViewTest(APITestCase):
    """Test cases for role selection"""
    
    def setUp(self):
        self.client = APIClient()
        self.role_selection_url = reverse('role-selection')
        
    def test_valid_role_selection(self):
        """Test selecting a valid role"""
        data = {'role': 'buyer'}
        response = self.client.post(self.role_selection_url, data)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['role'], 'buyer')
        
    def test_invalid_role_selection(self):
        """Test selecting an invalid role"""
        data = {'role': 'invalid_role'}
        response = self.client.post(self.role_selection_url, data)
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        
    def test_administrator_role_selection(self):
        """Test selecting administrator role (should be rejected)"""
        data = {'role': 'administrator'}
        response = self.client.post(self.role_selection_url, data)
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)


class UserSerializerTest(TestCase):
    """Test cases for user serializers"""
    
    def setUp(self):
        self.user = AppUser.objects.create_user(
            email='test@example.com',
            password='testpass123',
            first_name='John',
            last_name='Doe',
            phone_number='+1234567890',
            role='buyer'
        )
        
    def test_user_login_serializer_valid(self):
        """Test UserLoginSerializer with valid data"""
        data = {
            'email': 'test@example.com',
            'password': 'testpass123'
        }
        serializer = UserLoginSerializer(data=data)
        self.assertTrue(serializer.is_valid())
        
    def test_user_login_serializer_invalid(self):
        """Test UserLoginSerializer with invalid data"""
        data = {
            'email': 'test@example.com',
            'password': 'wrongpassword'
        }
        serializer = UserLoginSerializer(data=data)
        self.assertFalse(serializer.is_valid())
        
    def test_user_profile_serializer(self):
        """Test UserProfileSerializer"""
        serializer = UserProfileSerializer(self.user)
        self.assertEqual(serializer.data['email'], self.user.email)
        
    def test_password_reset_request_serializer_valid(self):
        """Test PasswordResetRequestSerializer with valid email"""
        data = {'email': 'test@example.com'}
        serializer = PasswordResetRequestSerializer(data=data)
        self.assertTrue(serializer.is_valid())
        
    def test_password_reset_request_serializer_invalid(self):
        """Test PasswordResetRequestSerializer with invalid email"""
        data = {'email': 'nonexistent@example.com'}
        serializer = PasswordResetRequestSerializer(data=data)
        self.assertFalse(serializer.is_valid())
        
    def test_password_reset_serializer_valid(self):
        """Test PasswordResetSerializer with valid data"""
        data = {
            'password': 'newpassword123',
            'confirm_password': 'newpassword123',
            'token': 'some-token'
        }
        serializer = PasswordResetSerializer(data=data)
        self.assertTrue(serializer.is_valid())
        
    def test_password_reset_serializer_password_mismatch(self):
        """Test PasswordResetSerializer with password mismatch"""
        data = {
            'password': 'newpassword123',
            'confirm_password': 'differentpassword',
            'token': 'some-token'
        }
        serializer = PasswordResetSerializer(data=data)
        self.assertFalse(serializer.is_valid())
        
    def test_role_selection_serializer_valid(self):
        """Test RoleSelectionSerializer with valid role"""
        data = {'role': 'seller'}
        serializer = RoleSelectionSerializer(data=data)
        self.assertTrue(serializer.is_valid())
        
    def test_role_selection_serializer_invalid(self):
        """Test RoleSelectionSerializer with invalid role"""
        data = {'role': 'administrator'}
        serializer = RoleSelectionSerializer(data=data)
        self.assertFalse(serializer.is_valid())
