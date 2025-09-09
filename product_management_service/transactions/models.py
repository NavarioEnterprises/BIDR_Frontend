"""
Transaction models for the BIDR Inventory Service.

This module handles orders, payments, and delivery tracking.
"""

from django.db import models
from django.contrib.auth.models import User
from django.core.validators import MinValueValidator, MaxValueValidator
from django.utils import timezone
from decimal import Decimal
from core.models import ComprehensiveBaseModel, StatusChoices, PriorityChoices
from core.utils import generate_reference_number
# from quotes.models import Quote  # Moved to quoting_service
# from products.models import Product  # Removed - products app deleted


class Transaction(ComprehensiveBaseModel):
    """
    Main transaction/order model representing accepted quotes.
    """
    TRANSACTION_TYPES = [
        ('purchase', 'Purchase Order'),
        ('service', 'Service Order'),
        ('rental', 'Rental Agreement'),
        ('subscription', 'Subscription'),
    ]
    
    PAYMENT_STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('partial', 'Partially Paid'),
        ('paid', 'Fully Paid'),
        ('overdue', 'Overdue'),
        ('refunded', 'Refunded'),
        ('cancelled', 'Cancelled'),
    ]
    
    FULFILLMENT_STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('processing', 'Processing'),
        ('ready', 'Ready for Pickup/Delivery'),
        ('shipped', 'Shipped'),
        ('delivered', 'Delivered'),
        ('completed', 'Completed'),
        ('cancelled', 'Cancelled'),
    ]
    
    # Basic information
    reference_number = models.CharField(max_length=50, unique=True, blank=True)
    transaction_type = models.CharField(max_length=20, choices=TRANSACTION_TYPES, default='purchase')
    
    # Related entities
    # TODO: Restore when quoting service is integrated
    # quote = models.OneToOneField(
    #     Quote,
    #     on_delete=models.PROTECT,
    #     related_name='transaction'
    # )
    buyer = models.ForeignKey(
        User,
        on_delete=models.PROTECT,
        related_name='purchases'
    )
    seller = models.ForeignKey(
        User,
        on_delete=models.PROTECT,
        related_name='sales'
    )
    
    # Financial details
    subtotal = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        validators=[MinValueValidator(Decimal('0.01'))]
    )
    shipping_cost = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        default=Decimal('0.00')
    )
    tax_amount = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        default=Decimal('0.00')
    )
    platform_fee = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        default=Decimal('0.00')
    )
    total_amount = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        validators=[MinValueValidator(Decimal('0.01'))]
    )
    
    # Status tracking
    status = models.CharField(
        max_length=20,
        choices=StatusChoices.choices,
        default=StatusChoices.ACTIVE
    )
    payment_status = models.CharField(
        max_length=20,
        choices=PAYMENT_STATUS_CHOICES,
        default='pending'
    )
    fulfillment_status = models.CharField(
        max_length=20,
        choices=FULFILLMENT_STATUS_CHOICES,
        default='pending'
    )
    
    # Important dates
    order_date = models.DateTimeField(auto_now_add=True)
    expected_delivery_date = models.DateTimeField(null=True, blank=True)
    actual_delivery_date = models.DateTimeField(null=True, blank=True)
    completion_date = models.DateTimeField(null=True, blank=True)
    
    # Terms and conditions
    payment_terms = models.CharField(max_length=100, blank=True)
    delivery_terms = models.TextField(blank=True)
    special_instructions = models.TextField(blank=True)
    
    # Tracking
    tracking_number = models.CharField(max_length=100, blank=True)
    carrier = models.CharField(max_length=100, blank=True)
    
    class Meta:
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['buyer', 'status']),
            models.Index(fields=['seller', 'status']),
            models.Index(fields=['payment_status']),
            models.Index(fields=['fulfillment_status']),
            models.Index(fields=['reference_number']),
            models.Index(fields=['order_date']),
        ]
    
    def __str__(self):
        return f"{self.reference_number} - {self.buyer.username} to {self.seller.username}"
    
    def save(self, *args, **kwargs):
        if not self.reference_number:
            self.reference_number = generate_reference_number("TXN")
        
        # Set expected delivery date from quote if not provided
        # TODO: Restore when quoting service is integrated
        # if not self.expected_delivery_date and self.quote:
        #     self.expected_delivery_date = self.quote.estimated_delivery_date
        
        super().save(*args, **kwargs)
    
    @property
    def is_completed(self):
        """Check if transaction is completed."""
        return (
            self.payment_status == 'paid' and
            self.fulfillment_status == 'completed'
        )
    
    @property
    def is_overdue(self):
        """Check if payment is overdue."""
        return self.payment_status == 'overdue'
    
    @property
    def days_since_order(self):
        """Get days since order was placed."""
        return (timezone.now() - self.order_date).days
    
    @property
    def estimated_profit(self):
        """Calculate estimated profit for seller."""
        return self.subtotal - self.platform_fee
    
    def mark_as_paid(self):
        """Mark transaction as fully paid."""
        self.payment_status = 'paid'
        self.save(update_fields=['payment_status'])
    
    def mark_as_delivered(self):
        """Mark transaction as delivered."""
        self.fulfillment_status = 'delivered'
        self.actual_delivery_date = timezone.now()
        self.save(update_fields=['fulfillment_status', 'actual_delivery_date'])
    
    def mark_as_completed(self):
        """Mark transaction as completed."""
        self.fulfillment_status = 'completed'
        self.completion_date = timezone.now()
        if self.payment_status != 'paid':
            self.payment_status = 'paid'
        self.save(update_fields=['fulfillment_status', 'completion_date', 'payment_status'])


