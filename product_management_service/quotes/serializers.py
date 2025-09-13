"""
Serializers for the Quotes app in BIDR Quoting Service.

This module provides serializers for Quote models and related entities.
"""

from rest_framework import serializers
from django.contrib.auth.models import User
from django.utils import timezone
from decimal import Decimal
from django.db.models import Q
from .models import (
    Quote, QuoteItem, QuoteAttachment, QuoteMessage, QuoteComparison
)


class UserMinimalSerializer(serializers.ModelSerializer):
    """
    Minimal serializer for User model to be used in nested serializations.
    """
    class Meta:
        model = User
        fields = ['id', 'username', 'email', 'first_name', 'last_name']
        read_only_fields = fields


class QuoteItemSerializer(serializers.ModelSerializer):
    """
    Serializer for quote items.
    """
    class Meta:
        model = QuoteItem
        fields = [
            'id', 'quote', 'product', 'name', 'description', 'sku',
            'unit_price', 'quantity', 'line_total', 'specifications',
            'sort_order'
        ]
        read_only_fields = ['id', 'line_total']

    def validate(self, data):
        """
        Validate that unit_price and quantity are positive.
        """
        if data.get('unit_price', 0) <= 0:
            raise serializers.ValidationError({
                'unit_price': 'Unit price must be greater than zero.'
            })
        
        if data.get('quantity', 0) <= 0:
            raise serializers.ValidationError({
                'quantity': 'Quantity must be greater than zero.'
            })
        
        return data


class QuoteAttachmentSerializer(serializers.ModelSerializer):
    """
    Serializer for quote attachments.
    """
    file_size_formatted = serializers.ReadOnlyField()
    
    class Meta:
        model = QuoteAttachment
        fields = [
            'id', 'quote', 'file', 'filename', 'description',
            'file_size', 'content_type', 'uploaded_at', 'file_size_formatted'
        ]
        read_only_fields = ['id', 'file_size', 'content_type', 'uploaded_at', 'file_size_formatted']


class QuoteMessageSerializer(serializers.ModelSerializer):
    """
    Serializer for quote messages.
    """
    sender_details = UserMinimalSerializer(source='sender', read_only=True)
    is_read = serializers.ReadOnlyField()
    
    class Meta:
        model = QuoteMessage
        fields = [
            'id', 'quote', 'sender', 'sender_details', 'message_type',
            'subject', 'message', 'is_internal', 'created_at',
            'read_at', 'is_read'
        ]
        read_only_fields = ['id', 'sender_details', 'created_at', 'read_at', 'is_read']


class QuoteListSerializer(serializers.ModelSerializer):
    """
    Simplified serializer for quote listings.
    """
    seller_details = UserMinimalSerializer(source='seller_id', read_only=True)
    request_id_details = serializers.CharField(source='request_id.request_id', read_only=True)
    is_expired = serializers.ReadOnlyField()
    is_valid = serializers.ReadOnlyField()
    
    class Meta:
        model = Quote
        fields = [
            'quote_id', 'request_id', 'request_id_details', 'seller_id', 'seller_details',
            'total_amount', 'currency', 'delivery_cost', 'installation_cost',
            'estimated_delivery_days', 'status', 'valid_until', 
            'is_expired', 'is_valid', 'created_at', 'updated_at'
        ]
        read_only_fields = [
            'quote_id', 'seller_details', 'request_id_details',
            'is_expired', 'is_valid', 'created_at', 'updated_at'
        ]


