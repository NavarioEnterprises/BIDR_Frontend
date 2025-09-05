"""
Django admin configuration for logging models.
"""

from django.contrib import admin
from django.utils.html import format_html
from django.urls import reverse
from django.utils.safestring import mark_safe
from .models import (
    APIRequestLog, ApplicationLog, ProductRequestLog, 
    CategoryLog, PerformanceLog, ErrorLog
)


@admin.register(APIRequestLog)
class APIRequestLogAdmin(admin.ModelAdmin):
    list_display = (
        'method', 'path', 'status_code', 'user', 'duration_ms', 
        'timestamp', 'is_successful', 'endpoint_category'
    )
    list_filter = (
        'method', 'status_code', 'endpoint_category', 
        'timestamp', 'user'
    )
    search_fields = ('path', 'user__username', 'ip_address', 'view_name')
    readonly_fields = (
        'id', 'timestamp', 'is_successful', 'is_client_error', 
        'is_server_error', 'duration_seconds'
    )
    
    fieldsets = (
        ('Request Details', {
            'fields': (
                'method', 'path', 'full_url', 'query_params',
                'view_name', 'endpoint_category'
            )
        }),
        ('Request Data', {
            'fields': ('request_body', 'request_size', 'headers'),
            'classes': ('collapse',)
        }),
        ('Response Details', {
            'fields': (
                'status_code', 'response_body', 'response_size', 
                'response_headers'
            ),
            'classes': ('collapse',)
        }),
        ('User & Session', {
            'fields': (
                'user', 'session_id', 'ip_address', 'user_agent'
            )
        }),
        ('Performance', {
            'fields': ('duration_ms', 'duration_seconds')
        }),
        ('Error Information', {
            'fields': ('error_message', 'error_traceback'),
            'classes': ('collapse',)
        }),
        ('System', {
            'fields': ('id', 'timestamp'),
            'classes': ('collapse',)
        }),
    )
    
    def is_successful(self, obj):
        return obj.is_successful
    is_successful.boolean = True
    is_successful.short_description = 'Success'
    
    def get_queryset(self, request):
        return super().get_queryset(request).select_related('user')


@admin.register(ApplicationLog)
class ApplicationLogAdmin(admin.ModelAdmin):
    list_display = (
        'level', 'event_type', 'category', 'message_short', 
        'user', 'timestamp'
    )
    list_filter = (
        'level', 'event_type', 'category', 'timestamp'
    )
    search_fields = ('message', 'category', 'user__username', 'subcategory')
    readonly_fields = ('id', 'timestamp')
    
    fieldsets = (
        ('Event Classification', {
            'fields': ('level', 'event_type', 'category', 'subcategory')
        }),
        ('Event Details', {
            'fields': ('message', 'context_data', 'tags')
        }),
        ('User Context', {
            'fields': ('user', 'session_id', 'ip_address')
        }),
        ('Related Object', {
            'fields': ('content_type', 'object_id', 'content_object'),
            'classes': ('collapse',)
        }),
        ('Error Information', {
            'fields': ('error_code', 'error_details'),
            'classes': ('collapse',)
        }),
        ('Performance', {
            'fields': ('execution_time_ms',),
            'classes': ('collapse',)
        }),
        ('System', {
            'fields': ('id', 'timestamp'),
            'classes': ('collapse',)
        }),
    )
    
    def message_short(self, obj):
        return obj.message[:100] + '...' if len(obj.message) > 100 else obj.message
    message_short.short_description = 'Message'
    
    def get_queryset(self, request):
        return super().get_queryset(request).select_related('user', 'content_type')


@admin.register(ProductRequestLog)
class ProductRequestLogAdmin(admin.ModelAdmin):
    list_display = (
        'product_request_id', 'action', 'category', 'user', 
        'timestamp', 'source'
    )
    list_filter = ('action', 'category', 'source', 'timestamp')
    search_fields = (
        'product_request_id', 'title', 'user__username', 'action'
    )
    readonly_fields = ('id', 'timestamp')
    
    fieldsets = (
        ('Product Request', {
            'fields': ('product_request_id', 'title', 'category')
        }),
        ('Action Details', {
            'fields': ('action', 'action_details', 'source')
        }),
        ('User Context', {
            'fields': ('user', 'ip_address', 'user_agent')
        }),
        ('Change Tracking', {
            'fields': ('old_values', 'new_values'),
            'classes': ('collapse',)
        }),
        ('System', {
            'fields': ('id', 'timestamp'),
            'classes': ('collapse',)
        }),
    )
    
    def get_queryset(self, request):
        return super().get_queryset(request).select_related('user')


