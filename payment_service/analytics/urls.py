from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import PaymentAnalyticsViewSet

router = DefaultRouter()
router.register(r'analytics', PaymentAnalyticsViewSet, basename='analytics')

urlpatterns = [
    path('', include(router.urls)),
]
