from django.urls import path
from .views import notifications_info, send_notification

urlpatterns = [
    path('info/', notifications_info, name='notifications-info'),
    path('send/', send_notification, name='send-notification'),
]
