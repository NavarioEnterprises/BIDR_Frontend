"""
BIDR API Management Models

This module contains models for managing API keys, rate limiting,
and API access control for the BIDR platform.
"""
import uuid
import secrets
import hashlib
from datetime import timedelta
from django.db import models
from django.utils import timezone
from django.contrib.auth import get_user_model
from django.core.exceptions import ValidationError

User = get_user_model()


class APIKeyStatus(models.TextChoices):
    """API Key status choices"""
    ACTIVE = 'active', 'Active'
    INACTIVE = 'inactive', 'Inactive'
    SUSPENDED = 'suspended', 'Suspended'
    REVOKED = 'revoked', 'Revoked'


class RateLimitPeriod(models.TextChoices):
    """Rate limiting period choices"""
    MINUTE = 'minute', 'Per Minute'
    HOUR = 'hour', 'Per Hour'
    DAY = 'day', 'Per Day'
    MONTH = 'month', 'Per Month'


class APIScope(models.Model):
    """
    Define API scopes/permissions for API keys
    """
    id = models.BigAutoField(primary_key=True)
    uuid = models.UUIDField(default=uuid.uuid4, editable=False, unique=True)
    
    # Scope Details
    name = models.CharField(
        max_length=100, 
        unique=True,
        help_text="Unique name for the API scope"
    )
    description = models.TextField(
        help_text="Description of what this scope allows"
    )
    resource = models.CharField(
        max_length=100,
        help_text="Resource this scope applies to (e.g., 'bids', 'users')"
    )
    permissions = models.JSONField(
        default=list,
        help_text="List of permissions (e.g., ['read', 'write', 'delete'])"
    )
    
    # Metadata
    is_default = models.BooleanField(
        default=False,
        help_text="Whether this scope is included by default"
    )
    is_sensitive = models.BooleanField(
        default=False,
        help_text="Whether this scope requires special approval"
    )
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'api_scopes'
        verbose_name = 'API Scope'
        verbose_name_plural = 'API Scopes'
        ordering = ['resource', 'name']
        indexes = [
            models.Index(fields=['name']),
            models.Index(fields=['resource']),
        ]

    def __str__(self):
        return f"{self.resource}:{self.name}"


