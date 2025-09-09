from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import PaymentGatewayViewSet, health_check, service_info

router = DefaultRouter()
router.register(r'payment-gateways', PaymentGatewayViewSet, basename='payment-gateway')

urlpatterns = [
    path('', include(router.urls)),
    path('health/', health_check, name='health-check'),
    path('info/', service_info, name='service-info'),
]
