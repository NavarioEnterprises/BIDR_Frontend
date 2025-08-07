"""
Quote models for the BIDR Inventory Service.

This module handles supplier quotes in response to product requests.
"""

from django.db import models
from django.contrib.auth.models import User
from django.core.validators import MinValueValidator, MaxValueValidator
from django.utils import timezone
from decimal import Decimal, ROUND_HALF_UP
from core.models import ComprehensiveBaseModel, StatusChoices, PriorityChoices
from core.utils import calculate_expiry_date, generate_reference_number, calculate_platform_fee
from product_requests.models import ProductRequest
from products.models import Product


class Quote(ComprehensiveBaseModel):
    """
    Supplier quotes in response to product requests.
    """
    QUOTE_TYPES = [
        ('standard', 'Standard Quote'),
        ('bulk_discount', 'Bulk Discount'),
        ('custom_pricing', 'Custom Pricing'),
        ('negotiable', 'Negotiable'),
        ('fixed_price', 'Fixed Price'),
    ]
    
    DELIVERY_METHODS = [
        ('pickup', 'Customer Pickup'),
        ('delivery', 'Supplier Delivery'),
        ('shipping', 'Third-party Shipping'),
        ('digital', 'Digital Delivery'),
    ]
    
    # Basic information
    reference_number = models.CharField(max_length=50, unique=True, blank=True)
    title = models.CharField(max_length=200)
    description = models.TextField(blank=True)
    quote_type = models.CharField(max_length=20, choices=QUOTE_TYPES, default='standard')
    
    # Related entities
    request = models.ForeignKey(
        ProductRequest,
        on_delete=models.CASCADE,
        related_name='quotes'
    )
    supplier = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='submitted_quotes'
    )
    product = models.ForeignKey(
        Product,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='quotes'
    )
    
    # Pricing
    unit_price = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        validators=[MinValueValidator(Decimal('0.01'))]
    )
    quantity_quoted = models.IntegerField(
        validators=[MinValueValidator(1)]
    )
    total_price = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        validators=[MinValueValidator(Decimal('0.01'))]
    )
    
    # Additional costs
    shipping_cost = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        default=Decimal('0.00'),
        validators=[MinValueValidator(Decimal('0.00'))]
    )
    tax_amount = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        default=Decimal('0.00'),
        validators=[MinValueValidator(Decimal('0.00'))]
    )
    platform_fee = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        default=Decimal('0.00'),
        validators=[MinValueValidator(Decimal('0.00'))]
    )
    final_total = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        validators=[MinValueValidator(Decimal('0.01'))]
    )
    
    # Delivery and terms
    delivery_method = models.CharField(
        max_length=20,
        choices=DELIVERY_METHODS,
        default='delivery'
    )
    estimated_delivery_days = models.IntegerField(
        default=7,
        validators=[MinValueValidator(0)],
        help_text="Estimated delivery time in days"
    )
    delivery_terms = models.TextField(blank=True)
    
    # Validity and payment
    valid_until = models.DateTimeField(
        null=True,
        blank=True,
        help_text="Quote validity expiration"
    )
    payment_terms = models.CharField(
        max_length=100,
        default='Net 30',
        help_text="Payment terms (e.g., Net 30, COD, etc.)"
    )
    
    # Status and workflow
    status = models.CharField(
        max_length=20,
        choices=StatusChoices.choices,
        default=StatusChoices.PENDING
    )
    
    # Competitive analysis
    is_best_price = models.BooleanField(default=False)
    rank_position = models.IntegerField(null=True, blank=True)
    
    # Response tracking
    viewed_by_requester = models.BooleanField(default=False)
    requester_view_date = models.DateTimeField(null=True, blank=True)
    
    class Meta:
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['request', 'status']),
            models.Index(fields=['supplier', 'status']),
            models.Index(fields=['status', 'valid_until']),
            models.Index(fields=['reference_number']),
            models.Index(fields=['unit_price']),
        ]
        unique_together = ['request', 'supplier']  # One quote per supplier per request
    
    def __str__(self):
        return f"{self.reference_number} - {self.supplier.username}"
    
    def save(self, *args, **kwargs):
        if not self.reference_number:
            self.reference_number = generate_reference_number("QTE")
        
        # Set validity date if not provided
        if not self.valid_until:
            from django.conf import settings
            days = getattr(settings, 'INVENTORY_SETTINGS', {}).get('DEFAULT_QUOTE_VALIDITY_DAYS', 7)
            self.valid_until = calculate_expiry_date(days)
        
        # Calculate platform fee
        if not self.platform_fee:
            from django.conf import settings
            fee_percentage = getattr(settings, 'INVENTORY_SETTINGS', {}).get('PLATFORM_FEE_PERCENTAGE', 5.0)
            self.platform_fee = calculate_platform_fee(self.total_price, fee_percentage)
        
        # Calculate final total
        self.final_total = self.total_price + self.shipping_cost + self.tax_amount + self.platform_fee
        
        super().save(*args, **kwargs)
        
        # Update request quote count
        if self.pk is None:  # New quote
            self.request.quote_count += 1
            self.request.save(update_fields=['quote_count'])
    
    @property
    def is_expired(self):
        """Check if the quote has expired."""
        if not self.valid_until:
            return False
        return timezone.now() > self.valid_until
    
    @property
    def is_valid(self):
        """Check if quote is still valid and can be accepted."""
        return (
            self.status == StatusChoices.ACTIVE and
            not self.is_expired and
            self.request.can_receive_quotes()
        )
    
    @property
    def price_per_unit_with_extras(self):
        """Calculate price per unit including shipping and fees."""
        if self.quantity_quoted == 0:
            return Decimal('0.00')
        return (self.final_total / self.quantity_quoted).quantize(
            Decimal('0.01'), rounding=ROUND_HALF_UP
        )
    
    @property
    def estimated_delivery_date(self):
        """Calculate estimated delivery date."""
        from datetime import timedelta
        return timezone.now().date() + timedelta(days=self.estimated_delivery_days)
    
    def mark_as_viewed(self, user=None):
        """Mark quote as viewed by requester."""
        if not self.viewed_by_requester:
            self.viewed_by_requester = True
            self.requester_view_date = timezone.now()
            self.save(update_fields=['viewed_by_requester', 'requester_view_date'])
    
    def calculate_savings_vs_budget(self):
        """Calculate savings compared to request budget."""
        if not self.request.average_budget:
            return None
        
        budget_total = self.request.average_budget * self.quantity_quoted
        savings = budget_total - self.final_total
        return {
            'savings_amount': savings,
            'savings_percentage': round((savings / budget_total) * 100, 2) if budget_total > 0 else 0
        }


