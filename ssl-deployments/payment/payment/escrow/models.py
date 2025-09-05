"""
Escrow models for BIDR Payment Service.

Handles payment hold periods, early release requests, and escrow management
as specified in the requirements.
"""

import uuid
from django.db import models
from django.utils import timezone
from django.core.validators import MinValueValidator
from core.models import BaseModel
from transactions.models import Transaction


class EscrowPeriod(BaseModel):
    """Model to manage escrow periods for transactions."""
    
    CATEGORY_CHOICES = [
        ('vehicle_parts', 'Vehicle Parts'),
        ('electronics', 'Electronics'),
        ('custom_high_value', 'Custom/High-value Items'),
        ('general', 'General Items'),
    ]
    
    STATUS_CHOICES = [
        ('active', 'Active'),
        ('completed', 'Completed'),
        ('early_released', 'Early Released'),
        ('disputed', 'Disputed'),
        ('refunded', 'Refunded'),
        ('expired', 'Expired'),
    ]
    
    # Core fields - removed duplicate primary key
    transaction = models.OneToOneField(Transaction, on_delete=models.CASCADE, related_name='escrow_period')
    
    # Escrow configuration
    category = models.CharField(max_length=20, choices=CATEGORY_CHOICES)
    hold_period_days = models.IntegerField(validators=[MinValueValidator(1)])
    
    # Timing
    start_date = models.DateTimeField()
    end_date = models.DateTimeField()
    actual_release_date = models.DateTimeField(null=True, blank=True)
    
    # Early release
    early_release_requested = models.BooleanField(default=False)
    early_release_approved = models.BooleanField(default=False)
    early_release_requested_at = models.DateTimeField(null=True, blank=True)
    early_release_approved_at = models.DateTimeField(null=True, blank=True)
    early_release_requested_by = models.ForeignKey(
        'auth.User', 
        on_delete=models.SET_NULL, 
        null=True, 
        blank=True,
        related_name='requested_early_releases'
    )
    early_release_approved_by = models.ForeignKey(
        'auth.User', 
        on_delete=models.SET_NULL, 
        null=True, 
        blank=True,
        related_name='approved_early_releases'
    )
    
    # Status
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='active')
    
    # Additional information
    release_reason = models.TextField(blank=True, null=True, help_text="Reason for early release or completion")
    dispute_reason = models.TextField(blank=True, null=True, help_text="Reason for dispute if applicable")
    notes = models.TextField(blank=True, null=True)
    
    class Meta:
        db_table = 'escrow_periods'
        verbose_name = 'Escrow Period'
        verbose_name_plural = 'Escrow Periods'
        indexes = [
            models.Index(fields=['transaction']),
            models.Index(fields=['status']),
            models.Index(fields=['end_date']),
            models.Index(fields=['early_release_requested']),
        ]
        
    def __str__(self):
        return f"Escrow {self.id} for Transaction {self.transaction.id} ({self.status})"
        
    def save(self, *args, **kwargs):
        if not self.start_date:
            self.start_date = timezone.now()
        if not self.end_date and self.hold_period_days:
            self.end_date = self.start_date + timezone.timedelta(days=self.hold_period_days)
        if not self.category:
            self.category = 'general'  # Default category
        if not self.hold_period_days:
            from django.conf import settings
            self.hold_period_days = settings.ESCROW_PERIODS.get('default', 14)
        super().save(*args, **kwargs)
        
    def is_expired(self):
        """Check if escrow period has expired."""
        return timezone.now() > self.end_date
        
    def days_remaining(self):
        """Calculate days remaining in escrow period."""
        if self.is_expired():
            return 0
        return (self.end_date - timezone.now()).days
        
    def can_request_early_release(self, user):
        """Check if user can request early release."""
        if self.status != 'active':
            return False
        if self.early_release_requested:
            return False
        # For now, allow any authenticated user to request early release
        return user.is_authenticated
        
    def request_early_release(self, requested_by, reason=None):
        """Request early release of escrow."""
        if not self.can_request_early_release(requested_by):
            return False
            
        self.early_release_requested = True
        self.early_release_requested_by = requested_by
        self.early_release_requested_at = timezone.now()
        self.release_reason = reason
        self.save()
        
        # Create early release request record
        EscrowEarlyReleaseRequest.objects.create(
            escrow_period=self,
            requested_by=requested_by,
            reason=reason
        )
        
        return True
        
    def approve_early_release(self, approved_by, reason=None):
        """Approve early release request."""
        if not self.early_release_requested or self.early_release_approved:
            return False
            
        self.early_release_approved = True
        self.early_release_approved_by = approved_by
        self.early_release_approved_at = timezone.now()
        self.actual_release_date = timezone.now()
        self.status = 'early_released'
        
        if reason:
            self.notes = f"{self.notes or ''}\nApproval reason: {reason}"
            
        self.save()
        
        # Update the transaction status
        self.transaction.status = 'completed'
        self.transaction.save()
        
        return True
        
    def complete_escrow(self, reason=None):
        """Complete escrow period normally."""
        if self.status != 'active':
            return False
            
        self.status = 'completed'
        self.actual_release_date = timezone.now()
        self.release_reason = reason or 'Escrow period completed successfully'
        self.save()
        
        # Update the transaction status
        self.transaction.status = 'completed'
        self.transaction.save()
        
        return True
        
    def dispute_escrow(self, reason):
        """Mark escrow as disputed."""
        self.status = 'disputed'
        self.dispute_reason = reason
        self.save()
        
        # Update the transaction status
        self.transaction.status = 'disputed'
        self.transaction.save()
        
        return True


