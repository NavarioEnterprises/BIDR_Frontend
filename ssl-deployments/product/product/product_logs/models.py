"""
Product Logs models for the BIDR Inventory Service.

This module tracks all changes made to products, inventory, pricing,
and other product-related data for audit and analytics purposes.
"""

from django.db import models
from django.contrib.auth.models import User
from django.contrib.contenttypes.models import ContentType
from django.contrib.contenttypes.fields import GenericForeignKey
from django.utils import timezone
from core.models import BaseModel, StatusChoices
from core.encryption import encrypt_field, decrypt_field
import json


class ChangeType(models.TextChoices):
    """Types of changes that can be tracked."""
    CREATE = 'create', 'Create'
    UPDATE = 'update', 'Update'
    DELETE = 'delete', 'Delete'
    RESTORE = 'restore', 'Restore'
    STATUS_CHANGE = 'status_change', 'Status Change'
    PRICE_CHANGE = 'price_change', 'Price Change'
    INVENTORY_CHANGE = 'inventory_change', 'Inventory Change'
    IMAGE_CHANGE = 'image_change', 'Image Change'
    ATTRIBUTE_CHANGE = 'attribute_change', 'Attribute Change'
    BULK_UPDATE = 'bulk_update', 'Bulk Update'


class ProductChangeLog(BaseModel):
    """
    Comprehensive change log for all product-related modifications.
    """
    # What was changed
    content_type = models.ForeignKey(
        ContentType,
        on_delete=models.CASCADE,
        help_text="Type of object that was changed"
    )
    object_id = models.CharField(max_length=100, help_text="ID of the changed object")
    content_object = GenericForeignKey('content_type', 'object_id')
    
    # Change details
    change_type = models.CharField(
        max_length=20,
        choices=ChangeType.choices,
        help_text="Type of change made"
    )
    field_name = models.CharField(
        max_length=100,
        blank=True,
        help_text="Specific field that was changed"
    )
    
    # Values (encrypted for sensitive data)
    old_value_encrypted = models.TextField(
        blank=True,
        help_text="Previous value (encrypted)"
    )
    new_value_encrypted = models.TextField(
        blank=True,
        help_text="New value (encrypted)"
    )
    
    # Change metadata
    change_reason = models.CharField(
        max_length=500,
        blank=True,
        help_text="Reason for the change"
    )
    change_source = models.CharField(
        max_length=100,
        default='manual',
        help_text="Source of change (manual, api, bulk_import, etc.)"
    )
    
    # Who made the change
    changed_by = models.ForeignKey(
        User,
        on_delete=models.PROTECT,
        null=True,
        blank=True,
        related_name='product_changes'
    )
    
    # Additional context
    ip_address = models.GenericIPAddressField(
        null=True,
        blank=True,
        help_text="IP address of the user who made the change"
    )
    user_agent = models.TextField(
        blank=True,
        help_text="User agent of the client"
    )
    
    # Change impact
    affects_inventory = models.BooleanField(
        default=False,
        help_text="Whether this change affects inventory levels"
    )
    affects_pricing = models.BooleanField(
        default=False,
        help_text="Whether this change affects pricing"
    )
    affects_availability = models.BooleanField(
        default=False,
        help_text="Whether this change affects product availability"
    )
    
    class Meta:
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['content_type', 'object_id']),
            models.Index(fields=['change_type', 'created_at']),
            models.Index(fields=['changed_by', 'created_at']),
            models.Index(fields=['affects_inventory', 'created_at']),
            models.Index(fields=['affects_pricing', 'created_at']),
            models.Index(fields=['field_name']),
        ]
    
    def __str__(self):
        return f"{self.change_type} on {self.content_type} {self.object_id} at {self.created_at}"
    
    @property
    def old_value(self):
        """Decrypt and return the old value."""
        if self.old_value_encrypted:
            return decrypt_field(self.old_value_encrypted)
        return None
    
    @old_value.setter
    def old_value(self, value):
        """Encrypt and store the old value."""
        if value is not None:
            if not isinstance(value, str):
                value = json.dumps(value, default=str)
            self.old_value_encrypted = encrypt_field(value)
        else:
            self.old_value_encrypted = None
    
    @property
    def new_value(self):
        """Decrypt and return the new value."""
        if self.new_value_encrypted:
            return decrypt_field(self.new_value_encrypted)
        return None
    
    @new_value.setter
    def new_value(self, value):
        """Encrypt and store the new value."""
        if value is not None:
            if not isinstance(value, str):
                value = json.dumps(value, default=str)
            self.new_value_encrypted = encrypt_field(value)
        else:
            self.new_value_encrypted = None
    
    def get_change_summary(self):
        """Get a human-readable summary of the change."""
        obj_name = f"{self.content_type.model} {self.object_id}"
        
        if self.change_type == ChangeType.CREATE:
            return f"Created {obj_name}"
        elif self.change_type == ChangeType.DELETE:
            return f"Deleted {obj_name}"
        elif self.change_type == ChangeType.UPDATE and self.field_name:
            return f"Updated {self.field_name} of {obj_name}"
        else:
            return f"{self.get_change_type_display()} on {obj_name}"


