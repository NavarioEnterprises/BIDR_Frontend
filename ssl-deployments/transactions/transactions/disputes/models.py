"""
Dispute models for the BIDR Transaction Service.

This module handles disputes between buyers and sellers for transactions.
"""

import uuid
from django.db import models
from django.utils import timezone

from transactions.models import Transaction
from django.contrib.auth.models import User as AppUser


class Dispute(models.Model):
    """
    Disputes for transactions between buyers and sellers.
    """
    DISPUTE_TYPE_CHOICES = [
        ('PAYMENT', 'Payment'),
        ('DELIVERY', 'Delivery'),
        ('QUALITY', 'Quality'),
        ('OTHER', 'Other'),
    ]
    
    STATUS_CHOICES = [
        ('OPEN', 'Open'),
        ('INVESTIGATING', 'Investigating'),
        ('RESOLVED', 'Resolved'),
        ('CLOSED', 'Closed'),
    ]
    
    # Primary key
    dispute_id = models.UUIDField(
        primary_key=True,
        default=uuid.uuid4,
        editable=False,
        help_text="Dispute identifier"
    )
    
    # Related entities
    request_id = models.UUIDField(
        default=uuid.uuid4,
        help_text="Reference to request UUID (formerly transaction_id)"
    )
    
    buyer_id = models.UUIDField(
        default=uuid.uuid4,
        help_text="Reference to buyer user UUID (formerly initiator_id)"
    )
    
    seller_id = models.UUIDField(
        default=uuid.uuid4,
        help_text="Reference to seller user UUID"
    )
    
    # Dispute details
    dispute_type = models.CharField(
        max_length=20,
        choices=DISPUTE_TYPE_CHOICES,
        help_text="'PAYMENT', 'DELIVERY', 'QUALITY', 'OTHER'"
    )
    
    description = models.TextField(
        help_text="Dispute description"
    )
    
    evidence_files = models.JSONField(
        null=True,
        blank=True,
        help_text="Supporting evidence"
    )
    
    # Status
    status = models.CharField(
        max_length=20,
        choices=STATUS_CHOICES,
        default='OPEN',
        help_text="'OPEN', 'INVESTIGATING', 'RESOLVED', 'CLOSED'"
    )
    
    # Resolution
    resolution = models.TextField(
        null=True,
        blank=True,
        help_text="Resolution details"
    )
    
    resolved_by = models.ForeignKey(
        AppUser,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='resolved_disputes',
        help_text="Reference to admin Users.user_id"
    )
    
    resolved_at = models.DateTimeField(
        null=True,
        blank=True,
        help_text="Resolution date"
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
            models.Index(fields=['request_id']),
            models.Index(fields=['buyer_id']),
            models.Index(fields=['seller_id']),
            models.Index(fields=['dispute_type']),
            models.Index(fields=['status']),
            models.Index(fields=['resolved_at']),
        ]
    
    def __str__(self):
        return f"Dispute {self.dispute_id} for Request {self.request_id}"
    
    def is_open(self):
        """Check if the dispute is open."""
        return self.status == 'OPEN'
    
    def is_investigating(self):
        """Check if the dispute is under investigation."""
        return self.status == 'INVESTIGATING'
    
    def is_resolved(self):
        """Check if the dispute has been resolved."""
        return self.status == 'RESOLVED'
    
    def is_closed(self):
        """Check if the dispute has been closed."""
        return self.status == 'CLOSED'
    
    def resolve(self, resolution_text, resolved_by_user):
        """
        Resolve the dispute with the provided resolution details.
        
        Args:
            resolution_text (str): The resolution details
            resolved_by_user (AppUser): The admin user who resolved the dispute
        """
        self.resolution = resolution_text
        self.resolved_by = resolved_by_user
        self.resolved_at = timezone.now()
        self.status = 'RESOLVED'
        self.save()
        return True
    
    def close(self):
        """Close the dispute."""
        self.status = 'CLOSED'
        self.save()
        return True
