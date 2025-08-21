"""
URL configuration for chat_service project.

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/5.0/topics/http/urls/
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
"""
URL configuration for BIDR Chat Service.

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/5.1/topics/http/urls/
"""

from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static
from django.http import JsonResponse
from django.views.generic import TemplateView
from django.utils import timezone
from rest_framework.authtoken.views import obtain_auth_token
from django_prometheus.exports import ExportToDjangoView

# Health check endpoint
def health_check(request):
    return JsonResponse({
        'status': 'healthy',
        'service': 'chat-service',
        'version': '1.0.0',
        'timestamp': timezone.now().isoformat()
    })

# Simple API root view
def api_root(request):
    return JsonResponse({
        'message': 'BIDR Chat Service API',
        'version': '1.0.0',
        'status': 'active',
        'endpoints': {
            'auth': '/api/auth/token/',
            'profiles': '/api/v1/core/profiles/',
            'config': '/api/v1/core/config/',
            'conversations': '/api/v1/chat/conversations/',
            'messages': '/api/v1/chat/messages/',
            'bidding': '/api/v1/chat/bidding/',
            'moderation': '/api/v1/chat/moderation/',
            'files': '/api/v1/chat/files/',
        },
        'documentation': {
            'swagger': '/swagger/',
            'redoc': '/redoc/',
            'openapi': '/swagger.json'
        }
    })

urlpatterns = [
    # Admin interface
    path('admin/', admin.site.urls),
    
    # Health check
    # Metrics endpoint for Prometheus
    path('metrics', ExportToDjangoView, name='prometheus-django-metrics'),
    path('health/', health_check, name='health-check'),
    
    # API root
    path('', api_root, name='api-root'),
    path('api/', api_root, name='api-root-v1'),
    
    # Authentication
    path('api/auth/token/', obtain_auth_token, name='api_token_auth'),
    
    # API endpoints - Version 1
    path('', include('chat_core.urls')),
]

# Add media files serving in development
if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
