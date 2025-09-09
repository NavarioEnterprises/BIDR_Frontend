import uuid
from django.db import models
from django.utils import timezone
from datetime import timedelta


class ServiceHealth(models.Model):
    """Overall health status of the notification service"""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    
    # Service status
    status = models.CharField(max_length=20, choices=[
        ('healthy', 'Healthy'),
        ('degraded', 'Degraded'),
        ('unhealthy', 'Unhealthy'),
        ('maintenance', 'Under Maintenance'),
    ], default='healthy')
    
    # Health metrics
    uptime_percentage = models.FloatField(default=100.0)
    response_time_ms = models.FloatField(default=0.0)
    error_rate_percentage = models.FloatField(default=0.0)
    
    # Resource usage
    cpu_usage_percentage = models.FloatField(default=0.0)
    memory_usage_percentage = models.FloatField(default=0.0)
    disk_usage_percentage = models.FloatField(default=0.0)
    
    # Queue health
    queue_size = models.PositiveIntegerField(default=0)
    oldest_message_age_minutes = models.FloatField(default=0.0)
    processing_rate_per_minute = models.FloatField(default=0.0)
    
    # Database health
    db_connection_pool_usage = models.FloatField(default=0.0)
    db_response_time_ms = models.FloatField(default=0.0)
    
    # External dependencies
    external_service_failures = models.PositiveIntegerField(default=0)
    
    # Last check information
    last_check_at = models.DateTimeField(default=timezone.now)
    check_duration_ms = models.FloatField(default=0.0)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['status']),
            models.Index(fields=['-created_at']),
        ]
    
    def __str__(self):
        return f"Service Health: {self.status} at {self.last_check_at}"
    
    @property
    def is_healthy(self):
        """Determine if service is healthy based on thresholds"""
        return (
            self.status == 'healthy' and
            self.error_rate_percentage < 5.0 and
            self.response_time_ms < 1000 and
            self.cpu_usage_percentage < 80.0 and
            self.memory_usage_percentage < 80.0
        )