class ProductAccessLog(BaseModel):
    """
    Log of product access for analytics and security monitoring.
    """
    ACCESS_TYPES = [
        ('view', 'View'),
        ('search', 'Search'),
        ('filter', 'Filter'),
        ('export', 'Export'),
        ('api_access', 'API Access'),
    ]
    
    # What was accessed
    content_type = models.ForeignKey(
        ContentType,
        on_delete=models.CASCADE
    )
    object_id = models.CharField(max_length=100)
    content_object = GenericForeignKey('content_type', 'object_id')
    
    # Access details
    access_type = models.CharField(max_length=20, choices=ACCESS_TYPES)
    user = models.ForeignKey(
        User,
        on_delete=models.PROTECT,
        null=True,
        blank=True,
        related_name='product_accesses'
    )
    
    # Request details
    ip_address = models.GenericIPAddressField(null=True, blank=True)
    user_agent = models.TextField(blank=True)
    referer = models.URLField(blank=True)
    request_path = models.CharField(max_length=500, blank=True)
    request_method = models.CharField(max_length=10, blank=True)
    
    # Additional context
    search_query = models.CharField(
        max_length=500,
        blank=True,
        help_text="Search query if access was through search"
    )
    filters_applied = models.JSONField(
        default=dict,
        blank=True,
        help_text="Filters applied if access was through filtering"
    )
    
    class Meta:
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['content_type', 'object_id']),
            models.Index(fields=['access_type', 'created_at']),
            models.Index(fields=['user', 'created_at']),
            models.Index(fields=['ip_address', 'created_at']),
        ]
    
    def __str__(self):
        return f"{self.access_type} of {self.content_type} {self.object_id} by {self.user or 'Anonymous'}"


class BulkOperationLog(BaseModel):
    """
    Log of bulk operations performed on products.
    """
    OPERATION_TYPES = [
        ('bulk_create', 'Bulk Create'),
        ('bulk_update', 'Bulk Update'),
        ('bulk_delete', 'Bulk Delete'),
        ('bulk_import', 'Bulk Import'),
        ('bulk_export', 'Bulk Export'),
        ('bulk_price_update', 'Bulk Price Update'),
        ('bulk_inventory_update', 'Bulk Inventory Update'),
        ('bulk_status_change', 'Bulk Status Change'),
    ]
    
    STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('in_progress', 'In Progress'),
        ('completed', 'Completed'),
        ('failed', 'Failed'),
        ('partially_completed', 'Partially Completed'),
    ]
    
    # Operation details
    operation_type = models.CharField(max_length=30, choices=OPERATION_TYPES)
    operation_name = models.CharField(
        max_length=200,
        help_text="Human-readable name for the operation"
    )
    description = models.TextField(
        blank=True,
        help_text="Detailed description of the operation"
    )
    
    # Who performed the operation
    performed_by = models.ForeignKey(
        User,
        on_delete=models.PROTECT,
        related_name='bulk_operations'
    )
    
    # Operation status and results
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    total_records = models.IntegerField(
        default=0,
        help_text="Total number of records to process"
    )
    processed_records = models.IntegerField(
        default=0,
        help_text="Number of records processed"
    )
    successful_records = models.IntegerField(
        default=0,
        help_text="Number of records successfully processed"
    )
    failed_records = models.IntegerField(
        default=0,
        help_text="Number of records that failed processing"
    )
    
    # Timing
    started_at = models.DateTimeField(null=True, blank=True)
    completed_at = models.DateTimeField(null=True, blank=True)
    
    # Results and errors
    results_summary = models.JSONField(
        default=dict,
        blank=True,
        help_text="Summary of operation results"
    )
    error_details = models.JSONField(
        default=list,
        blank=True,
        help_text="Details of any errors that occurred"
    )
    
    # File references (for import/export operations)
    input_file_path = models.CharField(
        max_length=500,
        blank=True,
        help_text="Path to input file for import operations"
    )
    output_file_path = models.CharField(
        max_length=500,
        blank=True,
        help_text="Path to output file for export operations"
    )
    
    class Meta:
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['operation_type', 'status']),
            models.Index(fields=['performed_by', 'created_at']),
            models.Index(fields=['status', 'created_at']),
        ]
    
    def __str__(self):
        return f"{self.operation_name} by {self.performed_by.username} - {self.status}"
    
    @property
    def progress_percentage(self):
        """Calculate progress percentage."""
        if self.total_records == 0:
            return 0
        return round((self.processed_records / self.total_records) * 100, 2)
    
    @property
    def success_rate(self):
        """Calculate success rate percentage."""
        if self.processed_records == 0:
            return 0
        return round((self.successful_records / self.processed_records) * 100, 2)
    
    @property
    def duration(self):
        """Calculate operation duration."""
        if self.started_at and self.completed_at:
            return self.completed_at - self.started_at
        elif self.started_at:
            return timezone.now() - self.started_at
        return None
    
    def start_operation(self):
        """Mark operation as started."""
        self.status = 'in_progress'
        self.started_at = timezone.now()
        self.save(update_fields=['status', 'started_at'])
    
    def complete_operation(self, success=True):
        """Mark operation as completed."""
        if success and self.failed_records == 0:
            self.status = 'completed'
        elif success and self.failed_records > 0:
            self.status = 'partially_completed'
        else:
            self.status = 'failed'
        
        self.completed_at = timezone.now()
        self.save(update_fields=['status', 'completed_at'])
    
    def add_error(self, error_message, record_id=None, additional_data=None):
        """Add an error to the operation log."""
        error_entry = {
            'timestamp': timezone.now().isoformat(),
            'message': error_message,
            'record_id': record_id,
            'additional_data': additional_data
        }
        
        self.error_details.append(error_entry)
        self.failed_records += 1
        self.processed_records += 1
        
        self.save(update_fields=['error_details', 'failed_records', 'processed_records'])
    
    def add_success(self, record_id=None, additional_data=None):
        """Add a successful operation to the log."""
        self.successful_records += 1
        self.processed_records += 1
        
        # Optionally store successful record info in results_summary
        if record_id:
            if 'successful_records' not in self.results_summary:
                self.results_summary['successful_records'] = []
            
            self.results_summary['successful_records'].append({
                'record_id': record_id,
                'timestamp': timezone.now().isoformat(),
                'additional_data': additional_data
            })
        
        self.save(update_fields=['successful_records', 'processed_records', 'results_summary'])


