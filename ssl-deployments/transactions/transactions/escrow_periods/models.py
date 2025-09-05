"""
Escrow period models for the BIDR Transaction Service.

This module handles escrow periods for transactions, defining hold periods
for payments based on product categories.
"""

import uuid
from django.db import models
from django.utils import timezone

from transactions.models import Transaction
# from product_management_service.categories.models import CategorySpecification  # External service
# Using simplified category choices for now
class CategorySpecification:
    CATEGORY_TYPES = [
        ('ELECTRONICS', 'Electronics'),
        ('VEHICLE_SPARES', 'Vehicle Spares'),
        ('TYRES_RIMS', 'Tyres & Rims'),
        ('OTHER', 'Other'),
    ]


class EscrowPeriod(models.Model):
    """
    Escrow periods for transaction payments with category-specific hold periods.
    """
    # Use the category types from CategorySpecification
    CATEGORY_CHOICES = CategorySpecification.CATEGORY_TYPES
    
    STATUS_CHOICES = [
        ('ACTIVE', 'Active'),
        ('RELEASED', 'Released'),
        ('DISPUTED', 'Disputed'),
    ]
    
    # Primary key
    escrow_id = models.UUIDField(
        primary_key=True,
        default=uuid.uuid4,
        editable=False,
        help_text="Escrow period identifier"
    )
    
    # Related transaction
    transaction_id = models.ForeignKey(
        Transaction,
        on_delete=models.CASCADE,
        related_name='escrow_periods',
        help_text="Reference to Transactions.transaction_id"
    )
    
    # Category and hold period
    category = models.CharField(
        max_length=20,
        choices=CATEGORY_CHOICES,
        help_text="Product category determining hold period"
    )
    
    hold_period_days = models.IntegerField(
        help_text="Days to hold payment"
    )
    
    # Period dates
    start_date = models.DateTimeField(
        help_text="Escrow period start"
    )
    
    end_date = models.DateTimeField(
        help_text="Scheduled release date"
    )
    
    # Early release flags
    early_release_requested = models.BooleanField(
        default=False,
        help_text="Early release flag"
    )
    
    early_release_approved = models.BooleanField(
        default=False,
        help_text="Admin approval for early release"
    )
    
    # Status
    status = models.CharField(
        max_length=20,
        choices=STATUS_CHOICES,
        default='ACTIVE',
        help_text="Escrow period status"
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
            models.Index(fields=['transaction_id']),
            models.Index(fields=['category']),
            models.Index(fields=['status']),
            models.Index(fields=['end_date']),
        ]
    
    def __str__(self):
        return f"Escrow {self.escrow_id} for Transaction {self.transaction_id}"
    
    def is_release_due(self):
        """Check if the escrow period has ended and payment should be released."""
        return timezone.now() >= self.end_date and self.status == 'ACTIVE'
    
    def calculate_end_date(self):
        """Calculate the end date based on start date and hold period."""
        from datetime import timedelta
        return self.start_date + timedelta(days=self.hold_period_days)
        
    @staticmethod
    def get_category_choices():
        """
        Get the category choices from the product management service.
        
        Returns:
            list: A list of tuples containing category type and display name.
        """
        return CategorySpecification.CATEGORY_TYPES
        
    @staticmethod
    def get_hold_period_for_category(category_type):
        """
        Get the recommended hold period in days for a specific category.
        
        Args:
            category_type (str): The category type code (e.g., 'ELECTRONICS')
            
        Returns:
            int: The recommended hold period in days for the category
        """
        # Default hold periods by category (in days)
        hold_periods = {
            'ELECTRONICS': 14,  # Electronics have a 14-day hold period
            'VEHICLE_SPARES': 21,  # Vehicle parts have a 21-day hold period
            'TYRES_RIMS': 21,  # Tyres & Rims have a 21-day hold period
            # Add more categories as needed
        }
        
        # Return the hold period for the category, or a default of 7 days
        return hold_periods.get(category_type, 7)
        
    def set_hold_period_from_category(self):
        """
        Set the hold period based on the selected category.
        This is useful when creating a new escrow period.
        """
        if self.category:
            self.hold_period_days = self.get_hold_period_for_category(self.category)
            return True
        return False
