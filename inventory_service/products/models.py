"""
Product models for the BIDR Inventory Service.

This module defines products, their attributes, images, and inventory management.
"""

from django.db import models
from django.contrib.auth.models import User
from django.core.validators import MinValueValidator, MaxValueValidator
from django.urls import reverse
from decimal import Decimal
from core.models import ComprehensiveBaseModel, StatusChoices, PriorityChoices
from core.api_integration import SellerIntegrationMixin, get_seller_info, notify_seller_activity
from core.encryption import encrypt_field, decrypt_field
from categories.models import Category, CategoryAttribute


class Product(ComprehensiveBaseModel, SellerIntegrationMixin):
    """
    Core product model representing items available in the inventory.
    """
    # Basic information
    name = models.CharField(max_length=200)
    slug = models.SlugField(max_length=220, unique=True)
    description = models.TextField()
    short_description = models.CharField(max_length=500, blank=True)
    
    # Categorization
    category = models.ForeignKey(
        Category,
        on_delete=models.PROTECT,
        related_name='products'
    )
    
    # Product identification
    sku = models.CharField(max_length=100, unique=True, blank=True)
    barcode = models.CharField(max_length=50, blank=True)
    
    # Pricing
    base_price = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        validators=[MinValueValidator(Decimal('0.01'))]
    )
    compare_price = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        null=True,
        blank=True,
        validators=[MinValueValidator(Decimal('0.01'))],
        help_text="Original price for comparison"
    )
    cost_price = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        null=True,
        blank=True,
        validators=[MinValueValidator(Decimal('0.00'))],
        help_text="Cost price for profit calculations"
    )
    
    # Inventory
    track_inventory = models.BooleanField(default=True)
    quantity_available = models.IntegerField(
        default=0,
        validators=[MinValueValidator(0)]
    )
    quantity_reserved = models.IntegerField(
        default=0,
        validators=[MinValueValidator(0)]
    )
    low_stock_threshold = models.IntegerField(
        default=5,
        validators=[MinValueValidator(0)]
    )
    
    # Physical properties
    weight = models.DecimalField(
        max_digits=8,
        decimal_places=3,
        null=True,
        blank=True,
        validators=[MinValueValidator(Decimal('0.001'))],
        help_text="Weight in kg"
    )
    dimensions_length = models.DecimalField(
        max_digits=8,
        decimal_places=2,
        null=True,
        blank=True,
        validators=[MinValueValidator(Decimal('0.01'))],
        help_text="Length in cm"
    )
    dimensions_width = models.DecimalField(
        max_digits=8,
        decimal_places=2,
        null=True,
        blank=True,
        validators=[MinValueValidator(Decimal('0.01'))],
        help_text="Width in cm"
    )
    dimensions_height = models.DecimalField(
        max_digits=8,
        decimal_places=2,
        null=True,
        blank=True,
        validators=[MinValueValidator(Decimal('0.01'))],
        help_text="Height in cm"
    )
    
    # Status and visibility
    status = models.CharField(
        max_length=20,
        choices=StatusChoices.choices,
        default=StatusChoices.ACTIVE
    )
    is_featured = models.BooleanField(default=False)
    is_digital = models.BooleanField(default=False)
    requires_shipping = models.BooleanField(default=True)
    
    # SEO fields
    meta_title = models.CharField(max_length=60, blank=True)
    meta_description = models.CharField(max_length=160, blank=True)
    
    # Supplier information
    supplier = models.ForeignKey(
        User,
        on_delete=models.PROTECT,
        related_name='supplied_products',
        null=True,
        blank=True
    )
    supplier_sku = models.CharField(max_length=100, blank=True)
    
    # Analytics
    view_count = models.IntegerField(default=0)
    request_count = models.IntegerField(default=0)
    
    class Meta:
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['status', 'category']),
            models.Index(fields=['sku']),
            models.Index(fields=['barcode']),
            models.Index(fields=['is_featured', 'status']),
            models.Index(fields=['supplier', 'status']),
            models.Index(fields=['created_at']),
        ]
    
    def __str__(self):
        return self.name
    
    def get_absolute_url(self):
        return reverse('product-detail', kwargs={'slug': self.slug})
    
    @property
    def available_quantity(self):
        """Get quantity available for new orders."""
        return max(0, self.quantity_available - self.quantity_reserved)
    
    @property
    def is_in_stock(self):
        """Check if product is in stock."""
        if not self.track_inventory:
            return True
        return self.available_quantity > 0
    
    @property
    def is_low_stock(self):
        """Check if product is low on stock."""
        if not self.track_inventory:
            return False
        return self.available_quantity <= self.low_stock_threshold
    
    @property
    def discount_percentage(self):
        """Calculate discount percentage if compare_price is set."""
        if self.compare_price and self.compare_price > self.base_price:
            discount = self.compare_price - self.base_price
            return round((discount / self.compare_price) * 100, 2)
        return 0
    
    @property
    def profit_margin(self):
        """Calculate profit margin if cost_price is set."""
        if self.cost_price and self.base_price > self.cost_price:
            profit = self.base_price - self.cost_price
            return round((profit / self.base_price) * 100, 2)
        return 0
    
    def can_fulfill_quantity(self, quantity):
        """Check if product can fulfill the requested quantity."""
        if not self.track_inventory:
            return True
        return self.available_quantity >= quantity
    
    def reserve_quantity(self, quantity):
        """Reserve quantity for an order."""
        if self.can_fulfill_quantity(quantity):
            self.quantity_reserved += quantity
            self.save(update_fields=['quantity_reserved'])
            return True
        return False
    
    def release_quantity(self, quantity):
        """Release reserved quantity."""
        self.quantity_reserved = max(0, self.quantity_reserved - quantity)
        self.save(update_fields=['quantity_reserved'])
    
    def adjust_inventory(self, quantity_change, reason=""):
        """Adjust inventory levels."""
        self.quantity_available += quantity_change
        if self.quantity_available < 0:
            self.quantity_available = 0
        self.save(update_fields=['quantity_available'])
        
        # Log inventory change
        InventoryLog.objects.create(
            product=self,
            quantity_change=quantity_change,
            new_quantity=self.quantity_available,
            reason=reason
        )


