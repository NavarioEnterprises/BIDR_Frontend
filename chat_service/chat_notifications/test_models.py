"""
Test suite for chat_notifications app

Tests cover:
- Notification creation and management
- Notification templates and configurations
- User notification preferences
- Delivery tracking and status updates
- Bulk notification operations
"""

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
        
        self.conversation = Conversation.objects.create(
            title='Test Conversation',
            buyer=self.user1
        )
        
        self.message = Message.objects.create(
            conversation=self.conversation,
            sender=self.user1,
            content='Test message for notification'
        )
    
    def test_create_notification(self):
        """Test creating a basic notification."""
        notification = Notification.objects.create(
            recipient=self.user2,
            notification_type='new_message',
            title='New Message',
            message='You have a new message',
            priority='medium',
            sender=self.user1,
            related_object_type='message',
            related_object_id=self.message.id
        )
        
        self.assertEqual(notification.recipient, self.user2)
        self.assertEqual(notification.notification_type, 'new_message')
        self.assertEqual(notification.priority, 'medium')
        self.assertFalse(notification.is_read)
        self.assertIsNone(notification.read_at)
    
    def test_mark_notification_as_read(self):
        """Test marking notification as read."""
        notification = Notification.objects.create(
            recipient=self.user2,
            notification_type='new_message',
            title='New Message',
            message='You have a new message',
            sender=self.user1
        )
        
        # Mark as read
        notification.mark_as_read()
        
        notification.refresh_from_db()
        self.assertTrue(notification.is_read)
        self.assertIsNotNone(notification.read_at)
    
    def test_notification_expiry(self):
        """Test notification expiry functionality."""
        past_time = timezone.now() - timezone.timedelta(days=1)
        notification = Notification.objects.create(
            recipient=self.user2,
            notification_type='reminder',
            title='Expired Notification',
            message='This should be expired',
            expires_at=past_time
        )
        
        self.assertTrue(notification.is_expired())
    
    def test_get_related_object(self):
        """Test getting related object from notification."""
        notification = Notification.objects.create(
            recipient=self.user2,
            notification_type='new_message',
            title='New Message',
            message='You have a new message',
            related_object_type='message',
            related_object_id=self.message.id
        )
        
        related_obj = notification.get_related_object()
        self.assertEqual(related_obj, self.message)


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
            template_type='new_message',
            title_template='New message from {sender_name}',
            message_template='You have received a new message: {message_preview}',
            email_subject_template='BIDR: New message from {sender_name}',
            email_body_template='Hello {recipient_name}, you have a new message...',
            push_title_template='{sender_name} sent you a message',
            push_body_template='{message_preview}',
            is_active=True,
            created_by=self.user
        )
        
        self.assertEqual(template.name, 'New Message Template')
        self.assertEqual(template.template_type, 'new_message')
        self.assertTrue(template.is_active)
    
    def test_render_notification_content(self):
        """Test rendering notification content with variables."""
        template = NotificationTemplate.objects.create(
            name='Message Template',
            template_type='new_message',
            title_template='New message from {sender_name}',
            message_template='Message: {message_content}',
            is_active=True,
            created_by=self.user
        )
        
        variables = {
            'sender_name': 'John Doe',
            'message_content': 'Hello there!'
        }
        
        rendered = template.render_notification(variables)
        
        self.assertEqual(rendered['title'], 'New message from John Doe')
        self.assertEqual(rendered['message'], 'Message: Hello there!')
    
    def test_template_variable_validation(self):
        """Test template variable validation."""
        template = NotificationTemplate.objects.create(
            name='Test Template',
            template_type='test',
            title_template='Hello {name}',
            message_template='Your score is {score}',
            required_variables=['name', 'score'],
            is_active=True,
            created_by=self.user
        )
        
        # Valid variables
        valid_vars = {'name': 'John', 'score': '100'}
        self.assertTrue(template.validate_variables(valid_vars))
        
        # Missing required variable
        invalid_vars = {'name': 'John'}
        self.assertFalse(template.validate_variables(invalid_vars))


