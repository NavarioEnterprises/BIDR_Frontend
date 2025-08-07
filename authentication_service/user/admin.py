from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from django.utils.html import format_html
from django.urls import reverse
from django.utils import timezone
from django.db.models import Count, Q
from django.contrib.admin import SimpleListFilter

from .models import AppUser, Address, MetadataModel


class RoleFilter(SimpleListFilter):
    """Custom filter for user roles"""
    title = 'Role'
    parameter_name = 'role'

    def lookups(self, request, model_admin):
        return AppUser.ROLE_CHOICES

    def queryset(self, request, queryset):
        if self.value():
            return queryset.filter(role=self.value())
        return queryset


class VerificationStatusFilter(SimpleListFilter):
    """Custom filter for verification status"""
    title = 'Verification Status'
    parameter_name = 'verification_status'

    def lookups(self, request, model_admin):
        return (
            ('verified', 'Verified'),
            ('unverified', 'Unverified'),
            ('email_verified', 'Email Verified Only'),
            ('phone_verified', 'Phone Verified Only'),
        )

    def queryset(self, request, queryset):
        if self.value() == 'verified':
            return queryset.filter(is_verified=True, email_verified=True, phone_verified=True)
        elif self.value() == 'unverified':
            return queryset.filter(is_verified=False)
        elif self.value() == 'email_verified':
            return queryset.filter(email_verified=True, phone_verified=False)
        elif self.value() == 'phone_verified':
            return queryset.filter(phone_verified=True, email_verified=False)
        return queryset


class AddressInline(admin.TabularInline):
    """Inline for editing addresses within user admin"""
    model = Address
    fk_name = 'user'
    extra = 0
    fields = [
        'address_type', 'address_line_1', 'city', 'state_province', 
        'postal_code', 'country', 'is_primary', 'is_visible'
    ]
    readonly_fields = ['address_id', 'created_at', 'updated_at']
    
    def get_queryset(self, request):
        """Only show non-deleted addresses"""
        return super().get_queryset(request).filter(is_deleted=False)


