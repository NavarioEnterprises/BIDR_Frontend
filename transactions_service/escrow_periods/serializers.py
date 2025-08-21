"""
Serializers for the EscrowPeriod models.

This module provides serializers for the EscrowPeriod model to convert model instances
to JSON and vice versa, with validation and custom field handling.
"""

from rest_framework import serializers
from django.utils import timezone
from django.core.exceptions import ValidationError

from .models import EscrowPeriod
from transactions.models import Transaction


class EscrowPeriodListSerializer(serializers.ModelSerializer):
    """
    Serializer for listing escrow periods with minimal information.
    """
    transaction_reference = serializers.SerializerMethodField()
    days_remaining = serializers.SerializerMethodField()
    
    class Meta:
        model = EscrowPeriod
        fields = [
            'escrow_id', 'transaction_reference', 'category',
            'hold_period_days', 'start_date', 'end_date', 
            'status', 'days_remaining'
        ]
    
    def get_transaction_reference(self, obj):
        """Get a readable transaction reference."""
        try:
            return str(obj.transaction_id.transaction_id)
        except (AttributeError, Exception):
            return "Unknown Transaction"
    
    def get_days_remaining(self, obj):
        """Calculate how many days remain until the escrow period ends."""
        if obj.status != 'ACTIVE':
            return 0
        
        today = timezone.now().date()
        end_date = obj.end_date.date()
        
        if end_date <= today:
            return 0
        
        delta = end_date - today
        return delta.days


class EscrowPeriodDetailSerializer(serializers.ModelSerializer):
    """
    Serializer for detailed escrow period information.
    """
    transaction_details = serializers.SerializerMethodField()
    category_display = serializers.SerializerMethodField()
    is_release_due = serializers.SerializerMethodField()
    
    class Meta:
        model = EscrowPeriod
        fields = [
            'escrow_id', 'transaction_id', 'transaction_details',
            'category', 'category_display', 'hold_period_days',
            'start_date', 'end_date', 'early_release_requested',
            'early_release_approved', 'status', 'is_release_due',
            'created_at', 'updated_at'
        ]
        read_only_fields = [
            'escrow_id', 'created_at', 'updated_at',
            'is_release_due', 'category_display'
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
    
    def get_category_display(self, obj):
        """Get the display name for the category."""
        return dict(EscrowPeriod.CATEGORY_CHOICES).get(obj.category, obj.category)
    
    def get_is_release_due(self, obj):
        """Check if the escrow period has ended and payment should be released."""
        return obj.is_release_due()


class EscrowPeriodCreateSerializer(serializers.ModelSerializer):
    """
    Serializer for creating new escrow periods with validation.
    """
    class Meta:
        model = EscrowPeriod
        fields = [
            'transaction_id', 'category', 'hold_period_days',
            'start_date', 'end_date'
        ]
    
    def validate_transaction_id(self, value):
        """Validate that the transaction exists and can have an escrow period."""
        try:
            transaction = Transaction.objects.get(transaction_id=value)
            
            # Check if transaction already has an active escrow period
            existing_escrows = EscrowPeriod.objects.filter(
                transaction_id=transaction,
                status='ACTIVE'
            )
            
            if existing_escrows.exists():
                raise ValidationError(
                    "This transaction already has an active escrow period. "
                    "Please refer to escrow ID: {}".format(
                        existing_escrows.first().escrow_id
                    )
                )
            
            # Check if transaction is in a valid state for escrow
            if transaction.status not in ['ACTIVE', 'COMPLETED']:
                raise ValidationError(
                    "Only active or completed transactions can have escrow periods. "
                    "Current status: {}".format(transaction.status)
                )
            
            return value
        except Transaction.DoesNotExist:
            raise ValidationError("Transaction does not exist")
    
    def validate(self, data):
        """Validate the escrow period data."""
        # If hold_period_days is not provided, calculate it from category
        if 'category' in data and 'hold_period_days' not in data:
            data['hold_period_days'] = EscrowPeriod.get_hold_period_for_category(data['category'])
        
        # If start_date is not provided, use current time
        if 'start_date' not in data:
            data['start_date'] = timezone.now()
        
        # If end_date is not provided, calculate it
        if 'end_date' not in data and 'start_date' in data and 'hold_period_days' in data:
            from datetime import timedelta
            data['end_date'] = data['start_date'] + timedelta(days=data['hold_period_days'])
        
        # Validate that end_date is after start_date
        if 'start_date' in data and 'end_date' in data:
            if data['end_date'] <= data['start_date']:
                raise ValidationError("End date must be after start date")
        
        return data
    
    def create(self, validated_data):
        """Create a new escrow period with default status of ACTIVE."""
        validated_data['status'] = 'ACTIVE'
        return super().create(validated_data)


class EscrowPeriodUpdateSerializer(serializers.ModelSerializer):
    """
    Serializer for updating escrow periods with status transitions and validation.
    """
    class Meta:
        model = EscrowPeriod
        fields = [
            'status', 'early_release_requested', 
            'early_release_approved', 'end_date'
        ]
    
    def validate_status(self, value):
        """Validate status transitions."""
        instance = self.instance
        if not instance:
            return value
        
        # Define valid status transitions
        valid_transitions = {
            'ACTIVE': ['RELEASED', 'DISPUTED'],
            'RELEASED': [],  # No transitions from RELEASED
            'DISPUTED': ['RELEASED']  # Can only go to RELEASED after dispute resolution
        }
        
        if value not in valid_transitions.get(instance.status, []):
            raise ValidationError(
                f"Invalid status transition from '{instance.status}' to '{value}'. "
                f"Valid transitions are: {', '.join(valid_transitions.get(instance.status, []))}"
            )
        
        return value
    
    def validate(self, data):
        """Validate the update data."""
        # If transitioning to RELEASED, ensure early_release is properly handled
        if 'status' in data and data['status'] == 'RELEASED':
            if self.instance.early_release_requested and not self.instance.early_release_approved:
                if not self.context['request'].user.is_staff:
                    raise ValidationError(
                        "Early release must be approved by an administrator before releasing"
                    )
        
        # If approving early release, ensure user is admin
        if 'early_release_approved' in data and data['early_release_approved']:
            if not self.context['request'].user.is_staff:
                raise ValidationError("Only administrators can approve early release")
        
        return data


class EarlyReleaseRequestSerializer(serializers.ModelSerializer):
    """
    Serializer for requesting early release of an escrow period.
    """
    class Meta:
        model = EscrowPeriod
        fields = ['early_release_requested']
    
    def validate(self, data):
        """Validate the early release request."""
        if self.instance.status != 'ACTIVE':
            raise ValidationError("Early release can only be requested for active escrow periods")
        
        if self.instance.early_release_requested:
            raise ValidationError("Early release has already been requested for this escrow period")
        
        return data