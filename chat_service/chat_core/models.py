"""
Core models for BIDR Chat Service.

This module defines the foundational models and base classes used throughout
the chat service including user management, common fields, and utilities.
"""

import uuid
from django.db import models
from django.contrib.auth.models import User
from django.core.validators import MinValueValidator, MaxValueValidator
from django.utils import timezone
from datetime import timedelta


class TimestampedModel(models.Model):
    """
    Abstract base class that provides self-updating created_at and updated_at fields.
    """
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        abstract = True


class UUIDModel(models.Model):
    """
    Abstract base class that provides a UUID primary key.
    """
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    
    class Meta:
        abstract = True


class BaseModel(UUIDModel, TimestampedModel):
    """
    Abstract base class combining UUID primary keys, timestamps, and soft delete.
    """
    is_active = models.BooleanField(default=True, help_text='Soft delete flag')
    
    class Meta:
        abstract = True


class StatusChoices(models.TextChoices):
    """Common status choices used across the application."""
    ACTIVE = 'active', 'Active'
    INACTIVE = 'inactive', 'Inactive'
    SUSPENDED = 'suspended', 'Suspended'
    DELETED = 'deleted', 'Deleted'
    ARCHIVED = 'archived', 'Archived'


class UserProfile(BaseModel):
    """
    Extended user profile for chat service with privacy and moderation features.
    """
    ROLE_CHOICES = [
        ('buyer', 'Buyer'),
        ('seller', 'Seller'), 
        ('moderator', 'Moderator'),
        ('admin', 'Administrator'),
    ]
    
    VERIFICATION_CHOICES = [
        ('unverified', 'Unverified'),
        ('email_verified', 'Email Verified'),
        ('phone_verified', 'Phone Verified'),
        ('identity_verified', 'Identity Verified'),
        ('business_verified', 'Business Verified'),
        ('fully_verified', 'Fully Verified'),
    ]
    
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='chat_profile')
    role = models.CharField(max_length=20, choices=ROLE_CHOICES, default='buyer')
    verification_status = models.CharField(max_length=20, choices=VERIFICATION_CHOICES, default='unverified')
    
    # Privacy Settings
    display_name = models.CharField(max_length=100, blank=True)
    avatar = models.ImageField(upload_to='avatars/', blank=True, null=True)
    bio = models.TextField(max_length=500, blank=True)
    location = models.CharField(max_length=100, blank=True)
    
    # Privacy Controls
    allow_direct_messages = models.BooleanField(default=True)
    show_online_status = models.BooleanField(default=True)
    allow_read_receipts = models.BooleanField(default=True)
    mask_personal_info = models.BooleanField(default=True)
    
    # Business Information (for sellers)
    company_name = models.CharField(max_length=200, blank=True)
    business_registration_number = models.CharField(max_length=100, blank=True)
    tax_number = models.CharField(max_length=100, blank=True)
    
    # Contact Information (encrypted/masked)
    phone_number = models.CharField(max_length=20, blank=True)
    business_email = models.EmailField(blank=True)
    website_url = models.URLField(blank=True)
    
    # Moderation Status
    status = models.CharField(max_length=20, choices=StatusChoices.choices, default=StatusChoices.ACTIVE)
    is_banned = models.BooleanField(default=False)
    ban_reason = models.TextField(blank=True)
    ban_expires_at = models.DateTimeField(null=True, blank=True)
    warning_count = models.PositiveIntegerField(default=0)
    
    # Statistics
    total_conversations = models.PositiveIntegerField(default=0)
    total_messages_sent = models.PositiveIntegerField(default=0)
    average_response_time_minutes = models.PositiveIntegerField(default=0)
    reputation_score = models.DecimalField(max_digits=3, decimal_places=1, default=5.0)
    
    # Timestamps
    last_seen = models.DateTimeField(default=timezone.now)
    last_activity = models.DateTimeField(default=timezone.now)
    
    class Meta:
        verbose_name = "User Profile"
        verbose_name_plural = "User Profiles"
        indexes = [
            models.Index(fields=['role', 'status']),
            models.Index(fields=['verification_status']),
            models.Index(fields=['is_banned']),
            models.Index(fields=['last_seen']),
        ]
    
    def __str__(self):
        return f"{self.get_display_name()} ({self.role})"
    
    def get_display_name(self):
        """Get the display name, falling back to username if not set."""
        return self.display_name or f"{self.role.title()} {self.user.username}"
    
    def is_online(self):
        """Check if user is currently online (last seen within 5 minutes)."""
        if not self.show_online_status:
            return False
        return timezone.now() - self.last_seen < timedelta(minutes=5)
    
    def can_send_messages(self):
        """Check if user can send messages (not banned and active)."""
        if self.is_banned:
            # Check if ban is permanent or still active
            if not self.ban_expires_at or timezone.now() < self.ban_expires_at:
                return False
        return self.status == StatusChoices.ACTIVE


