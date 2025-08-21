"""
Core models for BIDR Payment Service.

Contains base models and payment gateway credentials management.
"""

import uuid
from django.db import models
from django.contrib.auth.models import User
from django.core.validators import RegexValidator
from django.utils import timezone


class BaseModel(models.Model):
    """Base model with common fields for all payment service models."""
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    is_active = models.BooleanField(default=True)
    
    class Meta:
        abstract = True
        
    def __str__(self):
        return f"{self.__class__.__name__}: {self.id}"


class PaymentGateway(BaseModel):
    """Model to store payment gateway configurations and credentials."""
    
    name = models.CharField(max_length=100, help_text="Gateway name")
    slug = models.SlugField(max_length=50, unique=True, help_text="Gateway slug for API reference")
    config = models.JSONField(default=dict, help_text="Gateway configuration including API keys")
    is_enabled = models.BooleanField(default=False)
    is_default = models.BooleanField(default=False)
    
    # Credentials (encrypted in production)
    public_key = models.TextField(blank=True, null=True, help_text="Public/Publishable Key")
    secret_key = models.TextField(blank=True, null=True, help_text="Secret/Private Key")
    webhook_secret = models.TextField(blank=True, null=True, help_text="Webhook verification secret")
    
    # Configuration
    base_url = models.URLField(blank=True, null=True, help_text="Gateway API base URL")
    callback_url = models.URLField(blank=True, null=True, help_text="Payment callback URL")
    webhook_url = models.URLField(blank=True, null=True, help_text="Webhook notification URL")
    
    # Supported features
    supports_escrow = models.BooleanField(default=False)
    supports_refunds = models.BooleanField(default=True)
    supports_webhooks = models.BooleanField(default=True)
    supports_subscriptions = models.BooleanField(default=False)
    
    # Limits and fees
    min_amount = models.DecimalField(max_digits=10, decimal_places=2, default=0.01)
    max_amount = models.DecimalField(max_digits=12, decimal_places=2, null=True, blank=True)
    transaction_fee_percentage = models.DecimalField(max_digits=5, decimal_places=4, default=0.0150)
    fixed_transaction_fee = models.DecimalField(max_digits=8, decimal_places=2, default=0.00)
    
    # Metadata
    supported_currencies = models.JSONField(default=list, help_text="List of supported currency codes")
    supported_countries = models.JSONField(default=list, help_text="List of supported country codes")
    additional_config = models.JSONField(default=dict, help_text="Additional gateway-specific configuration")
    
    class Meta:
        db_table = 'payment_gateways'
        verbose_name = 'Payment Gateway'
        verbose_name_plural = 'Payment Gateways'
        
    def __str__(self):
        return f"{self.name} ({'Enabled' if self.is_enabled else 'Disabled'})"
        
    def save(self, *args, **kwargs):
        # Ensure only one gateway is set as default
        if self.is_default:
            PaymentGateway.objects.filter(is_default=True).update(is_default=False)
        super().save(*args, **kwargs)
        
    @classmethod
    def get_default_gateway(cls):
        """Get the default payment gateway."""
        return cls.objects.filter(is_default=True, is_enabled=True).first()
        
    @classmethod
    def get_enabled_gateways(cls):
        """Get all enabled payment gateways."""
        return cls.objects.filter(is_enabled=True)


class Currency(BaseModel):
    """Model to store supported currencies and exchange rates."""
    
    code = models.CharField(max_length=3, unique=True, help_text="ISO 4217 currency code")
    name = models.CharField(max_length=100)
    symbol = models.CharField(max_length=10)
    is_base_currency = models.BooleanField(default=False, help_text="Base currency for exchange rate calculations")
    is_supported = models.BooleanField(default=True)
    
    # Exchange rate relative to base currency
    exchange_rate = models.DecimalField(max_digits=10, decimal_places=6, default=1.000000)
    last_updated = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'currencies'
        verbose_name = 'Currency'
        verbose_name_plural = 'Currencies'
        
    def __str__(self):
        return f"{self.code} - {self.name} ({self.symbol})"
        
    def save(self, *args, **kwargs):
        # Ensure only one currency is set as base
        if self.is_base_currency:
            Currency.objects.filter(is_base_currency=True).update(is_base_currency=False)
            self.exchange_rate = 1.000000
        super().save(*args, **kwargs)


