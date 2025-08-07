"""
URLs for Products app.
"""

from django.urls import path, include
from rest_framework.routers import DefaultRouter
from . import views

router = DefaultRouter()
router.register(r'products', views.ProductViewSet)
router.register(r'images', views.ProductImageViewSet)
router.register(r'variants', views.ProductVariantViewSet)
router.register(r'reviews', views.ProductReviewViewSet)

urlpatterns = [
    path('', include(router.urls)),
]
