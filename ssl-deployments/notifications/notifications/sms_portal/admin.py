from django.contrib import admin
from .models import SMSPortalConfig, SMSMessage, SMSUsageStats, SMSTemplate


@admin.register(SMSPortalConfig)
class SMSPortalConfigAdmin(admin.ModelAdmin):
    list_display = ['name', 'is_active', 'rate_limit_per_minute', 'last_used', 'created_at']
    list_filter = ['is_active', 'created_at']
    search_fields = ['name', 'default_sender_id']
    readonly_fields = ['id', 'last_used', 'created_at', 'updated_at']
    
    fieldsets = (
        ('Basic Information', {
            'fields': ('name', 'is_active')
        }),
        ('API Configuration', {
            'fields': ('api_url', 'api_key', 'api_secret', 'default_sender_id'),
            'classes': ('collapse',)
        }),
        ('Rate Limiting', {
            'fields': ('rate_limit_per_minute',)
        }),
        ('Status', {
            'fields': ('last_used',),
            'classes': ('collapse',)
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )


@admin.register(SMSMessage)
class SMSMessageAdmin(admin.ModelAdmin):
    list_display = [
        'recipient_phone', 'message_type', 'status', 'sender_id', 
        'credits_used', 'sent_at', 'created_at'
    ]
    list_filter = [
        'status', 'message_type', 'sender_id', 'created_at', 
        'sent_at', 'delivered_at'
    ]
    search_fields = [
        'recipient_phone', 'message_content', 'external_message_id', 
        'notification_id'
    ]
    readonly_fields = [
        'id', 'external_message_id', 'external_status', 'response_data',
        'sent_at', 'delivered_at', 'created_at', 'updated_at'
    ]
    
    fieldsets = (
        ('Message Details', {
            'fields': ('recipient_phone', 'message_content', 'sender_id', 'message_type')
        }),
        ('Status & Tracking', {
            'fields': ('status', 'external_message_id', 'external_status', 'response_data')
        }),
        ('Cost & Credits', {
            'fields': ('cost', 'credits_used')
        }),
        ('Error Information', {
            'fields': ('error_message', 'error_code'),
            'classes': ('collapse',)
        }),
        ('Timing', {
            'fields': ('queued_at', 'sent_at', 'delivered_at'),
            'classes': ('collapse',)
        }),
        ('Retry Logic', {
            'fields': ('retry_count', 'max_retries', 'next_retry_at'),
            'classes': ('collapse',)
        }),
        ('References', {
            'fields': ('notification_id',),
            'classes': ('collapse',)
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )
    
    def get_queryset(self, request):
        return super().get_queryset(request).select_related()


@admin.register(SMSUsageStats)
class SMSUsageStatsAdmin(admin.ModelAdmin):
    list_display = [
        'date', 'total_sent', 'total_delivered', 'total_failed', 
        'delivery_rate_display', 'total_cost', 'total_credits_used'
    ]
    list_filter = ['date', 'created_at']
    search_fields = ['date']
    readonly_fields = [
        'id', 'delivery_rate', 'success_rate', 'created_at', 'updated_at'
    ]
    date_hierarchy = 'date'
    
    fieldsets = (
        ('Date', {
            'fields': ('date',)
        }),
        ('Usage Statistics', {
            'fields': (
                'total_sent', 'total_delivered', 'total_failed', 'total_bounced'
            )
        }),
        ('Cost Tracking', {
            'fields': ('total_cost', 'total_credits_used')
        }),
        ('Message Type Breakdown', {
            'fields': (
                'otp_count', 'notification_count', 'alert_count', 
                'marketing_count', 'system_count'
            ),
            'classes': ('collapse',)
        }),
        ('Calculated Fields', {
            'fields': ('delivery_rate', 'success_rate'),
            'classes': ('collapse',)
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )
    
    def delivery_rate_display(self, obj):
        return f"{obj.delivery_rate:.1f}%"
    delivery_rate_display.short_description = 'Delivery Rate'


@admin.register(SMSTemplate)
class SMSTemplateAdmin(admin.ModelAdmin):
    list_display = [
        'name', 'message_type', 'is_active', 'usage_count', 
        'last_used', 'created_at'
    ]
    list_filter = ['message_type', 'is_active', 'created_at', 'last_used']
    search_fields = ['name', 'content']
    readonly_fields = ['id', 'usage_count', 'last_used', 'created_at', 'updated_at']
    
    fieldsets = (
        ('Template Information', {
            'fields': ('name', 'message_type', 'is_active')
        }),
        ('Content', {
            'fields': ('content',)
        }),
        ('Settings', {
            'fields': ('sender_id',)
        }),
        ('Usage Statistics', {
            'fields': ('usage_count', 'last_used'),
            'classes': ('collapse',)
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )