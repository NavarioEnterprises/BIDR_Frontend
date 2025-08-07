from django.contrib import admin
from django.utils.html import format_html
from django.urls import reverse
from django.utils.safestring import mark_safe
from .models import Seller, SellerVettingLog, SellersAddressDetails, SellerBankAccount, CompanyInfo, CompanyContactInfo, BankingInfo, BusinessRegistration, SellerProfile
@admin.register(Seller)
class SellerAdmin(admin.ModelAdmin):
    """
    Admin interface for Seller model
    """
    list_display = [
        'user_email', 'registered_company_name', 'trading_name',
        'product_subcategory', 'is_verified_status', 'created_at_display'
    ]
    list_filter = [
        'product_subcategory', 'user__is_verified', 'user__is_active',
        'created_at', 'is_deleted'
    ]
    search_fields = [
        'user__email', 'user__fullname', 'registered_company_name',
        'trading_name', 'registration_number', 'vat_number'
    ]
    readonly_fields = ['created_at', 'updated_at']
    fieldsets = (
        ('User Information', {
            'fields': ('user',)
        }),
        ('Company Details', {
            'fields': ('registered_company_name', 'trading_name', 'registration_number',
                       'vat_number', 'website_url')
        }),
        ('Product Information', {
            'fields': ('product_category', 'product_subcategory')
        }),
        ('Metadata', {
            'fields': ('is_visible', 'is_hidden', 'is_deleted', 'created_at',
                       'updated_at', 'last_updated_by'),
            'classes': ('collapse',)
        })
    )

    def user_email(self, obj):
        """Display user email with link to user admin"""
        return format_html(
            '<a href="{}">{}</a>',
            reverse('admin:user_appuser_change', args=[obj.user.pk]),
            obj.user.email
        )

    user_email.short_description = 'User Email'
    user_email.admin_order_field = 'user__email'

    def is_verified_status(self, obj):
        """Display verification status with color coding"""
        if obj.user.is_verified:
            return format_html(
                '<span style="color: green;">✓ Verified</span>'
            )
        return format_html(
            '<span style="color: orange;">⏳ Pending</span>'
        )

    is_verified_status.short_description = 'Verification Status'
    is_verified_status.admin_order_field = 'user__is_verified'

    def created_at_display(self, obj):
        """Display formatted creation time"""
        return obj.created_at.strftime('%Y-%m-%d %H:%M')

    created_at_display.short_description = 'Created'
    created_at_display.admin_order_field = 'created_at'

    def get_queryset(self, request):
        """Optimize queryset with select_related"""
        return super().get_queryset(request).select_related('user')

    def save_model(self, request, obj, form, change):
        """Set last_updated_by when saving"""
        if hasattr(request, 'user'):
            obj.last_updated_by = request.user
        super().save_model(request, obj, form, change)


