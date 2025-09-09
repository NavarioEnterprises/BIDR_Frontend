"""
URL configuration for product_management_service project.

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/5.1/topics/http/urls/
"""

from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static
from django.http import JsonResponse
from django.utils import timezone
from rest_framework import permissions
from drf_yasg.views import get_schema_view
from drf_yasg import openapi
from django_prometheus.exports import ExportToDjangoView

# API documentation schema
schema_view = get_schema_view(
    openapi.Info(
        title="BIDR Product Management Service API",
        default_version='v1',
        description="A comprehensive product management system for handling product requests, quotes, transactions, categories, ratings, and analytics.",
        terms_of_service="https://www.bidr.com/terms/",
        contact=openapi.Contact(email="contact@bidr.com"),
        license=openapi.License(name="BSD License"),
    ),
    public=True,
    permission_classes=(permissions.AllowAny,),
)

# Health check endpoint
def health_check(request):
    return JsonResponse({
        'status': 'healthy',
        'service': 'product-management-service',
        'version': '1.0.0',
        'timestamp': timezone.now().isoformat()
    })

urlpatterns = [
    # Admin interface
    path('admin/', admin.site.urls),
    
    # Health check
    # Metrics endpoint for Prometheus
    path('metrics', ExportToDjangoView, name='prometheus-django-metrics'),
    path('health/', health_check, name='health-check'),
    
    # API documentation
    path('', schema_view.with_ui('swagger', cache_timeout=0), name='schema-swagger-ui'),
    path('swagger/', schema_view.with_ui('swagger', cache_timeout=0), name='schema-swagger-ui-alt'),
    path('redoc/', schema_view.with_ui('redoc', cache_timeout=0), name='schema-redoc'),
    path('swagger.json', schema_view.without_ui(cache_timeout=0), name='schema-json'),
    
    # Authentication endpoints
    path('api/', include('authentication.urls')),
    
    # Core API endpoints - v1
    path('api/v1/categories/', include('categories.urls')),
    path('api/v1/product-requests/', include('product_requests.urls')),
    path('api/v1/quotes/', include('quotes.urls')),
    path('api/v1/transactions/', include('transactions.urls')),
    path('api/v1/ratings/', include('ratings.urls')),
    path('api/v1/analytics/', include('analytics.urls')),
    
    # Legacy inventory service URLs (for backward compatibility)
    path('inventory/', include('inventory_service.urls')),
]

# Serve media files in development
if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
    urlpatterns += static(settings.STATIC_URL, document_root=settings.STATIC_ROOT)