class QuoteDetailSerializer(serializers.ModelSerializer):
    """
    Detailed serializer for individual quote views.
    """
    seller_details = UserMinimalSerializer(source='seller_id', read_only=True)
    request_details = serializers.SerializerMethodField()
    items = QuoteItemSerializer(many=True, read_only=True)
    attachments = QuoteAttachmentSerializer(many=True, read_only=True)
    messages = serializers.SerializerMethodField()
    
    # Computed properties
    is_expired = serializers.ReadOnlyField()
    is_valid = serializers.ReadOnlyField()
    
    class Meta:
        model = Quote
        fields = [
            'quote_id', 'request_id', 'request_details', 'seller_id', 'seller_details',
            'total_amount', 'currency', 'delivery_cost', 'installation_cost',
            'estimated_delivery_days', 'terms_conditions', 'seller_notes',
            'warranty_info', 'status', 'valid_until', 'is_expired', 'is_valid',
            'items', 'attachments', 'messages', 'created_at', 'updated_at'
        ]
        read_only_fields = [
            'quote_id', 'seller_details', 'request_details', 'is_expired', 'is_valid',
            'items', 'attachments', 'messages', 'created_at', 'updated_at'
        ]
    
    def get_request_details(self, obj):
        """Get comprehensive request details."""
        if obj.request_id:
            request = obj.request_id
            return {
                'id': request.request_id,
                'title': getattr(request, 'title', 'Product Request'),
                'description': getattr(request, 'description', ''),
                'category': getattr(request, 'category', ''),
                'quantity': getattr(request, 'quantity', None),
                'condition_preference': getattr(request, 'condition_preference', ''),
                'max_budget': getattr(request, 'max_budget', None),
                'currency': getattr(request, 'currency', 'ZAR'),
                'buyer_location': getattr(request, 'buyer_location', {}),
                'urgency_timeline': getattr(request, 'urgency_timeline', ''),
                'product_specifications': getattr(request, 'product_specifications', {}),
                'product_images': getattr(request, 'product_images', []),
                'vin_photo_url': getattr(request, 'vin_photo_url', ''),
                'status': getattr(request, 'status', ''),
                'created_at': request.created_at.isoformat() if hasattr(request, 'created_at') else None,
                'updated_at': request.updated_at.isoformat() if hasattr(request, 'updated_at') else None,
                # Category-specific summaries
                'vehicle_spares_summary': getattr(request, 'vehicle_spares_summary', ''),
                'tyres_rims_summary': getattr(request, 'tyres_rims_summary', ''),
                'consumer_electronics_summary': getattr(request, 'consumer_electronics_summary', ''),
                # Related category models data
                'vehicle_spares_data': self._get_vehicle_spares_data(request),
                'vehicle_tyres_rims_data': self._get_vehicle_tyres_rims_data(request),
                'consumer_electronics_data': self._get_consumer_electronics_data(request),
            }
        return None
    
    def _get_vehicle_spares_data(self, request):
        """Get vehicle spares specific data if available."""
        if hasattr(request, 'vehicle_spares') and request.vehicle_spares:
            vs = request.vehicle_spares
            return {
                'vehicle_make': getattr(vs, 'vehicle_make', ''),
                'vehicle_model': getattr(vs, 'vehicle_model', ''),
                'vehicle_year': getattr(vs, 'vehicle_year', None),
                'vehicle_type': getattr(vs, 'vehicle_type', ''),
                'engine_size': getattr(vs, 'engine_size', ''),
                'vin_number': getattr(vs, 'vin_number', ''),
                'part_name': getattr(vs, 'part_name', ''),
                'part_category': getattr(vs, 'part_category', ''),
                'part_number': getattr(vs, 'part_number', ''),
            }
        return None
    
    def _get_vehicle_tyres_rims_data(self, request):
        """Get tyres/rims specific data if available."""
        if hasattr(request, 'vehicle_tyres_rims') and request.vehicle_tyres_rims:
            tr = request.vehicle_tyres_rims
            return {
                'tyre_width': getattr(tr, 'tyre_width', ''),
                'sidewall_profile': getattr(tr, 'sidewall_profile', ''),
                'wheel_rim_diameter': getattr(tr, 'wheel_rim_diameter', ''),
                'select_tyres_rims': getattr(tr, 'select_tyres_rims', ''),
                'vehicle_type': getattr(tr, 'vehicle_type', ''),
                'preferred_brand': getattr(tr, 'preferred_brand', ''),
            }
        return None
    
    def _get_consumer_electronics_data(self, request):
        """Get consumer electronics specific data if available."""
        if hasattr(request, 'consumer_electronics') and request.consumer_electronics:
            ce = request.consumer_electronics
            return {
                'electronics_type': getattr(ce, 'electronics_type', ''),
                'brand_preference': getattr(ce, 'brand_preference', ''),
                'model_series': getattr(ce, 'model_series', ''),
                'screen_size': getattr(ce, 'screen_size', ''),
                'connectivity_options': getattr(ce, 'connectivity_options', []),
            }
        return None
    
    def get_messages(self, obj):
        """Get messages, filtering by visibility based on user."""
        user = self.context.get('request').user if self.context.get('request') else None
        if not user:
            return []
        
        # If user is the seller, show all non-internal messages and internal messages created by them
        if user == obj.seller_id:
            messages = obj.messages.filter(
                Q(is_internal=False) | 
                Q(is_internal=True, sender=user)
            )
        # If user is the requester, show all non-internal messages and internal messages created by them
        elif hasattr(obj.request_id, 'requester') and user == obj.request_id.requester:
            messages = obj.messages.filter(
                Q(is_internal=False) | 
                Q(is_internal=True, sender=user)
            )
        # For other users (admins), show all messages
        else:
            messages = obj.messages.all()
        
        return QuoteMessageSerializer(messages, many=True, context=self.context).data