@admin.register(SellerVettingLog)
class SellerVettingLogAdmin(admin.ModelAdmin):
    """
    Admin interface for SellerVettingLog model
    """
    list_display = [
        'seller_email', 'seller_company', 'certificate_status_display',
        'company_extract_status_display', 'all_approved_status', 'created_at_display'
    ]
    list_filter = [
        'certificate_of_incorporation_status', 'company_extract_status',
        'created_at', 'is_deleted'
    ]
    search_fields = [
        'seller__user__email', 'seller__user__fullname',
        'seller__registered_company_name', 'seller__trading_name'
    ]
    readonly_fields = ['created_at', 'updated_at']
    fieldsets = (
        ('Seller Information', {
            'fields': ('seller',)
        }),
        ('Certificate of Incorporation', {
            'fields': ('certificate_of_incorporation', 'certificate_of_incorporation_status')
        }),
        ('Company Extract', {
            'fields': ('company_extract', 'company_extract_status')
        }),
        ('Metadata', {
            'fields': ('is_visible', 'is_hidden', 'is_deleted', 'created_at',
                       'updated_at', 'last_updated_by'),
            'classes': ('collapse',)
        })
    )

    def seller_email(self, obj):
        """Display seller email"""
        return obj.seller.user.email

    seller_email.short_description = 'Seller Email'
    seller_email.admin_order_field = 'seller__user__email'

    def seller_company(self, obj):
        """Display seller company name"""
        return obj.seller.registered_company_name or obj.seller.trading_name or '-'

    seller_company.short_description = 'Company'

    def certificate_status_display(self, obj):
        """Display certificate status with color coding"""
        status = obj.certificate_of_incorporation_status
        colors = {
            'pending': 'orange',
            'approved': 'green',
            'declined': 'red'
        }
        return format_html(
            '<span style="color: {};">{}</span>',
            colors.get(status, 'black'),
            status.title()
        )

    certificate_status_display.short_description = 'Certificate Status'

    def company_extract_status_display(self, obj):
        """Display company extract status with color coding"""
        status = obj.company_extract_status
        colors = {
            'pending': 'orange',
            'approved': 'green',
            'declined': 'red'
        }
        return format_html(
            '<span style="color: {};">{}</span>',
            colors.get(status, 'black'),
            status.title()
        )

    company_extract_status_display.short_description = 'Extract Status'

    def all_approved_status(self, obj):
        """Display overall approval status"""
        if obj.all_documents_approved():
            return format_html(
                '<span style="color: green; font-weight: bold;">✓ All Approved</span>'
            )
        return format_html(
            '<span style="color: orange;">⏳ Pending</span>'
        )

    all_approved_status.short_description = 'Overall Status'

    def created_at_display(self, obj):
        """Display formatted creation time"""
        return obj.created_at.strftime('%Y-%m-%d %H:%M')

    created_at_display.short_description = 'Submitted'
    created_at_display.admin_order_field = 'created_at'

    def get_queryset(self, request):
        """Optimize queryset with select_related"""
        return super().get_queryset(request).select_related('seller__user')

    def save_model(self, request, obj, form, change):
        """Set last_updated_by when saving"""
        if hasattr(request, 'user'):
            obj.last_updated_by = request.user
        super().save_model(request, obj, form, change)

    actions = ['approve_all_documents', 'decline_all_documents']

    def approve_all_documents(self, request, queryset):
        """Approve all documents for selected vetting logs"""
        count = 0
        for vetting_log in queryset:
            vetting_log.certificate_of_incorporation_status = 'approved'
            vetting_log.company_extract_status = 'approved'
            vetting_log.save()

            # Mark seller as verified
            vetting_log.seller.user.is_verified = True
            vetting_log.seller.user.save(update_fields=['is_verified'])
            count += 1

        self.message_user(
            request,
            f'Approved all documents for {count} seller(s).'
        )

    approve_all_documents.short_description = 'Approve all documents'

    def decline_all_documents(self, request, queryset):
        """Decline all documents for selected vetting logs"""
        count = queryset.update(
            certificate_of_incorporation_status='declined',
            company_extract_status='declined'
        )
        self.message_user(
            request,
            f'Declined all documents for {count} seller(s).'
        )

    decline_all_documents.short_description = 'Decline all documents'


