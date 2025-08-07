"""
Admin interface for Product Requests app.
"""

from django.contrib import admin
from django.utils.html import format_html
from .models import (
    ProductRequest, RequestImage, RequestSpecification, 
    RequestMessage, RequestWatchlist, RequestTemplate
)


class RequestImageInline(admin.TabularInline):
    model = RequestImage
    extra = 0
    fields = ('image', 'caption', 'sort_order')
    ordering = ['sort_order']


class RequestSpecificationInline(admin.TabularInline):
    model = RequestSpecification
    extra = 0
    fields = ('name', 'value', 'is_required', 'sort_order')
    ordering = ['sort_order']


@admin.register(ProductRequest)
class ProductRequestAdmin(admin.ModelAdmin):
    list_display = (
        'reference_number', 'title', 'requester', 'category', 
        'request_type', 'status', 'priority', 'urgency', 
        'quantity_needed', 'quote_count', 'created_at'
    )
    list_filter = (
        'request_type', 'status', 'priority', 'urgency', 
        'category', 'delivery_required', 'created_at'
    )
    search_fields = (
        'reference_number', 'title', 'description', 
        'requester__username', 'requester__email'
    )
    readonly_fields = (
        'id', 'reference_number', 'quote_count', 'view_count',
        'is_expired', 'is_urgent', 'average_budget', 'created_at', 'updated_at'
    )
    
    fieldsets = (
        ('Basic Information', {
            'fields': (
                'reference_number', 'title', 'description', 'request_type'
            )
        }),
        ('Requester Details', {
            'fields': (
                'requester', 'requester_company', 'contact_email', 
                'contact_phone'
            )
        }),
        ('Product Information', {
            'fields': ('category', 'existing_product')
        }),
        ('Quantity & Specifications', {
            'fields': ('quantity_needed', 'unit_of_measure')
        }),
        ('Budget', {
            'fields': (
                'budget_min', 'budget_max', 'total_budget', 'average_budget'
            )
        }),
        ('Timeline', {
            'fields': (
                'urgency', 'needed_by_date', 'expires_at', 
                'is_expired', 'is_urgent'
            )
        }),
        ('Status & Priority', {
            'fields': ('status', 'priority')
        }),
        ('Delivery', {
            'fields': ('delivery_required', 'preferred_delivery_date')
        }),
        ('Tracking', {
            'fields': ('quote_count', 'view_count'),
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
    
    inlines = [RequestImageInline, RequestSpecificationInline]
    
    def get_queryset(self, request):
        return super().get_queryset(request).select_related(
            'requester', 'category', 'existing_product'
        )


@admin.register(RequestMessage)
class RequestMessageAdmin(admin.ModelAdmin):
    list_display = (
        'request', 'sender', 'message_type', 'subject', 
        'is_internal', 'is_read', 'created_at'
    )
    list_filter = (
        'message_type', 'is_internal', 'read_at', 'created_at'
    )
    search_fields = (
        'request__reference_number', 'sender__username', 
        'subject', 'message'
    )
    readonly_fields = ('created_at', 'is_read')
    
    def get_queryset(self, request):
        return super().get_queryset(request).select_related(
            'request', 'sender'
        )


@admin.register(RequestWatchlist)
class RequestWatchlistAdmin(admin.ModelAdmin):
    list_display = (
        'request', 'user', 'notify_on_quotes', 'notify_on_updates', 
        'notify_on_messages', 'created_at'
    )
    list_filter = (
        'notify_on_quotes', 'notify_on_updates', 'notify_on_messages',
        'created_at'
    )
    search_fields = (
        'request__reference_number', 'user__username'
    )
    
    def get_queryset(self, request):
        return super().get_queryset(request).select_related(
            'request', 'user'
        )


@admin.register(RequestTemplate)
class RequestTemplateAdmin(admin.ModelAdmin):
    list_display = (
        'name', 'category', 'request_type', 'usage_count', 
        'is_active', 'created_at'
    )
    list_filter = (
        'request_type', 'is_active', 'category', 'created_at'
    )
    search_fields = ('name', 'description', 'category__name')
    readonly_fields = ('usage_count', 'created_at', 'updated_at')
    
    def get_queryset(self, request):
        return super().get_queryset(request).select_related('category')
