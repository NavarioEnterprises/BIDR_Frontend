from rest_framework import serializers
from .models import Payment, PaymentWebhook, RefundRequest
from decimal import Decimal
from django.utils import timezone


class PaymentSerializer(serializers.ModelSerializer):
    """
    Serializer for Payment model
    """
    amount_display = serializers.SerializerMethodField()
    
    class Meta:
        model = Payment
        fields = [
            'id', 'user_id', 'payment_gateway', 'reference', 'amount', 'amount_display',
            'currency', 'status', 'payment_method', 'gateway_response', 'metadata',
            'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'reference', 'gateway_response', 'created_at', 'updated_at']
    
    def get_amount_display(self, obj):
        return f"{obj.currency} {obj.amount:,.2f}"
    
    def validate_amount(self, value):
        if value <= Decimal('0.00'):
            raise serializers.ValidationError("Amount must be greater than zero")
        if value > Decimal('1000000.00'):
            raise serializers.ValidationError("Amount cannot exceed 1,000,000")
        return value
    
    def validate(self, data):
        # Ensure user_id is provided for new payments
        if not self.instance and not data.get('user_id'):
            raise serializers.ValidationError("User ID is required for new payments")
        return data


class PaymentInitiationSerializer(serializers.Serializer):
    """
    Serializer for payment initiation requests
    """
    user_id = serializers.UUIDField()
    amount = serializers.DecimalField(max_digits=12, decimal_places=2)
    currency = serializers.CharField(max_length=3, default='NGN')
    payment_method = serializers.CharField(max_length=50, default='card')
    callback_url = serializers.URLField(required=False)
    metadata = serializers.JSONField(required=False)
    
    def validate_amount(self, value):
        if value <= Decimal('0.00'):
            raise serializers.ValidationError("Amount must be greater than zero")
        return value


class PaymentWebhookSerializer(serializers.ModelSerializer):
    """
    Serializer for PaymentWebhook model
    """
    
    class Meta:
        model = PaymentWebhook
        fields = [
            'id', 'payment', 'event_type', 'payload', 'processed',
            'created_at'
        ]
        read_only_fields = ['id', 'created_at']


class RefundRequestSerializer(serializers.ModelSerializer):
    """
    Serializer for RefundRequest model
    """
    amount_display = serializers.SerializerMethodField()
    
    class Meta:
        model = RefundRequest
        fields = [
            'id', 'payment', 'amount', 'amount_display', 'reason',
            'status', 'processed_at', 'gateway_response',
            'created_at', 'updated_at'
        ]
        read_only_fields = [
            'id', 'processed_at', 'gateway_response',
            'created_at', 'updated_at'
        ]
    
    def get_amount_display(self, obj):
        return f"{obj.payment.currency} {obj.amount:,.2f}"
    
    def validate(self, data):
        payment = data.get('payment')
        amount = data.get('amount')
        
        if payment and amount:
            if amount > payment.amount:
                raise serializers.ValidationError("Refund amount cannot exceed payment amount")
            
            # Check if payment is refundable
            if payment.status != 'completed':
                raise serializers.ValidationError("Only completed payments can be refunded")
        
        return data