class ProductImage(models.Model):
    """
    Images associated with products.
    """
    product = models.ForeignKey(
        Product,
        on_delete=models.CASCADE,
        related_name='images'
    )
    image = models.ImageField(upload_to='products/')
    alt_text = models.CharField(max_length=200, blank=True)
    is_primary = models.BooleanField(default=False)
    sort_order = models.IntegerField(default=0)
    
    class Meta:
        ordering = ['sort_order', 'id']
        indexes = [
            models.Index(fields=['product', 'is_primary']),
        ]
    
    def __str__(self):
        return f"{self.product.name} - Image {self.id}"
    
    def save(self, *args, **kwargs):
        # Ensure only one primary image per product
        if self.is_primary:
            ProductImage.objects.filter(
                product=self.product,
                is_primary=True
            ).update(is_primary=False)
        super().save(*args, **kwargs)


class ProductAttribute(models.Model):
    """
    Specific attribute values for products based on category attributes.
    """
    product = models.ForeignKey(
        Product,
        on_delete=models.CASCADE,
        related_name='attribute_values'
    )
    attribute = models.ForeignKey(
        CategoryAttribute,
        on_delete=models.CASCADE
    )
    value = models.JSONField()
    
    class Meta:
        unique_together = ['product', 'attribute']
        indexes = [
            models.Index(fields=['product', 'attribute']),
        ]
    
    def __str__(self):
        return f"{self.product.name} - {self.attribute.name}: {self.value}"


