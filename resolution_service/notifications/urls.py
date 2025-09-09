from django.urls import path, include
from rest_framework.routers import DefaultRouter
from . import views

router = DefaultRouter()
router.register(r'templates', views.NotificationTemplateViewSet, basename='notificationtemplate')
router.register(r'notifications_service', views.NotificationViewSet, basename='notification')
router.register(r'preferences', views.NotificationPreferenceViewSet, basename='notificationpreference')
router.register(r'channels', views.NotificationChannelViewSet, basename='notificationchannel')
router.register(r'batches', views.NotificationBatchViewSet, basename='notificationbatch')

urlpatterns = [
    path('', include(router.urls)),
    path('send/', views.send_notification, name='send_notification'),
    path('send-bulk/', views.send_bulk_notification, name='send_bulk_notification'),
    path('notifications_service/<int:notification_id>/mark-read/', views.mark_notification_read, name='mark_notification_read'),
    path('notifications_service/mark-all-read/', views.mark_all_notifications_read, name='mark_all_notifications_read'),
    path('user/<int:user_id>/notifications_service/', views.get_user_notifications, name='user_notifications'),
    path('user/<int:user_id>/unread-count/', views.get_unread_count, name='unread_count'),
    path('templates/test/<int:template_id>/', views.test_template, name='test_template'),
    path('stats/', views.notification_statistics, name='notification_statistics'),
]
