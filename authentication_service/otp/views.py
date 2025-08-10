from rest_framework import status, permissions
from rest_framework.response import Response
from rest_framework.views import APIView
from django.core.mail import send_mail
from django.conf import settings
from django.utils import timezone

from import_helper import setup_imports
setup_imports()
from user.models import AppUser
from .models import OTP
from .serializers import OTPVerificationSerializer
from .utils import OTPGenerator


class OTPVerificationView(APIView):
    """
    OTP verification endpoint
    """
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        serializer = OTPVerificationSerializer(data=request.data)
        if serializer.is_valid():
            user = serializer.validated_data['user']
            otp_instance = serializer.validated_data['otp_instance']

            # Mark OTP as verified
            otp_instance.verified_at = timezone.now()
            otp_instance.save()

            # Mark user email as verified
            user.email_verified = True
            user.save(update_fields=['email_verified'])

            return Response({
                'message': 'OTP verified successfully'
            }, status=status.HTTP_200_OK)

        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class ResendOTPView(APIView):
    """
    Resend OTP endpoint
    """
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        email = request.data.get('email')

        try:
            user = AppUser.objects.get(email=email)

            # Invalidate existing OTPs
            OTP.objects.filter(user=user, verified_at__isnull=True).update(
                verified_at=timezone.now()
            )

            # Generate new OTP using the OTPGenerator utility
            otp_code = OTPGenerator.generate_otp()
            OTP.objects.create(user=user, otp=otp_code)

            # Send OTP via email
            try:
                send_mail(
                    'Verify Your Account - BIDR',
                    f'Your verification code is: {otp_code}',
                    settings.DEFAULT_FROM_EMAIL,
                    [user.email],
                    fail_silently=False,
                )
            except Exception as e:
                return Response({
                    'error': 'Failed to send OTP'
                }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

            return Response({
                'message': 'OTP sent successfully'
            }, status=status.HTTP_200_OK)

        except AppUser.DoesNotExist:
            return Response({
                'error': 'User not found'
            }, status=status.HTTP_404_NOT_FOUND)
