"""
Product serializers for the BIDR Inventory Service.
"""

from rest_framework import serializers
from decimal import Decimal
from django.contrib.auth.models import User
from .models import (
    Product, ProductImage, ProductAttribute, ProductVariant, 
    InventoryLog, ProductReview
)
from categories.models import Category, CategoryAttribute


class ProductImageSerializer(serializers.ModelSerializer):
    """
    Serializer for product images.
    """
    class Meta:
        model = ProductImage
        fields = [
            'id', 'image', 'alt_text', 'is_primary', 'sort_order'
        ]
        read_only_fields = ['id']


class ProductAttributeSerializer(serializers.ModelSerializer):
    """
    Serializer for product attribute values.
    """
    attribute_name = serializers.CharField(source='attribute.name', read_only=True)
    attribute_label = serializers.CharField(source='attribute.display_label', read_only=True)
    attribute_type = serializers.CharField(source='attribute.attribute_type', read_only=True)
    
    class Meta:
        model = ProductAttribute
        fields = [
            'id', 'attribute', 'attribute_name', 'attribute_label', 
            'attribute_type', 'value'
        ]
        read_only_fields = ['id', 'attribute_name', 'attribute_label', 'attribute_type']


class ProductVariantSerializer(serializers.ModelSerializer):
    """
    Serializer for product variants.
    """
    effective_price = serializers.ReadOnlyField()
    available_quantity = serializers.ReadOnlyField()
    is_in_stock = serializers.ReadOnlyField()
    
    class Meta:
        model = ProductVariant
        fields = [
            'id', 'name', 'sku', 'price', 'compare_price', 'cost_price',
            'quantity_available', 'quantity_reserved', 'weight', 'status',
            'effective_price', 'available_quantity', 'is_in_stock',
            'created_at', 'updated_at'
        ]
        read_only_fields = [
            'id', 'effective_price', 'available_quantity', 'is_in_stock',
            'created_at', 'updated_at'
        ]


class InventoryLogSerializer(serializers.ModelSerializer):
    """
    Serializer for inventory logs.
    """
    created_by_username = serializers.CharField(source='created_by.username', read_only=True)
    
    class Meta:
        model = InventoryLog
        fields = [
            'id', 'quantity_change', 'new_quantity', 'reason', 
            'created_at', 'created_by', 'created_by_username'
        ]
        read_only_fields = ['id', 'created_at', 'created_by_username']


class ProductReviewSerializer(serializers.ModelSerializer):
    """
    Serializer for product reviews.
    """
    reviewer_username = serializers.CharField(source='reviewer.username', read_only=True)
    helpfulness_ratio = serializers.ReadOnlyField()
    
    class Meta:
        model = ProductReview
        fields = [
            'id', 'reviewer', 'reviewer_username', 'rating', 'title', 
            'review_text', 'status', 'helpful_count', 'not_helpful_count',
            'helpfulness_ratio', 'is_verified_purchase', 'created_at', 'updated_at'
        ]
        read_only_fields = [
            'id', 'reviewer_username', 'helpfulness_ratio', 'helpful_count',
            'not_helpful_count', 'created_at', 'updated_at'
        ]


class ProductListSerializer(serializers.ModelSerializer):
    """
    Simplified serializer for product listings.
    """
    category_name = serializers.CharField(source='category.name', read_only=True)
    category_slug = serializers.CharField(source='category.slug', read_only=True)
    primary_image = serializers.SerializerMethodField()
    available_quantity = serializers.ReadOnlyField()
    is_in_stock = serializers.ReadOnlyField()
    is_low_stock = serializers.ReadOnlyField()
    discount_percentage = serializers.ReadOnlyField()
    
    class Meta:
        model = Product
        fields = [
            'id', 'name', 'slug', 'short_description', 'category', 'category_name',
            'category_slug', 'sku', 'base_price', 'compare_price', 'primary_image',
            'status', 'is_featured', 'is_digital', 'requires_shipping',
            'available_quantity', 'is_in_stock', 'is_low_stock', 'discount_percentage',
            'view_count', 'request_count', 'created_at', 'updated_at'
        ]
        read_only_fields = [
            'id', 'category_name', 'category_slug', 'primary_image',
            'available_quantity', 'is_in_stock', 'is_low_stock', 'discount_percentage',
            'view_count', 'request_count', 'created_at', 'updated_at'
        ]
    
    def get_primary_image(self, obj):
        """Get the primary image URL if available."""
        primary_image = obj.images.filter(is_primary=True).first()
        if primary_image:
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(primary_image.image.url)
            return primary_image.image.url
        return None


