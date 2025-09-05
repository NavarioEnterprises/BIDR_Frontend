from django.db import models
from django.contrib.auth.models import User
from django.utils import timezone
from chat_core.models import BaseModel, StatusChoices
from chat_conversations.models import Conversation
from chat_messaging.models import Message
import json


class ModerationRule(BaseModel):
    """Configurable moderation rules for content filtering."""
    
    RULE_TYPES = [
        ('profanity', 'Profanity Filter'),
        ('personal_info', 'Personal Information'),
        ('spam', 'Spam Detection'),
        ('offensive', 'Offensive Content'),
        ('scam', 'Scam/Fraud Detection'),
        ('harassment', 'Harassment'),
        ('hate_speech', 'Hate Speech'),
        ('violence', 'Violence/Threats'),
        ('adult_content', 'Adult Content'),
        ('custom', 'Custom Rule'),
    ]
    
    ACTION_TYPES = [
        ('flag', 'Flag for Review'),
        ('block', 'Block Message'),
        ('warn', 'Warn User'),
        ('mask', 'Mask Content'),
        ('replace', 'Replace with Alternative'),
        ('escalate', 'Escalate to Human Review'),
        ('ban_user', 'Ban User'),
    ]
    
    SEVERITY_LEVELS = [
        ('low', 'Low'),
        ('medium', 'Medium'),
        ('high', 'High'),
        ('critical', 'Critical'),
    ]
    
    name = models.CharField(max_length=100)
    description = models.TextField(blank=True)
    rule_type = models.CharField(max_length=20, choices=RULE_TYPES)
    pattern = models.TextField(help_text="Regex pattern, keyword list, or ML model identifier")
    action = models.CharField(max_length=20, choices=ACTION_TYPES)
    severity = models.CharField(max_length=20, choices=SEVERITY_LEVELS, default='medium')
    
    # Configuration
    is_enabled = models.BooleanField(default=True)
    is_case_sensitive = models.BooleanField(default=False)
    language_codes = models.JSONField(default=list, help_text="Languages this rule applies to")
    replacement_text = models.TextField(blank=True, help_text="Text to replace matches with")
    
    # ML/AI configuration
    confidence_threshold = models.DecimalField(
        max_digits=5, decimal_places=4, 
        default=0.8000, 
        help_text="Minimum confidence for ML-based rules"
    )
    
    # Usage statistics
    trigger_count = models.PositiveIntegerField(default=0)
    false_positive_count = models.PositiveIntegerField(default=0)
    last_triggered = models.DateTimeField(null=True, blank=True)
    
    # Metadata
    created_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, related_name='created_moderation_rules')
    tags = models.JSONField(default=list, blank=True)
    
    class Meta:
        verbose_name = "Moderation Rule"
        verbose_name_plural = "Moderation Rules"
        indexes = [
            models.Index(fields=['rule_type']),
            models.Index(fields=['is_enabled']),
            models.Index(fields=['severity']),
        ]
    
    def __str__(self):
        return f"{self.name} ({self.get_rule_type_display()})"
    
    def increment_trigger_count(self):
        """Increment the trigger count and update last triggered."""
        self.trigger_count += 1
        self.last_triggered = timezone.now()
        self.save(update_fields=['trigger_count', 'last_triggered'])
    
    def get_accuracy_rate(self):
        """Calculate accuracy rate (non-false positives / total triggers)."""
        if self.trigger_count == 0:
            return 1.0
        return 1 - (self.false_positive_count / self.trigger_count)


