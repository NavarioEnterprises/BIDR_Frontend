"""
Logging models for the BIDR Product Management Service.

This module provides comprehensive logging functionality including:
- API request logging and monitoring
- Application event logging  
- Category and product request tracking
- Error and performance monitoring
"""

import uuid
import json
from django.db import models
from django.contrib.auth.models import User
from django.contrib.contenttypes.models import ContentType
from django.contrib.contenttypes.fields import GenericForeignKey
from django.utils import timezone
from decimal import Decimal


class LogLevel(models.TextChoices):
    """Log levels for different types of events."""
    DEBUG = 'DEBUG', 'Debug'
    INFO = 'INFO', 'Info'
    WARNING = 'WARNING', 'Warning'
    ERROR = 'ERROR', 'Error'
    CRITICAL = 'CRITICAL', 'Critical'


class EventType(models.TextChoices):
    """Types of events that can be logged."""
    API_REQUEST = 'API_REQUEST', 'API Request'
    USER_ACTION = 'USER_ACTION', 'User Action'
    SYSTEM_EVENT = 'SYSTEM_EVENT', 'System Event'
    DATA_CHANGE = 'DATA_CHANGE', 'Data Change'
    ERROR_EVENT = 'ERROR_EVENT', 'Error Event'
    AUTHENTICATION = 'AUTHENTICATION', 'Authentication'
    BUSINESS_LOGIC = 'BUSINESS_LOGIC', 'Business Logic'


class APIRequestLog(models.Model):
    """
    Detailed logging of all API requests made to the service.
    Tracks request/response details, performance metrics, and user activity.
    """
    
    # Primary identification
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    
    # Request details
    method = models.CharField(max_length=10, help_text="HTTP method (GET, POST, etc.)")
    path = models.CharField(max_length=500, help_text="Request path/endpoint")
    full_url = models.TextField(help_text="Complete request URL")
    query_params = models.JSONField(null=True, blank=True, help_text="Query parameters")
    
    # Request headers and body
    headers = models.JSONField(null=True, blank=True, help_text="Request headers")
    request_body = models.TextField(null=True, blank=True, help_text="Request body content")
    request_size = models.IntegerField(null=True, blank=True, help_text="Request size in bytes")
    
    # Response details
    status_code = models.IntegerField(help_text="HTTP response status code")
    response_body = models.TextField(null=True, blank=True, help_text="Response body content")
    response_size = models.IntegerField(null=True, blank=True, help_text="Response size in bytes")
    response_headers = models.JSONField(null=True, blank=True, help_text="Response headers")
    
    # Performance metrics
    duration_ms = models.DecimalField(
        max_digits=10, 
        decimal_places=3, 
        null=True, 
        blank=True,
        help_text="Request duration in milliseconds"
    )
    
    # User and session information
    user = models.ForeignKey(
        User, 
        on_delete=models.SET_NULL, 
        null=True, 
        blank=True,
        help_text="User who made the request"
    )
    session_id = models.CharField(max_length=40, null=True, blank=True, help_text="Session ID")
    ip_address = models.GenericIPAddressField(null=True, blank=True, help_text="Client IP address")
    user_agent = models.TextField(null=True, blank=True, help_text="User agent string")
    
    # Additional context
    view_name = models.CharField(max_length=200, null=True, blank=True, help_text="Django view name")
    endpoint_category = models.CharField(max_length=100, null=True, blank=True, help_text="API endpoint category")
    
    # Error information (if applicable)
    error_message = models.TextField(null=True, blank=True, help_text="Error message if request failed")
    error_traceback = models.TextField(null=True, blank=True, help_text="Error traceback")
    
    # Timestamps
    timestamp = models.DateTimeField(default=timezone.now, help_text="When the request was made")
    
    class Meta:
        db_table = 'api_request_log'
        ordering = ['-timestamp']
        indexes = [
            models.Index(fields=['timestamp']),
            models.Index(fields=['user', 'timestamp']),
            models.Index(fields=['method', 'path']),
            models.Index(fields=['status_code']),
            models.Index(fields=['endpoint_category']),
            models.Index(fields=['ip_address']),
        ]
        
    def __str__(self):
        return f"{self.method} {self.path} - {self.status_code} ({self.timestamp})"
    
    @property
    def is_successful(self):
        """Check if the request was successful (2xx status code)."""
        return 200 <= self.status_code < 300
    
    @property
    def is_client_error(self):
        """Check if the request had a client error (4xx status code)."""
        return 400 <= self.status_code < 500
    
    @property
    def is_server_error(self):
        """Check if the request had a server error (5xx status code)."""
        return 500 <= self.status_code < 600
    
    @property
    def duration_seconds(self):
        """Get duration in seconds."""
        if self.duration_ms:
            return self.duration_ms / 1000
        return None


