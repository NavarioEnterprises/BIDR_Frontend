from django.urls import path, include
from rest_framework.routers import DefaultRouter
from . import views

router = DefaultRouter()
router.register(r'templates', views.NotificationTemplateViewSet)
router.register(r'notifications', views.NotificationViewSet)
router.register(r'preferences', views.NotificationPreferenceViewSet)
router.register(r'batches', views.NotificationBatchViewSet)
router.register(r'queue', views.NotificationQueueViewSet)

urlpatterns = [
    path('', include(router.urls)),
    path('send/', views.SendNotificationView.as_view(), name='send-notification'),
    path('send/otp/', views.SendOTPNotificationView.as_view(), name='send-otp-notification'),
    path('bulk-send/', views.BulkSendNotificationsView.as_view(), name='bulk-send-notifications'),
    path('mark-read/<uuid:notification_id>/', views.mark_as_read, name='mark-as-read'),
    path('user/<uuid:user_id>/', views.get_user_notifications, name='user-notifications'),
    path('user/<uuid:user_id>/unread/', views.get_unread_notifications, name='user-unread-notifications'),
]
