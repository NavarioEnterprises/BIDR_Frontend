from django.urls import path

from .views import OTPVerificationView, ResendOTPView
from .multi_channel_views import SendMultiChannelOTPView, OTPDeliveryStatusView

urlpatterns = [
    path('verify/', OTPVerificationView.as_view(), name='otp-verify'),
    path('resend/', ResendOTPView.as_view(), name='otp-resend'),
    path('send/', SendMultiChannelOTPView.as_view(), name='otp-send-multichannel'),
    path('status/', OTPDeliveryStatusView.as_view(), name='otp-delivery-status'),
]

