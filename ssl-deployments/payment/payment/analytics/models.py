import uuid
from django.db import models
from django.utils import timezone
from decimal import Decimal


class PaymentAnalytics(models.Model):
    """
    Model to store daily payment analytics data
    """
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    date = models.DateField(unique=True, help_text="Date for analytics data")
    total_transactions = models.IntegerField(default=0)
    successful_transactions = models.IntegerField(default=0)
    failed_transactions = models.IntegerField(default=0)
    total_amount = models.DecimalField(max_digits=15, decimal_places=2, default=Decimal('0.00'))
    average_amount = models.DecimalField(max_digits=12, decimal_places=2, default=Decimal('0.00'))
    currency = models.CharField(max_length=3, default='NGN')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['-date']
        indexes = [
            models.Index(fields=['date']),
            models.Index(fields=['currency']),
        ]
    
    def __str__(self):
        return f"Analytics for {self.date} - {self.total_transactions} transactions"
    
    @property
    def success_rate(self):
        """Calculate success rate as percentage"""
        if self.total_transactions == 0:
            return 0
        return (self.successful_transactions / self.total_transactions) * 100
