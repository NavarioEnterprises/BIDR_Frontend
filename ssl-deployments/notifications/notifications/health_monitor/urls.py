from django.urls import path, include
from rest_framework.routers import DefaultRouter
from . import views

router = DefaultRouter()
router.register(r'service', views.ServiceHealthViewSet, basename='service')
router.register(r'components', views.ComponentHealthViewSet, basename='components')
router.register(r'checks', views.HealthCheckViewSet, basename='checks')
router.register(r'alerts', views.AlertViewSet, basename='alerts')
router.register(r'maintenance', views.MaintenanceWindowViewSet, basename='maintenance')

urlpatterns = [
    path('', include(router.urls)),
    path('status/', views.overall_health_status, name='health-status'),
    path('run-checks/', views.run_health_checks, name='run-health-checks'),
    path('alerts/acknowledge/<uuid:alert_id>/', views.acknowledge_alert, name='acknowledge-alert'),
    path('alerts/resolve/<uuid:alert_id>/', views.resolve_alert, name='resolve-alert'),
]
