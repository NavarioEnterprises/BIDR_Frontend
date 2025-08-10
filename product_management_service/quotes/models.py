"""
Quote models for the BIDR Quoting Service.

This module handles supplier quotes in response to product requests.
"""

import uuid
from django.db import models
from django.contrib.auth.models import User
from django.core.validators import MinValueValidator
from django.utils import timezone
from decimal import Decimal


class Quote(models.Model):
    """
    Supplier quotes in response to product requests.
    Based on the specifications table requirements.
    """
    STATUS_CHOICES = [
        ('PENDING', 'Pending'),
        ('ACCEPTED', 'Accepted'),
        ('REJECTED', 'Rejected'),
        ('EXPIRED', 'Expired'),
    ]
    
    # Primary key - quote_id (UUID, PRIMARY KEY, NOT NULL)
    quote_id = models.UUIDField(
        primary_key=True, 
        default=uuid.uuid4, 
        editable=False, 
        help_text="Quote identifier"
    )
    
    # Related entities
    request_id = models.ForeignKey(
        'product_requests.ProductRequest',
        on_delete=models.CASCADE,
        related_name='quotes',
        help_text="Reference to Product_Requests.request_id"
    )
    seller_id = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='submitted_quotes',
        help_text="Reference to Users.user_id"
    )
    
    # Pricing
    total_amount = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        validators=[MinValueValidator(Decimal('0.01'))],
        help_text="Total quote amount"
    )
    currency = models.CharField(
        max_length=3,
        help_text="Currency code"
    )
    
    # Additional costs
    delivery_cost = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        null=True,
        blank=True,
        help_text="Delivery charges"
    )
    installation_cost = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        null=True,
        blank=True,
        help_text="Installation charges"
    )
    
    # Delivery and terms
    estimated_delivery_days = models.IntegerField(
        null=True,
        blank=True,
        help_text="Delivery timeframe"
    )
    terms_conditions = models.TextField(
        null=True,
        blank=True,
        help_text="Quote terms"
    )
    seller_notes = models.TextField(
        null=True,
        blank=True,
        help_text="Additional seller comments"
    )
    warranty_info = models.JSONField(
        null=True,
        blank=True,
        help_text="Warranty details"
    )
    
    # Status and workflow
    status = models.CharField(
        max_length=20,
        choices=STATUS_CHOICES,
        default='PENDING',
        help_text="Quote status"
    )
    
    # Validity and timestamps
    valid_until = models.DateTimeField(
        help_text="Quote expiration"
    )
    created_at = models.DateTimeField(
        auto_now_add=True,
        help_text="Creation date"
    )
    updated_at = models.DateTimeField(
        auto_now=True,
        help_text="Last modified"
    )
    
    class Meta:
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['request_id']),
            models.Index(fields=['seller_id']),
            models.Index(fields=['status']),
        ]
    
    def __str__(self):
        return f"Quote {self.quote_id} - {self.seller_id.username}"
    
    @property
    def is_expired(self):
        """Check if the quote has expired."""
        return timezone.now() > self.valid_until
    
    @property
    def is_valid(self):
        """Check if quote is still valid and can be accepted."""
        return (
            self.status == 'PENDING' and
            not self.is_expired
        )


class QuoteItem(models.Model):
    """
    Individual items within a quote (for detailed breakdown).
    """
    quote = models.ForeignKey(
        Quote,
        on_delete=models.CASCADE,
        related_name='items'
    )
    
    # Item details
    name = models.CharField(max_length=200)
    description = models.TextField(blank=True)
    sku = models.CharField(max_length=100, blank=True)
    
    # Pricing and quantity
    unit_price = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        validators=[MinValueValidator(Decimal('0.01'))]
    )
    quantity = models.IntegerField(
        validators=[MinValueValidator(1)]
    )
    line_total = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        validators=[MinValueValidator(Decimal('0.01'))]
    )
    
    # Specifications
    specifications = models.JSONField(default=dict, blank=True)
    
    sort_order = models.IntegerField(default=0)
    
    class Meta:
        ordering = ['sort_order', 'id']
        indexes = [
            models.Index(fields=['quote', 'sort_order']),
        ]
    
    def __str__(self):
        return f"{self.quote.quote_id} - {self.name}"
    
    def save(self, *args, **kwargs):
        # Calculate line total
        self.line_total = self.unit_price * self.quantity
        super().save(*args, **kwargs)


