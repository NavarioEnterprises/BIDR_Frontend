from django.contrib import admin
from .models import Transaction, TransactionPIN, TransactionLog
from django.utils.html import format_html
from django.urls import reverse
from django.utils import timezone


@admin.register(Transaction)
class TransactionAdmin(admin.ModelAdmin):
    list_display = ['id', 'buyer_id', 'seller_id', 'amount', 'transaction_type', 
                   'status', 'payment_link', 'created_at']
    list_filter = ['status', 'transaction_type', 'created_at']
    search_fields = ['id', 'buyer_id', 'seller_id', 'description']
    readonly_fields = ['id', 'created_at', 'updated_at']
    date_hierarchy = 'created_at'
    
    fieldsets = (
        ('Transaction Details', {
            'fields': ('buyer_id', 'seller_id', 'amount', 'transaction_type')
        }),
        ('Payment & Status', {
            'fields': ('payment', 'status')
        }),
        ('Description & Metadata', {
            'fields': ('description', 'metadata')
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
    
    def get_queryset(self, request):
        return super().get_queryset(request).select_related('payment')
    
    def has_delete_permission(self, request, obj=None):
        # Only allow superusers to delete transactions
        return request.user.is_superuser


@admin.register(TransactionPIN)
class TransactionPINAdmin(admin.ModelAdmin):
    list_display = ['transaction_link', 'pin_code', 'attempts', 'is_used', 
                   'is_expired_display', 'expires_at', 'created_at']
    list_filter = ['is_used', 'expires_at', 'created_at']
    search_fields = ['transaction__id', 'pin_code']
    readonly_fields = ['id', 'created_at', 'is_expired_display', 'is_valid_display']
    date_hierarchy = 'created_at'
    
    fieldsets = (
        ('PIN Details', {
            'fields': ('transaction', 'pin_code', 'expires_at')
        }),
        ('Usage Status', {
            'fields': ('attempts', 'is_used')
        }),
        ('System Fields', {
            'fields': ('id', 'created_at', 'is_expired_display', 'is_valid_display'),
            'classes': ('collapse',)
        })
    )
    
    def transaction_link(self, obj):
        if obj.transaction:
            url = reverse('admin:transactions_transaction_change', args=[obj.transaction.pk])
            return format_html('<a href="{}">{}</a>', url, obj.transaction.id)
        return '-'
    transaction_link.short_description = 'Transaction'
    
    def is_expired_display(self, obj):
        return obj.is_expired()
    is_expired_display.boolean = True
    is_expired_display.short_description = 'Is Expired'
    
    def is_valid_display(self, obj):
        return obj.is_valid()
    is_valid_display.boolean = True
    is_valid_display.short_description = 'Is Valid'
    
    def get_queryset(self, request):
        return super().get_queryset(request).select_related('transaction')
    
    def has_delete_permission(self, request, obj=None):
        # Only allow superusers to delete PINs
        return request.user.is_superuser


@admin.register(TransactionLog)
class TransactionLogAdmin(admin.ModelAdmin):
    list_display = ['transaction_link', 'action', 'status', 'user_id', 
                   'ip_address', 'created_at']
    list_filter = ['action', 'status', 'created_at']
    search_fields = ['transaction__id', 'action', 'user_id', 'details']
    readonly_fields = ['id', 'created_at']
    date_hierarchy = 'created_at'
    
    fieldsets = (
        ('Log Details', {
            'fields': ('transaction', 'action', 'status')
        }),
        ('User & IP', {
            'fields': ('user_id', 'ip_address')
        }),
        ('Additional Details', {
            'fields': ('details',)
        }),
        ('System Fields', {
            'fields': ('id', 'created_at'),
            'classes': ('collapse',)
        })
    )
    
    def transaction_link(self, obj):
        if obj.transaction:
            url = reverse('admin:transactions_transaction_change', args=[obj.transaction.pk])
            return format_html('<a href="{}">{}</a>', url, obj.transaction.id)
        return '-'
    transaction_link.short_description = 'Transaction'
    
    def get_queryset(self, request):
        return super().get_queryset(request).select_related('transaction')
    
    def has_add_permission(self, request):
        # Transaction logs should be created programmatically
        return False
    
    def has_delete_permission(self, request, obj=None):
        # Only allow superusers to delete logs
        return request.user.is_superuser
