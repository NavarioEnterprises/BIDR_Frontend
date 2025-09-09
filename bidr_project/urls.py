"""bidr_project URL Configuration"""
from django.contrib import admin
from django.urls import path, include
from django.http import JsonResponse

def health_check(request):
    """Simple health check endpoint"""
    return JsonResponse({'status': 'ok', 'message': 'BIDR Backend is running'})

urlpatterns = [
    path('admin/', admin.site.urls),
    path('health/', health_check, name='health_check'),
    path('', health_check, name='root'),
    
    # Service endpoints
    path('reviews/', include('reviews_and_ratings.urls')),
    path('rewards/', include('reviews_and_ratings.rewards.urls')),
]
