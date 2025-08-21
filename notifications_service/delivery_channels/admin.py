from django.contrib import admin
from .models import NotificationChannel, DeliveryAttempt, ChannelRateLimit, ChannelCredential


@admin.register(NotificationChannel)
class NotificationChannelAdmin(admin.ModelAdmin):
    list_display = ['id', 'name', 'channel_type', 'is_active', 'priority', 'created_at']
    list_filter = ['channel_type', 'is_active']
    search_fields = ['name', 'description']
    readonly_fields = ['id', 'created_at', 'updated_at']
    ordering = ['priority']


@admin.register(DeliveryAttempt)
class DeliveryAttemptAdmin(admin.ModelAdmin):
    list_display = ['id', 'notification_id', 'channel', 'status', 'attempt_number', 'attempted_at']
    list_filter = ['status', 'channel']
    search_fields = ['notification_id']
    readonly_fields = ['id', 'attempted_at']
    ordering = ['-attempted_at']


@admin.register(ChannelRateLimit)
class ChannelRateLimitAdmin(admin.ModelAdmin):
    list_display = ['id', 'channel', 'max_requests', 'time_window_seconds', 'is_active', 'created_at']
    list_filter = ['is_active']
    search_fields = ['channel__name']
    readonly_fields = ['id', 'created_at', 'updated_at']


@admin.register(ChannelCredential)
class ChannelCredentialAdmin(admin.ModelAdmin):
    list_display = ['id', 'channel', 'credential_type', 'is_active', 'created_at']
    list_filter = ['credential_type', 'is_active']
    search_fields = ['channel__name']
    readonly_fields = ['id', 'created_at', 'updated_at']
    exclude = ['credential_data']  # Hide sensitive credential data from admin
