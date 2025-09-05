from django.urls import path, include
from rest_framework.routers import DefaultRouter
from . import views

router = DefaultRouter()
router.register(r'notifications', views.NotificationLogViewSet)
router.register(r'system', views.SystemLogViewSet)
router.register(r'errors', views.ErrorLogViewSet)
router.register(r'audit', views.AuditLogViewSet)
router.register(r'api', views.APILogViewSet)

urlpatterns = [
    path('', include(router.urls)),
    path('export/', views.export_logs, name='export-logs'),
    path('search/', views.search_logs, name='search-logs'),
]
