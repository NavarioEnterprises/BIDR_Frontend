"""
Serializers for the Dispute models.

This module provides serializers for the Dispute model to convert model instances
to JSON and vice versa, with validation and custom field handling.
"""

from rest_framework import serializers
from django.utils import timezone
from django.core.exceptions import ValidationError

from .models import Dispute
from transactions.models import Transaction
from external_models import AppUser


class DisputeListSerializer(serializers.ModelSerializer):
    """
    Serializer for listing disputes with minimal information.
    """
    initiator_name = serializers.SerializerMethodField()
    transaction_reference = serializers.SerializerMethodField()
    days_open = serializers.SerializerMethodField()
    
    class Meta:
        model = Dispute
        fields = [
            'dispute_id', 'transaction_reference', 'initiator_name',
            'dispute_type', 'status', 'created_at', 'days_open'
        ]
    
    def get_initiator_name(self, obj):
        """Get the initiator's full name."""
        try:
            return obj.initiator_id.get_full_name()
        except (AttributeError, Exception):
            return "Unknown User"
    
    def get_transaction_reference(self, obj):
        """Get a readable transaction reference."""
        try:
            return str(obj.transaction_id.transaction_id)
        except (AttributeError, Exception):
            return "Unknown Transaction"
    
    def get_days_open(self, obj):
        """Calculate how many days the dispute has been open."""
        if obj.status in ['RESOLVED', 'CLOSED']:
            end_date = obj.resolved_at or timezone.now()
            delta = end_date - obj.created_at
            return delta.days
        else:
            delta = timezone.now() - obj.created_at
            return delta.days


class DisputeDetailSerializer(serializers.ModelSerializer):
    """
    Serializer for detailed dispute information, including resolution details.
    """
    initiator_details = serializers.SerializerMethodField()
    transaction_details = serializers.SerializerMethodField()
    resolver_details = serializers.SerializerMethodField()
    
    class Meta:
        model = Dispute
        fields = [
            'dispute_id', 'transaction_id', 'transaction_details',
            'initiator_id', 'initiator_details', 'dispute_type',
            'description', 'evidence_files', 'status',
            'resolution', 'resolved_by', 'resolver_details',
            'resolved_at', 'created_at', 'updated_at'
        ]
        read_only_fields = [
            'dispute_id', 'created_at', 'updated_at',
            'resolved_at', 'resolver_details'
        ]
    
    def get_initiator_details(self, obj):
        """Get detailed information about the initiator."""
        try:
            user = obj.initiator_id
            return {
                'id': user.id,
                'name': user.get_full_name(),
                'email': user.email,
                'role': user.role
            }
        except (AttributeError, Exception):
            return None
    
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
    
    def get_resolver_details(self, obj):
        """Get information about the user who resolved the dispute."""
        if not obj.resolved_by:
            return None
        
        try:
            user = obj.resolved_by
            return {
                'id': user.id,
                'name': user.get_full_name(),
                'email': user.email,
                'role': user.role
            }
        except (AttributeError, Exception):
            return None


class DisputeCreateSerializer(serializers.ModelSerializer):
    """
    Serializer for creating new disputes with validation.
    """
    class Meta:
        model = Dispute
        fields = [
            'transaction_id', 'initiator_id', 'dispute_type',
            'description', 'evidence_files'
        ]
    
    def validate_transaction_id(self, value):
        """Validate that the transaction exists and can be disputed."""
        try:
            transaction = Transaction.objects.get(transaction_id=value)
            
            # Check if transaction is already disputed
            existing_disputes = Dispute.objects.filter(
                transaction_id=transaction,
                status__in=['OPEN', 'INVESTIGATING']
            )
            
            if existing_disputes.exists():
                raise ValidationError(
                    "This transaction already has an active dispute. "
                    "Please refer to dispute ID: {}".format(
                        existing_disputes.first().dispute_id
                    )
                )
            
            # Check if transaction is in a disputable state
            if transaction.status not in ['ACTIVE', 'COMPLETED']:
                raise ValidationError(
                    "Only active or completed transactions can be disputed. "
                    "Current status: {}".format(transaction.status)
                )
            
            return value
        except Transaction.DoesNotExist:
            raise ValidationError("Transaction does not exist")
    
    def validate_initiator_id(self, value):
        """Validate that the initiator exists and is related to the transaction."""
        try:
            user = AppUser.objects.get(id=value)
            
            # Additional validation will be done in validate() to check
            # if user is related to the transaction
            
            return value
        except AppUser.DoesNotExist:
            raise ValidationError("User does not exist")
    
    def validate(self, data):
        """Validate that the initiator is related to the transaction."""
        transaction = data.get('transaction_id')
        initiator = data.get('initiator_id')
        
        if transaction and initiator:
            # Check if user is buyer or seller of the transaction
            is_related = (
                (hasattr(transaction, 'buyer_id') and transaction.buyer_id.user == initiator) or
                (hasattr(transaction, 'seller_id') and transaction.seller_id.user == initiator)
            )
            
            if not is_related:
                raise ValidationError(
                    "The initiator must be either the buyer or seller of the transaction"
                )
        
        return data
    
    def create(self, validated_data):
        """Create a new dispute with default status of OPEN."""
        validated_data['status'] = 'OPEN'
        return super().create(validated_data)


