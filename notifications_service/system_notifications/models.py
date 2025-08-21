import uuid
from django.db import models
from django.contrib.auth.models import User
from django.contrib.contenttypes.models import ContentType
from django.contrib.contenttypes.fields import GenericForeignKey
from django.utils import timezone
from datetime import timedelta


class NotificationTemplate(models.Model):
    """Templates for different types of notifications"""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=100, unique=True)
    notification_type = models.CharField(max_length=50, choices=[
        # Payment notifications
        ('payment_success', 'Payment Successful'),
        ('payment_failed', 'Payment Failed'),
        ('payment_pending', 'Payment Pending'),
        ('refund_processed', 'Refund Processed'),
        ('escrow_released', 'Escrow Released'),
        
        # Review notifications
        ('review_received', 'Review Received'),
        ('review_response', 'Review Response'),
        ('review_flagged', 'Review Flagged'),
        
        # Return notifications
        ('return_request_received', 'Return Request Received'),
        ('return_approved', 'Return Approved'),
        ('return_rejected', 'Return Rejected'),
        ('return_shipped', 'Return Shipped'),
        ('return_received', 'Return Received'),
        ('return_completed', 'Return Completed'),
        
        # Dispute notifications
        ('dispute_created', 'Dispute Created'),
        ('dispute_message', 'Dispute Message'),
        ('dispute_escalated', 'Dispute Escalated'),
        ('dispute_resolved', 'Dispute Resolved'),
        ('resolution_offer', 'Resolution Offer'),
        ('mediation_scheduled', 'Mediation Scheduled'),
        
        # System notifications
        ('system_maintenance', 'System Maintenance'),
        ('policy_update', 'Policy Update'),
        ('account_update', 'Account Update'),
        ('security_alert', 'Security Alert'),
        
        # Chat notifications
        ('new_message', 'New Message'),
        ('message_read', 'Message Read'),
        ('chat_archived', 'Chat Archived'),
        
        # Authentication notifications
        ('login_success', 'Login Successful'),
        ('login_failed', 'Login Failed'),
        ('password_changed', 'Password Changed'),
        ('account_locked', 'Account Locked'),
        
        # General
        ('custom', 'Custom Notification'),
    ])
    
    # Template content
    subject_template = models.CharField(max_length=200)
    body_template = models.TextField()
    html_template = models.TextField(blank=True)
    
    # Delivery channels
    send_email = models.BooleanField(default=True)
    send_sms = models.BooleanField(default=False)
    send_push = models.BooleanField(default=True)
    send_in_app = models.BooleanField(default=True)
    
    # Settings
    is_active = models.BooleanField(default=True)
    priority = models.CharField(max_length=10, choices=[
        ('low', 'Low'),
        ('normal', 'Normal'),
        ('high', 'High'),
        ('urgent', 'Urgent')
    ], default='normal')
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['name']
        indexes = [
            models.Index(fields=['notification_type']),
            models.Index(fields=['is_active']),
        ]
    
    def __str__(self):
        return f"{self.name} - {self.notification_type}"


class Notification(models.Model):
    """Individual notifications sent to users"""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    recipient_id = models.UUIDField(help_text="User ID from external service")
    template = models.ForeignKey(NotificationTemplate, on_delete=models.CASCADE, null=True, blank=True)
    
    # Notification content
    notification_type = models.CharField(max_length=50)
    subject = models.CharField(max_length=200)
    message = models.TextField()
    html_content = models.TextField(blank=True)
    
    # Related object (generic foreign key)
    content_type = models.ForeignKey(ContentType, on_delete=models.CASCADE, null=True, blank=True)
    object_id = models.PositiveIntegerField(null=True, blank=True)
    content_object = GenericForeignKey('content_type', 'object_id')
    
    # Delivery status
    is_read = models.BooleanField(default=False)
    is_sent = models.BooleanField(default=False)
    sent_at = models.DateTimeField(null=True, blank=True)
    read_at = models.DateTimeField(null=True, blank=True)
    
    # Delivery channels attempted
    email_sent = models.BooleanField(default=False)
    sms_sent = models.BooleanField(default=False)
    push_sent = models.BooleanField(default=False)
    in_app_sent = models.BooleanField(default=False)
    
    # Delivery channel status
    email_status = models.CharField(max_length=20, blank=True)
    sms_status = models.CharField(max_length=20, blank=True)
    push_status = models.CharField(max_length=20, blank=True)
    
    # Priority and metadata
    priority = models.CharField(max_length=10, choices=[
        ('low', 'Low'),
        ('normal', 'Normal'),
        ('high', 'High'),
        ('urgent', 'Urgent')
    ], default='normal')
    
    # Additional data (JSON for template variables)
    data = models.JSONField(default=dict, blank=True)
    
    # Service origin
    source_service = models.CharField(max_length=50, choices=[
        ('payment_service', 'Payment Service'),
        ('resolution_service', 'Resolution Service'),
        ('chat_service', 'Chat Service'),
        ('auth_service', 'Authentication Service'),
        ('product_service', 'Product Service'),
        ('notification_service', 'Notification Service'),
    ], blank=True)
    
    # Retry information
    retry_count = models.PositiveIntegerField(default=0)
    max_retries = models.PositiveIntegerField(default=3)
    next_retry_at = models.DateTimeField(null=True, blank=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['recipient_id', '-created_at']),
            models.Index(fields=['notification_type']),
            models.Index(fields=['is_read']),
            models.Index(fields=['priority']),
            models.Index(fields=['source_service']),
        ]
    
    def __str__(self):
        return f"Notification to {self.recipient_id}: {self.subject}"


