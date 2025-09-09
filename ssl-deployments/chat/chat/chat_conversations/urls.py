"""
URL configuration for chat_conversations app.
"""

from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import ConversationViewSet

router = DefaultRouter()
router.register(r'conversations', ConversationViewSet, basename='conversation')

app_name = 'chat_conversations'

urlpatterns = [
    path('api/v1/chat/', include(router.urls)),
]
