import uuid
from django.db import models
from django.utils import timezone


class NotificationLog(models.Model):
    """Detailed logs for notification delivery"""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    notification_id = models.UUIDField(help_text="Reference to notification in system_notifications")
    channel_type = models.CharField(max_length=20)
    
    # Delivery attempt
    attempt_number = models.PositiveIntegerField(default=1)
    status = models.CharField(max_length=20, choices=[
        ('queued', 'Queued'),
        ('sending', 'Sending'),
        ('sent', 'Sent'),
        ('delivered', 'Delivered'),
        ('failed', 'Failed'),
        ('bounced', 'Bounced'),
        ('rejected', 'Rejected'),
        ('timeout', 'Timeout'),
        ('cancelled', 'Cancelled'),
    ])
    
    # Details
    external_id = models.CharField(max_length=255, blank=True, help_text="ID from external service")
    response_data = models.JSONField(default=dict, blank=True)
    error_message = models.TextField(blank=True)
    error_code = models.CharField(max_length=50, blank=True)
    
    # Timing
    processing_time_ms = models.PositiveIntegerField(null=True, blank=True, help_text="Processing time in milliseconds")
    
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['notification_id']),
            models.Index(fields=['status']),
            models.Index(fields=['channel_type', '-created_at']),
        ]
    
    def __str__(self):
        return f"Log for notification {self.notification_id} - {self.status}"


class SystemLog(models.Model):
    """System-wide logs for notification service"""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    
    # Log details
    level = models.CharField(max_length=10, choices=[
        ('DEBUG', 'Debug'),
        ('INFO', 'Info'),
        ('WARNING', 'Warning'),
        ('ERROR', 'Error'),
        ('CRITICAL', 'Critical'),
    ])
    
    component = models.CharField(max_length=50, help_text="System component that generated the log")
    action = models.CharField(max_length=100, help_text="Action being performed")
    message = models.TextField()
    
    # Context data
    context_data = models.JSONField(default=dict, blank=True)
    user_id = models.UUIDField(null=True, blank=True, help_text="User ID if action was user-initiated")
    session_id = models.CharField(max_length=100, blank=True)
    request_id = models.CharField(max_length=100, blank=True)
    
    # Additional metadata
    ip_address = models.GenericIPAddressField(null=True, blank=True)
    user_agent = models.TextField(blank=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['level', '-created_at']),
            models.Index(fields=['component']),
            models.Index(fields=['user_id']),
        ]
    
    def __str__(self):
        return f"{self.level}: {self.component} - {self.action}"


class ErrorLog(models.Model):
    """Specific error logs with detailed information"""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    
    # Error information
    error_type = models.CharField(max_length=100, help_text="Exception class name")
    error_message = models.TextField()
    stack_trace = models.TextField(blank=True)
    
    # Context
    component = models.CharField(max_length=50)
    function_name = models.CharField(max_length=100, blank=True)
    line_number = models.PositiveIntegerField(null=True, blank=True)
    
    # Related entities
    notification_id = models.UUIDField(null=True, blank=True)
    user_id = models.UUIDField(null=True, blank=True)
    
    # Request context
    request_method = models.CharField(max_length=10, blank=True)
    request_url = models.URLField(blank=True)
    request_data = models.JSONField(default=dict, blank=True)
    
    # Environment
    environment = models.CharField(max_length=20, choices=[
        ('development', 'Development'),
        ('staging', 'Staging'),
        ('production', 'Production'),
    ], default='development')
    
    # Status
    is_resolved = models.BooleanField(default=False)
    resolved_at = models.DateTimeField(null=True, blank=True)
    resolution_notes = models.TextField(blank=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['error_type']),
            models.Index(fields=['component']),
            models.Index(fields=['is_resolved', '-created_at']),
        ]
    
    def __str__(self):
        return f"{self.error_type}: {self.error_message[:50]}..."


class AuditLog(models.Model):
    """Audit logs for tracking administrative actions"""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    
    # User information
    user_id = models.UUIDField(help_text="User who performed the action")
    username = models.CharField(max_length=150, blank=True)
    
    # Action details
    action = models.CharField(max_length=100, choices=[
        ('create', 'Create'),
        ('update', 'Update'),
        ('delete', 'Delete'),
        ('view', 'View'),
        ('login', 'Login'),
        ('logout', 'Logout'),
        ('password_change', 'Password Change'),
        ('permission_change', 'Permission Change'),
        ('bulk_action', 'Bulk Action'),
    ])
    
    resource_type = models.CharField(max_length=50, help_text="Type of resource affected")
    resource_id = models.CharField(max_length=100, blank=True, help_text="ID of the specific resource")
    
    # Details
    description = models.TextField()
    changes = models.JSONField(default=dict, blank=True, help_text="Before/after values for updates")
    
    # Request context
    ip_address = models.GenericIPAddressField(null=True, blank=True)
    user_agent = models.TextField(blank=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['user_id', '-created_at']),
            models.Index(fields=['action']),
            models.Index(fields=['resource_type']),
        ]
    
    def __str__(self):
        return f"{self.username} {self.action} {self.resource_type}"


class APILog(models.Model):
    """Logs for API requests and responses"""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    
    # Request information
    method = models.CharField(max_length=10)
    endpoint = models.URLField()
    user_id = models.UUIDField(null=True, blank=True)
    
    # Request/Response details
    request_headers = models.JSONField(default=dict, blank=True)
    request_body = models.JSONField(default=dict, blank=True)
    response_status = models.PositiveIntegerField()
    response_body = models.JSONField(default=dict, blank=True)
    
    # Timing
    processing_time_ms = models.PositiveIntegerField(help_text="Processing time in milliseconds")
    
    # Client information
    ip_address = models.GenericIPAddressField(null=True, blank=True)
    user_agent = models.TextField(blank=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['method', 'endpoint']),
            models.Index(fields=['response_status']),
            models.Index(fields=['-created_at']),
        ]
    
    def __str__(self):
        return f"{self.method} {self.endpoint} - {self.response_status}"