class UserNotificationPreferenceTest(TestCase):
    """Test UserNotificationPreference model functionality."""
    
    def setUp(self):
        """Set up test data."""
        self.user = User.objects.create_user(
            username='testuser',
            email='test@example.com',
            password='testpass123'
        )
    
    def test_create_notification_preference(self):
        """Test creating user notification preferences."""
        preference = UserNotificationPreference.objects.create(
            user=self.user,
            notification_type='new_message',
            email_enabled=True,
            push_enabled=True,
            in_app_enabled=True,
            sms_enabled=False,
            frequency='immediate',
            quiet_hours_start='22:00',
            quiet_hours_end='08:00'
        )
        
        self.assertEqual(preference.user, self.user)
        self.assertEqual(preference.notification_type, 'new_message')
        self.assertTrue(preference.email_enabled)
        self.assertFalse(preference.sms_enabled)
    
    def test_check_delivery_method_enabled(self):
        """Test checking if delivery method is enabled."""
        preference = UserNotificationPreference.objects.create(
            user=self.user,
            notification_type='new_message',
            email_enabled=True,
            push_enabled=False,
            in_app_enabled=True
        )
        
        self.assertTrue(preference.is_delivery_enabled('email'))
        self.assertFalse(preference.is_delivery_enabled('push'))
        self.assertTrue(preference.is_delivery_enabled('in_app'))
    
    def test_quiet_hours_check(self):
        """Test quiet hours functionality."""
        preference = UserNotificationPreference.objects.create(
            user=self.user,
            notification_type='new_message',
            quiet_hours_enabled=True,
            quiet_hours_start='22:00',
            quiet_hours_end='08:00'
        )
        
        # Test time during quiet hours (11 PM)
        quiet_time = timezone.now().replace(hour=23, minute=0, second=0)
        self.assertTrue(preference.is_in_quiet_hours(quiet_time))
        
        # Test time outside quiet hours (2 PM)
        active_time = timezone.now().replace(hour=14, minute=0, second=0)
        self.assertFalse(preference.is_in_quiet_hours(active_time))
    
    def test_get_user_preferences(self):
        """Test getting all preferences for a user."""
        # Create multiple preferences
        UserNotificationPreference.objects.create(
            user=self.user,
            notification_type='new_message',
            email_enabled=True
        )
        UserNotificationPreference.objects.create(
            user=self.user,
            notification_type='mention',
            push_enabled=True
        )
        
        preferences = UserNotificationPreference.get_user_preferences(self.user)
        
        self.assertEqual(len(preferences), 2)
        pref_types = [p.notification_type for p in preferences]
        self.assertIn('new_message', pref_types)
        self.assertIn('mention', pref_types)


class NotificationDeliveryTest(TestCase):
    """Test NotificationDelivery model functionality."""
    
    def setUp(self):
        """Set up test data."""
        self.user = User.objects.create_user(
            username='testuser',
            email='test@example.com',
            password='testpass123'
        )
        
        self.notification = Notification.objects.create(
            recipient=self.user,
            notification_type='new_message',
            title='Test Notification',
            message='Test message'
        )
    
    def test_create_notification_delivery(self):
        """Test creating notification delivery record."""
        delivery = NotificationDelivery.objects.create(
            notification=self.notification,
            delivery_method='email',
            recipient_address='test@example.com',
            status='pending'
        )
        
        self.assertEqual(delivery.notification, self.notification)
        self.assertEqual(delivery.delivery_method, 'email')
        self.assertEqual(delivery.status, 'pending')
        self.assertIsNone(delivery.delivered_at)
    
    def test_mark_delivery_as_sent(self):
        """Test marking delivery as sent."""
        delivery = NotificationDelivery.objects.create(
            notification=self.notification,
            delivery_method='email',
            recipient_address='test@example.com',
            status='pending'
        )
        
        # Mark as sent
        delivery.mark_as_sent()
        
        delivery.refresh_from_db()
        self.assertEqual(delivery.status, 'sent')
        self.assertIsNotNone(delivery.delivered_at)
    
    def test_mark_delivery_as_failed(self):
        """Test marking delivery as failed."""
        delivery = NotificationDelivery.objects.create(
            notification=self.notification,
            delivery_method='email',
            recipient_address='invalid@email',
            status='pending'
        )
        
        # Mark as failed
        delivery.mark_as_failed('Invalid email address')
        
        delivery.refresh_from_db()
        self.assertEqual(delivery.status, 'failed')
        self.assertEqual(delivery.error_message, 'Invalid email address')
        self.assertIsNotNone(delivery.attempted_at)
    
    def test_retry_failed_delivery(self):
        """Test retrying failed delivery."""
        delivery = NotificationDelivery.objects.create(
            notification=self.notification,
            delivery_method='email',
            recipient_address='test@example.com',
            status='failed',
            retry_count=1
        )
        
        # Retry delivery
        delivery.retry()
        
        delivery.refresh_from_db()
        self.assertEqual(delivery.status, 'pending')
        self.assertEqual(delivery.retry_count, 2)
        self.assertIsNotNone(delivery.last_retry_at)


