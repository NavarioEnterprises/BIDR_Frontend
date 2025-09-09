from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import TransactionViewSet, TransactionLogViewSet

router = DefaultRouter()
router.register(r'transactions', TransactionViewSet, basename='transaction')
router.register(r'logs', TransactionLogViewSet, basename='transaction-log')

urlpatterns = [
    path('', include(router.urls)),
]
