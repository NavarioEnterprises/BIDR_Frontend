from django.db import models
from django.contrib.auth.models import User
from django.utils import timezone
from chat_core.models import BaseModel
from chat_conversations.models import Conversation
from chat_messaging.models import Message
import json


class NotificationTemplate(BaseModel):
    """Templates for different types of notifications_service."""
    
    TEMPLATE_TYPES = [
        ('message_received', 'New Message Received'),
        ('mention_received', 'User Mentioned'),
        ('conversation_invite', 'Conversation Invitation'),
        ('message_reaction', 'Message Reaction'),
        ('typing_indicator', 'User Typing'),
        ('file_shared', 'File Shared'),
        ('conversation_archived', 'Conversation Archived'),
        ('moderation_warning', 'Moderation Warning'),
        ('user_banned', 'User Banned'),
        ('translation_ready', 'Translation Ready'),
        ('system_announcement', 'System Announcement'),
        ('custom', 'Custom Notification'),
    ]
    
    CHANNELS = [
        ('push', 'Push Notification'),
        ('email', 'Email'),
        ('sms', 'SMS'),
        ('in_app', 'In-App Notification'),
        ('webhook', 'Webhook'),
    ]
    
    name = models.CharField(max_length=100, unique=True)
    template_type = models.CharField(max_length=30, choices=TEMPLATE_TYPES)
    channel = models.CharField(max_length=20, choices=CHANNELS)
    
    # Template content
    title_template = models.CharField(max_length=200, help_text="Title with variables like {{user_name}}")
    body_template = models.TextField(help_text="Body content with variables")
    
    # Optional rich content
    icon_url = models.URLField(blank=True, help_text="Icon URL for push notifications_service")
    action_url = models.URLField(blank=True, help_text="URL to open when clicked")
    
    # Configuration
    is_enabled = models.BooleanField(default=True)
    priority = models.CharField(max_length=10, choices=[
        ('low', 'Low'),
        ('normal', 'Normal'),
        ('high', 'High'),
        ('urgent', 'Urgent'),
    ], default='normal')
    
    # Scheduling
    delay_seconds = models.PositiveIntegerField(default=0, help_text="Delay before sending")
    batch_notifications = models.BooleanField(default=False, help_text="Batch similar notifications_service")
    
    # Metadata
    variables = models.JSONField(default=list, help_text="List of available template variables")
    created_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, related_name='created_templates')
    
    class Meta:
        verbose_name = "Notification Template"
        verbose_name_plural = "Notification Templates"
        indexes = [
            models.Index(fields=['template_type']),
            models.Index(fields=['channel']),
            models.Index(fields=['is_enabled']),
        ]
    
    def __str__(self):
        return f"{self.name} ({self.get_template_type_display()}) - {self.get_channel_display()}"
    
    def render(self, context):
        """Render template with context variables."""
        title = self.title_template
        body = self.body_template
        
        for key, value in context.items():
            placeholder = f"{{{{{key}}}}}"
            title = title.replace(placeholder, str(value))
            body = body.replace(placeholder, str(value))
        
        return {
            'title': title,
            'body': body,
            'icon_url': self.icon_url,
            'action_url': self.action_url,
            'priority': self.priority
        }