@admin.register(SellersAddressDetails)
class SellersAddressDetailsAdmin(admin.ModelAdmin):
    """
    Admin interface for SellersAddressDetails model
    """
    list_display = [
        'seller_email', 'contact_person_name', 'city', 'province',
        'country', 'is_primary_display', 'has_coordinates'
    ]
    list_filter = [
        'is_primary', 'is_billing_address', 'is_shipping_address',
        'city', 'province', 'country', 'is_deleted'
    ]
    search_fields = [
        'user__user__email', 'user__registered_company_name',
        'contact_person_name', 'contact_person_email_address',
        'physical_address', 'city', 'province'
    ]
    readonly_fields = ['uid', 'created_at', 'updated_at']
    fieldsets = (
        ('Seller Information', {
            'fields': ('user', 'uid')
        }),
        ('Address Information', {
            'fields': ('physical_address', 'postal_address', 'city',
                       'province', 'postal_code', 'country')
        }),
        ('Geographic Location', {
            'fields': ('latitude', 'longitude', 'location_address'),
            'description': 'Set the precise coordinates of the business location.'
        }),
        ('Contact Information', {
            'fields': ('contact_person_name', 'contact_person_telephone',
                       'contact_person_email_address', 'platform_workflow_email_address')
        }),
        ('Address Types', {
            'fields': ('is_primary', 'is_billing_address', 'is_shipping_address')
        }),
        ('Metadata', {
            'fields': ('is_visible', 'is_hidden', 'is_deleted', 'created_at',
                       'updated_at', 'last_updated_by'),
            'classes': ('collapse',)
        })
    )

    # Map configuration
    default_zoom = 12
    default_lon = 28.0473  # Johannesburg longitude
    default_lat = -26.2041  # Johannesburg latitude
    map_width = 800
    map_height = 500

    def seller_email(self, obj):
        """Display seller email"""
        return obj.user.user.email

    seller_email.short_description = 'Seller Email'
    seller_email.admin_order_field = 'user__user__email'

    def is_primary_display(self, obj):
        """Display primary status with icon"""
        if obj.is_primary:
            return format_html(
                '<span style="color: green;">★ Primary</span>'
            )
        return format_html(
            '<span style="color: gray;">☆ Secondary</span>'
        )

    is_primary_display.short_description = 'Primary'
    is_primary_display.admin_order_field = 'is_primary'

    def has_coordinates(self, obj):
        """Display whether location coordinates are set"""
        if obj.latitude and obj.longitude:
            return format_html(
                '<span style="color: green;">✓ ({:.4f}, {:.4f})</span>',
                float(obj.latitude), float(obj.longitude)
            )
        return format_html(
            '<span style="color: red;">✗ No coordinates</span>'
        )

    has_coordinates.short_description = 'Coordinates'

    def get_queryset(self, request):
        """Optimize queryset with select_related"""
        return super().get_queryset(request).select_related('user__user')

    def save_model(self, request, obj, form, change):
        """Set last_updated_by when saving"""
        if hasattr(request, 'user'):
            obj.last_updated_by = request.user
        super().save_model(request, obj, form, change)

    actions = ['set_as_primary', 'geocode_addresses']

    def set_as_primary(self, request, queryset):
        """Set selected address as primary for each seller"""
        count = 0
        for address in queryset:
            # First, unset all primary addresses for this seller
            SellersAddressDetails.objects.filter(
                user=address.user, is_primary=True
            ).update(is_primary=False)

            # Set this address as primary
            address.is_primary = True
            address.save(update_fields=['is_primary'])
            count += 1

        self.message_user(
            request,
            f'Set {count} address(es) as primary.'
        )

    set_as_primary.short_description = 'Set as primary address'

    def geocode_addresses(self, request, queryset):
        """Attempt to geocode addresses without coordinates"""
        # This would require a geocoding service like Google Maps API
        # For now, just show a message
        count = queryset.filter(location__isnull=True).count()
        self.message_user(
            request,
            f'Found {count} address(es) without coordinates. '
            'Geocoding service integration required.'
        )

    geocode_addresses.short_description = 'Geocode addresses'


@admin.register(SellerBankAccount)
class SellerBankAccountAdmin(admin.ModelAdmin):
    """
    Admin interface for SellerBankAccount model
    """
    list_display = [
        'user_email', 'bank_name', 'bank_account_type',
        'masked_account_number', 'bank_branch_code', 'created_at_display'
    ]
    list_filter = [
        'bank_name', 'bank_account_type', 'created_at', 'is_deleted'
    ]
    search_fields = [
        'user__email', 'user__fullname', 'bank_name',
        'bank_account_number', 'bank_branch_code'
    ]
    readonly_fields = ['created_at', 'updated_at']
    fieldsets = (
        ('User Information', {
            'fields': ('user',)
        }),
        ('Bank Details', {
            'fields': ('bank_name', 'bank_account_type', 'bank_account_number',
                       'bank_branch_code')
        }),
        ('Metadata', {
            'fields': ('is_visible', 'is_hidden', 'is_deleted', 'created_at',
                       'updated_at', 'last_updated_by'),
            'classes': ('collapse',)
        })
    )

    def user_email(self, obj):
        """Display user email"""
        return obj.user.email

    user_email.short_description = 'User Email'
    user_email.admin_order_field = 'user__email'

    def masked_account_number(self, obj):
        """Display masked account number for security"""
        if obj.bank_account_number:
            if len(obj.bank_account_number) > 4:
                return f"****{obj.bank_account_number[-4:]}"
            return "****"
        return '-'

    masked_account_number.short_description = 'Account Number'

    def created_at_display(self, obj):
        """Display formatted creation time"""
        return obj.created_at.strftime('%Y-%m-%d %H:%M')

    created_at_display.short_description = 'Created'
    created_at_display.admin_order_field = 'created_at'

    def get_queryset(self, request):
        """Optimize queryset with select_related"""
        return super().get_queryset(request).select_related('user')

    def save_model(self, request, obj, form, change):
        """Set last_updated_by when saving"""
        if hasattr(request, 'user'):
            obj.last_updated_by = request.user
        super().save_model(request, obj, form, change)


