from django.urls import path, include
from rest_framework.routers import DefaultRouter

from .views import BuyerViewSet, BuyerAddressViewSet


router = DefaultRouter()
router.register(r'buyers', BuyerViewSet, basename='buyers')
router.register(r'addresses', BuyerAddressViewSet, basename='buyer-addresses')

urlpatterns = [
    path('', include(router.urls)),
]