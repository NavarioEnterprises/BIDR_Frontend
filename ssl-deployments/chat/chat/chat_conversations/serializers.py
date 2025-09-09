"""
Serializers for chat_conversations app API endpoints.
"""

from rest_framework import serializers
from django.contrib.auth.models import User
from .models import Conversation, ConversationParticipant, ConversationBookmark, ConversationInvite


class UserSerializer(serializers.ModelSerializer):
    """Simple User serializer."""
    
    class Meta:
        model = User
        fields = ['id', 'username', 'first_name', 'last_name', 'email']
        read_only_fields = ['id']


class ConversationParticipantSerializer(serializers.ModelSerializer):
    """Conversation participant serializer."""
    user = UserSerializer(read_only=True)
    
    class Meta:
        model = ConversationParticipant
        fields = [
            'id', 'user', 'role', 'status', 'joined_at', 'last_read_at', 
            'last_active_at', 'message_count', 'can_send_messages', 
            'can_share_files', 'notifications_enabled'
        ]
        read_only_fields = ['id', 'user', 'joined_at', 'message_count']


class ConversationBookmarkSerializer(serializers.ModelSerializer):
    """Conversation bookmark serializer."""
    user = UserSerializer(read_only=True)
    
    class Meta:
        model = ConversationBookmark
        fields = ['id', 'user', 'conversation', 'note', 'created_at']
        read_only_fields = ['id', 'user', 'created_at']


class ConversationInviteSerializer(serializers.ModelSerializer):
    """Conversation invite serializer."""
    invited_by = UserSerializer(read_only=True)
    invited_user = UserSerializer(read_only=True)
    
    class Meta:
        model = ConversationInvite
        fields = [
            'id', 'conversation', 'invited_by', 'invited_user', 'status',
            'expires_at', 'responded_at', 'message', 'response_message', 'created_at'
        ]
        read_only_fields = [
            'id', 'invited_by', 'responded_at', 'created_at'
        ]


class ConversationSerializer(serializers.ModelSerializer):
    """Full conversation serializer with all related data."""
    buyer = UserSerializer(read_only=True)
    participants_details = ConversationParticipantSerializer(
        source='conversationparticipant_set',
        many=True,
        read_only=True
    )
    participant_count = serializers.SerializerMethodField()
    unread_count = serializers.SerializerMethodField()
    
    class Meta:
        model = Conversation
        fields = [
            'id', 'title', 'conversation_type', 'status', 'buyer',
            'request_id', 'product_request_id', 'quote_id',
            'allow_new_participants', 'is_bidding_enabled',
            'is_moderated', 'requires_approval', 'last_message_at',
            'total_messages', 'is_encrypted', 'created_at', 'updated_at',
            'participants_details', 'participant_count', 'unread_count'
        ]
        read_only_fields = ['id', 'buyer', 'total_messages', 'last_message_at', 'created_at', 'updated_at']
    
    def get_participant_count(self, obj):
        """Get the number of active participants."""
        return obj.get_active_participants().count()
    
    def get_unread_count(self, obj):
        """Get unread message count for the current user."""
        request = self.context.get('request')
        if not request or not request.user.is_authenticated:
            return 0
        
        try:
            participant = ConversationParticipant.objects.get(
                conversation=obj,
                user=request.user,
                status='active'
            )
            return participant.get_unread_count()
        except ConversationParticipant.DoesNotExist:
            return 0


class ConversationCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating conversations."""
    
    class Meta:
        model = Conversation
        fields = [
            'title', 'conversation_type', 'request_id', 'product_request_id',
            'quote_id', 'allow_new_participants', 'is_bidding_enabled',
            'is_moderated', 'requires_approval', 'is_encrypted'
        ]
    
    def validate_title(self, value):
        """Validate conversation title."""
        if len(value.strip()) < 3:
            raise serializers.ValidationError("Title must be at least 3 characters long.")
        return value.strip()
