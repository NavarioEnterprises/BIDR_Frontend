from rest_framework import serializers
from .models import EscrowAccount
from django.utils import timezone
from datetime import timedelta
from django.conf import settings


class EscrowAccountSerializer(serializers.ModelSerializer):
    """
    Serializer for EscrowAccount model
    """
    amount_display = serializers.SerializerMethodField()
    days_remaining = serializers.SerializerMethodField()
    is_expired = serializers.SerializerMethodField()
    
    class Meta:
        model = EscrowAccount
        fields = [
            'id', 'transaction', 'amount', 'amount_display', 'category',
            'start_date', 'end_date', 'days_remaining', 'is_expired',
            'early_release_requested', 'early_release_approved',
            'status', 'created_at', 'updated_at'
        ]
        read_only_fields = [
            'id', 'start_date', 'days_remaining', 'is_expired',
            'created_at', 'updated_at'
        ]
    
    def get_amount_display(self, obj):
        return f"NGN {obj.amount:,.2f}"
    
    def get_days_remaining(self, obj):
        if obj.end_date and obj.end_date > timezone.now().date():
            return (obj.end_date - timezone.now().date()).days
        return 0
    
    def get_is_expired(self, obj):
        if obj.end_date:
            return obj.end_date < timezone.now().date()
        return False
    
    def validate_end_date(self, value):
        if value and value <= timezone.now().date():
            raise serializers.ValidationError("End date must be in the future")
        return value


class EscrowCreateSerializer(serializers.Serializer):
    """
    Serializer for creating new escrow accounts
    """
    transaction_id = serializers.UUIDField()
    amount = serializers.DecimalField(max_digits=12, decimal_places=2)
    category = serializers.ChoiceField(choices=[
        'vehicle_parts', 'electronics', 'custom_high_value', 'default'
    ], default='default')
    custom_period_days = serializers.IntegerField(required=False, min_value=1, max_value=90)
    
    def validate_amount(self, value):
        if value <= 0:
            raise serializers.ValidationError("Amount must be greater than zero")
        return value
    
    def validate(self, data):
        from transactions.models import Transaction
        
        try:
            transaction = Transaction.objects.get(id=data['transaction_id'])
            if transaction.transaction_type != 'escrow':
                raise serializers.ValidationError("Transaction must be of type 'escrow'")
            if hasattr(transaction, 'escrowaccount'):
                raise serializers.ValidationError("Escrow account already exists for this transaction")
        except Transaction.DoesNotExist:
            raise serializers.ValidationError("Transaction not found")
        
        return data


class EscrowReleaseSerializer(serializers.Serializer):
    """
    Serializer for escrow release requests
    """
    release_type = serializers.ChoiceField(choices=['early', 'normal'], default='normal')
    reason = serializers.CharField(max_length=500, required=False)
    
    def validate_reason(self, value):
        release_type = self.initial_data.get('release_type')
        if release_type == 'early' and not value:
            raise serializers.ValidationError("Reason is required for early release requests")
        return value


class EscrowStatusUpdateSerializer(serializers.Serializer):
    """
    Serializer for escrow status updates
    """
    status = serializers.ChoiceField(choices=[
        'active', 'released', 'disputed', 'refunded'
    ])
    reason = serializers.CharField(max_length=500, required=False)
    admin_notes = serializers.CharField(max_length=1000, required=False)
