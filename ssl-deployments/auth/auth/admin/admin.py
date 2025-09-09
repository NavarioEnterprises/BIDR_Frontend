from datetime import timedelta

from django.contrib import admin
from django.utils.html import format_html
from django.utils import timezone

from .models import AdminProfile, AdminActivityLog, AdminNotification


@admin.register(AdminProfile)
class AdminProfileAdmin(admin.ModelAdmin):
    """
    Admin interface for AdminProfile model
    """
    list_display = [
        'user_email', 'employee_id', 'job_title', 'department',
        'access_level', 'is_active_status', 'hire_date', 'last_login_display'
    ]
    list_filter = [
        'department', 'access_level', 'can_approve_sellers',
        'can_manage_users', 'can_access_financial_data', 'can_moderate_content',
        'hire_date', 'is_deleted'
    ]
    search_fields = [
        'user__email', 'user__first_name', 'user__last_name', 'employee_id',
        'job_title', 'office_location'
    ]
    readonly_fields = [
        'uid', 'created_at', 'updated_at', 'last_login_ip',
        'failed_login_attempts', 'account_locked_until'
    ]
    fieldsets = (
        ('User Information', {
            'fields': ('user', 'uid', 'employee_id')
        }),
        ('Job Details', {
            'fields': ('job_title', 'department', 'access_level', 'manager',
                       'hire_date', 'office_location', 'phone_extension')
        }),
        ('Permissions', {
            'fields': ('can_approve_sellers', 'can_manage_users',
                       'can_access_financial_data', 'can_moderate_content'),
            'classes': ('collapse',)
        }),
        ('Emergency Contact', {
            'fields': ('emergency_contact_name', 'emergency_contact_phone',
                       'emergency_contact_relationship'),
            'classes': ('collapse',)
        }),
        ('Security', {
            'fields': ('last_login_ip', 'failed_login_attempts', 'account_locked_until'),
            'classes': ('collapse',)
        }),
        ('Metadata', {
            'fields': ('is_visible', 'is_hidden', 'is_deleted', 'created_at',
                       'updated_at', 'last_updated_by'),
            'classes': ('collapse',)
        }),
        ('Notes', {
            'fields': ('notes',),
            'classes': ('collapse',)
        })
    )

    def user_email(self, obj):
        """Display user email"""
        return obj.user.email

    user_email.short_description = 'Email'
    user_email.admin_order_field = 'user__email'

    def is_active_status(self, obj):
        """Display active status with color coding"""
        if obj.user.is_active:
            if obj.is_account_locked():
                return format_html(
                    '<span style="color: orange;">🔒 Locked</span>'
                )
            return format_html(
                '<span style="color: green;">✓ Active</span>'
            )
        return format_html(
            '<span style="color: red;">✗ Inactive</span>'
        )

    is_active_status.short_description = 'Status'

    def last_login_display(self, obj):
        """Display last login time"""
        if obj.user.last_login:
            return obj.user.last_login.strftime('%Y-%m-%d %H:%M')
        return 'Never'

    last_login_display.short_description = 'Last Login'
    last_login_display.admin_order_field = 'user__last_login'

    def get_queryset(self, request):
        """Optimize queryset with select_related"""
        return super().get_queryset(request).select_related('user', 'manager__user')

    def save_model(self, request, obj, form, change):
        """Set last_updated_by when saving"""
        if hasattr(request, 'user'):
            obj.last_updated_by = request.user
        super().save_model(request, obj, form, change)

    actions = ['unlock_accounts', 'reset_failed_logins']

    def unlock_accounts(self, request, queryset):
        """Unlock selected admin accounts"""
        count = 0
        for admin_profile in queryset:
            if admin_profile.is_account_locked():
                admin_profile.unlock_account()
                count += 1

        self.message_user(
            request,
            f'Successfully unlocked {count} admin account(s).'
        )

    unlock_accounts.short_description = 'Unlock selected accounts'

    def reset_failed_logins(self, request, queryset):
        """Reset failed login attempts for selected accounts"""
        count = queryset.update(failed_login_attempts=0)
        self.message_user(
            request,
            f'Reset failed login attempts for {count} admin account(s).'
        )

    reset_failed_logins.short_description = 'Reset failed login attempts'