class Notification(BaseModel):
    """Individual notifications_service sent to users."""
    
    STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('sent', 'Sent'),
        ('delivered', 'Delivered'),
        ('read', 'Read'),
        ('failed', 'Failed'),
        ('cancelled', 'Cancelled'),
    ]
    
    recipient = models.ForeignKey(User, on_delete=models.CASCADE, related_name='notifications_service')
    template = models.ForeignKey(NotificationTemplate, on_delete=models.CASCADE, related_name='notifications_service')
    
    # Content (rendered from template)
    title = models.CharField(max_length=200)
    body = models.TextField()
    icon_url = models.URLField(blank=True)
    action_url = models.URLField(blank=True)
    
    # Status and delivery
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    priority = models.CharField(max_length=10, choices=[
        ('low', 'Low'),
        ('normal', 'Normal'),
        ('high', 'High'),
        ('urgent', 'Urgent'),
    ], default='normal')
    
    # Timing
    scheduled_at = models.DateTimeField(default=timezone.now)
    sent_at = models.DateTimeField(null=True, blank=True)
    delivered_at = models.DateTimeField(null=True, blank=True)
    read_at = models.DateTimeField(null=True, blank=True)
    expires_at = models.DateTimeField(null=True, blank=True)
    
    # References
    related_message = models.ForeignKey(Message, on_delete=models.CASCADE, null=True, blank=True, related_name='notifications_service')
    related_conversation = models.ForeignKey(Conversation, on_delete=models.CASCADE, null=True, blank=True, related_name='notifications_service')
    
    # Metadata
    context_data = models.JSONField(default=dict, help_text="Context used to render template")
    delivery_attempts = models.PositiveIntegerField(default=0)
    error_message = models.TextField(blank=True)
    
    # Device/Platform specific
    device_token = models.CharField(max_length=255, blank=True)
    platform = models.CharField(max_length=20, choices=[
        ('ios', 'iOS'),
        ('android', 'Android'),
        ('web', 'Web'),
        ('email', 'Email'),
        ('sms', 'SMS'),
    ], blank=True)
    
    class Meta:
        verbose_name = "Notification"
        verbose_name_plural = "Notifications"
        indexes = [
            models.Index(fields=['recipient', 'status']),
            models.Index(fields=['status']),
            models.Index(fields=['scheduled_at']),
            models.Index(fields=['priority']),
            models.Index(fields=['expires_at']),
        ]
        ordering = ['-created_at']
    
    def __str__(self):
        return f"{self.title} -> {self.recipient.username} ({self.status})"
    
    def mark_as_sent(self):
        """Mark notification as sent."""
        self.status = 'sent'
        self.sent_at = timezone.now()
        self.save(update_fields=['status', 'sent_at'])
    
    def mark_as_delivered(self):
        """Mark notification as delivered."""
        self.status = 'delivered'
        self.delivered_at = timezone.now()
        self.save(update_fields=['status', 'delivered_at'])
    
    def mark_as_read(self):
        """Mark notification as read."""
        self.status = 'read'
        self.read_at = timezone.now()
        self.save(update_fields=['status', 'read_at'])
    
    def is_expired(self):
        """Check if notification has expired."""
        if not self.expires_at:
            return False
        return timezone.now() > self.expires_at


