from django.urls import path, include
from rest_framework.routers import DefaultRouter

from .views import (
    AuthenticationLogViewSet,
    SecurityEventViewSet,
    LoginSessionViewSet,
    AuditTrailViewSet,
    SuspiciousActivityViewSet
)

router = DefaultRouter()
router.register(r'auth-logs', AuthenticationLogViewSet, basename='auth-logs')
router.register(r'security-events', SecurityEventViewSet, basename='security-events')
router.register(r'login-sessions', LoginSessionViewSet, basename='login-sessions')
router.register(r'audit-trail', AuditTrailViewSet, basename='audit-trail')
router.register(r'suspicious-activities', SuspiciousActivityViewSet, basename='suspicious-activities')

urlpatterns = [
    path('', include(router.urls)),
]
