from django.contrib import admin
from .models import Payment, PaymentWebhook, RefundRequest
from django.utils.html import format_html
from django.urls import reverse
from django.utils import timezone


@admin.register(Payment)
class PaymentAdmin(admin.ModelAdmin):
    list_display = ['reference', 'amount', 'currency', 'status', 'payment_method', 
                   'payment_gateway', 'user_id', 'created_at']
    list_filter = ['status', 'payment_method', 'currency', 'payment_gateway', 'created_at']
    search_fields = ['reference', 'user_id', 'payment_gateway__name']
    readonly_fields = ['id', 'created_at', 'updated_at']
    date_hierarchy = 'created_at'
    
    fieldsets = (
        ('Payment Information', {
            'fields': ('user_id', 'payment_gateway', 'reference', 'payment_method')
        }),
        ('Amount & Currency', {
            'fields': ('amount', 'currency')
        }),
        ('Status & Responses', {
            'fields': ('status', 'gateway_response')
        }),
        ('Metadata', {
            'fields': ('metadata',)
        }),
        ('System Fields', {
            'fields': ('id', 'created_at', 'updated_at'),
            'classes': ('collapse',)
        })
    )
    
    def get_queryset(self, request):
        return super().get_queryset(request).select_related('payment_gateway')
    
    def has_delete_permission(self, request, obj=None):
        # Only allow superusers to delete payments
        return request.user.is_superuser


@admin.register(PaymentWebhook)
class PaymentWebhookAdmin(admin.ModelAdmin):
    list_display = ['event_type', 'payment_link', 'processed', 'created_at']
    list_filter = ['event_type', 'processed', 'created_at']
    search_fields = ['event_type', 'payment__reference']
    readonly_fields = ['id', 'created_at']
    date_hierarchy = 'created_at'
    
    fieldsets = (
        ('Webhook Details', {
            'fields': ('payment', 'event_type', 'processed')
        }),
        ('Payload', {
            'fields': ('payload',)
        }),
        ('System Fields', {
            'fields': ('id', 'created_at'),
            'classes': ('collapse',)
        })
    )
    
    def payment_link(self, obj):
        if obj.payment:
            url = reverse('admin:payments_payment_change', args=[obj.payment.pk])
            return format_html('<a href="{}">{}</a>', url, obj.payment.reference)
        return '-'
    payment_link.short_description = 'Payment'
    
    def get_queryset(self, request):
        return super().get_queryset(request).select_related('payment')


@admin.register(RefundRequest)
class RefundRequestAdmin(admin.ModelAdmin):
    list_display = ['payment_link', 'amount', 'status', 'reason_short', 'processed_at', 'created_at']
    list_filter = ['status', 'processed_at', 'created_at']
    search_fields = ['payment__reference', 'reason']
    readonly_fields = ['id', 'created_at', 'updated_at']
    date_hierarchy = 'created_at'
    
    fieldsets = (
        ('Refund Details', {
            'fields': ('payment', 'amount', 'reason')
        }),
        ('Status & Processing', {
            'fields': ('status', 'processed_at', 'gateway_response')
        }),
        ('System Fields', {
            'fields': ('id', 'created_at', 'updated_at'),
            'classes': ('collapse',)
        })
    )
    
    def payment_link(self, obj):
        if obj.payment:
            url = reverse('admin:payments_payment_change', args=[obj.payment.pk])
            return format_html('<a href="{}">{}</a>', url, obj.payment.reference)
        return '-'
    payment_link.short_description = 'Payment'
    
    def reason_short(self, obj):
        if len(obj.reason) > 50:
            return obj.reason[:50] + '...'
        return obj.reason
    reason_short.short_description = 'Reason'
    
    def get_queryset(self, request):
        return super().get_queryset(request).select_related('payment')
    
    def has_delete_permission(self, request, obj=None):
        # Only allow superusers to delete refund requests
        return request.user.is_superuser
