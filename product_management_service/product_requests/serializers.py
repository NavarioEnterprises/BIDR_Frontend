"""
Serializers for Product Request models.
"""

from rest_framework import serializers
from django.contrib.auth.models import User
from .models import (
    ConsumerElectronics, VehicleSpares, VehicleTyresRims, 
    ProductRequest, RequestImage, RequestSpecification, 
    RequestMessage, RequestWatchlist, RequestTemplate
)


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


class ProductRequestListSerializer(serializers.ModelSerializer):
    """Serializer for listing ProductRequest with basic information."""
    
    buyer_id = UserSerializer(read_only=True)
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
            'created_at', 'updated_at'
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
