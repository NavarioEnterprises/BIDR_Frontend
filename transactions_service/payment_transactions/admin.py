from django.contrib import admin
from django.utils.html import format_html
from django.urls import reverse
from .models import PaymentTransaction

@admin.register(PaymentTransaction)
class PaymentTransactionAdmin(admin.ModelAdmin):
    list_display = ('payment_id', 'get_transaction_link', 'payment_gateway', 
                    'amount', 'currency', 'status', 'created_at')
    list_filter = ('status', 'payment_gateway', 'created_at')
    search_fields = ('payment_id', 'transaction_id__transaction_id', 'gateway_transaction_id')
    readonly_fields = ('payment_id', 'created_at', 'updated_at')
    date_hierarchy = 'created_at'
    
    fieldsets = (
        ('Identification', {
            'fields': ('payment_id',)
        }),
        ('Related Transaction', {
            'fields': ('transaction_id',)
        }),
        ('Payment Gateway', {
            'fields': ('payment_gateway', 'gateway_transaction_id', 'gateway_response')
        }),
        ('Payment Details', {
            'fields': ('amount', 'currency', 'payment_method')
        }),
        ('Release Dates', {
            'fields': ('escrow_release_date', 'actual_release_date')
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
        """Restrict deletion of completed or refunded payments."""
        if obj and obj.status in ['CAPTURED', 'RELEASED', 'REFUNDED']:
            return False
        return super().has_delete_permission(request, obj)
    
    def get_readonly_fields(self, request, obj=None):
        """Make certain fields readonly based on payment status."""
        readonly_fields = list(self.readonly_fields)
        if obj and obj.status in ['CAPTURED', 'RELEASED', 'REFUNDED']:
            readonly_fields.extend(['payment_gateway', 'amount', 'currency', 'payment_method'])
        return readonly_fields
    
    def formfield_for_dbfield(self, db_field, **kwargs):
        """Customize form fields."""
        formfield = super().formfield_for_dbfield(db_field, **kwargs)
        
        # Make gateway_response field taller for better readability
        if db_field.name == 'gateway_response':
            formfield.widget.attrs['rows'] = 10
            
        return formfield