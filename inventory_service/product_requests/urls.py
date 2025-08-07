"""
URLs for Product Requests app.
"""

from django.urls import path, include
from rest_framework.routers import DefaultRouter

router = DefaultRouter()
# router.register(r'requests', views.ProductRequestViewSet)

urlpatterns = [
    path('', include(router.urls)),
]
