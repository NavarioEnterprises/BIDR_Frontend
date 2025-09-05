import uuid
from django.db import models
from django.utils import timezone
from datetime import date, timedelta
from decimal import Decimal


class NotificationStatistics(models.Model):
    """Daily statistics for notifications"""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    date = models.DateField(unique=True)
    
    # Counts by type
    total_sent = models.PositiveIntegerField(default=0)
    email_sent = models.PositiveIntegerField(default=0)
    sms_sent = models.PositiveIntegerField(default=0)
    push_sent = models.PositiveIntegerField(default=0)
    in_app_sent = models.PositiveIntegerField(default=0)
    
    # Success rates
    email_success_rate = models.FloatField(default=0.0)
    sms_success_rate = models.FloatField(default=0.0)
    push_success_rate = models.FloatField(default=0.0)
    
    # Response rates
    total_opened = models.PositiveIntegerField(default=0)
    total_clicked = models.PositiveIntegerField(default=0)
    total_read = models.PositiveIntegerField(default=0)
    
    # Performance metrics
    avg_processing_time_ms = models.FloatField(default=0.0)
    total_failed = models.PositiveIntegerField(default=0)
    total_bounced = models.PositiveIntegerField(default=0)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['-date']
        indexes = [
            models.Index(fields=['date']),
        ]
    
    def __str__(self):
        return f"Notification stats for {self.date}"
    
    @property
    def overall_success_rate(self):
        """Calculate overall success rate"""
        if self.total_sent == 0:
            return 0.0
        successful = self.total_sent - self.total_failed
        return (successful / self.total_sent) * 100


class ChannelAnalytics(models.Model):
    """Analytics data for specific notification channels"""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    channel_name = models.CharField(max_length=50)
    channel_type = models.CharField(max_length=20)
    date = models.DateField()
    
    # Volume metrics
    total_notifications = models.PositiveIntegerField(default=0)
    successful_deliveries = models.PositiveIntegerField(default=0)
    failed_deliveries = models.PositiveIntegerField(default=0)
    
    # Engagement metrics
    opened_count = models.PositiveIntegerField(default=0)
    clicked_count = models.PositiveIntegerField(default=0)
    unsubscribed_count = models.PositiveIntegerField(default=0)
    
    # Performance metrics
    avg_delivery_time_ms = models.FloatField(default=0.0)
    max_delivery_time_ms = models.FloatField(default=0.0)
    min_delivery_time_ms = models.FloatField(default=0.0)
    
    # Cost metrics (if applicable)
    total_cost = models.DecimalField(max_digits=10, decimal_places=4, default=Decimal('0.0000'))
    cost_per_notification = models.DecimalField(max_digits=8, decimal_places=4, default=Decimal('0.0000'))
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        unique_together = ['channel_name', 'date']
        ordering = ['-date', 'channel_name']
        indexes = [
            models.Index(fields=['channel_type', 'date']),
            models.Index(fields=['date']),
        ]
    
    def __str__(self):
        return f"{self.channel_name} analytics for {self.date}"
    
    @property
    def success_rate(self):
        """Calculate success rate as percentage"""
        if self.total_notifications == 0:
            return 0.0
        return (self.successful_deliveries / self.total_notifications) * 100
    
    @property
    def open_rate(self):
        """Calculate open rate as percentage"""
        if self.successful_deliveries == 0:
            return 0.0
        return (self.opened_count / self.successful_deliveries) * 100
    
    @property
    def click_through_rate(self):
        """Calculate click-through rate as percentage"""
        if self.opened_count == 0:
            return 0.0
        return (self.clicked_count / self.opened_count) * 100


class UserEngagementMetrics(models.Model):
    """Track user engagement with notifications"""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user_id = models.UUIDField()
    date = models.DateField()
    
    # Notification counts
    notifications_received = models.PositiveIntegerField(default=0)
    notifications_read = models.PositiveIntegerField(default=0)
    notifications_clicked = models.PositiveIntegerField(default=0)
    notifications_dismissed = models.PositiveIntegerField(default=0)
    
    # Engagement timing
    avg_time_to_read_minutes = models.FloatField(default=0.0)
    total_engagement_time_minutes = models.FloatField(default=0.0)
    
    # Preferences
    preferences_changed = models.PositiveIntegerField(default=0)
    unsubscribe_events = models.PositiveIntegerField(default=0)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        unique_together = ['user_id', 'date']
        ordering = ['-date', 'user_id']
        indexes = [
            models.Index(fields=['user_id', 'date']),
        ]
    
    def __str__(self):
        return f"User {self.user_id} engagement for {self.date}"
    
    @property
    def read_rate(self):
        """Calculate read rate as percentage"""
        if self.notifications_received == 0:
            return 0.0
        return (self.notifications_read / self.notifications_received) * 100
    
    @property
    def engagement_score(self):
        """Calculate engagement score (0-100)"""
        if self.notifications_received == 0:
            return 0.0
        
        # Weighted scoring
        read_weight = 0.3
        click_weight = 0.5
        time_weight = 0.2
        
        read_score = (self.notifications_read / self.notifications_received) * read_weight
        click_score = (self.notifications_clicked / self.notifications_received) * click_weight
        time_score = min(self.total_engagement_time_minutes / 60, 1.0) * time_weight  # Cap at 1 hour
        
        return (read_score + click_score + time_score) * 100


