from django.db import models
from django.contrib.auth.models import User
from django.utils import timezone
from django.core.validators import FileExtensionValidator
from chat_core.models import BaseModel, StatusChoices
from chat_conversations.models import Conversation
import uuid
import hashlib


class Message(BaseModel):
    """Core message model for chat communications."""
    
    MESSAGE_TYPES = [
        ('text', 'Text Message'),
        ('image', 'Image'),
        ('file', 'File Attachment'),
        ('audio', 'Audio Message'),
        ('video', 'Video'),
        ('location', 'Location'),
        ('contact', 'Contact Info'),
        ('quote', 'Quote/Bid'),
        ('system', 'System Message'),
        ('notification', 'Notification'),
    ]
    
    DELIVERY_STATUS = [
        ('sent', 'Sent'),
        ('delivered', 'Delivered'),
        ('read', 'Read'),
        ('failed', 'Failed'),
    ]
    
    # Core message data
    conversation = models.ForeignKey(Conversation, on_delete=models.CASCADE, related_name='messages')
    sender = models.ForeignKey(User, on_delete=models.CASCADE, related_name='sent_messages')
    message_type = models.CharField(max_length=20, choices=MESSAGE_TYPES, default='text')
    
    # Message content
    content = models.TextField(help_text='Main message content')
    original_content = models.TextField(blank=True, help_text='Original content before moderation')
    
    # Message metadata
    reply_to = models.ForeignKey('self', on_delete=models.SET_NULL, null=True, blank=True, related_name='replies')
    thread_id = models.UUIDField(null=True, blank=True, help_text='Thread identifier for grouped messages')
    
    # Delivery and status
    delivery_status = models.CharField(max_length=20, choices=DELIVERY_STATUS, default='sent')
    is_edited = models.BooleanField(default=False)
    edited_at = models.DateTimeField(null=True, blank=True)
    
    # Moderation flags
    is_flagged = models.BooleanField(default=False)
    flagged_reason = models.TextField(blank=True)
    is_auto_moderated = models.BooleanField(default=False)
    moderation_action = models.CharField(max_length=50, blank=True)
    
    # Privacy and security
    is_encrypted = models.BooleanField(default=False)
    encryption_key_id = models.CharField(max_length=100, blank=True)
    
    # Message reactions and interactions
    reaction_count = models.PositiveIntegerField(default=0)
    
    # Technical metadata
    client_message_id = models.CharField(max_length=100, blank=True, help_text='Client-side message ID')
    message_hash = models.CharField(max_length=64, blank=True, help_text='Content hash for deduplication')
    
    # External integration
    external_reference = models.CharField(max_length=100, blank=True, null=True)
    metadata = models.JSONField(default=dict, blank=True)
    
    class Meta:
        verbose_name = "Message"
        verbose_name_plural = "Messages"
        indexes = [
            models.Index(fields=['conversation', 'created_at']),
            models.Index(fields=['sender', 'created_at']),
            models.Index(fields=['message_type']),
            models.Index(fields=['delivery_status']),
            models.Index(fields=['is_flagged']),
            models.Index(fields=['thread_id']),
            models.Index(fields=['client_message_id']),
            models.Index(fields=['message_hash']),
        ]
        ordering = ['created_at']
    
    def __str__(self):
        content_preview = self.content[:50] + '...' if len(self.content) > 50 else self.content
        return f"{self.sender.username}: {content_preview}"
    
    def save(self, *args, **kwargs):
        # Generate message hash for deduplication
        if not self.message_hash and self.content:
            # Include timestamp to ensure uniqueness
            timestamp = timezone.now().isoformat()
            content_for_hash = f"{self.sender.id}:{self.conversation.id}:{self.content}:{timestamp}"
            self.message_hash = hashlib.sha256(content_for_hash.encode()).hexdigest()
        
        # Set thread_id if this is a reply
        if self.reply_to and not self.thread_id:
            self.thread_id = self.reply_to.thread_id or self.reply_to.id
        
        super().save(*args, **kwargs)
        
        # Update conversation last message timestamp
        self.conversation.last_message_at = self.created_at
        self.conversation.total_messages = self.conversation.messages.filter(is_active=True).count()
        self.conversation.save(update_fields=['last_message_at', 'total_messages'])
    
    def mark_as_read(self, user):
        """Mark message as read by a user."""
        read_receipt, created = MessageReadReceipt.objects.get_or_create(
            message=self,
            user=user,
            defaults={'read_at': timezone.now()}
        )
        return read_receipt
    
    def get_read_by_users(self):
        """Get list of users who have read this message."""
        return User.objects.filter(
            read_receipts__message=self
        ).distinct()
    
    def soft_delete(self, deleted_by=None):
        """Soft delete the message."""
        self.is_active = False
        self.save(update_fields=['is_active'])
        
        # Log the deletion
        MessageDeletion.objects.create(
            message=self,
            deleted_by=deleted_by,
            deletion_reason='user_requested'
        )


