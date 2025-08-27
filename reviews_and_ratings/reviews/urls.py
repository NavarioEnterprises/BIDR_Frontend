from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import ReviewViewSet, TicketViewSet

router = DefaultRouter()
router.register(r'reviews', ReviewViewSet)
router.register(r'tickets', TicketViewSet)

urlpatterns = [
    path('api/', include(router.urls)),
]
