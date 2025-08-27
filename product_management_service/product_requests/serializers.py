"""
Serializers for Product Request models.
"""

import json
from rest_framework import serializers
from django.contrib.auth.models import User
from .models import (
    ConsumerElectronics, VehicleSpares, VehicleTyresRims, 
    ProductRequest, RequestImage, RequestSpecification, 
    RequestMessage, RequestWatchlist, RequestTemplate
)
from quotes.models import Quote
from .models import Order
from django.utils import timezone


class JSONStringField(serializers.JSONField):
    """Custom JSON field that can handle JSON strings in multipart form data.
    Also handles when data is already a dictionary."""
    
    def to_internal_value(self, data):
        # If it's already a dict, use it directly
        if isinstance(data, dict):
            return data
            
        # Handle string inputs
        if isinstance(data, str):
            try:
                # Handle empty JSON objects
                if data.strip() in ['{}', '']:
                    return {}
                return json.loads(data)
            except (json.JSONDecodeError, ValueError) as e:
                self.fail('invalid', message=f'Invalid JSON format: {str(e)}')
        return super().to_internal_value(data)


class ConsumerElectronicsSerializer(serializers.ModelSerializer):
    """Serializer for ConsumerElectronics model."""
    
    # Read-only fields to show computed properties
    budget_range_display = serializers.ReadOnlyField()
    is_urgent = serializers.ReadOnlyField()
    full_product_description = serializers.ReadOnlyField()
    is_energy_conscious = serializers.ReadOnlyField()
    
    class Meta:
        model = ConsumerElectronics
        fields = '__all__'
        read_only_fields = ['id', 'created_at', 'updated_at']


class VehicleSparesSerializer(serializers.ModelSerializer):
    """Serializer for VehicleSpares model."""
    
    # Read-only fields to show computed properties
    vehicle_display = serializers.ReadOnlyField()
    is_urgent = serializers.ReadOnlyField()
    full_part_description = serializers.ReadOnlyField()
    
    class Meta:
        model = VehicleSpares
        fields = '__all__'
        read_only_fields = ['id', 'created_at', 'updated_at']


class VehicleTyresRimsSerializer(serializers.ModelSerializer):
    """Serializer for VehicleTyresRims model."""
    
    # Read-only fields to show computed properties
    tyre_size_display = serializers.ReadOnlyField()
    is_urgent = serializers.ReadOnlyField()
    
    class Meta:
        model = VehicleTyresRims
        fields = '__all__'
        read_only_fields = ['id', 'created_at', 'updated_at']


class UserSerializer(serializers.ModelSerializer):
    """Simple User serializer for nested representation."""
    
    class Meta:
        model = User
        fields = ['id', 'username', 'email', 'first_name', 'last_name']
        read_only_fields = ['id']


class QuoteListSerializer(serializers.ModelSerializer):
    """Serializer for Quote model used in product request listings."""
    
    seller_id = UserSerializer(read_only=True)
    is_expired = serializers.ReadOnlyField()
    is_valid = serializers.ReadOnlyField()
    
    class Meta:
        model = Quote
        fields = [
            'quote_id', 'seller_id', 'total_amount', 'currency',
            'delivery_cost', 'installation_cost', 'estimated_delivery_days',
            'status', 'valid_until', 'is_expired', 'is_valid',
            'created_at', 'updated_at'
        ]


class ProductRequestListSerializer(serializers.ModelSerializer):
    """Serializer for listing ProductRequest with basic information."""
    
    buyer_id = UserSerializer(read_only=True)
    quotes = QuoteListSerializer(many=True, read_only=True)
    is_expired = serializers.ReadOnlyField()
    is_urgent = serializers.ReadOnlyField()
    tyres_rims_summary = serializers.ReadOnlyField()
    vehicle_spares_summary = serializers.ReadOnlyField()
    consumer_electronics_summary = serializers.ReadOnlyField()
    
    class Meta:
        model = ProductRequest
        fields = [
            'request_id', 'buyer_id', 'category', 'title', 'description',
            'quantity', 'condition_preference', 'max_budget', 'currency',
            'urgency_timeline', 'status', 'view_count', 'is_expired', 'is_urgent',
            'tyres_rims_summary', 'vehicle_spares_summary', 'consumer_electronics_summary',
            'quotes', 'created_at', 'updated_at'
        ]


