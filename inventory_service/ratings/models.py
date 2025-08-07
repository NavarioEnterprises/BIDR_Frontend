"""
Rating models for the BIDR Inventory Service.

This module handles customer ratings and feedback for products and transactions.
"""

from django.db import models
from django.contrib.auth.models import User
from django.core.validators import MinValueValidator, MaxValueValidator
from django.utils import timezone
from core.models import ComprehensiveBaseModel, StatusChoices
from products.models import Product
from transactions.models import Transaction


class ProductRating(ComprehensiveBaseModel):
    """
    Customer ratings for products.
    """
    product = models.ForeignKey(
        Product,
        on_delete=models.CASCADE,
        related_name='ratings'
    )
    rater = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='product_ratings'
    )
    rating = models.IntegerField(
        validators=[MinValueValidator(1), MaxValueValidator(5)]
    )
    comment = models.TextField(blank=True)
    status = models.CharField(
        max_length=20,
        choices=StatusChoices.choices,
        default=StatusChoices.PENDING
    )
    
    class Meta:
        unique_together = ['product', 'rater']
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['product', 'rating']),
            models.Index(fields=['rater']),
        ]
    
    def __str__(self):
        return f"{self.product.name} - {self.rating}★ by {self.rater.username}"


class TransactionRating(ComprehensiveBaseModel):
    """
    Ratings and feedback for transactions.
    """
    transaction = models.OneToOneField(
        Transaction,
        on_delete=models.CASCADE,
        related_name='rating'
    )
    rater = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='transaction_ratings'
    )
    rating = models.IntegerField(
        validators=[MinValueValidator(1), MaxValueValidator(5)]
    )
    comment = models.TextField(blank=True)
    status = models.CharField(
        max_length=20,
        choices=StatusChoices.choices,
        default=StatusChoices.APPROVED
    )
    
    class Meta:
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['transaction', 'rating']),
            models.Index(fields=['rater']),
        ]
    
    def __str__(self):
        return f"Transaction {self.transaction.reference_number} - {self.rating}★ by {self.rater.username}"


class ReviewHelpfulVote(models.Model):
    """
    Track helpful votes on product and transaction reviews.
    """
    review = models.ForeignKey(
        ProductRating,
        on_delete=models.CASCADE,
        related_name='helpful_votes'
    )
    voter = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='helpful_voted_reviews'
    )
    is_helpful = models.BooleanField()
    
    class Meta:
        unique_together = ['review', 'voter']
    
    def __str__(self):
        helpfulness = "Helpful" if self.is_helpful else "Not helpful"
        return f"{self.review.product.name} review by {self.review.rater.username}: {helpfulness}"


class TransactionIssue(ComprehensiveBaseModel):
    """
    Report issues related to transactions.
    """
    transaction = models.ForeignKey(
        Transaction,
        on_delete=models.CASCADE,
        related_name='issues'
    )
    reporter = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='reported_issues'
    )
    summary = models.CharField(max_length=200)
    description = models.TextField()
    status = models.CharField(
        max_length=20,
        choices=StatusChoices.choices,
        default=StatusChoices.PENDING
    )
    resolution = models.TextField(blank=True)
    resolved_at = models.DateTimeField(null=True, blank=True)
    
    class Meta:
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['transaction', 'status']),
            models.Index(fields=['reporter']),
        ]
    
    def __str__(self):
        return f"{self.transaction.reference_number} - {self.summary}" 
    
    def mark_as_resolved(self, resolution_text=None):
        """Mark issue as resolved."""
        self.status = StatusChoices.COMPLETED
        self.resolved_at = timezone.now()
        if resolution_text:
            self.resolution = resolution_text
        self.save()