class BulkNotificationTest(TestCase):
    """Test BulkNotification model functionality."""
    
    def setUp(self):
        """Set up test data."""
        self.admin_user = User.objects.create_user(
            username='admin',
            email='admin@example.com',
            password='adminpass',
            is_staff=True
        )
        
        self.users = []
        for i in range(3):
            user = User.objects.create_user(
                username=f'user{i}',
                email=f'user{i}@example.com',
                password='testpass'
            )
            self.users.append(user)
    
    def test_create_bulk_notification(self):
        """Test creating bulk notification."""
        bulk_notification = BulkNotification.objects.create(
            title='System Maintenance',
            message='System will be down for maintenance',
            notification_type='announcement',
            target_audience='all_users',
            priority='high',
            scheduled_for=timezone.now() + timezone.timedelta(hours=1),
            created_by=self.admin_user
        )
        
        self.assertEqual(bulk_notification.title, 'System Maintenance')
        self.assertEqual(bulk_notification.target_audience, 'all_users')
        self.assertEqual(bulk_notification.status, 'draft')
        self.assertEqual(bulk_notification.total_recipients, 0)
    
    def test_calculate_recipient_count(self):
        """Test calculating recipient count."""
        bulk_notification = BulkNotification.objects.create(
            title='Test Bulk',
            message='Test message',
            notification_type='announcement',
            target_audience='all_users',
            created_by=self.admin_user
        )
        
        # Calculate recipients (this would normally be done by a method)
        recipient_count = User.objects.filter(is_active=True).count()
        bulk_notification.total_recipients = recipient_count
        bulk_notification.save()
        
        # Should include all active users (3 test users + admin)
        self.assertEqual(bulk_notification.total_recipients, 4)
    
    def test_start_bulk_notification_sending(self):
        """Test starting bulk notification sending process."""
        bulk_notification = BulkNotification.objects.create(
            title='Test Bulk',
            message='Test message',
            notification_type='announcement',
            target_audience='all_users',
            status='scheduled',
            created_by=self.admin_user
        )
        
        # Start sending
        bulk_notification.start_sending()
        
        bulk_notification.refresh_from_db()
        self.assertEqual(bulk_notification.status, 'sending')
        self.assertIsNotNone(bulk_notification.started_sending_at)
    
    def test_complete_bulk_notification(self):
        """Test completing bulk notification."""
        bulk_notification = BulkNotification.objects.create(
            title='Test Bulk',
            message='Test message',
            notification_type='announcement',
            target_audience='all_users',
            status='sending',
            total_recipients=10,
            created_by=self.admin_user
        )
        
        # Complete sending
        bulk_notification.complete_sending(
            successful_count=8,
            failed_count=2
        )
        
        bulk_notification.refresh_from_db()
        self.assertEqual(bulk_notification.status, 'completed')
        self.assertEqual(bulk_notification.successful_sends, 8)
        self.assertEqual(bulk_notification.failed_sends, 2)
        self.assertIsNotNone(bulk_notification.completed_at)
    
    def test_cancel_bulk_notification(self):
        """Test canceling bulk notification."""
        bulk_notification = BulkNotification.objects.create(
            title='Test Bulk',
            message='Test message',
            notification_type='announcement',
            target_audience='all_users',
            status='scheduled',
            created_by=self.admin_user
        )
        
        # Cancel notification
        bulk_notification.cancel('Admin decision')
        
        bulk_notification.refresh_from_db()
        self.assertEqual(bulk_notification.status, 'cancelled')
        self.assertEqual(bulk_notification.cancellation_reason, 'Admin decision')
        self.assertIsNotNone(bulk_notification.cancelled_at)
