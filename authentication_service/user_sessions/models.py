"""
BIDR Session Management Models

This module contains models for tracking and managing user sessions
across multiple devices and platforms.
"""
import uuid
from datetime import timedelta
from django.db import models
from django.utils import timezone
from django.contrib.auth import get_user_model
from django.contrib.sessions.models import Session as DjangoSession
from django.core.exceptions import ValidationError

User = get_user_model()


class DeviceType(models.TextChoices):
    """Device type choices"""
    DESKTOP = 'desktop', 'Desktop'
    MOBILE = 'mobile', 'Mobile'
    TABLET = 'tablet', 'Tablet'
    API = 'api', 'API Client'
    UNKNOWN = 'unknown', 'Unknown'


class SessionStatus(models.TextChoices):
    """Session status choices"""
    ACTIVE = 'active', 'Active'
    EXPIRED = 'expired', 'Expired'
    TERMINATED = 'terminated', 'Terminated'
    SUSPENDED = 'suspended', 'Suspended'


class UserSession(models.Model):
    """
    Extended session model for tracking user sessions with additional metadata
    """
    id = models.BigAutoField(primary_key=True)
    uuid = models.UUIDField(default=uuid.uuid4, editable=False, unique=True)
    user = models.ForeignKey(
        User, 
        on_delete=models.CASCADE, 
        related_name='user_sessions',
        help_text="User associated with this session"
    )
    session_key = models.CharField(
        max_length=40, 
        unique=True,
        help_text="Django session key"
    )
    
    # Device & Location Information
    device_id = models.CharField(
        max_length=255, 
        blank=True, 
        null=True,
        help_text="Unique device identifier"
    )
    device_type = models.CharField(
        max_length=20, 
        choices=DeviceType.choices, 
        default=DeviceType.UNKNOWN,
        help_text="Type of device used"
    )
    device_name = models.CharField(
        max_length=255, 
        blank=True, 
        null=True,
        help_text="Human-readable device name"
    )
    browser = models.CharField(
        max_length=100, 
        blank=True, 
        null=True,
        help_text="Browser used for the session"
    )
    browser_version = models.CharField(
        max_length=50, 
        blank=True, 
        null=True,
        help_text="Browser version"
    )
    operating_system = models.CharField(
        max_length=100, 
        blank=True, 
        null=True,
        help_text="Operating system"
    )
    
    # Network Information
    ip_address = models.GenericIPAddressField(
        help_text="IP address of the session"
    )
    user_agent = models.TextField(
        blank=True, 
        null=True,
        help_text="Full user agent string"
    )
    
    # Geographic Information
    country = models.CharField(
        max_length=100, 
        blank=True, 
        null=True,
        help_text="Country from IP geolocation"
    )
    city = models.CharField(
        max_length=100, 
        blank=True, 
        null=True,
        help_text="City from IP geolocation"
    )
    latitude = models.DecimalField(
        max_digits=9, 
        decimal_places=6, 
        blank=True, 
        null=True,
        help_text="Latitude coordinate"
    )
    longitude = models.DecimalField(
        max_digits=9, 
        decimal_places=6, 
        blank=True, 
        null=True,
        help_text="Longitude coordinate"
    )
    
    # Session Tracking
    status = models.CharField(
        max_length=20, 
        choices=SessionStatus.choices, 
        default=SessionStatus.ACTIVE,
        help_text="Current status of the session"
    )
    is_trusted = models.BooleanField(
        default=False,
        help_text="Whether this device/location is trusted"
    )
    
    # Timestamps
    created_at = models.DateTimeField(
        auto_now_add=True,
        help_text="When the session was created"
    )
    last_activity = models.DateTimeField(
        auto_now=True,
        help_text="Last activity timestamp"
    )
    expires_at = models.DateTimeField(
        help_text="When the session expires"
    )
    terminated_at = models.DateTimeField(
        blank=True, 
        null=True,
        help_text="When the session was terminated"
    )
    
    # Security
    security_score = models.IntegerField(
        default=50,
        help_text="Security score for this session (0-100)"
    )
    risk_factors = models.JSONField(
        default=list,
        help_text="List of identified risk factors"
    )
    
    class Meta:
        db_table = 'user_sessions'
        verbose_name = 'User Session'
        verbose_name_plural = 'User Sessions'
        ordering = ['-last_activity']
        indexes = [
            models.Index(fields=['user', 'status']),
            models.Index(fields=['session_key']),
            models.Index(fields=['ip_address']),
            models.Index(fields=['device_id']),
            models.Index(fields=['last_activity']),
        ]

    def __str__(self):
        return f"{self.user.email} - {self.device_type} ({self.ip_address})"

    def is_active(self):
        """Check if session is currently active"""
        return self.status == SessionStatus.ACTIVE and timezone.now() < self.expires_at

    def is_expired(self):
        """Check if session has expired"""
        return timezone.now() >= self.expires_at

    def terminate(self, reason=None):
        """Terminate the session"""
        self.status = SessionStatus.TERMINATED
        self.terminated_at = timezone.now()
        if reason:
            self.risk_factors.append(f"Terminated: {reason}")
        self.save(update_fields=['status', 'terminated_at', 'risk_factors'])

    def update_activity(self):
        """Update last activity timestamp"""
        self.last_activity = timezone.now()
        self.save(update_fields=['last_activity'])

    def calculate_session_duration(self):
        """Calculate total session duration"""
        end_time = self.terminated_at or timezone.now()
        return end_time - self.created_at

    def get_location_display(self):
        """Get human-readable location"""
        if self.city and self.country:
            return f"{self.city}, {self.country}"
        elif self.country:
            return self.country
        return "Unknown Location"