class ProductVariant(ComprehensiveBaseModel):
    """
    Product variants for products with different options (size, color, etc.).
    """
    parent_product = models.ForeignKey(
        Product,
        on_delete=models.CASCADE,
        related_name='variants'
    )
    name = models.CharField(max_length=200)
    sku = models.CharField(max_length=100, unique=True)
    
    # Pricing (can override parent product)
    price = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        null=True,
        blank=True,
        validators=[MinValueValidator(Decimal('0.01'))]
    )
    compare_price = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        null=True,
        blank=True,
        validators=[MinValueValidator(Decimal('0.01'))]
    )
    cost_price = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        null=True,
        blank=True,
        validators=[MinValueValidator(Decimal('0.00'))]
    )
    
    # Inventory (separate from parent)
    quantity_available = models.IntegerField(
        default=0,
        validators=[MinValueValidator(0)]
    )
    quantity_reserved = models.IntegerField(
        default=0,
        validators=[MinValueValidator(0)]
    )
    
    # Physical properties (can override parent)
    weight = models.DecimalField(
        max_digits=8,
        decimal_places=3,
        null=True,
        blank=True,
        validators=[MinValueValidator(Decimal('0.001'))]
    )
    
    # Status
    status = models.CharField(
        max_length=20,
        choices=StatusChoices.choices,
        default=StatusChoices.ACTIVE
    )
    
    class Meta:
        ordering = ['name']
        indexes = [
            models.Index(fields=['parent_product', 'status']),
            models.Index(fields=['sku']),
        ]
    
    def __str__(self):
        return f"{self.parent_product.name} - {self.name}"
    
    @property
    def effective_price(self):
        """Get the effective price (variant price or parent price)."""
        return self.price or self.parent_product.base_price
    
    @property
    def available_quantity(self):
        """Get quantity available for new orders."""
        return max(0, self.quantity_available - self.quantity_reserved)
    
    @property
    def is_in_stock(self):
        """Check if variant is in stock."""
        return self.available_quantity > 0


class InventoryLog(models.Model):
    """
    Log of inventory changes for auditing purposes.
    """
    product = models.ForeignKey(
        Product,
        on_delete=models.CASCADE,
        related_name='inventory_logs'
    )
    variant = models.ForeignKey(
        ProductVariant,
        on_delete=models.CASCADE,
        related_name='inventory_logs',
        null=True,
        blank=True
    )
    quantity_change = models.IntegerField()
    new_quantity = models.IntegerField()
    reason = models.CharField(max_length=200)
    created_at = models.DateTimeField(auto_now_add=True)
    created_by = models.ForeignKey(
        User,
        on_delete=models.PROTECT,
        null=True,
        blank=True
    )
    
    class Meta:
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['product', 'created_at']),
            models.Index(fields=['variant', 'created_at']),
        ]
    
    def __str__(self):
        item = self.variant or self.product
        return f"{item} - {self.quantity_change:+d} ({self.reason})"


class ProductReview(ComprehensiveBaseModel):
    """
    Customer reviews for products.
    """
    product = models.ForeignKey(
        Product,
        on_delete=models.CASCADE,
        related_name='reviews'
    )
    reviewer = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='product_reviews'
    )
    rating = models.IntegerField(
        validators=[MinValueValidator(1), MaxValueValidator(5)]
    )
    title = models.CharField(max_length=200)
    review_text = models.TextField()
    
    # Review status
    status = models.CharField(
        max_length=20,
        choices=StatusChoices.choices,
        default=StatusChoices.PENDING
    )
    
    # Helpfulness tracking
    helpful_count = models.IntegerField(default=0)
    not_helpful_count = models.IntegerField(default=0)
    
    # Verification
    is_verified_purchase = models.BooleanField(default=False)
    
    class Meta:
        unique_together = ['product', 'reviewer']
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['product', 'status', 'rating']),
            models.Index(fields=['reviewer']),
        ]
    
    def __str__(self):
        return f"{self.product.name} - {self.rating}★ by {self.reviewer.username}"
    
    @property
    def helpfulness_ratio(self):
        """Calculate helpfulness ratio."""
        total_votes = self.helpful_count + self.not_helpful_count
        if total_votes == 0:
            return 0
        return round((self.helpful_count / total_votes) * 100, 2)
