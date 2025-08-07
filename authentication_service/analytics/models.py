"""
BIDR Analytics Models

This module contains models for tracking and analyzing authentication
metrics, user behavior, and system performance.
"""
import uuid
from datetime import timedelta
from django.db import models
from django.utils import timezone
from django.contrib.auth import get_user_model
from django.db.models import Avg, Count, Sum, Max, Min

User = get_user_model()


class MetricType(models.TextChoices):
    """Types of metrics we can track"""
    COUNTER = 'counter', 'Counter'
    GAUGE = 'gauge', 'Gauge'
    HISTOGRAM = 'histogram', 'Histogram'
    TIMER = 'timer', 'Timer'


class MetricPeriod(models.TextChoices):
    """Time periods for metrics aggregation"""
    MINUTE = 'minute', 'Per Minute'
    HOUR = 'hour', 'Per Hour'
    DAY = 'day', 'Per Day'
    WEEK = 'week', 'Per Week'
    MONTH = 'month', 'Per Month'


class AuthenticationMetric(models.Model):
    """
    Store authentication metrics and KPIs
    """
    id = models.BigAutoField(primary_key=True)
    uuid = models.UUIDField(default=uuid.uuid4, editable=False, unique=True)
    
    # Metric Identity
    name = models.CharField(
        max_length=200,
        help_text="Name of the metric (e.g., 'login_attempts', 'registration_count')"
    )
    category = models.CharField(
        max_length=100,
        help_text="Category of the metric (e.g., 'authentication', 'security')"
    )
    metric_type = models.CharField(
        max_length=20,
        choices=MetricType.choices,
        help_text="Type of metric"
    )
    
    # Metric Value
    value = models.FloatField(
        help_text="Numeric value of the metric"
    )
    unit = models.CharField(
        max_length=50,
        blank=True,
        null=True,
        help_text="Unit of measurement (e.g., 'requests', 'seconds', 'percentage')"
    )
    
    # Time Dimensions
    period = models.CharField(
        max_length=10,
        choices=MetricPeriod.choices,
        help_text="Time period this metric covers"
    )
    timestamp = models.DateTimeField(
        help_text="Timestamp for this metric data point"
    )
    period_start = models.DateTimeField(
        help_text="Start of the time period"
    )
    period_end = models.DateTimeField(
        help_text="End of the time period"
    )
    
    # Context and Dimensions
    dimensions = models.JSONField(
        default=dict,
        help_text="Additional dimensions for filtering (e.g., {'user_type': 'buyer', 'device': 'mobile'})"
    )
    tags = models.JSONField(
        default=list,
        help_text="Tags for categorization and filtering"
    )
    
    # Metadata
    metadata = models.JSONField(
        default=dict,
        help_text="Additional metadata about the metric"
    )
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        db_table = 'authentication_metrics'
        verbose_name = 'Authentication Metric'
        verbose_name_plural = 'Authentication Metrics'
        ordering = ['-timestamp']
        indexes = [
            models.Index(fields=['name', 'timestamp']),
            models.Index(fields=['category', 'timestamp']),
            models.Index(fields=['period', 'timestamp']),
            models.Index(fields=['timestamp']),
        ]
        unique_together = ['name', 'period', 'timestamp', 'dimensions']

    def __str__(self):
        return f"{self.name}: {self.value} {self.unit or ''} ({self.timestamp})"


