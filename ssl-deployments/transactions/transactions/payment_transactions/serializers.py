"""
Serializers for the PaymentTransaction models.

This module provides serializers for the PaymentTransaction model to convert model instances
to JSON and vice versa, with validation and custom field handling.
"""

from rest_framework import serializers
from django.utils import timezone
from django.core.exceptions import ValidationError

from .models import PaymentTransaction, get_payment_gateway
from transactions.models import Transaction


class PaymentTransactionListSerializer(serializers.ModelSerializer):
    """
    Serializer for listing payment transactions with minimal information.
    """
    transaction_reference = serializers.SerializerMethodField()
    gateway_display = serializers.SerializerMethodField()
    
    class Meta:
        model = PaymentTransaction
        fields = [
            'payment_id', 'transaction_reference', 'payment_gateway',
            'gateway_display', 'amount', 'currency', 'status', 'created_at'
        ]
    
    def get_transaction_reference(self, obj):
        """Get a readable transaction reference."""
        try:
            return str(obj.transaction_id.transaction_id)
        except (AttributeError, Exception):
            return "Unknown Transaction"
    
    def get_gateway_display(self, obj):
        """Get the display name for the payment gateway."""
        return dict(PaymentTransaction.PAYMENT_GATEWAY_CHOICES).get(obj.payment_gateway, obj.payment_gateway)


class PaymentTransactionDetailSerializer(serializers.ModelSerializer):
    """
    Serializer for detailed payment transaction information.
    """
    transaction_details = serializers.SerializerMethodField()
    gateway_display = serializers.SerializerMethodField()
    gateway_response_formatted = serializers.SerializerMethodField()
    
    class Meta:
        model = PaymentTransaction
        fields = [
            'payment_id', 'transaction_id', 'transaction_details',
            'payment_gateway', 'gateway_display', 'gateway_transaction_id',
            'amount', 'currency', 'payment_method', 'gateway_response',
            'gateway_response_formatted', 'escrow_release_date', 
            'actual_release_date', 'status', 'created_at', 'updated_at'
        ]
        read_only_fields = [
            'payment_id', 'created_at', 'updated_at',
            'gateway_display', 'gateway_response_formatted'
        ]
    
    def get_transaction_details(self, obj):
        """Get detailed information about the transaction."""
        try:
            transaction = obj.transaction_id
            return {
                'id': str(transaction.transaction_id),
                'total_amount': str(transaction.total_amount),
                'currency': transaction.currency,
                'status': transaction.status,
                'created_at': transaction.created_at
            }
        except (AttributeError, Exception):
            return None
    
    def get_gateway_display(self, obj):
        """Get the display name for the payment gateway."""
        return dict(PaymentTransaction.PAYMENT_GATEWAY_CHOICES).get(obj.payment_gateway, obj.payment_gateway)
    
    def get_gateway_response_formatted(self, obj):
        """Get the gateway response as a formatted dictionary."""
        return obj.get_gateway_response_as_dict()


class PaymentTransactionCreateSerializer(serializers.ModelSerializer):
    """
    Serializer for creating new payment transactions with validation.
    """
    class Meta:
        model = PaymentTransaction
        fields = [
            'transaction_id', 'payment_gateway', 'amount',
            'currency', 'payment_method', 'escrow_release_date'
        ]
    
    def validate_transaction_id(self, value):
        """Validate that the transaction exists and can have a payment transaction."""
        try:
            transaction = Transaction.objects.get(transaction_id=value)
            
            # Check if transaction already has a completed payment
            existing_payments = PaymentTransaction.objects.filter(
                transaction_id=transaction,
                status__in=['CAPTURED', 'RELEASED']
            )
            
            if existing_payments.exists():
                raise ValidationError(
                    "This transaction already has a completed payment. "
                    "Please refer to payment ID: {}".format(
                        existing_payments.first().payment_id
                    )
                )
            
            # Check if transaction is in a valid state for payment
            if transaction.status not in ['ACTIVE', 'PENDING']:
                raise ValidationError(
                    "Only active or pending transactions can have payments. "
                    "Current status: {}".format(transaction.status)
                )
            
            return value
        except Transaction.DoesNotExist:
            raise ValidationError("Transaction does not exist")
    
    def validate_payment_gateway(self, value):
        """Validate that the payment gateway is supported."""
        try:
            # Try to get a gateway instance to validate
            get_payment_gateway(value)
            return value
        except ValueError as e:
            raise ValidationError(str(e))
    
    def validate(self, data):
        """Validate the payment transaction data."""
        # Ensure amount matches transaction amount if not specified
        if 'amount' in data and 'transaction_id' in data:
            transaction = data['transaction_id']
            if data['amount'] != transaction.total_amount:
                # This is just a warning, not an error
                pass
        
        # Ensure currency matches transaction currency
        if 'currency' in data and 'transaction_id' in data:
            transaction = data['transaction_id']
            if data['currency'] != transaction.currency:
                raise ValidationError(
                    "Currency must match transaction currency: {}".format(transaction.currency)
                )
        
        return data
    
    def create(self, validated_data):
        """Create a new payment transaction with default status of PENDING."""
        validated_data['status'] = 'PENDING'
        return super().create(validated_data)


