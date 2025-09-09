"""
URL configuration for reviews_and_ratings service apps.
This file includes URLs from all apps within the reviews_and_ratings service.
"""
from django.urls import path, include
from django.http import JsonResponse
from django.utils import timezone

# Health check for the reviews and ratings service
def service_health_check(request):
    return JsonResponse({
        'status': 'healthy',
        'service': 'reviews-and-ratings-service',
        'version': '1.0.0',
        'timestamp': timezone.now().isoformat(),
        'available_endpoints': [
            '/reviews/api/v1/',
            '/reviews/content/api/',
            '/reviews/admin/',
            '/rewards/api/'
        ]
    })

urlpatterns = [
    # Service health check
    path('health/', service_health_check, name='reviews_service_health'),
    
    # App URLs - Direct access endpoints
    path('api/reviews/', include('reviews_and_ratings.reviews.urls')),
    # V1 API compatibility - map directly to reviews without extra nesting
    path('api/v1/', include('reviews_and_ratings.reviews.urls')),
    path('content/api/', include('reviews_and_ratings.content.urls')),
]