class UserBehaviorAnalytics(models.Model):
    """
    Track user behavior patterns and analytics
    """
    id = models.BigAutoField(primary_key=True)
    uuid = models.UUIDField(default=uuid.uuid4, editable=False, unique=True)
    
    # User Context
    user = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='behavior_analytics',
        help_text="User this analytics record belongs to"
    )
    user_type = models.CharField(
        max_length=50,
        help_text="Type of user (buyer, seller, admin)"
    )
    
    # Time Period
    date = models.DateField(
        help_text="Date this analytics record covers"
    )
    period_type = models.CharField(
        max_length=10,
        choices=MetricPeriod.choices,
        default=MetricPeriod.DAY,
        help_text="Type of period (daily, weekly, monthly)"
    )
    
    # Login Behavior
    login_count = models.IntegerField(
        default=0,
        help_text="Number of login attempts"
    )
    successful_logins = models.IntegerField(
        default=0,
        help_text="Number of successful logins"
    )
    failed_logins = models.IntegerField(
        default=0,
        help_text="Number of failed login attempts"
    )
    unique_devices = models.IntegerField(
        default=0,
        help_text="Number of unique devices used"
    )
    unique_locations = models.IntegerField(
        default=0,
        help_text="Number of unique locations accessed from"
    )
    
    # Session Behavior
    total_session_time = models.DurationField(
        default=timedelta(0),
        help_text="Total time spent in sessions"
    )
    average_session_time = models.DurationField(
        default=timedelta(0),
        help_text="Average session duration"
    )
    max_session_time = models.DurationField(
        default=timedelta(0),
        help_text="Longest session duration"
    )
    session_count = models.IntegerField(
        default=0,
        help_text="Number of sessions"
    )
    
    # Activity Patterns
    most_active_hour = models.IntegerField(
        blank=True,
        null=True,
        help_text="Hour of day with most activity (0-23)"
    )
    most_active_day = models.IntegerField(
        blank=True,
        null=True,
        help_text="Day of week with most activity (0-6, Monday=0)"
    )
    
    # Device and Platform Usage
    device_types = models.JSONField(
        default=dict,
        help_text="Count of usage by device type"
    )
    browsers = models.JSONField(
        default=dict,
        help_text="Count of usage by browser"
    )
    operating_systems = models.JSONField(
        default=dict,
        help_text="Count of usage by operating system"
    )
    
    # Geographic Data
    countries = models.JSONField(
        default=dict,
        help_text="Count of logins by country"
    )
    cities = models.JSONField(
        default=dict,
        help_text="Count of logins by city"
    )
    
    # Security Metrics
    security_events = models.IntegerField(
        default=0,
        help_text="Number of security events triggered"
    )
    risk_score_avg = models.FloatField(
        default=0.0,
        help_text="Average risk score for the period"
    )
    risk_score_max = models.FloatField(
        default=0.0,
        help_text="Maximum risk score for the period"
    )
    
    # API Usage (if applicable)
    api_requests = models.IntegerField(
        default=0,
        help_text="Number of API requests made"
    )
    api_errors = models.IntegerField(
        default=0,
        help_text="Number of API errors encountered"
    )
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'user_behavior_analytics'
        verbose_name = 'User Behavior Analytics'
        verbose_name_plural = 'User Behavior Analytics'
        ordering = ['-date']
        unique_together = ['user', 'date', 'period_type']
        indexes = [
            models.Index(fields=['user', 'date']),
            models.Index(fields=['user_type', 'date']),
            models.Index(fields=['date']),
            models.Index(fields=['period_type']),
        ]

    def __str__(self):
        return f"{self.user.email} - {self.date} ({self.period_type})"

    def calculate_login_success_rate(self):
        """Calculate login success rate as percentage"""
        if self.login_count == 0:
            return 0.0
        return (self.successful_logins / self.login_count) * 100

    def calculate_api_error_rate(self):
        """Calculate API error rate as percentage"""
        if self.api_requests == 0:
            return 0.0
        return (self.api_errors / self.api_requests) * 100


