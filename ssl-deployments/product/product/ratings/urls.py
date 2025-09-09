"""
URLs for Ratings app.
"""

from django.urls import path, include
from rest_framework.routers import DefaultRouter

router = DefaultRouter()
# router.register(r'ratings', views.RatingViewSet)

urlpatterns = [
    path('', include(router.urls)),
]
