import uuid
from django.db import models
from django.utils import timezone


class NotificationChannel(models.Model):
    """Configuration for notification delivery channels"""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=50, unique=True)
    channel_type = models.CharField(max_length=20, choices=[
        ('email', 'Email'),
        ('sms', 'SMS'),
        ('push', 'Push Notification'),
        ('webhook', 'Webhook'),
        ('slack', 'Slack'),
        ('discord', 'Discord'),
        ('teams', 'Microsoft Teams'),
        ('whatsapp', 'WhatsApp'),
        ('telegram', 'Telegram'),
    ])
    
    # Configuration (JSON)
    config = models.JSONField(default=dict, help_text="Channel-specific configuration")
    
    # Status
    is_active = models.BooleanField(default=True)
    rate_limit = models.PositiveIntegerField(default=0, help_text="Messages per minute (0 = no limit)")
    
    # Statistics
    total_sent = models.PositiveIntegerField(default=0)
    total_failed = models.PositiveIntegerField(default=0)
    last_used = models.DateTimeField(null=True, blank=True)
    
    # Provider information
    provider = models.CharField(max_length=50, blank=True, help_text="External provider name")
    api_endpoint = models.URLField(blank=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['name']
        indexes = [
            models.Index(fields=['channel_type']),
            models.Index(fields=['is_active']),
        ]
    
    def __str__(self):
        return f"{self.name} ({self.channel_type})"
    
    @property
    def success_rate(self):
        """Calculate success rate as percentage"""
        total = self.total_sent + self.total_failed
        if total == 0:
            return 0
        return (self.total_sent / total) * 100


class ChannelCredential(models.Model):
    """Store encrypted credentials for delivery channels"""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    channel = models.ForeignKey(NotificationChannel, on_delete=models.CASCADE, related_name='credentials')
    
    # Credential information
    key_name = models.CharField(max_length=100)
    encrypted_value = models.TextField()
    
    # Metadata
    description = models.CharField(max_length=200, blank=True)
    expires_at = models.DateTimeField(null=True, blank=True)
    is_active = models.BooleanField(default=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        unique_together = ['channel', 'key_name']
        indexes = [
            models.Index(fields=['channel', 'key_name']),
        ]
    
    def __str__(self):
        return f"{self.channel.name} - {self.key_name}"


class DeliveryAttempt(models.Model):
    """Track delivery attempts for notifications"""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    notification_id = models.UUIDField(help_text="Reference to notification in system_notifications")
    channel = models.ForeignKey(NotificationChannel, on_delete=models.CASCADE)
    
    # Delivery attempt details
    attempt_number = models.PositiveIntegerField(default=1)
    status = models.CharField(max_length=20, choices=[
        ('queued', 'Queued'),
        ('sending', 'Sending'),
        ('sent', 'Sent'),
        ('delivered', 'Delivered'),
        ('failed', 'Failed'),
        ('bounced', 'Bounced'),
        ('rejected', 'Rejected'),
        ('timeout', 'Timeout'),
    ])
    
    # External tracking
    external_id = models.CharField(max_length=255, blank=True, help_text="ID from external service")
    external_status = models.CharField(max_length=50, blank=True)
    
    # Response data
    response_data = models.JSONField(default=dict, blank=True)
    error_message = models.TextField(blank=True)
    error_code = models.CharField(max_length=50, blank=True)
    
    # Timing
    started_at = models.DateTimeField(null=True, blank=True)
    completed_at = models.DateTimeField(null=True, blank=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['notification_id']),
            models.Index(fields=['status']),
            models.Index(fields=['channel', '-created_at']),
        ]
    
    def __str__(self):
        return f"Attempt {self.attempt_number} for notification {self.notification_id} - {self.status}"


class ChannelRateLimit(models.Model):
    """Track rate limiting for channels"""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    channel = models.ForeignKey(NotificationChannel, on_delete=models.CASCADE, related_name='rate_limits')
    
    # Rate limit configuration
    time_window = models.CharField(max_length=20, choices=[
        ('minute', 'Per Minute'),
        ('hour', 'Per Hour'),
        ('day', 'Per Day'),
        ('month', 'Per Month'),
    ])
    max_requests = models.PositiveIntegerField()
    
    # Current usage tracking
    current_count = models.PositiveIntegerField(default=0)
    window_start = models.DateTimeField(default=timezone.now)
    
    # Status
    is_active = models.BooleanField(default=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        unique_together = ['channel', 'time_window']
        indexes = [
            models.Index(fields=['channel', 'time_window']),
        ]
    
    def __str__(self):
        return f"{self.channel.name} - {self.max_requests}/{self.time_window}"
    
    def is_rate_limited(self):
        """Check if channel is currently rate limited"""
        # Reset counter if window has passed
        now = timezone.now()
        if self.time_window == 'minute' and (now - self.window_start).seconds >= 60:
            self.current_count = 0
            self.window_start = now
            self.save()
        elif self.time_window == 'hour' and (now - self.window_start).seconds >= 3600:
            self.current_count = 0
            self.window_start = now
            self.save()
        elif self.time_window == 'day' and (now - self.window_start).days >= 1:
            self.current_count = 0
            self.window_start = now
            self.save()
        
        return self.current_count >= self.max_requests
