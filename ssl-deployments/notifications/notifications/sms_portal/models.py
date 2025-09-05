import uuid
from django.db import models
from django.utils import timezone


class SMSPortalConfig(models.Model):
    """Configuration for SMS Portal API"""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=100, unique=True, default="SMS Portal")
    
    # API Configuration
    api_url = models.URLField(default="https://rest.smsportal.com/v1")
    api_key = models.CharField(max_length=255, help_text="SMS Portal API Key")
    api_secret = models.CharField(max_length=255, help_text="SMS Portal API Secret")
    
    # Default settings
    default_sender_id = models.CharField(max_length=20, help_text="Default sender ID/name")
    
    # Status and monitoring
    is_active = models.BooleanField(default=True)
    last_used = models.DateTimeField(null=True, blank=True)
    
    # Rate limiting
    rate_limit_per_minute = models.PositiveIntegerField(default=100)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'sms_portal_config'
        verbose_name = 'SMS Portal Configuration'
        verbose_name_plural = 'SMS Portal Configurations'
    
    def __str__(self):
        return f"{self.name} - {'Active' if self.is_active else 'Inactive'}"


class SMSMessage(models.Model):
    """Track SMS messages sent through SMS Portal"""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    
    # Message details
    recipient_phone = models.CharField(max_length=20, help_text="Recipient phone number")
    message_content = models.TextField(help_text="SMS message content")
    sender_id = models.CharField(max_length=20, help_text="Sender ID used")
    
    # SMS Portal response
    external_message_id = models.CharField(max_length=100, blank=True, help_text="SMS Portal message ID")
    external_status = models.CharField(max_length=50, blank=True, help_text="Status from SMS Portal")
    
    # Internal status tracking
    status = models.CharField(max_length=20, choices=[
        ('queued', 'Queued'),
        ('sending', 'Sending'),
        ('sent', 'Sent'),
        ('delivered', 'Delivered'),
        ('failed', 'Failed'),
        ('bounced', 'Bounced'),
        ('rejected', 'Rejected'),
    ], default='queued')
    
    # Response data
    response_data = models.JSONField(default=dict, blank=True)
    error_message = models.TextField(blank=True)
    error_code = models.CharField(max_length=50, blank=True)
    
    # Cost tracking
    cost = models.DecimalField(max_digits=10, decimal_places=4, null=True, blank=True)
    credits_used = models.PositiveIntegerField(default=1)
    
    # Timing
    queued_at = models.DateTimeField(auto_now_add=True)
    sent_at = models.DateTimeField(null=True, blank=True)
    delivered_at = models.DateTimeField(null=True, blank=True)
    
    # Retry handling
    retry_count = models.PositiveIntegerField(default=0)
    max_retries = models.PositiveIntegerField(default=3)
    next_retry_at = models.DateTimeField(null=True, blank=True)
    
    # Reference to notification
    notification_id = models.UUIDField(null=True, blank=True, help_text="Related notification ID")
    
    # Message type
    message_type = models.CharField(max_length=50, choices=[
        ('otp', 'OTP Verification'),
        ('notification', 'General Notification'),
        ('alert', 'Alert Message'),
        ('marketing', 'Marketing Message'),
        ('system', 'System Message'),
    ], default='notification')
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'sms_portal_messages'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['recipient_phone']),
            models.Index(fields=['status']),
            models.Index(fields=['external_message_id']),
            models.Index(fields=['message_type']),
            models.Index(fields=['-created_at']),
        ]
        verbose_name = 'SMS Message'
        verbose_name_plural = 'SMS Messages'
    
    def __str__(self):
        return f"SMS to {self.recipient_phone} - {self.status}"


class SMSUsageStats(models.Model):
    """Track SMS usage statistics"""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    
    # Date tracking
    date = models.DateField(help_text="Date for statistics")
    
    # Usage counts
    total_sent = models.PositiveIntegerField(default=0)
    total_delivered = models.PositiveIntegerField(default=0)
    total_failed = models.PositiveIntegerField(default=0)
    total_bounced = models.PositiveIntegerField(default=0)
    
    # Cost tracking
    total_cost = models.DecimalField(max_digits=12, decimal_places=4, default=0)
    total_credits_used = models.PositiveIntegerField(default=0)
    
    # Message type breakdown
    otp_count = models.PositiveIntegerField(default=0)
    notification_count = models.PositiveIntegerField(default=0)
    alert_count = models.PositiveIntegerField(default=0)
    marketing_count = models.PositiveIntegerField(default=0)
    system_count = models.PositiveIntegerField(default=0)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'sms_portal_usage_stats'
        unique_together = ['date']
        ordering = ['-date']
        verbose_name = 'SMS Usage Statistics'
        verbose_name_plural = 'SMS Usage Statistics'
    
    def __str__(self):
        return f"SMS Stats for {self.date}: {self.total_sent} sent"
    
    @property
    def delivery_rate(self):
        """Calculate delivery rate as percentage"""
        if self.total_sent == 0:
            return 0
        return (self.total_delivered / self.total_sent) * 100
    
    @property
    def success_rate(self):
        """Calculate success rate (sent successfully) as percentage"""
        if self.total_sent == 0:
            return 0
        successful = self.total_sent - self.total_failed
        return (successful / self.total_sent) * 100


class SMSTemplate(models.Model):
    """SMS message templates"""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=100, unique=True)
    
    # Template content
    content = models.TextField(help_text="SMS template with placeholders like {name}, {code}")
    
    # Template metadata
    message_type = models.CharField(max_length=50, choices=[
        ('otp', 'OTP Verification'),
        ('notification', 'General Notification'),
        ('alert', 'Alert Message'),
        ('marketing', 'Marketing Message'),
        ('system', 'System Message'),
    ])
    
    # Settings
    is_active = models.BooleanField(default=True)
    sender_id = models.CharField(max_length=20, blank=True, help_text="Override default sender ID")
    
    # Usage tracking
    usage_count = models.PositiveIntegerField(default=0)
    last_used = models.DateTimeField(null=True, blank=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'sms_portal_templates'
        ordering = ['name']
        verbose_name = 'SMS Template'
        verbose_name_plural = 'SMS Templates'
    
    def __str__(self):
        return f"{self.name} - {self.message_type}"
    
    def render_content(self, context):
        """Render template with context data"""
        try:
            return self.content.format(**context)
        except KeyError as e:
            raise ValueError(f"Missing template variable: {e}")