class QuoteAttachment(models.Model):
    """
    File attachments for quotes (specifications, catalogs, etc.).
    """
    quote = models.ForeignKey(
        Quote,
        on_delete=models.CASCADE,
        related_name='attachments'
    )
    file = models.FileField(upload_to='quotes/attachments/')
    filename = models.CharField(max_length=200)
    description = models.CharField(max_length=500, blank=True)
    file_size = models.IntegerField(help_text="File size in bytes")
    content_type = models.CharField(max_length=100)
    uploaded_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        ordering = ['uploaded_at']
    
    def __str__(self):
        return f"{self.quote.quote_id} - {self.filename}"
    
    @property
    def file_size_formatted(self):
        """Get human-readable file size."""
        size = self.file_size
        for unit in ['B', 'KB', 'MB', 'GB']:
            if size < 1024.0:
                return f"{size:.1f} {unit}"
            size /= 1024.0
        return f"{size:.1f} TB"


class QuoteMessage(models.Model):
    """
    Messages/communications related to quotes.
    """
    MESSAGE_TYPES = [
        ('clarification', 'Clarification'),
        ('negotiation', 'Negotiation'),
        ('revision', 'Revision Request'),
        ('acceptance', 'Acceptance'),
        ('rejection', 'Rejection'),
        ('system', 'System Message'),
    ]
    
    quote = models.ForeignKey(
        Quote,
        on_delete=models.CASCADE,
        related_name='messages'
    )
    sender = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='sent_quote_messages'
    )
    message_type = models.CharField(max_length=20, choices=MESSAGE_TYPES, default='clarification')
    subject = models.CharField(max_length=200, blank=True)
    message = models.TextField()
    is_internal = models.BooleanField(
        default=False,
        help_text="Internal messages not visible to other party"
    )
    created_at = models.DateTimeField(auto_now_add=True)
    read_at = models.DateTimeField(null=True, blank=True)
    
    class Meta:
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['quote', 'created_at']),
            models.Index(fields=['sender']),
        ]
    
    def __str__(self):
        return f"{self.quote.quote_id} - {self.sender.username}: {self.subject or 'Message'}"
    
    @property
    def is_read(self):
        """Check if message has been read."""
        return self.read_at is not None
    
    def mark_as_read(self):
        """Mark message as read."""
        if not self.is_read:
            self.read_at = timezone.now()
            self.save(update_fields=['read_at'])


class QuoteComparison(models.Model):
    """
    Store quote comparisons for a request.
    """
    request = models.OneToOneField(
        'product_requests.ProductRequest',
        on_delete=models.CASCADE,
        related_name='quote_comparison'
    )
    
    # Comparison metadata
    total_quotes = models.IntegerField(default=0)
    lowest_price = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        null=True,
        blank=True
    )
    highest_price = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        null=True,
        blank=True
    )
    average_price = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        null=True,
        blank=True
    )
    
    # Best options
    best_price_quote = models.ForeignKey(
        Quote,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='best_price_comparisons'
    )
    best_delivery_quote = models.ForeignKey(
        Quote,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='best_delivery_comparisons'
    )
    
    # Analysis data
    comparison_data = models.JSONField(
        default=dict,
        help_text="Detailed comparison analysis"
    )
    
    last_updated = models.DateTimeField(auto_now=True)
    
    class Meta:
        indexes = [
            models.Index(fields=['request']),
        ]
    
    def __str__(self):
        return f"Comparison for {self.request.request_id}"
    
    def refresh_comparison(self):
        """Refresh comparison data based on current quotes."""
        quotes = self.request.quotes.filter(
            status='ACTIVE'
        ).order_by('total_amount')
        
        if not quotes.exists():
            return
        
        self.total_quotes = quotes.count()
        prices = [q.total_amount for q in quotes]
        
        self.lowest_price = min(prices)
        self.highest_price = max(prices)
        self.average_price = sum(prices) / len(prices)
        
        # Best price quote
        self.best_price_quote = quotes.first()
        
        # Best delivery (shortest delivery time)
        self.best_delivery_quote = quotes.order_by('estimated_delivery_days').first()
        
        self.save()