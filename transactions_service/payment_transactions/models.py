"""
Payment transaction models for the BIDR Transaction Service.

This module handles payment transactions and integrates with various payment gateways.
"""

import uuid
from django.db import models
from django.core.validators import MinValueValidator
from decimal import Decimal
import json

from transactions.models import Transaction


class PaymentTransaction(models.Model):
    """
    Payment transactions for processing payments through various gateways.
    """
    PAYMENT_GATEWAY_CHOICES = [
        ('PAYFAST', 'PayFast'),
        ('STRIPE', 'Stripe'),
        ('PAYPAL', 'PayPal'),
    ]
    
    PAYMENT_STATUS_CHOICES = [
        ('PENDING', 'Pending'),
        ('AUTHORIZED', 'Authorized'),
        ('CAPTURED', 'Captured'),
        ('RELEASED', 'Released'),
        ('REFUNDED', 'Refunded'),
    ]
    
    # Primary key
    payment_id = models.UUIDField(
        primary_key=True,
        default=uuid.uuid4,
        editable=False,
        help_text="Payment identifier"
    )
    
    # Related transaction
    transaction_id = models.ForeignKey(
        Transaction,
        on_delete=models.CASCADE,
        related_name='payment_transactions',
        help_text="Reference to Transactions.transaction_id"
    )
    
    # Payment gateway details
    payment_gateway = models.CharField(
        max_length=50,
        choices=PAYMENT_GATEWAY_CHOICES,
        help_text="'PAYFAST', 'STRIPE', 'PAYPAL'"
    )
    
    gateway_transaction_id = models.CharField(
        max_length=255,
        null=True,
        blank=True,
        help_text="Gateway transaction reference"
    )
    
    # Payment details
    amount = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        validators=[MinValueValidator(Decimal('0.01'))],
        help_text="Payment amount"
    )
    
    currency = models.CharField(
        max_length=3,
        help_text="Currency code"
    )
    
    payment_method = models.CharField(
        max_length=50,
        help_text="Payment method used"
    )
    
    gateway_response = models.JSONField(
        null=True,
        blank=True,
        help_text="Complete gateway response"
    )
    
    # Release dates
    escrow_release_date = models.DateTimeField(
        null=True,
        blank=True,
        help_text="Scheduled payment release"
    )
    
    actual_release_date = models.DateTimeField(
        null=True,
        blank=True,
        help_text="Actual payment release"
    )
    
    # Status
    status = models.CharField(
        max_length=20,
        choices=PAYMENT_STATUS_CHOICES,
        default='PENDING',
        help_text="'PENDING', 'AUTHORIZED', 'CAPTURED', 'RELEASED', 'REFUNDED'"
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
            models.Index(fields=['payment_gateway']),
            models.Index(fields=['status']),
            models.Index(fields=['escrow_release_date']),
        ]
    
    def __str__(self):
        return f"Payment {self.payment_id} for Transaction {self.transaction_id}"
    
    def is_pending(self):
        """Check if the payment is pending."""
        return self.status == 'PENDING'
    
    def is_completed(self):
        """Check if the payment has been completed (captured or released)."""
        return self.status in ['CAPTURED', 'RELEASED']
    
    def is_refunded(self):
        """Check if the payment has been refunded."""
        return self.status == 'REFUNDED'
    
    def get_gateway_response_as_dict(self):
        """Get the gateway response as a dictionary."""
        if isinstance(self.gateway_response, str):
            try:
                return json.loads(self.gateway_response)
            except json.JSONDecodeError:
                return {}
        return self.gateway_response or {}


class PaymentGateway:
    """Base class for payment gateway integrations."""
    
    def __init__(self, config=None):
        self.config = config or {}
    
    def process_payment(self, payment_transaction):
        """Process a payment through the gateway."""
        raise NotImplementedError("Subclasses must implement process_payment")
    
    def verify_payment(self, payment_transaction):
        """Verify a payment's status with the gateway."""
        raise NotImplementedError("Subclasses must implement verify_payment")
    
    def refund_payment(self, payment_transaction, amount=None):
        """Refund a payment through the gateway."""
        raise NotImplementedError("Subclasses must implement refund_payment")


