from django.contrib import admin
from .models import PaymentGateway, Currency, UserProfile, SystemConfiguration


@admin.register(PaymentGateway)
class PaymentGatewayAdmin(admin.ModelAdmin):
    list_display = ['name', 'slug', 'is_active', 'is_enabled', 'created_at']
    list_filter = ['is_active', 'is_enabled', 'created_at']
    search_fields = ['name', 'slug']
    readonly_fields = ['created_at', 'updated_at']
    
    fieldsets = (
        ('Basic Information', {
            'fields': ('name', 'slug', 'is_active', 'is_enabled', 'is_default')
        }),
        ('Configuration', {
            'fields': ('config', 'public_key', 'secret_key', 'webhook_secret')
        }),
        ('URLs', {
            'fields': ('base_url', 'callback_url', 'webhook_url')
        }),
        ('Features', {
            'fields': ('supports_escrow', 'supports_refunds', 'supports_webhooks', 'supports_subscriptions')
        }),
        ('Limits & Fees', {
            'fields': ('min_amount', 'max_amount', 'transaction_fee_percentage', 'fixed_transaction_fee')
        }),
        ('Metadata', {
            'fields': ('supported_currencies', 'supported_countries', 'additional_config')
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        })
    )


@admin.register(Currency)
class CurrencyAdmin(admin.ModelAdmin):
    list_display = ['code', 'name', 'symbol', 'is_base_currency', 'is_supported', 'exchange_rate']
    list_filter = ['is_base_currency', 'is_supported']
    search_fields = ['code', 'name']
    readonly_fields = ['created_at', 'updated_at', 'last_updated']


@admin.register(UserProfile)  
class UserProfileAdmin(admin.ModelAdmin):
    list_display = ['user', 'verification_status', 'total_transactions', 'successful_transactions']
    list_filter = ['verification_status', 'two_factor_enabled', 'email_notifications']
    search_fields = ['user__username', 'user__email', 'phone_number']
    readonly_fields = ['created_at', 'updated_at', 'verified_at']


@admin.register(SystemConfiguration)
class SystemConfigurationAdmin(admin.ModelAdmin):
    list_display = ['key', 'value_type', 'category', 'is_system_managed']
    list_filter = ['value_type', 'category', 'is_system_managed']
    search_fields = ['key', 'description']
    readonly_fields = ['created_at', 'updated_at']