@admin.register(CategoryLog)
class CategoryLogAdmin(admin.ModelAdmin):
    list_display = (
        'category_name', 'event', 'request_count', 'user', 'timestamp'
    )
    list_filter = ('event', 'timestamp')
    search_fields = ('category_name', 'user__username', 'event')
    readonly_fields = ('id', 'timestamp')
    
    fieldsets = (
        ('Category Details', {
            'fields': ('category_id', 'category_name')
        }),
        ('Event Information', {
            'fields': ('event', 'event_data', 'request_count')
        }),
        ('Search Queries', {
            'fields': ('search_queries',),
            'classes': ('collapse',)
        }),
        ('User Context', {
            'fields': ('user',)
        }),
        ('System', {
            'fields': ('id', 'timestamp'),
            'classes': ('collapse',)
        }),
    )
    
    def get_queryset(self, request):
        return super().get_queryset(request).select_related('user')


@admin.register(PerformanceLog)
class PerformanceLogAdmin(admin.ModelAdmin):
    list_display = (
        'metric_name', 'metric_value', 'metric_unit', 'operation', 
        'threshold_exceeded', 'severity', 'timestamp'
    )
    list_filter = (
        'metric_name', 'metric_unit', 'threshold_exceeded', 
        'severity', 'timestamp'
    )
    search_fields = ('metric_name', 'operation', 'endpoint')
    readonly_fields = ('id', 'timestamp')
    
    fieldsets = (
        ('Performance Metric', {
            'fields': ('metric_name', 'metric_value', 'metric_unit')
        }),
        ('Context', {
            'fields': ('operation', 'endpoint', 'metadata')
        }),
        ('Alerts', {
            'fields': ('threshold_exceeded', 'severity')
        }),
        ('System', {
            'fields': ('id', 'timestamp'),
            'classes': ('collapse',)
        }),
    )
    
    def threshold_exceeded(self, obj):
        if obj.threshold_exceeded:
            return format_html(
                '<span style="color: red;">⚠️ Exceeded</span>'
            )
        return format_html('<span style="color: green;">✅ OK</span>')
    threshold_exceeded.short_description = 'Threshold'


@admin.register(ErrorLog)
class ErrorLogAdmin(admin.ModelAdmin):
    list_display = (
        'error_type', 'error_message_short', 'user', 'is_resolved', 
        'timestamp', 'method', 'path'
    )
    list_filter = (
        'error_type', 'is_resolved', 'timestamp', 'method'
    )
    search_fields = (
        'error_type', 'error_message', 'user__username', 
        'file_path', 'function_name'
    )
    readonly_fields = ('id', 'timestamp')
    
    fieldsets = (
        ('Error Details', {
            'fields': ('error_type', 'error_message', 'error_code')
        }),
        ('Debug Information', {
            'fields': (
                'stack_trace', 'file_path', 'line_number', 'function_name'
            ),
            'classes': ('collapse',)
        }),
        ('Request Context', {
            'fields': ('request_id', 'method', 'path'),
            'classes': ('collapse',)
        }),
        ('User Context', {
            'fields': ('user', 'session_id', 'ip_address')
        }),
        ('Additional Context', {
            'fields': ('context_data',),
            'classes': ('collapse',)
        }),
        ('Resolution Tracking', {
            'fields': (
                'is_resolved', 'resolution_notes', 'resolved_by', 'resolved_at'
            )
        }),
        ('System', {
            'fields': ('id', 'timestamp'),
            'classes': ('collapse',)
        }),
    )
    
    def error_message_short(self, obj):
        return obj.error_message[:100] + '...' if len(obj.error_message) > 100 else obj.error_message
    error_message_short.short_description = 'Error Message'
    
    def get_queryset(self, request):
        return super().get_queryset(request).select_related('user', 'resolved_by')
    
    actions = ['mark_as_resolved']
    
    def mark_as_resolved(self, request, queryset):
        from django.utils import timezone
        updated = queryset.update(
            is_resolved=True,
            resolved_by=request.user,
            resolved_at=timezone.now()
        )
        self.message_user(
            request, f'{updated} error(s) marked as resolved.'
        )
    mark_as_resolved.short_description = "Mark selected errors as resolved"