# Signal handlers for automatic logging
from django.db.models.signals import post_save, post_delete, pre_save
from django.dispatch import receiver
# from products.models import Product, ProductVariant, ProductImage, ProductAttribute  # Commented out - products app removed


# Temporarily commented out - products app removed
# @receiver(pre_save, sender=Product)
# def log_product_changes(sender, instance, **kwargs):
#     """Log changes to products before saving."""
#     if instance.pk:  # Only for updates
#         try:
#             old_instance = Product.objects.get(pk=instance.pk)
#             
#             # Check for significant changes
#             changes = []
#             
#             # Price changes
#             if old_instance.base_price != instance.base_price:
#                 changes.append({
#                     'field': 'base_price',
#                     'old_value': str(old_instance.base_price),
#                     'new_value': str(instance.base_price),
#                     'affects_pricing': True
#                 })
#             
#             # Status changes
#             if old_instance.status != instance.status:
#                 changes.append({
#                     'field': 'status',
#                     'old_value': old_instance.status,
#                     'new_value': instance.status,
#                     'affects_availability': True
#                 })
#             
#             # Inventory changes
#             if old_instance.quantity_available != instance.quantity_available:
#                 changes.append({
#                     'field': 'quantity_available',
#                     'old_value': str(old_instance.quantity_available),
#                     'new_value': str(instance.quantity_available),
#                     'affects_inventory': True
#                 })
#             
#             # Log each change
#             for change in changes:
#                 ProductChangeLog.objects.create(
#                     content_object=instance,
#                     change_type=ChangeType.UPDATE,
#                     field_name=change['field'],
#                     old_value=change['old_value'],
#                     new_value=change['new_value'],
#                     affects_pricing=change.get('affects_pricing', False),
#                     affects_inventory=change.get('affects_inventory', False),
#                     affects_availability=change.get('affects_availability', False),
#                     change_source='model_save'
#                 )
#                 
#         except Product.DoesNotExist:
#             pass  # New product, will be logged by post_save
# 
# 
# @receiver(post_save, sender=Product)
# def log_product_creation(sender, instance, created, **kwargs):
#     """Log product creation."""
#     if created:
#         ProductChangeLog.objects.create(
#             content_object=instance,
#             change_type=ChangeType.CREATE,
#             new_value=f"Product created: {instance.name}",
#             change_source='model_save'
#         )
# 
# 
# @receiver(post_delete, sender=Product)
# def log_product_deletion(sender, instance, **kwargs):
#     """Log product deletion."""
#     ProductChangeLog.objects.create(
#         content_type=ContentType.objects.get_for_model(Product),
#         object_id=str(instance.pk),
#         change_type=ChangeType.DELETE,
#         old_value=f"Product deleted: {instance.name}",
#         change_source='model_delete'
#     )
