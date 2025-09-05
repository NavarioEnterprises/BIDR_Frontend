"""
BIDR Sessions URLs

URL configuration for session management endpoints.
"""
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import (
    UserSessionViewSet, TrustedDeviceViewSet, 
    SessionSecurityEventViewSet, SessionActivityViewSet
)

router = DefaultRouter()
router.register(r'sessions', UserSessionViewSet, basename='sessions')
router.register(r'trusted-devices', TrustedDeviceViewSet, basename='trusted-devices')
router.register(r'security-events', SessionSecurityEventViewSet, basename='security-events')
router.register(r'activities', SessionActivityViewSet, basename='activities')

app_name = 'user_sessions'

urlpatterns = [
    path('', include(router.urls)),
]
