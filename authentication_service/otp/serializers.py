from rest_framework import serializers
from django.contrib.auth import authenticate
from django.contrib.auth.password_validation import validate_password

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
            otp = OTP.objects.get(user=user, otp=otp_code, verified_at__isnull=True)

            if otp.is_expired():
                raise serializers.ValidationError("OTP has expired")

            attrs['user'] = user
            attrs['otp_instance'] = otp
        except AppUser.DoesNotExist:
            raise serializers.ValidationError("User not found")
        except OTP.DoesNotExist:
            raise serializers.ValidationError("Invalid OTP")

        return attrs