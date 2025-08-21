from rest_framework import serializers
from .models import Transaction, TransactionPIN, TransactionLog
from django.utils import timezone
from datetime import timedelta
from django.conf import settings
import random
import string


class TransactionSerializer(serializers.ModelSerializer):
    """
    Serializer for Transaction model
    """
    amount_display = serializers.SerializerMethodField()
    
    class Meta:
        model = Transaction
        fields = [
            'id', 'buyer_id', 'seller_id', 'payment', 'amount', 'amount_display',
            'transaction_type', 'status', 'description', 'metadata',
            'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']
    
    def get_amount_display(self, obj):
        return f"NGN {obj.amount:,.2f}"
    
    def validate(self, data):
        if data.get('buyer_id') == data.get('seller_id'):
            raise serializers.ValidationError("Buyer and seller cannot be the same user")
        return data


class TransactionCreateSerializer(serializers.Serializer):
    """
    Serializer for creating new transactions
    """
    buyer_id = serializers.UUIDField()
    seller_id = serializers.UUIDField()
    amount = serializers.DecimalField(max_digits=12, decimal_places=2)
    transaction_type = serializers.ChoiceField(choices=['escrow', 'direct'], default='escrow')
    description = serializers.CharField(max_length=500, required=False)
    metadata = serializers.JSONField(required=False)
    
    def validate(self, data):
        if data.get('buyer_id') == data.get('seller_id'):
            raise serializers.ValidationError("Buyer and seller cannot be the same user")
        
        if data.get('amount') <= 0:
            raise serializers.ValidationError("Amount must be greater than zero")
        
        return data


class TransactionPINSerializer(serializers.ModelSerializer):
    """
    Serializer for TransactionPIN model
    """
    is_expired = serializers.SerializerMethodField()
    
    class Meta:
        model = TransactionPIN
        fields = [
            'id', 'transaction', 'pin_code', 'attempts', 'is_used',
            'is_expired', 'expires_at', 'created_at'
        ]
        read_only_fields = ['id', 'pin_code', 'attempts', 'expires_at', 'created_at']
    
    def get_is_expired(self, obj):
        return obj.expires_at < timezone.now()


class PINGenerationSerializer(serializers.Serializer):
    """
    Serializer for PIN generation requests
    """
    transaction_id = serializers.UUIDField()
    delivery_method = serializers.ChoiceField(choices=['sms', 'email'], default='sms')
    
    def validate_transaction_id(self, value):
        try:
            transaction = Transaction.objects.get(id=value)
            if transaction.status != 'pending':
                raise serializers.ValidationError("PIN can only be generated for pending transactions")
        except Transaction.DoesNotExist:
            raise serializers.ValidationError("Transaction not found")
        return value


class PINVerificationSerializer(serializers.Serializer):
    """
    Serializer for PIN verification requests
    """
    transaction_id = serializers.UUIDField()
    pin_code = serializers.CharField(max_length=6, min_length=6)
    
    def validate_pin_code(self, value):
        if not value.isdigit():
            raise serializers.ValidationError("PIN must contain only digits")
        return value


class TransactionLogSerializer(serializers.ModelSerializer):
    """
    Serializer for TransactionLog model
    """
    
    class Meta:
        model = TransactionLog
        fields = [
            'id', 'transaction', 'action', 'status', 'details',
            'user_id', 'ip_address', 'created_at'
        ]
        read_only_fields = ['id', 'created_at']


class TransactionStatusUpdateSerializer(serializers.Serializer):
    """
    Serializer for transaction status updates
    """
    status = serializers.ChoiceField(choices=[
        'pending', 'processing', 'completed', 'failed', 'cancelled'
    ])
    reason = serializers.CharField(max_length=500, required=False)
    
    def validate_status(self, value):
        # Add business logic validation here
        return value
