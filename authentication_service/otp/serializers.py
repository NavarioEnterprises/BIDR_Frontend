from rest_framework import serializers

from import_helper import setup_imports
setup_imports()
from user.models import AppUser
from .models import OTP


class OTPVerificationSerializer(serializers.Serializer):
    """Serializer for OTP verification"""
    otp = serializers.CharField(max_length=6)
    email = serializers.EmailField()

    def validate(self, attrs):
        email = attrs.get('email')
        otp_code = attrs.get('otp')

        try:
            user = AppUser.objects.get(email=email)
            
            # Try to find valid OTP
            try:
                otp = OTP.objects.get(user=user, otp=otp_code, verified_at__isnull=True)
                
                if otp.is_expired():
                    raise serializers.ValidationError({
                        "otp": "OTP has expired. Please request a new one.",
                        "error_code": "OTP_EXPIRED"
                    })
                    
            except OTP.DoesNotExist:
                # Check if there are any OTPs for this user (for better error messaging)
                user_otps = OTP.objects.filter(user=user).order_by('-created_at')
                if user_otps.exists():
                    latest_otp = user_otps.first()
                    if latest_otp.verified_at:
                        raise serializers.ValidationError({
                            "otp": "OTP has already been used. Please request a new one.",
                            "error_code": "OTP_ALREADY_USED"
                        })
                    elif latest_otp.is_expired():
                        raise serializers.ValidationError({
                            "otp": "OTP has expired. Please request a new one.",
                            "error_code": "OTP_EXPIRED"
                        })
                
                raise serializers.ValidationError({
                    "otp": "Invalid OTP code. Please check and try again.",
                    "error_code": "INVALID_OTP"
                })

            attrs['user'] = user
            attrs['otp_instance'] = otp
            
        except AppUser.DoesNotExist:
            raise serializers.ValidationError({
                "email": "User not found with this email address.",
                "error_code": "USER_NOT_FOUND"
            })

        return attrs
