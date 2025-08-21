"""
URL configuration for notifications_service project.

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/5.1/topics/http/urls/
Examples:
Function views
    1. Add an import:  from my_app import views
    2. Add a URL to urlpatterns:  path('', views.home, name='home')
Class-based views
    1. Add an import:  from other_app.views import Home
    2. Add a URL to urlpatterns:  path('', Home.as_view(), name='home')
Including another URLconf
    1. Import the include() function: from django.urls import include, path
    2. Add a URL to urlpatterns:  path('blog/', include('blog.urls'))
"""
from django.contrib import admin
from django.urls import path, include
from django.http import JsonResponse
from system_notifications.webhooks import payment_webhook, resolution_webhook
from django_prometheus.exports import ExportToDjangoView


def health_check(request):
    return JsonResponse({
        'status': 'healthy',
        'service': 'notification-service',
        'version': '1.0.0'
    })


urlpatterns = [
    path('admin/', admin.site.urls),
    
    # Metrics endpoint for Prometheus
    path('metrics', ExportToDjangoView, name='prometheus-django-metrics'),
    path('health/', health_check, name='health-check'),
    path('api/v1/notifications/', include('system_notifications.urls')),
    path('api/v1/channels/', include('delivery_channels.urls')),
    path('api/v1/logs/', include('notification_logs.urls')),
    path('api/v1/analytics/', include('notification_analytics.urls')),
    path('api/v1/health/', include('health_monitor.urls')),
    # Webhook endpoints
    path('webhooks/payment/', payment_webhook, name='payment-webhook'),
    path('webhooks/resolution/', resolution_webhook, name='resolution-webhook'),
]
