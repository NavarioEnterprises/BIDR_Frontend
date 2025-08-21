"""
Conversation models for BIDR Chat Service.

This module defines the conversation and messaging models that handle
real-time communication between buyers and sellers with integrated
bidding and negotiation features.
"""

from django.db import models
from django.contrib.auth.models import User
from django.utils import timezone
from django.core.validators import MinValueValidator, MaxValueValidator
from chat_core.models import BaseModel, StatusChoices


class Conversation(BaseModel):
    """
    Main conversation model that groups messages between participants.
    """
    CONVERSATION_TYPES = [
        ('product_inquiry', 'Product Inquiry'),
        ('quote_negotiation', 'Quote Negotiation'),
        ('bidding_round', 'Bidding Round'),
        ('dispute_resolution', 'Dispute Resolution'),
        ('general', 'General Chat'),
    ]
    
    CONVERSATION_STATUS = [
        ('active', 'Active'),
        ('paused', 'Paused'),
        ('archived', 'Archived'),
        ('closed', 'Closed'),
        ('escalated', 'Escalated'),
    ]
    
    # Core Fields
    title = models.CharField(max_length=200)
    conversation_type = models.CharField(max_length=30, choices=CONVERSATION_TYPES, default='product_inquiry')
    status = models.CharField(max_length=20, choices=CONVERSATION_STATUS, default='active')
    
    # Participants
    buyer = models.ForeignKey(User, on_delete=models.CASCADE, related_name='buyer_conversations')
    participants = models.ManyToManyField(User, through='ConversationParticipant', related_name='chat_conversations')
    
    # External References
    product_request_id = models.UUIDField(null=True, blank=True)  # Reference to product request
    quote_id = models.UUIDField(null=True, blank=True)  # Reference to quote
    
    # Conversation Settings
    allow_new_participants = models.BooleanField(default=False)
    is_bidding_enabled = models.BooleanField(default=True)
    auto_archive_after_hours = models.PositiveIntegerField(default=720)  # 30 days
    
    # Moderation
    is_moderated = models.BooleanField(default=True)
    requires_approval = models.BooleanField(default=False)
    
    # Metadata
    last_message_at = models.DateTimeField(null=True, blank=True)
    total_messages = models.PositiveIntegerField(default=0)
    
    # Privacy & Security
    is_encrypted = models.BooleanField(default=False)
    access_code = models.CharField(max_length=50, blank=True)  # For secure access
    
    class Meta:
        verbose_name = "Conversation"
        verbose_name_plural = "Conversations"
        indexes = [
            models.Index(fields=['buyer', 'status']),
            models.Index(fields=['conversation_type', 'status']),
            models.Index(fields=['product_request_id']),
            models.Index(fields=['quote_id']),
            models.Index(fields=['last_message_at']),
            models.Index(fields=['created_at']),
        ]
        ordering = ['-last_message_at', '-created_at']
    
    def __str__(self):
        return f"{self.title} ({self.conversation_type})"
    
    def add_participant(self, user, role='participant'):
        """Add a new participant to the conversation."""
        participant, created = ConversationParticipant.objects.get_or_create(
            conversation=self,
            user=user,
            defaults={'role': role}
        )
        return participant
    
    def get_active_participants(self):
        """Get all active participants in the conversation."""
        return self.participants.filter(
            conversationparticipant__status='active',
            conversationparticipant__is_active=True
        )
    
    def can_user_access(self, user):
        """Check if a user can access this conversation."""
        return self.participants.filter(id=user.id).exists() or user.is_staff
    
    def archive_conversation(self):
        """Archive the conversation and all related data."""
        self.status = 'archived'
        self.save(update_fields=['status'])
        
        # Archive all participants
        self.conversationparticipant_set.update(status='inactive')


class ConversationParticipant(BaseModel):
    """Through model for conversation participants with roles and permissions."""
    
    ROLE_CHOICES = [
        ('owner', 'Owner'),
        ('admin', 'Administrator'),
        ('moderator', 'Moderator'),
        ('participant', 'Participant'),
        ('observer', 'Observer'),
        ('restricted', 'Restricted'),
    ]
    
    PARTICIPANT_STATUS = [
        ('active', 'Active'),
        ('inactive', 'Inactive'),
        ('banned', 'Banned'),
        ('left', 'Left'),
        ('kicked', 'Kicked'),
    ]
    
    conversation = models.ForeignKey(Conversation, on_delete=models.CASCADE)
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    role = models.CharField(max_length=20, choices=ROLE_CHOICES, default='participant')
    status = models.CharField(max_length=20, choices=PARTICIPANT_STATUS, default='active')
    
    # Permissions
    can_send_messages = models.BooleanField(default=True)
    can_share_files = models.BooleanField(default=True)
    can_invite_others = models.BooleanField(default=False)
    can_moderate_content = models.BooleanField(default=False)
    
    # Activity tracking
    joined_at = models.DateTimeField(default=timezone.now)
    last_read_at = models.DateTimeField(null=True, blank=True)
    last_active_at = models.DateTimeField(default=timezone.now)
    message_count = models.PositiveIntegerField(default=0)
    
    # Notification preferences
    notifications_enabled = models.BooleanField(default=True)
    email_notifications = models.BooleanField(default=False)
    
    # Moderation fields
    warning_count = models.PositiveIntegerField(default=0)
    banned_until = models.DateTimeField(null=True, blank=True)
    ban_reason = models.TextField(blank=True)
    
    class Meta:
        verbose_name = "Conversation Participant"
        verbose_name_plural = "Conversation Participants"
        unique_together = ['conversation', 'user']
        indexes = [
            models.Index(fields=['conversation', 'status']),
            models.Index(fields=['user', 'status']),
            models.Index(fields=['role']),
            models.Index(fields=['last_active_at']),
        ]
    
    def __str__(self):
        return f"{self.user.username} in {self.conversation.title} ({self.role})"
    
    def can_perform_action(self, action):
        """Check if participant can perform specific actions."""
        if self.status != 'active':
            return False
        
        permissions = {
            'send_message': self.can_send_messages,
            'share_file': self.can_share_files,
            'invite_user': self.can_invite_others,
            'moderate': self.can_moderate_content,
        }
        
        return permissions.get(action, False)
    
    def get_unread_count(self):
        """Get count of unread messages for this participant."""
        if not self.last_read_at:
            return self.conversation.total_messages
        
        from chat_messaging.models import Message
        return Message.objects.filter(
            conversation=self.conversation,
            created_at__gt=self.last_read_at,
            is_active=True
        ).count()
    
    def mark_as_read(self, timestamp=None):
        """Mark conversation as read up to timestamp."""
        self.last_read_at = timestamp or timezone.now()
        self.save(update_fields=['last_read_at'])


