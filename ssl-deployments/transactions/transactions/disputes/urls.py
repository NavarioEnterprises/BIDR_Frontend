"""
URL configuration for the Dispute API.

This module defines the URL patterns for the Dispute API endpoints,
including routes for listing, retrieving, creating, and updating disputes.
"""

from django.urls import path, include
from rest_framework.routers import DefaultRouter

from .views import DisputeViewSet

# Set the application namespace
app_name = 'disputes'

# Create a router and register our viewsets with it
router = DefaultRouter()
router.register(r'disputes', DisputeViewSet, basename='dispute')

# The API URLs are determined automatically by the router
urlpatterns = [
    path('', include(router.urls)),
]

# Additional URL patterns for specific endpoints
urlpatterns += [
    # Any additional custom URLs can be added here if needed
]