class SessionActivity(models.Model):
    """
    Track specific activities within a session
    """
    id = models.BigAutoField(primary_key=True)
    session = models.ForeignKey(
        UserSession, 
        on_delete=models.CASCADE, 
        related_name='activities',
        help_text="Session this activity belongs to"
    )
    
    # Activity Details
    action = models.CharField(
        max_length=100,
        help_text="Type of action performed"
    )
    endpoint = models.CharField(
        max_length=500, 
        blank=True, 
        null=True,
        help_text="API endpoint or page accessed"
    )
    method = models.CharField(
        max_length=10, 
        blank=True, 
        null=True,
        help_text="HTTP method used"
    )
    status_code = models.IntegerField(
        blank=True, 
        null=True,
        help_text="HTTP status code"
    )
    
    # Additional Context
    request_data = models.JSONField(
        default=dict,
        help_text="Request data (sanitized)"
    )
    response_time = models.FloatField(
        blank=True, 
        null=True,
        help_text="Response time in milliseconds"
    )
    
    # Timestamps
    timestamp = models.DateTimeField(
        auto_now_add=True,
        help_text="When the activity occurred"
    )
    
    class Meta:
        db_table = 'session_activities'
        verbose_name = 'Session Activity'
        verbose_name_plural = 'Session Activities'
        ordering = ['-timestamp']
        indexes = [
            models.Index(fields=['session', 'timestamp']),
            models.Index(fields=['action']),
            models.Index(fields=['endpoint']),
        ]

    def __str__(self):
        return f"{self.session.user.email} - {self.action} at {self.timestamp}"