class SystemConfig(BaseModel):
    """System-wide configuration for chat service features."""
    
    CONFIG_CATEGORIES = [
        ('moderation', 'Content Moderation'),
        ('translation', 'Translation Services'),
        ('limits', 'System Limits'),
        ('features', 'Feature Flags'),
        ('privacy', 'Privacy Controls'),
        ('notifications_service', 'Notification Settings'),
    ]
    
    category = models.CharField(max_length=50, choices=CONFIG_CATEGORIES)
    key = models.CharField(max_length=100)
    value = models.TextField()
    description = models.TextField(blank=True)
    is_system_managed = models.BooleanField(default=False)
    is_user_configurable = models.BooleanField(default=True)
    
    class Meta:
        verbose_name = "System Configuration"
        verbose_name_plural = "System Configurations"
        unique_together = ['category', 'key']
        indexes = [
            models.Index(fields=['category']),
            models.Index(fields=['key']),
        ]
    
    def __str__(self):
        return f"{self.category}.{self.key}"
    
    @staticmethod
    def get_config(category, key, default=None):
        """Get configuration value with fallback."""
        try:
            config = SystemConfig.objects.get(category=category, key=key)
            # Try to parse JSON, fallback to string
            try:
                import json
                return json.loads(config.value)
            except (json.JSONDecodeError, TypeError):
                return config.value
        except SystemConfig.DoesNotExist:
            return default


class AuditLog(BaseModel):
    """Comprehensive audit logging for all system actions."""
    
    ACTION_TYPES = [
        ('user_login', 'User Login'),
        ('user_logout', 'User Logout'),
        ('message_sent', 'Message Sent'),
        ('message_deleted', 'Message Deleted'),
        ('message_edited', 'Message Edited'),
        ('conversation_created', 'Conversation Created'),
        ('conversation_deleted', 'Conversation Deleted'),
        ('user_banned', 'User Banned'),
        ('user_unbanned', 'User Unbanned'),
        ('content_moderated', 'Content Moderated'),
        ('file_uploaded', 'File Uploaded'),
        ('file_deleted', 'File Deleted'),
        ('translation_requested', 'Translation Requested'),
        ('privacy_violation', 'Privacy Violation Detected'),
        ('spam_detected', 'Spam Content Detected'),
        ('profanity_detected', 'Profanity Detected'),
        ('personal_info_shared', 'Personal Information Shared'),
        ('system_config_changed', 'System Configuration Changed'),
    ]
    
    user = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True, related_name='audit_logs')
    action_type = models.CharField(max_length=50, choices=ACTION_TYPES)
    resource_type = models.CharField(max_length=100)  # Model name
    resource_id = models.CharField(max_length=100)    # Object ID
    details = models.JSONField(default=dict, blank=True)
    ip_address = models.GenericIPAddressField(null=True, blank=True)
    user_agent = models.TextField(blank=True)
    severity = models.CharField(max_length=20, choices=[
        ('low', 'Low'),
        ('medium', 'Medium'),
        ('high', 'High'),
        ('critical', 'Critical'),
    ], default='low')
    
    class Meta:
        verbose_name = "Audit Log"
        verbose_name_plural = "Audit Logs"
        indexes = [
            models.Index(fields=['user']),
            models.Index(fields=['action_type']),
            models.Index(fields=['resource_type']),
            models.Index(fields=['severity']),
            models.Index(fields=['created_at']),
        ]
    
    def __str__(self):
        user_str = self.user.username if self.user else 'System'
        return f"{user_str} - {self.get_action_type_display()}"


class TranslationCache(BaseModel):
    """Cache for translated content to improve performance."""
    
    source_text = models.TextField()
    source_language = models.CharField(max_length=10)
    target_language = models.CharField(max_length=10)
    translated_text = models.TextField()
    translation_service = models.CharField(max_length=50, default='google')  # google, azure, aws
    confidence_score = models.DecimalField(max_digits=5, decimal_places=4, null=True, blank=True)
    
    # Usage tracking
    usage_count = models.PositiveIntegerField(default=1)
    last_used = models.DateTimeField(auto_now=True)
    
    class Meta:
        verbose_name = "Translation Cache"
        verbose_name_plural = "Translation Caches"
        unique_together = ['source_text', 'source_language', 'target_language']
        indexes = [
            models.Index(fields=['source_language', 'target_language']),
            models.Index(fields=['last_used']),
        ]
    
    def __str__(self):
        return f"{self.source_language} -> {self.target_language}: {self.source_text[:50]}..."


