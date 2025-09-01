from rest_framework import status, permissions
from rest_framework.response import Response
from rest_framework.views import APIView
from django.utils import timezone
import logging

from import_helper import setup_imports
setup_imports()
from user.models import AppUser
from .models import OTP
from .utils import OTPGenerator
from .services import OTPDeliveryService

logger = logging.getLogger(__name__)


class SendMultiChannelOTPView(APIView):
    """
    Send OTP via multiple channels (email and/or SMS)
    """
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        """
        Send OTP to user via specified channels
        
        Expected payload:
        {
            "email": "user@example.com",  // optional
            "phone": "+1234567890",       // optional
            "channels": ["email", "sms"], // optional, defaults based on provided contact info
            "user_id": "uuid",            // optional, for existing users
            "force_create": false         // if true, create user if not found
        }
        """
        try:
            data = request.data
            email = data.get('email')
            phone = data.get('phone')
            channels = data.get('channels', [])
            user_id = data.get('user_id')
            force_create = data.get('force_create', False)
            
            # Validation
            if not email and not phone and not user_id:
                return Response({
                    'success': False,
                    'error': 'Either email, phone, or user_id is required'
                }, status=status.HTTP_400_BAD_REQUEST)
            
            # Find or create user
            user = None
            created = False
            
            if user_id:
                try:
                    user = AppUser.objects.get(uid=user_id)
                except AppUser.DoesNotExist:
                    return Response({
                        'success': False,
                        'error': 'User not found'
                    }, status=status.HTTP_404_NOT_FOUND)
            else:
                # Try to find user by email or phone
                if email:
                    user = AppUser.objects.filter(email=email).first()
                if not user and phone:
                    user = AppUser.objects.filter(phone_number=phone).first()
                
                if not user and force_create:
                    # Create new user if not found and force_create is True
                    if not email:
                        return Response({
                            'success': False,
                            'error': 'Email is required to create new user'
                        }, status=status.HTTP_400_BAD_REQUEST)
                    
                    user = AppUser.objects.create_user(
                        email=email,
                        phone_number=phone or '',
                        password=None,  # Will be set later during registration
                        is_active=False  # Inactive until OTP verification
                    )
                    created = True
                    logger.info(f"Created new user {user.id} for OTP verification")
                
                elif not user:
                    return Response({
                        'success': False,
                        'error': 'User not found. Set force_create=true to create a new user.'
                    }, status=status.HTTP_404_NOT_FOUND)
            
            # Determine channels if not specified
            if not channels:
                if user.email:
                    channels.append('email')
                if user.phone_number:
                    channels.append('sms')
            
            if not channels:
                return Response({
                    'success': False,
                    'error': 'No valid delivery channels available'
                }, status=status.HTTP_400_BAD_REQUEST)
            
            # Invalidate existing OTPs for this user
            OTP.objects.filter(user=user, verified_at__isnull=True).update(
                verified_at=timezone.now()
            )
            
            # Generate new OTP
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
                
                logger.info(f"OTP {otp_code} sent to user {user.uid} via {', '.join(sent_via)}")
                
                return Response({
                    'success': True,
                    'message': f'OTP sent successfully via {", ".join(sent_via)}',
                    'user_id': str(user.uid),
                    'user_created': created,
                    'delivery_results': {
                        'email': delivery_results['email'] if 'email' in channels else None,
                        'sms': delivery_results['sms'] if 'sms' in channels else None
                    },
                    'expires_in_minutes': 5
                }, status=status.HTTP_200_OK)
            else:
                # All delivery methods failed
                logger.error(f"Failed to deliver OTP {otp_code} to user {user.uid}")
                
                # If user was just created and OTP failed, we might want to delete them
                if created:
                    user.delete()
                    logger.info(f"Deleted newly created user {user.uid} due to OTP delivery failure")
                
                return Response({
                    'success': False,
                    'error': 'Failed to send OTP via any channel',
                    'delivery_results': {
                        'email': delivery_results['email'] if 'email' in channels else None,
                        'sms': delivery_results['sms'] if 'sms' in channels else None
                    }
                }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
                
        except Exception as e:
            logger.error(f"Unexpected error in SendMultiChannelOTPView: {str(e)}")
            return Response({
                'success': False,
                'error': 'An unexpected error occurred'
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


class OTPDeliveryStatusView(APIView):
    """
    Check OTP delivery status and get available delivery channels
    """
    permission_classes = [permissions.AllowAny]
    
    def post(self, request):
        """
        Check available delivery channels for a user
        
        Expected payload:
        {
            "email": "user@example.com",  // optional
            "phone": "+1234567890",       // optional
            "user_id": "uuid"             // optional
        }
        """
        try:
            data = request.data
            email = data.get('email')
            phone = data.get('phone')
            user_id = data.get('user_id')
            
            if not email and not phone and not user_id:
                return Response({
                    'success': False,
                    'error': 'Either email, phone, or user_id is required'
                }, status=status.HTTP_400_BAD_REQUEST)
            
            # Find user
            user = None
            if user_id:
                try:
                    user = AppUser.objects.get(uid=user_id)
                except AppUser.DoesNotExist:
                    return Response({
                        'success': False,
                        'error': 'User not found'
                    }, status=status.HTTP_404_NOT_FOUND)
            else:
                if email:
                    user = AppUser.objects.filter(email=email).first()
                if not user and phone:
                    user = AppUser.objects.filter(phone_number=phone).first()
            
            if not user:
                return Response({
                    'success': False,
                    'error': 'User not found',
                    'available_channels': []
                }, status=status.HTTP_404_NOT_FOUND)
            
            # Check available channels
            available_channels = []
            if user.email:
                available_channels.append({
                    'type': 'email',
                    'destination': user.email,
                    'masked_destination': f"{user.email[:3]}***@{user.email.split('@')[1]}"
                })
            
            decrypted_phone = user.get_decrypted_phone_number() if hasattr(user, 'get_decrypted_phone_number') else None
            if decrypted_phone:
                phone_masked = f"{decrypted_phone[:4]}***{decrypted_phone[-3:]}" if len(decrypted_phone) > 7 else "***"
                available_channels.append({
                    'type': 'sms',
                    'destination': decrypted_phone,
                    'masked_destination': phone_masked
                })
            
            # Check for pending OTPs
            pending_otp = OTP.objects.filter(
                user=user,
                verified_at__isnull=True,
                expires_at__gt=timezone.now()
            ).first()
            
            return Response({
                'success': True,
                'user_id': str(user.uid),
                'available_channels': available_channels,
                'has_pending_otp': bool(pending_otp),
                'pending_otp_expires_at': pending_otp.expires_at if pending_otp else None
            }, status=status.HTTP_200_OK)
            
        except Exception as e:
            logger.error(f"Unexpected error in OTPDeliveryStatusView: {str(e)}")
            return Response({
                'success': False,
                'error': 'An unexpected error occurred'
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)