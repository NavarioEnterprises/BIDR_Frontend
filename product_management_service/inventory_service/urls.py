"""
URL configuration for BIDR Inventory Service.

This service handles product requests, quotes, transactions, and ratings
for the BIDR platform.
"""

from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static
from rest_framework import permissions
from drf_yasg.views import get_schema_view
from drf_yasg import openapi

# API documentation schema
schema_view = get_schema_view(
    openapi.Info(
        title="BIDR Inventory Service API",
        default_version='v1',
        description="A comprehensive inventory management system for handling product requests, quotes, transactions, and ratings.",
        terms_of_service="https://www.bidr.com/terms/",
        contact=openapi.Contact(email="contact@bidr.com"),
        license=openapi.License(name="BSD License"),
    ),
    public=True,
    permission_classes=(permissions.AllowAny,),
)

urlpatterns = [
    # Admin interface
    path('admin/', admin.site.urls),
    
    # API documentation
    path('swagger/', schema_view.with_ui('swagger', cache_timeout=0), name='schema-swagger-ui'),
    path('redoc/', schema_view.with_ui('redoc', cache_timeout=0), name='schema-redoc'),
    path('swagger.json', schema_view.without_ui(cache_timeout=0), name='schema-json'),
    
    # Authentication endpoints
    path('api/', include('authentication.urls')),
    
    # API endpoints
    path('api/v1/categories/', include('categories.urls')),
    path('api/v1/requests/', include('product_requests.urls')),
    path('api/v1/quotes/', include('quotes.urls')),
    path('api/v1/transactions/', include('transactions.urls')),
    path('api/v1/ratings/', include('ratings.urls')),
    path('api/v1/analytics/', include('analytics.urls')),
]

# Serve media files in development
if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
    urlpatterns += static(settings.STATIC_URL, document_root=settings.STATIC_ROOT)