class PayFastGateway(PaymentGateway):
    """PayFast payment gateway integration."""
    
    def process_payment(self, payment_transaction):
        """Process a payment through PayFast."""
        # Implementation would include:
        # 1. Preparing payment data for PayFast
        # 2. Making API call to PayFast
        # 3. Handling response and updating payment_transaction
        
        # Placeholder for actual implementation
        payment_transaction.status = 'PENDING'
        payment_transaction.gateway_response = {'status': 'pending', 'message': 'Payment initiated'}
        return payment_transaction
    
    def verify_payment(self, payment_transaction):
        """Verify a payment's status with PayFast."""
        # Implementation would include:
        # 1. Making API call to PayFast to check payment status
        # 2. Updating payment_transaction based on response
        
        # Placeholder for actual implementation
        return {'verified': True, 'status': payment_transaction.status}
    
    def refund_payment(self, payment_transaction, amount=None):
        """Refund a payment through PayFast."""
        # Implementation would include:
        # 1. Preparing refund data for PayFast
        # 2. Making API call to PayFast
        # 3. Handling response and updating payment_transaction
        
        # Placeholder for actual implementation
        refund_amount = amount or payment_transaction.amount
        payment_transaction.status = 'REFUNDED'
        payment_transaction.gateway_response = {
            'status': 'refunded',
            'refund_amount': str(refund_amount),
            'message': 'Payment refunded'
        }
        return payment_transaction


class StripeGateway(PaymentGateway):
    """Stripe payment gateway integration."""
    
    def process_payment(self, payment_transaction):
        """Process a payment through Stripe."""
        # Implementation would include:
        # 1. Preparing payment data for Stripe
        # 2. Making API call to Stripe
        # 3. Handling response and updating payment_transaction
        
        # Placeholder for actual implementation
        payment_transaction.status = 'PENDING'
        payment_transaction.gateway_response = {'status': 'pending', 'message': 'Payment initiated'}
        return payment_transaction
    
    def verify_payment(self, payment_transaction):
        """Verify a payment's status with Stripe."""
        # Implementation would include:
        # 1. Making API call to Stripe to check payment status
        # 2. Updating payment_transaction based on response
        
        # Placeholder for actual implementation
        return {'verified': True, 'status': payment_transaction.status}
    
    def refund_payment(self, payment_transaction, amount=None):
        """Refund a payment through Stripe."""
        # Implementation would include:
        # 1. Preparing refund data for Stripe
        # 2. Making API call to Stripe
        # 3. Handling response and updating payment_transaction
        
        # Placeholder for actual implementation
        refund_amount = amount or payment_transaction.amount
        payment_transaction.status = 'REFUNDED'
        payment_transaction.gateway_response = {
            'status': 'refunded',
            'refund_amount': str(refund_amount),
            'message': 'Payment refunded'
        }
        return payment_transaction


class PayPalGateway(PaymentGateway):
    """PayPal payment gateway integration."""
    
    def process_payment(self, payment_transaction):
        """Process a payment through PayPal."""
        # Implementation would include:
        # 1. Preparing payment data for PayPal
        # 2. Making API call to PayPal
        # 3. Handling response and updating payment_transaction
        
        # Placeholder for actual implementation
        payment_transaction.status = 'PENDING'
        payment_transaction.gateway_response = {'status': 'pending', 'message': 'Payment initiated'}
        return payment_transaction
    
    def verify_payment(self, payment_transaction):
        """Verify a payment's status with PayPal."""
        # Implementation would include:
        # 1. Making API call to PayPal to check payment status
        # 2. Updating payment_transaction based on response
        
        # Placeholder for actual implementation
        return {'verified': True, 'status': payment_transaction.status}
    
    def refund_payment(self, payment_transaction, amount=None):
        """Refund a payment through PayPal."""
        # Implementation would include:
        # 1. Preparing refund data for PayPal
        # 2. Making API call to PayPal
        # 3. Handling response and updating payment_transaction
        
        # Placeholder for actual implementation
        refund_amount = amount or payment_transaction.amount
        payment_transaction.status = 'REFUNDED'
        payment_transaction.gateway_response = {
            'status': 'refunded',
            'refund_amount': str(refund_amount),
            'message': 'Payment refunded'
        }
        return payment_transaction


def get_payment_gateway(gateway_name):
    """
    Factory function to get the appropriate payment gateway instance.
    
    Args:
        gateway_name (str): The name of the gateway ('PAYFAST', 'STRIPE', 'PAYPAL')
        
    Returns:
        PaymentGateway: An instance of the appropriate payment gateway
    """
    gateways = {
        'PAYFAST': PayFastGateway,
        'STRIPE': StripeGateway,
        'PAYPAL': PayPalGateway,
    }
    
    gateway_class = gateways.get(gateway_name.upper())
    if not gateway_class:
        raise ValueError(f"Unsupported payment gateway: {gateway_name}")
    
    return gateway_class()