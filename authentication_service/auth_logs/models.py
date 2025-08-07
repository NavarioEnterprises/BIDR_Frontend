"""
BIDR Authentication Logging Models

This module contains models for logging all authentication-related activities
in the BIDR platform including logins, registrations, password resets, etc.
"""
from django.db import models
from django.contrib.contenttypes.models import ContentType
from django.contrib.contenttypes.fields import GenericForeignKey
from django.core.validators import RegexValidator
from django.utils import timezone
from datetime import timedelta
import json


class AuthenticationLog(models.Model):
    """
    Comprehensive authentication logging for BIDR platform.
    Tracks all authentication-related activities.
    """
    
    # Authentication Actions
    ACTION_CHOICES = [
        # Login Actions
        ('login_attempt', 'Login Attempt'),
        ('login_success', 'Login Successful'),
        ('login_failed', 'Login Failed'),
        ('login_blocked', 'Login Blocked'),
        ('logout', 'Logout'),
        ('force_logout', 'Force Logout'),
        
        # Registration Actions
        ('registration_attempt', 'Registration Attempt'),
        ('registration_success', 'Registration Successful'),
        ('registration_failed', 'Registration Failed'),
        ('email_verification_sent', 'Email Verification Sent'),
        ('email_verification_success', 'Email Verification Successful'),
        ('email_verification_failed', 'Email Verification Failed'),
        
        # Password Actions
        ('password_reset_request', 'Password Reset Requested'),
        ('password_reset_email_sent', 'Password Reset Email Sent'),
        ('password_reset_success', 'Password Reset Successful'),
        ('password_reset_failed', 'Password Reset Failed'),
        ('password_change_success', 'Password Change Successful'),
        ('password_change_failed', 'Password Change Failed'),
        
        # OTP Actions
        ('otp_request', 'OTP Requested'),
        ('otp_sent', 'OTP Sent'),
        ('otp_verify_success', 'OTP Verification Successful'),
        ('otp_verify_failed', 'OTP Verification Failed'),
        ('otp_expired', 'OTP Expired'),
        ('otp_resend', 'OTP Resend'),
        
        # Account Actions
        ('account_locked', 'Account Locked'),
        ('account_unlocked', 'Account Unlocked'),
        ('account_suspended', 'Account Suspended'),
        ('account_activated', 'Account Activated'),
        ('account_deactivated', 'Account Deactivated'),
        
        # Profile Actions
        ('profile_update', 'Profile Updated'),
        ('role_assignment', 'Role Assigned'),
        ('role_removal', 'Role Removed'),
        ('permission_grant', 'Permission Granted'),
        ('permission_revoke', 'Permission Revoked'),
        
        # Security Actions
        ('suspicious_activity', 'Suspicious Activity Detected'),
        ('security_alert', 'Security Alert'),
        ('device_registration', 'Device Registered'),
        ('device_removal', 'Device Removed'),
        ('session_expired', 'Session Expired'),
        ('token_refresh', 'Token Refreshed'),
        ('token_blacklist', 'Token Blacklisted'),
        
        # Business Actions
        ('seller_verification', 'Seller Verification'),
        ('buyer_verification', 'Buyer Verification'),
        ('document_upload', 'Document Uploaded'),
        ('document_verification', 'Document Verified'),
        ('document_rejection', 'Document Rejected'),
        
        # API Actions
        ('api_key_generated', 'API Key Generated'),
        ('api_key_revoked', 'API Key Revoked'),
        ('unauthorized_api_access', 'Unauthorized API Access'),
    ]
    
    # User Types
    USER_TYPE_CHOICES = [
        ('individual_seller', 'Individual Seller'),
        ('business_seller', 'Business Seller'),
        ('corporate_seller', 'Corporate Seller'),
        ('individual_buyer', 'Individual Buyer'),
        ('business_buyer', 'Business Buyer'),
        ('corporate_buyer', 'Corporate Buyer'),
        ('admin', 'Administrator'),
        ('moderator', 'Moderator'),
        ('support', 'Support Agent'),
        ('unknown', 'Unknown'),
    ]
    
    # Status
    STATUS_CHOICES = [
        ('success', 'Success'),
        ('failed', 'Failed'),
        ('pending', 'Pending'),
        ('blocked', 'Blocked'),
        ('expired', 'Expired'),
        ('cancelled', 'Cancelled'),
    ]
    
    # Core Fields
    log_id = models.BigAutoField(primary_key=True)
    user_email = models.EmailField(db_index=True, help_text="Email of the user performing the action")
    user_id = models.IntegerField(null=True, blank=True, db_index=True, help_text="Internal user ID if available")
    user_type = models.CharField(max_length=50, choices=USER_TYPE_CHOICES, default='unknown')
    action = models.CharField(max_length=50, choices=ACTION_CHOICES, db_index=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='success')
    
    # Request Details
    ip_address = models.GenericIPAddressField(help_text="IP address of the request")
    user_agent = models.TextField(help_text="User agent string from the request")
    device_id = models.CharField(max_length=255, null=True, blank=True, help_text="Unique device identifier")
    device_type = models.CharField(max_length=50, null=True, blank=True, help_text="Device type (mobile, desktop, tablet)")
    device_os = models.CharField(max_length=50, null=True, blank=True, help_text="Operating system")
    browser = models.CharField(max_length=100, null=True, blank=True, help_text="Browser information")
    
    # Location Data
    country = models.CharField(max_length=100, null=True, blank=True)
    region = models.CharField(max_length=100, null=True, blank=True)
    city = models.CharField(max_length=100, null=True, blank=True)
    latitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    longitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    
    # Additional Data
    endpoint = models.CharField(max_length=200, help_text="API endpoint that was called")
    method = models.CharField(max_length=10, help_text="HTTP method (GET, POST, etc.)")
    response_code = models.IntegerField(help_text="HTTP response status code")
    response_time_ms = models.IntegerField(null=True, blank=True, help_text="Response time in milliseconds")
    
    # Contextual Information
    details = models.JSONField(default=dict, blank=True, help_text="Additional context data")
    error_message = models.TextField(null=True, blank=True, help_text="Error message if action failed")
    session_id = models.CharField(max_length=255, null=True, blank=True, help_text="Session identifier")
    request_id = models.CharField(max_length=255, null=True, blank=True, help_text="Unique request identifier")
    
    # Referrer and Source
    referrer = models.URLField(null=True, blank=True, help_text="HTTP referrer")
    source_application = models.CharField(max_length=100, default='BIDR_WEB', help_text="Source application")
    
    # Timestamps
    timestamp = models.DateTimeField(auto_now_add=True, db_index=True)
    processed_at = models.DateTimeField(null=True, blank=True, help_text="When the log was processed")
    
    class Meta:
        db_table = "bidr_authentication_logs"
        ordering = ['-timestamp']
        indexes = [
            models.Index(fields=['user_email', 'timestamp']),
            models.Index(fields=['action', 'timestamp']),
            models.Index(fields=['status', 'timestamp']),
            models.Index(fields=['ip_address', 'timestamp']),
            models.Index(fields=['user_type', 'action']),
            models.Index(fields=['response_code', 'timestamp']),
            models.Index(fields=['device_id', 'timestamp']),
        ]
        
    def __str__(self):
        return f"{self.user_email} - {self.get_action_display()} at {self.timestamp}"
    
    def save(self, *args, **kwargs):
        """Override save to set processed_at timestamp."""
        if not self.processed_at:
            self.processed_at = timezone.now()
        super().save(*args, **kwargs)
    
    @property
    def is_suspicious(self):
        """Check if this log entry indicates suspicious activity."""
        suspicious_actions = [
            'login_blocked', 'suspicious_activity', 'security_alert',
            'unauthorized_api_access', 'account_locked'
        ]
        return self.action in suspicious_actions
    
    @property
    def is_failed_attempt(self):
        """Check if this is a failed authentication attempt."""
        failed_actions = [
            'login_failed', 'registration_failed', 'password_reset_failed',
            'otp_verify_failed', 'password_change_failed'
        ]
        return self.action in failed_actions


