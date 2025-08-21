from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import EscrowAccountViewSet

router = DefaultRouter()
router.register(r'escrow', EscrowAccountViewSet, basename='escrow')

urlpatterns = [
    path('', include(router.urls)),
]
