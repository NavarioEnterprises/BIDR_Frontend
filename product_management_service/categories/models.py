"""
Category models for the BIDR Inventory Service.

This module defines the category system that organizes products
into hierarchical structures for easy browsing and filtering.
"""

from django.db import models
from django.core.validators import MinValueValidator, MaxValueValidator
from django.urls import reverse

from mptt.models import MPTTModel, TreeForeignKey
from core.models import BaseModel, MetadataModel, StatusChoices


class Category(MPTTModel, BaseModel, MetadataModel):
    """
    Hierarchical category model using MPTT for efficient tree operations.
    Categories can be nested to create subcategories.
    """
    name = models.CharField(max_length=100, unique=True)
    slug = models.SlugField(max_length=120, unique=True)
    description = models.TextField(blank=True)
    
    # Hierarchy
    parent = TreeForeignKey(
        'self',
        on_delete=models.CASCADE,
        null=True,
        blank=True,
        related_name='children'
    )
    
    # Display and ordering
    icon = models.CharField(max_length=50, blank=True, help_text="CSS icon class or emoji")
    image = models.ImageField(upload_to='categories/', blank=True, null=True)
    color = models.CharField(max_length=7, blank=True, help_text="Hex color code")
    sort_order = models.IntegerField(default=0)
    
    # Status and visibility
    status = models.CharField(
        max_length=20,
        choices=StatusChoices.choices,
        default=StatusChoices.ACTIVE
    )
    is_featured = models.BooleanField(default=False)
    show_in_menu = models.BooleanField(default=True)
    
    # SEO fields
    meta_title = models.CharField(max_length=60, blank=True)
    meta_description = models.CharField(max_length=160, blank=True)
    
    # Commission settings
    commission_rate = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        default=5.00,
        validators=[MinValueValidator(0), MaxValueValidator(100)],
        help_text="Commission rate as percentage"
    )
    
    class MPTTMeta:
        order_insertion_by = ['sort_order', 'name']
    
    class Meta:
        verbose_name_plural = "Categories"
        ordering = ['sort_order', 'name']
        indexes = [
            models.Index(fields=['status', 'show_in_menu']),
            models.Index(fields=['parent', 'status']),
            models.Index(fields=['is_featured']),
        ]
    
    def __str__(self):
        return self.name
    
    def get_absolute_url(self):
        return reverse('category-detail', kwargs={'slug': self.slug})
    
    @property
    def full_name(self):
        """Get the full category path name."""
        if self.parent:
            return f"{self.parent.full_name} > {self.name}"
        return self.name
    
    @property
    def breadcrumbs(self):
        """Get list of parent categories for breadcrumb navigation."""
        ancestors = list(self.get_ancestors(include_self=True))
        return [{'name': cat.name, 'slug': cat.slug} for cat in ancestors]
    
    def get_active_children(self):
        """Get only active child categories."""
        return self.get_children().filter(status=StatusChoices.ACTIVE)
    
    def get_product_count(self, include_subcategories=True):
        """Get count of products in this category."""
        # For now, return 0 since products app doesn't exist yet
        # This can be implemented when products app is created
        return 0
    
    def clean(self):
        """Custom validation."""
        super().clean()
        
        # Prevent circular references
        if self.parent and self.parent == self:
            raise ValueError("A category cannot be its own parent")
        
        # Validate commission rate
        if self.commission_rate < 0 or self.commission_rate > 100:
            raise ValueError("Commission rate must be between 0 and 100")

    def get_specification_type(self):
        """Get the specification type for this category or its ancestors."""
        try:
            # Check if specification exists for this category
            if hasattr(self, 'specification') and self.specification:
                return self.specification.category_type
        except AttributeError:
            pass
            
        # Check parent categories for specification
        for ancestor in self.get_ancestors():
            try:
                if hasattr(ancestor, 'specification') and ancestor.specification:
                    return ancestor.specification.category_type
            except AttributeError:
                continue
        return None

    def get_specification_schema(self):
        """Get the specification schema for this category or its ancestors."""
        try:
            # Check if specification exists for this category
            if hasattr(self, 'specification') and self.specification:
                return self.specification.specification_schema
        except AttributeError:
            pass
            
        # Check parent categories for specification
        for ancestor in self.get_ancestors():
            try:
                if hasattr(ancestor, 'specification') and ancestor.specification:
                    return ancestor.specification.specification_schema
            except AttributeError:
                continue
        return None

    def has_specifications(self):
        """Check if this category or any ancestor has specifications."""
        return self.get_specification_type() is not None


