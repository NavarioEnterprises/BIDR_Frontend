"""
Serializers for Categories app.
"""

from rest_framework import serializers
from .models import Category, CategoryAttribute


class CategoryAttributeSerializer(serializers.ModelSerializer):
    """Serializer for category attributes."""
    
    display_label = serializers.ReadOnlyField()
    
    class Meta:
        model = CategoryAttribute
        fields = [
            'id', 'category', 'name', 'attribute_type', 'is_required',
            'is_filterable', 'is_searchable', 'show_in_listing',
            'label', 'display_label', 'help_text', 'placeholder', 'sort_order',
            'min_value', 'max_value', 'min_length', 'max_length',
            'regex_pattern', 'choices', 'default_value',
            'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at', 'display_label']


class CategorySerializer(serializers.ModelSerializer):
    """Serializer for categories with hierarchical support."""
    
    children = serializers.SerializerMethodField()
    attributes = CategoryAttributeSerializer(many=True, read_only=True)
    full_name = serializers.ReadOnlyField()
    breadcrumbs = serializers.ReadOnlyField()
    product_count = serializers.SerializerMethodField()
    
    class Meta:
        model = Category
        fields = [
            'id', 'name', 'slug', 'description', 'parent', 'children',
            'icon', 'image', 'color', 'sort_order',
            'status', 'is_featured', 'show_in_menu',
            'meta_title', 'meta_description', 'commission_rate',
            'full_name', 'breadcrumbs', 'attributes', 'product_count',
            'tags', 'notes', 'metadata',
            'created_at', 'updated_at'
        ]
        read_only_fields = [
            'id', 'children', 'full_name', 'breadcrumbs', 
            'product_count', 'created_at', 'updated_at'
        ]
    
    def get_children(self, obj):
        """Get active child categories."""
        children = obj.get_active_children()
        return CategorySerializer(children, many=True, context=self.context).data
    
    def get_product_count(self, obj):
        """Get count of products in this category."""
        return obj.get_product_count(include_subcategories=True)


class CategoryTreeSerializer(serializers.ModelSerializer):
    """Simplified serializer for category tree display."""
    
    children = serializers.SerializerMethodField()
    
    class Meta:
        model = Category
        fields = [
            'id', 'name', 'slug', 'icon', 'color', 
            'sort_order', 'children'
        ]
    
    def get_children(self, obj):
        """Get active child categories."""
        children = obj.get_active_children()
        return CategoryTreeSerializer(children, many=True).data
