"""
URL configuration for transactions_service project.

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
from django.utils import timezone
from django_prometheus.exports import ExportToDjangoView

# Health check endpoint
def health_check(request):
    return JsonResponse({
        'status': 'healthy',
        'service': 'transactions-service',
        'version': '1.0.0',
        'timestamp': timezone.now().isoformat()
    })

urlpatterns = [
    path('admin/', admin.site.urls),
    
    # Health check
    # Metrics endpoint for Prometheus
    path('metrics', ExportToDjangoView, name='prometheus-django-metrics'),
    path('health/', health_check, name='health-check'),
    
    # Include disputes app URLs
    path('api/v1/', include('disputes.urls')),
    # Include escrow periods app URLs
    path('api/v1/', include('escrow_periods.urls')),
    # Include payment transactions app URLs
    path('api/v1/', include('payment_transactions.urls')),
    # Add REST framework browsable API login/logout views
    path('api-auth/', include('rest_framework.urls')),
]
