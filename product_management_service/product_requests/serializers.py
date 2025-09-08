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
        # Debug logging to see what we're receiving
        print(f"JSONStringField received data: {repr(data)} (type: {type(data)})")
        
        # If it's already a dict, use it directly
        if isinstance(data, dict):
            return data
            
        # Handle string inputs
        if isinstance(data, str):
            try:
                # Handle empty JSON objects
                if data.strip() in ['{}', '']:
                    return {}
                
                # First try to parse as regular JSON
                try:
                    parsed_data = json.loads(data)
                    print(f"Successfully parsed JSON: {parsed_data}")
                    return parsed_data
                except json.JSONDecodeError:
                    # If that fails, try to fix single quotes by replacing them with double quotes
                    # This is a simple fix for Python dict strings sent from Flutter
                    fixed_data = data.replace("'", '"')
                    print(f"Attempting to fix single quotes: {repr(fixed_data)}")
                    parsed_data = json.loads(fixed_data)
                    print(f"Successfully parsed fixed JSON: {parsed_data}")
                    return parsed_data
                    
            except (json.JSONDecodeError, ValueError) as e:
                print(f"JSON parsing failed for data: {repr(data)}")
                print(f"Error: {str(e)}")
                self.fail('invalid', message=f'Invalid JSON format: {str(e)}')
        
        print(f"Falling back to super() for data: {repr(data)}")
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
    
    # Since buyer_id is a UUID field, serialize it as UUID
    buyer_id = serializers.UUIDField(read_only=True)
    quotes = serializers.SerializerMethodField()
    is_expired = serializers.ReadOnlyField()
    is_urgent = serializers.ReadOnlyField()
    tyres_rims_summary = serializers.ReadOnlyField()
    vehicle_spares_summary = serializers.ReadOnlyField()
    consumer_electronics_summary = serializers.ReadOnlyField()
    
    def get_quotes(self, obj):
        """Return only valid (non-expired) quotes."""
        valid_quotes = [
            quote for quote in obj.quotes.all() 
            if quote.is_valid and not quote.is_expired
        ]
        return QuoteListSerializer(valid_quotes, many=True).data

    class Meta:
        model = ProductRequest
        fields = [
            'request_id', 'buyer_id', 'category', 'title', 'description',
            'quantity', 'condition_preference', 'max_budget', 'currency',
            'urgency_timeline', 'status', 'view_count', 'is_expired', 'is_urgent',
            'tyres_rims_summary', 'vehicle_spares_summary', 'consumer_electronics_summary',
            'quotes', 'is_flagged', 'flags', 'created_at', 'updated_at'
        ]


class ProductRequestDetailSerializer(serializers.ModelSerializer):
    """Detailed serializer for ProductRequest with all nested data."""
    
    # Since buyer_id is a UUID field, serialize it as UUID
    buyer_id = serializers.UUIDField(read_only=True)
    consumer_electronics = ConsumerElectronicsSerializer(read_only=True)
    vehicle_spares = VehicleSparesSerializer(read_only=True)
    vehicle_tyres_rims = VehicleTyresRimsSerializer(read_only=True)
    quotes = serializers.SerializerMethodField()
    
    # Read-only computed properties
    is_expired = serializers.ReadOnlyField()
    is_urgent = serializers.ReadOnlyField()
    tyres_rims_summary = serializers.ReadOnlyField()
    vehicle_spares_summary = serializers.ReadOnlyField()
    consumer_electronics_summary = serializers.ReadOnlyField()
    
    def get_quotes(self, obj):
        """Return only valid (non-expired) quotes."""
        valid_quotes = [
            quote for quote in obj.quotes.all() 
            if quote.is_valid and not quote.is_expired
        ]
        return QuoteListSerializer(valid_quotes, many=True).data
    
    class Meta:
        model = ProductRequest
        fields = '__all__'
        read_only_fields = ['request_id', 'created_at', 'updated_at', 'view_count', 'expiry_date', 'is_flagged', 'flags']


class ProductRequestCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating new ProductRequest with nested category data."""
    
    # Optional nested data for creating related models - handled as JSON strings from multipart form
    consumer_electronics_data = JSONStringField(required=False, write_only=True)
    vehicle_spares_data = JSONStringField(required=False, write_only=True)
    vehicle_tyres_rims_data = JSONStringField(required=False, write_only=True)
    
    # Override JSON fields to handle strings from multipart form data
    product_specifications = JSONStringField()
    buyer_location = JSONStringField()
    product_images = JSONStringField(required=False, allow_null=True)
    
    # Image upload fields - these handle actual file uploads
    images = serializers.ListField(
        child=serializers.ImageField(max_length=None, use_url=True),
        required=False,
        write_only=True,
        help_text="Upload images for the product request"
    )
    vin_images = serializers.ListField(
        child=serializers.ImageField(max_length=None, use_url=True),
        required=False,
        write_only=True,
        help_text="Upload VIN images for vehicle requests"
    )
    
    # User ID field for setting the buyer - allow UUID strings
    buyer_id = serializers.UUIDField(required=False)
    auth_user_uid = serializers.UUIDField(required=True)
    
    class Meta:
        model = ProductRequest
        fields = [
            'buyer_id', 'auth_user_uid', 'category', 'title', 'description', 'product_specifications',
            'quantity', 'condition_preference', 'max_budget', 'currency',
            'buyer_location', 'max_travel_distance', 'urgency_timeline',
            'product_images', 'vin_photo_url', 'terms_accepted', 'contact_consent',
            'consumer_electronics_data', 'vehicle_spares_data', 'vehicle_tyres_rims_data',
            'images', 'vin_images'
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
        
        # Create a mutable copy of data to avoid QueryDict immutability issues
        if hasattr(data, '_mutable'):
            # This is a QueryDict, make it mutable
            data._mutable = True
        else:
            # Create a mutable copy for other dict-like objects
            data = data.copy()
        
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
        
        # Extract image files
        uploaded_images = validated_data.pop('images', [])
        vin_images = validated_data.pop('vin_images', [])
        
        # Handle buyer_id: use auth_user_uid as buyer_id since it's the actual UUID
        auth_user_uid = validated_data.get('auth_user_uid')
        if auth_user_uid:
            validated_data['buyer_id'] = auth_user_uid
        
        # Process uploaded images and save them
        from core.image_utils import save_uploaded_images, validate_image_file
        import logging
        
        logger = logging.getLogger(__name__)
        saved_image_urls = []
        vin_image_url = None
        
        # Process regular product images
        if uploaded_images:
            # Validate images first
            valid_images = []
            for image in uploaded_images:
                if validate_image_file(image):
                    valid_images.append(image)
                else:
                    logger.warning(f"Invalid image file skipped: {getattr(image, 'name', 'unknown')}")
            
            if valid_images:
                saved_image_urls = save_uploaded_images(valid_images, 'product_requests')
                logger.info(f"Saved {len(saved_image_urls)} product images")
        
        # Process VIN images (usually just one)
        if vin_images:
            # Validate VIN images
            valid_vin_images = []
            for image in vin_images:
                if validate_image_file(image):
                    valid_vin_images.append(image)
                else:
                    logger.warning(f"Invalid VIN image file skipped: {getattr(image, 'name', 'unknown')}")
            
            if valid_vin_images:
                vin_urls = save_uploaded_images(valid_vin_images, 'vin_images')
                if vin_urls:
                    vin_image_url = vin_urls[0]  # Use first VIN image
                    logger.info(f"Saved VIN image: {vin_image_url}")
        
        # Set image data in validated_data
        if saved_image_urls:
            validated_data['product_images'] = saved_image_urls
        
        if vin_image_url:
            validated_data['vin_photo_url'] = vin_image_url
        
        # Create the main ProductRequest
        product_request = ProductRequest.objects.create(**validated_data)
        
        # Create and link the category-specific model
        if consumer_electronics_data:
            # Add saved images to electronics data
            if saved_image_urls:
                consumer_electronics_data['product_images'] = saved_image_urls
            consumer_electronics = ConsumerElectronics.objects.create(**consumer_electronics_data)
            product_request.consumer_electronics = consumer_electronics
            
        elif vehicle_spares_data:
            # Filter only fields that exist in VehicleSpares model
            vehicle_spares_fields = {
                'vehicle_make', 'vehicle_model', 'vehicle_year', 'vehicle_type',
                'engine_size', 'vin_number', 'part_name', 'part_category', 'part_number',
                'quantity', 'condition_preference', 'urgency', 'description',
                'compatible_models', 'preferred_brand', 'avoid_brands',
                'installation_required', 'warranty_required', 'max_budget', 'currency',
                'product_images', 'vin_photo', 'location_info'
            }
            filtered_vehicle_data = {
                k: v for k, v in vehicle_spares_data.items() 
                if k in vehicle_spares_fields
            }
            
            # Add saved images to vehicle spares data
            if saved_image_urls:
                filtered_vehicle_data['product_images'] = saved_image_urls
            if vin_image_url:
                filtered_vehicle_data['vin_photo'] = vin_image_url
            
            logger.info(f"Filtered vehicle spares data: {filtered_vehicle_data}")
            vehicle_spares = VehicleSpares.objects.create(**filtered_vehicle_data)
            product_request.vehicle_spares = vehicle_spares
            
        elif vehicle_tyres_rims_data:
            # Filter to only include fields that exist in the VehicleTyresRims model
            vehicle_tyres_rims_fields = {
                'tyre_width', 'sidewall_profile', 'wheel_rim_diameter', 'select_tyres_rims',
                'quantity', 'urgency', 'description', 'vehicle_type', 'pitch_circle_diameter',
                'preferred_brand', 'tyre_construction_type', 'balancing_required',
                'tyre_rotation_required', 'fitment_required', 'product_images'
            }
            filtered_tyres_rims_data = {
                k: v for k, v in vehicle_tyres_rims_data.items() 
                if k in vehicle_tyres_rims_fields
            }
            
            # Add saved images to tyres/rims data
            if saved_image_urls:
                filtered_tyres_rims_data['product_images'] = saved_image_urls
            
            logger.info(f"Filtered vehicle tyres/rims data: {filtered_tyres_rims_data}")
            vehicle_tyres_rims = VehicleTyresRims.objects.create(**filtered_tyres_rims_data)
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
    
    # Since buyer_id and seller_id are UUID fields, serialize them as UUIDs
    buyer_id = serializers.UUIDField(read_only=True)
    seller_id = serializers.UUIDField(read_only=True)
    status_display = serializers.CharField(source='get_status_display', read_only=True)
    payment_status_display = serializers.CharField(source='get_payment_status_display', read_only=True)
    is_completed = serializers.ReadOnlyField()
    is_active = serializers.ReadOnlyField()
    can_cancel = serializers.ReadOnlyField()
    
    # Request and quote basic info
    request_id = serializers.UUIDField(source='request_id.request_id', read_only=True)
    request_title = serializers.CharField(source='request_id.title', read_only=True)
    request_category = serializers.CharField(source='request_id.category', read_only=True)
    quote_total = serializers.DecimalField(source='quote_id.total_amount', max_digits=12, decimal_places=2, read_only=True)
    
    class Meta:
        model = Order
        fields = [
            'order_id', 'order_number', 'request_id', 'status', 'status_display',
            'payment_status', 'payment_status_display', 'buyer_id', 'seller_id',
            'total_amount', 'delivery_cost', 'installation_cost', 'currency',
            'payment_method', 'payment_date', 'estimated_delivery_date',
            'actual_delivery_date', 'tracking_number', 'is_completed',
            'is_active', 'can_cancel', 'request_title', 'request_category',
            'quote_total', 'created_at', 'updated_at'
        ]


class OrderDetailSerializer(serializers.ModelSerializer):
    """Detailed serializer for individual order retrieval."""
    
    # Since buyer_id and seller_id are UUID fields, serialize them as UUIDs
    buyer_id = serializers.UUIDField(read_only=True)
    seller_id = serializers.UUIDField(read_only=True)
    status_display = serializers.CharField(source='get_status_display', read_only=True)
    payment_status_display = serializers.CharField(source='get_payment_status_display', read_only=True)
    is_completed = serializers.ReadOnlyField()
    is_active = serializers.ReadOnlyField()
    can_cancel = serializers.ReadOnlyField()
    
    # Request and quote information
    request_id = serializers.UUIDField(source='request_id.request_id', read_only=True)
    request_info = serializers.SerializerMethodField()
    quote_info = serializers.SerializerMethodField()
    
    class Meta:
        model = Order
        fields = [
            'order_id', 'order_number', 'request_id', 'status', 'status_display',
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
            'order_id', 'request_id', 'quote_id', 'delivery_address',
            'special_instructions'
        ]
        read_only_fields = ['order_id']

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

        # Verify the request allows order creation
        if request_obj.status not in ['ACTIVE', 'PENDING']:
            raise serializers.ValidationError(
                f"Cannot create order for request with status: {request_obj.status}"
            )

        # Check if an order already exists for this request
        if Order.objects.filter(request_id=request_obj).exists():
            raise serializers.ValidationError(
                "An order has already been created for this request."
            )

        return attrs

    def create(self, validated_data):
        """Create a new order from validated data."""
        print("=== DEBUG CREATE ORDER ===")
        print(f"validated_data keys: {list(validated_data.keys())}")
        print(f"validated_data: {validated_data}")
        print("=== END DEBUG ===")

        request_obj = validated_data['request_id']
        quote_obj = validated_data['quote_id']

        # Get buyer and seller from the related objects, not from validated_data
        buyer_id = request_obj.buyer_id or request_obj.auth_user_uid  # Get buyer from the ProductRequest, fallback to auth_user_uid
        # Extract UUID from seller User object
        # If it's a placeholder user with pattern "seller_{uuid}", extract the UUID
        if hasattr(quote_obj.seller_id, 'username') and quote_obj.seller_id.username.startswith('seller_'):
            seller_id = quote_obj.seller_id.username.replace('seller_', '')
        elif hasattr(quote_obj.seller_id, 'id'):
            seller_id = quote_obj.seller_id.id
        else:
            seller_id = quote_obj.seller_id

        print(f"buyer_id from request: {buyer_id}")
        print(f"buyer_id from auth_user_uid: {request_obj.auth_user_uid}")
        print(f"seller_id from quote: {seller_id}")
        print(f"seller_id username: {getattr(quote_obj.seller_id, 'username', 'N/A')}")

        # Create the order
        order = Order.objects.create(
            request_id=request_obj,
            quote_id=quote_obj,
            buyer_id=buyer_id,
            seller_id=seller_id,
            total_amount=quote_obj.total_amount,
            delivery_cost=quote_obj.delivery_cost or 0,
            installation_cost=quote_obj.installation_cost or 0,
            currency=quote_obj.currency,
            delivery_address=validated_data.get('delivery_address'),
            special_instructions=validated_data.get('special_instructions'),
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
