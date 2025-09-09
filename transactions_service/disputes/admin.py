from django.contrib import admin
from django.utils.html import format_html
from django.urls import reverse
from django.utils import timezone
from .models import Dispute

@admin.register(Dispute)
class DisputeAdmin(admin.ModelAdmin):
    list_display = ('dispute_id', 'get_request_display', 'get_buyer_display', 'get_seller_display',
                    'dispute_type', 'status', 'created_at', 'updated_at')
    list_filter = ('status', 'dispute_type', 'created_at')
    search_fields = ('dispute_id', 'request_id', 'buyer_id', 'seller_id', 'description', 'resolution')
    readonly_fields = ('dispute_id', 'created_at', 'updated_at')
    date_hierarchy = 'created_at'
    
    fieldsets = (
        ('Identification', {
            'fields': ('dispute_id',)
        }),
        ('Related Entities', {
            'fields': ('request_id', 'buyer_id', 'seller_id')
        }),
        ('Dispute Details', {
            'fields': ('dispute_type', 'description', 'evidence_files')
        }),
        ('Status & Resolution', {
            'fields': ('status', 'resolution', 'resolved_by', 'resolved_at')
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )
    
    def get_request_display(self, obj):
        """Display the request ID."""
        return str(obj.request_id)[:8] + '...'  # Show first 8 chars of UUID
    get_request_display.short_description = 'Request ID'
    
    def get_buyer_display(self, obj):
        """Display the buyer ID."""
        return str(obj.buyer_id)[:8] + '...'
    get_buyer_display.short_description = 'Buyer ID'
    
    def get_seller_display(self, obj):
        """Display the seller ID."""
        return str(obj.seller_id)[:8] + '...'
    get_seller_display.short_description = 'Seller ID'
    
    def has_delete_permission(self, request, obj=None):
        """Restrict deletion of resolved or closed disputes."""
        if obj and obj.status in ['RESOLVED', 'CLOSED']:
            return False
        return super().has_delete_permission(request, obj)
    
    def get_readonly_fields(self, request, obj=None):
        """Make certain fields readonly based on dispute status."""
        readonly_fields = list(self.readonly_fields)
        if obj and obj.status in ['RESOLVED', 'CLOSED']:
            readonly_fields.extend(['dispute_type', 'description', 'evidence_files'])
        return readonly_fields
    
    def save_model(self, request, obj, form, change):
        """Custom save logic for disputes."""
        # If dispute is being resolved, set the resolved_by user
        if 'status' in form.changed_data and obj.status == 'RESOLVED':
            if not obj.resolved_by:
                obj.resolved_by = request.user
            if not obj.resolved_at:
                obj.resolved_at = timezone.now()
        super().save_model(request, obj, form, change)
