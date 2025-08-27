from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import (
    FAQViewSet, BlogViewSet, PolicyViewSet, 
    ContactSubmissionViewSet, NewsletterSubscriptionViewSet
)

router = DefaultRouter()
router.register(r'faqs', FAQViewSet)
router.register(r'blogs', BlogViewSet)
router.register(r'policies', PolicyViewSet)
router.register(r'contact', ContactSubmissionViewSet)
router.register(r'newsletter', NewsletterSubscriptionViewSet)

urlpatterns = [
    path('api/', include(router.urls)),
]