class DisputeUpdateSerializer(serializers.ModelSerializer):
    """
    Serializer for updating disputes with status transitions and validation.
    """
    class Meta:
        model = Dispute
        fields = ['status', 'resolution', 'resolved_by']
        read_only_fields = ['resolved_by']
    
    def validate_status(self, value):
        """Validate status transitions."""
        instance = self.instance
        if not instance:
            return value
        
        # Define valid status transitions
        valid_transitions = {
            'OPEN': ['INVESTIGATING', 'RESOLVED', 'CLOSED'],
            'INVESTIGATING': ['RESOLVED', 'CLOSED'],
            'RESOLVED': ['CLOSED'],
            'CLOSED': []  # No transitions from CLOSED
        }
        
        if value not in valid_transitions.get(instance.status, []):
            raise ValidationError(
                f"Invalid status transition from '{instance.status}' to '{value}'. "
                f"Valid transitions are: {', '.join(valid_transitions.get(instance.status, []))}"
            )
        
        return value
    
    def validate(self, data):
        """Validate that resolution is provided when status is RESOLVED."""
        status = data.get('status')
        resolution = data.get('resolution')
        
        if status == 'RESOLVED' and not resolution and not self.instance.resolution:
            raise ValidationError(
                "Resolution details are required when resolving a dispute"
            )
        
        return data
    
    def update(self, instance, validated_data):
        """Update dispute with custom logic for resolution."""
        status = validated_data.get('status')
        
        # Handle resolution logic
        if status == 'RESOLVED' and instance.status != 'RESOLVED':
            validated_data['resolved_at'] = timezone.now()
            validated_data['resolved_by'] = self.context['request'].user
        
        return super().update(instance, validated_data)


class DisputeEvidenceSerializer(serializers.ModelSerializer):
    """
    Serializer for updating dispute evidence files.
    """
    class Meta:
        model = Dispute
        fields = ['evidence_files']
    
    def validate_evidence_files(self, value):
        """Validate evidence files format."""
        if not isinstance(value, list) and not isinstance(value, dict):
            raise ValidationError("Evidence files must be a list or dictionary")
        
        # If it's a list, ensure each item is a valid URL or file path
        if isinstance(value, list):
            for item in value:
                if not isinstance(item, str):
                    raise ValidationError("Each evidence item must be a string (URL or file path)")
        
        # If it's a dict, validate its structure
        if isinstance(value, dict):
            if 'files' not in value:
                raise ValidationError("Evidence dictionary must contain a 'files' key")
            
            if not isinstance(value['files'], list):
                raise ValidationError("The 'files' value must be a list")
            
            for item in value['files']:
                if not isinstance(item, str):
                    raise ValidationError("Each evidence file must be a string (URL or file path)")
        
        return value
    
    def update(self, instance, validated_data):
        """Update evidence files with merge logic."""
        if instance.status in ['RESOLVED', 'CLOSED']:
            raise ValidationError("Cannot update evidence for resolved or closed disputes")
        
        # Get existing evidence files
        existing_evidence = instance.evidence_files or {}
        
        # If existing evidence is a list, convert to dict format
        if isinstance(existing_evidence, list):
            existing_evidence = {'files': existing_evidence}
        
        # Get new evidence files
        new_evidence = validated_data.get('evidence_files', {})
        
        # If new evidence is a list, convert to dict format
        if isinstance(new_evidence, list):
            new_evidence = {'files': new_evidence}
        
        # Merge evidence
        if 'files' in new_evidence:
            if 'files' not in existing_evidence:
                existing_evidence['files'] = []
            
            # Add new files, avoiding duplicates
            for file in new_evidence['files']:
                if file not in existing_evidence['files']:
                    existing_evidence['files'].append(file)
        
        # Update other evidence metadata if provided
        for key, value in new_evidence.items():
            if key != 'files':
                existing_evidence[key] = value
        
        # Save merged evidence
        instance.evidence_files = existing_evidence
        instance.save()
        
        return instance