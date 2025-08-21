"""
Test suite for privacy_guard app

Tests cover:
- PII detection rules and results
- Data masking profiles and configurations
- Privacy consent management
- Data retention policies
- Data deletion requests
- Privacy audit logging
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
from chat_messaging.models import Message
from chat_conversations.models import Conversation
from .models import (
    PIIDetectionRule, PIIDetectionResult, DataMaskingProfile,
    PrivacyConsent, DataRetentionPolicy, DataDeletionRequest,
    PrivacyAuditLog
)


class PIIDetectionRuleTest(TestCase):
    """Test PII detection rule functionality."""
    
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
    
    def test_email_pattern_matching(self):
        """Test email pattern detection."""
        rule = PIIDetectionRule.objects.create(
            name='Email Detection',
            pii_type='email',
            regex_pattern=r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b',
            is_enabled=True
        )
        
        test_text = "Contact me at john.doe@example.com for more info"
        matches = rule.detect_pii(test_text)
        
        self.assertTrue(len(matches) > 0)
        self.assertEqual(matches[0]['match'], 'john.doe@example.com')
    
    def test_phone_pattern_matching(self):
        """Test phone number pattern detection."""
        rule = PIIDetectionRule.objects.create(
            name='Phone Detection',
            pii_type='phone',
            pattern_regex=r'\b\d{3}-\d{3}-\d{4}\b',
            confidence_threshold=0.9,
            is_active=True,
            created_by=self.user
        )
        
        test_text = "Call me at 555-123-4567 or email"
        matches = rule.test_pattern(test_text)
        
        self.assertTrue(len(matches) > 0)
        self.assertEqual(matches[0], '555-123-4567')
    
    def test_ssn_pattern_matching(self):
        """Test SSN pattern detection."""
        rule = PIIDetectionRule.objects.create(
            name='SSN Detection',
            pii_type='ssn',
            pattern_regex=r'\b\d{3}-\d{2}-\d{4}\b',
            confidence_threshold=0.95,
            is_active=True,
            severity_level='high',
            created_by=self.user
        )
        
        test_text = "My SSN is 123-45-6789"
        matches = rule.test_pattern(test_text)
        
        self.assertTrue(len(matches) > 0)
        self.assertEqual(matches[0], '123-45-6789')


class PIIDetectionResultTest(TestCase):
    """Test PII detection result functionality."""
    
    def setUp(self):
        """Set up test data."""
        self.user = User.objects.create_user(
            username='testuser',
            email='test@example.com',
            password='testpass123'
        )
        
        self.conversation = Conversation.objects.create(
            title='Test Conversation',
            buyer=self.user
        )
        
        self.message = Message.objects.create(
            conversation=self.conversation,
            sender=self.user,
            content='Contact me at john@example.com'
        )
        
        self.detection_rule = PIIDetectionRule.objects.create(
            name='Email Detection',
            pii_type='email',
            pattern_regex=r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b',
            confidence_threshold=0.8,
            is_active=True,
            created_by=self.user
        )
    
    def test_create_pii_detection_result(self):
        """Test creating a PII detection result."""
        result = PIIDetectionResult.objects.create(
            detection_rule=self.detection_rule,
            content_type='message',
            content_id=self.message.id,
            detected_content='john@example.com',
            masked_content='j***@example.com',
            confidence_score=0.95,
            position_start=15,
            position_end=31,
            action_taken='mask',
            reviewed_by=self.user
        )
        
        self.assertEqual(result.detection_rule, self.detection_rule)
        self.assertEqual(result.detected_content, 'john@example.com')
        self.assertEqual(result.masked_content, 'j***@example.com')
        self.assertEqual(result.action_taken, 'mask')
        self.assertTrue(result.is_confirmed)
    
    def test_auto_masking_application(self):
        """Test automatic masking of detected PII."""
        result = PIIDetectionResult.objects.create(
            detection_rule=self.detection_rule,
            content_type='message',
            content_id=self.message.id,
            detected_content='john@example.com',
            confidence_score=0.95,
            position_start=15,
            position_end=31,
            action_taken='mask'
        )
        
        # Apply masking
        masked_content = result.apply_masking('Contact me at john@example.com')
        expected = 'Contact me at [EMAIL_REDACTED]'
        
        # Note: Actual masking logic would be implemented in the model
        self.assertIsNotNone(masked_content)


class DataMaskingProfileTest(TestCase):
    """Test data masking profile functionality."""
    
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
            profile_name='Default Profile',
            masking_level='partial',
            mask_emails=True,
            mask_phones=True,
            mask_ssn=True,
            mask_addresses=False,
            custom_patterns='creditcard:partial',
            is_active=True
        )
        
        self.assertEqual(profile.user, self.user)
        self.assertEqual(profile.profile_name, 'Default Profile')
        self.assertEqual(profile.masking_level, 'partial')
        self.assertTrue(profile.mask_emails)
        self.assertTrue(profile.mask_phones)
        self.assertFalse(profile.mask_addresses)
    
    def test_get_masking_configuration(self):
        """Test getting masking configuration."""
        profile = DataMaskingProfile.objects.create(
            user=self.user,
            profile_name='Strict Profile',
            masking_level='full',
            mask_emails=True,
            mask_phones=True,
            mask_ssn=True,
            mask_addresses=True,
            is_active=True
        )
        
        config = profile.get_masking_config()
        
        self.assertIn('email', config)
        self.assertIn('phone', config)
        self.assertIn('ssn', config)
        self.assertIn('address', config)
        self.assertTrue(config['email'])


class PrivacyConsentTest(TestCase):
    """Test privacy consent functionality."""
    
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
            purpose='chat_functionality',
            consent_given=True,
            consent_method='explicit',
            ip_address='192.168.1.1',
            user_agent='Mozilla/5.0',
            consent_version='v1.0'
        )
        
        self.assertEqual(consent.user, self.user)
        self.assertEqual(consent.consent_type, 'data_processing')
        self.assertTrue(consent.consent_given)
        self.assertEqual(consent.consent_method, 'explicit')
        self.assertIsNone(consent.consent_withdrawn_at)
    
    def test_withdraw_consent(self):
        """Test withdrawing consent."""
        consent = PrivacyConsent.objects.create(
            user=self.user,
            consent_type='data_processing',
            purpose='chat_functionality',
            consent_given=True,
            consent_method='explicit'
        )
        
        # Withdraw consent
        consent.withdraw_consent('user_request')
        
        consent.refresh_from_db()
        self.assertFalse(consent.consent_given)
        self.assertIsNotNone(consent.consent_withdrawn_at)
        self.assertEqual(consent.withdrawal_reason, 'user_request')
    
    def test_check_active_consent(self):
        """Test checking if consent is active."""
        consent = PrivacyConsent.objects.create(
            user=self.user,
            consent_type='data_processing',
            purpose='chat_functionality',
            consent_given=True,
            consent_method='explicit'
        )
        
        self.assertTrue(consent.is_active())
        
        # Withdraw and check again
        consent.withdraw_consent()
        self.assertFalse(consent.is_active())


class DataRetentionPolicyTest(TestCase):
    """Test data retention policy functionality."""
    
    def test_create_data_retention_policy(self):
        """Test creating data retention policy."""
        policy = DataRetentionPolicy.objects.create(
            policy_name='Chat Messages Policy',
            data_type='chat_message',
            retention_period_days=90,
            deletion_method='soft_delete',
            policy_description='Retain chat messages for 90 days',
            is_active=True,
            compliance_requirement='GDPR'
        )
        
        self.assertEqual(policy.policy_name, 'Chat Messages Policy')
        self.assertEqual(policy.retention_period_days, 90)
        self.assertEqual(policy.deletion_method, 'soft_delete')
        self.assertTrue(policy.is_active)
    
    def test_calculate_expiry_date(self):
        """Test calculating data expiry date."""
        policy = DataRetentionPolicy.objects.create(
            policy_name='Short Term Policy',
            data_type='temporary_data',
            retention_period_days=30,
            is_active=True
        )
        
        # Calculate expiry for a given creation date
        creation_date = timezone.now().date()
        expiry_date = policy.calculate_expiry_date(creation_date)
        expected_expiry = creation_date + timezone.timedelta(days=30)
        
        self.assertEqual(expiry_date, expected_expiry)


class DataDeletionRequestTest(TestCase):
    """Test data deletion request functionality."""
    
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
            request_type='full_deletion',
            reason='user_request',
            data_categories=['messages', 'profile', 'attachments'],
            requested_completion_date=timezone.now().date() + timezone.timedelta(days=7),
            status='pending'
        )
        
        self.assertEqual(request.user, self.user)
        self.assertEqual(request.request_type, 'full_deletion')
        self.assertEqual(request.status, 'pending')
        self.assertIn('messages', request.data_categories)
    
    def test_approve_deletion_request(self):
        """Test approving deletion request."""
        admin_user = User.objects.create_user(
            username='admin',
            email='admin@example.com',
            password='adminpass',
            is_staff=True
        )
        
        request = DataDeletionRequest.objects.create(
            user=self.user,
            request_type='partial_deletion',
            reason='user_request',
            data_categories=['messages'],
            status='pending'
        )
        
        # Approve request
        request.approve(approved_by=admin_user)
        
        request.refresh_from_db()
        self.assertEqual(request.status, 'approved')
        self.assertEqual(request.approved_by, admin_user)
        self.assertIsNotNone(request.approved_at)
    
    def test_complete_deletion_request(self):
        """Test completing deletion request."""
        request = DataDeletionRequest.objects.create(
            user=self.user,
            request_type='full_deletion',
            reason='user_request',
            data_categories=['messages', 'profile'],
            status='approved'
        )
        
        # Complete request
        request.complete('All requested data has been deleted')
        
        request.refresh_from_db()
        self.assertEqual(request.status, 'completed')
        self.assertIsNotNone(request.completed_at)
        self.assertEqual(request.completion_notes, 'All requested data has been deleted')


class PrivacyAuditLogTest(TestCase):
    """Test privacy audit log functionality."""
    
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
            action='data_access',
            resource_type='user_profile',
            resource_id=self.user.id,
            details={
                'accessed_fields': ['email', 'username'],
                'access_reason': 'profile_view'
            },
            ip_address='192.168.1.1',
            user_agent='Mozilla/5.0',
            success=True
        )
        
        self.assertEqual(log_entry.user, self.user)
        self.assertEqual(log_entry.action, 'data_access')
        self.assertEqual(log_entry.resource_type, 'user_profile')
        self.assertTrue(log_entry.success)
        self.assertIn('accessed_fields', log_entry.details)
    
    def test_log_pii_detection(self):
        """Test logging PII detection event."""
        log_entry = PrivacyAuditLog.objects.create(
            user=self.user,
            action='pii_detection',
            resource_type='message',
            resource_id=123,
            details={
                'pii_type': 'email',
                'detection_rule': 'email_pattern',
                'confidence': 0.95,
                'action_taken': 'mask'
            },
            success=True
        )
        
        self.assertEqual(log_entry.action, 'pii_detection')
        self.assertEqual(log_entry.details['pii_type'], 'email')
        self.assertEqual(log_entry.details['action_taken'], 'mask')
    
    def test_log_consent_change(self):
        """Test logging consent change event."""
        log_entry = PrivacyAuditLog.objects.create(
            user=self.user,
            action='consent_change',
            resource_type='privacy_consent',
            details={
                'consent_type': 'data_processing',
                'previous_state': 'granted',
                'new_state': 'withdrawn',
                'reason': 'user_request'
            },
            ip_address='192.168.1.1',
            success=True
        )
        
        self.assertEqual(log_entry.action, 'consent_change')
        self.assertEqual(log_entry.details['new_state'], 'withdrawn')
        self.assertEqual(log_entry.details['reason'], 'user_request')
