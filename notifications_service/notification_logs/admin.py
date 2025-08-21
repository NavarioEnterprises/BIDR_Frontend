from django.contrib import admin
from .models import NotificationLog, SystemLog, ErrorLog, AuditLog, APILog


@admin.register(NotificationLog)
class NotificationLogAdmin(admin.ModelAdmin):
    list_display = ['id', 'notification_id', 'channel_type', 'status', 'attempt_number', 'created_at']
    list_filter = ['channel_type', 'status']
    search_fields = ['notification_id', 'error_message']
    readonly_fields = ['id', 'created_at']
    ordering = ['-created_at']


@admin.register(SystemLog)
class SystemLogAdmin(admin.ModelAdmin):
    list_display = ['id', 'component', 'level', 'action', 'created_at']
    list_filter = ['level', 'component']
    search_fields = ['message', 'component']
    readonly_fields = ['id', 'created_at']
    ordering = ['-created_at']


@admin.register(ErrorLog)
class ErrorLogAdmin(admin.ModelAdmin):
    list_display = ['id', 'error_type', 'component', 'environment', 'created_at']
    list_filter = ['error_type', 'component', 'environment']
    search_fields = ['error_message', 'component']
    readonly_fields = ['id', 'created_at']
    ordering = ['-created_at']


@admin.register(AuditLog)
class AuditLogAdmin(admin.ModelAdmin):
    list_display = ['id', 'user_id', 'action', 'resource_type', 'resource_id', 'created_at']
    list_filter = ['action', 'resource_type']
    search_fields = ['user_id', 'resource_id']
    readonly_fields = ['id', 'created_at']
    ordering = ['-created_at']


@admin.register(APILog)
class APILogAdmin(admin.ModelAdmin):
    list_display = ['id', 'endpoint', 'method', 'response_status', 'processing_time_ms', 'created_at']
    list_filter = ['method', 'response_status']
    search_fields = ['endpoint', 'user_agent']
    readonly_fields = ['id', 'created_at']
    ordering = ['-created_at']