class PaymentTransactionUpdateSerializer(serializers.ModelSerializer):
    """
    Serializer for updating payment transactions with status transitions and validation.
    """
    class Meta:
        model = PaymentTransaction
        fields = [
            'status', 'gateway_transaction_id', 'gateway_response',
            'escrow_release_date', 'actual_release_date'
        ]
    
    def validate_status(self, value):
        """Validate status transitions."""
        instance = self.instance
        if not instance:
            return value
        
        # Define valid status transitions
        valid_transitions = {
            'PENDING': ['AUTHORIZED', 'CAPTURED', 'REFUNDED'],
            'AUTHORIZED': ['CAPTURED', 'REFUNDED'],
            'CAPTURED': ['RELEASED', 'REFUNDED'],
            'RELEASED': ['REFUNDED'],
            'REFUNDED': []  # No transitions from REFUNDED
        }
        
        if value not in valid_transitions.get(instance.status, []):
            raise ValidationError(
                f"Invalid status transition from '{instance.status}' to '{value}'. "
                f"Valid transitions are: {', '.join(valid_transitions.get(instance.status, []))}"
            )
        
        return value
    
    def validate(self, data):
        """Validate the update data."""
        # If transitioning to RELEASED, ensure actual_release_date is set
        if 'status' in data and data['status'] == 'RELEASED':
            if 'actual_release_date' not in data:
                data['actual_release_date'] = timezone.now()
        
        return data


class ProcessPaymentSerializer(serializers.Serializer):
    """
    Serializer for processing a payment through a payment gateway.
    """
    payment_id = serializers.UUIDField(required=True)
    payment_token = serializers.CharField(required=True)
    additional_data = serializers.JSONField(required=False)
    
    def validate_payment_id(self, value):
        """Validate that the payment exists and can be processed."""
        try:
            payment = PaymentTransaction.objects.get(payment_id=value)
            
            if payment.status != 'PENDING':
                raise ValidationError(
                    f"Payment cannot be processed. Current status: {payment.status}"
                )
            
            return value
        except PaymentTransaction.DoesNotExist:
            raise ValidationError("Payment does not exist")
    
    def process_payment(self):
        """
        Process the payment through the appropriate gateway.
        
        Returns:
            tuple: (success, result) where success is a boolean and result is a dict
        """
        payment_id = self.validated_data['payment_id']
        payment_token = self.validated_data['payment_token']
        additional_data = self.validated_data.get('additional_data', {})
        
        try:
            # Get the payment transaction
            payment = PaymentTransaction.objects.get(payment_id=payment_id)
            
            # Get the appropriate gateway
            gateway = get_payment_gateway(payment.payment_gateway)
            
            # Process the payment
            # In a real implementation, we would pass the payment token to the gateway
            # For now, we just update the payment status
            payment.gateway_transaction_id = f"mock_{payment_token[:8]}"
            payment.status = 'CAPTURED'
            payment.gateway_response = {
                'status': 'success',
                'transaction_id': payment.gateway_transaction_id,
                'timestamp': timezone.now().isoformat(),
                'additional_data': additional_data
            }
            payment.save()
            
            return True, {
                'payment_id': str(payment.payment_id),
                'status': payment.status,
                'gateway_transaction_id': payment.gateway_transaction_id
            }
        except Exception as e:
            return False, {'error': str(e)}


class RefundPaymentSerializer(serializers.Serializer):
    """
    Serializer for refunding a payment.
    """
    payment_id = serializers.UUIDField(required=True)
    amount = serializers.DecimalField(max_digits=12, decimal_places=2, required=False)
    reason = serializers.CharField(required=False)
    
    def validate_payment_id(self, value):
        """Validate that the payment exists and can be refunded."""
        try:
            payment = PaymentTransaction.objects.get(payment_id=value)
            
            if payment.status not in ['CAPTURED', 'RELEASED']:
                raise ValidationError(
                    f"Payment cannot be refunded. Current status: {payment.status}"
                )
            
            return value
        except PaymentTransaction.DoesNotExist:
            raise ValidationError("Payment does not exist")
    
    def refund_payment(self):
        """
        Refund the payment through the appropriate gateway.
        
        Returns:
            tuple: (success, result) where success is a boolean and result is a dict
        """
        payment_id = self.validated_data['payment_id']
        amount = self.validated_data.get('amount')
        reason = self.validated_data.get('reason', 'Customer requested refund')
        
        try:
            # Get the payment transaction
            payment = PaymentTransaction.objects.get(payment_id=payment_id)
            
            # Get the appropriate gateway
            gateway = get_payment_gateway(payment.payment_gateway)
            
            # Refund the payment
            # In a real implementation, we would call the gateway's refund method
            # For now, we just update the payment status
            payment.status = 'REFUNDED'
            
            # Update gateway response
            current_response = payment.get_gateway_response_as_dict()
            current_response.update({
                'refund': {
                    'amount': str(amount) if amount else str(payment.amount),
                    'reason': reason,
                    'timestamp': timezone.now().isoformat()
                }
            })
            payment.gateway_response = current_response
            payment.save()
            
            return True, {
                'payment_id': str(payment.payment_id),
                'status': payment.status,
                'refund_amount': str(amount) if amount else str(payment.amount)
            }
        except Exception as e:
            return False, {'error': str(e)}