class UserProfile(BaseModel):
    """Extended user profile for payment service functionality."""
    
    VERIFICATION_STATUS_CHOICES = [
        ('unverified', 'Unverified'),
        ('pending', 'Pending Verification'),
        ('verified', 'Verified'),
        ('rejected', 'Rejected'),
    ]
    
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='payment_profile')
    phone_number = models.CharField(
        max_length=20, 
        blank=True, 
        null=True,
        validators=[RegexValidator(regex=r'^\+?1?\d{9,15}$', message="Phone number must be in format: '+999999999'")]
    )
    
    # Verification
    verification_status = models.CharField(max_length=20, choices=VERIFICATION_STATUS_CHOICES, default='unverified')
    identity_document = models.FileField(upload_to='identity_documents/', blank=True, null=True)
    verification_notes = models.TextField(blank=True, null=True)
    verified_at = models.DateTimeField(blank=True, null=True)
    
    # Payment settings
    default_currency = models.ForeignKey(Currency, on_delete=models.PROTECT, null=True, blank=True)
    preferred_payment_method = models.CharField(max_length=50, blank=True, null=True)
    
    # Security
    pin_attempts = models.IntegerField(default=0)
    pin_locked_until = models.DateTimeField(blank=True, null=True)
    two_factor_enabled = models.BooleanField(default=False)
    
    # Statistics
    total_transactions = models.IntegerField(default=0)
    successful_transactions = models.IntegerField(default=0)
    total_amount_transacted = models.DecimalField(max_digits=15, decimal_places=2, default=0.00)
    
    # Preferences
    email_notifications = models.BooleanField(default=True)
    sms_notifications = models.BooleanField(default=True)
    push_notifications = models.BooleanField(default=True)
    
    class Meta:
        db_table = 'user_profiles'
        verbose_name = 'User Profile'
        verbose_name_plural = 'User Profiles'
        
    def __str__(self):
        return f"{self.user.username} - {self.verification_status}"
        
    def is_pin_locked(self):
        """Check if user PIN is currently locked."""
        if self.pin_locked_until:
            return timezone.now() < self.pin_locked_until
        return False
        
    def can_transact(self):
        """Check if user can perform transactions."""
        return (
            self.verification_status == 'verified' and 
            not self.is_pin_locked() and 
            self.is_active
        )
        
    def increment_transaction_stats(self, amount, success=True):
        """Update transaction statistics."""
        self.total_transactions += 1
        if success:
            self.successful_transactions += 1
            self.total_amount_transacted += amount
        self.save(update_fields=['total_transactions', 'successful_transactions', 'total_amount_transacted'])


class SystemConfiguration(BaseModel):
    """System-wide configuration settings for the payment service."""
    
    CONFIG_TYPES = [
        ('string', 'String'),
        ('integer', 'Integer'),
        ('decimal', 'Decimal'),
        ('boolean', 'Boolean'),
        ('json', 'JSON'),
        ('text', 'Text'),
    ]
    
    key = models.CharField(max_length=100, unique=True)
    value = models.TextField()
    value_type = models.CharField(max_length=20, choices=CONFIG_TYPES, default='string')
    description = models.TextField(blank=True, null=True)
    is_system_managed = models.BooleanField(default=True, help_text="Managed by system, not editable by users")
    category = models.CharField(max_length=50, default='general')
    
    class Meta:
        db_table = 'system_configurations'
        verbose_name = 'System Configuration'
        verbose_name_plural = 'System Configurations'
        
    def __str__(self):
        return f"{self.key}: {self.value[:50]}..."
        
    def get_typed_value(self):
        """Return the value converted to its proper type."""
        if self.value_type == 'integer':
            return int(self.value)
        elif self.value_type == 'decimal':
            return float(self.value)
        elif self.value_type == 'boolean':
            return self.value.lower() in ('true', '1', 'yes', 'on')
        elif self.value_type == 'json':
            import json
            return json.loads(self.value)
        return self.value
