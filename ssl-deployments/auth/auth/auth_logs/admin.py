from django.contrib import admin

from .models import AuthenticationLog, SecurityEvent, LoginSession, AuditTrail, SuspiciousActivity


class AuthenticationLogAdmin(admin.ModelAdmin):
    list_display = ('user_email', 'action', 'status', 'ip_address', 'timestamp')
    search_fields = ('user_email', 'user_id', 'ip_address', 'device_id')
    list_filter = ('action', 'status', 'user_type', 'timestamp')
    readonly_fields = ('timestamp', 'processed_at')


class SecurityEventAdmin(admin.ModelAdmin):
    list_display = ('title', 'user_email', 'event_type', 'severity', 'status', 'detected_at')
    search_fields = ('user_email', 'title', 'description')
    list_filter = ('event_type', 'severity', 'status', 'detected_at')
    readonly_fields = ('detected_at', 'last_updated')


class LoginSessionAdmin(admin.ModelAdmin):
    list_display = ('user_email', 'ip_address', 'is_active', 'login_timestamp', 'last_activity')
    search_fields = ('user_email', 'session_id', 'ip_address', 'device_id')
    list_filter = ('is_active', 'login_timestamp', 'last_activity')
    readonly_fields = ('login_timestamp', 'last_activity')


class AuditTrailAdmin(admin.ModelAdmin):
    list_display = ('admin_email', 'action', 'target_user_email', 'timestamp')
    search_fields = ('admin_email', 'target_user_email', 'description')
    list_filter = ('action', 'timestamp')
    readonly_fields = ('timestamp',)


class SuspiciousActivityAdmin(admin.ModelAdmin):
    list_display = ('activity_type', 'severity', 'status', 'user_email', 'description', 'detected_at')
    search_fields = ('user_email', 'description', 'source_ip')
    list_filter = ('activity_type', 'severity', 'status', 'detected_at')
    readonly_fields = ('detected_at',)


admin.site.register(SecurityEvent, SecurityEventAdmin)
admin.site.register(LoginSession, LoginSessionAdmin)
admin.site.register(AuditTrail, AuditTrailAdmin)
admin.site.register(AuthenticationLog, AuthenticationLogAdmin)
admin.site.register(SuspiciousActivity, SuspiciousActivityAdmin)
