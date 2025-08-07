"""
BIDR Analytics URLs

URL configuration for analytics endpoints.
"""
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import (
    AuthenticationMetricViewSet, UserBehaviorAnalyticsViewSet,
    SystemPerformanceMetricViewSet, AuthenticationTrendViewSet,
    AnalyticsReportViewSet
)

router = DefaultRouter()
router.register(r'metrics', AuthenticationMetricViewSet, basename='metrics')
router.register(r'user-behavior', UserBehaviorAnalyticsViewSet, basename='user-behavior')
router.register(r'performance', SystemPerformanceMetricViewSet, basename='performance')
router.register(r'trends', AuthenticationTrendViewSet, basename='trends')
router.register(r'reports', AnalyticsReportViewSet, basename='reports')

app_name = 'analytics'

urlpatterns = [
    path('', include(router.urls)),
]
