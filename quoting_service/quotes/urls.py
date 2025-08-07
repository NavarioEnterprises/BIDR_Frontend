"""
URLs for Quotes app.
"""

from django.urls import path, include
from rest_framework.routers import DefaultRouter

router = DefaultRouter()
# router.register(r'quotes', views.QuoteViewSet)

urlpatterns = [
    path('', include(router.urls)),
]