class ConversationInvite(BaseModel):
    """Invitations to join conversations."""
    
    INVITE_STATUS = [
        ('pending', 'Pending'),
        ('accepted', 'Accepted'),
        ('declined', 'Declined'),
        ('expired', 'Expired'),
        ('cancelled', 'Cancelled'),
    ]
    
    conversation = models.ForeignKey(Conversation, on_delete=models.CASCADE, related_name='invites')
    invited_by = models.ForeignKey(User, on_delete=models.CASCADE, related_name='sent_invites')
    invited_user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='received_invites')
    
    status = models.CharField(max_length=20, choices=INVITE_STATUS, default='pending')
    role = models.CharField(max_length=20, choices=ConversationParticipant.ROLE_CHOICES, default='participant')
    
    # Invitation details
    message = models.TextField(blank=True, help_text='Personal message with invitation')
    expires_at = models.DateTimeField(help_text='When this invitation expires')
    
    # Response tracking
    responded_at = models.DateTimeField(null=True, blank=True)
    response_message = models.TextField(blank=True)
    
    class Meta:
        verbose_name = "Conversation Invite"
        verbose_name_plural = "Conversation Invites"
        unique_together = ['conversation', 'invited_user']
        indexes = [
            models.Index(fields=['status']),
            models.Index(fields=['invited_user']),
            models.Index(fields=['expires_at']),
        ]
    
    def __str__(self):
        return f"Invite for {self.invited_user.username} to {self.conversation.title}"
    
    def is_expired(self):
        """Check if invitation has expired."""
        return timezone.now() > self.expires_at
    
    def accept(self, response_message=''):
        """Accept the invitation."""
        if self.is_expired() or self.status != 'pending':
            return False
        
        self.status = 'accepted'
        self.responded_at = timezone.now()
        self.response_message = response_message
        self.save()
        
        # Add user as participant
        self.conversation.add_participant(self.invited_user, self.role)
        return True
    
    def decline(self, response_message=''):
        """Decline the invitation."""
        if self.is_expired() or self.status != 'pending':
            return False
        
        self.status = 'declined'
        self.responded_at = timezone.now()
        self.response_message = response_message
        self.save()
        return True


class ConversationTag(BaseModel):
    """Tags for categorizing and organizing conversations."""
    
    name = models.CharField(max_length=50, unique=True)
    description = models.TextField(blank=True)
    color = models.CharField(max_length=7, default='#007bff', help_text='Hex color code')
    is_system_tag = models.BooleanField(default=False, help_text='System-managed tag')
    usage_count = models.PositiveIntegerField(default=0)
    
    class Meta:
        verbose_name = "Conversation Tag"
        verbose_name_plural = "Conversation Tags"
        ordering = ['name']
    
    def __str__(self):
        return self.name


class ConversationTagAssignment(BaseModel):
    """Assignment of tags to conversations."""
    
    conversation = models.ForeignKey(Conversation, on_delete=models.CASCADE, related_name='tag_assignments')
    tag = models.ForeignKey(ConversationTag, on_delete=models.CASCADE, related_name='assignments')
    assigned_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, related_name='assigned_tags')
    
    class Meta:
        verbose_name = "Conversation Tag Assignment"
        verbose_name_plural = "Conversation Tag Assignments"
        unique_together = ['conversation', 'tag']
    
    def __str__(self):
        return f"{self.tag.name} -> {self.conversation.title}"


class ConversationBookmark(BaseModel):
    """User bookmarks for important conversations."""
    
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='conversation_bookmarks')
    conversation = models.ForeignKey(Conversation, on_delete=models.CASCADE, related_name='bookmarks')
    note = models.TextField(blank=True, help_text='Personal note about this bookmark')
    
    class Meta:
        verbose_name = "Conversation Bookmark"
        verbose_name_plural = "Conversation Bookmarks"
        unique_together = ['user', 'conversation']
        ordering = ['-created_at']
    
    def __str__(self):
        return f"{self.user.username} bookmarked {self.conversation.title}"
