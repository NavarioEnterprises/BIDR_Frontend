from django.contrib import admin
from .models import (
    Notification, NotificationTemplate, NotificationPreference,
    NotificationQueue, NotificationBatch
)


@admin.register(Notification)
class NotificationAdmin(admin.ModelAdmin):
    list_display = ['id', 'recipient_id', 'notification_type', 'subject', 'is_read', 'priority', 'created_at']
    list_filter = ['is_read', 'priority', 'notification_type', 'source_service']
    search_fields = ['recipient_id', 'subject', 'message']
    readonly_fields = ['id', 'created_at', 'updated_at']
    ordering = ['-created_at']


@admin.register(NotificationTemplate)
class NotificationTemplateAdmin(admin.ModelAdmin):
    list_display = ['id', 'name', 'notification_type', 'priority', 'is_active', 'created_at']
    list_filter = ['notification_type', 'priority', 'is_active']
    search_fields = ['name', 'subject_template']
    readonly_fields = ['id', 'created_at', 'updated_at']


@admin.register(NotificationPreference)
class NotificationPreferenceAdmin(admin.ModelAdmin):
    list_display = ['id', 'user_id', 'email_enabled', 'sms_enabled', 'push_enabled', 'created_at']
    list_filter = ['email_enabled', 'sms_enabled', 'push_enabled']
    search_fields = ['user_id']
    readonly_fields = ['id', 'created_at', 'updated_at']


@admin.register(NotificationQueue)
class NotificationQueueAdmin(admin.ModelAdmin):
    list_display = ['id', 'notification', 'priority', 'scheduled_for', 'is_processing', 'created_at']
    list_filter = ['is_processing', 'priority']
    search_fields = ['notification__subject']
    readonly_fields = ['id', 'created_at']
    ordering = ['-created_at']


@admin.register(NotificationBatch)
class NotificationBatchAdmin(admin.ModelAdmin):
    list_display = ['id', 'name', 'status', 'total_recipients', 'success_count', 'failed_count', 'created_at']
    list_filter = ['status', 'notification_type']
    search_fields = ['name']
    readonly_fields = ['id', 'created_at']
    ordering = ['-created_at']
