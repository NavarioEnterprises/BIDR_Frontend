from django.urls import path

from .views import OTPVerificationView, ResendOTPView

urlpatterns = [
    path('verify/', OTPVerificationView.as_view(), name='otp-verify'),
    path('resend/', ResendOTPView.as_view(), name='otp-resend'),
]
