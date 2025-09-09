from django.contrib import admin
from .models import EscrowPeriod, EscrowEarlyReleaseRequest, EscrowAccount
from django.utils.html import format_html
from django.urls import reverse
from django.utils import timezone


@admin.register(EscrowPeriod)
class EscrowPeriodAdmin(admin.ModelAdmin):
    list_display = ['id', 'transaction_link', 'category', 'status', 'hold_period_days', 
                   'days_remaining_display', 'early_release_requested', 'created_at']
    list_filter = ['status', 'category', 'early_release_requested', 'early_release_approved', 'created_at']
    search_fields = ['transaction__id', 'id']
    readonly_fields = ['created_at', 'updated_at', 'days_remaining_display', 'is_expired_display']
    date_hierarchy = 'created_at'
    
    fieldsets = (
        ('Transaction & Configuration', {
            'fields': ('transaction', 'category', 'hold_period_days')
        }),
        ('Timing', {
            'fields': ('start_date', 'end_date', 'actual_release_date')
        }),
        ('Early Release', {
            'fields': ('early_release_requested', 'early_release_approved', 
                      'early_release_requested_at', 'early_release_approved_at',
                      'early_release_requested_by', 'early_release_approved_by')
        }),
        ('Status & Details', {
            'fields': ('status', 'release_reason', 'dispute_reason', 'notes')
        }),
        ('Metadata', {
            'fields': ('created_at', 'updated_at', 'days_remaining_display', 'is_expired_display'),
            'classes': ('collapse',)
        })
    )
    
    def transaction_link(self, obj):
        if obj.transaction:
            url = reverse('admin:transactions_transaction_change', args=[obj.transaction.pk])
            return format_html('<a href="{}">{}</a>', url, obj.transaction.id)
        return '-'
    transaction_link.short_description = 'Transaction'
    
    def days_remaining_display(self, obj):
        days = obj.days_remaining()
        if days > 0:
            return f"{days} days"
        elif obj.is_expired():
            return format_html('<span style="color: red;">Expired</span>')
        return "0 days"
    days_remaining_display.short_description = 'Days Remaining'
    
    def is_expired_display(self, obj):
        return obj.is_expired()
    is_expired_display.boolean = True
    is_expired_display.short_description = 'Is Expired'


@admin.register(EscrowEarlyReleaseRequest)
class EscrowEarlyReleaseRequestAdmin(admin.ModelAdmin):
    list_display = ['id', 'escrow_period_link', 'requested_by', 'status', 'buyer_approved', 
                   'seller_approved', 'admin_review_required', 'created_at']
    list_filter = ['status', 'buyer_approved', 'seller_approved', 'admin_review_required', 'created_at']
    search_fields = ['escrow_period__id', 'requested_by__username', 'reason']
    readonly_fields = ['created_at', 'updated_at']
    date_hierarchy = 'created_at'
    
    fieldsets = (
        ('Request Details', {
            'fields': ('escrow_period', 'requested_by', 'reason', 'supporting_documents')
        }),
        ('Approval Status', {
            'fields': ('status', 'buyer_approved', 'seller_approved', 'admin_review_required')
        }),
        ('Processing', {
            'fields': ('processed_by', 'processed_at', 'processing_notes')
        }),
        ('Metadata', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        })
    )
    
    def escrow_period_link(self, obj):
        if obj.escrow_period:
            url = reverse('admin:escrow_escrowperiod_change', args=[obj.escrow_period.pk])
            return format_html('<a href="{}">{}</a>', url, obj.escrow_period.id)
        return '-'
    escrow_period_link.short_description = 'Escrow Period'


@admin.register(EscrowAccount)
class EscrowAccountAdmin(admin.ModelAdmin):
    list_display = ['id', 'transaction_link', 'amount', 'category', 'status', 
                   'days_remaining_display', 'early_release_requested', 'created_at']
    list_filter = ['status', 'category', 'early_release_requested', 'early_release_approved', 'created_at']
    search_fields = ['transaction__id', 'id']
    readonly_fields = ['created_at', 'updated_at', 'days_remaining_display', 'is_expired_display']
    date_hierarchy = 'created_at'
    
    fieldsets = (
        ('Account Details', {
            'fields': ('transaction', 'amount', 'category')
        }),
        ('Timeline', {
            'fields': ('start_date', 'end_date')
        }),
        ('Early Release', {
            'fields': ('early_release_requested', 'early_release_approved')
        }),
        ('Status', {
            'fields': ('status',)
        }),
        ('Metadata', {
            'fields': ('created_at', 'updated_at', 'days_remaining_display', 'is_expired_display'),
            'classes': ('collapse',)
        })
    )
    
    def transaction_link(self, obj):
        if obj.transaction:
            url = reverse('admin:transactions_transaction_change', args=[obj.transaction.pk])
            return format_html('<a href="{}">{}</a>', url, obj.transaction.id)
        return '-'
    transaction_link.short_description = 'Transaction'
    
    def days_remaining_display(self, obj):
        days = obj.days_remaining
        if days > 0:
            return f"{days} days"
        elif obj.is_expired:
            return format_html('<span style="color: red;">Expired</span>')
        return "0 days"
    days_remaining_display.short_description = 'Days Remaining'
    
    def is_expired_display(self, obj):
        return obj.is_expired
    is_expired_display.boolean = True
    is_expired_display.short_description = 'Is Expired'
