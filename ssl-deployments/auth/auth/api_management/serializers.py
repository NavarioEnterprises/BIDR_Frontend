"""
BIDR API Management Serializers

Serializers for API key management and monitoring.
"""
from rest_framework import serializers

from .models import APIKey, APIScope, APIRequest, RateLimitBucket, APIKeyUsageQuota


class APIScopeSerializer(serializers.ModelSerializer):
    """Serializer for API scopes"""
    
    class Meta:
        model = APIScope
        fields = [
            'uuid', 'name', 'description', 'resource', 'permissions',
            'is_default', 'is_sensitive', 'created_at', 'updated_at'
        ]
        read_only_fields = ['uuid', 'created_at', 'updated_at']


class APIKeySerializer(serializers.ModelSerializer):
    """Serializer for API keys (without sensitive data)"""
    
    scopes = APIScopeSerializer(many=True, read_only=True)
    is_active = serializers.BooleanField(read_only=True)
    is_expired = serializers.BooleanField(read_only=True)
    
    class Meta:
        model = APIKey
        fields = [
            'uuid', 'name', 'description', 'key_id', 'key_prefix',
            'status', 'scopes', 'allowed_ips', 'allowed_origins',
            'rate_limit_requests', 'rate_limit_period',
            'daily_request_limit', 'monthly_request_limit',
            'total_requests', 'last_used_at', 'last_used_ip',
            'created_at', 'expires_at', 'last_rotated_at',
            'is_active', 'is_expired'
        ]
        read_only_fields = [
            'uuid', 'key_id', 'key_prefix', 'total_requests',
            'last_used_at', 'last_used_ip', 'created_at',
            'last_rotated_at', 'is_active', 'is_expired'
        ]


class APIKeyCreateSerializer(serializers.Serializer):
    """Serializer for creating new API keys"""
    
    name = serializers.CharField(max_length=255)
    description = serializers.CharField(required=False, allow_blank=True)
    scopes = serializers.ListField(
        child=serializers.UUIDField(),
        required=False,
        help_text="List of scope UUIDs"
    )
    allowed_ips = serializers.ListField(
        child=serializers.IPAddressField(),
        required=False,
        help_text="List of allowed IP addresses"
    )
    allowed_origins = serializers.ListField(
        child=serializers.CharField(),
        required=False,
        help_text="List of allowed origins"
    )
    rate_limit_requests = serializers.IntegerField(default=1000, min_value=1)
    rate_limit_period = serializers.ChoiceField(
        choices=['minute', 'hour', 'day', 'month'],
        default='hour'
    )
    daily_request_limit = serializers.IntegerField(required=False, min_value=1)
    monthly_request_limit = serializers.IntegerField(required=False, min_value=1)
    expires_at = serializers.DateTimeField(required=False)


class APIKeyResponseSerializer(serializers.Serializer):
    """Serializer for API key creation response (includes secret key)"""
    
    api_key = APIKeySerializer()
    secret_key = serializers.CharField(
        help_text="The secret key - store this securely as it won't be shown again"
    )


class APIRequestSerializer(serializers.ModelSerializer):
    """Serializer for API requests"""
    
    api_key_name = serializers.CharField(source='api_key.name', read_only=True)
    is_success = serializers.BooleanField(read_only=True)
    is_error = serializers.BooleanField(read_only=True)
    
    class Meta:
        model = APIRequest
        fields = [
            'uuid', 'api_key_name', 'method', 'endpoint', 'status_code',
            'ip_address', 'user_agent', 'origin', 'response_time',
            'request_size', 'response_size', 'timestamp',
            'is_success', 'is_error'
        ]


class APIKeyAnalyticsSerializer(serializers.Serializer):
    """Serializer for API key analytics"""
    
    total_requests = serializers.IntegerField()
    successful_requests = serializers.IntegerField()
    failed_requests = serializers.IntegerField()
    error_rate = serializers.FloatField()
    avg_response_time = serializers.FloatField()
    requests_by_endpoint = serializers.DictField()
    requests_by_status_code = serializers.DictField()
    requests_by_day = serializers.DictField()
    top_ips = serializers.ListField()
    usage_by_hour = serializers.DictField()


class RateLimitBucketSerializer(serializers.ModelSerializer):
    """Serializer for rate limit buckets"""
    
    api_key_name = serializers.CharField(source='api_key.name', read_only=True)
    is_expired = serializers.BooleanField(read_only=True)
    
    class Meta:
        model = RateLimitBucket
        fields = [
            'api_key_name', 'period', 'bucket_key', 'request_count',
            'first_request_at', 'last_request_at', 'expires_at', 'is_expired'
        ]


class APIKeyUsageQuotaSerializer(serializers.ModelSerializer):
    """Serializer for API key usage quotas"""
    
    api_key_name = serializers.CharField(source='api_key.name', read_only=True)
    is_expired = serializers.BooleanField(read_only=True)
    is_quota_exceeded = serializers.BooleanField(read_only=True)
    usage_percentage = serializers.SerializerMethodField()
    
    class Meta:
        model = APIKeyUsageQuota
        fields = [
            'api_key_name', 'quota_type', 'period_start', 'period_end',
            'request_count', 'quota_limit', 'is_expired', 'is_quota_exceeded',
            'usage_percentage', 'created_at', 'last_updated'
        ]
    
    def get_usage_percentage(self, obj):
        return obj.get_usage_percentage()


class APIKeyBulkActionSerializer(serializers.Serializer):
    """Serializer for bulk API key actions"""
    
    action = serializers.ChoiceField(
        choices=['activate', 'deactivate', 'revoke', 'rotate'],
        help_text="Action to perform on API keys"
    )
    api_key_uuids = serializers.ListField(
        child=serializers.UUIDField(),
        help_text="List of API key UUIDs"
    )
    reason = serializers.CharField(required=False, help_text="Reason for the action")