class CategorySpecification(models.Model):
    """
    Category-specific specification schemas to extend your existing Category model.
    """
    CATEGORY_TYPES = [
        ('VEHICLE_SPARES', 'Vehicle Spares'),
        ('TYRES_RIMS', 'Tyres & Rims'),
        ('ELECTRONICS', 'Electronics'),
    ]

    category = models.OneToOneField(
        'Category',  # Reference to your existing Category model
        on_delete=models.CASCADE,
        related_name='specification'
    )
    category_type = models.CharField(
        max_length=20,
        choices=CATEGORY_TYPES,
        help_text="Type identifier for category-specific specifications"
    )

    # JSON schema for category-specific specifications
    specification_schema = models.JSONField(
        help_text="JSON schema defining required fields for this category"
    )

    # Template for form generation
    form_template = models.JSONField(
        null=True,
        blank=True,
        help_text="UI form template configuration"
    )

    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "Category Specification"
        verbose_name_plural = "Category Specifications"

    def __str__(self):
        try:
            category_name = self.category.name if self.category else "Unknown Category"
            return f"{category_name} - {self.get_category_type_display()}"
        except AttributeError:
            return f"CategorySpecification {self.id} - {self.get_category_type_display()}"


class CategoryAttribute(BaseModel):
    """
    Attributes that can be associated with categories to define
    what properties products in that category should have.
    """
    
    ATTRIBUTE_TYPES = [
        ('text', 'Text'),
        ('number', 'Number'),
        ('decimal', 'Decimal'),
        ('boolean', 'Boolean'),
        ('choice', 'Single Choice'),
        ('multiple_choice', 'Multiple Choice'),
        ('date', 'Date'),
        ('datetime', 'Date Time'),
        ('url', 'URL'),
        ('email', 'Email'),
        ('phone', 'Phone'),
        ('color', 'Color'),
        ('file', 'File'),
        ('image', 'Image'),
    ]
    
    category = models.ForeignKey(
        Category,
        on_delete=models.CASCADE,
        related_name='attributes'
    )
    name = models.CharField(max_length=100)
    attribute_type = models.CharField(max_length=20, choices=ATTRIBUTE_TYPES)
    
    # Configuration
    is_required = models.BooleanField(default=False)
    is_filterable = models.BooleanField(default=True)
    is_searchable = models.BooleanField(default=False)
    show_in_listing = models.BooleanField(default=False)
    
    # Display
    label = models.CharField(max_length=100, blank=True)
    help_text = models.TextField(blank=True)
    placeholder = models.CharField(max_length=100, blank=True)
    sort_order = models.IntegerField(default=0)
    
    # Validation
    min_value = models.FloatField(null=True, blank=True)
    max_value = models.FloatField(null=True, blank=True)
    min_length = models.IntegerField(null=True, blank=True)
    max_length = models.IntegerField(null=True, blank=True)
    regex_pattern = models.CharField(max_length=200, blank=True)
    
    # Choices (for choice types)
    choices = models.JSONField(
        default=list,
        blank=True,
        help_text="List of choices for choice-based attributes"
    )
    
    # Default value
    default_value = models.JSONField(null=True, blank=True)
    
    class Meta:
        unique_together = ['category', 'name']
        ordering = ['sort_order', 'name']
        indexes = [
            models.Index(fields=['category', 'is_required']),
            models.Index(fields=['category', 'is_filterable']),
        ]
    
    def __str__(self):
        return f"{self.category.name} - {self.name}"
    
    @property
    def display_label(self):
        """Get the display label, falling back to name if not set."""
        return self.label or self.name.replace('_', ' ').title()
    
    def clean(self):
        """Custom validation."""
        super().clean()
        
        # Validate choices for choice types
        if self.attribute_type in ['choice', 'multiple_choice']:
            if not self.choices or not isinstance(self.choices, list):
                raise ValueError("Choices must be a non-empty list for choice-based attributes")
        
        # Validate numeric constraints
        if self.min_value is not None and self.max_value is not None:
            if self.min_value > self.max_value:
                raise ValueError("Minimum value cannot be greater than maximum value")
        
        if self.min_length is not None and self.max_length is not None:
            if self.min_length > self.max_length:
                raise ValueError("Minimum length cannot be greater than maximum length")
