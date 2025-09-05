from rest_framework import serializers
from .models import (
    UserProfile, SystemConfiguration, ServiceHealth, 
    APIKey, TransactionReference
)


class UserProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = UserProfile
        fields = '__all__'
        read_only_fields = ('created_at', 'updated_at')


class SystemConfigurationSerializer(serializers.ModelSerializer):
    class Meta:
        model = SystemConfiguration
        fields = '__all__'
        read_only_fields = ('created_at', 'updated_at')


class ServiceHealthSerializer(serializers.ModelSerializer):
    class Meta:
        model = ServiceHealth
        fields = '__all__'
        read_only_fields = ('last_check',)


class APIKeySerializer(serializers.ModelSerializer):
    class Meta:
        model = APIKey
        fields = '__all__'
        read_only_fields = ('created_at', 'last_used')
        extra_kwargs = {
            'key': {'write_only': True}
        }


class TransactionReferenceSerializer(serializers.ModelSerializer):
    class Meta:
        model = TransactionReference
        fields = '__all__'
        read_only_fields = ('created_at', 'updated_at')
