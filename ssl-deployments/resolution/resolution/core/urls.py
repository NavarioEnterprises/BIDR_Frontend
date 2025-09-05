from django.urls import path, include
from rest_framework.routers import DefaultRouter
from . import views

router = DefaultRouter()
router.register(r'user-profiles', views.UserProfileViewSet)
router.register(r'system-config', views.SystemConfigurationViewSet)
router.register(r'service-health', views.ServiceHealthViewSet)
router.register(r'api-keys', views.APIKeyViewSet)
router.register(r'transaction-references', views.TransactionReferenceViewSet)

urlpatterns = [
    path('', include(router.urls)),
    path('health/', views.health_check, name='health_check'),
    path('service-info/', views.service_info, name='service_info'),
    path('stats/', views.service_statistics, name='service_statistics'),
]
