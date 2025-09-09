from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import ReviewViewSet, TicketViewSet, reviews_endpoint

router = DefaultRouter()
router.register(r'reviews', ReviewViewSet)
router.register(r'tickets', TicketViewSet)

urlpatterns = [
    # Custom endpoint for direct access - handles both GET and POST
    path('', reviews_endpoint, name='reviews_endpoint'),  # GET/POST /api/reviews/
    # V1 API endpoint for backward compatibility
    path('api/reviews/', reviews_endpoint, name='v1_reviews_endpoint'),  # GET/POST /api/v1/api/reviews/
    # Router endpoints
    path('router/', include(router.urls)),
]