class ProductDetailSerializer(serializers.ModelSerializer):
    """
    Detailed serializer for individual product views.
    """
    category_name = serializers.CharField(source='category.name', read_only=True)
    category_slug = serializers.CharField(source='category.slug', read_only=True)
    category_breadcrumbs = serializers.CharField(source='category.breadcrumbs', read_only=True)
    supplier_username = serializers.CharField(source='supplier.username', read_only=True)
    
    # Related objects
    images = ProductImageSerializer(many=True, read_only=True)
    attribute_values = ProductAttributeSerializer(many=True, read_only=True)
    variants = ProductVariantSerializer(many=True, read_only=True)
    
    # Computed properties
    available_quantity = serializers.ReadOnlyField()
    is_in_stock = serializers.ReadOnlyField()
    is_low_stock = serializers.ReadOnlyField()
    discount_percentage = serializers.ReadOnlyField()
    profit_margin = serializers.ReadOnlyField()
    
    # Review statistics
    review_count = serializers.SerializerMethodField()
    average_rating = serializers.SerializerMethodField()
    
    class Meta:
        model = Product
        fields = [
            'id', 'name', 'slug', 'description', 'short_description',
            'category', 'category_name', 'category_slug', 'category_breadcrumbs',
            'sku', 'barcode', 'base_price', 'compare_price', 'cost_price',
            'track_inventory', 'quantity_available', 'quantity_reserved',
            'low_stock_threshold', 'weight', 'dimensions_length',
            'dimensions_width', 'dimensions_height', 'status', 'is_featured',
            'is_digital', 'requires_shipping', 'meta_title', 'meta_description',
            'supplier', 'supplier_username', 'supplier_sku', 'view_count',
            'request_count', 'available_quantity', 'is_in_stock', 'is_low_stock',
            'discount_percentage', 'profit_margin', 'images', 'attribute_values',
            'variants', 'review_count', 'average_rating', 'tags', 'notes',
            'metadata', 'created_at', 'updated_at'
        ]
        read_only_fields = [
            'id', 'category_name', 'category_slug', 'category_breadcrumbs',
            'supplier_username', 'available_quantity', 'is_in_stock', 'is_low_stock',
            'discount_percentage', 'profit_margin', 'images', 'attribute_values',
            'variants', 'review_count', 'average_rating', 'view_count',
            'request_count', 'created_at', 'updated_at'
        ]
    
    def get_review_count(self, obj):
        """Get the number of approved reviews."""
        return obj.reviews.filter(status='active').count()
    
    def get_average_rating(self, obj):
        """Get the average rating from approved reviews."""
        reviews = obj.reviews.filter(status='active')
        if reviews.exists():
            total_rating = sum(review.rating for review in reviews)
            return round(total_rating / reviews.count(), 2)
        return None


class ProductCreateUpdateSerializer(serializers.ModelSerializer):
    """
    Serializer for creating and updating products.
    """
    class Meta:
        model = Product
        fields = [
            'name', 'slug', 'description', 'short_description', 'category',
            'sku', 'barcode', 'base_price', 'compare_price', 'cost_price',
            'track_inventory', 'quantity_available', 'quantity_reserved',
            'low_stock_threshold', 'weight', 'dimensions_length',
            'dimensions_width', 'dimensions_height', 'status', 'is_featured',
            'is_digital', 'requires_shipping', 'meta_title', 'meta_description',
            'supplier', 'supplier_sku', 'tags', 'notes', 'metadata'
        ]
    
    def validate_base_price(self, value):
        """Validate base price is positive."""
        if value <= 0:
            raise serializers.ValidationError("Base price must be greater than 0.")
        return value
    
    def validate_compare_price(self, value):
        """Validate compare price if provided."""
        if value is not None and value <= 0:
            raise serializers.ValidationError("Compare price must be greater than 0.")
        return value
    
    def validate_cost_price(self, value):
        """Validate cost price if provided."""
        if value is not None and value < 0:
            raise serializers.ValidationError("Cost price cannot be negative.")
        return value
    
    def validate(self, data):
        """Cross-field validation."""
        base_price = data.get('base_price')
        compare_price = data.get('compare_price')
        cost_price = data.get('cost_price')
        
        # Compare price should be higher than base price for discount calculation
        if compare_price and base_price and compare_price <= base_price:
            raise serializers.ValidationError({
                'compare_price': 'Compare price should be higher than base price.'
            })
        
        # Cost price should typically be lower than base price
        if cost_price and base_price and cost_price >= base_price:
            # This is a warning, not an error - sometimes cost might be higher
            pass
        
        return data


class InventoryAdjustmentSerializer(serializers.Serializer):
    """
    Serializer for inventory adjustments.
    """
    quantity_change = serializers.IntegerField()
    reason = serializers.CharField(max_length=200)
    
    def validate_quantity_change(self, value):
        """Validate quantity change is not zero."""
        if value == 0:
            raise serializers.ValidationError("Quantity change cannot be zero.")
        return value