class NotificationTypeAnalytics(models.Model):
    """Analytics for different notification types"""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    notification_type = models.CharField(max_length=50)
    date = models.DateField()
    
    # Volume metrics
    total_sent = models.PositiveIntegerField(default=0)
    successful_deliveries = models.PositiveIntegerField(default=0)
    failed_deliveries = models.PositiveIntegerField(default=0)
    
    # Engagement metrics
    total_opened = models.PositiveIntegerField(default=0)
    total_clicked = models.PositiveIntegerField(default=0)
    total_dismissed = models.PositiveIntegerField(default=0)
    
    # Timing metrics
    avg_processing_time_ms = models.FloatField(default=0.0)
    avg_time_to_read_minutes = models.FloatField(default=0.0)
    
    # User interaction
    unique_recipients = models.PositiveIntegerField(default=0)
    repeat_interactions = models.PositiveIntegerField(default=0)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        unique_together = ['notification_type', 'date']
        ordering = ['-date', 'notification_type']
        indexes = [
            models.Index(fields=['notification_type', 'date']),
        ]
    
    def __str__(self):
        return f"{self.notification_type} analytics for {self.date}"
    
    @property
    def success_rate(self):
        if self.total_sent == 0:
            return 0.0
        return (self.successful_deliveries / self.total_sent) * 100
    
    @property
    def engagement_rate(self):
        if self.successful_deliveries == 0:
            return 0.0
        engaged = self.total_opened + self.total_clicked
        return (engaged / self.successful_deliveries) * 100


class SystemPerformanceMetrics(models.Model):
    """System-wide performance metrics"""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    timestamp = models.DateTimeField()
    
    # Queue metrics
    queue_size = models.PositiveIntegerField(default=0)
    avg_queue_wait_time_ms = models.FloatField(default=0.0)
    max_queue_wait_time_ms = models.FloatField(default=0.0)
    
    # Processing metrics
    notifications_processed_per_minute = models.FloatField(default=0.0)
    avg_processing_time_ms = models.FloatField(default=0.0)
    error_rate_percentage = models.FloatField(default=0.0)
    
    # Resource utilization
    cpu_usage_percentage = models.FloatField(default=0.0)
    memory_usage_percentage = models.FloatField(default=0.0)
    
    # Channel health
    active_channels = models.PositiveIntegerField(default=0)
    failing_channels = models.PositiveIntegerField(default=0)
    
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        ordering = ['-timestamp']
        indexes = [
            models.Index(fields=['timestamp']),
        ]
    
    def __str__(self):
        return f"System metrics at {self.timestamp}"


class TrendAnalysis(models.Model):
    """Trend analysis data for notifications"""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    metric_name = models.CharField(max_length=100)
    time_period = models.CharField(max_length=20, choices=[
        ('daily', 'Daily'),
        ('weekly', 'Weekly'),
        ('monthly', 'Monthly'),
        ('quarterly', 'Quarterly'),
    ])
    period_start = models.DateField()
    period_end = models.DateField()
    
    # Trend data
    current_value = models.FloatField()
    previous_value = models.FloatField(default=0.0)
    change_percentage = models.FloatField(default=0.0)
    trend_direction = models.CharField(max_length=10, choices=[
        ('up', 'Increasing'),
        ('down', 'Decreasing'),
        ('stable', 'Stable'),
    ])
    
    # Statistical data
    min_value = models.FloatField(default=0.0)
    max_value = models.FloatField(default=0.0)
    avg_value = models.FloatField(default=0.0)
    std_deviation = models.FloatField(default=0.0)
    
    # Context
    category = models.CharField(max_length=50, blank=True)
    subcategory = models.CharField(max_length=50, blank=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        unique_together = ['metric_name', 'time_period', 'period_start']
        ordering = ['-period_start', 'metric_name']
        indexes = [
            models.Index(fields=['metric_name', 'time_period']),
            models.Index(fields=['period_start', 'period_end']),
        ]
    
    def __str__(self):
        return f"{self.metric_name} trend for {self.period_start} - {self.period_end}"
