from django.db import models
from django.contrib.auth.models import User
from django.core.validators import MinValueValidator, MaxValueValidator


class Rating(models.Model):
    """Model for quick ratings without full reviews"""
    
    # User who gave the rating
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='ratings')
    
    # Product/Service identifiers
    product_id = models.CharField(max_length=100, help_text="External product ID")
    seller_id = models.CharField(max_length=100, help_text="External seller ID")
    
    # Rating categories
    overall_rating = models.IntegerField(
        validators=[MinValueValidator(1), MaxValueValidator(5)],
        help_text="Overall rating from 1 to 5 stars"
    )
    
    quality_rating = models.IntegerField(
        validators=[MinValueValidator(1), MaxValueValidator(5)],
        help_text="Quality rating from 1 to 5 stars",
        null=True, blank=True
    )
    
    service_rating = models.IntegerField(
        validators=[MinValueValidator(1), MaxValueValidator(5)],
        help_text="Service rating from 1 to 5 stars",
        null=True, blank=True
    )
    
    delivery_rating = models.IntegerField(
        validators=[MinValueValidator(1), MaxValueValidator(5)],
        help_text="Delivery rating from 1 to 5 stars",
        null=True, blank=True
    )
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['-created_at']
        unique_together = ['user', 'product_id']  # One rating per user per product
    
    def __str__(self):
        return f"Rating by {self.user.username} - {self.overall_rating}★ for product {self.product_id}"


class AverageRating(models.Model):
    """Model to store calculated average ratings for products/sellers"""
    
    # Target identifiers
    product_id = models.CharField(max_length=100, unique=True, help_text="External product ID")
    seller_id = models.CharField(max_length=100, help_text="External seller ID")
    
    # Calculated averages
    overall_avg = models.DecimalField(max_digits=3, decimal_places=2, default=0.00)
    quality_avg = models.DecimalField(max_digits=3, decimal_places=2, default=0.00, null=True, blank=True)
    service_avg = models.DecimalField(max_digits=3, decimal_places=2, default=0.00, null=True, blank=True)
    delivery_avg = models.DecimalField(max_digits=3, decimal_places=2, default=0.00, null=True, blank=True)
    
    # Counts
    total_ratings = models.IntegerField(default=0)
    total_reviews = models.IntegerField(default=0)
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['-overall_avg']
    
    def __str__(self):
        return f"Average Rating for {self.product_id} - {self.overall_avg}★ ({self.total_ratings} ratings)"
