"""
URL configuration for chat_core app.
"""

from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import UserProfileViewSet, SystemConfigViewSet

router = DefaultRouter()
router.register(r'profiles', UserProfileViewSet, basename='userprofile')
router.register(r'config', SystemConfigViewSet, basename='systemconfig')

app_name = 'chat_core'

urlpatterns = [
    path('api/v1/core/', include(router.urls)),
]
