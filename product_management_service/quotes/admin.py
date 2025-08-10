"""
Admin interface for Quotes app.
"""

from django.contrib import admin
from django.utils.html import format_html
from .models import (
    Quote, QuoteItem, QuoteAttachment, QuoteMessage, QuoteComparison
)


class QuoteItemInline(admin.TabularInline):
    model = QuoteItem
    extra = 0
    fields = (
        'name', 'sku', 'unit_price', 'quantity', 'line_total', 'sort_order'
    )
    readonly_fields = ('line_total',)
    ordering = ['sort_order']


class QuoteAttachmentInline(admin.TabularInline):
    model = QuoteAttachment
    extra = 0
    fields = ('file', 'filename', 'description')
    readonly_fields = ('file_size', 'content_type', 'uploaded_at')


@admin.register(Quote)
class QuoteAdmin(admin.ModelAdmin):
    list_display = (
        'quote_id', 'request_id', 'seller_id', 'total_amount', 'currency',
        'status', 'valid_until', 'created_at', 'updated_at'
    )
    list_filter = (
        'status', 'currency', 'created_at', 'valid_until'
    )
    search_fields = (
        'quote_id', 'seller_id__username', 'seller_id__email'
    )
    readonly_fields = (
        'quote_id', 'is_expired', 'is_valid', 'created_at', 'updated_at'
    )
    
    fieldsets = (
        ('Basic Information', {
            'fields': (
                'quote_id', 'status'
            )
        }),
        ('Related Entities', {
            'fields': ('request_id', 'seller_id')
        }),
        ('Pricing', {
            'fields': (
                'total_amount', 'currency', 'delivery_cost', 'installation_cost'
            )
        }),
        ('Delivery & Terms', {
            'fields': (
                'estimated_delivery_days', 'terms_conditions', 'seller_notes', 'warranty_info'
            )
        }),
        ('Validity', {
            'fields': (
                'valid_until', 'is_expired', 'is_valid'
            )
        }),
        ('System Information', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        })
    )
    
    inlines = [QuoteItemInline, QuoteAttachmentInline]
    
    def get_queryset(self, request):
        return super().get_queryset(request).select_related(
            'request_id', 'seller_id'
        ).prefetch_related('items', 'attachments')


@admin.register(QuoteItem)
class QuoteItemAdmin(admin.ModelAdmin):
    list_display = (
        'quote', 'name', 'sku', 'unit_price', 'quantity', 
        'line_total', 'sort_order'
    )
    list_filter = ('quote__status',)
    search_fields = (
        'name', 'sku', 'description', 'quote__quote_id'
    )
    readonly_fields = ('line_total',)
    
    def get_queryset(self, request):
        return super().get_queryset(request).select_related('quote')


@admin.register(QuoteAttachment)
class QuoteAttachmentAdmin(admin.ModelAdmin):
    list_display = (
        'quote', 'filename', 'description', 'file_size_formatted', 
        'content_type', 'uploaded_at'
    )
    list_filter = ('content_type', 'uploaded_at')
    search_fields = (
        'filename', 'description', 'quote__quote_id'
    )
    readonly_fields = (
        'file_size', 'file_size_formatted', 'content_type', 'uploaded_at'
    )
    
    def get_queryset(self, request):
        return super().get_queryset(request).select_related('quote')


@admin.register(QuoteMessage)
class QuoteMessageAdmin(admin.ModelAdmin):
    list_display = (
        'quote', 'sender', 'message_type', 'subject', 
        'is_internal', 'is_read', 'created_at'
    )
    list_filter = (
        'message_type', 'is_internal', 'read_at', 'created_at'
    )
    search_fields = (
        'quote__quote_id', 'sender__username', 
        'subject', 'message'
    )
    readonly_fields = ('created_at', 'is_read')
    
    def get_queryset(self, request):
        return super().get_queryset(request).select_related(
            'quote', 'sender'
        )


@admin.register(QuoteComparison)
class QuoteComparisonAdmin(admin.ModelAdmin):
    list_display = (
        'request', 'total_quotes', 'lowest_price', 'highest_price',
        'average_price', 'best_price_quote', 'best_delivery_quote',
        'last_updated'
    )
    list_filter = ('last_updated',)
    search_fields = ('request__request_id',)
    readonly_fields = (
        'total_quotes', 'lowest_price', 'highest_price', 'average_price',
        'last_updated'
    )
    
    def get_queryset(self, request):
        return super().get_queryset(request).select_related(
            'request', 'best_price_quote', 'best_delivery_quote'
        )