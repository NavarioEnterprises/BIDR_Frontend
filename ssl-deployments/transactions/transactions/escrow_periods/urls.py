"""
URL configuration for the EscrowPeriod API.

This module defines the URL patterns for the EscrowPeriod API endpoints,
including routes for listing, retrieving, creating, and updating escrow periods.
"""

from django.urls import path, include
from rest_framework.routers import DefaultRouter

from .views import EscrowPeriodViewSet

# Set the application namespace
app_name = 'escrow_periods'

# Create a router and register our viewsets with it
router = DefaultRouter()
router.register(r'escrow-periods', EscrowPeriodViewSet, basename='escrow-period')

# The API URLs are determined automatically by the router
urlpatterns = [
    path('', include(router.urls)),
]

# Additional URL patterns for specific endpoints
urlpatterns += [
    # Any additional custom URLs can be added here if needed
]