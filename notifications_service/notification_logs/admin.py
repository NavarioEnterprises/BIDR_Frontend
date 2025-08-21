from django.contrib import admin
from .models import NotificationLog, SystemLog, ErrorLog, AuditLog, APILog


@admin.register(NotificationLog)
class NotificationLogAdmin(admin.ModelAdmin):
    list_display = ['id', 'notification_id', 'event_type', 'status', 'channel', 'created_at']
    list_filter = ['event_type', 'status', 'channel']
    search_fields = ['notification_id', 'message']
    readonly_fields = ['id', 'created_at']
    ordering = ['-created_at']


@admin.register(SystemLog)
class SystemLogAdmin(admin.ModelAdmin):
    list_display = ['id', 'service', 'log_level', 'component', 'created_at']
    list_filter = ['log_level', 'service', 'component']
    search_fields = ['message', 'service']
    readonly_fields = ['id', 'created_at']
    ordering = ['-created_at']


@admin.register(ErrorLog)
class ErrorLogAdmin(admin.ModelAdmin):
    list_display = ['id', 'error_type', 'severity', 'service', 'created_at']
    list_filter = ['error_type', 'severity', 'service']
    search_fields = ['error_message', 'service']
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
    list_display = ['id', 'endpoint', 'method', 'status_code', 'response_time_ms', 'created_at']
    list_filter = ['method', 'status_code']
    search_fields = ['endpoint', 'user_agent']
    readonly_fields = ['id', 'created_at']
    ordering = ['-created_at']
