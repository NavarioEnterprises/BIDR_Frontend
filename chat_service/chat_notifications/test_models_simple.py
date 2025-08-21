"""
Simple test suite for chat_notifications app models
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
    NotificationTemplate,
    Notification,
    NotificationPreference,
    NotificationDevice,
    NotificationBatch
)


class NotificationTemplateTest(TestCase):
    """Test NotificationTemplate model functionality."""
    
    def setUp(self):
        """Set up test data."""
        self.user = User.objects.create_user(
            username='admin',
            email='admin@example.com',
            password='adminpass',
            is_staff=True
        )
    
    def test_create_notification_template(self):
        """Test creating notification template."""
        template = NotificationTemplate.objects.create(
            name='New Message Template',
            template_type='message_received',
            channel='push',
            title_template='New message from {{user_name}}',
            body_template='You have received a new message: {{message_preview}}',
            created_by=self.user
        )
        
        self.assertEqual(template.name, 'New Message Template')
        self.assertEqual(template.template_type, 'message_received')
        self.assertEqual(template.channel, 'push')
        self.assertTrue(template.is_enabled)


class NotificationTest(TestCase):
    """Test Notification model functionality."""
    
    def setUp(self):
        """Set up test data."""
        self.user1 = User.objects.create_user(
            username='user1',
            email='user1@example.com',
            password='testpass123'
        )
        self.user2 = User.objects.create_user(
            username='user2',
            email='user2@example.com',
            password='testpass123'
        )
        
        self.template = NotificationTemplate.objects.create(
            name='Test Template',
            template_type='message_received',
            channel='in_app',
            title_template='Test notification',
            body_template='Test body'
        )
    
    def test_create_notification(self):
        """Test creating a basic notification."""
        notification = Notification.objects.create(
            recipient=self.user2,
            template=self.template,
            title='New Message',
            body='You have a new message'
        )
        
        self.assertEqual(notification.recipient, self.user2)
        self.assertEqual(notification.template, self.template)
        self.assertEqual(notification.status, 'pending')
    
    def test_mark_notification_as_read(self):
        """Test marking notification as read."""
        notification = Notification.objects.create(
            recipient=self.user2,
            template=self.template,
            title='New Message',
            body='You have a new message'
        )
        
        # Mark as read
        notification.mark_as_read()
        
        notification.refresh_from_db()
        self.assertEqual(notification.status, 'read')
        self.assertIsNotNone(notification.read_at)


class NotificationPreferenceTest(TestCase):
    """Test NotificationPreference model functionality."""
    
    def setUp(self):
        """Set up test data."""
        self.user = User.objects.create_user(
            username='testuser',
            email='test@example.com',
            password='testpass123'
        )
    
    def test_create_notification_preference(self):
        """Test creating user notification preferences."""
        preference = NotificationPreference.objects.create(
            user=self.user,
            notifications_enabled=True,
            push_notifications=True,
            email_notifications=False
        )
        
        self.assertEqual(preference.user, self.user)
        self.assertTrue(preference.notifications_enabled)
        self.assertTrue(preference.push_notifications)
        self.assertFalse(preference.email_notifications)


class NotificationDeviceTest(TestCase):
    """Test NotificationDevice model functionality."""
    
    def setUp(self):
        """Set up test data."""
        self.user = User.objects.create_user(
            username='testuser',
            email='test@example.com',
            password='testpass123'
        )
    
    def test_create_notification_device(self):
        """Test creating notification device."""
        device = NotificationDevice.objects.create(
            user=self.user,
            device_type='ios',
            device_token='test_device_token_123',
            device_name='iPhone 12'
        )
        
        self.assertEqual(device.user, self.user)
        self.assertEqual(device.device_type, 'ios')
        self.assertEqual(device.device_token, 'test_device_token_123')
        self.assertTrue(device.is_active)


class NotificationBatchTest(TestCase):
    """Test NotificationBatch model functionality."""
    
    def setUp(self):
        """Set up test data."""
        self.user = User.objects.create_user(
            username='testuser',
            email='test@example.com',
            password='testpass123'
        )
        
        self.template = NotificationTemplate.objects.create(
            name='Batch Template',
            template_type='system_announcement',
            channel='push',
            title_template='System Update',
            body_template='System maintenance scheduled'
        )
    
    def test_create_notification_batch(self):
        """Test creating notification batch."""
        batch = NotificationBatch.objects.create(
            recipient=self.user,
            template=self.template,
            title='System Maintenance',
            summary='System will be down for maintenance',
            item_count=5
        )
        
        self.assertEqual(batch.recipient, self.user)
        self.assertEqual(batch.template, self.template)
        self.assertEqual(batch.item_count, 5)
        self.assertEqual(batch.status, 'pending')
