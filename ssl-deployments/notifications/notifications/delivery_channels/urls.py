from django.urls import path, include
from rest_framework.routers import DefaultRouter
from . import views

router = DefaultRouter()
router.register(r'channels', views.NotificationChannelViewSet)
router.register(r'credentials', views.ChannelCredentialViewSet)
router.register(r'attempts', views.DeliveryAttemptViewSet)
router.register(r'rate-limits', views.ChannelRateLimitViewSet)

urlpatterns = [
    path('', include(router.urls)),
    path('test/<uuid:channel_id>/', views.test_channel, name='test-channel'),
    path('stats/', views.channel_statistics, name='channel-statistics'),
]
