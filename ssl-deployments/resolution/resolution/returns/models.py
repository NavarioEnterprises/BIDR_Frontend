from django.db import models
from django.contrib.auth.models import User
from django.utils import timezone
from datetime import timedelta
from core.models import TransactionReference


class ReturnRequest(models.Model):
    """Return requests from buyers"""
    transaction = models.ForeignKey(TransactionReference, on_delete=models.CASCADE)
    buyer = models.ForeignKey(User, on_delete=models.CASCADE, related_name='return_requests_made')
    seller = models.ForeignKey(User, on_delete=models.CASCADE, related_name='return_requests_received')
    
    # Return details
    reason = models.CharField(max_length=50, choices=[
        ('defective', 'Defective Product'),
        ('not_as_described', 'Not as Described'),
        ('wrong_item', 'Wrong Item Received'),
        ('damaged_shipping', 'Damaged During Shipping'),
        ('quality_issues', 'Quality Issues'),
        ('size_fit', 'Size/Fit Issues'),
        ('changed_mind', 'Changed Mind'),
        ('other', 'Other')
    ])
    description = models.TextField()
    requested_outcome = models.CharField(max_length=20, choices=[
        ('full_refund', 'Full Refund'),
        ('partial_refund', 'Partial Refund'),
        ('exchange', 'Exchange'),
        ('store_credit', 'Store Credit')
    ])
    
    # Status tracking
    status = models.CharField(max_length=20, choices=[
        ('pending', 'Pending Review'),
        ('approved', 'Approved'),
        ('rejected', 'Rejected'),
        ('in_transit', 'In Transit to Seller'),
        ('received', 'Received by Seller'),
        ('processing', 'Processing'),
        ('completed', 'Completed'),
        ('disputed', 'Disputed')
    ], default='pending')
    
    # Important dates
    return_deadline = models.DateTimeField()
    created_at = models.DateTimeField(auto_now_add=True)
    approved_at = models.DateTimeField(null=True, blank=True)
    shipped_at = models.DateTimeField(null=True, blank=True)
    received_at = models.DateTimeField(null=True, blank=True)
    completed_at = models.DateTimeField(null=True, blank=True)
    
    # Additional info
    admin_notes = models.TextField(blank=True)
    refund_amount = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)
    
    def __str__(self):
        return f"Return Request {self.id} - {self.transaction.transaction_id}"
    
    @property
    def is_within_deadline(self):
        return timezone.now() <= self.return_deadline
    
    def save(self, *args, **kwargs):
        if not self.return_deadline:
            # Default to 30 days from transaction completion
            if self.transaction.completed_at:
                self.return_deadline = self.transaction.completed_at + timedelta(days=30)
            else:
                self.return_deadline = timezone.now() + timedelta(days=30)
        super().save(*args, **kwargs)


class ReturnPhoto(models.Model):
    """Photos documenting return condition"""
    return_request = models.ForeignKey(ReturnRequest, on_delete=models.CASCADE, related_name='photos')
    image = models.ImageField(upload_to='returns/photos/')
    caption = models.CharField(max_length=200, blank=True)
    photo_type = models.CharField(max_length=20, choices=[
        ('initial', 'Initial Condition'),
        ('defect', 'Defect Documentation'),
        ('packaging', 'Packaging'),
        ('shipping', 'Shipping Documentation'),
        ('other', 'Other')
    ], default='initial')
    uploaded_by = models.ForeignKey(User, on_delete=models.CASCADE)
    created_at = models.DateTimeField(auto_now_add=True)
    
    def __str__(self):
        return f"Photo for return {self.return_request.id}"


class ReturnShipping(models.Model):
    """Shipping information for returns"""
    return_request = models.OneToOneField(ReturnRequest, on_delete=models.CASCADE, related_name='shipping')
    
    # Shipping details
    carrier = models.CharField(max_length=50, blank=True)
    tracking_number = models.CharField(max_length=100, blank=True)
    shipping_label_url = models.URLField(blank=True)
    
    # Addresses
    return_address = models.TextField()  # Seller's return address
    pickup_address = models.TextField(blank=True)  # Buyer's pickup address
    
    # Costs
    shipping_cost = models.DecimalField(max_digits=8, decimal_places=2, null=True, blank=True)
    paid_by = models.CharField(max_length=10, choices=[
        ('buyer', 'Buyer'),
        ('seller', 'Seller'),
        ('platform', 'Platform')
    ], default='buyer')
    
    # Tracking
    shipped_at = models.DateTimeField(null=True, blank=True)
    delivered_at = models.DateTimeField(null=True, blank=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    def __str__(self):
        return f"Shipping for return {self.return_request.id}"


class ReturnEvaluation(models.Model):
    """Seller's evaluation of returned item"""
    return_request = models.OneToOneField(ReturnRequest, on_delete=models.CASCADE, related_name='evaluation')
    evaluator = models.ForeignKey(User, on_delete=models.CASCADE)  # Should be the seller
    
    # Evaluation results
    condition_assessment = models.CharField(max_length=20, choices=[
        ('excellent', 'Excellent - Like New'),
        ('good', 'Good - Minor Wear'),
        ('fair', 'Fair - Some Wear'),
        ('poor', 'Poor - Significant Wear'),
        ('damaged', 'Damaged - Not Resellable')
    ])
    
    # Evaluation criteria
    packaging_intact = models.BooleanField(default=True)
    all_items_present = models.BooleanField(default=True)
    no_additional_damage = models.BooleanField(default=True)
    
    # Decision
    is_acceptable = models.BooleanField()  # Whether return is acceptable
    refund_percentage = models.PositiveSmallIntegerField(default=100)  # 0-100
    
    # Notes
    evaluation_notes = models.TextField()
    rejection_reason = models.TextField(blank=True)  # If not acceptable
    
    created_at = models.DateTimeField(auto_now_add=True)
    
    def __str__(self):
        status = "Accepted" if self.is_acceptable else "Rejected"
        return f"Evaluation for return {self.return_request.id} - {status}"


class ReturnStatusHistory(models.Model):
    """Track status changes for returns"""
    return_request = models.ForeignKey(ReturnRequest, on_delete=models.CASCADE, related_name='status_history')
    status = models.CharField(max_length=20)
    changed_by = models.ForeignKey(User, on_delete=models.CASCADE)
    notes = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        ordering = ['-created_at']
        verbose_name_plural = "Return status histories"
    
    def __str__(self):
        return f"Return {self.return_request.id} -> {self.status}"


class ReturnPolicy(models.Model):
    """Return policies for different categories/sellers"""
    name = models.CharField(max_length=100)
    description = models.TextField()
    
    # Policy settings
    return_period_days = models.PositiveIntegerField(default=30)
    restocking_fee_percent = models.DecimalField(max_digits=5, decimal_places=2, default=0.00)
    who_pays_shipping = models.CharField(max_length=10, choices=[
        ('buyer', 'Buyer'),
        ('seller', 'Seller'),
        ('platform', 'Platform')
    ], default='buyer')
    
    # Conditions
    requires_original_packaging = models.BooleanField(default=True)
    requires_tags_attached = models.BooleanField(default=False)
    allows_used_items = models.BooleanField(default=True)
    
    # Applicable categories
    applicable_categories = models.JSONField(default=list)
    
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    def __str__(self):
        return f"{self.name} - {self.return_period_days} days"
