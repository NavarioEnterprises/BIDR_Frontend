from django.contrib import admin
from django.utils.html import format_html
from django.urls import reverse
from django.utils import timezone

from .models import OTP


@admin.register(OTP)
class OTPAdmin(admin.ModelAdmin):
    """
    Admin interface for OTP model
    """
    list_display = [
        'user_email', 'otp_masked', 'created_at_display',
        'expires_at_display', 'is_expired_status', 'is_verified_status'
    ]
    list_filter = ['created_at', 'expires_at', 'verified_at']
    search_fields = ['user__email', 'user__fullname', 'otp']
    readonly_fields = [
        'user', 'otp', 'created_at', 'expires_at', 'verified_at', 'devices'
    ]
    date_hierarchy = 'created_at'

    def user_email(self, obj):
        """Display user email with link"""
        return format_html(
            '<a href="{}">{}</a>',
            reverse('admin:user_appuser_change', args=[obj.user.pk]),
            obj.user.email
        )

    user_email.short_description = 'User'
    user_email.admin_order_field = 'user__email'

    def otp_masked(self, obj):
        """Display masked OTP for security"""
        return f"***{obj.otp[-2:]}" if len(obj.otp) >= 2 else "***"

    otp_masked.short_description = 'OTP'

    def created_at_display(self, obj):
        """Display formatted creation time"""
        return obj.created_at.strftime('%Y-%m-%d %H:%M:%S')

    created_at_display.short_description = 'Created'
    created_at_display.admin_order_field = 'created_at'

    def expires_at_display(self, obj):
        """Display formatted expiration time"""
        return obj.expires_at.strftime('%Y-%m-%d %H:%M:%S')

    expires_at_display.short_description = 'Expires'
    expires_at_display.admin_order_field = 'expires_at'

    def is_expired_status(self, obj):
        """Display expiration status"""
        if obj.is_expired():
            return format_html(
                '<span style="color: red;">⚠ Expired</span>'
            )
        return format_html(
            '<span style="color: green;">✓ Valid</span>'
        )

    is_expired_status.short_description = 'Status'

    def is_verified_status(self, obj):
        """Display verification status"""
        if obj.verified_at:
            return format_html(
                '<span style="color: green;">✓ Verified</span>'
            )
        return format_html(
            '<span style="color: orange;">⏳ Pending</span>'
        )

    is_verified_status.short_description = 'Verified'

    def get_queryset(self, request):
        """Optimize queryset with select_related"""
        return super().get_queryset(request).select_related('user')

    def has_add_permission(self, request):
        """Disable manual OTP creation"""
        return False

    def has_change_permission(self, request, obj=None):
        """Disable OTP editing"""
        return False

    def has_delete_permission(self, request, obj=None):
        """Only allow deletion for administrators"""
        return request.user.role == 'administrator' or request.user.is_superuser

    actions = ['invalidate_otps']

    def invalidate_otps(self, request, queryset):
        """Invalidate selected OTPs"""
        if request.user.role != 'administrator' and not request.user.is_superuser:
            self.message_user(request, "Only administrators can invalidate OTPs.", level='ERROR')
            return

        count = queryset.filter(verified_at__isnull=True).update(
            verified_at=timezone.now()
        )
        self.message_user(request, f'Invalidated {count} OTP(s).')

    invalidate_otps.short_description = 'Invalidate OTPs'
