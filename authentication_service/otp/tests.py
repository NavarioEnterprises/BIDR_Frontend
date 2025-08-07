"""
Tests for the OTP app
"""
import random
import string
from datetime import timedelta
from django.test import TestCase
from django.urls import reverse
from django.utils import timezone
from rest_framework import status
from rest_framework.test import APITestCase, APIClient

from user.models import AppUser
from .models import OTP
from .serializers import OTPVerificationSerializer


class OTPModelTest(TestCase):
    """Test cases for OTP model"""
    
    def setUp(self):
        self.user = AppUser.objects.create_user(
            email='test@example.com',
            password='testpass123',
            first_name='John',
            last_name='Doe',
            phone_number='+1234567890',
            role='buyer'
        )
        self.otp_code = "123456"
        
    def test_create_otp(self):
        """Test creating a new OTP"""
        otp = OTP.objects.create(user=self.user, otp=self.otp_code)
        self.assertEqual(otp.user, self.user)
        self.assertEqual(otp.otp, self.otp_code)
        self.assertIsNotNone(otp.uuid)
        self.assertIsNone(otp.verified_at)
        
    def test_otp_str_method(self):
        """Test OTP string representation"""
        otp = OTP.objects.create(user=self.user, otp=self.otp_code)
        expected_str = f"OTP {self.otp_code} for {self.user.email} (Expires: {otp.expires_at})"
        self.assertEqual(str(otp), expected_str)
        
    def test_otp_is_expired_false(self):
        """Test OTP is not expired when within validity period"""
        otp = OTP.objects.create(user=self.user, otp=self.otp_code)
        self.assertFalse(otp.is_expired())
        
    def test_otp_is_expired_true(self):
        """Test OTP is expired when past validity period"""
        past_time = timezone.now() - timedelta(minutes=10)
        otp = OTP.objects.create(
            user=self.user,
            otp=self.otp_code,
            expires_at=past_time
        )
        self.assertTrue(otp.is_expired())
        
    def test_validate_for_device(self):
        """Test device-specific validation"""
        device_id = "device123"
        otp = OTP.objects.create(
            user=self.user,
            otp=self.otp_code,
            devices=[device_id, "device456"]
        )
        self.assertTrue(otp.validate_for_device(device_id))
        self.assertFalse(otp.validate_for_device("unknown_device"))
        
    def test_default_expires_at(self):
        """Test default expiration time"""
        otp = OTP.objects.create(user=self.user, otp=self.otp_code)
        expected_expiry = timezone.now() + timedelta(minutes=5)
        # Allow for small time difference during test execution
        time_diff = abs((otp.expires_at - expected_expiry).total_seconds())
        self.assertLess(time_diff, 5)  # Within 5 seconds


class OTPVerificationViewTest(APITestCase):
    """Test cases for OTP verification"""
    
    def setUp(self):
        self.client = APIClient()
        self.verify_url = reverse('verify-otp')
        self.user = AppUser.objects.create_user(
            email='test@example.com',
            password='testpass123',
            first_name='John',
            last_name='Doe',
            phone_number='+1234567890',
            role='buyer',
            email_verified=False
        )
        self.otp_code = "123456"
        self.otp = OTP.objects.create(user=self.user, otp=self.otp_code)
        
    def test_successful_otp_verification(self):
        """Test successful OTP verification"""
        data = {
            'email': 'test@example.com',
            'otp': self.otp_code
        }
        response = self.client.post(self.verify_url, data)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('verified successfully', response.data['message'])
        
        # Check that user is now verified
        self.user.refresh_from_db()
        self.assertTrue(self.user.email_verified)
        
        # Check that OTP is marked as verified
        self.otp.refresh_from_db()
        self.assertIsNotNone(self.otp.verified_at)
        
    def test_otp_verification_with_invalid_code(self):
        """Test OTP verification with invalid code"""
        data = {
            'email': 'test@example.com',
            'otp': '999999'
        }
        response = self.client.post(self.verify_url, data)
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        
    def test_otp_verification_with_invalid_email(self):
        """Test OTP verification with invalid email"""
        data = {
            'email': 'nonexistent@example.com',
            'otp': self.otp_code
        }
        response = self.client.post(self.verify_url, data)
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)


class ResendOTPViewTest(APITestCase):
    """Test cases for resending OTP"""
    
    def setUp(self):
        self.client = APIClient()
        self.resend_url = reverse('resend-otp')
        self.user = AppUser.objects.create_user(
            email='test@example.com',
            password='testpass123',
            first_name='John',
            last_name='Doe',
            phone_number='+1234567890',
            role='buyer'
        )
        
    def test_successful_otp_resend(self):
        """Test successful OTP resend"""
        # Create existing unverified OTP
        old_otp = OTP.objects.create(user=self.user, otp="123456")
        
        data = {'email': 'test@example.com'}
        response = self.client.post(self.resend_url, data)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('sent successfully', response.data['message'])
        
        # Check that old OTP was invalidated
        old_otp.refresh_from_db()
        self.assertIsNotNone(old_otp.verified_at)
        
        # Check that new OTP was created
        new_otps = OTP.objects.filter(user=self.user, verified_at__isnull=True)
        self.assertEqual(new_otps.count(), 1)
        
    def test_otp_resend_with_invalid_email(self):
        """Test OTP resend with invalid email"""
        data = {'email': 'nonexistent@example.com'}
        response = self.client.post(self.resend_url, data)
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)