class TrustedDevice(models.Model):
    """
    Track trusted devices for users
    """
    id = models.BigAutoField(primary_key=True)
    uuid = models.UUIDField(default=uuid.uuid4, editable=False, unique=True)
    user = models.ForeignKey(
        User, 
        on_delete=models.CASCADE, 
        related_name='trusted_devices',
        help_text="User who owns this trusted device"
    )
    
    # Device Information
    device_id = models.CharField(
        max_length=255,
        help_text="Unique device identifier"
    )
    device_name = models.CharField(
        max_length=255,
        help_text="Human-readable device name"
    )
    device_type = models.CharField(
        max_length=20, 
        choices=DeviceType.choices,
        help_text="Type of device"
    )
    device_fingerprint = models.TextField(
        help_text="Device fingerprint hash"
    )
    
    # Trust Information
    trusted_at = models.DateTimeField(
        auto_now_add=True,
        help_text="When the device was marked as trusted"
    )
    last_used = models.DateTimeField(
        auto_now=True,
        help_text="Last time this device was used"
    )
    expires_at = models.DateTimeField(
        blank=True, 
        null=True,
        help_text="When the trust expires"
    )
    is_active = models.BooleanField(
        default=True,
        help_text="Whether the trust is currently active"
    )
    
    class Meta:
        db_table = 'trusted_devices'
        verbose_name = 'Trusted Device'
        verbose_name_plural = 'Trusted Devices'
        unique_together = ['user', 'device_id']
        ordering = ['-last_used']
        indexes = [
            models.Index(fields=['user', 'is_active']),
            models.Index(fields=['device_id']),
        ]

    def __str__(self):
        return f"{self.user.email} - {self.device_name}"

    def is_expired(self):
        """Check if device trust has expired"""
        if self.expires_at:
            return timezone.now() >= self.expires_at
        return False

    def revoke_trust(self):
        """Revoke trust for this device"""
        self.is_active = False
        self.save(update_fields=['is_active'])


class SessionSecurityEvent(models.Model):
    """
    Track security events related to sessions
    """
    SECURITY_EVENT_TYPES = [
        ('suspicious_location', 'Suspicious Location'),
        ('multiple_sessions', 'Multiple Active Sessions'),
        ('unusual_activity', 'Unusual Activity Pattern'),
        ('brute_force', 'Brute Force Attempt'),
        ('session_hijack', 'Potential Session Hijacking'),
        ('untrusted_device', 'Untrusted Device Access'),
    ]
    
    SEVERITY_LEVELS = [
        ('low', 'Low'),
        ('medium', 'Medium'),
        ('high', 'High'),
        ('critical', 'Critical'),
    ]
    
    id = models.BigAutoField(primary_key=True)
    uuid = models.UUIDField(default=uuid.uuid4, editable=False, unique=True)
    session = models.ForeignKey(
        UserSession, 
        on_delete=models.CASCADE, 
        related_name='security_events',
        help_text="Session where the security event occurred"
    )
    
    # Event Details
    event_type = models.CharField(
        max_length=50, 
        choices=SECURITY_EVENT_TYPES,
        help_text="Type of security event"
    )
    severity = models.CharField(
        max_length=20, 
        choices=SEVERITY_LEVELS, 
        default='medium',
        help_text="Severity level of the event"
    )
    description = models.TextField(
        help_text="Detailed description of the security event"
    )
    
    # Event Data
    event_data = models.JSONField(
        default=dict,
        help_text="Additional data related to the security event"
    )
    risk_score = models.IntegerField(
        default=0,
        help_text="Risk score assigned to this event (0-100)"
    )
    
    # Resolution
    is_resolved = models.BooleanField(
        default=False,
        help_text="Whether the security event has been resolved"
    )
    resolved_at = models.DateTimeField(
        blank=True, 
        null=True,
        help_text="When the event was resolved"
    )
    resolution_notes = models.TextField(
        blank=True, 
        null=True,
        help_text="Notes about how the event was resolved"
    )
    
    # Timestamps
    detected_at = models.DateTimeField(
        auto_now_add=True,
        help_text="When the security event was detected"
    )
    
    class Meta:
        db_table = 'session_security_events'
        verbose_name = 'Session Security Event'
        verbose_name_plural = 'Session Security Events'
        ordering = ['-detected_at']
        indexes = [
            models.Index(fields=['session', 'event_type']),
            models.Index(fields=['severity', 'is_resolved']),
            models.Index(fields=['detected_at']),
        ]

    def __str__(self):
        return f"{self.event_type} - {self.session.user.email} ({self.severity})"

    def resolve(self, notes=None):
        """Mark the security event as resolved"""
        self.is_resolved = True
        self.resolved_at = timezone.now()
        if notes:
            self.resolution_notes = notes
        self.save(update_fields=['is_resolved', 'resolved_at', 'resolution_notes'])
