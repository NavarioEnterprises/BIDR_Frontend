"""
Serializers for chat_core app API endpoints.
"""

from rest_framework import serializers
from django.contrib.auth.models import User
from .models import (
    UserProfile, SystemConfig, AuditLog, TranslationCache,
    ContentFilterRule, ModerationQueue, LanguagePreference
)


class UserSerializer(serializers.ModelSerializer):
    """Basic user serializer."""
    class Meta:
        model = User
        fields = ['id', 'username', 'email', 'first_name', 'last_name', 'date_joined']
        read_only_fields = ['id', 'date_joined']


class UserProfileSerializer(serializers.ModelSerializer):
    """User profile serializer with nested user data."""
    user = UserSerializer(read_only=True)
    is_online = serializers.SerializerMethodField()
    can_send_messages = serializers.SerializerMethodField()
    
    class Meta:
        model = UserProfile
        fields = [
            'id', 'user', 'role', 'verification_status', 'display_name', 'avatar',
            'bio', 'location', 'allow_direct_messages', 'show_online_status',
            'allow_read_receipts', 'mask_personal_info', 'company_name',
            'business_registration_number', 'phone_number', 'business_email',
            'website_url', 'status', 'is_banned', 'ban_reason', 'ban_expires_at',
            'warning_count', 'total_conversations', 'total_messages_sent',
            'average_response_time_minutes', 'reputation_score', 'last_seen',
            'last_activity', 'is_online', 'can_send_messages', 'created_at',
            'updated_at'
        ]
        read_only_fields = [
            'id', 'user', 'total_conversations', 'total_messages_sent',
            'average_response_time_minutes', 'reputation_score', 'last_seen',
            'last_activity', 'is_online', 'can_send_messages', 'created_at',
            'updated_at'
        ]
    
    def get_is_online(self, obj):
        return obj.is_online()
    
    def get_can_send_messages(self, obj):
        return obj.can_send_messages()


class UserProfileCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating user profiles."""
    class Meta:
        model = UserProfile
        fields = [
            'role', 'display_name', 'bio', 'location', 'allow_direct_messages',
            'show_online_status', 'allow_read_receipts', 'mask_personal_info',
            'company_name', 'business_registration_number', 'phone_number',
            'business_email', 'website_url'
        ]


class SystemConfigSerializer(serializers.ModelSerializer):
    """System configuration serializer."""
    parsed_value = serializers.SerializerMethodField()
    
    class Meta:
        model = SystemConfig
        fields = [
            'id', 'category', 'key', 'value', 'parsed_value', 'description',
            'is_system_managed', 'is_user_configurable', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'parsed_value', 'created_at', 'updated_at']
    
    def get_parsed_value(self, obj):
        return SystemConfig.get_config(obj.category, obj.key, obj.value)


class AuditLogSerializer(serializers.ModelSerializer):
    """Audit log serializer."""
    user = UserSerializer(read_only=True)
    
    class Meta:
        model = AuditLog
        fields = [
            'id', 'user', 'action_type', 'resource_type', 'resource_id',
            'details', 'ip_address', 'user_agent', 'severity', 'created_at'
        ]
        read_only_fields = ['id', 'created_at']


class TranslationCacheSerializer(serializers.ModelSerializer):
    """Translation cache serializer."""
    class Meta:
        model = TranslationCache
        fields = [
            'id', 'source_text', 'source_language', 'target_language',
            'translated_text', 'translation_service', 'confidence_score',
            'usage_count', 'last_used', 'created_at'
        ]
        read_only_fields = ['id', 'usage_count', 'last_used', 'created_at']


class ContentFilterRuleSerializer(serializers.ModelSerializer):
    """Content filter rule serializer."""
    class Meta:
        model = ContentFilterRule
        fields = [
            'id', 'name', 'rule_type', 'pattern', 'action', 'severity',
            'is_enabled', 'language_codes', 'replacement_text', 'trigger_count',
            'last_triggered', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'trigger_count', 'last_triggered', 'created_at', 'updated_at']


class ModerationQueueSerializer(serializers.ModelSerializer):
    """Moderation queue serializer."""
    reported_by = UserSerializer(read_only=True)
    assigned_to = UserSerializer(read_only=True)
    
    class Meta:
        model = ModerationQueue
        fields = [
            'id', 'content_type', 'content_id', 'reported_by', 'assigned_to',
            'status', 'priority', 'reason', 'content_snapshot', 'moderator_notes',
            'decision_reason', 'processed_at', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'reported_by', 'created_at', 'updated_at']


class LanguagePreferenceSerializer(serializers.ModelSerializer):
    """Language preference serializer."""
    user = UserSerializer(read_only=True)
    
    class Meta:
        model = LanguagePreference
        fields = [
            'id', 'user', 'primary_language', 'secondary_languages',
            'auto_translate_enabled', 'translate_from_languages', 'show_original_text',
            'date_format', 'time_format', 'timezone', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'user', 'created_at', 'updated_at']