class ModerationAction(BaseModel):
    """Records of moderation actions taken."""
    
    ACTION_TYPES = [
        ('message_flagged', 'Message Flagged'),
        ('message_blocked', 'Message Blocked'),
        ('message_masked', 'Message Masked'),
        ('user_warned', 'User Warned'),
        ('user_banned', 'User Banned'),
        ('content_removed', 'Content Removed'),
        ('escalated', 'Escalated to Human'),
        ('false_positive', 'False Positive Reported'),
    ]
    
    # What was moderated
    content_type = models.CharField(max_length=20, choices=[
        ('message', 'Message'),
        ('profile', 'User Profile'),
        ('file', 'File Upload'),
        ('conversation', 'Conversation'),
    ])
    content_id = models.CharField(max_length=100)
    
    # Action details
    action_type = models.CharField(max_length=30, choices=ACTION_TYPES)
    rule_triggered = models.ForeignKey(ModerationRule, on_delete=models.SET_NULL, null=True, blank=True)
    confidence_score = models.DecimalField(max_digits=5, decimal_places=4, null=True, blank=True)
    
    # Users involved
    target_user = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, related_name='moderation_actions_received')
    moderator = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True, related_name='moderation_actions_taken')
    
    # Action metadata
    reason = models.TextField(help_text="Reason for the action")
    details = models.JSONField(default=dict, blank=True)
    is_automated = models.BooleanField(default=True)
    
    # Content snapshot
    original_content = models.TextField(help_text="Snapshot of original content")
    modified_content = models.TextField(blank=True, help_text="Content after moderation")
    
    # Review status
    is_reviewed = models.BooleanField(default=False)
    review_status = models.CharField(max_length=20, choices=[
        ('upheld', 'Action Upheld'),
        ('overturned', 'Action Overturned'),
        ('modified', 'Action Modified'),
        ('pending', 'Under Review'),
    ], blank=True)
    
    reviewed_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True, related_name='reviewed_actions')
    reviewed_at = models.DateTimeField(null=True, blank=True)
    review_notes = models.TextField(blank=True)
    
    class Meta:
        verbose_name = "Moderation Action"
        verbose_name_plural = "Moderation Actions"
        indexes = [
            models.Index(fields=['content_type', 'content_id']),
            models.Index(fields=['action_type']),
            models.Index(fields=['target_user']),
            models.Index(fields=['is_automated']),
            models.Index(fields=['created_at']),
        ]
    
    def __str__(self):
        return f"{self.get_action_type_display()} - {self.target_user.username if self.target_user else 'Unknown'}"


class UserWarning(BaseModel):
    """Warnings issued to users for policy violations."""
    
    WARNING_TYPES = [
        ('content_violation', 'Content Policy Violation'),
        ('spam', 'Spam Behavior'),
        ('harassment', 'Harassment'),
        ('inappropriate_content', 'Inappropriate Content'),
        ('personal_info_sharing', 'Sharing Personal Information'),
        ('scam_attempt', 'Scam/Fraud Attempt'),
        ('other', 'Other'),
    ]
    
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='warnings')
    warning_type = models.CharField(max_length=30, choices=WARNING_TYPES)
    title = models.CharField(max_length=200)
    description = models.TextField()
    
    # Reference to the content that caused the warning
    related_message = models.ForeignKey(Message, on_delete=models.SET_NULL, null=True, blank=True)
    related_conversation = models.ForeignKey(Conversation, on_delete=models.SET_NULL, null=True, blank=True)
    
    # Warning details
    severity = models.CharField(max_length=20, choices=ModerationRule.SEVERITY_LEVELS, default='medium')
    expires_at = models.DateTimeField(null=True, blank=True, help_text="When this warning expires")
    
    # Status
    is_acknowledged = models.BooleanField(default=False)
    acknowledged_at = models.DateTimeField(null=True, blank=True)
    
    # Staff details
    issued_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, related_name='issued_warnings')
    is_automated = models.BooleanField(default=False)
    
    class Meta:
        verbose_name = "User Warning"
        verbose_name_plural = "User Warnings"
        indexes = [
            models.Index(fields=['user']),
            models.Index(fields=['warning_type']),
            models.Index(fields=['severity']),
            models.Index(fields=['is_acknowledged']),
        ]
    
    def __str__(self):
        return f"Warning for {self.user.username} - {self.title}"
    
    def acknowledge(self):
        """Mark warning as acknowledged by user."""
        self.is_acknowledged = True
        self.acknowledged_at = timezone.now()
        self.save(update_fields=['is_acknowledged', 'acknowledged_at'])
    
    def is_expired(self):
        """Check if warning has expired."""
        if not self.expires_at:
            return False
        return timezone.now() > self.expires_at