class MessageAttachment(BaseModel):
    """File attachments for messages."""
    
    ATTACHMENT_TYPES = [
        ('image', 'Image'),
        ('video', 'Video'),
        ('audio', 'Audio'),
        ('document', 'Document'),
        ('archive', 'Archive'),
        ('other', 'Other'),
    ]
    
    message = models.ForeignKey(Message, on_delete=models.CASCADE, related_name='attachments')
    file = models.FileField(upload_to='chat_attachments/%Y/%m/%d/')
    filename = models.CharField(max_length=255)
    file_size = models.PositiveIntegerField(help_text='File size in bytes')
    file_type = models.CharField(max_length=20, choices=ATTACHMENT_TYPES)
    mime_type = models.CharField(max_length=100)
    
    # File metadata
    width = models.PositiveIntegerField(null=True, blank=True, help_text='Image/video width')
    height = models.PositiveIntegerField(null=True, blank=True, help_text='Image/video height')
    duration = models.PositiveIntegerField(null=True, blank=True, help_text='Audio/video duration in seconds')
    
    # Security
    is_scanned = models.BooleanField(default=False)
    scan_result = models.CharField(max_length=20, choices=[
        ('clean', 'Clean'),
        ('suspicious', 'Suspicious'),
        ('malicious', 'Malicious'),
        ('error', 'Scan Error'),
    ], blank=True)
    
    # Privacy
    is_public = models.BooleanField(default=False)
    download_count = models.PositiveIntegerField(default=0)
    
    # Technical
    file_hash = models.CharField(max_length=64, blank=True, help_text='SHA-256 hash of file')
    thumbnail = models.ImageField(upload_to='thumbnails/', null=True, blank=True)
    
    class Meta:
        verbose_name = "Message Attachment"
        verbose_name_plural = "Message Attachments"
        indexes = [
            models.Index(fields=['message']),
            models.Index(fields=['file_type']),
            models.Index(fields=['file_hash']),
        ]
    
    def __str__(self):
        return f"{self.filename} ({self.get_file_type_display()})"
    
    def get_file_size_display(self):
        """Human readable file size."""
        for unit in ['B', 'KB', 'MB', 'GB']:
            if self.file_size < 1024.0:
                return f"{self.file_size:.1f} {unit}"
            self.file_size /= 1024.0
        return f"{self.file_size:.1f} TB"


class MessageReaction(BaseModel):
    """User reactions to messages (like, love, laugh, etc.)."""
    
    REACTION_TYPES = [
        ('like', '👍'),
        ('love', '❤️'),
        ('laugh', '😂'),
        ('wow', '😮'),
        ('sad', '😢'),
        ('angry', '😠'),
    ]
    
    message = models.ForeignKey(Message, on_delete=models.CASCADE, related_name='reactions')
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='message_reactions')
    reaction_type = models.CharField(max_length=10, choices=REACTION_TYPES)
    
    class Meta:
        verbose_name = "Message Reaction"
        verbose_name_plural = "Message Reactions"
        unique_together = ['message', 'user', 'reaction_type']
        indexes = [
            models.Index(fields=['message']),
            models.Index(fields=['user']),
        ]
    
    def __str__(self):
        return f"{self.user.username} reacted {self.get_reaction_type_display()} to message"


class MessageReadReceipt(BaseModel):
    """Track which users have read which messages."""
    
    message = models.ForeignKey(Message, on_delete=models.CASCADE, related_name='read_receipts')
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='read_receipts')
    read_at = models.DateTimeField(default=timezone.now)
    
    class Meta:
        verbose_name = "Message Read Receipt"
        verbose_name_plural = "Message Read Receipts"
        unique_together = ['message', 'user']
        indexes = [
            models.Index(fields=['message']),
            models.Index(fields=['user', 'read_at']),
        ]
    
    def __str__(self):
        return f"{self.user.username} read message at {self.read_at}"


