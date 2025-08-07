"""
Admin interface for Products app.
"""

from django.contrib import admin
from django.utils.html import format_html
from .models import (
    Product, ProductImage, ProductAttribute, ProductVariant, 
    InventoryLog, ProductReview
)


class ProductImageInline(admin.TabularInline):
    model = ProductImage
    extra = 0
    fields = ('image', 'alt_text', 'is_primary', 'sort_order')
    ordering = ['sort_order']


class ProductAttributeInline(admin.TabularInline):
    model = ProductAttribute
    extra = 0
    fields = ('attribute', 'value')
    
    def get_queryset(self, request):
        return super().get_queryset(request).select_related('attribute')


class ProductVariantInline(admin.TabularInline):
    model = ProductVariant
    extra = 0
    fields = (
        'name', 'sku', 'price', 'quantity_available', 
        'quantity_reserved', 'status'
    )
    readonly_fields = ('id', 'created_at', 'updated_at')


@admin.register(Product)
class ProductAdmin(admin.ModelAdmin):
    list_display = (
        'name', 'category', 'sku', 'base_price', 'quantity_available', 
        'quantity_reserved', 'status', 'is_featured', 'created_at'
    )
    list_filter = (
        'status', 'is_featured', 'is_digital', 'requires_shipping', 
        'track_inventory', 'category', 'supplier'
    )
    search_fields = ('name', 'sku', 'barcode', 'description')
    prepopulated_fields = {'slug': ('name',)}
    readonly_fields = (
        'id', 'view_count', 'request_count', 'created_at', 'updated_at',
        'available_quantity', 'is_in_stock', 'is_low_stock'
    )
    
    fieldsets = (
        ('Basic Information', {
            'fields': ('name', 'slug', 'description', 'short_description', 'category')
        }),
        ('Product Identification', {
            'fields': ('sku', 'barcode')
        }),
        ('Pricing', {
            'fields': ('base_price', 'compare_price', 'cost_price')
        }),
        ('Inventory', {
            'fields': (
                'track_inventory', 'quantity_available', 'quantity_reserved', 
                'low_stock_threshold', 'available_quantity', 'is_in_stock', 'is_low_stock'
            )
        }),
        ('Physical Properties', {
            'fields': (
                'weight', 'dimensions_length', 'dimensions_width', 
                'dimensions_height'
            ),
            'classes': ('collapse',)
        }),
        ('Status & Visibility', {
            'fields': ('status', 'is_featured', 'is_digital', 'requires_shipping')
        }),
        ('SEO', {
            'fields': ('meta_title', 'meta_description'),
            'classes': ('collapse',)
        }),
        ('Supplier Information', {
            'fields': ('supplier', 'supplier_sku'),
            'classes': ('collapse',)
        }),
        ('Analytics', {
            'fields': ('view_count', 'request_count'),
            'classes': ('collapse',)
        }),
        ('Location', {
            'fields': (
                'address_line_1', 'address_line_2', 'city', 'state_province',
                'postal_code', 'country', 'location', 'search_radius'
            ),
            'classes': ('collapse',)
        }),
        ('Metadata', {
            'fields': ('tags', 'notes', 'metadata'),
            'classes': ('collapse',)
        }),
        ('System Information', {
            'fields': ('id', 'created_at', 'updated_at'),
            'classes': ('collapse',)
        })
    )
    
    inlines = [ProductImageInline, ProductAttributeInline, ProductVariantInline]
    
    def get_queryset(self, request):
        return super().get_queryset(request).select_related(
            'category', 'supplier'
        ).prefetch_related('images', 'variants')
    
    def available_quantity(self, obj):
        return obj.available_quantity
    available_quantity.short_description = 'Available Qty'
    
    def is_in_stock(self, obj):
        return '✓' if obj.is_in_stock else '✗'
    is_in_stock.short_description = 'In Stock'
    is_in_stock.boolean = True
    
    def is_low_stock(self, obj):
        return '⚠' if obj.is_low_stock else ''
    is_low_stock.short_description = 'Low Stock Warning'


