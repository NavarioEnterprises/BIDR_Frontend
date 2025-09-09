from django.urls import path, include
from rest_framework.routers import DefaultRouter
from . import views

router = DefaultRouter()
router.register(r'statistics', views.NotificationStatisticsViewSet, basename='statistics')
router.register(r'channel-analytics', views.ChannelAnalyticsViewSet, basename='channel-analytics')
router.register(r'user-engagement', views.UserEngagementMetricsViewSet, basename='user-engagement')
router.register(r'type-analytics', views.NotificationTypeAnalyticsViewSet, basename='type-analytics')
router.register(r'system-performance', views.SystemPerformanceMetricsViewSet, basename='system-performance')
router.register(r'trends', views.TrendAnalysisViewSet, basename='trends')

urlpatterns = [
    path('', include(router.urls)),
    path('dashboard/', views.analytics_dashboard, name='analytics-dashboard'),
    path('reports/daily/', views.daily_report, name='daily-report'),
    path('reports/weekly/', views.weekly_report, name='weekly-report'),
    path('reports/monthly/', views.monthly_report, name='monthly-report'),
]