class ProductRequestDetailSerializer(serializers.ModelSerializer):
    """Detailed serializer for ProductRequest with all nested data."""
    
    buyer_id = UserSerializer(read_only=True)
    consumer_electronics = ConsumerElectronicsSerializer(read_only=True)
    vehicle_spares = VehicleSparesSerializer(read_only=True)
    vehicle_tyres_rims = VehicleTyresRimsSerializer(read_only=True)
    
    # Read-only computed properties
    is_expired = serializers.ReadOnlyField()
    is_urgent = serializers.ReadOnlyField()
    tyres_rims_summary = serializers.ReadOnlyField()
    vehicle_spares_summary = serializers.ReadOnlyField()
    consumer_electronics_summary = serializers.ReadOnlyField()
    
    class Meta:
        model = ProductRequest
        fields = '__all__'
        read_only_fields = ['request_id', 'created_at', 'updated_at', 'view_count', 'expiry_date']


class ProductRequestCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating new ProductRequest with nested category data."""
    
    # Optional nested data for creating related models
    consumer_electronics_data = ConsumerElectronicsSerializer(required=False, write_only=True)
    vehicle_spares_data = VehicleSparesSerializer(required=False, write_only=True)
    vehicle_tyres_rims_data = VehicleTyresRimsSerializer(required=False, write_only=True)
    
    # Override JSON fields to handle strings from multipart form data
    product_specifications = JSONStringField()
    buyer_location = JSONStringField()
    product_images = JSONStringField(required=False, allow_null=True)
    
    # User ID field for setting the buyer
    buyer_id = serializers.PrimaryKeyRelatedField(queryset=User.objects.all())
    
    class Meta:
        model = ProductRequest
        fields = [
            'buyer_id', 'category', 'title', 'description', 'product_specifications',
            'quantity', 'condition_preference', 'max_budget', 'currency',
            'buyer_location', 'max_travel_distance', 'urgency_timeline',
            'product_images', 'vin_photo_url', 'terms_accepted', 'contact_consent',
            'consumer_electronics_data', 'vehicle_spares_data', 'vehicle_tyres_rims_data'
        ]
        
    def to_internal_value(self, data):
        """Custom parsing to handle JSON strings for nested data fields.
        Also handles when data is already a dictionary."""
        # Handle multipart form data where nested objects come as JSON strings
        # or regular JSON data where they're already dictionaries
        json_fields = [
            'vehicle_spares_data', 'consumer_electronics_data', 'vehicle_tyres_rims_data',
            'buyer_location', 'product_specifications'
        ]
        
        for field in json_fields:
            if field in data:
                # If it's already a dict, leave it as is
                if isinstance(data[field], dict):
                    continue
                    
                # Handle string inputs (from form data)
                if isinstance(data[field], str):
                    try:
                        # Handle empty JSON objects
                        if data[field].strip() in ['{}', '']:
                            data[field] = {}
                        else:
                            data[field] = json.loads(data[field])
                    except (json.JSONDecodeError, ValueError) as e:
                        raise serializers.ValidationError({
                            field: f"Invalid JSON format: {str(e)}"
                        })
        
        return super().to_internal_value(data)
    
    def validate(self, data):
        """Validate that the category matches the provided nested data."""
        category = data.get('category')
        
        # Check that category-specific data is provided
        if category == 'ELECTRONICS' and 'consumer_electronics_data' not in data:
            raise serializers.ValidationError(
                "consumer_electronics_data is required for ELECTRONICS category"
            )
        elif category == 'VEHICLE_SPARES' and 'vehicle_spares_data' not in data:
            raise serializers.ValidationError(
                "vehicle_spares_data is required for VEHICLE_SPARES category"
            )
        elif category == 'TYRES_RIMS' and 'vehicle_tyres_rims_data' not in data:
            raise serializers.ValidationError(
                "vehicle_tyres_rims_data is required for TYRES_RIMS category"
            )
            
        # Ensure only relevant category data is provided
        category_data_fields = {
            'ELECTRONICS': 'consumer_electronics_data',
            'VEHICLE_SPARES': 'vehicle_spares_data',
            'TYRES_RIMS': 'vehicle_tyres_rims_data'
        }
        
        for cat, field in category_data_fields.items():
            if category != cat and field in data:
                raise serializers.ValidationError(
                    f"{field} should not be provided for {category} category"
                )
        
        return data
    
    def create(self, validated_data):
        """Create ProductRequest with nested category data."""
        
        # Extract nested data
        consumer_electronics_data = validated_data.pop('consumer_electronics_data', None)
        vehicle_spares_data = validated_data.pop('vehicle_spares_data', None)
        vehicle_tyres_rims_data = validated_data.pop('vehicle_tyres_rims_data', None)
        
        # Create the main ProductRequest
        product_request = ProductRequest.objects.create(**validated_data)
        
        # Create and link the category-specific model
        if consumer_electronics_data:
            consumer_electronics = ConsumerElectronics.objects.create(**consumer_electronics_data)
            product_request.consumer_electronics = consumer_electronics
            
        elif vehicle_spares_data:
            vehicle_spares = VehicleSpares.objects.create(**vehicle_spares_data)
            product_request.vehicle_spares = vehicle_spares
            
        elif vehicle_tyres_rims_data:
            vehicle_tyres_rims = VehicleTyresRims.objects.create(**vehicle_tyres_rims_data)
            product_request.vehicle_tyres_rims = vehicle_tyres_rims
        
        # Save the product request with the linked category model
        product_request.save()
        
        # Synchronize the data between nested model and JSON specifications
        if product_request.consumer_electronics:
            product_request.sync_consumer_electronics_data()
        elif product_request.vehicle_spares:
            product_request.sync_vehicle_spares_data()
        elif product_request.vehicle_tyres_rims:
            product_request.sync_vehicle_tyres_rims_data()
            
        product_request.save()
        
        return product_request


class RequestImageSerializer(serializers.ModelSerializer):
    """Serializer for RequestImage model."""
    
    class Meta:
        model = RequestImage
        fields = '__all__'
        read_only_fields = ['id']


class RequestSpecificationSerializer(serializers.ModelSerializer):
    """Serializer for RequestSpecification model."""
    
    class Meta:
        model = RequestSpecification
        fields = '__all__'
        

class RequestMessageSerializer(serializers.ModelSerializer):
    """Serializer for RequestMessage model."""
    
    sender = UserSerializer(read_only=True)
    is_read = serializers.ReadOnlyField()
    
    class Meta:
        model = RequestMessage
        fields = '__all__'
        read_only_fields = ['created_at', 'read_at']


class RequestWatchlistSerializer(serializers.ModelSerializer):
    """Serializer for RequestWatchlist model."""
    
    user = UserSerializer(read_only=True)
    
    class Meta:
        model = RequestWatchlist
        fields = '__all__'
        read_only_fields = ['created_at']


class OrderListSerializer(serializers.ModelSerializer):
    """Serializer for listing orders with basic information."""
    
    buyer_id = UserSerializer(read_only=True)
    seller_id = UserSerializer(read_only=True)
    status_display = serializers.CharField(source='get_status_display', read_only=True)
    payment_status_display = serializers.CharField(source='get_payment_status_display', read_only=True)
    is_completed = serializers.ReadOnlyField()
    is_active = serializers.ReadOnlyField()
    can_cancel = serializers.ReadOnlyField()
    
    # Request and quote basic info
    request_title = serializers.CharField(source='request_id.title', read_only=True)
    request_category = serializers.CharField(source='request_id.category', read_only=True)
    quote_total = serializers.DecimalField(source='quote_id.total_amount', max_digits=12, decimal_places=2, read_only=True)
    
    class Meta:
        model = Order
        fields = [
            'order_id', 'order_number', 'status', 'status_display',
            'payment_status', 'payment_status_display', 'buyer_id', 'seller_id',
            'total_amount', 'delivery_cost', 'installation_cost', 'currency',
            'payment_method', 'payment_date', 'estimated_delivery_date',
            'actual_delivery_date', 'tracking_number', 'is_completed',
            'is_active', 'can_cancel', 'request_title', 'request_category',
            'quote_total', 'created_at', 'updated_at'
        ]


class OrderDetailSerializer(serializers.ModelSerializer):
    """Detailed serializer for individual order retrieval."""
    
    buyer_id = UserSerializer(read_only=True)
    seller_id = UserSerializer(read_only=True)
    status_display = serializers.CharField(source='get_status_display', read_only=True)
    payment_status_display = serializers.CharField(source='get_payment_status_display', read_only=True)
    is_completed = serializers.ReadOnlyField()
    is_active = serializers.ReadOnlyField()
    can_cancel = serializers.ReadOnlyField()
    
    # Nested request information
    request_info = serializers.SerializerMethodField()
    quote_info = serializers.SerializerMethodField()
    
    class Meta:
        model = Order
        fields = [
            'order_id', 'order_number', 'status', 'status_display',
            'payment_status', 'payment_status_display', 'buyer_id', 'seller_id',
            'total_amount', 'delivery_cost', 'installation_cost', 'currency',
            'payment_method', 'payment_reference', 'payment_date',
            'delivery_address', 'estimated_delivery_date', 'actual_delivery_date',
            'tracking_number', 'special_instructions', 'notes',
            'is_completed', 'is_active', 'can_cancel',
            'request_info', 'quote_info', 'created_at', 'updated_at'
        ]
    
    def get_request_info(self, obj):
        """Get detailed request information."""
        request = obj.request_id
        return {
            'request_id': str(request.request_id),
            'title': request.title,
            'description': request.description,
            'category': request.category,
            'quantity': request.quantity,
            'condition_preference': request.condition_preference,
            'urgency_timeline': request.urgency_timeline,
            'tyres_rims_summary': request.tyres_rims_summary,
            'vehicle_spares_summary': request.vehicle_spares_summary,
            'consumer_electronics_summary': request.consumer_electronics_summary,
        }
    
    def get_quote_info(self, obj):
        """Get detailed quote information."""
        quote = obj.quote_id
        if quote:
            return {
                'quote_id': str(quote.quote_id),
                'total_amount': quote.total_amount,
                'delivery_cost': quote.delivery_cost,
                'installation_cost': quote.installation_cost,
                'currency': quote.currency,
                'estimated_delivery_days': quote.estimated_delivery_days,
                'terms_conditions': quote.terms_conditions,
                'seller_notes': quote.seller_notes,
                'warranty_info': quote.warranty_info,
                'valid_until': quote.valid_until,
                'created_at': quote.created_at,
            }
        return None


class OrderCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating new orders."""
    
    class Meta:
        model = Order
        fields = [
            'request_id', 'quote_id', 'delivery_address',
            'special_instructions'
        ]
    
    def validate(self, attrs):
        """Validate order creation data."""
        request_obj = attrs['request_id']
        quote_obj = attrs['quote_id']
        
        # Verify the quote belongs to the request
        if quote_obj.request_id != request_obj:
            raise serializers.ValidationError(
                "The quote does not belong to the specified request."
            )
        
        # Verify the quote is still valid
        if not quote_obj.is_valid:
            raise serializers.ValidationError(
                "The quote is no longer valid or has expired."
            )
        
        # Verify the request is still active
        if not request_obj.can_receive_quotes():
            raise serializers.ValidationError(
                "The request is no longer active."
            )
        
        return attrs
    
    def create(self, validated_data):
        """Create a new order from validated data."""
        request_obj = validated_data['request_id']
        quote_obj = validated_data['quote_id']
        
        # Get buyer and seller from the request context
        buyer = self.context['request'].user
        seller = quote_obj.seller_id
        
        # Create the order with data from the quote
        order = Order.objects.create(
            request_id=request_obj,
            quote_id=quote_obj,
            buyer_id=buyer,
            seller_id=seller,
            total_amount=quote_obj.total_amount,
            delivery_cost=quote_obj.delivery_cost,
            installation_cost=quote_obj.installation_cost,
            currency=quote_obj.currency,
            delivery_address=validated_data.get('delivery_address'),
            special_instructions=validated_data.get('special_instructions'),
            # Calculate estimated delivery date
            estimated_delivery_date=(
                timezone.now() + 
                timezone.timedelta(days=quote_obj.estimated_delivery_days or 7)
            ) if quote_obj.estimated_delivery_days else None
        )
        
        # Update quote status to accepted
        quote_obj.status = 'ACCEPTED'
        quote_obj.save(update_fields=['status'])
        
        # Close the request to prevent more quotes
        request_obj.close_request()
        
        return order


