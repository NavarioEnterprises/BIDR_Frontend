"""
BIDR Sessions Admin

Django admin configuration for session management models.
"""
from django.contrib import admin
from .models import UserSession, SessionActivity, TrustedDevice, SessionSecurityEvent


@admin.register(UserSession)
class UserSessionAdmin(admin.ModelAdmin):
    """Admin interface for UserSession model"""
    
    list_display = [
        'user', 'device_type', 'device_name', 'ip_address', 
        'status', 'is_trusted', 'created_at', 'last_activity'
    ]
    list_filter = [
        'status', 'device_type', 'is_trusted', 'country', 
        'created_at', 'last_activity'
    ]
    search_fields = [
        'user__email', 'device_name', 'ip_address', 
        'browser', 'operating_system'
    ]
    readonly_fields = [
        'uuid', 'session_key', 'created_at', 'last_activity', 
        'terminated_at'
    ]
    fieldsets = (
        ('Basic Information', {
            'fields': ('uuid', 'user', 'session_key', 'status')
        }),
        ('Device Information', {
            'fields': (
                'device_id', 'device_type', 'device_name', 
                'browser', 'browser_version', 'operating_system'
            )
        }),
        ('Network Information', {
            'fields': ('ip_address', 'user_agent')
        }),
        ('Location Information', {
            'fields': ('country', 'city', 'latitude', 'longitude')
        }),
        ('Security', {
            'fields': ('is_trusted', 'security_score', 'risk_factors')
        }),
        ('Timestamps', {
            'fields': (
                'created_at', 'last_activity', 'expires_at', 'terminated_at'
            )
        }),
    )
    date_hierarchy = 'created_at'
    ordering = ['-last_activity']


@admin.register(SessionActivity)
class SessionActivityAdmin(admin.ModelAdmin):
    """Admin interface for SessionActivity model"""
    
    list_display = [
        'session', 'action', 'endpoint', 'method', 
        'status_code', 'response_time', 'timestamp'
    ]
    list_filter = ['action', 'method', 'status_code', 'timestamp']
    search_fields = ['action', 'endpoint', 'session__user__email']
    readonly_fields = ['timestamp']
    date_hierarchy = 'timestamp'
    ordering = ['-timestamp']


@admin.register(TrustedDevice)
class TrustedDeviceAdmin(admin.ModelAdmin):
    """Admin interface for TrustedDevice model"""
    
    list_display = [
        'user', 'device_name', 'device_type', 'is_active', 
        'trusted_at', 'last_used'
    ]
    list_filter = ['device_type', 'is_active', 'trusted_at', 'last_used']
    search_fields = ['user__email', 'device_name', 'device_id']
    readonly_fields = ['uuid', 'trusted_at', 'last_used']
    date_hierarchy = 'trusted_at'
    ordering = ['-last_used']


@admin.register(SessionSecurityEvent)
class SessionSecurityEventAdmin(admin.ModelAdmin):
    """Admin interface for SessionSecurityEvent model"""
    
    list_display = [
        'session', 'event_type', 'severity', 'risk_score',
        'is_resolved', 'detected_at'
    ]
    list_filter = [
        'event_type', 'severity', 'is_resolved', 'detected_at'
    ]
    search_fields = [
        'session__user__email', 'description', 'event_type'
    ]
    readonly_fields = ['uuid', 'detected_at', 'resolved_at']
    fieldsets = (
        ('Event Information', {
            'fields': ('uuid', 'session', 'event_type', 'severity')
        }),
        ('Details', {
            'fields': ('description', 'event_data', 'risk_score')
        }),
        ('Resolution', {
            'fields': ('is_resolved', 'resolved_at', 'resolution_notes')
        }),
        ('Timestamps', {
            'fields': ('detected_at',)
        }),
    )
    date_hierarchy = 'detected_at'
    ordering = ['-detected_at']
