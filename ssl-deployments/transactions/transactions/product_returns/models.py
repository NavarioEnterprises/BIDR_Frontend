"""
Product return models for the BIDR Transaction Service.

This module handles product returns and refunds for transactions.
"""

import uuid
from django.db import models
from django.core.validators import MinValueValidator
from decimal import Decimal

from transactions.models import Transaction


class ProductReturn(models.Model):
    """
    Product returns and refund requests for transactions.
    """
    STATUS_CHOICES = [
        ('REQUESTED', 'Requested'),
        ('APPROVED', 'Approved'),
        ('REJECTED', 'Rejected'),
        ('COMPLETED', 'Completed'),
    ]
    
    # Primary key
    return_id = models.UUIDField(
        primary_key=True,
        default=uuid.uuid4,
        editable=False,
        help_text="Return identifier"
    )
    
    # Related transaction
    transaction_id = models.ForeignKey(
        Transaction,
        on_delete=models.CASCADE,
        related_name='product_returns',
        help_text="Reference to Transactions.transaction_id"
    )
    
    # Return details
    return_reason = models.CharField(
        max_length=100,
        help_text="Reason for return"
    )
    
    return_description = models.TextField(
        help_text="Detailed return description"
    )
    
    condition_photos = models.JSONField(
        help_text="Array of photo URLs"
    )
    
    return_shipping_address = models.JSONField(
        help_text="Return address details"
    )
    
    return_tracking_number = models.CharField(
        max_length=100,
        null=True,
        blank=True,
        help_text="Return shipment tracking"
    )
    
    # Refund details
    refund_amount = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        validators=[MinValueValidator(Decimal('0.01'))],
        help_text="Refund amount"
    )
    
    admin_notes = models.TextField(
        null=True,
        blank=True,
        help_text="Administrative comments"
    )
    
    # Status
    status = models.CharField(
        max_length=20,
        choices=STATUS_CHOICES,
        default='REQUESTED',
        help_text="'REQUESTED', 'APPROVED', 'REJECTED', 'COMPLETED'"
    )
    
    # Timestamps
    requested_at = models.DateTimeField(
        auto_now_add=True,
        help_text="Return request date"
    )
    
    processed_at = models.DateTimeField(
        null=True,
        blank=True,
        help_text="Processing completion date"
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
            models.Index(fields=['transaction_id']),
            models.Index(fields=['status']),
            models.Index(fields=['requested_at']),
        ]
    
    def __str__(self):
        return f"Return {self.return_id} for Transaction {self.transaction_id}"
    
    def is_pending(self):
        """Check if the return is pending approval."""
        return self.status == 'REQUESTED'
    
    def is_approved(self):
        """Check if the return has been approved."""
        return self.status == 'APPROVED'
    
    def is_rejected(self):
        """Check if the return has been rejected."""
        return self.status == 'REJECTED'
    
    def is_completed(self):
        """Check if the return process has been completed."""
        return self.status == 'COMPLETED'
