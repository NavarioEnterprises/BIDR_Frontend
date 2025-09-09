from django.db import models
from django.contrib.auth.models import User
from django.contrib.contenttypes.models import ContentType
from django.contrib.contenttypes.fields import GenericForeignKey


class ActivityLog(models.Model):
    """Log of all user and system activities"""
    # User information
    user = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True)
    
    # Activity details
    action = models.CharField(max_length=100)
    category = models.CharField(max_length=50, choices=[
        ('authentication', 'Authentication'),
        ('review', 'Review Activity'),
        ('return', 'Return Activity'),
        ('dispute', 'Dispute Activity'),
        ('notification', 'Notification Activity'),
        ('admin', 'Admin Activity'),
        ('system', 'System Activity'),
        ('api', 'API Activity'),
        ('other', 'Other')
    ])
    
    description = models.TextField()
    
    # Related object (generic foreign key)
    content_type = models.ForeignKey(ContentType, on_delete=models.SET_NULL, null=True, blank=True)
    object_id = models.PositiveIntegerField(null=True, blank=True)
    content_object = GenericForeignKey('content_type', 'object_id')
    
    # Request information
    ip_address = models.GenericIPAddressField(null=True, blank=True)
    user_agent = models.TextField(blank=True)
    request_method = models.CharField(max_length=10, blank=True)
    request_path = models.CharField(max_length=500, blank=True)
    
    # Additional data
    metadata = models.JSONField(default=dict, blank=True)
    
    # Status
    success = models.BooleanField(default=True)
    error_message = models.TextField(blank=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['user', '-created_at']),
            models.Index(fields=['category', '-created_at']),
            models.Index(fields=['action']),
            models.Index(fields=['success']),
        ]
    
    def __str__(self):
        user_str = self.user.username if self.user else 'System'
        return f"{user_str}: {self.action} ({self.created_at.strftime('%Y-%m-%d %H:%M')})"


class SystemLog(models.Model):
    """System-level logs for debugging and monitoring"""
    level = models.CharField(max_length=10, choices=[
        ('DEBUG', 'Debug'),
        ('INFO', 'Info'),
        ('WARNING', 'Warning'),
        ('ERROR', 'Error'),
        ('CRITICAL', 'Critical')
    ])
    
    logger_name = models.CharField(max_length=100)
    message = models.TextField()
    
    # Context
    module = models.CharField(max_length=100, blank=True)
    function = models.CharField(max_length=100, blank=True)
    line_number = models.PositiveIntegerField(null=True, blank=True)
    
    # Exception details (if applicable)
    exception_type = models.CharField(max_length=100, blank=True)
    exception_message = models.TextField(blank=True)
    traceback = models.TextField(blank=True)
    
    # Additional context
    extra_data = models.JSONField(default=dict, blank=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['level', '-created_at']),
            models.Index(fields=['logger_name']),
            models.Index(fields=['created_at']),
        ]
    
    def __str__(self):
        return f"{self.level} - {self.logger_name}: {self.message[:100]}"


class APIRequestLog(models.Model):
    """Detailed logs of API requests"""
    # Request details
    method = models.CharField(max_length=10)
    path = models.CharField(max_length=500)
    query_params = models.TextField(blank=True)
    headers = models.JSONField(default=dict, blank=True)
    
    # Request body (truncated for large requests)
    request_body = models.TextField(blank=True)
    request_body_size = models.PositiveIntegerField(default=0)
    
    # Response details
    status_code = models.PositiveIntegerField()
    response_body = models.TextField(blank=True)
    response_body_size = models.PositiveIntegerField(default=0)
    response_headers = models.JSONField(default=dict, blank=True)
    
    # Timing
    processing_time = models.FloatField()  # in milliseconds
    
    # Client information
    ip_address = models.GenericIPAddressField(null=True, blank=True)
    user_agent = models.TextField(blank=True)
    user = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True)
    
    # Authentication
    api_key = models.CharField(max_length=100, blank=True)
    auth_method = models.CharField(max_length=50, blank=True)
    
    # Errors
    error_message = models.TextField(blank=True)
    exception_type = models.CharField(max_length=100, blank=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['method', 'path']),
            models.Index(fields=['status_code']),
            models.Index(fields=['user', '-created_at']),
            models.Index(fields=['-created_at']),
        ]
    
    def __str__(self):
        return f"{self.method} {self.path} - {self.status_code} ({self.processing_time:.2f}ms)"


class SecurityLog(models.Model):
    """Security-related events and violations"""
    event_type = models.CharField(max_length=50, choices=[
        ('login_attempt', 'Login Attempt'),
        ('login_success', 'Login Success'),
        ('login_failure', 'Login Failure'),
        ('logout', 'Logout'),
        ('password_change', 'Password Change'),
        ('account_locked', 'Account Locked'),
        ('suspicious_activity', 'Suspicious Activity'),
        ('rate_limit_exceeded', 'Rate Limit Exceeded'),
        ('unauthorized_access', 'Unauthorized Access'),
        ('data_breach_attempt', 'Data Breach Attempt'),
        ('admin_action', 'Admin Action'),
        ('other', 'Other')
    ])
    
    user = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True)
    ip_address = models.GenericIPAddressField(null=True, blank=True)
    user_agent = models.TextField(blank=True)
    
    # Event details
    description = models.TextField()
    severity = models.CharField(max_length=10, choices=[
        ('low', 'Low'),
        ('medium', 'Medium'),
        ('high', 'High'),
        ('critical', 'Critical')
    ], default='medium')
    
    # Additional context
    request_path = models.CharField(max_length=500, blank=True)
    additional_data = models.JSONField(default=dict, blank=True)
    
    # Investigation status
    is_investigated = models.BooleanField(default=False)
    investigation_notes = models.TextField(blank=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['event_type', '-created_at']),
            models.Index(fields=['severity', '-created_at']),
            models.Index(fields=['user', '-created_at']),
            models.Index(fields=['ip_address']),
        ]
    
    def __str__(self):
        user_str = self.user.username if self.user else 'Unknown'
        return f"{self.event_type} - {user_str} ({self.severity})"


