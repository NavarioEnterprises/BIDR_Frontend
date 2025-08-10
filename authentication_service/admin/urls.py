from django.urls import path, include
from rest_framework.routers import DefaultRouter

from .views import AdminProfileViewSet, AdminActivityLogViewSet, AdminNotificationViewSet


router = DefaultRouter()
router.register(r'profile', AdminProfileViewSet, basename='admin-profile')
router.register(r'activity-logs', AdminActivityLogViewSet, basename='admin-activity-log')
router.register(r'notifications', AdminNotificationViewSet, basename='admin-notification')

urlpatterns = [
    path('', include(router.urls)),
]