class ApplicationLog(models.Model):
    """
    General application event logging for tracking system events,
    business logic execution, and application state changes.
    """
    
    # Primary identification
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    
    # Log classification
    level = models.CharField(
        max_length=10, 
        choices=LogLevel.choices, 
        default=LogLevel.INFO,
        help_text="Log severity level"
    )
    event_type = models.CharField(
        max_length=20, 
        choices=EventType.choices,
        help_text="Type of event being logged"
    )
    
    # Event details
    message = models.TextField(help_text="Human-readable log message")
    category = models.CharField(max_length=100, help_text="Log category (e.g., 'product_requests', 'analytics')")
    subcategory = models.CharField(max_length=100, null=True, blank=True, help_text="Log subcategory")
    
    # Context and metadata
    context_data = models.JSONField(null=True, blank=True, help_text="Additional context information")
    tags = models.JSONField(null=True, blank=True, help_text="Tags for filtering and searching")
    
    # User and session information
    user = models.ForeignKey(
        User, 
        on_delete=models.SET_NULL, 
        null=True, 
        blank=True,
        help_text="User associated with this event"
    )
    session_id = models.CharField(max_length=40, null=True, blank=True, help_text="Session ID")
    ip_address = models.GenericIPAddressField(null=True, blank=True, help_text="Client IP address")
    
    # Related object (generic foreign key)
    content_type = models.ForeignKey(ContentType, on_delete=models.CASCADE, null=True, blank=True)
    object_id = models.CharField(max_length=255, null=True, blank=True)
    content_object = GenericForeignKey('content_type', 'object_id')
    
    # Error information (if applicable)
    error_code = models.CharField(max_length=50, null=True, blank=True, help_text="Error code")
    error_details = models.JSONField(null=True, blank=True, help_text="Detailed error information")
    
    # Performance metrics
    execution_time_ms = models.DecimalField(
        max_digits=10, 
        decimal_places=3, 
        null=True, 
        blank=True,
        help_text="Execution time in milliseconds"
    )
    
    # Timestamps
    timestamp = models.DateTimeField(default=timezone.now, help_text="When the event occurred")
    
    class Meta:
        db_table = 'application_log'
        ordering = ['-timestamp']
        indexes = [
            models.Index(fields=['timestamp']),
            models.Index(fields=['level', 'timestamp']),
            models.Index(fields=['event_type', 'timestamp']),
            models.Index(fields=['category', 'timestamp']),
            models.Index(fields=['user', 'timestamp']),
            models.Index(fields=['content_type', 'object_id']),
        ]
        
    def __str__(self):
        return f"[{self.level}] {self.category}: {self.message[:50]}..."


class ProductRequestLog(models.Model):
    """
    Specific logging for product request related activities.
    Tracks creation, updates, views, and interactions with product requests.
    """
    
    # Primary identification
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    
    # Reference to product request (using CharField for UUID)
    product_request_id = models.CharField(
        max_length=36, 
        help_text="UUID of the product request"
    )
    
    # Action details
    action = models.CharField(
        max_length=50, 
        help_text="Action performed (created, updated, viewed, etc.)"
    )
    action_details = models.JSONField(
        null=True, 
        blank=True,
        help_text="Additional details about the action"
    )
    
    # User and context
    user = models.ForeignKey(
        User, 
        on_delete=models.SET_NULL, 
        null=True, 
        blank=True,
        help_text="User who performed the action"
    )
    ip_address = models.GenericIPAddressField(null=True, blank=True, help_text="Client IP address")
    user_agent = models.TextField(null=True, blank=True, help_text="User agent string")
    
    # Request context
    category = models.CharField(max_length=50, null=True, blank=True, help_text="Product request category")
    title = models.CharField(max_length=200, null=True, blank=True, help_text="Product request title")
    
    # Changes tracking (for updates)
    old_values = models.JSONField(null=True, blank=True, help_text="Previous values (for updates)")
    new_values = models.JSONField(null=True, blank=True, help_text="New values (for updates)")
    
    # Performance and metadata
    source = models.CharField(
        max_length=100, 
        null=True, 
        blank=True,
        help_text="Source of the action (web, mobile, api, etc.)"
    )
    
    # Timestamps
    timestamp = models.DateTimeField(default=timezone.now, help_text="When the action occurred")
    
    class Meta:
        db_table = 'product_request_log'
        ordering = ['-timestamp']
        indexes = [
            models.Index(fields=['product_request_id', 'timestamp']),
            models.Index(fields=['action', 'timestamp']),
            models.Index(fields=['user', 'timestamp']),
            models.Index(fields=['category', 'timestamp']),
            models.Index(fields=['timestamp']),
        ]
        
    def __str__(self):
        return f"{self.action} on {self.product_request_id} by {self.user or 'Anonymous'}"


