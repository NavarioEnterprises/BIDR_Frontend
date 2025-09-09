"""
Transaction models for the BIDR Transaction Service.

This module handles financial transactions between buyers and sellers.
"""

import uuid
from django.db import models
from django.core.validators import MinValueValidator
from decimal import Decimal

# Using local placeholder models to avoid cross-service dependencies
from external_models import Quote, Seller, Buyer

class Transaction(models.Model):
    """
    Financial transactions between buyers and sellers.
    """
    PAYMENT_STATUS_CHOICES = [
        ('PENDING', 'Pending'),
        ('PAID', 'Paid'),
        ('FAILED', 'Failed'),
        ('REFUNDED', 'Refunded'),
    ]
    
    DELIVERY_STATUS_CHOICES = [
        ('PENDING', 'Pending'),
        ('SHIPPED', 'Shipped'),
        ('DELIVERED', 'Delivered'),
        ('COMPLETED', 'Completed'),
    ]
    
    STATUS_CHOICES = [
        ('ACTIVE', 'Active'),
        ('COMPLETED', 'Completed'),
        ('CANCELLED', 'Cancelled'),
        ('DISPUTED', 'Disputed'),
    ]
    
    # Primary key
    transaction_id = models.UUIDField(
        primary_key=True,
        default=uuid.uuid4,
        editable=False,
        help_text="Transaction identifier"
    )
    
    # Related entities
    quote_id = models.ForeignKey(
        Quote,
        on_delete=models.CASCADE,
        related_name='quote_transactions',
        help_text="Reference to Quotes.quote_id"
    )
    buyer_id = models.ForeignKey(
        Buyer,
        on_delete=models.CASCADE,
        related_name='buyer_transactions',
        help_text="Reference to Users.user_id"
    )
    seller_id = models.ForeignKey(
        Seller,
        on_delete=models.CASCADE,
        related_name='seller_transactions',
        help_text="Reference to Users.user_id"
    )
    
    # Security PINs
    buyer_pin = models.CharField(
        max_length=6,
        help_text="6-digit buyer PIN"
    )
    seller_pin = models.CharField(
        max_length=6,
        help_text="6-digit seller PIN"
    )
    
    # Financial details
    total_amount = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        validators=[MinValueValidator(Decimal('0.01'))],
        help_text="Transaction amount"
    )
    currency = models.CharField(
        max_length=3,
        help_text="Currency code"
    )
    
    # Status fields
    payment_status = models.CharField(
        max_length=20,
        choices=PAYMENT_STATUS_CHOICES,
        default='PENDING',
        help_text="Payment status"
    )
    delivery_status = models.CharField(
        max_length=20,
        choices=DELIVERY_STATUS_CHOICES,
        default='PENDING',
        help_text="Delivery status"
    )
    
    # Shipping details
    tracking_number = models.CharField(
        max_length=100,
        null=True,
        blank=True,
        help_text="Shipment tracking number"
    )
    estimated_delivery = models.DateTimeField(
        null=True,
        blank=True,
        help_text="Expected delivery date"
    )
    actual_delivery = models.DateTimeField(
        null=True,
        blank=True,
        help_text="Actual delivery date"
    )
    
    # Overall status
    status = models.CharField(
        max_length=20,
        choices=STATUS_CHOICES,
        default='ACTIVE',
        help_text="Transaction status"
    )
    
    # Timestamps
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
            models.Index(fields=['quote_id']),
            models.Index(fields=['buyer_id']),
            models.Index(fields=['seller_id']),
            models.Index(fields=['payment_status']),
            models.Index(fields=['delivery_status']),
            models.Index(fields=['status']),
        ]
    
    def __str__(self):
        return f"Transaction {self.transaction_id}"