class SecurityEvent(models.Model):
    """
    Security events and alerts for BIDR platform.
    """
    
    SEVERITY_CHOICES = [
        ('low', 'Low'),
        ('medium', 'Medium'),
        ('high', 'High'),
        ('critical', 'Critical'),
    ]
    
    EVENT_TYPE_CHOICES = [
        ('multiple_failed_logins', 'Multiple Failed Login Attempts'),
        ('suspicious_location', 'Suspicious Location Access'),
        ('multiple_devices', 'Multiple Device Access'),
        ('brute_force_attack', 'Brute Force Attack'),
        ('impossible_travel', 'Impossible Travel'),
        ('account_takeover', 'Potential Account Takeover'),
        ('api_abuse', 'API Abuse'),
        ('bot_activity', 'Bot Activity Detected'),
        ('data_breach_attempt', 'Data Breach Attempt'),
        ('privilege_escalation', 'Privilege Escalation Attempt'),
    ]
    
    STATUS_CHOICES = [
        ('active', 'Active'),
        ('investigating', 'Under Investigation'),
        ('resolved', 'Resolved'),
        ('false_positive', 'False Positive'),
        ('ignored', 'Ignored'),
    ]
    
    event_id = models.BigAutoField(primary_key=True)
    user_email = models.EmailField(db_index=True)
    event_type = models.CharField(max_length=50, choices=EVENT_TYPE_CHOICES)
    severity = models.CharField(max_length=20, choices=SEVERITY_CHOICES, default='medium')
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='active')
    
    title = models.CharField(max_length=255)
    description = models.TextField()
    recommendation = models.TextField(null=True, blank=True)
    
    # Event Data
    event_data = models.JSONField(default=dict, help_text="Additional event-specific data")
    risk_score = models.IntegerField(default=0, help_text="Risk score from 0-100")
    
    # Associated Logs
    related_logs = models.ManyToManyField(AuthenticationLog, related_name='security_events')
    
    # Timestamps
    detected_at = models.DateTimeField(auto_now_add=True, db_index=True)
    resolved_at = models.DateTimeField(null=True, blank=True)
    last_updated = models.DateTimeField(auto_now=True)
    
    # Investigation
    investigated_by = models.EmailField(null=True, blank=True)
    investigation_notes = models.TextField(null=True, blank=True)
    
    class Meta:
        db_table = "bidr_security_events"
        ordering = ['-detected_at']
        indexes = [
            models.Index(fields=['user_email', 'detected_at']),
            models.Index(fields=['event_type', 'severity']),
            models.Index(fields=['status', 'detected_at']),
            models.Index(fields=['risk_score']),
        ]
    
    def __str__(self):
        return f"{self.title} ({self.get_severity_display()}) - {self.user_email}"
    
    def mark_resolved(self, resolved_by=None, notes=None):
        """Mark security event as resolved."""
        self.status = 'resolved'
        self.resolved_at = timezone.now()
        if resolved_by:
            self.investigated_by = resolved_by
        if notes:
            self.investigation_notes = notes
        self.save()