@admin.register(AdminActivityLog)
class AdminActivityLogAdmin(admin.ModelAdmin):
    """
    Admin interface for AdminActivityLog model
    """
    list_display = [
        'admin_name', 'action', 'target_user_email', 'ip_address',
        'created_at_display'
    ]
    list_filter = [
        'action', 'created_at', 'admin__department', 'admin__access_level'
    ]
    search_fields = [
        'admin__user__email', 'admin__user__first_name', 'admin__user__last_name',
        'target_user__email', 'description', 'ip_address'
    ]
    readonly_fields = [
        'admin', 'action', 'target_user', 'description', 'ip_address',
        'user_agent', 'additional_data', 'created_at', 'updated_at'
    ]
    date_hierarchy = 'created_at'

    def admin_name(self, obj):
        """Display admin name"""
        return f"{obj.admin.user.first_name} {obj.admin.user.last_name}"

    admin_name.short_description = 'Admin'
    admin_name.admin_order_field = 'admin__user__first_name'

    def target_user_email(self, obj):
        """Display target user email"""
        return obj.target_user.email if obj.target_user else '-'

    target_user_email.short_description = 'Target User'
    target_user_email.admin_order_field = 'target_user__email'

    def created_at_display(self, obj):
        """Display formatted creation time"""
        return obj.created_at.strftime('%Y-%m-%d %H:%M:%S')

    created_at_display.short_description = 'Date/Time'
    created_at_display.admin_order_field = 'created_at'

    def get_queryset(self, request):
        """Optimize queryset with select_related"""
        return super().get_queryset(request).select_related(
            'admin__user', 'target_user'
        )

    def has_add_permission(self, request):
        """Disable manual addition of activity logs"""
        return False

    def has_change_permission(self, request, obj=None):
        """Disable editing of activity logs"""
        return False

    def has_delete_permission(self, request, obj=None):
        """Only allow deletion for superusers"""
        return request.user.is_superuser


@admin.register(AdminNotification)
class AdminNotificationAdmin(admin.ModelAdmin):
    """
    Admin interface for AdminNotification model
    """
    list_display = [
        'admin_name', 'title', 'notification_type', 'priority',
        'is_read_status', 'created_at_display', 'expires_at_display'
    ]
    list_filter = [
        'notification_type', 'priority', 'is_read', 'created_at',
        'expires_at', 'admin__department'
    ]
    search_fields = [
        'admin__user__email', 'admin__user__first_name', 'admin__user__last_name',
        'title', 'message'
    ]
    readonly_fields = [
        'created_at', 'updated_at', 'read_at'
    ]
    fieldsets = (
        ('Notification Details', {
            'fields': ('admin', 'title', 'message', 'notification_type', 'priority')
        }),
        ('Action', {
            'fields': ('action_url', 'action_label'),
            'classes': ('collapse',)
        }),
        ('Status', {
            'fields': ('is_read', 'read_at', 'expires_at')
        }),
        ('Metadata', {
            'fields': ('is_visible', 'is_hidden', 'is_deleted', 'created_at',
                       'updated_at', 'last_updated_by'),
            'classes': ('collapse',)
        })
    )
    date_hierarchy = 'created_at'

    def admin_name(self, obj):
        """Display admin name"""
        return f"{obj.admin.user.first_name} {obj.admin.user.last_name}"

    admin_name.short_description = 'Admin'
    admin_name.admin_order_field = 'admin__user__first_name'

    def is_read_status(self, obj):
        """Display read status with color coding"""
        if obj.is_read:
            return format_html(
                '<span style="color: green;">✓ Read</span>'
            )
        elif obj.is_expired():
            return format_html(
                '<span style="color: red;">⚠ Expired</span>'
            )
        return format_html(
            '<span style="color: orange;">● Unread</span>'
        )

    is_read_status.short_description = 'Status'

    def created_at_display(self, obj):
        """Display formatted creation time"""
        return obj.created_at.strftime('%Y-%m-%d %H:%M')

    created_at_display.short_description = 'Created'
    created_at_display.admin_order_field = 'created_at'

    def expires_at_display(self, obj):
        """Display formatted expiration time"""
        if obj.expires_at:
            return obj.expires_at.strftime('%Y-%m-%d %H:%M')
        return 'Never'

    expires_at_display.short_description = 'Expires'
    expires_at_display.admin_order_field = 'expires_at'

    def get_queryset(self, request):
        """Optimize queryset with select_related"""
        return super().get_queryset(request).select_related('admin__user')

    def save_model(self, request, obj, form, change):
        """Set last_updated_by when saving"""
        if hasattr(request, 'user'):
            obj.last_updated_by = request.user
        super().save_model(request, obj, form, change)

    actions = ['mark_as_read', 'mark_as_unread', 'extend_expiration']

    def mark_as_read(self, request, queryset):
        """Mark selected notifications_service as read"""
        count = 0
        for notification in queryset.filter(is_read=False):
            notification.mark_as_read()
            count += 1

        self.message_user(
            request,
            f'Marked {count} notification(s) as read.'
        )

    mark_as_read.short_description = 'Mark as read'

    def mark_as_unread(self, request, queryset):
        """Mark selected notifications_service as unread"""
        count = queryset.filter(is_read=True).update(
            is_read=False,
            read_at=None
        )
        self.message_user(
            request,
            f'Marked {count} notification(s) as unread.'
        )

    mark_as_unread.short_description = 'Mark as unread'

    def extend_expiration(self, request, queryset):
        """Extend expiration by 7 days"""
        count = 0
        for notification in queryset:
            if notification.expires_at:
                notification.expires_at = notification.expires_at + timedelta(days=7)
            else:
                notification.expires_at = timezone.now() + timedelta(days=7)
            notification.save(update_fields=['expires_at'])
            count += 1

        self.message_user(
            request,
            f'Extended expiration for {count} notification(s) by 7 days.'
        )

    extend_expiration.short_description = 'Extend expiration by 7 days'

