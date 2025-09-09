from django.contrib import admin
from .models import PaymentAnalytics


@admin.register(PaymentAnalytics)
class PaymentAnalyticsAdmin(admin.ModelAdmin):
    list_display = ['date', 'total_transactions', 'successful_transactions', 'failed_transactions', 
                   'total_amount', 'currency', 'success_rate']
    list_filter = ['currency', 'date', 'created_at']
    search_fields = ['date']
    readonly_fields = ['created_at', 'updated_at', 'success_rate']
    date_hierarchy = 'date'
    
    fieldsets = (
        ('Date & Currency', {
            'fields': ('date', 'currency')
        }),
        ('Transaction Counts', {
            'fields': ('total_transactions', 'successful_transactions', 'failed_transactions')
        }),
        ('Amounts', {
            'fields': ('total_amount', 'average_amount')
        }),
        ('Metadata', {
            'fields': ('created_at', 'updated_at', 'success_rate'),
            'classes': ('collapse',)
        })
    )
    
    def success_rate(self, obj):
        return f"{obj.success_rate:.2f}%"
    success_rate.short_description = 'Success Rate'
    
    def has_delete_permission(self, request, obj=None):
        # Prevent accidental deletion of analytics data
        return request.user.is_superuser