class OrderUpdateSerializer(serializers.ModelSerializer):
    """Serializer for updating order information."""
    
    class Meta:
        model = Order
        fields = [
            'delivery_address', 'special_instructions', 'tracking_number'
        ]


class OrderStatusUpdateSerializer(serializers.Serializer):
    """Serializer for updating order status."""
    
    status = serializers.ChoiceField(choices=Order.STATUS_CHOICES)
    payment_method = serializers.CharField(max_length=50, required=False)
    payment_reference = serializers.CharField(max_length=100, required=False)
    tracking_number = serializers.CharField(max_length=100, required=False)
    reason = serializers.CharField(max_length=500, required=False)
    
    def validate_status(self, value):
        """Validate status transition."""
        order = self.context['order']
        current_status = order.status
        
        # Define valid status transitions
        valid_transitions = {
            'PENDING': ['PAID', 'CANCELLED'],
            'PAID': ['PROCESSING', 'CANCELLED'],
            'PROCESSING': ['SHIPPED', 'CANCELLED'],
            'SHIPPED': ['DELIVERED', 'CANCELLED'],
            'DELIVERED': ['COMPLETED'],
            'COMPLETED': [],  # Final state
            'CANCELLED': [],  # Final state
            'REFUNDED': [],   # Final state
        }
        
        if value not in valid_transitions.get(current_status, []):
            raise serializers.ValidationError(
                f"Cannot transition from {current_status} to {value}"
            )
        
        return value


# For backward compatibility with existing code
OrderSerializer = OrderDetailSerializer