class SystemPerformanceMetric(models.Model):
    """
    Track system performance metrics related to authentication
    """
    id = models.BigAutoField(primary_key=True)
    uuid = models.UUIDField(default=uuid.uuid4, editable=False, unique=True)
    
    # Metric Identity
    metric_name = models.CharField(
        max_length=200,
        help_text="Name of the performance metric"
    )
    component = models.CharField(
        max_length=100,
        help_text="System component (e.g., 'login_endpoint', 'otp_service')"
    )
    
    # Performance Data
    response_time_avg = models.FloatField(
        help_text="Average response time in milliseconds"
    )
    response_time_min = models.FloatField(
        help_text="Minimum response time in milliseconds"
    )
    response_time_max = models.FloatField(
        help_text="Maximum response time in milliseconds"
    )
    response_time_p50 = models.FloatField(
        blank=True,
        null=True,
        help_text="50th percentile response time"
    )
    response_time_p95 = models.FloatField(
        blank=True,
        null=True,
        help_text="95th percentile response time"
    )
    response_time_p99 = models.FloatField(
        blank=True,
        null=True,
        help_text="99th percentile response time"
    )
    
    # Request Metrics
    total_requests = models.IntegerField(
        help_text="Total number of requests"
    )
    successful_requests = models.IntegerField(
        help_text="Number of successful requests"
    )
    failed_requests = models.IntegerField(
        help_text="Number of failed requests"
    )
    
    # Error Metrics
    error_rate = models.FloatField(
        help_text="Error rate as percentage"
    )
    error_breakdown = models.JSONField(
        default=dict,
        help_text="Breakdown of errors by type/code"
    )
    
    # Time Period
    period = models.CharField(
        max_length=10,
        choices=MetricPeriod.choices,
        help_text="Time period for this metric"
    )
    timestamp = models.DateTimeField(
        help_text="Timestamp for this metric data point"
    )
    period_start = models.DateTimeField(
        help_text="Start of the measurement period"
    )
    period_end = models.DateTimeField(
        help_text="End of the measurement period"
    )
    
    # Additional Context
    metadata = models.JSONField(
        default=dict,
        help_text="Additional metadata"
    )
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        db_table = 'system_performance_metrics'
        verbose_name = 'System Performance Metric'
        verbose_name_plural = 'System Performance Metrics'
        ordering = ['-timestamp']
        indexes = [
            models.Index(fields=['component', 'timestamp']),
            models.Index(fields=['metric_name', 'timestamp']),
            models.Index(fields=['timestamp']),
        ]

    def __str__(self):
        return f"{self.component} - {self.metric_name} ({self.timestamp})"

    def calculate_success_rate(self):
        """Calculate success rate as percentage"""
        if self.total_requests == 0:
            return 0.0
        return (self.successful_requests / self.total_requests) * 100


class AuthenticationTrend(models.Model):
    """
    Track trends in authentication patterns over time
    """
    id = models.BigAutoField(primary_key=True)
    uuid = models.UUIDField(default=uuid.uuid4, editable=False, unique=True)
    
    # Trend Identity
    trend_name = models.CharField(
        max_length=200,
        help_text="Name of the trend being tracked"
    )
    category = models.CharField(
        max_length=100,
        help_text="Category of the trend (e.g., 'user_growth', 'security_events')"
    )
    
    # Time Period
    date = models.DateField(
        help_text="Date for this trend data point"
    )
    period_type = models.CharField(
        max_length=10,
        choices=MetricPeriod.choices,
        help_text="Type of period aggregation"
    )
    
    # Trend Data
    current_value = models.FloatField(
        help_text="Current value for the trend"
    )
    previous_value = models.FloatField(
        blank=True,
        null=True,
        help_text="Previous period value for comparison"
    )
    change_absolute = models.FloatField(
        blank=True,
        null=True,
        help_text="Absolute change from previous period"
    )
    change_percentage = models.FloatField(
        blank=True,
        null=True,
        help_text="Percentage change from previous period"
    )
    
    # Trend Direction
    is_increasing = models.BooleanField(
        default=False,
        help_text="Whether the trend is increasing"
    )
    is_decreasing = models.BooleanField(
        default=False,
        help_text="Whether the trend is decreasing"
    )
    is_stable = models.BooleanField(
        default=False,
        help_text="Whether the trend is stable"
    )
    
    # Statistical Data
    moving_average_7 = models.FloatField(
        blank=True,
        null=True,
        help_text="7-period moving average"
    )
    moving_average_30 = models.FloatField(
        blank=True,
        null=True,
        help_text="30-period moving average"
    )
    
    # Context
    dimensions = models.JSONField(
        default=dict,
        help_text="Additional dimensions for filtering"
    )
    metadata = models.JSONField(
        default=dict,
        help_text="Additional metadata"
    )
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'authentication_trends'
        verbose_name = 'Authentication Trend'
        verbose_name_plural = 'Authentication Trends'
        ordering = ['-date']
        unique_together = ['trend_name', 'date', 'period_type', 'dimensions']
        indexes = [
            models.Index(fields=['trend_name', 'date']),
            models.Index(fields=['category', 'date']),
            models.Index(fields=['date']),
        ]

    def __str__(self):
        return f"{self.trend_name} - {self.date} ({self.current_value})"

    def calculate_trend_direction(self):
        """Calculate and update trend direction"""
        if self.previous_value is None:
            self.is_stable = True
            return
        
        if self.change_percentage is None:
            return
        
        # Define thresholds for stable vs changing
        stable_threshold = 5.0  # 5% change considered stable
        
        if abs(self.change_percentage) <= stable_threshold:
            self.is_stable = True
            self.is_increasing = False
            self.is_decreasing = False
        elif self.change_percentage > 0:
            self.is_increasing = True
            self.is_stable = False
            self.is_decreasing = False
        else:
            self.is_decreasing = True
            self.is_stable = False
            self.is_increasing = False


