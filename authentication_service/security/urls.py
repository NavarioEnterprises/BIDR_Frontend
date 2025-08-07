from django.urls import path, include
from rest_framework.routers import DefaultRouter

from .views import (
    SecurityPolicyViewSet,
    SecurityAuditLogViewSet,
    BlockedIPViewSet,
    SecurityQuestionViewSet,
    UserSecurityQuestionViewSet,
    TwoFactorMethodViewSet,
    APIKeyViewSet
)


router = DefaultRouter()
router.register(r'policies', SecurityPolicyViewSet)
router.register(r'audit-logs', SecurityAuditLogViewSet)
router.register(r'blocked-ips', BlockedIPViewSet)
router.register(r'security-questions', SecurityQuestionViewSet)
router.register(r'user-security-questions', UserSecurityQuestionViewSet)
router.register(r'two-factor-methods', TwoFactorMethodViewSet)
router.register(r'api-keys', APIKeyViewSet)

urlpatterns = [
    path('', include(router.urls)),
]

app_name = 'security'
