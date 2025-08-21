from rest_framework import status, generics, permissions
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.tokens import RefreshToken
from django.contrib.auth import logout
from django.contrib.auth.tokens import default_token_generator
from django.core.mail import send_mail
from django.conf import settings
from django.utils.http import urlsafe_base64_encode, urlsafe_base64_decode
from django.utils.encoding import force_bytes, force_str
from django.utils import timezone


from .models import AppUser, Address
from .serializers import (
    UserLoginSerializer, PasswordResetRequestSerializer, PasswordResetSerializer,
    UserProfileSerializer, RoleSelectionSerializer, UserRegistrationSerializer,
    ComprehensiveUserProfileSerializer, UserProfileUpdateSerializer, UserBasicInfoSerializer,
    AddressSerializer, AddressCreateSerializer, AddressUpdateSerializer, UserPreferencesSerializer
)

class UserLoginView(APIView):
    """
    User login endpoint
    """
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        serializer = UserLoginSerializer(data=request.data)
        if serializer.is_valid():
            user = serializer.validated_data['user']

            # Check if user is verified
            if not user.email_verified:
                return Response({
                    'error': 'Please verify your email before logging in.'
                }, status=status.HTTP_400_BAD_REQUEST)

            # Generate JWT tokens
            refresh = RefreshToken.for_user(user)
            access_token = refresh.access_token

            # Update last login
            user.last_login = timezone.now()
            user.save(update_fields=['last_login'])

            return Response({
                'message': 'Login successful',
                'access_token': str(access_token),
                'refresh_token': str(refresh),
                'user': UserBasicInfoSerializer(user).data
            }, status=status.HTTP_200_OK)

        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class PasswordResetRequestView(APIView):
    """
    Password reset request endpoint
    """
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        serializer = PasswordResetRequestSerializer(data=request.data)
        if serializer.is_valid():
            email = serializer.validated_data['email']
            user = AppUser.objects.get(email=email)

            # Generate reset token
            token = default_token_generator.make_token(user)
            uid = urlsafe_base64_encode(force_bytes(user.pk))

            # Send reset email
            reset_link = f"{settings.FRONTEND_URL}/reset-password/{uid}/{token}/"
            try:
                send_mail(
                    'Password Reset - BIDR',
                    f'Click the link to reset your password: {reset_link}',
                    settings.DEFAULT_FROM_EMAIL,
                    [user.email],
                    fail_silently=False,
                )
            except Exception as e:
                return Response({
                    'error': 'Failed to send reset email'
                }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

            return Response({
                'message': 'Password reset link sent to your email'
            }, status=status.HTTP_200_OK)

        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class PasswordResetView(APIView):
    """
    Password reset endpoint
    """
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        serializer = PasswordResetSerializer(data=request.data)
        if serializer.is_valid():
            token = serializer.validated_data['token']
            password = serializer.validated_data['password']

            try:
                # Decode user ID from token
                uid = request.data.get('uid')
                user_id = force_str(urlsafe_base64_decode(uid))
                user = AppUser.objects.get(pk=user_id)

                # Verify token
                if default_token_generator.check_token(user, token):
                    user.set_password(password)
                    user.save()

                    return Response({
                        'message': 'Password reset successful'
                    }, status=status.HTTP_200_OK)
                else:
                    return Response({
                        'error': 'Invalid or expired token'
                    }, status=status.HTTP_400_BAD_REQUEST)

            except (TypeError, ValueError, OverflowError, AppUser.DoesNotExist):
                return Response({
                    'error': 'Invalid token'
                }, status=status.HTTP_400_BAD_REQUEST)

        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class UserLogoutView(APIView):
    """
    User logout endpoint
    """
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        try:
            refresh_token = request.data.get('refresh_token')
            if refresh_token:
                token = RefreshToken(refresh_token)
                token.blacklist()

            logout(request)
            return Response({
                'message': 'Logout successful'
            }, status=status.HTTP_200_OK)

        except Exception as e:
            return Response({
                'error': 'Invalid token'
            }, status=status.HTTP_400_BAD_REQUEST)


class UserProfileView(generics.RetrieveUpdateAPIView):
    """
    User profile view
    """
    serializer_class = UserProfileSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_object(self):
        return self.request.user


class UserRegistrationView(APIView):
    """
    User registration endpoint
    """
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        serializer = UserRegistrationSerializer(data=request.data)
        if serializer.is_valid():
            user = serializer.save()
            
            # Generate OTP for email verification
            import random
            import string
            from otp.models import OTP
            
            otp_code = "".join(random.choices(string.digits, k=6))
            otp_instance = OTP.objects.create(user=user, otp=otp_code)
            
            # Send OTP via email (in production)
            try:
                send_mail(
                    'Welcome to BIDR - Verify Your Account',
                    f'Your verification code is: {otp_code}',
                    settings.DEFAULT_FROM_EMAIL,
                    [user.email],
                    fail_silently=False,
                )
            except Exception as e:
                # For demo purposes, return OTP code in response (remove in production)
                return Response({
                    'message': 'User registered successfully. Please verify your email.',
                    'user_id': user.id,
                    'email': user.email,
                    'otp_code': otp_code,  # Remove in production
                    'note': 'OTP code included for testing purposes'
                }, status=status.HTTP_201_CREATED)
            
            return Response({
                'message': 'User registered successfully. Please check your email for verification code.',
                'user_id': user.id,
                'email': user.email
            }, status=status.HTTP_201_CREATED)
            
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class RoleSelectionView(APIView):
    """
    Endpoint for initial role selection before registration.
    """
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        serializer = RoleSelectionSerializer(data=request.data)
        if serializer.is_valid():
            role = serializer.validated_data["role"]
            return Response({"message": f"Role \'{role}\' selected. Proceed to registration.", "role": role}, status=status.HTTP_200_OK)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class ComprehensiveUserProfileView(generics.RetrieveAPIView):
    """
    Comprehensive user profile view with all profile data and addresses
    """
    serializer_class = ComprehensiveUserProfileSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_object(self):
        return self.request.user


class UserProfileUpdateView(generics.UpdateAPIView):
    """
    Update user profile information
    """
    serializer_class = UserProfileUpdateSerializer
    permission_classes = [permissions.IsAuthenticated]
    http_method_names = ['patch', 'put']

    def get_object(self):
        return self.request.user
    
    def perform_update(self, serializer):
        """Update profile and recalculate profile status"""
        serializer.save()
        
        # Update profile status based on completion
        user = serializer.instance
        completion_percentage = user.calculate_profile_completion()
        
        if completion_percentage >= 90:
            user.profile_status = 'complete'
        elif completion_percentage >= 50:
            user.profile_status = 'incomplete'
        
        user.save(update_fields=['profile_status'])
    
    def update(self, request, *args, **kwargs):
        """Custom update response"""
        partial = kwargs.pop('partial', False)
        instance = self.get_object()
        serializer = self.get_serializer(instance, data=request.data, partial=partial)
        serializer.is_valid(raise_exception=True)
        self.perform_update(serializer)
        
        # Return comprehensive profile data
        return Response({
            'message': 'Profile updated successfully',
            'profile': ComprehensiveUserProfileSerializer(instance).data
        }, status=status.HTTP_200_OK)


class UserPreferencesView(generics.RetrieveUpdateAPIView):
    """
    Manage user preferences
    """
    serializer_class = UserPreferencesSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_object(self):
        return self.request.user


class AddressListCreateView(generics.ListCreateAPIView):
    """
    List user addresses and create new addresses
    """
    permission_classes = [permissions.IsAuthenticated]
    
    def get_serializer_class(self):
        if self.request.method == 'POST':
            return AddressCreateSerializer
        return AddressSerializer
    
    def get_queryset(self):
        return Address.objects.filter(
            user=self.request.user,
            is_deleted=False
        ).order_by('-is_primary', '-created_at')
    
    def create(self, request, *args, **kwargs):
        """Create a new address"""
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        address = serializer.save()
        
        return Response({
            'message': 'Address created successfully',
            'address': address.get_decrypted_data()
        }, status=status.HTTP_201_CREATED)


class AddressDetailView(generics.RetrieveUpdateDestroyAPIView):
    """
    Retrieve, update, or delete a specific address
    """
    permission_classes = [permissions.IsAuthenticated]
    lookup_field = 'address_id'
    
    def get_serializer_class(self):
        if self.request.method in ['PUT', 'PATCH']:
            return AddressUpdateSerializer
        return AddressSerializer
    
    def get_queryset(self):
        return Address.objects.filter(
            user=self.request.user,
            is_deleted=False
        )
    
    def update(self, request, *args, **kwargs):
        """Update address with custom response"""
        partial = kwargs.pop('partial', False)
        instance = self.get_object()
        serializer = self.get_serializer(instance, data=request.data, partial=partial)
        serializer.is_valid(raise_exception=True)
        address = serializer.save()
        
        return Response({
            'message': 'Address updated successfully',
            'address': address.get_decrypted_data()
        }, status=status.HTTP_200_OK)
    
    def destroy(self, request, *args, **kwargs):
        """Soft delete address"""
        instance = self.get_object()
        instance.soft_delete()
        
        return Response({
            'message': 'Address deleted successfully'
        }, status=status.HTTP_200_OK)



class AddressSetPrimaryView(APIView):
    """
    Set an address as primary
    """
    permission_classes = [permissions.IsAuthenticated]
    
    def post(self, request, address_id):
        try:
            address = Address.objects.get(
                address_id=address_id,
                user=request.user,
                is_deleted=False
            )
            
            address.set_as_primary()
            
            return Response({
                'message': 'Address set as primary successfully',
                'address': address.get_decrypted_data()
            }, status=status.HTTP_200_OK)
            
        except Address.DoesNotExist:
            return Response({
                'error': 'Address not found'
            }, status=status.HTTP_404_NOT_FOUND)


class UserAddressesByTypeView(generics.ListAPIView):
    """
    Get addresses by type (home, business, shipping, billing)
    """
    serializer_class = AddressSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        address_type = self.kwargs.get('address_type')
        return Address.objects.filter(
            user=self.request.user,
            address_type=address_type,
            is_deleted=False
        ).order_by('-is_primary', '-created_at')


class UserPrimaryAddressView(generics.RetrieveAPIView):
    """
    Get user's primary address
    """
    serializer_class = AddressSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_object(self):
        try:
            return Address.objects.get(
                user=self.request.user,
                is_primary=True,
                is_deleted=False
            )
        except Address.DoesNotExist:
            return None
    
    def retrieve(self, request, *args, **kwargs):
        instance = self.get_object()
        if instance is None:
            return Response({
                'message': 'No primary address found',
                'address': None
            }, status=status.HTTP_200_OK)
        
        return Response({
            'message': 'Primary address retrieved successfully',
            'address': instance.get_decrypted_data()
        }, status=status.HTTP_200_OK)


class ProfileCompletionView(APIView):
    """
    Get profile completion status and suggestions
    """
    permission_classes = [permissions.IsAuthenticated]
    
    def get(self, request):
        user = request.user
        completion_percentage = user.calculate_profile_completion()
        
        # Determine missing fields
        missing_fields = []
        if not user.get_decrypted_first_name():
            missing_fields.append('first_name')
        if not user.get_decrypted_last_name():
            missing_fields.append('last_name')
        if not user.get_decrypted_date_of_birth():
            missing_fields.append('date_of_birth')
        if not user.gender:
            missing_fields.append('gender')
        if not user.bio:
            missing_fields.append('bio')
        if not user.profile_picture:
            missing_fields.append('profile_picture')
        if not user.addresses.filter(is_deleted=False).exists():
            missing_fields.append('address')
        
        # Provide completion suggestions
        suggestions = []
        if completion_percentage < 50:
            suggestions.append('Complete your basic information to get started')
        if completion_percentage < 75:
            suggestions.append('Add a profile picture to help others recognize you')
            suggestions.append('Write a brief bio to tell others about yourself')
        if completion_percentage < 90:
            suggestions.append('Add at least one address for deliveries')
        
        return Response({
            'completion_percentage': completion_percentage,
            'profile_status': user.profile_status,
            'missing_fields': missing_fields,
            'suggestions': suggestions,
            'is_complete': completion_percentage >= 90
        }, status=status.HTTP_200_OK)
