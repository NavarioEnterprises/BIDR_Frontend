from django.db import models
from django.contrib.auth.models import User
from django.core.validators import MinValueValidator, MaxValueValidator


class UserProfile(models.Model):
    """Extended user profile for resolution service"""
    user = models.OneToOneField(User, on_delete=models.CASCADE)
    phone_number = models.CharField(max_length=20, blank=True, null=True)
    is_verified = models.BooleanField(default=False)
    reputation_score = models.DecimalField(
        max_digits=3, 
        decimal_places=2, 
        default=5.00,
        validators=[MinValueValidator(0.00), MaxValueValidator(5.00)]
    )
    total_transactions = models.PositiveIntegerField(default=0)
    successful_transactions = models.PositiveIntegerField(default=0)
    dispute_count = models.PositiveIntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    def __str__(self):
        return f"{self.user.username} - Profile"
    
    @property
    def success_rate(self):
        if self.total_transactions == 0:
            return 0
        return (self.successful_transactions / self.total_transactions) * 100


class SystemConfiguration(models.Model):
    """System-wide configuration settings"""
    key = models.CharField(max_length=100, unique=True)
    value = models.TextField()
    description = models.TextField(blank=True)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    def __str__(self):
        return f"{self.key}: {self.value[:50]}"


class ServiceHealth(models.Model):
    """Track service health and status"""
    service_name = models.CharField(max_length=100)
    status = models.CharField(max_length=20, choices=[
        ('healthy', 'Healthy'),
        ('warning', 'Warning'),
        ('critical', 'Critical'),
        ('down', 'Down')
    ], default='healthy')
    response_time = models.FloatField(null=True, blank=True)  # in milliseconds
    last_check = models.DateTimeField(auto_now=True)
    error_message = models.TextField(blank=True, null=True)
    
    class Meta:
        unique_together = ['service_name']
    
    def __str__(self):
        return f"{self.service_name}: {self.status}"


class APIKey(models.Model):
    """API keys for service integration"""
    name = models.CharField(max_length=100)
    key = models.CharField(max_length=255, unique=True)
    is_active = models.BooleanField(default=True)
    permissions = models.JSONField(default=list)  # List of allowed endpoints/actions
    rate_limit = models.PositiveIntegerField(default=1000)  # Requests per hour
    created_by = models.ForeignKey(User, on_delete=models.CASCADE)
    created_at = models.DateTimeField(auto_now_add=True)
    last_used = models.DateTimeField(null=True, blank=True)
    
    def __str__(self):
        return f"{self.name} - {'Active' if self.is_active else 'Inactive'}"


class TransactionReference(models.Model):
    """References to transactions from other services"""
    transaction_id = models.CharField(max_length=100, unique=True)
    service_name = models.CharField(max_length=50)  # e.g., 'payment_service'
    buyer_id = models.CharField(max_length=100)
    seller_id = models.CharField(max_length=100)
    amount = models.DecimalField(max_digits=12, decimal_places=2)
    currency = models.CharField(max_length=3, default='USD')
    status = models.CharField(max_length=20, choices=[
        ('pending', 'Pending'),
        ('completed', 'Completed'),
        ('cancelled', 'Cancelled'),
        ('disputed', 'Disputed')
    ])
    completed_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    def __str__(self):
        return f"Transaction {self.transaction_id} - {self.status}"
