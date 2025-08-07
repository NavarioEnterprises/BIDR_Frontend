"""
Product Request models for the BIDR Inventory Service.

This module handles customer requests for products, including RFQs (Request for Quote).
"""

from django.db import models
from django.contrib.auth.models import User
from django.core.validators import MinValueValidator, MaxValueValidator
from django.utils import timezone
from decimal import Decimal
from core.models import ComprehensiveBaseModel, StatusChoices, PriorityChoices
from core.utils import calculate_expiry_date, generate_reference_number
from categories.models import Category
from products.models import Product


class ProductRequest(ComprehensiveBaseModel):
    """
    Customer requests for products or quotes.
    """
    REQUEST_TYPES = [
        ('product_inquiry', 'Product Inquiry'),
        ('quote_request', 'Quote Request'),
        ('bulk_order', 'Bulk Order'),
        ('custom_product', 'Custom Product'),
        ('unavailable_product', 'Unavailable Product Request'),
    ]
    
    URGENCY_LEVELS = [
        ('low', 'Low - No rush'),
        ('medium', 'Medium - Standard'),
        ('high', 'High - Priority'),
        ('urgent', 'Urgent - ASAP'),
    ]
    
    # Basic information
    reference_number = models.CharField(max_length=50, unique=True, blank=True)
    title = models.CharField(max_length=200)
    description = models.TextField()
    request_type = models.CharField(max_length=30, choices=REQUEST_TYPES)
    
    # Requester information
    requester = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='product_requests'
    )
    requester_company = models.CharField(max_length=200, blank=True)
    contact_email = models.EmailField(blank=True)
    contact_phone = models.CharField(max_length=20, blank=True)
    
    # Product details
    category = models.ForeignKey(
        Category,
        on_delete=models.PROTECT,
        null=True,
        blank=True
    )
    existing_product = models.ForeignKey(
        Product,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='requests'
    )
    
    # Quantity and specifications
    quantity_needed = models.IntegerField(
        validators=[MinValueValidator(1)],
        help_text="Quantity of items needed"
    )
    unit_of_measure = models.CharField(
        max_length=50,
        default='pieces',
        help_text="Unit of measurement (pieces, kg, meters, etc.)"
    )
    
    # Budget and pricing
    budget_min = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        null=True,
        blank=True,
        validators=[MinValueValidator(Decimal('0.01'))],
        help_text="Minimum budget per unit"
    )
    budget_max = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        null=True,
        blank=True,
        validators=[MinValueValidator(Decimal('0.01'))],
        help_text="Maximum budget per unit"
    )
    total_budget = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        null=True,
        blank=True,
        validators=[MinValueValidator(Decimal('0.01'))],
        help_text="Total budget for the entire order"
    )
    
    # Timeline
    urgency = models.CharField(
        max_length=10,
        choices=URGENCY_LEVELS,
        default='medium'
    )
    needed_by_date = models.DateTimeField(
        null=True,
        blank=True,
        help_text="When the product is needed by"
    )
    expires_at = models.DateTimeField(
        null=True,
        blank=True,
        help_text="When this request expires"
    )
    
    # Status and workflow
    status = models.CharField(
        max_length=20,
        choices=StatusChoices.choices,
        default=StatusChoices.PENDING
    )
    priority = models.CharField(
        max_length=10,
        choices=PriorityChoices.choices,
        default=PriorityChoices.MEDIUM
    )
    
    # Response tracking
    quote_count = models.IntegerField(default=0)
    view_count = models.IntegerField(default=0)
    
    # Delivery requirements
    delivery_required = models.BooleanField(default=True)
    preferred_delivery_date = models.DateTimeField(null=True, blank=True)
    
    class Meta:
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['status', 'priority']),
            models.Index(fields=['requester', 'status']),
            models.Index(fields=['category', 'status']),
            models.Index(fields=['expires_at']),
            models.Index(fields=['needed_by_date']),
            models.Index(fields=['reference_number']),
        ]
    
    def __str__(self):
        return f"{self.reference_number} - {self.title}"
    
    def save(self, *args, **kwargs):
        if not self.reference_number:
            self.reference_number = generate_reference_number("REQ")
        
        # Set expiry date if not provided
        if not self.expires_at:
            from django.conf import settings
            days = getattr(settings, 'INVENTORY_SETTINGS', {}).get('DEFAULT_REQUEST_EXPIRY_DAYS', 30)
            self.expires_at = calculate_expiry_date(days)
        
        super().save(*args, **kwargs)
    
    @property
    def is_expired(self):
        """Check if the request has expired."""
        if not self.expires_at:
            return False
        return timezone.now() > self.expires_at
    
    @property
    def is_urgent(self):
        """Check if the request is urgent based on needed_by_date."""
        if not self.needed_by_date:
            return self.urgency in ['high', 'urgent']
        
        # Check if needed within 48 hours
        time_left = self.needed_by_date - timezone.now()
        return time_left.total_seconds() < 48 * 3600  # 48 hours in seconds
    
    @property
    def average_budget(self):
        """Get average budget per unit."""
        if self.budget_min and self.budget_max:
            return (self.budget_min + self.budget_max) / 2
        return self.budget_min or self.budget_max
    
    def can_receive_quotes(self):
        """Check if request can still receive quotes."""
        return (
            self.status in [StatusChoices.PENDING, StatusChoices.ACTIVE] and
            not self.is_expired
        )
    
    def mark_as_viewed(self):
        """Increment view count."""
        self.view_count += 1
        self.save(update_fields=['view_count'])