class AnalyticsReport(models.Model):
    """
    Store generated analytics reports
    """
    REPORT_TYPES = [
        ('daily_summary', 'Daily Summary'),
        ('weekly_summary', 'Weekly Summary'),
        ('monthly_summary', 'Monthly Summary'),
        ('security_report', 'Security Report'),
        ('performance_report', 'Performance Report'),
        ('user_behavior', 'User Behavior Report'),
        ('custom', 'Custom Report'),
    ]
    
    REPORT_STATUS = [
        ('generating', 'Generating'),
        ('completed', 'Completed'),
        ('failed', 'Failed'),
        ('scheduled', 'Scheduled'),
    ]
    
    id = models.BigAutoField(primary_key=True)
    uuid = models.UUIDField(default=uuid.uuid4, editable=False, unique=True)
    
    # Report Identity
    name = models.CharField(
        max_length=255,
        help_text="Name of the report"
    )
    description = models.TextField(
        blank=True,
        null=True,
        help_text="Description of the report"
    )
    report_type = models.CharField(
        max_length=50,
        choices=REPORT_TYPES,
        help_text="Type of report"
    )
    
    # Report Configuration
    filters = models.JSONField(
        default=dict,
        help_text="Filters applied to the report"
    )
    parameters = models.JSONField(
        default=dict,
        help_text="Report parameters and configuration"
    )
    
    # Time Range
    start_date = models.DateTimeField(
        help_text="Start date for report data"
    )
    end_date = models.DateTimeField(
        help_text="End date for report data"
    )
    
    # Report Data
    data = models.JSONField(
        default=dict,
        help_text="Generated report data"
    )
    summary = models.JSONField(
        default=dict,
        help_text="Report summary and key metrics"
    )
    
    # Generation Info
    status = models.CharField(
        max_length=20,
        choices=REPORT_STATUS,
        default='scheduled',
        help_text="Current status of the report"
    )
    generated_by = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        help_text="User who generated the report"
    )
    generation_time = models.FloatField(
        blank=True,
        null=True,
        help_text="Time taken to generate report in seconds"
    )
    error_message = models.TextField(
        blank=True,
        null=True,
        help_text="Error message if generation failed"
    )
    
    # File Storage
    file_path = models.CharField(
        max_length=500,
        blank=True,
        null=True,
        help_text="Path to the generated report file"
    )
    file_size = models.IntegerField(
        blank=True,
        null=True,
        help_text="Size of the report file in bytes"
    )
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    generated_at = models.DateTimeField(
        blank=True,
        null=True,
        help_text="When the report was generated"
    )
    expires_at = models.DateTimeField(
        blank=True,
        null=True,
        help_text="When the report expires"
    )
    
    class Meta:
        db_table = 'analytics_reports'
        verbose_name = 'Analytics Report'
        verbose_name_plural = 'Analytics Reports'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['report_type', 'status']),
            models.Index(fields=['generated_by', 'created_at']),
            models.Index(fields=['start_date', 'end_date']),
            models.Index(fields=['created_at']),
        ]

    def __str__(self):
        return f"{self.name} ({self.report_type}) - {self.status}"

    def is_expired(self):
        """Check if the report has expired"""
        if self.expires_at:
            return timezone.now() >= self.expires_at
        return False

    def mark_completed(self, generation_time=None):
        """Mark the report as completed"""
        self.status = 'completed'
        self.generated_at = timezone.now()
        if generation_time:
            self.generation_time = generation_time
        self.save(update_fields=['status', 'generated_at', 'generation_time'])

    def mark_failed(self, error_message):
        """Mark the report as failed"""
        self.status = 'failed'
        self.error_message = error_message
        self.save(update_fields=['status', 'error_message'])
