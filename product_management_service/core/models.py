"""
Core models and base classes for the BIDR Inventory Service.

This module provides abstract base models and common functionality
that is shared across different apps in the inventory service.
"""

import uuid
from django.db import models
from django.contrib.auth.models import User
from django.core.validators import MinValueValidator, MaxValueValidator
from django.utils import timezone


class TimestampedModel(models.Model):
    """
    Abstract base model that provides self-updating
    'created_at' and 'updated_at' fields.
    """
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        abstract = True


class UUIDModel(models.Model):
    """
    Abstract base model that uses UUID as primary key.
    """
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)

    class Meta:
        abstract = True


class SoftDeleteManager(models.Manager):
    """
    Manager that excludes soft-deleted objects by default.
    """
    def get_queryset(self):
        return super().get_queryset().filter(deleted_at__isnull=True)

    def with_deleted(self):
        """Include soft-deleted objects in queryset."""
        return super().get_queryset()

    def deleted_only(self):
        """Return only soft-deleted objects."""
        return super().get_queryset().filter(deleted_at__isnull=False)


class SoftDeleteModel(models.Model):
    """
    Abstract base model that provides soft delete functionality.
    """
    deleted_at = models.DateTimeField(null=True, blank=True)

    objects = SoftDeleteManager()
    all_objects = models.Manager()  # Access to all objects including deleted

    class Meta:
        abstract = True

    def delete(self, using=None, keep_parents=False, hard=False):
        """
        Soft delete the object unless hard=True is specified.
        """
        if hard:
            super().delete(using=using, keep_parents=keep_parents)
        else:
            self.deleted_at = timezone.now()
            self.save(using=using)

    def restore(self):
        """
        Restore a soft-deleted object.
        """
        self.deleted_at = None
        self.save()

    @property
    def is_deleted(self):
        """
        Check if the object is soft-deleted.
        """
        return self.deleted_at is not None


class BaseModel(UUIDModel, TimestampedModel, SoftDeleteModel):
    """
    Base model that combines UUID, timestamps, and soft delete functionality.
    """
    class Meta:
        abstract = True


class StatusChoices(models.TextChoices):
    """
    Common status choices used across different models.
    """
    ACTIVE = 'active', 'Active'
    INACTIVE = 'inactive', 'Inactive'
    PENDING = 'pending', 'Pending'
    APPROVED = 'approved', 'Approved'
    REJECTED = 'rejected', 'Rejected'
    CANCELLED = 'cancelled', 'Cancelled'
    COMPLETED = 'completed', 'Completed'
    EXPIRED = 'expired', 'Expired'
    DRAFT = 'draft', 'Draft'


class PriorityChoices(models.TextChoices):
    """
    Priority levels for requests, quotes, etc.
    """
    LOW = 'low', 'Low'
    MEDIUM = 'medium', 'Medium'
    HIGH = 'high', 'High'
    URGENT = 'urgent', 'Urgent'


class LocationMixin(models.Model):
    """
    Mixin that provides location functionality.
    """
    # Address components
    address_line_1 = models.CharField(max_length=255, blank=True)
    address_line_2 = models.CharField(max_length=255, blank=True)
    city = models.CharField(max_length=100, blank=True)
    state_province = models.CharField(max_length=100, blank=True)
    postal_code = models.CharField(max_length=20, blank=True)
    country = models.CharField(max_length=100, blank=True)
    
    # Coordinate fields (simplified without GIS)
    latitude = models.DecimalField(
        max_digits=10, 
        decimal_places=8, 
        null=True, 
        blank=True,
        validators=[MinValueValidator(-90), MaxValueValidator(90)]
    )
    longitude = models.DecimalField(
        max_digits=11, 
        decimal_places=8, 
        null=True, 
        blank=True,
        validators=[MinValueValidator(-180), MaxValueValidator(180)]
    )
    search_radius = models.IntegerField(
        default=50,
        validators=[MinValueValidator(1), MaxValueValidator(1000)],
        help_text="Search radius in kilometers"
    )

    class Meta:
        abstract = True

    def set_location_from_coordinates(self, latitude, longitude):
        """
        Set the location from latitude and longitude.
        """
        if latitude and longitude:
            self.latitude = latitude
            self.longitude = longitude

    @property
    def full_address(self):
        """
        Get the complete formatted address.
        """
        parts = [
            self.address_line_1,
            self.address_line_2,
            self.city,
            self.state_province,
            self.postal_code,
            self.country
        ]
        return ', '.join([part for part in parts if part])

    @property
    def coordinates(self):
        """
        Get latitude and longitude as a tuple.
        """
        if self.latitude and self.longitude:
            return (float(self.latitude), float(self.longitude))
        return None


class MetadataModel(models.Model):
    """
    Abstract model for storing metadata and additional information.
    """
    metadata = models.JSONField(default=dict, blank=True)
    tags = models.JSONField(default=list, blank=True)
    notes = models.TextField(blank=True)

    class Meta:
        abstract = True

    def add_tag(self, tag):
        """Add a tag to the tags list."""
        if tag not in self.tags:
            self.tags.append(tag)

    def remove_tag(self, tag):
        """Remove a tag from the tags list."""
        if tag in self.tags:
            self.tags.remove(tag)

    def set_metadata(self, key, value):
        """Set a metadata key-value pair."""
        self.metadata[key] = value

    def get_metadata(self, key, default=None):
        """Get a metadata value by key."""
        return self.metadata.get(key, default)


class AuditModel(models.Model):
    """
    Abstract model that tracks who created and last modified the object.
    """
    created_by = models.ForeignKey(
        User,
        on_delete=models.PROTECT,
        related_name='%(class)s_created',
        null=True,
        blank=True
    )
    updated_by = models.ForeignKey(
        User,
        on_delete=models.PROTECT,
        related_name='%(class)s_updated',
        null=True,
        blank=True
    )

    class Meta:
        abstract = True


class ComprehensiveBaseModel(BaseModel, LocationMixin, MetadataModel, AuditModel):
    """
    Most comprehensive base model that includes all common functionality.
    Use this for main business objects that need full tracking.
    """
    class Meta:
        abstract = True
