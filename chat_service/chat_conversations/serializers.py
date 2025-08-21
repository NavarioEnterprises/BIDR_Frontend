"""
Serializers for chat_conversations app API endpoints.
"""

from rest_framework import serializers
from django.contrib.auth.models import User
from chat_core.serializers import UserSerializer
from .models import (
    Conversation, ConversationParticipant, ConversationBookmark,
    ConversationInvite, ConversationTemplate, ConversationMetrics
)


class ConversationParticipantSerializer(serializers.ModelSerializer):
    """Conversation participant serializer."""
    user = UserSerializer(read_only=True)
    
    class Meta:
        model = ConversationParticipant
        fields = [
            'id', 'user', 'role', 'joined_at', 'left_at', 'is_muted',
            'notification_level', 'permissions', 'custom_title', 'invite_code',
            'last_read_at', 'unread_count', 'is_active'
        ]
        read_only_fields = ['id', 'user', 'joined_at', 'invite_code', 'unread_count']


class ConversationBookmarkSerializer(serializers.ModelSerializer):
    """Conversation bookmark serializer."""
    user = UserSerializer(read_only=True)
    
    class Meta:
        model = ConversationBookmark
        fields = ['id', 'user', 'conversation', 'label', 'created_at']
        read_only_fields = ['id', 'user', 'created_at']


class ConversationInviteSerializer(serializers.ModelSerializer):
    """Conversation invite serializer."""
    invited_by = UserSerializer(read_only=True)
    invited_user = UserSerializer(read_only=True)
    
    class Meta:
        model = ConversationInvite
        fields = [
            'id', 'conversation', 'invited_by', 'invited_user', 'invite_code',
            'status', 'expires_at', 'accepted_at', 'declined_at', 'message',
            'max_uses', 'use_count', 'created_at'
        ]
        read_only_fields = [
            'id', 'invited_by', 'invite_code', 'accepted_at', 'declined_at',
            'use_count', 'created_at'
        ]


class ConversationMetricsSerializer(serializers.ModelSerializer):
    """Conversation metrics serializer."""
    
    class Meta:
        model = ConversationMetrics
        fields = [
            'id', 'conversation', 'total_messages', 'total_participants',
            'active_participants_24h', 'average_response_time_minutes',
            'peak_activity_hour', 'last_activity_at', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']


class ConversationSerializer(serializers.ModelSerializer):
    """Full conversation serializer with all related data."""
    buyer = UserSerializer(read_only=True)
    seller = UserSerializer(read_only=True)
    participants = ConversationParticipantSerializer(many=True, read_only=True)
    bookmarks = ConversationBookmarkSerializer(many=True, read_only=True)
    metrics = ConversationMetricsSerializer(read_only=True)
    participant_count = serializers.SerializerMethodField()
    user_role = serializers.SerializerMethodField()
    is_user_participant = serializers.SerializerMethodField()
    last_message_preview = serializers.SerializerMethodField()
    
    class Meta:
        model = Conversation
        fields = [
            'id', 'title', 'description', 'conversation_type', 'status',
            'buyer', 'seller', 'auction_id', 'category', 'tags', 'is_encrypted',
            'encryption_key_id', 'is_archived', 'archived_reason', 'archived_by',
            'archived_at', 'total_messages', 'last_message_at', 'participants',
            'bookmarks', 'metrics', 'participant_count', 'user_role',
            'is_user_participant', 'last_message_preview', 'metadata',
            'is_active', 'created_at', 'updated_at'
        ]
        read_only_fields = [
            'id', 'buyer', 'seller', 'total_messages', 'last_message_at',
            'participants', 'bookmarks', 'metrics', 'participant_count',
            'user_role', 'is_user_participant', 'last_message_preview',
            'is_active', 'created_at', 'updated_at'
        ]
    
    def get_participant_count(self, obj):
        return obj.participants.filter(is_active=True).count()
    
    def get_user_role(self, obj):
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            participant = obj.participants.filter(user=request.user).first()
            return participant.role if participant else None
        return None
    
    def get_is_user_participant(self, obj):
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            return obj.participants.filter(user=request.user, is_active=True).exists()
        return False
    
    def get_last_message_preview(self, obj):
        last_message = obj.messages.filter(is_active=True).last()
        if last_message:
            return {
                'id': last_message.id,
                'content': last_message.content[:100],  # Truncated
                'sender': last_message.sender.username,
                'message_type': last_message.message_type,
                'created_at': last_message.created_at
            }
        return None


class ConversationCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating conversations."""
    
    class Meta:
        model = Conversation
        fields = [
            'title', 'description', 'conversation_type', 'seller',
            'auction_id', 'category', 'tags', 'metadata'
        ]
    
    def create(self, validated_data):
        # Set the buyer as the request user
        validated_data['buyer'] = self.context['request'].user
        conversation = super().create(validated_data)
        
        # Create participant record for the buyer
        ConversationParticipant.objects.create(
            conversation=conversation,
            user=conversation.buyer,
            role='owner'
        )
        
        # Create participant record for the seller if specified
        if conversation.seller:
            ConversationParticipant.objects.create(
                conversation=conversation,
                user=conversation.seller,
                role='participant'
            )
        
        return conversation


class ConversationUpdateSerializer(serializers.ModelSerializer):
    """Serializer for updating conversations (limited fields)."""
    
    class Meta:
        model = Conversation
        fields = ['title', 'description', 'tags', 'metadata']


class ConversationListSerializer(serializers.ModelSerializer):
    """Lightweight serializer for conversation lists."""
    buyer = UserSerializer(read_only=True)
    seller = UserSerializer(read_only=True)
    participant_count = serializers.SerializerMethodField()
    unread_count = serializers.SerializerMethodField()
    last_message_preview = serializers.SerializerMethodField()
    
    class Meta:
        model = Conversation
        fields = [
            'id', 'title', 'conversation_type', 'status', 'buyer', 'seller',
            'total_messages', 'last_message_at', 'participant_count',
            'unread_count', 'last_message_preview', 'is_archived', 'created_at'
        ]
        read_only_fields = ['id', 'created_at']
    
    def get_participant_count(self, obj):
        return obj.participants.filter(is_active=True).count()
    
    def get_unread_count(self, obj):
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            participant = obj.participants.filter(user=request.user).first()
            if participant and participant.last_read_at:
                return obj.messages.filter(
                    created_at__gt=participant.last_read_at,
                    is_active=True
                ).count()
        return 0
    
    def get_last_message_preview(self, obj):
        last_message = obj.messages.filter(is_active=True).last()
        if last_message:
            return {
                'content': last_message.content[:50],  # Shorter preview for list
                'sender': last_message.sender.username,
                'created_at': last_message.created_at
            }
        return None


class ConversationTemplateSerializer(serializers.ModelSerializer):
    """Conversation template serializer."""
    created_by = UserSerializer(read_only=True)
    
    class Meta:
        model = ConversationTemplate
        fields = [
            'id', 'name', 'description', 'template_category', 'conversation_type',
            'title_template', 'description_template', 'default_tags',
            'auto_messages', 'settings', 'is_public', 'usage_count',
            'created_by', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'usage_count', 'created_by', 'created_at', 'updated_at']
