"""
BIDR Analytics Serializers

Serializers for analytics and reporting endpoints.
"""
from rest_framework import serializers

from .models import (
    AuthenticationMetric, UserBehaviorAnalytics, SystemPerformanceMetric,
    AuthenticationTrend, AnalyticsReport
)


class AuthenticationMetricSerializer(serializers.ModelSerializer):
    """Serializer for authentication metrics"""
    
    class Meta:
        model = AuthenticationMetric
        fields = [
            'uuid', 'name', 'category', 'metric_type', 'value', 'unit',
            'period', 'timestamp', 'period_start', 'period_end',
            'dimensions', 'tags', 'metadata', 'created_at'
        ]
        read_only_fields = ['uuid', 'created_at']


class UserBehaviorAnalyticsSerializer(serializers.ModelSerializer):
    """Serializer for user behavior analytics"""
    
    user_email = serializers.CharField(source='user.email', read_only=True)
    login_success_rate = serializers.SerializerMethodField()
    api_error_rate = serializers.SerializerMethodField()
    
    class Meta:
        model = UserBehaviorAnalytics
        fields = [
            'uuid', 'user_email', 'user_type', 'date', 'period_type',
            'login_count', 'successful_logins', 'failed_logins',
            'unique_devices', 'unique_locations', 'total_session_time',
            'average_session_time', 'max_session_time', 'session_count',
            'most_active_hour', 'most_active_day', 'device_types',
            'browsers', 'operating_systems', 'countries', 'cities',
            'security_events', 'risk_score_avg', 'risk_score_max',
            'api_requests', 'api_errors', 'login_success_rate', 'api_error_rate',
            'created_at', 'updated_at'
        ]
        read_only_fields = ['uuid', 'created_at', 'updated_at', 'login_success_rate', 'api_error_rate']
    
    def get_login_success_rate(self, obj):
        return obj.calculate_login_success_rate()
    
    def get_api_error_rate(self, obj):
        return obj.calculate_api_error_rate()


class SystemPerformanceMetricSerializer(serializers.ModelSerializer):
    """Serializer for system performance metrics"""
    
    success_rate = serializers.SerializerMethodField()
    
    class Meta:
        model = SystemPerformanceMetric
        fields = [
            'uuid', 'metric_name', 'component', 'response_time_avg',
            'response_time_min', 'response_time_max', 'response_time_p50',
            'response_time_p95', 'response_time_p99', 'total_requests',
            'successful_requests', 'failed_requests', 'error_rate',
            'error_breakdown', 'period', 'timestamp', 'period_start',
            'period_end', 'metadata', 'success_rate', 'created_at'
        ]
        read_only_fields = ['uuid', 'created_at', 'success_rate']
    
    def get_success_rate(self, obj):
        return obj.calculate_success_rate()


class AuthenticationTrendSerializer(serializers.ModelSerializer):
    """Serializer for authentication trends"""
    
    class Meta:
        model = AuthenticationTrend
        fields = [
            'uuid', 'trend_name', 'category', 'date', 'period_type',
            'current_value', 'previous_value', 'change_absolute',
            'change_percentage', 'is_increasing', 'is_decreasing',
            'is_stable', 'moving_average_7', 'moving_average_30',
            'dimensions', 'metadata', 'created_at', 'updated_at'
        ]
        read_only_fields = ['uuid', 'created_at', 'updated_at']


class AnalyticsReportSerializer(serializers.ModelSerializer):
    """Serializer for analytics reports"""
    
    generated_by_email = serializers.CharField(source='generated_by.email', read_only=True)
    is_expired = serializers.BooleanField(read_only=True)
    
    class Meta:
        model = AnalyticsReport
        fields = [
            'uuid', 'name', 'description', 'report_type', 'filters',
            'parameters', 'start_date', 'end_date', 'data', 'summary',
            'status', 'generated_by_email', 'generation_time', 'error_message',
            'file_path', 'file_size', 'created_at', 'generated_at',
            'expires_at', 'is_expired'
        ]
        read_only_fields = [
            'uuid', 'data', 'summary', 'status', 'generated_by_email',
            'generation_time', 'error_message', 'file_path', 'file_size',
            'created_at', 'generated_at', 'is_expired'
        ]


class AnalyticsReportCreateSerializer(serializers.Serializer):
    """Serializer for creating analytics reports"""
    
    name = serializers.CharField(max_length=255)
    description = serializers.CharField(required=False, allow_blank=True)
    report_type = serializers.ChoiceField(
        choices=[
            ('daily_summary', 'Daily Summary'),
            ('weekly_summary', 'Weekly Summary'),
            ('monthly_summary', 'Monthly Summary'),
            ('security_report', 'Security Report'),
            ('performance_report', 'Performance Report'),
            ('user_behavior', 'User Behavior Report'),
            ('custom', 'Custom Report'),
        ]
    )
    filters = serializers.DictField(required=False, default=dict)
    parameters = serializers.DictField(required=False, default=dict)
    start_date = serializers.DateTimeField()
    end_date = serializers.DateTimeField()
    expires_at = serializers.DateTimeField(required=False)


class MetricsSummarySerializer(serializers.Serializer):
    """Serializer for metrics summary dashboard"""
    
    total_users = serializers.IntegerField()
    active_users_today = serializers.IntegerField()
    total_logins_today = serializers.IntegerField()
    failed_logins_today = serializers.IntegerField()
    login_success_rate = serializers.FloatField()
    total_sessions = serializers.IntegerField()
    active_sessions = serializers.IntegerField()
    avg_session_duration = serializers.FloatField()
    security_events_today = serializers.IntegerField()
    api_requests_today = serializers.IntegerField()
    api_error_rate = serializers.FloatField()
    system_performance_score = serializers.FloatField()


class TrendAnalysisSerializer(serializers.Serializer):
    """Serializer for trend analysis data"""
    
    period = serializers.CharField()
    login_trend = serializers.ListField()
    registration_trend = serializers.ListField()
    security_events_trend = serializers.ListField()
    performance_trend = serializers.ListField()
    user_growth_trend = serializers.ListField()
