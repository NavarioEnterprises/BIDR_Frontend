from django.contrib import admin
from django.utils import timezone
from .models import SecurityPolicy, SecurityAuditLog, BlockedIP, SecurityQuestion, UserSecurityQuestion, TwoFactorMethod

@admin.register(SecurityPolicy)
class SecurityPolicyAdmin(admin.ModelAdmin):
    list_display = ('name', 'policy_type', 'is_active', 'effective_from', 'created_at')
    list_filter = ('policy_type', 'is_active', 'created_at')
    search_fields = ('name', 'description', 'policy_type')
    readonly_fields = ('created_at', 'updated_at')

@admin.register(SecurityAuditLog)
class SecurityAuditLogAdmin(admin.ModelAdmin):
    list_display = ('event_type', 'user', 'ip_address', 'severity', 'timestamp')
    list_filter = ('event_type', 'severity', 'timestamp')
    search_fields = ('event_type', 'user__email', 'ip_address', 'description')
    readonly_fields = ('timestamp', 'created_at', 'updated_at')

    def has_add_permission(self, request):
        return False

    def has_change_permission(self, request, obj=None):
        return False

@admin.register(BlockedIP)
class BlockedIPAdmin(admin.ModelAdmin):
    list_display = ('ip_address', 'reason', 'is_permanent', 'blocked_at', 'blocked_by')
    list_filter = ('is_permanent', 'reason', 'blocked_at')
    search_fields = ('ip_address', 'description', 'blocked_by__email')
    readonly_fields = ('blocked_at', 'created_at', 'updated_at')

@admin.register(SecurityQuestion)
class SecurityQuestionAdmin(admin.ModelAdmin):
    list_display = ('question_text', 'is_active', 'created_at')
    list_filter = ('is_active', 'created_at')
    search_fields = ('question_text',)
    readonly_fields = ('created_at', 'updated_at')

@admin.register(UserSecurityQuestion)
class UserSecurityQuestionAdmin(admin.ModelAdmin):
    list_display = ('user', 'question', 'created_at')
    list_filter = ('created_at',)
    search_fields = ('user__email', 'question__question_text')
    readonly_fields = ('created_at', 'updated_at')

@admin.register(TwoFactorMethod)
class TwoFactorMethodAdmin(admin.ModelAdmin):
    list_display = ('user', 'method_type', 'is_active', 'is_primary', 'last_used', 'created_at')
    list_filter = ('method_type', 'is_active', 'is_primary', 'created_at')
    search_fields = ('user__email', 'identifier')
    readonly_fields = ('created_at', 'updated_at', 'last_used')
