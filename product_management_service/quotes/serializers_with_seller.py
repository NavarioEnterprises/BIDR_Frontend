"""
Extended serializers that include seller details from authentication service.

This module provides serializers that enhance the standard quote serializers
by fetching seller information from the authentication service.
"""

from rest_framework import serializers
from django.db.models import Q
from .serializers import (
    QuoteListSerializer, QuoteDetailSerializer, QuoteCreateUpdateSerializer,
    QuoteItemSerializer
)
from .models import Quote
from core.auth_service import get_seller_basic_info, get_multiple_sellers


class SellerInfoMixin:
    """
    Mixin to add seller information to serializers.
    """
    
    def get_seller_info(self, obj):
        """Get seller information from authentication service."""
        if hasattr(obj, 'seller_id') and obj.seller_id:
            return get_seller_basic_info(str(obj.seller_id))
        return None
    
    def to_representation(self, instance):
        """Add seller info to the serialized representation."""
        representation = super().to_representation(instance)
        
        # Add seller details from authentication service
        seller_info = self.get_seller_info(instance)
        if seller_info:
            representation['seller_details'] = seller_info
        
        return representation


class QuoteListWithSellerSerializer(SellerInfoMixin, QuoteListSerializer):
    """
    Quote list serializer with seller details from authentication service.
    """
    seller_details = serializers.SerializerMethodField()
    
    class Meta(QuoteListSerializer.Meta):
        fields = QuoteListSerializer.Meta.fields + ['seller_details']
    
    def get_seller_details(self, obj):
        """Get seller details from authentication service."""
        return self.get_seller_info(obj)


class QuoteDetailWithSellerSerializer(SellerInfoMixin, QuoteDetailSerializer):
    """
    Quote detail serializer with seller details from authentication service.
    """
    seller_details = serializers.SerializerMethodField()
    
    class Meta(QuoteDetailSerializer.Meta):
        fields = QuoteDetailSerializer.Meta.fields + ['seller_details']
    
    def get_seller_details(self, obj):
        """Get seller details from authentication service."""
        return self.get_seller_info(obj)


class QuoteCreateUpdateWithSellerSerializer(QuoteCreateUpdateSerializer):
    """
    Quote create/update serializer with seller validation.
    """
    
    def validate_seller_id(self, value):
        """Validate that seller exists in authentication service."""
        from core.auth_service import validate_seller_exists
        
        if not validate_seller_exists(str(value)):
            raise serializers.ValidationError(
                f"Seller with ID {value} not found in authentication service."
            )
        return value
    
    def to_representation(self, instance):
        """Add seller info to the response."""
        representation = super().to_representation(instance)
        
        # Add seller details from authentication service
        seller_info = get_seller_basic_info(str(instance.seller_id))
        if seller_info:
            representation['seller_details'] = seller_info
        
        return representation


class QuoteItemWithSellerSerializer(QuoteItemSerializer):
    """
    Quote item serializer with seller details.
    """
    seller_details = serializers.SerializerMethodField()
    
    class Meta(QuoteItemSerializer.Meta):
        fields = QuoteItemSerializer.Meta.fields + ['seller_details']
    
    def get_seller_details(self, obj):
        """Get seller details from the parent quote."""
        if hasattr(obj, 'quote') and hasattr(obj.quote, 'seller_id'):
            return get_seller_basic_info(str(obj.quote.seller_id))
        return None


class BulkQuoteWithSellerSerializer(serializers.ModelSerializer):
    """
    Serializer for handling bulk quote operations with seller details.
    """
    seller_details = serializers.SerializerMethodField()
    
    class Meta:
        model = Quote
        fields = [
            'quote_id', 'request_id', 'seller_id', 'total_amount', 'currency',
            'status', 'created_at', 'seller_details'
        ]
    
    def get_seller_details(self, obj):
        """Get seller details from authentication service."""
        return get_seller_basic_info(str(obj.seller_id))
    
    @classmethod
    def get_quotes_with_sellers(cls, quotes):
        """
        Efficiently get multiple quotes with seller details.
        
        Args:
            quotes: QuerySet or list of Quote instances
            
        Returns:
            Serialized data with seller details
        """
        # Extract unique seller IDs
        seller_ids = list(set(str(quote.seller_id) for quote in quotes if quote.seller_id))
        
        # Fetch all seller details at once
        sellers_data = get_multiple_sellers(seller_ids)
        
        # Serialize quotes and add seller details
        serializer = cls(quotes, many=True)
        data = serializer.data
        
        # Enhance with seller details
        for item in data:
            seller_id = str(item['seller_id'])
            if seller_id in sellers_data:
                item['seller_details'] = sellers_data[seller_id]
        
        return data


# Utility functions for views
def enhance_quotes_with_seller_details(quotes_data):
    """
    Add seller details to a list of quote dictionaries.
    
    Args:
        quotes_data: List of quote dictionaries
        
    Returns:
        Enhanced quotes data with seller details
    """
    if not quotes_data:
        return quotes_data
    
    # Extract seller IDs
    seller_ids = []
    for quote in quotes_data:
        if 'seller_id' in quote and quote['seller_id']:
            seller_ids.append(str(quote['seller_id']))
    
    # Get seller details
    if seller_ids:
        sellers_info = get_multiple_sellers(list(set(seller_ids)))
        
        # Add seller details to each quote
        for quote in quotes_data:
            seller_id = str(quote.get('seller_id', ''))
            if seller_id in sellers_info:
                quote['seller_details'] = sellers_info[seller_id]
    
    return quotes_data


def get_seller_quotes_summary(seller_id: str):
    """
    Get a summary of quotes for a specific seller.
    
    Args:
        seller_id: Seller UUID
        
    Returns:
        Dict with quote statistics and seller info
    """
    from django.db.models import Count, Sum, Avg
    from .models import Quote
    
    seller_info = get_seller_basic_info(seller_id)
    
    quote_stats = Quote.objects.filter(seller_id=seller_id).aggregate(
        total_quotes=Count('quote_id'),
        total_value=Sum('total_amount'),
        avg_quote_value=Avg('total_amount'),
        accepted_quotes=Count('quote_id', filter=Q(status='ACCEPTED')),
        pending_quotes=Count('quote_id', filter=Q(status='PENDING')),
        rejected_quotes=Count('quote_id', filter=Q(status='REJECTED'))
    )
    
    return {
        'seller_info': seller_info,
        'quote_statistics': quote_stats,
        'success_rate': (
            (quote_stats['accepted_quotes'] / quote_stats['total_quotes'] * 100) 
            if quote_stats['total_quotes'] > 0 else 0
        )
    }