class MessageDeletion(BaseModel):
    """Track message deletions for audit purposes."""
    
    DELETION_REASONS = [
        ('user_requested', 'User Requested'),
        ('moderation', 'Content Moderation'),
        ('admin_action', 'Admin Action'),
        ('system_cleanup', 'System Cleanup'),
        ('privacy_request', 'Privacy Request'),
    ]
    
    message = models.ForeignKey(Message, on_delete=models.CASCADE, related_name='deletions')
    deleted_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, related_name='deleted_messages')
    deletion_reason = models.CharField(max_length=30, choices=DELETION_REASONS)
    deletion_details = models.TextField(blank=True)
    
    # Snapshot of deleted content for audit
    content_snapshot = models.TextField(help_text='Snapshot of message content at deletion')
    metadata_snapshot = models.JSONField(default=dict, blank=True)
    
    class Meta:
        verbose_name = "Message Deletion"
        verbose_name_plural = "Message Deletions"
        indexes = [
            models.Index(fields=['message']),
            models.Index(fields=['deleted_by']),
            models.Index(fields=['deletion_reason']),
        ]
    
    def __str__(self):
        return f"Deleted message by {self.deleted_by} - {self.get_deletion_reason_display()}"


class MessageTranslation(BaseModel):
    """Translations of messages to different languages."""
    
    message = models.ForeignKey(Message, on_delete=models.CASCADE, related_name='translations')
    target_language = models.CharField(max_length=10, help_text='Language code (e.g., en, es, fr)')
    translated_content = models.TextField()
    translation_service = models.CharField(max_length=50, default='google')
    confidence_score = models.DecimalField(max_digits=5, decimal_places=4, null=True, blank=True)
    
    # Translation metadata
    source_language = models.CharField(max_length=10, help_text='Detected source language')
    is_auto_translation = models.BooleanField(default=True)
    human_reviewed = models.BooleanField(default=False)
    
    class Meta:
        verbose_name = "Message Translation"
        verbose_name_plural = "Message Translations"
        unique_together = ['message', 'target_language']
        indexes = [
            models.Index(fields=['message']),
            models.Index(fields=['target_language']),
        ]
    
    def __str__(self):
        return f"Translation of message to {self.target_language}"


class MessageMention(BaseModel):
    """User mentions within messages (@username)."""
    
    message = models.ForeignKey(Message, on_delete=models.CASCADE, related_name='mentions')
    mentioned_user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='message_mentions')
    mention_text = models.CharField(max_length=100, help_text='The actual mention text used')
    position_start = models.PositiveIntegerField(help_text='Start position in message content')
    position_end = models.PositiveIntegerField(help_text='End position in message content')
    
    # Notification tracking
    notification_sent = models.BooleanField(default=False)
    notification_read = models.BooleanField(default=False)
    
    class Meta:
        verbose_name = "Message Mention"
        verbose_name_plural = "Message Mentions"
        indexes = [
            models.Index(fields=['message']),
            models.Index(fields=['mentioned_user']),
        ]
    
    def __str__(self):
        return f"@{self.mentioned_user.username} mentioned in message"


class TypingIndicator(BaseModel):
    """Real-time typing indicators."""
    
    conversation = models.ForeignKey(Conversation, on_delete=models.CASCADE, related_name='typing_indicators')
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='typing_indicators')
    is_typing = models.BooleanField(default=True)
    last_typing_at = models.DateTimeField(default=timezone.now)
    
    class Meta:
        verbose_name = "Typing Indicator"
        verbose_name_plural = "Typing Indicators"
        unique_together = ['conversation', 'user']
        indexes = [
            models.Index(fields=['conversation', 'is_typing']),
            models.Index(fields=['last_typing_at']),
        ]
    
    def __str__(self):
        return f"{self.user.username} typing in {self.conversation.title}"
    
    def is_stale(self, seconds=10):
        """Check if typing indicator is stale."""
        return (timezone.now() - self.last_typing_at).seconds > seconds
