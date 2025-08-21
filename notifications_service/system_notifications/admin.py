from django.contrib import admin
from .models import (
    Notification, NotificationTemplate, NotificationPreference,
    NotificationQueue, NotificationBatch
)


@admin.register(Notification)
class NotificationAdmin(admin.ModelAdmin):
    list_display = ['id', 'recipient_id', 'notification_type', 'title', 'status', 'is_read', 'priority', 'created_at']
    list_filter = ['status', 'is_read', 'priority', 'notification_type', 'source_service']
    search_fields = ['recipient_id', 'title', 'message']
    readonly_fields = ['id', 'created_at', 'updated_at']
    ordering = ['-created_at']


@admin.register(NotificationTemplate)
class NotificationTemplateAdmin(admin.ModelAdmin):
    list_display = ['id', 'name', 'notification_type', 'channel', 'is_active', 'created_at']
    list_filter = ['notification_type', 'channel', 'is_active']
    search_fields = ['name', 'subject_template']
    readonly_fields = ['id', 'created_at', 'updated_at']


@admin.register(NotificationPreference)
class NotificationPreferenceAdmin(admin.ModelAdmin):
    list_display = ['id', 'user_id', 'notification_type', 'channel', 'is_enabled', 'created_at']
    list_filter = ['notification_type', 'channel', 'is_enabled']
    search_fields = ['user_id']
    readonly_fields = ['id', 'created_at', 'updated_at']


@admin.register(NotificationQueue)
class NotificationQueueAdmin(admin.ModelAdmin):
    list_display = ['id', 'notification_id', 'channel', 'status', 'priority', 'scheduled_at', 'created_at']
    list_filter = ['status', 'channel', 'priority']
    search_fields = ['notification_id']
    readonly_fields = ['id', 'created_at', 'updated_at']
    ordering = ['-created_at']


@admin.register(NotificationBatch)
class NotificationBatchAdmin(admin.ModelAdmin):
    list_display = ['id', 'batch_id', 'status', 'total_notifications', 'sent_notifications', 'failed_notifications', 'created_at']
    list_filter = ['status']
    search_fields = ['batch_id']
    readonly_fields = ['id', 'created_at', 'updated_at']
    ordering = ['-created_at']