class NotificationPreference(models.Model):
    """User preferences for notifications"""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user_id = models.UUIDField(unique=True, help_text="User ID from external service")
    
    # Global settings
    email_enabled = models.BooleanField(default=True)
    sms_enabled = models.BooleanField(default=False)
    push_enabled = models.BooleanField(default=True)
    in_app_enabled = models.BooleanField(default=True)
    
    # Notification type preferences (JSON)
    # Example: {'review_received': {'email': True, 'push': False}, ...}
    type_preferences = models.JSONField(default=dict, blank=True)
    
    # Quiet hours
    quiet_hours_enabled = models.BooleanField(default=False)
    quiet_hours_start = models.TimeField(null=True, blank=True)  # e.g., 22:00
    quiet_hours_end = models.TimeField(null=True, blank=True)    # e.g., 08:00
    
    # Frequency settings
    digest_frequency = models.CharField(max_length=10, choices=[
        ('never', 'Never'),
        ('daily', 'Daily'),
        ('weekly', 'Weekly'),
        ('monthly', 'Monthly')
    ], default='never')
    
    last_digest_sent = models.DateTimeField(null=True, blank=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        indexes = [
            models.Index(fields=['user_id']),
        ]
    
    def __str__(self):
        return f"Notification preferences for {self.user_id}"


class NotificationBatch(models.Model):
    """Batch processing of notifications"""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=100)
    notification_type = models.CharField(max_length=50)
    
    # Batch details
    total_recipients = models.PositiveIntegerField(default=0)
    processed_count = models.PositiveIntegerField(default=0)
    success_count = models.PositiveIntegerField(default=0)
    failed_count = models.PositiveIntegerField(default=0)
    
    # Status
    status = models.CharField(max_length=20, choices=[
        ('pending', 'Pending'),
        ('processing', 'Processing'),
        ('completed', 'Completed'),
        ('failed', 'Failed'),
        ('cancelled', 'Cancelled')
    ], default='pending')
    
    # Timing
    scheduled_at = models.DateTimeField(null=True, blank=True)
    started_at = models.DateTimeField(null=True, blank=True)
    completed_at = models.DateTimeField(null=True, blank=True)
    
    # Content
    template = models.ForeignKey(NotificationTemplate, on_delete=models.CASCADE)
    batch_data = models.JSONField(default=dict)  # Data for template rendering
    
    created_by_id = models.UUIDField(help_text="Admin/System user ID")
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['status']),
            models.Index(fields=['notification_type']),
        ]
    
    def __str__(self):
        return f"Batch: {self.name} ({self.status})"


class NotificationQueue(models.Model):
    """Queue for processing notifications"""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    notification = models.OneToOneField(Notification, on_delete=models.CASCADE, related_name='queue_entry')
    
    # Queue details
    priority = models.PositiveIntegerField(default=5)  # 1=highest, 10=lowest
    scheduled_for = models.DateTimeField()
    
    # Processing
    is_processing = models.BooleanField(default=False)
    processing_started = models.DateTimeField(null=True, blank=True)
    worker_id = models.CharField(max_length=100, blank=True)
    
    # Retry logic
    retry_count = models.PositiveIntegerField(default=0)
    last_error = models.TextField(blank=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        ordering = ['priority', 'scheduled_for']
        indexes = [
            models.Index(fields=['priority', 'scheduled_for']),
            models.Index(fields=['is_processing']),
        ]
    
    def __str__(self):
        return f"Queue entry for notification {self.notification.id}"
