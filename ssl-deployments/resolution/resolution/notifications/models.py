from django.db import models
from django.contrib.auth.models import User
from django.contrib.contenttypes.models import ContentType
from django.contrib.contenttypes.fields import GenericForeignKey


class NotificationTemplate(models.Model):
    """Templates for different types of notifications_service"""
    name = models.CharField(max_length=100, unique=True)
    notification_type = models.CharField(max_length=50, choices=[
        # Review notifications_service
        ('review_received', 'Review Received'),
        ('review_response', 'Review Response'),
        ('review_flagged', 'Review Flagged'),
        
        # Return notifications_service
        ('return_request_received', 'Return Request Received'),
        ('return_approved', 'Return Approved'),
        ('return_rejected', 'Return Rejected'),
        ('return_shipped', 'Return Shipped'),
        ('return_received', 'Return Received'),
        ('return_completed', 'Return Completed'),
        
        # Dispute notifications_service
        ('dispute_created', 'Dispute Created'),
        ('dispute_message', 'Dispute Message'),
        ('dispute_escalated', 'Dispute Escalated'),
        ('dispute_resolved', 'Dispute Resolved'),
        ('resolution_offer', 'Resolution Offer'),
        ('mediation_scheduled', 'Mediation Scheduled'),
        
        # System notifications_service
        ('system_maintenance', 'System Maintenance'),
        ('policy_update', 'Policy Update'),
        ('account_update', 'Account Update'),
        
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
    
    def __str__(self):
        return f"{self.name} - {self.notification_type}"


class Notification(models.Model):
    """Individual notifications_service sent to users"""
    recipient = models.ForeignKey(User, on_delete=models.CASCADE, related_name='notifications')
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
    
    # Retry information
    retry_count = models.PositiveIntegerField(default=0)
    max_retries = models.PositiveIntegerField(default=3)
    next_retry_at = models.DateTimeField(null=True, blank=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['recipient', '-created_at']),
            models.Index(fields=['notification_type']),
            models.Index(fields=['is_read']),
            models.Index(fields=['priority']),
        ]
    
    def __str__(self):
        return f"Notification to {self.recipient.username}: {self.subject}"


class NotificationPreference(models.Model):
    """User preferences for notifications_service"""
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='notification_preferences')
    
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
    
    def __str__(self):
        return f"Notification preferences for {self.user.username}"


class NotificationChannel(models.Model):
    """Configuration for notification delivery channels"""
    name = models.CharField(max_length=50, unique=True)
    channel_type = models.CharField(max_length=20, choices=[
        ('email', 'Email'),
        ('sms', 'SMS'),
        ('push', 'Push Notification'),
        ('webhook', 'Webhook'),
        ('slack', 'Slack'),
        ('discord', 'Discord')
    ])
    
    # Configuration (JSON)
    config = models.JSONField(default=dict)
    
    # Status
    is_active = models.BooleanField(default=True)
    rate_limit = models.PositiveIntegerField(default=0)  # 0 = no limit
    
    # Statistics
    total_sent = models.PositiveIntegerField(default=0)
    total_failed = models.PositiveIntegerField(default=0)
    last_used = models.DateTimeField(null=True, blank=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    def __str__(self):
        return f"{self.name} ({self.channel_type})"


class NotificationBatch(models.Model):
    """Batch processing of notifications_service"""
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
    
    created_by = models.ForeignKey(User, on_delete=models.CASCADE)
    created_at = models.DateTimeField(auto_now_add=True)
    
    def __str__(self):
        return f"Batch: {self.name} ({self.status})"


class NotificationLog(models.Model):
    """Detailed logs for notification delivery"""
    notification = models.ForeignKey(Notification, on_delete=models.CASCADE, related_name='logs')
    channel_type = models.CharField(max_length=20)
    
    # Delivery attempt
    attempt_number = models.PositiveIntegerField(default=1)
    status = models.CharField(max_length=20, choices=[
        ('queued', 'Queued'),
        ('sending', 'Sending'),
        ('sent', 'Sent'),
        ('delivered', 'Delivered'),
        ('failed', 'Failed'),
        ('bounced', 'Bounced'),
        ('rejected', 'Rejected')
    ])
    
    # Details
    external_id = models.CharField(max_length=255, blank=True)  # ID from external service
    response_data = models.JSONField(default=dict, blank=True)
    error_message = models.TextField(blank=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        ordering = ['-created_at']
    
    def __str__(self):
        return f"Log for notification {self.notification.id} - {self.status}"


class NotificationQueue(models.Model):
    """Queue for processing notifications_service"""
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
    
    def __str__(self):
        return f"Queue entry for notification {self.notification.id}"


class NotificationStatistics(models.Model):
    """Daily statistics for notifications_service"""
    date = models.DateField(unique=True)
    
    # Counts by type
    total_sent = models.PositiveIntegerField(default=0)
    email_sent = models.PositiveIntegerField(default=0)
    sms_sent = models.PositiveIntegerField(default=0)
    push_sent = models.PositiveIntegerField(default=0)
    
    # Success rates
    email_success_rate = models.FloatField(default=0.0)
    sms_success_rate = models.FloatField(default=0.0)
    push_success_rate = models.FloatField(default=0.0)
    
    # Response rates
    total_opened = models.PositiveIntegerField(default=0)
    total_clicked = models.PositiveIntegerField(default=0)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    def __str__(self):
        return f"Notification stats for {self.date}"