@admin.register(CompanyInfo)
class CompanyInfoAdmin(admin.ModelAdmin):
    """Admin interface for CompanyInfo model"""
    list_display = ['company_name', 'trading_name', 'registration_number', 'vat_number', 'website_url']
    list_filter = ['created_at', 'is_deleted']
    search_fields = ['company_name', 'trading_name', 'registration_number', 'vat_number']
    readonly_fields = ['created_at', 'updated_at']
    fieldsets = (
        ('Company Information', {
            'fields': ('company_name', 'trading_name', 'registration_number', 'vat_number', 'website_url')
        }),
        ('Documents', {
            'fields': ('cipc_document_path',)
        }),
        ('Metadata', {
            'fields': ('is_visible', 'is_hidden', 'is_deleted', 'created_at', 'updated_at', 'last_updated_by'),
            'classes': ('collapse',)
        })
    )

    def save_model(self, request, obj, form, change):
        if hasattr(request, 'user'):
            obj.last_updated_by = request.user
        super().save_model(request, obj, form, change)


@admin.register(CompanyContactInfo)
class CompanyContactInfoAdmin(admin.ModelAdmin):
    """Admin interface for CompanyContactInfo model"""
    list_display = ['contact_person_name', 'contact_person_email', 'contact_person_telephone', 'platform_workflow_email']
    list_filter = ['created_at', 'is_deleted']
    search_fields = ['contact_person_name', 'contact_person_email', 'postal_address', 'physical_address']
    readonly_fields = ['created_at', 'updated_at']
    fieldsets = (
        ('Contact Person', {
            'fields': ('contact_person_name', 'contact_person_telephone', 'contact_person_email')
        }),
        ('Address Information', {
            'fields': ('postal_address', 'physical_address')
        }),
        ('Location Coordinates', {
            'fields': ('latitude', 'longitude')
        }),
        ('Platform Settings', {
            'fields': ('platform_workflow_email',)
        }),
        ('Metadata', {
            'fields': ('is_visible', 'is_hidden', 'is_deleted', 'created_at', 'updated_at', 'last_updated_by'),
            'classes': ('collapse',)
        })
    )

    def save_model(self, request, obj, form, change):
        if hasattr(request, 'user'):
            obj.last_updated_by = request.user
        super().save_model(request, obj, form, change)


@admin.register(BankingInfo)
class BankingInfoAdmin(admin.ModelAdmin):
    """Admin interface for BankingInfo model"""
    list_display = ['bank_name', 'account_holder', 'masked_account_number', 'branch_code']
    list_filter = ['bank_name', 'created_at', 'is_deleted']
    search_fields = ['bank_name', 'account_holder', 'account_number', 'branch_code']
    readonly_fields = ['created_at', 'updated_at']
    fieldsets = (
        ('Bank Details', {
            'fields': ('bank_name', 'account_number', 'branch_code', 'account_holder')
        }),
        ('Metadata', {
            'fields': ('is_visible', 'is_hidden', 'is_deleted', 'created_at', 'updated_at', 'last_updated_by'),
            'classes': ('collapse',)
        })
    )

    def masked_account_number(self, obj):
        """Display masked account number for security"""
        if obj.account_number:
            if len(obj.account_number) > 4:
                return f"****{obj.account_number[-4:]}"
            return "****"
        return '-'
    
    masked_account_number.short_description = 'Account Number'

    def save_model(self, request, obj, form, change):
        if hasattr(request, 'user'):
            obj.last_updated_by = request.user
        super().save_model(request, obj, form, change)


