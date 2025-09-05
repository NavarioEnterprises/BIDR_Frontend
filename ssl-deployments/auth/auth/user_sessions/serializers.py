"""
BIDR Sessions Serializers

Serializers for session management API endpoints.
"""
from rest_framework import serializers
from django.contrib.auth import get_user_model
from .models import (
    UserSession, SessionActivity, TrustedDevice, 
    SessionSecurityEvent, DeviceType, SessionStatus
)

User = get_user_model()


class UserSessionSerializer(serializers.ModelSerializer):
    """Serializer for UserSession model"""
    
    location_display = serializers.CharField(source='get_location_display', read_only=True)
    is_active = serializers.BooleanField(read_only=True)
    is_expired = serializers.BooleanField(read_only=True)
    session_duration = serializers.SerializerMethodField()
    
    class Meta:
        model = UserSession
        fields = [
            'uuid', 'session_key', 'device_id', 'device_type', 'device_name',
            'browser', 'browser_version', 'operating_system', 'ip_address',
            'country', 'city', 'latitude', 'longitude', 'status', 'is_trusted',
            'created_at', 'last_activity', 'expires_at', 'terminated_at',
            'security_score', 'risk_factors', 'location_display', 'is_active',
            'is_expired', 'session_duration'
        ]
        read_only_fields = [
            'uuid', 'created_at', 'last_activity', 'terminated_at',
            'location_display', 'is_active', 'is_expired', 'session_duration'
        ]

    def get_session_duration(self, obj):
        """Get session duration in seconds"""
        duration = obj.calculate_session_duration()
        return duration.total_seconds()


class SessionActivitySerializer(serializers.ModelSerializer):
    """Serializer for SessionActivity model"""
    
    class Meta:
        model = SessionActivity
        fields = [
            'id', 'action', 'endpoint', 'method', 'status_code',
            'request_data', 'response_time', 'timestamp'
        ]
        read_only_fields = ['id', 'timestamp']


class TrustedDeviceSerializer(serializers.ModelSerializer):
    """Serializer for TrustedDevice model"""
    
    is_expired = serializers.BooleanField(read_only=True)
    
    class Meta:
        model = TrustedDevice
        fields = [
            'uuid', 'device_id', 'device_name', 'device_type', 
            'device_fingerprint', 'trusted_at', 'last_used', 
            'expires_at', 'is_active', 'is_expired'
        ]
        read_only_fields = ['uuid', 'trusted_at', 'last_used', 'is_expired']


class SessionSecurityEventSerializer(serializers.ModelSerializer):
    """Serializer for SessionSecurityEvent model"""
    
    class Meta:
        model = SessionSecurityEvent
        fields = [
            'uuid', 'event_type', 'severity', 'description', 'event_data',
            'risk_score', 'is_resolved', 'resolved_at', 'resolution_notes',
            'detected_at'
        ]
        read_only_fields = ['uuid', 'detected_at']


class SessionCreateSerializer(serializers.Serializer):
    """Serializer for creating a new session"""
    
    device_id = serializers.CharField(max_length=255, required=False)
    device_name = serializers.CharField(max_length=255, required=False)
    device_type = serializers.ChoiceField(choices=DeviceType.choices, default=DeviceType.UNKNOWN)
    browser = serializers.CharField(max_length=100, required=False)
    browser_version = serializers.CharField(max_length=50, required=False)
    operating_system = serializers.CharField(max_length=100, required=False)
    latitude = serializers.DecimalField(max_digits=9, decimal_places=6, required=False)
    longitude = serializers.DecimalField(max_digits=9, decimal_places=6, required=False)


class SessionTerminateSerializer(serializers.Serializer):
    """Serializer for terminating sessions"""
    
    session_uuids = serializers.ListField(
        child=serializers.UUIDField(),
        help_text="List of session UUIDs to terminate"
    )
    reason = serializers.CharField(max_length=255, required=False)


class SessionListSerializer(serializers.ModelSerializer):
    """Lightweight serializer for listing sessions"""
    
    location_display = serializers.CharField(source='get_location_display', read_only=True)
    is_active = serializers.BooleanField(read_only=True)
    
    class Meta:
        model = UserSession
        fields = [
            'uuid', 'device_type', 'device_name', 'ip_address',
            'location_display', 'status', 'is_trusted', 'created_at',
            'last_activity', 'is_active'
        ]


class SessionAnalyticsSerializer(serializers.Serializer):
    """Serializer for session analytics data"""
    
    total_sessions = serializers.IntegerField()
    active_sessions = serializers.IntegerField()
    unique_devices = serializers.IntegerField()
    unique_locations = serializers.IntegerField()
    average_session_duration = serializers.FloatField()
    device_type_breakdown = serializers.DictField()
    browser_breakdown = serializers.DictField()
    country_breakdown = serializers.DictField()
    security_events_count = serializers.IntegerField()
    trusted_devices_count = serializers.IntegerField()


class DeviceManagementSerializer(serializers.Serializer):
    """Serializer for device management operations"""
    
    action = serializers.ChoiceField(
        choices=['trust', 'revoke_trust', 'remove'],
        help_text="Action to perform on the device"
    )
    device_uuids = serializers.ListField(
        child=serializers.UUIDField(),
        help_text="List of device UUIDs to perform action on"
    )
    expires_at = serializers.DateTimeField(
        required=False,
        help_text="Expiration date for trust (only for 'trust' action)"
    )