class APIKey(models.Model):
    """
    API Key model for managing third-party access to BIDR APIs
    """
    id = models.BigAutoField(primary_key=True)
    uuid = models.UUIDField(default=uuid.uuid4, editable=False, unique=True)
    
    # Ownership
    user = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='api_keys',
        help_text="User who owns this API key"
    )
    
    # Key Details
    name = models.CharField(
        max_length=255,
        help_text="Human-readable name for the API key"
    )
    description = models.TextField(
        blank=True,
        null=True,
        help_text="Description of the API key's purpose"
    )
    key_id = models.CharField(
        max_length=32,
        unique=True,
        help_text="Public key identifier"
    )
    key_hash = models.CharField(
        max_length=128,
        help_text="Hashed version of the secret key"
    )
    key_prefix = models.CharField(
        max_length=8,
        help_text="Visible prefix of the key for identification"
    )
    
    # Status and Lifecycle
    status = models.CharField(
        max_length=20,
        choices=APIKeyStatus.choices,
        default=APIKeyStatus.ACTIVE,
        help_text="Current status of the API key"
    )
    
    # Permissions
    scopes = models.ManyToManyField(
        APIScope,
        blank=True,
        help_text="API scopes this key has access to"
    )
    allowed_ips = models.JSONField(
        default=list,
        help_text="List of allowed IP addresses (empty = all allowed)"
    )
    allowed_origins = models.JSONField(
        default=list,
        help_text="List of allowed origins for CORS"
    )
    
    # Usage Limits
    rate_limit_requests = models.IntegerField(
        default=1000,
        help_text="Number of requests allowed per period"
    )
    rate_limit_period = models.CharField(
        max_length=10,
        choices=RateLimitPeriod.choices,
        default=RateLimitPeriod.HOUR,
        help_text="Rate limiting period"
    )
    daily_request_limit = models.IntegerField(
        blank=True,
        null=True,
        help_text="Maximum requests per day (null = unlimited)"
    )
    monthly_request_limit = models.IntegerField(
        blank=True,
        null=True,
        help_text="Maximum requests per month (null = unlimited)"
    )
    
    # Usage Tracking
    total_requests = models.BigIntegerField(
        default=0,
        help_text="Total number of requests made with this key"
    )
    last_used_at = models.DateTimeField(
        blank=True,
        null=True,
        help_text="Last time this API key was used"
    )
    last_used_ip = models.GenericIPAddressField(
        blank=True,
        null=True,
        help_text="IP address of last usage"
    )
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    expires_at = models.DateTimeField(
        blank=True,
        null=True,
        help_text="When the API key expires (null = never)"
    )
    revoked_at = models.DateTimeField(
        blank=True,
        null=True,
        help_text="When the API key was revoked"
    )
    last_rotated_at = models.DateTimeField(
        blank=True,
        null=True,
        help_text="When the API key was last rotated"
    )
    
    class Meta:
        db_table = 'api_keys'
        verbose_name = 'API Key'
        verbose_name_plural = 'API Keys'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['key_id']),
            models.Index(fields=['user', 'status']),
            models.Index(fields=['status']),
            models.Index(fields=['last_used_at']),
        ]

    def __str__(self):
        return f"{self.name} ({self.key_prefix}***)"

    def save(self, *args, **kwargs):
        if not self.key_id:
            self.key_id = self.generate_key_id()
        if not self.key_prefix and hasattr(self, '_raw_key'):
            self.key_prefix = self._raw_key[:8]
        super().save(*args, **kwargs)

    @classmethod
    def generate_key_id(cls):
        """Generate a unique key ID"""
        return secrets.token_urlsafe(24)

    @classmethod
    def generate_secret_key(cls):
        """Generate a secure secret key"""
        return f"bidr_{''.join(secrets.choice('abcdefghijklmnopqrstuvwxyz0123456789') for _ in range(32))}"

    @classmethod
    def create_api_key(cls, user, name, description=None, scopes=None):
        """Create a new API key with proper security"""
        raw_key = cls.generate_secret_key()
        key_hash = hashlib.sha256(raw_key.encode()).hexdigest()
        
        api_key = cls.objects.create(
            user=user,
            name=name,
            description=description,
            key_hash=key_hash,
            key_prefix=raw_key[:8]
        )
        api_key._raw_key = raw_key  # Store temporarily for response
        
        if scopes:
            api_key.scopes.set(scopes)
        
        return api_key, raw_key

    def verify_key(self, provided_key):
        """Verify if the provided key matches this API key"""
        return hashlib.sha256(provided_key.encode()).hexdigest() == self.key_hash

    def is_active(self):
        """Check if the API key is currently active"""
        if self.status != APIKeyStatus.ACTIVE:
            return False
        if self.expires_at and timezone.now() >= self.expires_at:
            return False
        return True

    def is_expired(self):
        """Check if the API key has expired"""
        if self.expires_at:
            return timezone.now() >= self.expires_at
        return False

    def can_access_ip(self, ip_address):
        """Check if the IP address is allowed"""
        if not self.allowed_ips:
            return True
        return ip_address in self.allowed_ips

    def can_access_origin(self, origin):
        """Check if the origin is allowed"""
        if not self.allowed_origins:
            return True
        return origin in self.allowed_origins

    def revoke(self, reason=None):
        """Revoke the API key"""
        self.status = APIKeyStatus.REVOKED
        self.revoked_at = timezone.now()
        self.save(update_fields=['status', 'revoked_at'])

    def rotate(self):
        """Rotate the API key (generate new secret)"""
        raw_key = self.generate_secret_key()
        self.key_hash = hashlib.sha256(raw_key.encode()).hexdigest()
        self.key_prefix = raw_key[:8]
        self.last_rotated_at = timezone.now()
        self.save(update_fields=['key_hash', 'key_prefix', 'last_rotated_at'])
        return raw_key

    def update_usage(self, ip_address=None):
        """Update usage statistics"""
        self.total_requests += 1
        self.last_used_at = timezone.now()
        if ip_address:
            self.last_used_ip = ip_address
        self.save(update_fields=['total_requests', 'last_used_at', 'last_used_ip'])


class APIRequest(models.Model):
    """
    Track individual API requests for analytics and monitoring
    """
    id = models.BigAutoField(primary_key=True)
    uuid = models.UUIDField(default=uuid.uuid4, editable=False, unique=True)
    
    # Request Details
    api_key = models.ForeignKey(
        APIKey,
        on_delete=models.CASCADE,
        related_name='requests',
        help_text="API key used for this request"
    )
    
    # HTTP Details
    method = models.CharField(
        max_length=10,
        help_text="HTTP method (GET, POST, etc.)"
    )
    endpoint = models.CharField(
        max_length=500,
        help_text="API endpoint accessed"
    )
    status_code = models.IntegerField(
        help_text="HTTP status code returned"
    )
    
    # Request Context
    ip_address = models.GenericIPAddressField(
        help_text="IP address of the request"
    )
    user_agent = models.TextField(
        blank=True,
        null=True,
        help_text="User agent string"
    )
    origin = models.CharField(
        max_length=255,
        blank=True,
        null=True,
        help_text="Request origin"
    )
    
    # Performance
    response_time = models.FloatField(
        help_text="Response time in milliseconds"
    )
    request_size = models.IntegerField(
        default=0,
        help_text="Request size in bytes"
    )
    response_size = models.IntegerField(
        default=0,
        help_text="Response size in bytes"
    )
    
    # Additional Data
    query_params = models.JSONField(
        default=dict,
        help_text="Query parameters (sanitized)"
    )
    request_headers = models.JSONField(
        default=dict,
        help_text="Request headers (sanitized)"
    )
    error_details = models.JSONField(
        default=dict,
        help_text="Error details if request failed"
    )
    
    # Timestamps
    timestamp = models.DateTimeField(
        auto_now_add=True,
        help_text="When the request was made"
    )
    
    class Meta:
        db_table = 'api_requests'
        verbose_name = 'API Request'
        verbose_name_plural = 'API Requests'
        ordering = ['-timestamp']
        indexes = [
            models.Index(fields=['api_key', 'timestamp']),
            models.Index(fields=['endpoint', 'timestamp']),
            models.Index(fields=['status_code']),
            models.Index(fields=['ip_address']),
            models.Index(fields=['timestamp']),
        ]

    def __str__(self):
        return f"{self.method} {self.endpoint} - {self.status_code}"

    @property
    def is_success(self):
        """Check if the request was successful"""
        return 200 <= self.status_code < 300

    @property
    def is_error(self):
        """Check if the request resulted in an error"""
        return self.status_code >= 400


