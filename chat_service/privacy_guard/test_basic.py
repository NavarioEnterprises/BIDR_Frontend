"""
Basic test suite for privacy_guard app with only actual model fields

Tests cover:
- Basic model creation and functionality
"""

# Set up Django environment if not already configured
import os
import django
from django.conf import settings

if not settings.configured:
    os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'chat_service.settings')
    django.setup()

from django.test import TestCase
from django.contrib.auth.models import User
from django.utils import timezone
from .models import (
    PIIDetectionRule, PIIDetectionResult, DataMaskingProfile,
    PrivacyConsent, DataRetentionPolicy, DataDeletionRequest,
    PrivacyAuditLog
)


class BasicPIIDetectionRuleTest(TestCase):
    """Test basic PII detection rule functionality."""
    
    def setUp(self):
        """Set up test data."""
        self.user = User.objects.create_user(
            username='testuser',
            email='test@example.com',
            password='testpass123'
        )
    
    def test_create_pii_detection_rule(self):
        """Test creating a PII detection rule."""
        rule = PIIDetectionRule.objects.create(
            name='Email Detection',
            pii_type='email',
            regex_pattern=r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b',
            is_enabled=True,
            sensitivity_level='medium'
        )
        
        self.assertEqual(rule.name, 'Email Detection')
        self.assertEqual(rule.pii_type, 'email')
        self.assertEqual(rule.sensitivity_level, 'medium')
        self.assertTrue(rule.is_enabled)
        self.assertEqual(rule.detection_count, 0)


class BasicDataMaskingProfileTest(TestCase):
    """Test basic data masking profile functionality."""
    
    def setUp(self):
        """Set up test data."""
        self.user = User.objects.create_user(
            username='testuser',
            email='test@example.com',
            password='testpass123'
        )
    
    def test_create_data_masking_profile(self):
        """Test creating a data masking profile."""
        profile = DataMaskingProfile.objects.create(
            user=self.user,
            auto_masking_enabled=True,
            mask_email=True,
            mask_phone=True,
            mask_ssn=True,
            mask_address=False
        )
        
        self.assertEqual(profile.user, self.user)
        self.assertTrue(profile.auto_masking_enabled)
        self.assertTrue(profile.mask_email)
        self.assertTrue(profile.mask_phone)
        self.assertFalse(profile.mask_address)


class BasicPrivacyConsentTest(TestCase):
    """Test basic privacy consent functionality."""
    
    def setUp(self):
        """Set up test data."""
        self.user = User.objects.create_user(
            username='testuser',
            email='test@example.com',
            password='testpass123'
        )
    
    def test_create_privacy_consent(self):
        """Test creating privacy consent record."""
        consent = PrivacyConsent.objects.create(
            user=self.user,
            consent_type='data_processing',
            is_granted=True,
            consent_text='User agrees to data processing',
            version='v1.0'
        )
        
        self.assertEqual(consent.user, self.user)
        self.assertEqual(consent.consent_type, 'data_processing')
        self.assertTrue(consent.is_granted)
        self.assertEqual(consent.version, 'v1.0')


class BasicDataRetentionPolicyTest(TestCase):
    """Test basic data retention policy functionality."""
    
    def test_create_data_retention_policy(self):
        """Test creating data retention policy."""
        policy = DataRetentionPolicy.objects.create(
            name='Chat Messages Policy',
            data_type='messages',
            retention_period_days=90,
            description='Retain chat messages for 90 days'
        )
        
        self.assertEqual(policy.name, 'Chat Messages Policy')
        self.assertEqual(policy.data_type, 'messages')
        self.assertEqual(policy.retention_period_days, 90)


class BasicDataDeletionRequestTest(TestCase):
    """Test basic data deletion request functionality."""
    
    def setUp(self):
        """Set up test data."""
        self.user = User.objects.create_user(
            username='testuser',
            email='test@example.com',
            password='testpass123'
        )
    
    def test_create_data_deletion_request(self):
        """Test creating data deletion request."""
        request = DataDeletionRequest.objects.create(
            user=self.user,
            request_type='full_account',
            status='submitted',
            reason='User wants to delete account',
            data_types=['messages', 'profile']
        )
        
        self.assertEqual(request.user, self.user)
        self.assertEqual(request.request_type, 'full_account')
        self.assertEqual(request.status, 'submitted')
        self.assertIn('messages', request.data_types)


class BasicPrivacyAuditLogTest(TestCase):
    """Test basic privacy audit log functionality."""
    
    def setUp(self):
        """Set up test data."""
        self.user = User.objects.create_user(
            username='testuser',
            email='test@example.com',
            password='testpass123'
        )
    
    def test_create_privacy_audit_log(self):
        """Test creating privacy audit log entry."""
        log_entry = PrivacyAuditLog.objects.create(
            user=self.user,
            action_type='pii_detected',
            description='Email address detected in message',
            data_types_involved=['email']
        )
        
        self.assertEqual(log_entry.user, self.user)
        self.assertEqual(log_entry.action_type, 'pii_detected')
        self.assertIn('email', log_entry.data_types_involved)