class EscrowEarlyReleaseRequest(BaseModel):
    """Model to track early release requests for escrow periods."""
    
    STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('approved', 'Approved'),
        ('rejected', 'Rejected'),
        ('cancelled', 'Cancelled'),
    ]
    
    escrow_period = models.ForeignKey(EscrowPeriod, on_delete=models.CASCADE, related_name='early_release_requests')
    requested_by = models.ForeignKey('auth.User', on_delete=models.CASCADE, related_name='escrow_release_requests')
    
    # Request details
    reason = models.TextField()
    supporting_documents = models.JSONField(default=list, help_text="List of supporting document URLs")
    
    # Status and processing
    status = models.CharField(max_length=10, choices=STATUS_CHOICES, default='pending')
    processed_by = models.ForeignKey(
        'auth.User', 
        on_delete=models.SET_NULL, 
        null=True, 
        blank=True,
        related_name='processed_release_requests'
    )
    processed_at = models.DateTimeField(null=True, blank=True)
    processing_notes = models.TextField(blank=True, null=True)
    
    # Communication
    buyer_approved = models.BooleanField(null=True, blank=True, help_text="Buyer approval for early release")
    seller_approved = models.BooleanField(null=True, blank=True, help_text="Seller approval for early release")
    admin_review_required = models.BooleanField(default=False)
    
    class Meta:
        db_table = 'escrow_early_release_requests'
        verbose_name = 'Escrow Early Release Request'
        verbose_name_plural = 'Escrow Early Release Requests'
        indexes = [
            models.Index(fields=['escrow_period']),
            models.Index(fields=['requested_by']),
            models.Index(fields=['status']),
            models.Index(fields=['created_at']),
        ]
        
    def __str__(self):
        return f"Early Release Request for {self.escrow_period.transaction.transaction_id} by {self.requested_by.username}"
        
    def can_approve(self, user):
        """Check if user can approve this early release request."""
        if self.status != 'pending':
            return False
            
        transaction = self.escrow_period.transaction
        
        # Admin can always approve
        if user.is_staff:
            return True
            
        # If requested by buyer, seller must approve
        if self.requested_by == transaction.buyer:
            return user == transaction.seller
            
        # If requested by seller, buyer must approve
        if self.requested_by == transaction.seller:
            return user == transaction.buyer
            
        return False
        
    def approve(self, approved_by, notes=None):
        """Approve the early release request."""
        if not self.can_approve(approved_by):
            return False
            
        self.status = 'approved'
        self.processed_by = approved_by
        self.processed_at = timezone.now()
        self.processing_notes = notes
        
        # Mark appropriate approval flags
        transaction = self.escrow_period.transaction
        if approved_by == transaction.buyer:
            self.buyer_approved = True
        elif approved_by == transaction.seller:
            self.seller_approved = True
            
        self.save()
        
        # Approve the escrow early release
        self.escrow_period.approve_early_release(approved_by, notes)
        
        return True
        
    def reject(self, rejected_by, reason):
        """Reject the early release request."""
        if self.status != 'pending':
            return False
            
        self.status = 'rejected'
        self.processed_by = rejected_by
        self.processed_at = timezone.now()
        self.processing_notes = reason
        self.save()
        
        return True


class EscrowAccount(models.Model):
    """
    Simplified model for escrow account management to match API views
    """
    STATUS_CHOICES = [
        ('active', 'Active'),
        ('released', 'Released'),
        ('disputed', 'Disputed'),
        ('refunded', 'Refunded'),
    ]
    
    CATEGORY_CHOICES = [
        ('vehicle_parts', 'Vehicle Parts'),
        ('electronics', 'Electronics'),
        ('custom_high_value', 'Custom/High-value Items'),
        ('default', 'Default'),
    ]
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    transaction = models.OneToOneField('transactions.Transaction', on_delete=models.CASCADE)
    amount = models.DecimalField(max_digits=12, decimal_places=2)
    category = models.CharField(max_length=20, choices=CATEGORY_CHOICES, default='default')
    start_date = models.DateField()
    end_date = models.DateField()
    early_release_requested = models.BooleanField(default=False)
    early_release_approved = models.BooleanField(default=False)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='active')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['status']),
            models.Index(fields=['category']),
            models.Index(fields=['end_date']),
        ]
    
    def __str__(self):
        return f"Escrow {self.id} - {self.amount} ({self.status})"
    
    @property
    def days_remaining(self):
        """Calculate days remaining in escrow period"""
        if self.end_date and self.end_date > timezone.now().date():
            return (self.end_date - timezone.now().date()).days
        return 0
    
    @property
    def is_expired(self):
        """Check if escrow period has expired"""
        if self.end_date:
            return self.end_date < timezone.now().date()
        return False
