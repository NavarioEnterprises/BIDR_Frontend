from django.contrib import admin

from .models import Buyer, BuyersAddressDetails


class BuyerAdmin(admin.ModelAdmin):
    """Admin configuration for Buyer model"""
    list_display = ('user_email', 'user_full_name', 'is_active', 'created_at', 'updated_at')
    list_filter = ('is_active', 'created_at', 'updated_at')
    search_fields = ('user__email', 'user__first_name', 'user__last_name')
    readonly_fields = ('uid', 'created_at', 'updated_at')
    
    def user_email(self, obj):
        return obj.user.email
    
    def user_full_name(self, obj):
        return f"{obj.user.first_name} {obj.user.last_name}"
    
    user_email.short_description = 'Email'
    user_full_name.short_description = 'Full Name'


class BuyersAddressDetailsAdmin(admin.ModelAdmin):
    """Admin configuration for BuyersAddressDetails model"""
    list_display = ('user_email', 'physical_address', 'contact_person_name', 
                   'contact_person_telephone', 'is_primary', 'created_at')
    list_filter = ('is_primary', 'created_at', 'updated_at')
    search_fields = ('user__email', 'physical_address', 'contact_person_name', 
                    'contact_person_telephone', 'contact_person_email_address')
    readonly_fields = ('uid', 'created_at', 'updated_at')
    
    def user_email(self, obj):
        return obj.user.email
    
    user_email.short_description = 'User Email'


admin.site.register(Buyer, BuyerAdmin)
admin.site.register(BuyersAddressDetails, BuyersAddressDetailsAdmin)