class NotificationPreference(BaseModel):
    """User preferences for notifications_service."""
    
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='notification_preferences')
    
    # Global settings
    notifications_enabled = models.BooleanField(default=True)
    do_not_disturb = models.BooleanField(default=False)
    
    # Quiet hours
    quiet_hours_enabled = models.BooleanField(default=False)
    quiet_start_time = models.TimeField(null=True, blank=True)
    quiet_end_time = models.TimeField(null=True, blank=True)
    
    # Channel preferences
    push_notifications = models.BooleanField(default=True)
    email_notifications = models.BooleanField(default=True)
    sms_notifications = models.BooleanField(default=False)
    in_app_notifications = models.BooleanField(default=True)
    
    # Content preferences
    message_notifications = models.BooleanField(default=True)
    mention_notifications = models.BooleanField(default=True)
    invitation_notifications = models.BooleanField(default=True)
    reaction_notifications = models.BooleanField(default=True)
    file_share_notifications = models.BooleanField(default=True)
    moderation_notifications = models.BooleanField(default=True)
    system_notifications = models.BooleanField(default=True)
    
    # Advanced settings
    notification_preview = models.BooleanField(default=True, help_text="Show message preview in notifications_service")
    group_notifications = models.BooleanField(default=True, help_text="Group similar notifications_service")
    sound_enabled = models.BooleanField(default=True)
    vibration_enabled = models.BooleanField(default=True)
    
    # Frequency settings
    max_notifications_per_hour = models.PositiveIntegerField(default=50)
    batch_delay_minutes = models.PositiveIntegerField(default=5, help_text="Delay for batching notifications_service")
    
    class Meta:
        verbose_name = "Notification Preference"
        verbose_name_plural = "Notification Preferences"
    
    def __str__(self):
        return f"{self.user.username} notification preferences"
    
    def can_send_notification(self, notification_type, channel):
        """Check if a specific notification type can be sent via channel."""
        if not self.notifications_enabled:
            return False
        
        if self.do_not_disturb:
            return False
        
        # Check quiet hours
        if self.quiet_hours_enabled and self.quiet_start_time and self.quiet_end_time:
            current_time = timezone.now().time()
            if self.quiet_start_time <= current_time <= self.quiet_end_time:
                return False
        
        # Check channel preferences
        channel_map = {
            'push': self.push_notifications,
            'email': self.email_notifications,
            'sms': self.sms_notifications,
            'in_app': self.in_app_notifications,
        }
        
        if not channel_map.get(channel, True):
            return False
        
        # Check content preferences
        content_map = {
            'message_received': self.message_notifications,
            'mention_received': self.mention_notifications,
            'conversation_invite': self.invitation_notifications,
            'message_reaction': self.reaction_notifications,
            'file_shared': self.file_share_notifications,
            'moderation_warning': self.moderation_notifications,
            'system_announcement': self.system_notifications,
        }
        
        return content_map.get(notification_type, True)


class NotificationDevice(BaseModel):
    """User devices for push notifications_service."""
    
    DEVICE_TYPES = [
        ('ios', 'iOS'),
        ('android', 'Android'),
        ('web', 'Web Browser'),
    ]
    
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='notification_devices')
    device_type = models.CharField(max_length=20, choices=DEVICE_TYPES)
    device_token = models.CharField(max_length=255, unique=True)
    device_name = models.CharField(max_length=100, blank=True)
    
    # Device info
    app_version = models.CharField(max_length=20, blank=True)
    os_version = models.CharField(max_length=20, blank=True)
    
    # Status
    is_active = models.BooleanField(default=True)
    last_used = models.DateTimeField(default=timezone.now)
    
    # Statistics
    total_notifications_sent = models.PositiveIntegerField(default=0)
    total_notifications_delivered = models.PositiveIntegerField(default=0)
    
    class Meta:
        verbose_name = "Notification Device"
        verbose_name_plural = "Notification Devices"
        indexes = [
            models.Index(fields=['user']),
            models.Index(fields=['device_type']),
            models.Index(fields=['is_active']),
        ]
    
    def __str__(self):
        return f"{self.user.username} - {self.device_name or self.get_device_type_display()}"


class NotificationBatch(BaseModel):
    """Batched notifications_service for efficiency."""
    
    recipient = models.ForeignKey(User, on_delete=models.CASCADE, related_name='notification_batches')
    template = models.ForeignKey(NotificationTemplate, on_delete=models.CASCADE)
    
    # Batch content
    title = models.CharField(max_length=200)
    summary = models.TextField()
    item_count = models.PositiveIntegerField(default=1)
    
    # Status
    status = models.CharField(max_length=20, choices=Notification.STATUS_CHOICES, default='pending')
    sent_at = models.DateTimeField(null=True, blank=True)
    
    # References
    notifications = models.ManyToManyField(Notification, related_name='batches')
    
    class Meta:
        verbose_name = "Notification Batch"
        verbose_name_plural = "Notification Batches"
        indexes = [
            models.Index(fields=['recipient', 'status']),
            models.Index(fields=['sent_at']),
        ]
    
    def __str__(self):
        return f"Batch of {self.item_count} notifications_service for {self.recipient.username}"
