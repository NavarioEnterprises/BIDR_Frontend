"""
Serializers for BIDR Authentication Logging System
"""
from rest_framework import serializers

from .models import AuthenticationLog, SecurityEvent, LoginSession, AuditTrail, SuspiciousActivity


class AuthenticationLogSerializer(serializers.ModelSerializer):
    """Serializer for authentication logs."""
    
    action_display = serializers.CharField(source='get_action_display', read_only=True)
    status_display = serializers.CharField(source='get_status_display', read_only=True)
    user_type_display = serializers.CharField(source='get_user_type_display', read_only=True)
    is_suspicious = serializers.BooleanField(read_only=True)
    is_failed_attempt = serializers.BooleanField(read_only=True)
    
    class Meta:
        model = AuthenticationLog
        fields = [
            'log_id', 'user_email', 'user_id', 'user_type', 'user_type_display',
            'action', 'action_display', 'status', 'status_display',
            'ip_address', 'user_agent', 'device_id', 'device_type', 'device_os', 'browser',
            'country', 'region', 'city', 'latitude', 'longitude',
            'endpoint', 'method', 'response_code', 'response_time_ms',
            'details', 'error_message', 'session_id', 'request_id',
            'referrer', 'source_application', 'timestamp', 'processed_at',
            'is_suspicious', 'is_failed_attempt'
        ]
        read_only_fields = ['log_id', 'timestamp', 'processed_at']


class AuthenticationLogCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating authentication logs."""
    
    class Meta:
        model = AuthenticationLog
        fields = [
            'user_email', 'user_id', 'user_type', 'action', 'status',
            'ip_address', 'user_agent', 'device_id', 'device_type', 'device_os', 'browser',
            'country', 'region', 'city', 'latitude', 'longitude',
            'endpoint', 'method', 'response_code', 'response_time_ms',
            'details', 'error_message', 'session_id', 'request_id',
            'referrer', 'source_application'
        ]
    
    def validate_action(self, value):
        """Validate that action is a valid choice."""
        valid_actions = [choice[0] for choice in AuthenticationLog.ACTION_CHOICES]
        if value not in valid_actions:
            raise serializers.ValidationError(f"Invalid action. Must be one of: {valid_actions}")
        return value


class SecurityEventSerializer(serializers.ModelSerializer):
    """Serializer for security events."""
    
    severity_display = serializers.CharField(source='get_severity_display', read_only=True)
    event_type_display = serializers.CharField(source='get_event_type_display', read_only=True)
    status_display = serializers.CharField(source='get_status_display', read_only=True)
    related_logs_count = serializers.SerializerMethodField()
    
    class Meta:
        model = SecurityEvent
        fields = [
            'event_id', 'user_email', 'event_type', 'event_type_display',
            'severity', 'severity_display', 'status', 'status_display',
            'title', 'description', 'recommendation', 'event_data', 'risk_score',
            'detected_at', 'resolved_at', 'last_updated',
            'investigated_by', 'investigation_notes', 'related_logs_count'
        ]
        read_only_fields = ['event_id', 'detected_at', 'last_updated']
    
    def get_related_logs_count(self, obj):
        """Get count of related authentication logs."""
        return obj.related_logs.count()


class SecurityEventDetailSerializer(SecurityEventSerializer):
    """Detailed serializer for security events including related logs."""
    
    related_logs = AuthenticationLogSerializer(many=True, read_only=True)
    
    class Meta(SecurityEventSerializer.Meta):
        fields = SecurityEventSerializer.Meta.fields + ['related_logs']


class LoginSessionSerializer(serializers.ModelSerializer):
    """Serializer for login sessions."""
    
    duration_minutes = serializers.SerializerMethodField()
    is_expired = serializers.BooleanField(read_only=True)
    
    class Meta:
        model = LoginSession
        fields = [
            'session_id', 'user_email', 'user_id', 'ip_address', 'device_id',
            'device_info', 'location_info', 'is_active', 'login_timestamp',
            'last_activity', 'logout_timestamp', 'jwt_token_id', 'refresh_token_id',
            'duration_minutes', 'is_expired'
        ]
        read_only_fields = ['login_timestamp', 'last_activity', 'logout_timestamp']
    
    def get_duration_minutes(self, obj):
        """Get session duration in minutes."""
        duration = obj.duration
        return int(duration.total_seconds() / 60)


class AuditTrailSerializer(serializers.ModelSerializer):
    """Serializer for audit trail."""
    
    action_display = serializers.CharField(source='get_action_display', read_only=True)
    
    class Meta:
        model = AuditTrail
        fields = [
            'audit_id', 'admin_email', 'admin_id', 'action', 'action_display',
            'description', 'target_user_email', 'target_user_id',
            'before_data', 'after_data', 'additional_info',
            'ip_address', 'user_agent', 'timestamp'
        ]
        read_only_fields = ['audit_id', 'timestamp']


class AuthenticationAnalyticsSerializer(serializers.Serializer):
    """Serializer for authentication analytics data."""
    
    total_logs = serializers.IntegerField()
    successful_logins = serializers.IntegerField()
    failed_logins = serializers.IntegerField()
    registrations = serializers.IntegerField()
    password_resets = serializers.IntegerField()
    security_events = serializers.IntegerField()
    unique_users = serializers.IntegerField()
    unique_ips = serializers.IntegerField()
    
    # Time series data
    hourly_stats = serializers.ListField(child=serializers.DictField())
    daily_stats = serializers.ListField(child=serializers.DictField())
    
    # Top stats
    top_actions = serializers.ListField(child=serializers.DictField())
    top_user_types = serializers.ListField(child=serializers.DictField())
    top_countries = serializers.ListField(child=serializers.DictField())
    top_devices = serializers.ListField(child=serializers.DictField())


class UserActivitySummarySerializer(serializers.Serializer):
    """Serializer for user activity summary."""
    
    user_email = serializers.EmailField()
    total_activities = serializers.IntegerField()
    last_login = serializers.DateTimeField()
    last_activity = serializers.DateTimeField()
    successful_logins = serializers.IntegerField()
    failed_logins = serializers.IntegerField()
    devices_used = serializers.IntegerField()
    countries_accessed = serializers.ListField(child=serializers.CharField())
    security_events = serializers.IntegerField()
    account_status = serializers.CharField()
    
    # Recent activities
    recent_activities = AuthenticationLogSerializer(many=True)


class SecurityDashboardSerializer(serializers.Serializer):
    """Serializer for security dashboard data."""
    
    # Current security status
    active_security_events = serializers.IntegerField()
    high_risk_events = serializers.IntegerField()
    failed_login_attempts_today = serializers.IntegerField()
    suspicious_activities_today = serializers.IntegerField()
    
    # Trends (compared to previous period)
    login_success_rate = serializers.FloatField()
    average_response_time = serializers.FloatField()
    unique_users_today = serializers.IntegerField()
    
    # Recent critical events
    recent_critical_events = SecurityEventSerializer(many=True)
    
    # Geographic distribution
    geographic_distribution = serializers.ListField(child=serializers.DictField())
    
    # Device and browser stats
    device_stats = serializers.ListField(child=serializers.DictField())
    browser_stats = serializers.ListField(child=serializers.DictField())


class LogFilterSerializer(serializers.Serializer):
    """Serializer for log filtering parameters."""
    
    start_date = serializers.DateTimeField(required=False, help_text="Start date for filtering logs")
    end_date = serializers.DateTimeField(required=False, help_text="End date for filtering logs")
    user_email = serializers.EmailField(required=False, help_text="Filter by user email")
    action = serializers.ChoiceField(
        choices=AuthenticationLog.ACTION_CHOICES, 
        required=False, 
        help_text="Filter by action type"
    )
    status = serializers.ChoiceField(
        choices=AuthenticationLog.STATUS_CHOICES, 
        required=False, 
        help_text="Filter by status"
    )
    user_type = serializers.ChoiceField(
        choices=AuthenticationLog.USER_TYPE_CHOICES, 
        required=False, 
        help_text="Filter by user type"
    )
    ip_address = serializers.IPAddressField(required=False, help_text="Filter by IP address")
    country = serializers.CharField(max_length=100, required=False, help_text="Filter by country")
    device_type = serializers.CharField(max_length=50, required=False, help_text="Filter by device type")
    
    def validate(self, data):
        """Validate filter parameters."""
        if data.get('start_date') and data.get('end_date'):
            if data['start_date'] > data['end_date']:
                raise serializers.ValidationError("start_date must be before end_date")
        return data


class BulkLogCreateSerializer(serializers.Serializer):
    """Serializer for bulk log creation."""
    
    logs = AuthenticationLogCreateSerializer(many=True)
    
    def validate_logs(self, value):
        """Validate that logs list is not empty and not too large."""
        if not value:
            raise serializers.ValidationError("Logs list cannot be empty")
        if len(value) > 1000:
            raise serializers.ValidationError("Cannot create more than 1000 logs at once")
        return value


class SuspiciousActivitySerializer(serializers.ModelSerializer):
    """Serializer for suspicious activities."""
    
    activity_type_display = serializers.CharField(source='get_activity_type_display', read_only=True)
    severity_display = serializers.CharField(source='get_severity_display', read_only=True)
    status_display = serializers.CharField(source='get_status_display', read_only=True)
    related_auth_logs_count = serializers.SerializerMethodField()
    
    class Meta:
        model = SuspiciousActivity
        fields = [
            'id', 'user_email', 'user_id', 'activity_type', 'activity_type_display',
            'severity', 'severity_display', 'status', 'status_display',
            'description', 'source_ip', 'country', 'region', 'city',
            'latitude', 'longitude', 'device_info', 'details',
            'detected_at', 'resolved_at', 'resolved_by', 'resolution_notes',
            'related_auth_logs_count'
        ]
        read_only_fields = ['id', 'detected_at', 'resolved_at']
    
    def get_related_auth_logs_count(self, obj):
        """Get count of related authentication logs."""
        return obj.related_auth_logs.count()


class SuspiciousActivityDetailSerializer(SuspiciousActivitySerializer):
    """Detailed serializer for suspicious activities including related logs."""
    
    related_auth_logs = AuthenticationLogSerializer(many=True, read_only=True)
    
    class Meta(SuspiciousActivitySerializer.Meta):
        fields = SuspiciousActivitySerializer.Meta.fields + ['related_auth_logs']


class ExportRequestSerializer(serializers.Serializer):
    """Serializer for log export requests."""
    
    format = serializers.ChoiceField(
        choices=['csv', 'json', 'xlsx'], 
        default='csv',
        help_text="Export format"
    )
    filters = LogFilterSerializer(required=False, help_text="Filters to apply to export")
    fields = serializers.ListField(
        child=serializers.CharField(),
        required=False,
        help_text="Specific fields to include in export"
    )
    max_records = serializers.IntegerField(
        default=10000,
        min_value=1,
        max_value=100000,
        help_text="Maximum number of records to export"
    )