@admin.register(BusinessRegistration)
class BusinessRegistrationAdmin(admin.ModelAdmin):
    """Admin interface for BusinessRegistration model"""
    list_display = ['seller_email', 'company_name', 'contact_person', 'bank_name', 'product_categories_display']
    list_filter = ['created_at', 'is_deleted']
    search_fields = [
        'seller__user__email', 'company_info__company_name', 
        'contact_info__contact_person_name', 'banking_info__bank_name'
    ]
    readonly_fields = ['created_at', 'updated_at']
    fieldsets = (
        ('Seller', {
            'fields': ('seller',)
        }),
        ('Company Information', {
            'fields': ('company_info',)
        }),
        ('Contact Information', {
            'fields': ('contact_info',)
        }),
        ('Banking Information', {
            'fields': ('banking_info',)
        }),
        ('Product Categories', {
            'fields': ('product_categories',)
        }),
        ('Metadata', {
            'fields': ('is_visible', 'is_hidden', 'is_deleted', 'created_at', 'updated_at', 'last_updated_by'),
            'classes': ('collapse',)
        })
    )

    def seller_email(self, obj):
        return obj.seller.user.email
    seller_email.short_description = 'Seller Email'
    seller_email.admin_order_field = 'seller__user__email'

    def company_name(self, obj):
        return obj.company_info.company_name
    company_name.short_description = 'Company Name'
    company_name.admin_order_field = 'company_info__company_name'

    def contact_person(self, obj):
        return obj.contact_info.contact_person_name
    contact_person.short_description = 'Contact Person'
    contact_person.admin_order_field = 'contact_info__contact_person_name'

    def bank_name(self, obj):
        return obj.banking_info.bank_name
    bank_name.short_description = 'Bank Name'
    bank_name.admin_order_field = 'banking_info__bank_name'

    def product_categories_display(self, obj):
        return ', '.join(obj.product_categories) if obj.product_categories else '-'
    product_categories_display.short_description = 'Product Categories'

    def get_queryset(self, request):
        return super().get_queryset(request).select_related(
            'seller__user', 'company_info', 'contact_info', 'banking_info'
        )

    def save_model(self, request, obj, form, change):
        if hasattr(request, 'user'):
            obj.last_updated_by = request.user
        super().save_model(request, obj, form, change)


@admin.register(SellerProfile)
class SellerProfileAdmin(admin.ModelAdmin):
    """Admin interface for SellerProfile model"""
    list_display = [
        'seller_email', 'vendor_id', 'approval_status', 'display_name_preference', 
        'background_check_status', 'average_rating', 'completion_rate_display'
    ]
    list_filter = [
        'approval_status', 'display_name_preference', 'background_check_authorized',
        'background_check_completed', 'background_check_passed', 'auto_respond_enabled'
    ]
    search_fields = [
        'seller__user__email', 'vendor_id', 'seller__registered_company_name', 'seller__trading_name'
    ]
    readonly_fields = ['id', 'vendor_id', 'created_at', 'updated_at']
    fieldsets = (
        ('Seller Information', {
            'fields': ('seller', 'vendor_id', 'is_active')
        }),
        ('Business Information', {
            'fields': ('approval_status', 'display_name_preference')
        }),
        ('Verification', {
            'fields': ('background_check_authorized', 'background_check_completed', 'background_check_passed')
        }),
        ('Platform Settings', {
            'fields': ('notification_preferences', 'auto_respond_enabled', 'minimum_order_value', 'response_time_hours')
        }),
        ('Performance Metrics', {
            'fields': (
                'total_quotes_submitted', 'total_deals_won', 'total_deals_completed', 
                'average_rating', 'response_rate_percentage'
            )
        }),
        ('Timestamps', {
            'fields': ('application_submitted_at', 'approved_at', 'last_active_at')
        }),
        ('Metadata', {
            'fields': ('is_visible', 'is_hidden', 'is_deleted', 'created_at', 'updated_at', 'last_updated_by'),
            'classes': ('collapse',)
        })
    )

    def seller_email(self, obj):
        return obj.seller.user.email
    seller_email.short_description = 'Seller Email'
    seller_email.admin_order_field = 'seller__user__email'

    def background_check_status(self, obj):
        if obj.background_check_passed:
            return format_html('<span style="color: green;">✓ Passed</span>')
        elif obj.background_check_completed:
            return format_html('<span style="color: red;">✗ Failed</span>')
        elif obj.background_check_authorized:
            return format_html('<span style="color: orange;">⏳ In Progress</span>')
        else:
            return format_html('<span style="color: gray;">Not Authorized</span>')
    background_check_status.short_description = 'Background Check'

    def completion_rate_display(self, obj):
        return f"{obj.completion_rate:.1f}%"
    completion_rate_display.short_description = 'Completion Rate'
    completion_rate_display.admin_order_field = 'total_deals_completed'

    def get_queryset(self, request):
        return super().get_queryset(request).select_related('seller__user')

    def save_model(self, request, obj, form, change):
        if hasattr(request, 'user'):
            obj.last_updated_by = request.user
        super().save_model(request, obj, form, change)

