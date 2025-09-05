"""
URLs for Categories app.
"""

from django.urls import path, include
from rest_framework.routers import DefaultRouter
from . import views

router = DefaultRouter()
router.register(r'categories', views.CategoryViewSet)
router.register(r'attributes', views.CategoryAttributeViewSet)

urlpatterns = [
    path('', include(router.urls)),
]