class LoginSession(models.Model):
    """
    Track active login sessions for users.
    """
    
    session_id = models.CharField(max_length=255, primary_key=True)
    user_email = models.EmailField(db_index=True)
    user_id = models.IntegerField(null=True, blank=True)
    
    # Session Details
    ip_address = models.GenericIPAddressField()
    device_id = models.CharField(max_length=255, null=True, blank=True)
    device_info = models.JSONField(default=dict)
    location_info = models.JSONField(default=dict)
    
    # Session State
    is_active = models.BooleanField(default=True)
    login_timestamp = models.DateTimeField(auto_now_add=True)
    last_activity = models.DateTimeField(auto_now=True)
    logout_timestamp = models.DateTimeField(null=True, blank=True)
    
    # Session Metadata
    jwt_token_id = models.CharField(max_length=255, null=True, blank=True)
    refresh_token_id = models.CharField(max_length=255, null=True, blank=True)
    
    class Meta:
        db_table = "bidr_login_sessions"
        ordering = ['-login_timestamp']
        indexes = [
            models.Index(fields=['user_email', 'is_active']),
            models.Index(fields=['device_id', 'is_active']),
            models.Index(fields=['last_activity']),
        ]
    
    def __str__(self):
        return f"{self.user_email} session from {self.ip_address}"
    
    def terminate_session(self):
        """Terminate the session."""
        self.is_active = False
        self.logout_timestamp = timezone.now()
        self.save()
    
    @property
    def duration(self):
        """Get session duration."""
        end_time = self.logout_timestamp or timezone.now()
        return end_time - self.login_timestamp
    
    @property
    def is_expired(self):
        """Check if session has expired (24 hours of inactivity)."""
        return timezone.now() - self.last_activity > timedelta(hours=24)


class AuditTrail(models.Model):
    """
    Administrative audit trail for BIDR platform.
    """
    
    ACTION_CHOICES = [
        ('user_created', 'User Created'),
        ('user_updated', 'User Updated'),
        ('user_deleted', 'User Deleted'),
        ('role_assigned', 'Role Assigned'),
        ('role_removed', 'Role Removed'),
        ('permission_granted', 'Permission Granted'),
        ('permission_revoked', 'Permission Revoked'),
        ('account_locked', 'Account Locked'),
        ('account_unlocked', 'Account Unlocked'),
        ('password_reset', 'Password Reset by Admin'),
        ('security_event_resolved', 'Security Event Resolved'),
        ('system_setting_changed', 'System Setting Changed'),
        ('bulk_operation', 'Bulk Operation Performed'),
    ]
    
    audit_id = models.BigAutoField(primary_key=True)
    
    # Who performed the action
    admin_email = models.EmailField(help_text="Email of admin who performed the action")
    admin_id = models.IntegerField(null=True, blank=True)
    
    # What action was performed
    action = models.CharField(max_length=50, choices=ACTION_CHOICES)
    description = models.TextField()
    
    # Target of the action
    target_user_email = models.EmailField(null=True, blank=True)
    target_user_id = models.IntegerField(null=True, blank=True)
    
    # Additional context
    before_data = models.JSONField(null=True, blank=True, help_text="Data before the change")
    after_data = models.JSONField(null=True, blank=True, help_text="Data after the change")
    additional_info = models.JSONField(default=dict)
    
    # Request context
    ip_address = models.GenericIPAddressField()
    user_agent = models.TextField()
    
    # Timestamps
    timestamp = models.DateTimeField(auto_now_add=True, db_index=True)
    
    class Meta:
        db_table = "bidr_audit_trail"
        ordering = ['-timestamp']
        indexes = [
            models.Index(fields=['admin_email', 'timestamp']),
            models.Index(fields=['target_user_email', 'timestamp']),
            models.Index(fields=['action', 'timestamp']),
        ]
    
    def __str__(self):
        return f"{self.admin_email} performed {self.get_action_display()} at {self.timestamp}"
