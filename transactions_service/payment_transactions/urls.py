"""
URL configuration for the PaymentTransaction API.

This module defines the URL patterns for the PaymentTransaction API endpoints,
including routes for listing, retrieving, creating, updating, and processing payments.
"""

from django.urls import path, include
from rest_framework.routers import DefaultRouter

from .views import PaymentTransactionViewSet

# Set the application namespace
app_name = 'payment_transactions'

# Create a router and register our viewsets with it
router = DefaultRouter()
router.register(r'payment-transactions', PaymentTransactionViewSet, basename='payment-transaction')

# The API URLs are determined automatically by the router
urlpatterns = [
    path('', include(router.urls)),
]

# Additional URL patterns for specific endpoints
urlpatterns += [
    # Any additional custom URLs can be added here if needed
]