class ComponentHealth(models.Model):
    """Health status for individual service components"""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    
    component_name = models.CharField(max_length=100)
    component_type = models.CharField(max_length=50, choices=[
        ('database', 'Database'),
        ('queue', 'Message Queue'),
        ('email_service', 'Email Service'),
        ('sms_service', 'SMS Service'),
        ('push_service', 'Push Notification Service'),
        ('webhook_service', 'Webhook Service'),
        ('api_endpoint', 'API Endpoint'),
        ('background_worker', 'Background Worker'),
        ('cache', 'Cache'),
        ('external_api', 'External API'),
    ])
    
    status = models.CharField(max_length=20, choices=[
        ('up', 'Up'),
        ('down', 'Down'),
        ('degraded', 'Degraded'),
        ('unknown', 'Unknown'),
    ])
    
    # Health metrics specific to component
    response_time_ms = models.FloatField(default=0.0)
    success_rate_percentage = models.FloatField(default=100.0)
    error_count = models.PositiveIntegerField(default=0)
    
    # Component-specific data
    metadata = models.JSONField(default=dict, blank=True)
    
    last_check_at = models.DateTimeField(default=timezone.now)
    last_success_at = models.DateTimeField(null=True, blank=True)
    last_failure_at = models.DateTimeField(null=True, blank=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        unique_together = ['component_name', 'component_type']
        ordering = ['component_name']
        indexes = [
            models.Index(fields=['component_type', 'status']),
            models.Index(fields=['status', '-last_check_at']),
        ]
    
    def __str__(self):
        return f"{self.component_name} ({self.component_type}): {self.status}"


class HealthCheck(models.Model):
    """Individual health check records"""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    
    check_name = models.CharField(max_length=100)
    check_type = models.CharField(max_length=50, choices=[
        ('ping', 'Ping Test'),
        ('database', 'Database Connection'),
        ('queue', 'Queue Connectivity'),
        ('email', 'Email Service'),
        ('sms', 'SMS Service'),
        ('push', 'Push Service'),
        ('webhook', 'Webhook Service'),
        ('disk_space', 'Disk Space'),
        ('memory', 'Memory Usage'),
        ('cpu', 'CPU Usage'),
        ('custom', 'Custom Check'),
    ])
    
    status = models.CharField(max_length=10, choices=[
        ('pass', 'Pass'),
        ('fail', 'Fail'),
        ('warn', 'Warning'),
    ])
    
    # Check details
    message = models.TextField(blank=True)
    duration_ms = models.FloatField(default=0.0)
    
    # Check results
    result_data = models.JSONField(default=dict, blank=True)
    expected_value = models.CharField(max_length=200, blank=True)
    actual_value = models.CharField(max_length=200, blank=True)
    
    # Timing
    executed_at = models.DateTimeField(default=timezone.now)
    timeout_seconds = models.PositiveIntegerField(default=30)
    
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        ordering = ['-executed_at']
        indexes = [
            models.Index(fields=['check_name', '-executed_at']),
            models.Index(fields=['status', '-executed_at']),
            models.Index(fields=['check_type']),
        ]
    
    def __str__(self):
        return f"{self.check_name}: {self.status} at {self.executed_at}"


class Alert(models.Model):
    """System alerts for health issues"""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    
    # Alert details
    alert_type = models.CharField(max_length=50, choices=[
        ('service_down', 'Service Down'),
        ('high_error_rate', 'High Error Rate'),
        ('slow_response', 'Slow Response Time'),
        ('queue_backlog', 'Queue Backlog'),
        ('resource_exhaustion', 'Resource Exhaustion'),
        ('external_service_failure', 'External Service Failure'),
        ('custom', 'Custom Alert'),
    ])
    
    severity = models.CharField(max_length=10, choices=[
        ('info', 'Info'),
        ('warning', 'Warning'),
        ('error', 'Error'),
        ('critical', 'Critical'),
    ])
    
    title = models.CharField(max_length=200)
    description = models.TextField()
    
    # Alert source
    source_component = models.CharField(max_length=100, blank=True)
    source_check = models.CharField(max_length=100, blank=True)
    
    # Alert status
    status = models.CharField(max_length=20, choices=[
        ('active', 'Active'),
        ('acknowledged', 'Acknowledged'),
        ('resolved', 'Resolved'),
        ('suppressed', 'Suppressed'),
    ], default='active')
    
    # Resolution
    acknowledged_by = models.CharField(max_length=100, blank=True)
    acknowledged_at = models.DateTimeField(null=True, blank=True)
    resolved_at = models.DateTimeField(null=True, blank=True)
    resolution_notes = models.TextField(blank=True)
    
    # Notification tracking
    notifications_sent = models.PositiveIntegerField(default=0)
    last_notification_at = models.DateTimeField(null=True, blank=True)
    
    # Alert data
    alert_data = models.JSONField(default=dict, blank=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['alert_type', 'severity']),
            models.Index(fields=['status', '-created_at']),
            models.Index(fields=['source_component']),
        ]
    
    def __str__(self):
        return f"{self.severity.upper()}: {self.title}"
    
    @property
    def is_active(self):
        return self.status == 'active'
    
    def acknowledge(self, acknowledged_by):
        """Acknowledge the alert"""
        self.status = 'acknowledged'
        self.acknowledged_by = acknowledged_by
        self.acknowledged_at = timezone.now()
        self.save()
    
    def resolve(self, resolution_notes=''):
        """Mark alert as resolved"""
        self.status = 'resolved'
        self.resolved_at = timezone.now()
        self.resolution_notes = resolution_notes
        self.save()


class MaintenanceWindow(models.Model):
    """Scheduled maintenance windows"""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    
    title = models.CharField(max_length=200)
    description = models.TextField()
    
    # Timing
    start_time = models.DateTimeField()
    end_time = models.DateTimeField()
    timezone_name = models.CharField(max_length=50, default='UTC')
    
    # Maintenance details
    maintenance_type = models.CharField(max_length=50, choices=[
        ('planned', 'Planned Maintenance'),
        ('emergency', 'Emergency Maintenance'),
        ('upgrade', 'System Upgrade'),
        ('patch', 'Security Patch'),
    ])
    
    # Affected components
    affected_components = models.JSONField(default=list, help_text="List of affected components")
    impact_level = models.CharField(max_length=20, choices=[
        ('low', 'Low Impact'),
        ('medium', 'Medium Impact'),
        ('high', 'High Impact'),
        ('full_outage', 'Full Outage'),
    ])
    
    # Status
    status = models.CharField(max_length=20, choices=[
        ('scheduled', 'Scheduled'),
        ('in_progress', 'In Progress'),
        ('completed', 'Completed'),
        ('cancelled', 'Cancelled'),
    ], default='scheduled')
    
    # Notifications
    notify_users = models.BooleanField(default=True)
    notification_sent = models.BooleanField(default=False)
    
    created_by = models.CharField(max_length=100)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['start_time']
        indexes = [
            models.Index(fields=['start_time', 'end_time']),
            models.Index(fields=['status']),
        ]
    
    def __str__(self):
        return f"{self.title} ({self.start_time} - {self.end_time})"
    
    @property
    def is_active(self):
        """Check if maintenance window is currently active"""
        now = timezone.now()
        return self.start_time <= now <= self.end_time
    
    @property
    def duration(self):
        """Get maintenance duration as timedelta"""
        return self.end_time - self.start_time