class CategoryLog(models.Model):
    """
    Logging for category-related activities and changes.
    Tracks category usage, modifications, and analytics.
    """
    
    # Primary identification
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    
    # Category reference
    category_id = models.IntegerField(help_text="ID of the category")
    category_name = models.CharField(max_length=200, help_text="Category name at time of logging")
    
    # Event details
    event = models.CharField(
        max_length=50, 
        help_text="Event type (accessed, modified, searched, etc.)"
    )
    event_data = models.JSONField(null=True, blank=True, help_text="Additional event data")
    
    # Context
    user = models.ForeignKey(
        User, 
        on_delete=models.SET_NULL, 
        null=True, 
        blank=True,
        help_text="User who triggered the event"
    )
    
    # Metrics
    request_count = models.IntegerField(default=1, help_text="Number of requests for this category")
    search_queries = models.JSONField(
        null=True, 
        blank=True,
        help_text="Search queries related to this category"
    )
    
    # Timestamps
    timestamp = models.DateTimeField(default=timezone.now, help_text="When the event occurred")
    
    class Meta:
        db_table = 'category_log'
        ordering = ['-timestamp']
        indexes = [
            models.Index(fields=['category_id', 'timestamp']),
            models.Index(fields=['event', 'timestamp']),
            models.Index(fields=['user', 'timestamp']),
            models.Index(fields=['timestamp']),
        ]
        
    def __str__(self):
        return f"{self.event} on {self.category_name} ({self.timestamp})"


class PerformanceLog(models.Model):
    """
    Performance monitoring and metrics logging.
    Tracks system performance, slow queries, and resource usage.
    """
    
    # Primary identification
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    
    # Performance metrics
    metric_name = models.CharField(max_length=100, help_text="Name of the performance metric")
    metric_value = models.DecimalField(
        max_digits=15, 
        decimal_places=6,
        help_text="Performance metric value"
    )
    metric_unit = models.CharField(max_length=20, help_text="Unit of measurement (ms, mb, count, etc.)")
    
    # Context
    operation = models.CharField(max_length=200, help_text="Operation being measured")
    endpoint = models.CharField(max_length=500, null=True, blank=True, help_text="API endpoint (if applicable)")
    
    # Metadata
    metadata = models.JSONField(null=True, blank=True, help_text="Additional performance metadata")
    
    # Thresholds and alerts
    threshold_exceeded = models.BooleanField(default=False, help_text="Whether a performance threshold was exceeded")
    severity = models.CharField(
        max_length=10, 
        choices=LogLevel.choices, 
        default=LogLevel.INFO,
        help_text="Severity of the performance metric"
    )
    
    # Timestamps
    timestamp = models.DateTimeField(default=timezone.now, help_text="When the metric was recorded")
    
    class Meta:
        db_table = 'performance_log'
        ordering = ['-timestamp']
        indexes = [
            models.Index(fields=['metric_name', 'timestamp']),
            models.Index(fields=['operation', 'timestamp']),
            models.Index(fields=['threshold_exceeded', 'timestamp']),
            models.Index(fields=['severity', 'timestamp']),
            models.Index(fields=['timestamp']),
        ]
        
    def __str__(self):
        return f"{self.metric_name}: {self.metric_value} {self.metric_unit} ({self.operation})"


class ErrorLog(models.Model):
    """
    Dedicated error logging for detailed error tracking and debugging.
    """
    
    # Primary identification
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    
    # Error details
    error_type = models.CharField(max_length=100, help_text="Type/class of error")
    error_message = models.TextField(help_text="Error message")
    error_code = models.CharField(max_length=50, null=True, blank=True, help_text="Application error code")
    
    # Stack trace and debugging info
    stack_trace = models.TextField(null=True, blank=True, help_text="Full stack trace")
    file_path = models.CharField(max_length=500, null=True, blank=True, help_text="File where error occurred")
    line_number = models.IntegerField(null=True, blank=True, help_text="Line number where error occurred")
    function_name = models.CharField(max_length=200, null=True, blank=True, help_text="Function where error occurred")
    
    # Request context (if from an API request)
    request_id = models.UUIDField(null=True, blank=True, help_text="Related API request ID")
    method = models.CharField(max_length=10, null=True, blank=True, help_text="HTTP method")
    path = models.CharField(max_length=500, null=True, blank=True, help_text="Request path")
    
    # User context
    user = models.ForeignKey(
        User, 
        on_delete=models.SET_NULL, 
        null=True, 
        blank=True,
        help_text="User who encountered the error"
    )
    session_id = models.CharField(max_length=40, null=True, blank=True, help_text="Session ID")
    ip_address = models.GenericIPAddressField(null=True, blank=True, help_text="Client IP address")
    
    # Additional context
    context_data = models.JSONField(null=True, blank=True, help_text="Additional error context")
    
    # Resolution tracking
    is_resolved = models.BooleanField(default=False, help_text="Whether the error has been resolved")
    resolution_notes = models.TextField(null=True, blank=True, help_text="Notes about error resolution")
    resolved_by = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='resolved_errors',
        help_text="User who resolved the error"
    )
    resolved_at = models.DateTimeField(null=True, blank=True, help_text="When the error was resolved")
    
    # Timestamps
    timestamp = models.DateTimeField(default=timezone.now, help_text="When the error occurred")
    
    class Meta:
        db_table = 'error_log'
        ordering = ['-timestamp']
        indexes = [
            models.Index(fields=['error_type', 'timestamp']),
            models.Index(fields=['is_resolved', 'timestamp']),
            models.Index(fields=['user', 'timestamp']),
            models.Index(fields=['request_id']),
            models.Index(fields=['timestamp']),
        ]
        
    def __str__(self):
        return f"{self.error_type}: {self.error_message[:50]}..."
