"""
Views for Categories app.
"""

from rest_framework import viewsets, permissions, filters
from django_filters.rest_framework import DjangoFilterBackend
from drf_yasg.utils import swagger_auto_schema
from drf_yasg import openapi
from .models import Category, CategoryAttribute
from .serializers import CategorySerializer, CategoryAttributeSerializer


class CategoryViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing product categories.
    
    Provides CRUD operations for hierarchical product categories.
    """
    queryset = Category.objects.all()
    serializer_class = CategorySerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['status', 'is_featured', 'show_in_menu', 'parent']
    search_fields = ['name', 'description']
    ordering_fields = ['name', 'sort_order', 'created_at']
    ordering = ['sort_order', 'name']
    
    def get_queryset(self):
        return Category.objects.select_related('parent').prefetch_related('children')
    
    @swagger_auto_schema(
        operation_description="Get category tree with all descendants",
        responses={200: CategorySerializer(many=True)}
    )
    def list(self, request, *args, **kwargs):
        """List categories with optional filtering and search."""
        return super().list(request, *args, **kwargs)


class CategoryAttributeViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing category attributes.
    
    Defines what attributes products in each category can have.
    """
    queryset = CategoryAttribute.objects.all()
    serializer_class = CategoryAttributeSerializer
    permission_classes = [permissions.IsAuthenticated]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = [
        'category', 'attribute_type', 'is_required', 
        'is_filterable', 'is_searchable'
    ]
    search_fields = ['name', 'label']
    ordering_fields = ['name', 'sort_order', 'created_at']
    ordering = ['sort_order', 'name']
    
    def get_queryset(self):
        return CategoryAttribute.objects.select_related('category')