class RequestImage(models.Model):
    """
    Images attached to product requests for reference.
    """
    request = models.ForeignKey(
        ProductRequest,
        on_delete=models.CASCADE,
        related_name='images'
    )
    image = models.ImageField(upload_to='requests/')
    caption = models.CharField(max_length=200, blank=True)
    sort_order = models.IntegerField(default=0)
    
    class Meta:
        ordering = ['sort_order', 'id']
    
    def __str__(self):
        return f"{self.request.reference_number} - Image {self.id}"


class RequestSpecification(models.Model):
    """
    Detailed specifications for product requests.
    """
    request = models.ForeignKey(
        ProductRequest,
        on_delete=models.CASCADE,
        related_name='specifications'
    )
    name = models.CharField(max_length=100)
    value = models.TextField()
    is_required = models.BooleanField(default=False)
    sort_order = models.IntegerField(default=0)
    
    class Meta:
        unique_together = ['request', 'name']
        ordering = ['sort_order', 'name']
    
    def __str__(self):
        return f"{self.request.reference_number} - {self.name}: {self.value}"


class RequestMessage(models.Model):
    """
    Messages/communications related to product requests.
    """
    MESSAGE_TYPES = [
        ('inquiry', 'Inquiry'),
        ('clarification', 'Clarification'),
        ('update', 'Update'),
        ('quote_submission', 'Quote Submission'),
        ('system', 'System Message'),
    ]
    
    request = models.ForeignKey(
        ProductRequest,
        on_delete=models.CASCADE,
        related_name='messages'
    )
    sender = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='sent_request_messages'
    )
    message_type = models.CharField(max_length=20, choices=MESSAGE_TYPES, default='inquiry')
    subject = models.CharField(max_length=200, blank=True)
    message = models.TextField()
    is_internal = models.BooleanField(
        default=False,
        help_text="Internal messages not visible to requester"
    )
    created_at = models.DateTimeField(auto_now_add=True)
    read_at = models.DateTimeField(null=True, blank=True)
    
    class Meta:
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['request', 'created_at']),
            models.Index(fields=['sender']),
        ]
    
    def __str__(self):
        return f"{self.request.reference_number} - {self.sender.username}: {self.subject or 'Message'}"
    
    @property
    def is_read(self):
        """Check if message has been read."""
        return self.read_at is not None
    
    def mark_as_read(self):
        """Mark message as read."""
        if not self.is_read:
            self.read_at = timezone.now()
            self.save(update_fields=['read_at'])


class RequestWatchlist(models.Model):
    """
    Users can watch product requests to get notifications.
    """
    request = models.ForeignKey(
        ProductRequest,
        on_delete=models.CASCADE,
        related_name='watchers'
    )
    user = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='watched_requests'
    )
    created_at = models.DateTimeField(auto_now_add=True)
    
    # Notification preferences
    notify_on_quotes = models.BooleanField(default=True)
    notify_on_updates = models.BooleanField(default=True)
    notify_on_messages = models.BooleanField(default=False)
    
    class Meta:
        unique_together = ['request', 'user']
        indexes = [
            models.Index(fields=['user', 'created_at']),
        ]
    
    def __str__(self):
        return f"{self.user.username} watching {self.request.reference_number}"


class RequestTemplate(models.Model):
    """
    Templates for common product request types.
    """
    name = models.CharField(max_length=100)
    description = models.TextField(blank=True)
    category = models.ForeignKey(
        Category,
        on_delete=models.CASCADE,
        related_name='request_templates'
    )
    request_type = models.CharField(
        max_length=30,
        choices=ProductRequest.REQUEST_TYPES
    )
    
    # Template data
    template_data = models.JSONField(
        default=dict,
        help_text="JSON data for pre-filling request forms"
    )
    
    # Usage tracking
    usage_count = models.IntegerField(default=0)
    is_active = models.BooleanField(default=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['category__name', 'name']
        indexes = [
            models.Index(fields=['category', 'is_active']),
            models.Index(fields=['request_type', 'is_active']),
        ]
    
    def __str__(self):
        return f"{self.category.name} - {self.name}"
    
    def increment_usage(self):
        """Increment usage count when template is used."""
        self.usage_count += 1
        self.save(update_fields=['usage_count'])
