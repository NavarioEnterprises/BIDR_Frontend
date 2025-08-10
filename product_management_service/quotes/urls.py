"""
URLs for Quotes app.
"""

from django.urls import path, include
from rest_framework.routers import DefaultRouter
from . import views

router = DefaultRouter()
router.register(r'quotes', views.QuoteViewSet)
router.register(r'quote-items', views.QuoteItemViewSet)
router.register(r'quote-attachments', views.QuoteAttachmentViewSet)
router.register(r'quote-messages', views.QuoteMessageViewSet)
router.register(r'quote-comparisons', views.QuoteComparisonViewSet)

urlpatterns = [
    path('', include(router.urls)),
]