@admin.register(AppUser)
class AppUserAdmin(BaseUserAdmin):
    """
    Custom admin for AppUser with role-based permissions
    """
    list_display = [
        'email', 'first_name', 'last_name', 'role_display', 'verification_status',
        'account_status', 'last_login_display', 'created_at_display'
    ]
    list_filter = [
        RoleFilter, VerificationStatusFilter, 'is_active', 'is_suspended',
        'created_at', 'last_login'
    ]
    search_fields = ['email', 'first_name', 'last_name', 'phone_number', 'uid']
    ordering = ['-created_at']
    readonly_fields = [
        'uid', 'created_at', 'updated_at', 'last_login', 'date_joined'
    ]
    inlines = [AddressInline]

    fieldsets = (
        ('User Information', {
            'fields': ('uid', 'email', 'fullname', 'phone_number', 'alternative_phone')
        }),
        ('Personal Information', {
            'fields': ('middle_name', 'date_of_birth', 'gender', 'profile_picture'),
            'classes': ('collapse',)
        }),
        ('Authentication', {
            'fields': ('password', 'last_login')
        }),
        ('Verification Status', {
            'fields': ('email_verified', 'phone_verified', 'is_verified', 'kyc_verified', 'identity_verified')
        }),
        ('Role & Permissions', {
            'fields': ('role', 'is_active', 'is_staff', 'is_superuser', 'is_suspended')
        }),
        ('Profile & Preferences', {
            'fields': (
                'bio', 'website', 'occupation', 'company', 'emergency_contact_name', 'emergency_contact_phone',
                'preferred_language', 'timezone', 'currency', 'notification_preferences',
                'marketing_preferences', 'data_sharing_consent'
            ),
            'classes': ('collapse',)
        }),
        ('Privacy & Security', {
            'fields': (
                'profile_visibility', 'two_factor_enabled', 'login_alerts_enabled',
                'data_export_requested', 'account_deletion_requested'
            ),
            'classes': ('collapse',)
        }),
        ('Account Status', {
            'fields': (
                'email_bounce_count', 'failed_login_attempts', 'account_locked_until',
                'password_changed_at', 'terms_accepted_at', 'privacy_policy_accepted_at'
            ),
            'classes': ('collapse',)
        }),
        ('OTP Settings', {
            'fields': ('otp_type',),
            'classes': ('collapse',)
        }),
        ('Groups & Permissions', {
            'fields': ('groups', 'user_permissions'),
            'classes': ('collapse',)
        }),
        ('Important Dates', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        })
    )

    add_fieldsets = (
        ('User Information', {
            'classes': ('wide',),
            'fields': ('email', 'fullname', 'phone_number', 'role', 'password1', 'password2')
        }),
    )

    def role_display(self, obj):
        """Display role with color coding"""
        colors = {
            'administrator': 'red',
            'seller': 'blue',
            'buyer': 'green'
        }
        return format_html(
            '<span style="color: {}; font-weight: bold;">{}</span>',
            colors.get(obj.role, 'black'),
            obj.get_role_display()
        )

    role_display.short_description = 'Role'
    role_display.admin_order_field = 'role'

    def verification_status(self, obj):
        """Display comprehensive verification status"""
        statuses = []

        if obj.is_verified:
            statuses.append('<span style="color: green;">✓ Verified</span>')
        else:
            statuses.append('<span style="color: red;">✗ Not Verified</span>')

        if obj.email_verified:
            statuses.append('<span style="color: green;">📧 Email</span>')
        else:
            statuses.append('<span style="color: orange;">📧 Email</span>')

        if obj.phone_verified:
            statuses.append('<span style="color: green;">📱 Phone</span>')
        else:
            statuses.append('<span style="color: orange;">📱 Phone</span>')

        return format_html(' | '.join(statuses))

    verification_status.short_description = 'Verification'

    def account_status(self, obj):
        """Display account status with icons"""
        if obj.is_suspended:
            return format_html(
                '<span style="color: red;">🚫 Suspended</span>'
            )
        elif not obj.is_active:
            return format_html(
                '<span style="color: orange;">⏸ Inactive</span>'
            )
        else:
            return format_html(
                '<span style="color: green;">✅ Active</span>'
            )

    account_status.short_description = 'Status'
    account_status.admin_order_field = 'is_active'

    def last_login_display(self, obj):
        """Display formatted last login"""
        if obj.last_login:
            return obj.last_login.strftime('%Y-%m-%d %H:%M')
        return 'Never'

    last_login_display.short_description = 'Last Login'
    last_login_display.admin_order_field = 'last_login'

    def created_at_display(self, obj):
        """Display formatted creation date"""
        return obj.created_at.strftime('%Y-%m-%d %H:%M')

    created_at_display.short_description = 'Created'
    created_at_display.admin_order_field = 'created_at'

    def get_queryset(self, request):
        """Optimize queryset and add annotations"""
        return super().get_queryset(request).annotate(
            otp_count=Count('otps')
        )

    def has_change_permission(self, request, obj=None):
        """Role-based change permissions"""
        if not request.user.is_authenticated:
            return False

        # Superusers can change anything
        if request.user.is_superuser:
            return True

        # Administrators can change non-admin user
        if request.user.role == 'administrator':
            if obj is None:  # List view
                return True
            # Cannot change other administrators or superusers
            return obj.role != 'administrator' and not obj.is_superuser

        # Users can only change their own profile (limited fields)
        if obj:
            return obj.pk == request.user.pk

        return False

    def has_delete_permission(self, request, obj=None):
        """Role-based delete permissions"""
        if not request.user.is_authenticated:
            return False

        # Only superusers can delete user
        if request.user.is_superuser:
            return True

        # Administrators can delete non-admin user
        if request.user.role == 'administrator':
            if obj is None:
                return True
            return obj.role != 'administrator' and not obj.is_superuser

        return False

    def get_readonly_fields(self, request, obj=None):
        """Dynamic readonly fields based on user role"""
        readonly = list(self.readonly_fields)

        if not request.user.is_superuser:
            if request.user.role == 'administrator':
                # Admins cannot change certain sensitive fields
                readonly.extend(['is_superuser', 'is_staff'])

                # Admins cannot change other admin roles
                if obj and obj.role == 'administrator':
                    readonly.extend(['role', 'is_active', 'is_suspended'])
            else:
                # Regular user can only change limited fields
                readonly.extend([
                    'role', 'is_active', 'is_staff', 'is_superuser', 'is_suspended',
                    'email_verified', 'phone_verified', 'is_verified',
                    'groups', 'user_permissions'
                ])

        return readonly

    actions = [
        'verify_users', 'unverify_users', 'suspend_users', 'unsuspend_users',
        'activate_users', 'deactivate_users', 'send_verification_email'
    ]

    def verify_users(self, request, queryset):
        """Mark selected user as verified"""
        if request.user.role != 'administrator' and not request.user.is_superuser:
            self.message_user(request, "Only administrators can verify user.", level='ERROR')
            return

        count = queryset.update(is_verified=True)
        self.message_user(request, f'Verified {count} user(s).')

    verify_users.short_description = 'Mark as verified'

    def unverify_users(self, request, queryset):
        """Mark selected user as unverified"""
        if request.user.role != 'administrator' and not request.user.is_superuser:
            self.message_user(request, "Only administrators can unverify user.", level='ERROR')
            return

        count = queryset.update(is_verified=False)
        self.message_user(request, f'Unverified {count} user(s).')

    unverify_users.short_description = 'Mark as unverified'

    def suspend_users(self, request, queryset):
        """Suspend selected user"""
        if request.user.role != 'administrator' and not request.user.is_superuser:
            self.message_user(request, "Only administrators can suspend user.", level='ERROR')
            return

        # Prevent suspending administrators
        admin_users = queryset.filter(role='administrator').count()
        if admin_users > 0:
            self.message_user(
                request,
                f"Cannot suspend {admin_users} administrator(s). Only non-admin user can be suspended.",
                level='WARNING'
            )

        count = queryset.exclude(role='administrator').update(is_suspended=True)
        self.message_user(request, f'Suspended {count} user(s).')

    suspend_users.short_description = 'Suspend user'

    def unsuspend_users(self, request, queryset):
        """Unsuspend selected user"""
        if request.user.role != 'administrator' and not request.user.is_superuser:
            self.message_user(request, "Only administrators can unsuspend user.", level='ERROR')
            return

        count = queryset.update(is_suspended=False)
        self.message_user(request, f'Unsuspended {count} user(s).')

    unsuspend_users.short_description = 'Unsuspend user'

    def activate_users(self, request, queryset):
        """Activate selected user"""
        if request.user.role != 'administrator' and not request.user.is_superuser:
            self.message_user(request, "Only administrators can activate user.", level='ERROR')
            return

        count = queryset.update(is_active=True)
        self.message_user(request, f'Activated {count} user(s).')

    activate_users.short_description = 'Activate user'

    def deactivate_users(self, request, queryset):
        """Deactivate selected user"""
        if request.user.role != 'administrator' and not request.user.is_superuser:
            self.message_user(request, "Only administrators can deactivate user.", level='ERROR')
            return

        # Prevent deactivating administrators
        admin_users = queryset.filter(role='administrator').count()
        if admin_users > 0:
            self.message_user(
                request,
                f"Cannot deactivate {admin_users} administrator(s).",
                level='WARNING'
            )

        count = queryset.exclude(role='administrator').update(is_active=False)
        self.message_user(request, f'Deactivated {count} user(s).')

    deactivate_users.short_description = 'Deactivate user'

    def send_verification_email(self, request, queryset):
        """Send verification email to selected user"""
        if request.user.role != 'administrator' and not request.user.is_superuser:
            self.message_user(request, "Only administrators can send verification emails.", level='ERROR')
            return

        # This would integrate with email service
        count = queryset.filter(email_verified=False).count()
        self.message_user(
            request,
            f'Verification emails would be sent to {count} user(s). Email service integration required.'
        )

    send_verification_email.short_description = 'Send verification email'


