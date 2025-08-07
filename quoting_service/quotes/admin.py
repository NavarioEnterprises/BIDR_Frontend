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
        'reference_number', 'request', 'supplier', 'quote_type',
        'unit_price', 'quantity_quoted', 'final_total', 'status',
        'is_best_price', 'rank_position', 'viewed_by_requester', 'created_at'
    )
    list_filter = (
        'quote_type', 'status', 'delivery_method', 'is_best_price',
        'viewed_by_requester', 'created_at', 'valid_until'
    )
    search_fields = (
        'reference_number', 'title', 'request__reference_number',
        'supplier__username', 'supplier__email'
    )
    readonly_fields = (
        'id', 'reference_number', 'final_total', 'platform_fee',
        'is_expired', 'is_valid', 'price_per_unit_with_extras',
        'estimated_delivery_date', 'viewed_by_requester',
        'requester_view_date', 'created_at', 'updated_at'
    )
    
    fieldsets = (
        ('Basic Information', {
            'fields': (
                'reference_number', 'title', 'description', 'quote_type'
            )
        }),
        ('Related Entities', {
            'fields': ('request', 'supplier', 'product')
        }),
        ('Pricing', {
            'fields': (
                'unit_price', 'quantity_quoted', 'total_price',
                'shipping_cost', 'tax_amount', 'platform_fee', 'final_total',
                'price_per_unit_with_extras'
            )
        }),
        ('Delivery & Terms', {
            'fields': (
                'delivery_method', 'estimated_delivery_days', 
                'estimated_delivery_date', 'delivery_terms'
            )
        }),
        ('Validity & Payment', {
            'fields': (
                'valid_until', 'is_expired', 'is_valid', 'payment_terms'
            )
        }),
        ('Status & Competition', {
            'fields': (
                'status', 'is_best_price', 'rank_position'
            )
        }),
        ('Response Tracking', {
            'fields': (
                'viewed_by_requester', 'requester_view_date'
            ),
            'classes': ('collapse',)
        }),
        ('Location', {
            'fields': (
                'address_line_1', 'address_line_2', 'city', 'state_province',
                'postal_code', 'country', 'latitude', 'longitude', 'search_radius'
            ),
            'classes': ('collapse',)
        }),
        ('Metadata', {
            'fields': ('tags', 'notes', 'metadata'),
            'classes': ('collapse',)
        }),
        ('System Information', {
            'fields': ('id', 'created_at', 'updated_at'),
            'classes': ('collapse',)
        })
    )
    
    inlines = [QuoteItemInline, QuoteAttachmentInline]
    
    def get_queryset(self, request):
        return super().get_queryset(request).select_related(
            'request', 'supplier', 'product'
        ).prefetch_related('items', 'attachments')


@admin.register(QuoteItem)
class QuoteItemAdmin(admin.ModelAdmin):
    list_display = (
        'quote', 'name', 'sku', 'unit_price', 'quantity', 
        'line_total', 'sort_order'
    )
    list_filter = ('quote__status', 'quote__supplier')
    search_fields = (
        'name', 'sku', 'description', 'quote__reference_number'
    )
    readonly_fields = ('line_total',)
    
    def get_queryset(self, request):
        return super().get_queryset(request).select_related(
            'quote', 'product'
        )


@admin.register(QuoteAttachment)
class QuoteAttachmentAdmin(admin.ModelAdmin):
    list_display = (
        'quote', 'filename', 'description', 'file_size_formatted', 
        'content_type', 'uploaded_at'
    )
    list_filter = ('content_type', 'uploaded_at')
    search_fields = (
        'filename', 'description', 'quote__reference_number'
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
        'quote__reference_number', 'sender__username', 
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
    search_fields = ('request__reference_number',)
    readonly_fields = (
        'total_quotes', 'lowest_price', 'highest_price', 'average_price',
        'last_updated'
    )
    
    def get_queryset(self, request):
        return super().get_queryset(request).select_related(
            'request', 'best_price_quote', 'best_delivery_quote'
        )
