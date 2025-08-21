"""
Placeholder models for external service dependencies.
These are simplified local models to avoid cross-service dependencies.
"""

import uuid
from django.db import models
from django.contrib.auth.models import AbstractUser


class AppUser(AbstractUser):
    """Placeholder AppUser model - should sync with actual authentication service"""
    id = models.UUIDField(
        primary_key=True, 
        default=uuid.uuid4, 
        editable=False
    )
    email = models.EmailField(unique=True)
    phone_number = models.CharField(max_length=20, blank=True, null=True)
    role = models.CharField(max_length=20, default='BUYER')
    is_verified = models.BooleanField(default=False)
    
    class Meta:
        app_label = 'transactions'  # Use existing app for simplicity
    
    def __str__(self):
        return self.username or self.email
    
    def get_full_name(self):
        """Return the full name of the user"""
        return f"{self.first_name} {self.last_name}".strip() or self.username


class Quote(models.Model):
    """Placeholder Quote model - should sync with actual quoting service"""
    id = models.UUIDField(
        primary_key=True, 
        default=uuid.uuid4, 
        editable=False
    )
    amount = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    currency = models.CharField(max_length=3, default='USD')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        app_label = 'transactions'  # Use existing app for simplicity
    
    def __str__(self):
        return f"Quote {self.id}"


class Seller(models.Model):
    """Placeholder Seller model - should sync with actual auth service"""
    id = models.UUIDField(
        primary_key=True, 
        default=uuid.uuid4, 
        editable=False
    )
    username = models.CharField(max_length=150, unique=True, default='seller')
    email = models.EmailField(unique=True, default='seller@example.com')
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        app_label = 'transactions'  # Use existing app for simplicity
    
    def __str__(self):
        return self.username


class Buyer(models.Model):
    """Placeholder Buyer model - should sync with actual auth service"""
    id = models.UUIDField(
        primary_key=True, 
        default=uuid.uuid4, 
        editable=False
    )
    username = models.CharField(max_length=150, unique=True, default='buyer')
    email = models.EmailField(unique=True, default='buyer@example.com')
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        app_label = 'transactions'  # Use existing app for simplicity
    
    def __str__(self):
        return self.username
