"""
URLs for Product Requests app.
"""

from django.urls import path, include
from rest_framework.routers import DefaultRouter
from . import views

# Create router and register viewsets
router = DefaultRouter()
router.register(r'requests', views.ProductRequestViewSet, basename='productrequest')
router.register(r'consumer-electronics', views.ConsumerElectronicsViewSet, basename='consumerelectronics')
router.register(r'vehicle-spares', views.VehicleSparesViewSet, basename='vehiclespares')
router.register(r'tyres-rims', views.VehicleTyresRimsViewSet, basename='vehicletyresrims')
router.register(r'messages', views.RequestMessageViewSet, basename='requestmessage')
router.register(r'watchlist', views.RequestWatchlistViewSet, basename='requestwatchlist')
router.register(r'orders', views.OrderViewSet, basename='order')

urlpatterns = [
    path('', include(router.urls)),
    
    # Collection Code endpoints
    path('collection-codes/get-or-create/', views.get_or_create_collection_code, name='get_or_create_collection_code'),
    path('collection-codes/confirm/', views.confirm_collection_code, name='confirm_collection_code'),
    path('collection-codes/status/<str:order_number>/', views.collection_code_status, name='collection_code_status'),
]
