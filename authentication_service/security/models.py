from django.db import models
from django.utils import timezone

from import_helper import setup_imports
setup_imports()
from user.models import MetadataModel, AppUser


class SecurityPolicy(MetadataModel):
    """
    Defines security policies for the system
    """
    POLICY_TYPE_CHOICES = (
        ('authentication', 'Authentication'),
        ('authorization', 'Authorization'),
        ('data_protection', 'Data Protection'),
        ('password', 'Password'),
        ('session', 'Session'),
        ('api', 'API Security'),
        ('device', 'Device Security'),
        ('network', 'Network Security'),
        ('audit', 'Audit and Logging'),
        ('general', 'General Security'),
    )

    name = models.CharField(max_length=100)
    policy_type = models.CharField(max_length=20, choices=POLICY_TYPE_CHOICES)
    description = models.TextField()
    policy_data = models.JSONField(help_text="Policy configuration in JSON format")
    is_active = models.BooleanField(default=True)
    version = models.CharField(max_length=20)
    effective_from = models.DateTimeField(default=timezone.now)
    effective_to = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    created_by = models.ForeignKey(AppUser, on_delete=models.SET_NULL, null=True,
                                   related_name='created_security_policies')

    def __str__(self):
        return f"{self.name} v{self.version}"

    class Meta:
        db_table = "security_policy"
        verbose_name = "Security Policy"
        verbose_name_plural = "Security Policies"
        ordering = ['policy_type', '-version']
        unique_together = ('name', 'version')


class SecurityAuditLog(MetadataModel):
    """
    Records security-related events for audit purposes
    """
    EVENT_TYPE_CHOICES = (
        ('login', 'Login'),
        ('logout', 'Logout'),
        ('login_failed', 'Login Failed'),
        ('password_change', 'Password Change'),
        ('password_reset', 'Password Reset'),
        ('account_locked', 'Account Locked'),
        ('account_unlocked', 'Account Unlocked'),
        ('permission_change', 'Permission Change'),
        ('role_change', 'Role Change'),
        ('sensitive_data_access', 'Sensitive Data Access'),
        ('security_setting_change', 'Security Setting Change'),
        ('api_key_generated', 'API Key Generated'),
        ('api_key_revoked', 'API Key Revoked'),
        ('suspicious_activity', 'Suspicious Activity'),
        ('other', 'Other'),
    )

    SEVERITY_CHOICES = (
        ('info', 'Information'),
        ('warning', 'Warning'),
        ('critical', 'Critical'),
    )

    event_type = models.CharField(max_length=30, choices=EVENT_TYPE_CHOICES)
    user = models.ForeignKey(AppUser, on_delete=models.SET_NULL, null=True, blank=True, related_name='security_logs')
    ip_address = models.GenericIPAddressField(null=True, blank=True)
    user_agent = models.TextField(null=True, blank=True)
    device_info = models.JSONField(null=True, blank=True)
    location_info = models.JSONField(null=True, blank=True)
    description = models.TextField()
    event_data = models.JSONField(null=True, blank=True)
    severity = models.CharField(max_length=10, choices=SEVERITY_CHOICES, default='info')
    timestamp = models.DateTimeField(default=timezone.now)

    def __str__(self):
        return f"{self.get_event_type_display()} - {self.timestamp}"

    class Meta:
        db_table = "security_audit_log"
        verbose_name = "Security Audit Log"
        verbose_name_plural = "Security Audit Logs"
        ordering = ['-timestamp']


class BlockedIP(MetadataModel):
    """
    Records blocked IP addresses
    """
    BLOCK_REASON_CHOICES = (
        ('suspicious_activity', 'Suspicious Activity'),
        ('brute_force', 'Brute Force Attempt'),
        ('spam', 'Spam'),
        ('malware', 'Malware'),
        ('manual', 'Manually Blocked'),
        ('geo_restriction', 'Geographic Restriction'),
        ('other', 'Other'),
    )

    ip_address = models.GenericIPAddressField(unique=True)
    reason = models.CharField(max_length=20, choices=BLOCK_REASON_CHOICES)
    description = models.TextField(blank=True, null=True)
    blocked_at = models.DateTimeField(default=timezone.now)
    blocked_until = models.DateTimeField(null=True, blank=True)
    is_permanent = models.BooleanField(default=False)
    blocked_by = models.ForeignKey(AppUser, on_delete=models.SET_NULL, null=True, blank=True,
                                   related_name='blocked_ips')

    def __str__(self):
        return f"{self.ip_address} - {self.get_reason_display()}"

    def is_active(self):
        if self.is_permanent:
            return True
        if self.blocked_until and timezone.now() < self.blocked_until:
            return True
        return False

    class Meta:
        db_table = "blocked_ip"
        verbose_name = "Blocked IP"
        verbose_name_plural = "Blocked IPs"
        ordering = ['-blocked_at']


class SecurityQuestion(MetadataModel):
    """
    Security questions for account recovery
    """
    question_text = models.CharField(max_length=255)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return self.question_text

    class Meta:
        db_table = "security_question"
        verbose_name = "Security Question"
        verbose_name_plural = "Security Questions"


class UserSecurityQuestion(MetadataModel):
    """
    User's answers to security questions
    """
    user = models.ForeignKey(AppUser, on_delete=models.CASCADE, related_name='security_questions')
    question = models.ForeignKey(SecurityQuestion, on_delete=models.CASCADE)
    answer_hash = models.CharField(max_length=255)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"{self.user}'s answer to {self.question}"

    class Meta:
        db_table = "user_security_question"
        verbose_name = "User Security Question"
        verbose_name_plural = "User Security Questions"
        unique_together = ('user', 'question')


class TwoFactorMethod(MetadataModel):
    """
    Two-factor authentication methods for users
    """
    METHOD_TYPE_CHOICES = (
        ('sms', 'SMS'),
        ('email', 'Email'),
        ('authenticator_app', 'Authenticator App'),
        ('backup_codes', 'Backup Codes'),
        ('push_notification', 'Push Notification'),
    )

    user = models.ForeignKey(AppUser, on_delete=models.CASCADE, related_name='two_factor_methods')
    method_type = models.CharField(max_length=20, choices=METHOD_TYPE_CHOICES)
    identifier = models.CharField(max_length=255, blank=True, null=True, help_text="Phone number, email, etc.")
    secret_key = models.CharField(max_length=255, blank=True, null=True)
    backup_codes = models.JSONField(null=True, blank=True)
    is_primary = models.BooleanField(default=False)
    is_active = models.BooleanField(default=True)
    last_used = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"{self.user}'s {self.get_method_type_display()}"

    class Meta:
        db_table = "two_factor_method"
        verbose_name = "Two-Factor Method"
        verbose_name_plural = "Two-Factor Methods"
        unique_together = ('user', 'method_type')


class APIKey(MetadataModel):
    """
    API keys for external integrations
    """
    name = models.CharField(max_length=100)
    key_prefix = models.CharField(max_length=10, editable=False)
    key_hash = models.CharField(max_length=255, editable=False)
    user = models.ForeignKey(AppUser, on_delete=models.CASCADE, related_name='api_keys')
    permissions = models.JSONField(null=True, blank=True)
    expires_at = models.DateTimeField(null=True, blank=True)
    last_used = models.DateTimeField(null=True, blank=True)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"{self.name} ({self.key_prefix}...)"

    def is_expired(self):
        if self.expires_at and timezone.now() > self.expires_at:
            return True
        return False

    class Meta:
        db_table = "api_key"
        verbose_name = "API Key"
        verbose_name_plural = "API Keys"
        ordering = ['-created_at']
