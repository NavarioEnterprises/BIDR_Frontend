"""
Views for Products app.
"""

from rest_framework import viewsets, permissions, filters, status
from rest_framework.decorators import action
from rest_framework.response import Response
from django_filters.rest_framework import DjangoFilterBackend
from drf_yasg.utils import swagger_auto_schema
from drf_yasg import openapi
from django.db.models import Q, Avg, F
from django.db import models
from decimal import Decimal

from .models import (
    Product, ProductImage, ProductAttribute, ProductVariant, 
    InventoryLog, ProductReview
)
from .serializers import (
    ProductListSerializer, ProductDetailSerializer, ProductCreateUpdateSerializer,
    ProductImageSerializer, ProductAttributeSerializer, ProductVariantSerializer,
    InventoryLogSerializer, ProductReviewSerializer, InventoryAdjustmentSerializer
)


class ProductViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing products.
    
    Provides CRUD operations for products with different serializers
    for list and detail views.
    """
    queryset = Product.objects.select_related('category', 'supplier').prefetch_related(
        'images', 'attribute_values__attribute', 'variants', 'reviews'
    )
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = [
        'status', 'category', 'is_featured', 'is_digital', 'requires_shipping',
        'supplier', 'track_inventory'
    ]
    search_fields = ['name', 'description', 'short_description', 'sku', 'barcode']
    ordering_fields = [
        'name', 'base_price', 'created_at', 'updated_at', 'view_count',
        'request_count', 'quantity_available'
    ]
    ordering = ['-created_at']
    lookup_field = 'slug'
    
    def get_serializer_class(self):
        """Return appropriate serializer based on action."""
        if self.action == 'list':
            return ProductListSerializer
        elif self.action in ['create', 'update', 'partial_update']:
            return ProductCreateUpdateSerializer
        return ProductDetailSerializer
    
    def get_queryset(self):
        """Filter queryset based on user permissions."""
        queryset = self.queryset
        
        # Non-authenticated users only see active products
        if not self.request.user.is_authenticated:
            queryset = queryset.filter(status='active')
        
        # Filter by price range if provided
        min_price = self.request.query_params.get('min_price')
        max_price = self.request.query_params.get('max_price')
        
        if min_price:
            try:
                queryset = queryset.filter(base_price__gte=Decimal(min_price))
            except (ValueError, TypeError):
                pass
        
        if max_price:
            try:
                queryset = queryset.filter(base_price__lte=Decimal(max_price))
            except (ValueError, TypeError):
                pass
        
        # Filter by stock status
        in_stock = self.request.query_params.get('in_stock')
        if in_stock and in_stock.lower() == 'true':
            queryset = queryset.filter(
                Q(track_inventory=False) | 
                Q(quantity_available__gt=0, track_inventory=True)
            )
        
        return queryset
    
    def retrieve(self, request, *args, **kwargs):
        """Retrieve a product and increment view count."""
        instance = self.get_object()
        
        # Increment view count
        Product.objects.filter(pk=instance.pk).update(
            view_count=instance.view_count + 1
        )
        
        serializer = self.get_serializer(instance)
        return Response(serializer.data)
    
    @swagger_auto_schema(
        operation_description="Get products with low stock",
        responses={200: ProductListSerializer(many=True)}
    )
    @action(detail=False, methods=['get'])
    def low_stock(self, request):
        """Get products with low stock."""
        products = self.get_queryset().filter(
            track_inventory=True,
            quantity_available__lte=models.F('low_stock_threshold')
        )
        serializer = ProductListSerializer(
            products, many=True, context={'request': request}
        )
        return Response(serializer.data)
    
    @swagger_auto_schema(
        operation_description="Get featured products",
        responses={200: ProductListSerializer(many=True)}
    )
    @action(detail=False, methods=['get'])
    def featured(self, request):
        """Get featured products."""
        products = self.get_queryset().filter(
            is_featured=True, status='active'
        )
        serializer = ProductListSerializer(
            products, many=True, context={'request': request}
        )
        return Response(serializer.data)
    
    @swagger_auto_schema(
        method='post',
        operation_description="Adjust product inventory",
        request_body=InventoryAdjustmentSerializer,
        responses={
            200: openapi.Response(
                description="Success",
                schema=openapi.Schema(
                    type=openapi.TYPE_OBJECT,
                    properties={
                        'message': openapi.Schema(type=openapi.TYPE_STRING),
                        'new_quantity': openapi.Schema(type=openapi.TYPE_INTEGER),
                    }
                )
            )
        }
    )
    @action(detail=True, methods=['post'], permission_classes=[permissions.IsAuthenticated])
    def adjust_inventory(self, request, slug=None):
        """Adjust product inventory levels."""
        product = self.get_object()
        serializer = InventoryAdjustmentSerializer(data=request.data)
        
        if serializer.is_valid():
            quantity_change = serializer.validated_data['quantity_change']
            reason = serializer.validated_data['reason']
            
            # Perform the adjustment
            old_quantity = product.quantity_available
            product.adjust_inventory(quantity_change, reason)
            
            # Create log entry with user
            InventoryLog.objects.filter(
                product=product, reason=reason
            ).update(created_by=request.user)
            
            return Response({
                'message': f'Inventory adjusted by {quantity_change:+d}',
                'old_quantity': old_quantity,
                'new_quantity': product.quantity_available
            })
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
    @swagger_auto_schema(
        operation_description="Get product inventory logs",
        responses={200: InventoryLogSerializer(many=True)}
    )
    @action(detail=True, methods=['get'])
    def inventory_logs(self, request, slug=None):
        """Get inventory change logs for a product."""
        product = self.get_object()
        logs = product.inventory_logs.all()[:20]  # Last 20 logs
        serializer = InventoryLogSerializer(logs, many=True)
        return Response(serializer.data)
    
    @swagger_auto_schema(
        operation_description="Get product reviews",
        responses={200: ProductReviewSerializer(many=True)}
    )
    @action(detail=True, methods=['get'])
    def reviews(self, request, slug=None):
        """Get reviews for a product."""
        product = self.get_object()
        reviews = product.reviews.filter(status='active').order_by('-created_at')
        serializer = ProductReviewSerializer(reviews, many=True)
        return Response(serializer.data)
    
    @swagger_auto_schema(
        method='post',
        operation_description="Add a review for a product",
        request_body=ProductReviewSerializer,
        responses={201: ProductReviewSerializer}
    )
    @action(detail=True, methods=['post'], permission_classes=[permissions.IsAuthenticated])
    def add_review(self, request, slug=None):
        """Add a review for a product."""
        product = self.get_object()
        serializer = ProductReviewSerializer(data=request.data)
        
        if serializer.is_valid():
            # Check if user already reviewed this product
            if ProductReview.objects.filter(
                product=product, reviewer=request.user
            ).exists():
                return Response(
                    {'error': 'You have already reviewed this product.'},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            serializer.save(product=product, reviewer=request.user)
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class ProductImageViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing product images.
    """
    queryset = ProductImage.objects.all()
    serializer_class = ProductImageSerializer
    permission_classes = [permissions.IsAuthenticated]
    filter_backends = [DjangoFilterBackend, filters.OrderingFilter]
    filterset_fields = ['product', 'is_primary']
    ordering_fields = ['sort_order', 'id']
    ordering = ['sort_order', 'id']


class ProductVariantViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing product variants.
    """
    queryset = ProductVariant.objects.select_related('parent_product')
    serializer_class = ProductVariantSerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['parent_product', 'status']
    search_fields = ['name', 'sku']
    ordering_fields = ['name', 'price', 'created_at']
    ordering = ['name']


class ProductReviewViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing product reviews.
    """
    queryset = ProductReview.objects.select_related('product', 'reviewer')
    serializer_class = ProductReviewSerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]
    filter_backends = [DjangoFilterBackend, filters.OrderingFilter]
    filterset_fields = ['product', 'rating', 'status', 'is_verified_purchase']
    ordering_fields = ['rating', 'created_at', 'helpful_count']
    ordering = ['-created_at']
    
    def get_queryset(self):
        """Filter reviews based on user permissions."""
        queryset = self.queryset
        
        # Non-authenticated users only see active reviews
        if not self.request.user.is_authenticated:
            queryset = queryset.filter(status='active')
        
        return queryset
    
    def perform_create(self, serializer):
        """Set the reviewer to the current user."""
        serializer.save(reviewer=self.request.user)
    
    @swagger_auto_schema(
        method='post',
        operation_description="Mark review as helpful",
        responses={
            200: openapi.Response(
                description="Success",
                schema=openapi.Schema(
                    type=openapi.TYPE_OBJECT,
                    properties={
                        'message': openapi.Schema(type=openapi.TYPE_STRING),
                        'helpful_count': openapi.Schema(type=openapi.TYPE_INTEGER),
                    }
                )
            )
        }
    )
    @action(detail=True, methods=['post'], permission_classes=[permissions.IsAuthenticated])
    def mark_helpful(self, request, pk=None):
        """Mark a review as helpful."""
        review = self.get_object()
        review.helpful_count += 1
        review.save(update_fields=['helpful_count'])
        
        return Response({
            'message': 'Review marked as helpful',
            'helpful_count': review.helpful_count
        })
    
    @swagger_auto_schema(
        method='post',
        operation_description="Mark review as not helpful",
        responses={
            200: openapi.Response(
                description="Success",
                schema=openapi.Schema(
                    type=openapi.TYPE_OBJECT,
                    properties={
                        'message': openapi.Schema(type=openapi.TYPE_STRING),
                        'not_helpful_count': openapi.Schema(type=openapi.TYPE_INTEGER),
                    }
                )
            )
        }
    )
    @action(detail=True, methods=['post'], permission_classes=[permissions.IsAuthenticated])
    def mark_not_helpful(self, request, pk=None):
        """Mark a review as not helpful."""
        review = self.get_object()
        review.not_helpful_count += 1
        review.save(update_fields=['not_helpful_count'])
        
        return Response({
            'message': 'Review marked as not helpful',
            'not_helpful_count': review.not_helpful_count
        })