class AddressTypeFilter(SimpleListFilter):
    """Custom filter for address types"""
    title = 'Address Type'
    parameter_name = 'address_type'

    def lookups(self, request, model_admin):
        return Address.ADDRESS_TYPE_CHOICES

    def queryset(self, request, queryset):
        if self.value():
            return queryset.filter(address_type=self.value())
        return queryset


class PrimaryAddressFilter(SimpleListFilter):
    """Custom filter for primary addresses"""
    title = 'Primary Address'
    parameter_name = 'is_primary'

    def lookups(self, request, model_admin):
        return (
            ('yes', 'Primary'),
            ('no', 'Not Primary'),
        )

    def queryset(self, request, queryset):
        if self.value() == 'yes':
            return queryset.filter(is_primary=True)
        elif self.value() == 'no':
            return queryset.filter(is_primary=False)
        return queryset


@admin.register(Address)
class AddressAdmin(admin.ModelAdmin):
    """Admin interface for Address model"""
    list_display = [
        'user_display', 'address_type', 'address_preview', 'city', 'country',
        'is_primary', 'primary_status_display', 'visibility_status', 'created_at_display'
    ]
    list_filter = [
        AddressTypeFilter, PrimaryAddressFilter, 'country', 'is_visible', 'created_at'
    ]
    search_fields = [
        'user__email', 'user__first_name', 'user__last_name',
        'address_line_1', 'city', 'state_province', 'postal_code', 'country'
    ]
    ordering = ['-created_at']
    readonly_fields = ['address_id', 'created_at', 'updated_at']
    
    fieldsets = (
        ('Address Information', {
            'fields': ('address_id', 'user', 'address_type', 'address_name')
        }),
        ('Location Details', {
            'fields': (
                'address_line_1', 'address_line_2', 'city', 'state_province',
                'postal_code', 'country', 'latitude', 'longitude'
            )
        }),
        ('Settings', {
            'fields': ('is_primary', 'is_visible'),
            'classes': ('wide',)
        }),
        ('Metadata', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        })
    )
    
    def user_display(self, obj):
        """Display user with link to user admin"""
        return format_html(
            '<a href="{}">{}</a>',
            reverse('admin:user_appuser_change', args=[obj.user.pk]),
            obj.user.email
        )
    user_display.short_description = 'User'
    user_display.admin_order_field = 'user__email'
    
    def address_preview(self, obj):
        """Display formatted address preview"""
        try:
            address_data = obj.get_decrypted_data()
            street = address_data.get('address_line_1', 'N/A')
            return f"{street[:30]}..." if len(street) > 30 else street
        except Exception:
            return "[Encrypted]"
    address_preview.short_description = 'Address'
    
    def primary_status_display(self, obj):
        """Display primary status with icon"""
        if obj.is_primary:
            return format_html('<span style="color: green;">⭐ Primary</span>')
        return format_html('<span style="color: gray;">-</span>')
    primary_status_display.short_description = 'Primary'
    primary_status_display.admin_order_field = 'is_primary'
    
    def visibility_status(self, obj):
        """Display visibility status with icon"""
        if obj.is_visible:
            return format_html('<span style="color: green;">👁 Visible</span>')
        return format_html('<span style="color: orange;">🚫 Hidden</span>')
    visibility_status.short_description = 'Visibility'
    visibility_status.admin_order_field = 'is_visible'
    
    def created_at_display(self, obj):
        """Display formatted creation date"""
        return obj.created_at.strftime('%Y-%m-%d %H:%M')
    created_at_display.short_description = 'Created'
    created_at_display.admin_order_field = 'created_at'
    
    def get_queryset(self, request):
        """Optimize queryset and exclude soft-deleted addresses"""
        return super().get_queryset(request).select_related('user').filter(is_deleted=False)
    
    actions = ['mark_as_primary', 'mark_as_visible', 'mark_as_hidden', 'soft_delete_addresses']
    
    def mark_as_primary(self, request, queryset):
        """Mark selected addresses as primary (one per user per type)"""
        if request.user.role != 'administrator' and not request.user.is_superuser:
            self.message_user(request, "Only administrators can modify primary addresses.", level='ERROR')
            return
        
        updated = 0
        for address in queryset:
            # First, unset other primary addresses of the same type for this user
            Address.objects.filter(
                user=address.user,
                address_type=address.address_type,
                is_primary=True
            ).exclude(pk=address.pk).update(is_primary=False)
            
            # Then set this address as primary
            address.is_primary = True
            address.save()
            updated += 1
        
        self.message_user(request, f'Set {updated} address(es) as primary.')
    mark_as_primary.short_description = 'Set as primary address'
    
    def mark_as_visible(self, request, queryset):
        """Mark selected addresses as visible"""
        count = queryset.update(is_visible=True)
        self.message_user(request, f'Made {count} address(es) visible.')
    mark_as_visible.short_description = 'Make visible'
    
    def mark_as_hidden(self, request, queryset):
        """Mark selected addresses as hidden"""
        count = queryset.update(is_visible=False)
        self.message_user(request, f'Made {count} address(es) hidden.')
    mark_as_hidden.short_description = 'Make hidden'
    
    def soft_delete_addresses(self, request, queryset):
        """Soft delete selected addresses"""
        if request.user.role != 'administrator' and not request.user.is_superuser:
            self.message_user(request, "Only administrators can delete addresses.", level='ERROR')
            return
        
        count = queryset.update(is_deleted=True, is_visible=False)
        self.message_user(request, f'Soft deleted {count} address(es).')
    soft_delete_addresses.short_description = 'Soft delete addresses'

