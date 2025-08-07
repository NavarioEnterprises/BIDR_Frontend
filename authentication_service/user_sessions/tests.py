"""
Tests for the user_sessions app
"""
from datetime import timedelta
from django.test import TestCase
from django.urls import reverse
from django.utils import timezone
from rest_framework import status
from rest_framework.test import APITestCase, APIClient

from user.models import AppUser
from .models import UserSession


class UserSessionModelTest(TestCase):
    """Test cases for UserSession model"""
    
    def setUp(self):
        self.user = AppUser.objects.create_user(
            email='test@example.com',
            password='testpass123',
            first_name='John',
            last_name='Doe',
            phone_number='+1234567890',
            role='buyer'
        )
        
    def test_create_user_session(self):
        """Test creating a new user session"""
        session = UserSession.objects.create(
            user=self.user,
            session_key='test_session_key',
            ip_address='192.168.1.1',
            user_agent='Mozilla/5.0 Test Browser',
            device_type='desktop',
            operating_system='windows',
            expires_at=timezone.now() + timedelta(hours=24)
        )
        self.assertEqual(session.user, self.user)
        self.assertEqual(session.session_key, 'test_session_key')
        self.assertTrue(session.is_active())
        self.assertIsNone(session.terminated_at)
        
    def test_session_str_method(self):
        """Test session string representation"""
        session = UserSession.objects.create(
            user=self.user,
            session_key='test_session_key',
            ip_address='192.168.1.1',
            device_type='desktop',
            expires_at=timezone.now() + timedelta(hours=24)
        )
        expected_str = f"{self.user.email} - desktop (192.168.1.1)"
        self.assertEqual(str(session), expected_str)
        
    def test_session_is_expired_false(self):
        """Test session is not expired"""
        session = UserSession.objects.create(
            user=self.user,
            session_key='test_session_key',
            ip_address='192.168.1.1',
            expires_at=timezone.now() + timedelta(hours=24)
        )
        self.assertFalse(session.is_expired())
        
    def test_session_is_expired_true(self):
        """Test session is expired"""
        past_time = timezone.now() - timedelta(hours=1)
        session = UserSession.objects.create(
            user=self.user,
            session_key='test_session_key',
            ip_address='192.168.1.1',
            expires_at=past_time
        )
        self.assertTrue(session.is_expired())
        
    def test_terminate_session(self):
        """Test terminating a session"""
        session = UserSession.objects.create(
            user=self.user,
            session_key='test_session_key',
            ip_address='192.168.1.1',
            expires_at=timezone.now() + timedelta(hours=24)
        )
        session.terminate('Manual termination')
        
        self.assertEqual(session.status, 'terminated')
        self.assertIsNotNone(session.terminated_at)
        
    def test_get_active_sessions_for_user(self):
        """Test getting active sessions for a user"""
        active_session = UserSession.objects.create(
            user=self.user,
            session_key='active_session',
            ip_address='192.168.1.1',
            expires_at=timezone.now() + timedelta(hours=24),
            status='active'
        )
        
        inactive_session = UserSession.objects.create(
            user=self.user,
            session_key='inactive_session',
            ip_address='192.168.1.2',
            expires_at=timezone.now() + timedelta(hours=24),
            status='terminated'
        )
        
        active_sessions = UserSession.objects.filter(user=self.user, status='active')
        self.assertIn(active_session, active_sessions)
        self.assertNotIn(inactive_session, active_sessions)
