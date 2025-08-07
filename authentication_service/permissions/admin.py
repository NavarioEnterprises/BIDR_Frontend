"""
Django admin interfaces for the roles and permissions system.
"""
from django.contrib import admin
from django.utils.html import format_html
from django.urls import reverse
from django.utils.safestring import mark_safe

from .models import Permission, UserRoleType, RolePermission, UserRole, UserPermission


@admin.register(Permission)
class PermissionAdmin(admin.ModelAdmin):
    """Admin interface for Permission model."""
    
    list_display = ['name', 'type', 'module', 'is_active', 'created_at']
    list_filter = ['type', 'module', 'is_active', 'created_at']
    search_fields = ['name', 'description']
    ordering = ['module', 'name']
    list_per_page = 50
    
    fieldsets = (
        ('Basic Information', {
            'fields': ('name', 'type', 'module', 'description')
        }),
        ('Status', {
            'fields': ('is_active',)
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )
    
    readonly_fields = ['created_at', 'updated_at']
    
    def get_queryset(self, request):
        """Add select_related to reduce database queries."""
        queryset = super().get_queryset(request)
        return queryset.select_related()
    
    actions = ['make_active', 'make_inactive']
    
    @admin.action(description='Mark selected permissions as active')
    def make_active(self, request, queryset):
        """Mark selected permissions as active."""
        queryset.update(is_active=True)
        self.message_user(request, f'Successfully activated {queryset.count()} permissions.')
    
    @admin.action(description='Mark selected permissions as inactive')
    def make_inactive(self, request, queryset):
        """Mark selected permissions as inactive."""
        queryset.update(is_active=False)
        self.message_user(request, f'Successfully deactivated {queryset.count()} permissions.')


class RolePermissionInline(admin.TabularInline):
    """Inline admin for RolePermission."""
    
    model = RolePermission
    extra = 0
    fields = ['permission', 'assigned_by', 'assigned_at', 'is_active']
    readonly_fields = ['assigned_at']
    autocomplete_fields = ['permission']


@admin.register(UserRoleType)
class UserRoleTypeAdmin(admin.ModelAdmin):
    """Admin interface for UserRoleType model."""
    
    list_display = ['role_name', 'company_type', 'role_level', 'permissions_count', 'is_active', 'created_at']
    list_filter = ['company_type', 'role_level', 'role_job_function', 'function_department', 'is_active', 'created_at']
    search_fields = ['role_name']
    ordering = ['company_type', 'role_level', 'role_name']
    list_per_page = 50
    
    fieldsets = (
        ('Basic Information', {
            'fields': ('role_name', 'company_type', 'role_level')
        }),
        ('Job Details', {
            'fields': ('role_job_function', 'function_department')
        }),
        ('Status', {
            'fields': ('is_active',)
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )
    
    readonly_fields = ['created_at', 'updated_at']
    inlines = [RolePermissionInline]
    
    def permissions_count(self, obj):
        """Display the count of permissions for this role."""
        count = obj.permissions.filter(is_active=True).count()
        if count > 0:
            url = reverse('admin:permissions_rolepermission_changelist') + f'?role__id__exact={obj.role_id}'
            return format_html('<a href="{}">{} permissions</a>', url, count)
        return '0 permissions'
    permissions_count.short_description = 'Permissions'
    
    def get_queryset(self, request):
        """Add prefetch_related to reduce database queries."""
        queryset = super().get_queryset(request)
        return queryset.prefetch_related('permissions')
    
    actions = ['make_active', 'make_inactive']
    
    @admin.action(description='Mark selected roles as active')
    def make_active(self, request, queryset):
        """Mark selected roles as active."""
        queryset.update(is_active=True)
        self.message_user(request, f'Successfully activated {queryset.count()} roles.')
    
    @admin.action(description='Mark selected roles as inactive')
    def make_inactive(self, request, queryset):
        """Mark selected roles as inactive."""
        queryset.update(is_active=False)
        self.message_user(request, f'Successfully deactivated {queryset.count()} roles.')


@admin.register(RolePermission)
class RolePermissionAdmin(admin.ModelAdmin):
    """Admin interface for RolePermission model."""
    
    list_display = ['role', 'permission', 'permission_module', 'permission_type', 'assigned_by', 'is_active', 'assigned_at']
    list_filter = ['permission__module', 'permission__type', 'is_active', 'assigned_at']
    search_fields = ['role__role_name', 'permission__name']
    ordering = ['-assigned_at']
    list_per_page = 50
    
    autocomplete_fields = ['role', 'permission']
    
    def permission_module(self, obj):
        """Display the permission module."""
        return obj.permission.get_module_display()
    permission_module.short_description = 'Module'
    
    def permission_type(self, obj):
        """Display the permission type."""
        return obj.permission.get_type_display()
    permission_type.short_description = 'Type'
    
    def get_queryset(self, request):
        """Add select_related to reduce database queries."""
        queryset = super().get_queryset(request)
        return queryset.select_related('role', 'permission')


@admin.register(UserRole)
class UserRoleAdmin(admin.ModelAdmin):
    """Admin interface for UserRole model."""
    
    list_display = ['user_email', 'role', 'assigned_by', 'is_active', 'is_expired_display', 'assigned_at']
    list_filter = ['role__company_type', 'role__role_level', 'is_active', 'assigned_at', 'end_date']
    search_fields = ['user_email', 'role__role_name']
    ordering = ['-assigned_at']
    list_per_page = 50
    
    autocomplete_fields = ['role']
    
    fieldsets = (
        ('Assignment Details', {
            'fields': ('user_email', 'role', 'assigned_by')
        }),
        ('Status & Dates', {
            'fields': ('is_active', 'start_date', 'end_date')
        }),
        ('Timestamps', {
            'fields': ('assigned_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )
    
    readonly_fields = ['assigned_at', 'updated_at']
    
    def is_expired_display(self, obj):
        """Display if the role is expired."""
        if obj.is_expired():
            return format_html('<span style="color: red;">Expired</span>')
        return format_html('<span style="color: green;">Active</span>')
    is_expired_display.short_description = 'Expiry Status'
    
    def get_queryset(self, request):
        """Add select_related to reduce database queries."""
        queryset = super().get_queryset(request)
        return queryset.select_related('role')
    
    actions = ['activate_roles', 'deactivate_roles']
    
    @admin.action(description='Activate selected user roles')
    def activate_roles(self, request, queryset):
        """Activate selected user roles."""
        for user_role in queryset:
            user_role.activate(activated_by=request.user.email)
        self.message_user(request, f'Successfully activated {queryset.count()} user roles.')
    
    @admin.action(description='Deactivate selected user roles')
    def deactivate_roles(self, request, queryset):
        """Deactivate selected user roles."""
        for user_role in queryset:
            user_role.deactivate(deactivated_by=request.user.email)
        self.message_user(request, f'Successfully deactivated {queryset.count()} user roles.')


@admin.register(UserPermission)
class UserPermissionAdmin(admin.ModelAdmin):
    """Admin interface for UserPermission model."""
    
    list_display = ['user_email', 'permission', 'permission_type', 'assigned_by', 'is_active', 'is_expired_display', 'assigned_at']
    list_filter = ['permission__module', 'permission__type', 'permission_type', 'is_active', 'assigned_at', 'end_date']
    search_fields = ['user_email', 'permission__name']
    ordering = ['-assigned_at']
    list_per_page = 50
    
    autocomplete_fields = ['permission']
    
    fieldsets = (
        ('Assignment Details', {
            'fields': ('user_email', 'permission', 'permission_type', 'assigned_by')
        }),
        ('Status & Dates', {
            'fields': ('is_active', 'start_date', 'end_date')
        }),
        ('Timestamps', {
            'fields': ('assigned_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )
    
    readonly_fields = ['assigned_at', 'updated_at']
    
    def is_expired_display(self, obj):
        """Display if the permission is expired."""
        if obj.is_expired():
            return format_html('<span style="color: red;">Expired</span>')
        return format_html('<span style="color: green;">Active</span>')
    is_expired_display.short_description = 'Expiry Status'
    
    def get_queryset(self, request):
        """Add select_related to reduce database queries."""
        queryset = super().get_queryset(request)
        return queryset.select_related('permission')
    
    actions = ['activate_permissions', 'deactivate_permissions']
    
    @admin.action(description='Activate selected user permissions')
    def activate_permissions(self, request, queryset):
        """Activate selected user permissions."""
        for user_permission in queryset:
            user_permission.activate(activated_by=request.user.email)
        self.message_user(request, f'Successfully activated {queryset.count()} user permissions.')
    
    @admin.action(description='Deactivate selected user permissions')
    def deactivate_permissions(self, request, queryset):
        """Deactivate selected user permissions."""
        for user_permission in queryset:
            user_permission.deactivate(deactivated_by=request.user.email)
        self.message_user(request, f'Successfully deactivated {queryset.count()} user permissions.')
