from django.contrib import admin
from django.utils.html import format_html
from django.urls import reverse
from django.utils import timezone
from .models import EscrowPeriod

@admin.register(EscrowPeriod)
class EscrowPeriodAdmin(admin.ModelAdmin):
    list_display = ('escrow_id', 'get_transaction_link', 'category', 
                    'hold_period_days', 'start_date', 'end_date', 'status')
    list_filter = ('status', 'category', 'early_release_requested', 'early_release_approved')
    search_fields = ('escrow_id', 'transaction_id__transaction_id')
    readonly_fields = ('escrow_id', 'created_at', 'updated_at')
    date_hierarchy = 'start_date'
    
    fieldsets = (
        ('Identification', {
            'fields': ('escrow_id',)
        }),
        ('Related Transaction', {
            'fields': ('transaction_id',)
        }),
        ('Category & Hold Period', {
            'fields': ('category', 'hold_period_days')
        }),
        ('Period Dates', {
            'fields': ('start_date', 'end_date')
        }),
        ('Early Release', {
            'fields': ('early_release_requested', 'early_release_approved')
        }),
        ('Status', {
            'fields': ('status',)
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )
    
    def get_transaction_link(self, obj):
        """Generate a link to the related transaction in admin."""
        url = reverse('admin:transactions_transaction_change', args=[obj.transaction_id.pk])
        return format_html('<a href="{}">{}</a>', url, obj.transaction_id)
    get_transaction_link.short_description = 'Transaction'
    
    def has_delete_permission(self, request, obj=None):
        """Restrict deletion of released or disputed escrow periods."""
        if obj and obj.status in ['RELEASED', 'DISPUTED']:
            return False
        return super().has_delete_permission(request, obj)
    
    def get_readonly_fields(self, request, obj=None):
        """Make certain fields readonly based on escrow period status."""
        readonly_fields = list(self.readonly_fields)
        if obj and obj.status in ['RELEASED', 'DISPUTED']:
            readonly_fields.extend(['category', 'hold_period_days', 'start_date', 'end_date'])
        return readonly_fields
    
    def save_model(self, request, obj, form, change):
        """Custom save logic for escrow periods."""
        # If this is a new escrow period and hold_period_days is not set
        if not change and not obj.hold_period_days:
            # Set the hold period based on the category
            obj.set_hold_period_from_category()
            
        # If this is a new escrow period and end_date is not set
        if not change and not obj.end_date:
            # Calculate the end date based on start date and hold period
            obj.end_date = obj.calculate_end_date()
            
        super().save_model(request, obj, form, change)