class QuoteCreateUpdateSerializer(serializers.ModelSerializer):
    """
    Serializer for creating and updating quotes.
    """
    items = QuoteItemSerializer(many=True, required=False)
    
    class Meta:
        model = Quote
        fields = [
            'request_id', 'seller_id', 'total_amount', 'currency',
            'delivery_cost', 'installation_cost', 'estimated_delivery_days',
            'terms_conditions', 'seller_notes', 'warranty_info',
            'status', 'valid_until', 'items'
        ]
    
    def validate(self, data):
        """
        Cross-field validation.
        """
        # Validate total_amount is positive
        if data.get('total_amount', 0) <= 0:
            raise serializers.ValidationError({
                'total_amount': 'Total amount must be greater than zero.'
            })
        
        # Validate request_id and seller_id
        request_id = data.get('request_id')
        seller_id = data.get('seller_id')
        
        # Check for duplicate quotes from same seller for same request
        if request_id and seller_id and self.instance is None:  # Only for new quotes
            if Quote.objects.filter(request_id=request_id, seller_id=seller_id).exists():
                raise serializers.ValidationError({
                    'seller_id': 'This seller has already submitted a quote for this request.'
                })
        
        return data
    
    def create(self, validated_data):
        """
        Create a quote with nested items.
        """
        items_data = validated_data.pop('items', [])
        quote = Quote.objects.create(**validated_data)
        
        for item_data in items_data:
            QuoteItem.objects.create(quote=quote, **item_data)
        
        return quote
    
    def update(self, instance, validated_data):
        """
        Update a quote with nested items.
        """
        items_data = validated_data.pop('items', None)
        
        # Update quote fields
        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        instance.save()
        
        # Update items if provided
        if items_data is not None:
            # Remove existing items
            instance.items.all().delete()
            
            # Create new items
            for item_data in items_data:
                QuoteItem.objects.create(quote=instance, **item_data)
        
        return instance


class QuoteComparisonSerializer(serializers.ModelSerializer):
    """
    Serializer for quote comparisons.
    """
    request_reference = serializers.CharField(source='request.reference_number', read_only=True)
    best_price_quote_details = QuoteListSerializer(source='best_price_quote', read_only=True)
    best_delivery_quote_details = QuoteListSerializer(source='best_delivery_quote', read_only=True)
    
    class Meta:
        model = QuoteComparison
        fields = [
            'id', 'request', 'request_reference', 'total_quotes',
            'lowest_price', 'highest_price', 'average_price',
            'best_price_quote', 'best_price_quote_details',
            'best_delivery_quote', 'best_delivery_quote_details',
            'comparison_data', 'last_updated'
        ]
        read_only_fields = fields


class QuoteMessageCreateSerializer(serializers.ModelSerializer):
    """
    Serializer for creating quote messages.
    """
    class Meta:
        model = QuoteMessage
        fields = [
            'quote', 'sender', 'message_type', 'subject',
            'message', 'is_internal'
        ]
    
    def validate(self, data):
        """
        Validate that the sender has permission to send messages for this quote.
        """
        quote = data.get('quote')
        sender = data.get('sender')
        
        if not quote or not sender:
            return data
        
        # Check if sender is the supplier or requester
        if sender != quote.supplier and sender != quote.request.requester:
            # Check if sender is an admin or staff
            if not sender.is_staff and not sender.is_superuser:
                raise serializers.ValidationError({
                    'sender': 'You do not have permission to send messages for this quote.'
                })
        
        return data


class QuoteStatusUpdateSerializer(serializers.Serializer):
    """
    Serializer for updating quote status.
    """
    status = serializers.ChoiceField(choices=Quote.STATUS_CHOICES)
    notes = serializers.CharField(required=False, allow_blank=True)
    
    def validate_status(self, value):
        """
        Validate status transitions.
        """
        instance = self.instance
        
        # Define allowed transitions
        allowed_transitions = {
            'PENDING': ['ACCEPTED', 'REJECTED'],
            'ACCEPTED': [],  # Terminal state
            'REJECTED': [],  # Terminal state
            'EXPIRED': []    # Terminal state
        }
        
        if instance and value not in allowed_transitions.get(instance.status, []):
            current_status = dict(Quote.STATUS_CHOICES)[instance.status]
            new_status = dict(Quote.STATUS_CHOICES)[value]
            raise serializers.ValidationError(
                f"Cannot transition from '{current_status}' to '{new_status}'."
            )
        
        return value