class TransactionItem(models.Model):
    """
    Individual items within a transaction.
    """
    transaction = models.ForeignKey(
        Transaction,
        on_delete=models.CASCADE,
        related_name='items'
    )
    # Temporarily commented out - products app removed
    # product = models.ForeignKey(
    #     Product,
    #     on_delete=models.PROTECT,
    #     null=True,
    #     blank=True
    # )
    
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
    
    # Status tracking
    fulfillment_status = models.CharField(
        max_length=20,
        choices=Transaction.FULFILLMENT_STATUS_CHOICES,
        default='pending'
    )
    
    # Specifications
    specifications = models.JSONField(default=dict, blank=True)
    
    sort_order = models.IntegerField(default=0)
    
    class Meta:
        ordering = ['sort_order', 'id']
        indexes = [
            models.Index(fields=['transaction', 'sort_order']),
            # models.Index(fields=['product']),  # Commented out - products app removed
        ]
    
    def __str__(self):
        return f"{self.transaction.reference_number} - {self.name}"
    
    def save(self, *args, **kwargs):
        # Calculate line total
        self.line_total = self.unit_price * self.quantity
        super().save(*args, **kwargs)
        
        # Reserve inventory if product exists
        # if self.product and self.pk is None:  # New item
        #     self.product.reserve_quantity(self.quantity)
        # TODO: Restore when products app is recreated


class Payment(models.Model):
    """
    Payment records for transactions.
    """
    PAYMENT_METHODS = [
        ('credit_card', 'Credit Card'),
        ('debit_card', 'Debit Card'),
        ('bank_transfer', 'Bank Transfer'),
        ('paypal', 'PayPal'),
        ('stripe', 'Stripe'),
        ('cash', 'Cash'),
        ('check', 'Check'),
        ('crypto', 'Cryptocurrency'),
    ]
    
    PAYMENT_TYPES = [
        ('full', 'Full Payment'),
        ('partial', 'Partial Payment'),
        ('deposit', 'Deposit'),
        ('refund', 'Refund'),
    ]
    
    # Basic information
    reference_number = models.CharField(max_length=50, unique=True, blank=True)
    transaction = models.ForeignKey(
        Transaction,
        on_delete=models.CASCADE,
        related_name='payments'
    )
    
    # Payment details
    amount = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        validators=[MinValueValidator(Decimal('0.01'))]
    )
    payment_method = models.CharField(max_length=20, choices=PAYMENT_METHODS)
    payment_type = models.CharField(max_length=10, choices=PAYMENT_TYPES, default='full')
    
    # Status and timing
    status = models.CharField(
        max_length=20,
        choices=StatusChoices.choices,
        default=StatusChoices.PENDING
    )
    payment_date = models.DateTimeField(auto_now_add=True)
    processed_date = models.DateTimeField(null=True, blank=True)
    
    # External payment processor data
    external_transaction_id = models.CharField(max_length=200, blank=True)
    processor_response = models.JSONField(default=dict, blank=True)
    
    # Additional information
    notes = models.TextField(blank=True)
    processed_by = models.ForeignKey(
        User,
        on_delete=models.PROTECT,
        null=True,
        blank=True,
        related_name='processed_payments'
    )
    
    class Meta:
        ordering = ['-payment_date']
        indexes = [
            models.Index(fields=['transaction', 'status']),
            models.Index(fields=['reference_number']),
            models.Index(fields=['external_transaction_id']),
        ]
    
    def __str__(self):
        return f"{self.reference_number} - ${self.amount}"
    
    def save(self, *args, **kwargs):
        if not self.reference_number:
            self.reference_number = generate_reference_number("PAY")
        super().save(*args, **kwargs)
    
    def mark_as_processed(self, user=None):
        """Mark payment as processed."""
        self.status = StatusChoices.COMPLETED
        self.processed_date = timezone.now()
        if user:
            self.processed_by = user
        self.save(update_fields=['status', 'processed_date', 'processed_by'])