class ContentFilterRule(BaseModel):
    """Configurable content filtering rules for moderation."""
    
    RULE_TYPES = [
        ('profanity', 'Profanity Filter'),
        ('personal_info', 'Personal Information'),
        ('spam', 'Spam Detection'),
        ('offensive', 'Offensive Content'),
        ('scam', 'Scam/Fraud Detection'),
        ('custom', 'Custom Rule'),
    ]
    
    ACTION_TYPES = [
        ('flag', 'Flag for Review'),
        ('block', 'Block Message'),
        ('warn', 'Warn User'),
        ('mask', 'Mask Content'),
        ('replace', 'Replace with Alternative'),
    ]
    
    name = models.CharField(max_length=100)
    rule_type = models.CharField(max_length=20, choices=RULE_TYPES)
    pattern = models.TextField(help_text="Regex pattern or keyword list")
    action = models.CharField(max_length=20, choices=ACTION_TYPES)
    severity = models.CharField(max_length=20, choices=[
        ('low', 'Low'),
        ('medium', 'Medium'),
        ('high', 'High'),
    ], default='medium')
    
    is_enabled = models.BooleanField(default=True)
    language_codes = models.JSONField(default=list, help_text="Languages this rule applies to")
    replacement_text = models.TextField(blank=True, help_text="Text to replace matches with")
    
    # Usage statistics
    trigger_count = models.PositiveIntegerField(default=0)
    last_triggered = models.DateTimeField(null=True, blank=True)
    
    class Meta:
        verbose_name = "Content Filter Rule"
        verbose_name_plural = "Content Filter Rules"
        indexes = [
            models.Index(fields=['rule_type']),
            models.Index(fields=['is_enabled']),
        ]
    
    def __str__(self):
        return f"{self.name} ({self.get_rule_type_display()})"


class ModerationQueue(BaseModel):
    """Queue for content requiring manual moderation."""
    
    CONTENT_TYPES = [
        ('message', 'Chat Message'),
        ('file', 'File Upload'),
        ('profile', 'User Profile'),
        ('conversation', 'Conversation'),
    ]
    
    STATUS_CHOICES = [
        ('pending', 'Pending Review'),
        ('approved', 'Approved'),
        ('rejected', 'Rejected'),
        ('escalated', 'Escalated'),
    ]
    
    content_type = models.CharField(max_length=20, choices=CONTENT_TYPES)
    content_id = models.CharField(max_length=100)
    reported_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True, related_name='moderation_reports')
    assigned_to = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True, related_name='assigned_moderation')
    
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    priority = models.CharField(max_length=20, choices=[
        ('low', 'Low'),
        ('normal', 'Normal'),
        ('high', 'High'),
        ('urgent', 'Urgent'),
    ], default='normal')
    
    reason = models.TextField()
    content_snapshot = models.JSONField(help_text="Snapshot of content at time of report")
    moderator_notes = models.TextField(blank=True)
    decision_reason = models.TextField(blank=True)
    processed_at = models.DateTimeField(null=True, blank=True)
    
    class Meta:
        verbose_name = "Moderation Queue Item"
        verbose_name_plural = "Moderation Queue"
        indexes = [
            models.Index(fields=['status']),
            models.Index(fields=['priority']),
            models.Index(fields=['assigned_to']),
            models.Index(fields=['created_at']),
        ]
    
    def __str__(self):
        return f"{self.get_content_type_display()} - {self.get_status_display()}"


class LanguagePreference(BaseModel):
    """User language preferences and translation settings."""
    
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='language_preference')
    primary_language = models.CharField(max_length=10, default='en')
    secondary_languages = models.JSONField(default=list)
    
    # Translation preferences
    auto_translate_enabled = models.BooleanField(default=False)
    translate_from_languages = models.JSONField(default=list)
    show_original_text = models.BooleanField(default=True)
    
    # UI preferences
    date_format = models.CharField(max_length=20, default='%Y-%m-%d')
    time_format = models.CharField(max_length=20, default='%H:%M')
    timezone = models.CharField(max_length=50, default='UTC')
    
    class Meta:
        verbose_name = "Language Preference"
        verbose_name_plural = "Language Preferences"
    
    def __str__(self):
        return f"{self.user.username} - {self.primary_language}"