class QuoteItem(models.Model):
    """
    Individual items within a quote (for detailed breakdown).
    """
    quote = models.ForeignKey(
        Quote,
        on_delete=models.CASCADE,
        related_name='items'
    )
    product = models.ForeignKey(
        Product,
        on_delete=models.SET_NULL,
        null=True,
        blank=True
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
        return f"{self.quote.reference_number} - {self.name}"
    
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
        return f"{self.quote.reference_number} - {self.filename}"
    
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
        return f"{self.quote.reference_number} - {self.sender.username}: {self.subject or 'Message'}"
    
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
        ProductRequest,
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
        return f"Comparison for {self.request.reference_number}"
    
    def refresh_comparison(self):
        """Refresh comparison data based on current quotes."""
        quotes = self.request.quotes.filter(
            status=StatusChoices.ACTIVE
        ).order_by('final_total')
        
        if not quotes.exists():
            return
        
        self.total_quotes = quotes.count()
        prices = [q.final_total for q in quotes]
        
        self.lowest_price = min(prices)
        self.highest_price = max(prices)
        self.average_price = sum(prices) / len(prices)
        
        # Best price quote
        self.best_price_quote = quotes.first()
        
        # Best delivery (shortest delivery time)
        self.best_delivery_quote = quotes.order_by('estimated_delivery_days').first()
        
        # Update ranking
        for i, quote in enumerate(quotes, 1):
            quote.rank_position = i
            quote.is_best_price = (i == 1)
            quote.save(update_fields=['rank_position', 'is_best_price'])
        
        self.save()
