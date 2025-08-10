from django.contrib import admin
from django.utils.html import format_html
from django.urls import reverse
from django.utils.safestring import mark_safe

# Core models don't have concrete models to register
# This is a placeholder for any future core admin functionality

class CoreAdminMixin:
    """
    Mixin class for common admin functionality across all models.
    """
    def created_at_display(self, obj):
        if hasattr(obj, 'created_at') and obj.created_at:
            return obj.created_at.strftime("%Y-%m-%d %H:%M")
        return "-"
    created_at_display.short_description = "Created"
    created_at_display.admin_order_field = "created_at"
    
    def updated_at_display(self, obj):
        if hasattr(obj, 'updated_at') and obj.updated_at:
            return obj.updated_at.strftime("%Y-%m-%d %H:%M")
        return "-"
    updated_at_display.short_description = "Updated"
    updated_at_display.admin_order_field = "updated_at"
    
    def status_display(self, obj):
        if hasattr(obj, 'status'):
            colors = {
                'ACTIVE': 'green',
                'INACTIVE': 'red',
                'PENDING': 'orange',
                'DRAFT': 'gray',
                'APPROVED': 'green',
                'REJECTED': 'red',
                'CANCELLED': 'red',
                'COMPLETED': 'blue',
                'EXPIRED': 'red',
            }
            color = colors.get(obj.status, 'black')
            return format_html(
                '<span style="color: {}; font-weight: bold;">{}</span>',
                color,
                obj.get_status_display() if hasattr(obj, 'get_status_display') else obj.status
            )
        return "-"
    status_display.short_description = "Status"
    status_display.admin_order_field = "status"
