"""
WebSocket URL routing for BIDR Chat Service
"""

from django.urls import re_path
from . import consumers

websocket_urlpatterns = [
    # Chat room WebSocket
    re_path(r'ws/chat/(?P<conversation_id>[^/]+)/$', consumers.ChatConsumer.as_asgi()),
    
    # Notifications WebSocket
    re_path(r'ws/notifications_service/$', consumers.NotificationConsumer.as_asgi()),
]
