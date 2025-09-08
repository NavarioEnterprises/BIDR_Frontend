"""
Serializers for chat_messaging app API endpoints.
"""

from rest_framework import serializers
from django.contrib.auth.models import User
from django.utils import timezone
from chat_core.serializers import UserSerializer
from .models import (
    Message, MessageAttachment, MessageReaction, MessageReadReceipt,
    MessageTranslation, MessageMention, TypingIndicator, MessageDeletion
)


class MessageAttachmentSerializer(serializers.ModelSerializer):
    """Message attachment serializer."""
    file_size_display = serializers.SerializerMethodField()
    file_url = serializers.SerializerMethodField()
    
    class Meta:
        model = MessageAttachment
        fields = [
            'id', 'filename', 'file_size', 'file_size_display', 'file_type',
            'mime_type', 'width', 'height', 'duration', 'is_scanned',
            'scan_result', 'is_public', 'download_count', 'file_hash',
            'thumbnail', 'file_url', 'created_at'
        ]
        read_only_fields = [
            'id', 'file_size_display', 'is_scanned', 'scan_result', 
            'download_count', 'file_hash', 'created_at'
        ]
    
    def get_file_size_display(self, obj):
        return obj.get_file_size_display()
    
    def get_file_url(self, obj):
        if obj.file:
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(obj.file.url)
            return obj.file.url
        return None


class MessageReactionSerializer(serializers.ModelSerializer):
    """Message reaction serializer."""
    user = UserSerializer(read_only=True)
    
    class Meta:
        model = MessageReaction
        fields = ['id', 'user', 'reaction_type', 'created_at']
        read_only_fields = ['id', 'user', 'created_at']


class MessageMentionSerializer(serializers.ModelSerializer):
    """Message mention serializer."""
    mentioned_user = UserSerializer(read_only=True)
    
    class Meta:
        model = MessageMention
        fields = [
            'id', 'mentioned_user', 'mention_text', 'position_start',
            'position_end', 'notification_sent', 'notification_read'
        ]
        read_only_fields = ['id', 'mentioned_user', 'notification_sent', 'notification_read']


class MessageTranslationSerializer(serializers.ModelSerializer):
    """Message translation serializer."""
    class Meta:
        model = MessageTranslation
        fields = [
            'id', 'target_language', 'translated_content', 'translation_service',
            'confidence_score', 'source_language', 'is_auto_translation',
            'human_reviewed', 'created_at'
        ]
        read_only_fields = ['id', 'created_at']


class MessageReadReceiptSerializer(serializers.ModelSerializer):
    """Message read receipt serializer."""
    user = UserSerializer(read_only=True)
    
    class Meta:
        model = MessageReadReceipt
        fields = ['id', 'user', 'read_at']
        read_only_fields = ['id', 'user', 'read_at']


class MessageSerializer(serializers.ModelSerializer):
    """Message serializer with all related data."""
    sender = UserSerializer(read_only=True)
    attachments = MessageAttachmentSerializer(many=True, read_only=True)
    reactions = MessageReactionSerializer(many=True, read_only=True)
    mentions = MessageMentionSerializer(many=True, read_only=True)
    translations = MessageTranslationSerializer(many=True, read_only=True)
    read_receipts = MessageReadReceiptSerializer(many=True, read_only=True)
    read_by_count = serializers.SerializerMethodField()
    is_read_by_user = serializers.SerializerMethodField()
    reply_to_message = serializers.SerializerMethodField()
    
    class Meta:
        model = Message
        fields = [
            'id', 'sender', 'sender_name', 'sender_role', 'conversation', 'message_type', 'content',
            'original_content', 'reply_to', 'reply_to_message', 'thread_id',
            'delivery_status', 'is_edited', 'edited_at', 'is_flagged',
            'flagged_reason', 'is_auto_moderated', 'moderation_action',
            'is_encrypted', 'encryption_key_id', 'reaction_count',
            'client_message_id', 'message_hash', 'external_reference',
            'metadata', 'attachments', 'reactions', 'mentions', 'translations',
            'read_receipts', 'read_by_count', 'is_read_by_user', 'is_active',
            'created_at', 'updated_at'
        ]
        read_only_fields = [
            'id', 'sender', 'original_content', 'thread_id', 'is_edited',
            'edited_at', 'is_flagged', 'flagged_reason', 'is_auto_moderated',
            'moderation_action', 'is_encrypted', 'encryption_key_id',
            'reaction_count', 'message_hash', 'attachments', 'reactions',
            'mentions', 'translations', 'read_receipts', 'read_by_count',
            'is_read_by_user', 'reply_to_message', 'created_at', 'updated_at'
        ]
    
    def get_read_by_count(self, obj):
        return obj.read_receipts.count()
    
    def get_is_read_by_user(self, obj):
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            return obj.read_receipts.filter(user=request.user).exists()
        return False
    
    def get_reply_to_message(self, obj):
        if obj.reply_to:
            sender_name = obj.reply_to.sender.username if obj.reply_to.sender else "Anonymous"
            return {
                'id': obj.reply_to.id,
                'content': obj.reply_to.content[:100],  # Truncated content
                'sender': sender_name,
                'created_at': obj.reply_to.created_at
            }
        return None


class MessageCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating messages."""
    
    class Meta:
        model = Message
        fields = [
            'conversation', 'message_type', 'content', 'sender_name', 'sender_role', 'reply_to',
            'client_message_id', 'external_reference', 'metadata'
        ]
    
    def create(self, validated_data):
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            validated_data['sender'] = request.user
            # If sender_name not provided, use authenticated user's username
            if not validated_data.get('sender_name'):
                validated_data['sender_name'] = request.user.username
        # For unauthenticated users, sender will be None (which should be allowed)
        # sender_name and sender_role should be provided in the request data
        return super().create(validated_data)


class MessageUpdateSerializer(serializers.ModelSerializer):
    """Serializer for updating messages (limited fields)."""
    
    class Meta:
        model = Message
        fields = ['content', 'metadata']
    
    def update(self, instance, validated_data):
        # Track editing
        if 'content' in validated_data and validated_data['content'] != instance.content:
            instance.original_content = instance.content
            instance.is_edited = True
            instance.edited_at = timezone.now()
        
        return super().update(instance, validated_data)


class TypingIndicatorSerializer(serializers.ModelSerializer):
    """Typing indicator serializer."""
    user = UserSerializer(read_only=True)
    is_stale = serializers.SerializerMethodField()
    
    class Meta:
        model = TypingIndicator
        fields = [
            'id', 'user', 'conversation', 'is_typing', 'last_typing_at',
            'is_stale', 'created_at'
        ]
        read_only_fields = ['id', 'user', 'is_stale', 'created_at']
    
    def get_is_stale(self, obj):
        return obj.is_stale()


class MessageDeletionSerializer(serializers.ModelSerializer):
    """Message deletion serializer for audit purposes."""
    deleted_by = UserSerializer(read_only=True)
    
    class Meta:
        model = MessageDeletion
        fields = [
            'id', 'deleted_by', 'deletion_reason', 'deletion_details',
            'content_snapshot', 'metadata_snapshot', 'created_at'
        ]
        read_only_fields = ['id', 'deleted_by', 'content_snapshot', 'metadata_snapshot', 'created_at']