class Delivery(models.Model):
    """
    Delivery information and tracking for transactions.
    """
    DELIVERY_METHODS = [
        ('pickup', 'Customer Pickup'),
        ('delivery', 'Supplier Delivery'),
        ('courier', 'Courier Service'),
        ('postal', 'Postal Service'),
        ('freight', 'Freight Shipping'),
        ('digital', 'Digital Delivery'),
    ]
    
    DELIVERY_STATUS_CHOICES = [
        ('scheduled', 'Scheduled'),
        ('picked_up', 'Picked Up'),
        ('in_transit', 'In Transit'),
        ('out_for_delivery', 'Out for Delivery'),
        ('delivered', 'Delivered'),
        ('failed', 'Delivery Failed'),
        ('returned', 'Returned to Sender'),
    ]
    
    transaction = models.OneToOneField(
        Transaction,
        on_delete=models.CASCADE,
        related_name='delivery'
    )
    
    # Delivery method and carrier
    delivery_method = models.CharField(max_length=20, choices=DELIVERY_METHODS)
    carrier = models.CharField(max_length=100, blank=True)
    tracking_number = models.CharField(max_length=100, blank=True)
    
    # Delivery address
    delivery_address = models.TextField()
    delivery_contact_name = models.CharField(max_length=200)
    delivery_contact_phone = models.CharField(max_length=20, blank=True)
    delivery_contact_email = models.EmailField(blank=True)
    
    # Scheduling
    scheduled_date = models.DateTimeField(null=True, blank=True)
    estimated_delivery_window_start = models.DateTimeField(null=True, blank=True)
    estimated_delivery_window_end = models.DateTimeField(null=True, blank=True)
    
    # Status and timeline
    status = models.CharField(
        max_length=20,
        choices=DELIVERY_STATUS_CHOICES,
        default='scheduled'
    )
    pickup_date = models.DateTimeField(null=True, blank=True)
    delivery_date = models.DateTimeField(null=True, blank=True)
    
    # Delivery details
    delivery_instructions = models.TextField(blank=True)
    signature_required = models.BooleanField(default=False)
    signature_name = models.CharField(max_length=200, blank=True)
    delivery_notes = models.TextField(blank=True)
    
    # Costs
    delivery_cost = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        default=Decimal('0.00')
    )
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['tracking_number']),
            models.Index(fields=['status']),
            models.Index(fields=['scheduled_date']),
        ]
    
    def __str__(self):
        return f"Delivery for {self.transaction.reference_number}"
    
    @property
    def is_delivered(self):
        """Check if delivery is completed."""
        return self.status == 'delivered'
    
    def mark_as_delivered(self, signature_name=None, notes=None):
        """Mark delivery as completed."""
        self.status = 'delivered'
        self.delivery_date = timezone.now()
        if signature_name:
            self.signature_name = signature_name
        if notes:
            self.delivery_notes = notes
        self.save()
        
        # Update transaction status
        self.transaction.mark_as_delivered()


class TransactionMessage(models.Model):
    """
    Messages/communications related to transactions.
    """
    MESSAGE_TYPES = [
        ('inquiry', 'General Inquiry'),
        ('payment', 'Payment Related'),
        ('delivery', 'Delivery Related'),
        ('issue', 'Issue/Problem'),
        ('update', 'Status Update'),
        ('system', 'System Message'),
    ]
    
    transaction = models.ForeignKey(
        Transaction,
        on_delete=models.CASCADE,
        related_name='messages'
    )
    sender = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='sent_transaction_messages'
    )
    message_type = models.CharField(max_length=20, choices=MESSAGE_TYPES, default='inquiry')
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
            models.Index(fields=['transaction', 'created_at']),
            models.Index(fields=['sender']),
        ]
    
    def __str__(self):
        return f"{self.transaction.reference_number} - {self.sender.username}: {self.subject or 'Message'}"
    
    @property
    def is_read(self):
        """Check if message has been read."""
        return self.read_at is not None
    
    def mark_as_read(self):
        """Mark message as read."""
        if not self.is_read:
            self.read_at = timezone.now()
            self.save(update_fields=['read_at'])