class DataChangeLog(models.Model):
    """Track changes to important data models"""
    # Changed object
    content_type = models.ForeignKey(ContentType, on_delete=models.CASCADE)
    object_id = models.PositiveIntegerField()
    content_object = GenericForeignKey('content_type', 'object_id')
    
    # Change details
    action = models.CharField(max_length=10, choices=[
        ('CREATE', 'Create'),
        ('UPDATE', 'Update'),
        ('DELETE', 'Delete')
    ])
    
    # Who made the change
    user = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True)
    
    # What changed
    field_changes = models.JSONField(default=dict, blank=True)  # {field: {'old': value, 'new': value}}
    previous_values = models.JSONField(default=dict, blank=True)
    new_values = models.JSONField(default=dict, blank=True)
    
    # Context
    reason = models.TextField(blank=True)
    ip_address = models.GenericIPAddressField(null=True, blank=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['content_type', 'object_id']),
            models.Index(fields=['user', '-created_at']),
            models.Index(fields=['action', '-created_at']),
        ]
    
    def __str__(self):
        return f"{self.action} {self.content_type.model} #{self.object_id}"


class PerformanceLog(models.Model):
    """Performance metrics and monitoring"""
    metric_name = models.CharField(max_length=100)
    metric_type = models.CharField(max_length=20, choices=[
        ('response_time', 'Response Time'),
        ('database_query', 'Database Query'),
        ('cache_hit_rate', 'Cache Hit Rate'),
        ('memory_usage', 'Memory Usage'),
        ('cpu_usage', 'CPU Usage'),
        ('disk_usage', 'Disk Usage'),
        ('network_io', 'Network I/O'),
        ('custom', 'Custom Metric')
    ])
    
    # Metric value
    value = models.FloatField()
    unit = models.CharField(max_length=20, blank=True)  # e.g., 'ms', 'MB', '%'
    
    # Context
    endpoint = models.CharField(max_length=200, blank=True)
    query_type = models.CharField(max_length=50, blank=True)
    additional_context = models.JSONField(default=dict, blank=True)
    
    # Thresholds
    threshold_warning = models.FloatField(null=True, blank=True)
    threshold_critical = models.FloatField(null=True, blank=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['metric_name', '-created_at']),
            models.Index(fields=['metric_type', '-created_at']),
            models.Index(fields=['endpoint']),
        ]
    
    def __str__(self):
        return f"{self.metric_name}: {self.value} {self.unit}"


class ErrorLog(models.Model):
    """Application errors and exceptions"""
    error_type = models.CharField(max_length=100)
    error_message = models.TextField()
    traceback = models.TextField(blank=True)
    
    # Context
    request_path = models.CharField(max_length=500, blank=True)
    request_method = models.CharField(max_length=10, blank=True)
    user = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True)
    ip_address = models.GenericIPAddressField(null=True, blank=True)
    
    # Error details
    status_code = models.PositiveIntegerField(null=True, blank=True)
    module = models.CharField(max_length=100, blank=True)
    function = models.CharField(max_length=100, blank=True)
    line_number = models.PositiveIntegerField(null=True, blank=True)
    
    # Additional data
    request_data = models.JSONField(default=dict, blank=True)
    context_data = models.JSONField(default=dict, blank=True)
    
    # Resolution
    is_resolved = models.BooleanField(default=False)
    resolution_notes = models.TextField(blank=True)
    resolved_at = models.DateTimeField(null=True, blank=True)
    resolved_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True, related_name='resolved_errors')
    
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['error_type', '-created_at']),
            models.Index(fields=['is_resolved']),
            models.Index(fields=['status_code']),
            models.Index(fields=['-created_at']),
        ]
    
    def __str__(self):
        return f"{self.error_type}: {self.error_message[:100]}"


class LogArchive(models.Model):
    """Archived logs for long-term storage"""
    log_type = models.CharField(max_length=50)
    start_date = models.DateTimeField()
    end_date = models.DateTimeField()
    
    # Archive details
    record_count = models.PositiveIntegerField()
    file_path = models.CharField(max_length=500)  # Path to archived file
    file_size = models.PositiveIntegerField()  # Size in bytes
    compression_format = models.CharField(max_length=20, default='gzip')
    
    # Status
    status = models.CharField(max_length=20, choices=[
        ('pending', 'Pending'),
        ('processing', 'Processing'),
        ('completed', 'Completed'),
        ('failed', 'Failed')
    ], default='pending')
    
    created_at = models.DateTimeField(auto_now_add=True)
    completed_at = models.DateTimeField(null=True, blank=True)
    
    def __str__(self):
        return f"{self.log_type} archive ({self.start_date.date()} to {self.end_date.date()})"
