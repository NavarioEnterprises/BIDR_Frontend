import uuid
from django.db import models
from django.utils import timezone
from decimal import Decimal


class Payment(models.Model):
    """
    Model to store payment records
    """
    STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('processing', 'Processing'),
        ('completed', 'Completed'),
        ('failed', 'Failed'),
        ('cancelled', 'Cancelled'),
        ('refunded', 'Refunded'),
    ]
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user_id = models.UUIDField(help_text="User ID from external service")
    payment_gateway = models.ForeignKey(
        'core.PaymentGateway', 
        on_delete=models.CASCADE,
        help_text="Payment gateway used"
    )
    reference = models.CharField(max_length=100, unique=True, help_text="Unique payment reference")
    amount = models.DecimalField(max_digits=12, decimal_places=2)
    currency = models.CharField(max_length=3, default='NGN')
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    payment_method = models.CharField(max_length=50, default='card')
    gateway_response = models.JSONField(null=True, blank=True, help_text="Response from payment gateway")
    metadata = models.JSONField(default=dict, blank=True, help_text="Additional payment metadata")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['user_id']),
            models.Index(fields=['reference']),
            models.Index(fields=['status']),
            models.Index(fields=['created_at']),
        ]
    
    def __str__(self):
        return f"Payment {self.reference} - {self.amount} {self.currency}"


class PaymentWebhook(models.Model):
    """
    Model to store payment webhook events
    """
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    payment = models.ForeignKey(Payment, on_delete=models.CASCADE, null=True, blank=True)
    event_type = models.CharField(max_length=50)
    payload = models.JSONField(help_text="Webhook payload")
    processed = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        ordering = ['-created_at']
    
    def __str__(self):
        return f"Webhook {self.event_type} - {self.created_at}"


class RefundRequest(models.Model):
    """
    Model to handle refund requests
    """
    STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('approved', 'Approved'),
        ('rejected', 'Rejected'),
        ('processed', 'Processed'),
    ]
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    payment = models.ForeignKey(Payment, on_delete=models.CASCADE)
    amount = models.DecimalField(max_digits=12, decimal_places=2, help_text="Refund amount")
    reason = models.TextField(help_text="Reason for refund")
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    processed_at = models.DateTimeField(null=True, blank=True)
    gateway_response = models.JSONField(null=True, blank=True, help_text="Gateway refund response")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['-created_at']
    
    def __str__(self):
        return f"Refund Request {self.payment.reference} - {self.amount}"