@admin.register(ProductImage)
class ProductImageAdmin(admin.ModelAdmin):
    list_display = ('product', 'alt_text', 'is_primary', 'sort_order')
    list_filter = ('is_primary', 'product__category')
    search_fields = ('product__name', 'alt_text')
    
    def get_queryset(self, request):
        return super().get_queryset(request).select_related('product')


@admin.register(ProductVariant)
class ProductVariantAdmin(admin.ModelAdmin):
    list_display = (
        'parent_product', 'name', 'sku', 'effective_price', 
        'quantity_available', 'quantity_reserved', 'status'
    )
    list_filter = ('status', 'parent_product__category')
    search_fields = ('name', 'sku', 'parent_product__name')
    readonly_fields = (
        'id', 'effective_price', 'available_quantity', 'is_in_stock',
        'created_at', 'updated_at'
    )
    
    fieldsets = (
        ('Basic Information', {
            'fields': ('parent_product', 'name', 'sku')
        }),
        ('Pricing', {
            'fields': ('price', 'compare_price', 'cost_price', 'effective_price')
        }),
        ('Inventory', {
            'fields': (
                'quantity_available', 'quantity_reserved', 
                'available_quantity', 'is_in_stock'
            )
        }),
        ('Physical Properties', {
            'fields': ('weight',)
        }),
        ('Status', {
            'fields': ('status',)
        }),
        ('Location', {
            'fields': (
                'address_line_1', 'address_line_2', 'city', 'state_province',
                'postal_code', 'country', 'location', 'search_radius'
            ),
            'classes': ('collapse',)
        }),
        ('Metadata', {
            'fields': ('tags', 'notes', 'metadata'),
            'classes': ('collapse',)
        }),
        ('System Information', {
            'fields': ('id', 'created_at', 'updated_at'),
            'classes': ('collapse',)
        })
    )
    
    def get_queryset(self, request):
        return super().get_queryset(request).select_related('parent_product')


@admin.register(InventoryLog)
class InventoryLogAdmin(admin.ModelAdmin):
    list_display = (
        'product', 'variant', 'quantity_change', 'new_quantity', 
        'reason', 'created_at', 'created_by'
    )
    list_filter = ('created_at', 'product__category', 'created_by')
    search_fields = ('product__name', 'variant__name', 'reason')
    readonly_fields = ('created_at',)
    
    def get_queryset(self, request):
        return super().get_queryset(request).select_related(
            'product', 'variant', 'created_by'
        )
    
    def has_change_permission(self, request, obj=None):
        return False  # Inventory logs should not be editable


@admin.register(ProductReview)
class ProductReviewAdmin(admin.ModelAdmin):
    list_display = (
        'product', 'reviewer', 'rating', 'title', 'status', 
        'is_verified_purchase', 'created_at'
    )
    list_filter = (
        'rating', 'status', 'is_verified_purchase', 
        'product__category', 'created_at'
    )
    search_fields = ('product__name', 'reviewer__username', 'title', 'review_text')
    readonly_fields = (
        'id', 'helpful_count', 'not_helpful_count', 'helpfulness_ratio',
        'created_at', 'updated_at'
    )
    
    fieldsets = (
        ('Review Information', {
            'fields': ('product', 'reviewer', 'rating', 'title', 'review_text')
        }),
        ('Status', {
            'fields': ('status', 'is_verified_purchase')
        }),
        ('Helpfulness', {
            'fields': ('helpful_count', 'not_helpful_count', 'helpfulness_ratio'),
            'classes': ('collapse',)
        }),
        ('Location', {
            'fields': (
                'address_line_1', 'address_line_2', 'city', 'state_province',
                'postal_code', 'country', 'location', 'search_radius'
            ),
            'classes': ('collapse',)
        }),
        ('Metadata', {
            'fields': ('tags', 'notes', 'metadata'),
            'classes': ('collapse',)
        }),
        ('System Information', {
            'fields': ('id', 'created_at', 'updated_at'),
            'classes': ('collapse',)
        })
    )
    
    def get_queryset(self, request):
        return super().get_queryset(request).select_related(
            'product', 'reviewer'
        )
