from rest_framework import status, permissions
from rest_framework.response import Response
from rest_framework.views import APIView
from django.core.mail import send_mail
from django.conf import settings
from django.utils import timezone
import requests
import json
import logging

from import_helper import setup_imports
setup_imports()
from user.models import AppUser
from .models import OTP
from .serializers import OTPVerificationSerializer
from .utils import OTPGenerator
from .services import OTPDeliveryService

logger = logging.getLogger(__name__)


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
                'success': True,
                'message': 'OTP verified successfully'
            }, status=status.HTTP_200_OK)

        return Response({
            'success': False,
            'errors': serializer.errors
        }, status=status.HTTP_400_BAD_REQUEST)


class ResendOTPView(APIView):
    """
    Resend OTP endpoint with email and SMS support
    """
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        email = request.data.get('email')
        phone = request.data.get('phone')
        delivery_method = request.data.get('delivery_method', 'sms')  # Default to SMS
        
        # Convert delivery_method to channels array for backward compatibility
        if delivery_method == 'sms':
            channels = ['sms']
        elif delivery_method == 'email':
            channels = ['email']
        elif delivery_method == 'both':
            channels = ['sms', 'email']
        else:
            # Fallback to legacy channels parameter if provided
            channels = request.data.get('channels', ['sms'])
        
        print(request.data)
        
        if not email and not phone:
            return Response({
                'success': False,
                'error': 'Either email or phone number is required'
            }, status=status.HTTP_400_BAD_REQUEST)

        try:
            # Find user by email or phone
            user = None
            if email:
                user = AppUser.objects.filter(email__iexact=email).first()
            elif phone:
                # Assuming AppUser has a phone field - adjust as needed
                user = AppUser.objects.filter(phone_number=phone).first()
            
            if not user:
                return Response({
                    'success': False,
                    'error': 'User not found'
                }, status=status.HTTP_404_NOT_FOUND)

            # Invalidate existing OTPs for this user
            OTP.objects.filter(user=user, verified_at__isnull=True).update(
                verified_at=timezone.now()
            )

            # Generate new OTP using the OTPGenerator utility
            otp_code = OTPGenerator.generate_otp()
            otp_instance = OTP.objects.create(user=user, otp=otp_code)

            # Initialize delivery service
            delivery_service = OTPDeliveryService()
            
            # Send OTP via requested channels
            delivery_results = delivery_service.send_otp_multi_channel(
                user_id=str(user.uid),
                otp_code=otp_code,
                email=user.email if 'email' in channels else None,
                phone=user.get_decrypted_phone_number() if 'sms' in channels and hasattr(user, 'get_decrypted_phone_number') else None,
                user_name=f"{user.first_name} {user.last_name}".strip() or user.email
            )

            if delivery_results['overall_success']:
                # Log successful delivery
                sent_via = []
                if delivery_results['email']['success']:
                    sent_via.append('email')
                if delivery_results['sms']['success']:
                    sent_via.append('SMS')
                
                logger.info(f"OTP {otp_code} sent to user {user.id} via {', '.join(sent_via)}")
                
                return Response({
                    'success': True,
                    'message': f'OTP sent successfully via {", ".join(sent_via)}',
                    'delivery_results': {
                        'email': delivery_results['email'] if 'email' in channels else None,
                        'sms': delivery_results['sms'] if 'sms' in channels else None
                    }
                }, status=status.HTTP_200_OK)
            else:
                # All delivery methods failed
                logger.error(f"Failed to deliver OTP {otp_code} to user {user.id}")
                return Response({
                    'success': False,
                    'error': 'Failed to send OTP via any channel',
                    'delivery_results': {
                        'email': delivery_results['email'] if 'email' in channels else None,
                        'sms': delivery_results['sms'] if 'sms' in channels else None
                    }
                }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

        except Exception as e:
            logger.error(f"Unexpected error in ResendOTPView: {str(e)}")
            return Response({
                'success': False,
                'error': 'An unexpected error occurred'
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
