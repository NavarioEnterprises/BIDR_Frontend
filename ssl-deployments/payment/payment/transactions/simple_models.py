import uuid
from django.db import models
from django.utils import timezone
from datetime import timedelta
from django.conf import settings


class Transaction(models.Model):
    """
    Model to store transaction records
    """
    STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('processing', 'Processing'),
        ('completed', 'Completed'),
        ('failed', 'Failed'),
        ('cancelled', 'Cancelled'),
        ('disputed', 'Disputed'),
        ('refunded', 'Refunded'),
    ]
    
    TYPE_CHOICES = [
        ('escrow', 'Escrow'),
        ('direct', 'Direct'),
    ]
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    buyer_id = models.UUIDField(help_text="Buyer user ID from external service")
    seller_id = models.UUIDField(help_text="Seller user ID from external service")
    payment = models.ForeignKey(
        'payments.Payment', 
        on_delete=models.CASCADE,
        null=True, blank=True,
        help_text="Associated payment record"
    )
    amount = models.DecimalField(max_digits=12, decimal_places=2)
    transaction_type = models.CharField(max_length=20, choices=TYPE_CHOICES, default='escrow')
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    description = models.TextField(blank=True, help_text="Transaction description")
    metadata = models.JSONField(default=dict, blank=True, help_text="Additional transaction metadata")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['buyer_id']),
            models.Index(fields=['seller_id']),
            models.Index(fields=['status']),
            models.Index(fields=['transaction_type']),
            models.Index(fields=['created_at']),
        ]
    
    def __str__(self):
        return f"Transaction {self.id} - {self.amount} ({self.status})"


class TransactionPIN(models.Model):
    """
    Model to store transaction PIN verification codes
    """
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    transaction = models.ForeignKey(Transaction, on_delete=models.CASCADE)
    pin_code = models.CharField(max_length=10, help_text="PIN verification code")
    attempts = models.IntegerField(default=0, help_text="Number of verification attempts")
    is_used = models.BooleanField(default=False, help_text="Whether PIN has been used")
    expires_at = models.DateTimeField(help_text="PIN expiration time")
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        ordering = ['-created_at']
    
    def __str__(self):
        return f"PIN for Transaction {self.transaction.id}"
    
    def is_expired(self):
        """Check if PIN is expired"""
        return timezone.now() > self.expires_at
    
    def is_valid(self):
        """Check if PIN is valid for use"""
        return not self.is_used and not self.is_expired() and self.attempts < settings.MAX_PIN_ATTEMPTS


class TransactionLog(models.Model):
    """
    Model to log transaction activities and changes
    """
    STATUS_CHOICES = [
        ('success', 'Success'),
        ('failed', 'Failed'),
        ('pending', 'Pending'),
    ]
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    transaction = models.ForeignKey(Transaction, on_delete=models.CASCADE)
    action = models.CharField(max_length=50, help_text="Action performed")
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='success')
    details = models.TextField(blank=True, help_text="Additional details about the action")
    user_id = models.UUIDField(null=True, blank=True, help_text="User who performed the action")
    ip_address = models.GenericIPAddressField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        ordering = ['-created_at']
    
    def __str__(self):
        return f"Log: {self.action} for Transaction {self.transaction.id}"
