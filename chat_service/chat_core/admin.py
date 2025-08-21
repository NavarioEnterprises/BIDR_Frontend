"""
Django admin configuration for Chat Core models.
"""

from django.contrib import admin
from django.utils.html import format_html
from .models import (
    UserProfile, SystemConfig, AuditLog, TranslationCache,
    ContentFilterRule, ModerationQueue, LanguagePreference
)


@admin.register(UserProfile)
class UserProfileAdmin(admin.ModelAdmin):
    """Admin interface for UserProfile model."""
    
    list_display = [
        'user', 'role', 'verification_status', 'display_name',
        'is_online_display', 'status', 'is_banned', 'warning_count',
        'reputation_score', 'total_conversations', 'created_at'
    ]
    
    list_filter = [
        'role', 'verification_status', 'status', 'is_banned',
        'created_at', 'last_seen'
    ]
    
    search_fields = [
        'user__username', 'user__email', 'display_name',
        'company_name', 'phone_number'
    ]
    
    readonly_fields = [
        'id', 'created_at', 'updated_at', 'last_seen', 'last_activity',
        'total_conversations', 'total_messages_sent',
        'average_response_time_minutes'
    ]
    
    def is_online_display(self, obj):
        """Display online status with colored indicator."""
        if obj.is_online():
            return format_html(
                '<span style="color: green;">● Online</span>'
            )
        else:
            return format_html(
                '<span style="color: gray;">○ Offline</span>'
            )
    is_online_display.short_description = 'Online Status'


@admin.register(SystemConfig)
class SystemConfigAdmin(admin.ModelAdmin):
    """Admin interface for SystemConfig model."""
    list_display = ['category', 'key', 'value_preview', 'is_system_managed', 'updated_at']
    list_filter = ['category', 'is_system_managed', 'is_user_configurable']
    search_fields = ['key', 'value', 'description']
    readonly_fields = ['id', 'created_at', 'updated_at']
    
    def value_preview(self, obj):
        if len(obj.value) > 50:
            return f"{obj.value[:50]}..."
        return obj.value
    value_preview.short_description = 'Value'


@admin.register(AuditLog)
class AuditLogAdmin(admin.ModelAdmin):
    """Admin interface for AuditLog model."""
    list_display = ['user', 'action_type', 'resource_type', 'severity', 'created_at']
    list_filter = ['action_type', 'resource_type', 'severity', 'created_at']
    search_fields = ['user__username', 'resource_type', 'resource_id']
    readonly_fields = ['id', 'created_at', 'updated_at']
    date_hierarchy = 'created_at'
    ordering = ['-created_at']
    
    def has_add_permission(self, request):
        return False
    
    def has_change_permission(self, request, obj=None):
        return False


@admin.register(TranslationCache)
class TranslationCacheAdmin(admin.ModelAdmin):
    """Admin interface for TranslationCache model."""
    list_display = ['source_language', 'target_language', 'source_preview', 'usage_count', 'last_used']
    list_filter = ['source_language', 'target_language', 'translation_service']
    search_fields = ['source_text', 'translated_text']
    readonly_fields = ['id', 'created_at', 'updated_at', 'usage_count', 'last_used']
    
    def source_preview(self, obj):
        return obj.source_text[:50] + '...' if len(obj.source_text) > 50 else obj.source_text
    source_preview.short_description = 'Source Text'


@admin.register(ContentFilterRule)
class ContentFilterRuleAdmin(admin.ModelAdmin):
    """Admin interface for ContentFilterRule model."""
    list_display = ['name', 'rule_type', 'action', 'severity', 'is_enabled', 'trigger_count']
    list_filter = ['rule_type', 'action', 'severity', 'is_enabled']
    search_fields = ['name', 'pattern']
    readonly_fields = ['id', 'created_at', 'updated_at', 'trigger_count', 'last_triggered']


@admin.register(ModerationQueue)
class ModerationQueueAdmin(admin.ModelAdmin):
    """Admin interface for ModerationQueue model."""
    list_display = ['content_type', 'status', 'priority', 'reported_by', 'created_at']
    list_filter = ['content_type', 'status', 'priority', 'created_at']
    search_fields = ['content_id', 'reason', 'reported_by__username']
    readonly_fields = ['id', 'created_at', 'updated_at', 'content_snapshot']
    date_hierarchy = 'created_at'
    ordering = ['priority', '-created_at']


@admin.register(LanguagePreference)
class LanguagePreferenceAdmin(admin.ModelAdmin):
    """Admin interface for LanguagePreference model."""
    list_display = ['user', 'primary_language', 'auto_translate_enabled', 'timezone']
    list_filter = ['primary_language', 'auto_translate_enabled']
    search_fields = ['user__username', 'user__email']
    readonly_fields = ['id', 'created_at', 'updated_at']