class UserBan(BaseModel):
    """Temporary or permanent bans for users."""
    
    BAN_TYPES = [
        ('temporary', 'Temporary Ban'),
        ('permanent', 'Permanent Ban'),
        ('shadow', 'Shadow Ban'),  # User can send messages but others can't see them
    ]
    
    BAN_SCOPES = [
        ('global', 'Global (All chat features)'),
        ('messaging', 'Messaging only'),
        ('group_chat', 'Group chats only'),
        ('file_sharing', 'File sharing only'),
    ]
    
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='bans')
    ban_type = models.CharField(max_length=20, choices=BAN_TYPES)
    ban_scope = models.CharField(max_length=20, choices=BAN_SCOPES, default='global')
    
    reason = models.TextField()
    internal_notes = models.TextField(blank=True, help_text="Internal notes for staff")
    
    # Duration
    starts_at = models.DateTimeField(default=timezone.now)
    expires_at = models.DateTimeField(null=True, blank=True, help_text="Leave blank for permanent ban")
    
    # Status
    is_active = models.BooleanField(default=True)
    lifted_at = models.DateTimeField(null=True, blank=True)
    lifted_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True, related_name='lifted_bans')
    lift_reason = models.TextField(blank=True)
    
    # Staff details
    banned_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, related_name='issued_bans')
    
    # References
    related_warnings = models.ManyToManyField(UserWarning, blank=True)
    related_actions = models.ManyToManyField(ModerationAction, blank=True)
    
    class Meta:
        verbose_name = "User Ban"
        verbose_name_plural = "User Bans"
        indexes = [
            models.Index(fields=['user']),
            models.Index(fields=['ban_type']),
            models.Index(fields=['is_active']),
            models.Index(fields=['expires_at']),
        ]
    
    def __str__(self):
        ban_duration = "permanent" if not self.expires_at else f"until {self.expires_at.strftime('%Y-%m-%d')}"
        return f"{self.get_ban_type_display()} for {self.user.username} ({ban_duration})"
    
    def is_expired(self):
        """Check if ban has expired."""
        if not self.expires_at:
            return False  # Permanent ban
        return timezone.now() > self.expires_at
    
    def lift_ban(self, lifted_by_user, reason=""):
        """Lift the ban."""
        self.is_active = False
        self.lifted_at = timezone.now()
        self.lifted_by = lifted_by_user
        self.lift_reason = reason
        self.save()
    
    def can_user_perform_action(self, action):
        """Check if banned user can perform a specific action."""
        if not self.is_active or self.is_expired():
            return True
        
        if self.ban_scope == 'global':
            return False
        
        action_scope_map = {
            'send_message': 'messaging',
            'join_group': 'group_chat',
            'upload_file': 'file_sharing',
        }
        
        return self.ban_scope != action_scope_map.get(action, 'global')


class AutoModerationSettings(BaseModel):
    """Settings for automatic moderation features."""
    
    # Global settings
    auto_moderation_enabled = models.BooleanField(default=True)
    confidence_threshold = models.DecimalField(
        max_digits=5, decimal_places=4, 
        default=0.7000,
        help_text="Minimum confidence score for auto-actions"
    )
    
    # Feature-specific settings
    profanity_filter_enabled = models.BooleanField(default=True)
    spam_detection_enabled = models.BooleanField(default=True)
    pii_protection_enabled = models.BooleanField(default=True)
    hate_speech_detection_enabled = models.BooleanField(default=True)
    
    # Rate limiting
    max_messages_per_minute = models.PositiveIntegerField(default=20)
    max_identical_messages = models.PositiveIntegerField(default=3)
    rate_limit_window_minutes = models.PositiveIntegerField(default=5)
    
    # Escalation settings
    auto_escalate_high_confidence = models.BooleanField(default=True)
    escalation_confidence_threshold = models.DecimalField(
        max_digits=5, decimal_places=4,
        default=0.9000
    )
    
    # Review settings
    require_human_review_for_bans = models.BooleanField(default=True)
    auto_ban_repeat_offenders = models.BooleanField(default=True)
    repeat_offender_threshold = models.PositiveIntegerField(default=3)
    
    # Notification settings
    notify_moderators_for_escalations = models.BooleanField(default=True)
    notify_users_of_actions = models.BooleanField(default=True)
    
    # Metadata
    updated_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True)
    
    class Meta:
        verbose_name = "Auto Moderation Settings"
        verbose_name_plural = "Auto Moderation Settings"
    
    def __str__(self):
        return f"Auto Moderation Settings (Updated: {self.updated_at})"
    
    @classmethod
    def get_current_settings(cls):
        """Get the current active settings."""
        return cls.objects.first() or cls.objects.create()