class RateLimitBucket(models.Model):
    """
    Track rate limiting buckets for API keys
    """
    id = models.BigAutoField(primary_key=True)
    api_key = models.ForeignKey(
        APIKey,
        on_delete=models.CASCADE,
        related_name='rate_limit_buckets',
        help_text="API key this bucket belongs to"
    )
    
    # Bucket Details
    period = models.CharField(
        max_length=10,
        choices=RateLimitPeriod.choices,
        help_text="Rate limiting period"
    )
    bucket_key = models.CharField(
        max_length=100,
        help_text="Unique key for this time bucket"
    )
    
    # Usage Tracking
    request_count = models.IntegerField(
        default=0,
        help_text="Number of requests in this bucket"
    )
    first_request_at = models.DateTimeField(
        help_text="Timestamp of first request in bucket"
    )
    last_request_at = models.DateTimeField(
        help_text="Timestamp of last request in bucket"
    )
    
    # Bucket Lifecycle
    expires_at = models.DateTimeField(
        help_text="When this bucket expires"
    )
    
    class Meta:
        db_table = 'rate_limit_buckets'
        verbose_name = 'Rate Limit Bucket'
        verbose_name_plural = 'Rate Limit Buckets'
        unique_together = ['api_key', 'period', 'bucket_key']
        ordering = ['-last_request_at']
        indexes = [
            models.Index(fields=['api_key', 'period']),
            models.Index(fields=['expires_at']),
        ]

    def __str__(self):
        return f"{self.api_key.name} - {self.period} - {self.request_count}"

    def is_expired(self):
        """Check if the bucket has expired"""
        return timezone.now() >= self.expires_at

    def add_request(self):
        """Add a request to this bucket"""
        self.request_count += 1
        self.last_request_at = timezone.now()
        if not self.first_request_at:
            self.first_request_at = self.last_request_at
        self.save(update_fields=['request_count', 'last_request_at', 'first_request_at'])

    def is_rate_limited(self, limit):
        """Check if this bucket has exceeded the rate limit"""
        return self.request_count >= limit


class APIKeyUsageQuota(models.Model):
    """
    Track usage quotas for API keys (daily, monthly limits)
    """
    id = models.BigAutoField(primary_key=True)
    api_key = models.ForeignKey(
        APIKey,
        on_delete=models.CASCADE,
        related_name='usage_quotas',
        help_text="API key this quota belongs to"
    )
    
    # Quota Period
    quota_type = models.CharField(
        max_length=10,
        choices=[('daily', 'Daily'), ('monthly', 'Monthly')],
        help_text="Type of quota period"
    )
    period_start = models.DateTimeField(
        help_text="Start of the quota period"
    )
    period_end = models.DateTimeField(
        help_text="End of the quota period"
    )
    
    # Usage Tracking
    request_count = models.IntegerField(
        default=0,
        help_text="Number of requests in this quota period"
    )
    quota_limit = models.IntegerField(
        help_text="Maximum requests allowed in this period"
    )
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    last_updated = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'api_key_usage_quotas'
        verbose_name = 'API Key Usage Quota'
        verbose_name_plural = 'API Key Usage Quotas'
        unique_together = ['api_key', 'quota_type', 'period_start']
        ordering = ['-period_start']
        indexes = [
            models.Index(fields=['api_key', 'quota_type']),
            models.Index(fields=['period_end']),
        ]

    def __str__(self):
        return f"{self.api_key.name} - {self.quota_type} - {self.request_count}/{self.quota_limit}"

    def is_expired(self):
        """Check if the quota period has expired"""
        return timezone.now() >= self.period_end

    def is_quota_exceeded(self):
        """Check if the quota has been exceeded"""
        return self.request_count >= self.quota_limit

    def add_request(self):
        """Add a request to this quota"""
        self.request_count += 1
        self.save(update_fields=['request_count'])

    def get_usage_percentage(self):
        """Get usage as a percentage"""
        if self.quota_limit == 0:
            return 0
        return (self.request_count / self.quota_limit) * 100
