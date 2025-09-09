from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import PaymentViewSet, RefundRequestViewSet, paystack_webhook

router = DefaultRouter()
router.register(r'payments', PaymentViewSet, basename='payment')
router.register(r'refunds', RefundRequestViewSet, basename='refund')

urlpatterns = [
    path('', include(router.urls)),
    path('paystack/webhook/', paystack_webhook, name='paystack-webhook'),
]
