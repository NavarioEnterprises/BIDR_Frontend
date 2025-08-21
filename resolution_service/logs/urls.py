from django.urls import path, include
from rest_framework.routers import DefaultRouter
from . import views

router = DefaultRouter()
router.register(r'activity-logs', views.ActivityLogViewSet, basename='activitylog')
router.register(r'system-logs', views.SystemLogViewSet, basename='systemlog')
router.register(r'api-request-logs', views.APIRequestLogViewSet, basename='apirequestlog')
router.register(r'security-logs', views.SecurityLogViewSet, basename='securitylog')
router.register(r'data-change-logs', views.DataChangeLogViewSet, basename='datachangelog')
router.register(r'performance-logs', views.PerformanceLogViewSet, basename='performancelog')
router.register(r'error-logs', views.ErrorLogViewSet, basename='errorlog')

urlpatterns = [
    path('', include(router.urls)),
    path('activity/<int:user_id>/', views.get_user_activity, name='user_activity'),
    path('security/suspicious/', views.get_suspicious_activities, name='suspicious_activities'),
    path('performance/metrics/', views.get_performance_metrics, name='performance_metrics'),
    path('errors/unresolved/', views.get_unresolved_errors, name='unresolved_errors'),
    path('stats/', views.log_statistics, name='log_statistics'),
    path('export/', views.export_logs, name='export_logs'),
]
