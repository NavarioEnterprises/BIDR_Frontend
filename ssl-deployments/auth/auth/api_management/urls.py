"""
BIDR API Management URLs

URL configuration for API management endpoints.
"""
from django.urls import path, include
from rest_framework.routers import DefaultRouter

from .views import (
    APIKeyViewSet, APIScopeViewSet, APIRequestViewSet,
    RateLimitBucketViewSet, APIKeyUsageQuotaViewSet, APIKeyBulkActionViewSet
)

router = DefaultRouter()
router.register(r'api-keys', APIKeyViewSet, basename='api-keys')
router.register(r'scopes', APIScopeViewSet, basename='scopes')
router.register(r'requests', APIRequestViewSet, basename='requests')
router.register(r'rate-limits', RateLimitBucketViewSet, basename='rate-limits')
router.register(r'quotas', APIKeyUsageQuotaViewSet, basename='quotas')
router.register(r'bulk-actions', APIKeyBulkActionViewSet, basename='bulk-actions')

app_name = 'api_management'

urlpatterns = [
    path('', include(router.urls)),
]
