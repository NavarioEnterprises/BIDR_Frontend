"""
Analytics models for the BIDR Inventory Service.

This module provides comprehensive analytics and reporting capabilities
for products, sales, inventory, and user behavior.
"""

from django.db import models
from django.contrib.auth.models import User
from django.contrib.contenttypes.models import ContentType
from django.contrib.contenttypes.fields import GenericForeignKey
from django.utils import timezone
from django.db.models import Sum, Avg, Count, F, Q
from decimal import Decimal
from datetime import datetime, timedelta
from core.models import BaseModel, StatusChoices
from categories.models import Category
from products.models import Product


class AnalyticsTimeframe(models.TextChoices):
    """Time frames for analytics reporting."""
    HOURLY = 'hourly', 'Hourly'
    DAILY = 'daily', 'Daily'
    WEEKLY = 'weekly', 'Weekly'
    MONTHLY = 'monthly', 'Monthly'
    QUARTERLY = 'quarterly', 'Quarterly'
    YEARLY = 'yearly', 'Yearly'


class ProductAnalytics(BaseModel):
    """
    Analytics data for individual products.
    """
    product = models.ForeignKey(
        Product,
        on_delete=models.CASCADE,
        related_name='analytics'
    )
    
    # Time period
    date = models.DateField(help_text="Date this analytics record represents")
    timeframe = models.CharField(
        max_length=20,
        choices=AnalyticsTimeframe.choices,
        default=AnalyticsTimeframe.DAILY
    )
    
    # View metrics
    views = models.IntegerField(default=0, help_text="Number of views")
    unique_views = models.IntegerField(default=0, help_text="Number of unique views")
    search_appearances = models.IntegerField(
        default=0,
        help_text="Times product appeared in search results"
    )
    search_clicks = models.IntegerField(
        default=0,
        help_text="Times product was clicked from search results"
    )
    
    # Request metrics
    quote_requests = models.IntegerField(
        default=0,
        help_text="Number of quote requests received"
    )
    quotes_submitted = models.IntegerField(
        default=0,
        help_text="Number of quotes submitted for this product"
    )
    quotes_accepted = models.IntegerField(
        default=0,
        help_text="Number of quotes accepted"
    )
    
    # Sales metrics
    orders = models.IntegerField(default=0, help_text="Number of orders")
    units_sold = models.IntegerField(default=0, help_text="Number of units sold")
    revenue = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        default=Decimal('0.00'),
        help_text="Total revenue generated"
    )
    
    # Inventory metrics
    stock_level_start = models.IntegerField(
        default=0,
        help_text="Stock level at start of period"
    )
    stock_level_end = models.IntegerField(
        default=0,
        help_text="Stock level at end of period"
    )
    stock_movements = models.IntegerField(
        default=0,
        help_text="Number of stock movements"
    )
    
    # Performance metrics
    conversion_rate = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        default=Decimal('0.00'),
        help_text="Conversion rate from views to orders (percentage)"
    )
    average_order_value = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        default=Decimal('0.00'),
        help_text="Average order value"
    )
    
    class Meta:
        unique_together = ['product', 'date', 'timeframe']
        ordering = ['-date', '-created_at']
        indexes = [
            models.Index(fields=['product', 'date']),
            models.Index(fields=['date', 'timeframe']),
            models.Index(fields=['product', 'timeframe']),
        ]
    
    def __str__(self):
        return f"{self.product.name} analytics for {self.date} ({self.timeframe})"
    
    @property
    def click_through_rate(self):
        """Calculate click-through rate from search appearances."""
        if self.search_appearances == 0:
            return Decimal('0.00')
        return round(Decimal(self.search_clicks) / Decimal(self.search_appearances) * 100, 2)
    
    @property
    def quote_conversion_rate(self):
        """Calculate quote conversion rate."""
        if self.quotes_submitted == 0:
            return Decimal('0.00')
        return round(Decimal(self.quotes_accepted) / Decimal(self.quotes_submitted) * 100, 2)


class CategoryAnalytics(BaseModel):
    """
    Analytics data for product categories.
    """
    category = models.ForeignKey(
        Category,
        on_delete=models.CASCADE,
        related_name='analytics'
    )
    
    # Time period
    date = models.DateField()
    timeframe = models.CharField(
        max_length=20,
        choices=AnalyticsTimeframe.choices,
        default=AnalyticsTimeframe.DAILY
    )
    
    # Product metrics
    total_products = models.IntegerField(
        default=0,
        help_text="Total number of products in category"
    )
    active_products = models.IntegerField(
        default=0,
        help_text="Number of active products"
    )
    new_products = models.IntegerField(
        default=0,
        help_text="New products added in this period"
    )
    
    # Activity metrics
    total_views = models.IntegerField(default=0)
    total_requests = models.IntegerField(default=0)
    total_quotes = models.IntegerField(default=0)
    total_orders = models.IntegerField(default=0)
    total_revenue = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        default=Decimal('0.00')
    )
    
    # Performance metrics
    average_price = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        default=Decimal('0.00'),
        help_text="Average product price in category"
    )
    average_rating = models.DecimalField(
        max_digits=3,
        decimal_places=2,
        default=Decimal('0.00'),
        help_text="Average product rating in category"
    )
    
    class Meta:
        unique_together = ['category', 'date', 'timeframe']
        ordering = ['-date', '-created_at']
        indexes = [
            models.Index(fields=['category', 'date']),
            models.Index(fields=['date', 'timeframe']),
        ]
    
    def __str__(self):
        return f"{self.category.name} analytics for {self.date} ({self.timeframe})"


class UserBehaviorAnalytics(BaseModel):
    """
    Analytics for user behavior patterns.
    """
    # Time period
    date = models.DateField()
    timeframe = models.CharField(
        max_length=20,
        choices=AnalyticsTimeframe.choices,
        default=AnalyticsTimeframe.DAILY
    )
    
    # User metrics
    total_users = models.IntegerField(default=0)
    active_users = models.IntegerField(default=0)
    new_users = models.IntegerField(default=0)
    returning_users = models.IntegerField(default=0)
    
    # Activity metrics
    total_sessions = models.IntegerField(default=0)
    total_pageviews = models.IntegerField(default=0)
    average_session_duration = models.DurationField(
        null=True,
        blank=True,
        help_text="Average session duration"
    )
    bounce_rate = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        default=Decimal('0.00'),
        help_text="Bounce rate percentage"
    )
    
    # Conversion metrics
    users_with_requests = models.IntegerField(
        default=0,
        help_text="Users who made at least one request"
    )
    users_with_quotes = models.IntegerField(
        default=0,
        help_text="Users who submitted at least one quote"
    )
    users_with_orders = models.IntegerField(
        default=0,
        help_text="Users who made at least one order"
    )
    
    class Meta:
        unique_together = ['date', 'timeframe']
        ordering = ['-date', '-created_at']
        indexes = [
            models.Index(fields=['date', 'timeframe']),
        ]
    
    def __str__(self):
        return f"User behavior analytics for {self.date} ({self.timeframe})"


class SearchAnalytics(BaseModel):
    """
    Analytics for search queries and results.
    """
    # Search query details
    query = models.CharField(
        max_length=500,
        help_text="The search query"
    )
    query_hash = models.CharField(
        max_length=64,
        help_text="Hash of the query for grouping"
    )
    
    # Time period
    date = models.DateField()
    
    # Search metrics
    search_count = models.IntegerField(
        default=1,
        help_text="Number of times this query was searched"
    )
    results_count = models.IntegerField(
        default=0,
        help_text="Number of results returned"
    )
    clicks = models.IntegerField(
        default=0,
        help_text="Number of clicks on results"
    )
    
    # Performance metrics
    average_position_clicked = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        default=Decimal('0.00'),
        help_text="Average position of clicked results"
    )
    zero_results = models.BooleanField(
        default=False,
        help_text="Whether this query returned zero results"
    )
    
    class Meta:
        unique_together = ['query_hash', 'date']
        ordering = ['-search_count', '-date']
        indexes = [
            models.Index(fields=['query_hash', 'date']),
            models.Index(fields=['date', 'search_count']),
            models.Index(fields=['zero_results', 'date']),
        ]
    
    def __str__(self):
        return f"Search: '{self.query}' ({self.search_count} times on {self.date})"
    
    @property
    def click_through_rate(self):
        """Calculate click-through rate."""
        if self.search_count == 0:
            return Decimal('0.00')
        return round(Decimal(self.clicks) / Decimal(self.search_count) * 100, 2)


class SalesAnalytics(BaseModel):
    """
    Sales performance analytics.
    """
    # Time period
    date = models.DateField()
    timeframe = models.CharField(
        max_length=20,
        choices=AnalyticsTimeframe.choices,
        default=AnalyticsTimeframe.DAILY
    )
    
    # Sales metrics
    total_orders = models.IntegerField(default=0)
    total_revenue = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        default=Decimal('0.00')
    )
    total_units_sold = models.IntegerField(default=0)
    
    # Order metrics
    average_order_value = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        default=Decimal('0.00')
    )
    average_units_per_order = models.DecimalField(
        max_digits=8,
        decimal_places=2,
        default=Decimal('0.00')
    )
    
    # Quote metrics
    total_quotes = models.IntegerField(default=0)
    accepted_quotes = models.IntegerField(default=0)
    quote_acceptance_rate = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        default=Decimal('0.00')
    )
    
    # Top performing categories and products
    top_category = models.ForeignKey(
        Category,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        help_text="Top performing category by revenue"
    )
    top_product = models.ForeignKey(
        Product,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        help_text="Top performing product by revenue"
    )
    
    class Meta:
        unique_together = ['date', 'timeframe']
        ordering = ['-date', '-created_at']
        indexes = [
            models.Index(fields=['date', 'timeframe']),
            models.Index(fields=['total_revenue', 'date']),
        ]
    
    def __str__(self):
        return f"Sales analytics for {self.date} ({self.timeframe}): ${self.total_revenue}"


class InventoryAnalytics(BaseModel):
    """
    Inventory performance and movement analytics.
    """
    # Time period
    date = models.DateField()
    timeframe = models.CharField(
        max_length=20,
        choices=AnalyticsTimeframe.choices,
        default=AnalyticsTimeframe.DAILY
    )
    
    # Inventory levels
    total_products = models.IntegerField(
        default=0,
        help_text="Total number of products"
    )
    total_inventory_value = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        default=Decimal('0.00'),
        help_text="Total value of inventory"
    )
    total_units = models.IntegerField(
        default=0,
        help_text="Total number of units in stock"
    )
    
    # Stock status
    in_stock_products = models.IntegerField(
        default=0,
        help_text="Number of products in stock"
    )
    out_of_stock_products = models.IntegerField(
        default=0,
        help_text="Number of products out of stock"
    )
    low_stock_products = models.IntegerField(
        default=0,
        help_text="Number of products with low stock"
    )
    
    # Movement metrics
    units_received = models.IntegerField(
        default=0,
        help_text="Units added to inventory"
    )
    units_sold = models.IntegerField(
        default=0,
        help_text="Units sold from inventory"
    )
    units_adjusted = models.IntegerField(
        default=0,
        help_text="Units adjusted (positive or negative)"
    )
    
    # Performance metrics
    inventory_turnover = models.DecimalField(
        max_digits=8,
        decimal_places=2,
        default=Decimal('0.00'),
        help_text="Inventory turnover ratio"
    )
    days_of_inventory = models.DecimalField(
        max_digits=8,
        decimal_places=2,
        default=Decimal('0.00'),
        help_text="Days of inventory remaining"
    )
    
    class Meta:
        unique_together = ['date', 'timeframe']
        ordering = ['-date', '-created_at']
        indexes = [
            models.Index(fields=['date', 'timeframe']),
        ]
    
    def __str__(self):
        return f"Inventory analytics for {self.date} ({self.timeframe})"


class AnalyticsReport(BaseModel):
    """
    Generated analytics reports for specific time periods and metrics.
    """
    REPORT_TYPES = [
        ('product_performance', 'Product Performance'),
        ('sales_summary', 'Sales Summary'),
        ('inventory_status', 'Inventory Status'),
        ('user_behavior', 'User Behavior'),
        ('search_analysis', 'Search Analysis'),
        ('category_performance', 'Category Performance'),
        ('custom', 'Custom Report'),
    ]
    
    REPORT_FORMATS = [
        ('json', 'JSON'),
        ('csv', 'CSV'),
        ('pdf', 'PDF'),
        ('excel', 'Excel'),
    ]
    
    # Report details
    name = models.CharField(max_length=200)
    report_type = models.CharField(max_length=30, choices=REPORT_TYPES)
    description = models.TextField(blank=True)
    
    # Time range
    start_date = models.DateField()
    end_date = models.DateField()
    
    # Generation details
    generated_by = models.ForeignKey(
        User,
        on_delete=models.PROTECT,
        related_name='generated_reports'
    )
    status = models.CharField(
        max_length=20,
        choices=StatusChoices.choices,
        default=StatusChoices.PENDING
    )
    
    # Report data and files
    report_data = models.JSONField(
        default=dict,
        help_text="Generated report data"
    )
    file_path = models.CharField(
        max_length=500,
        blank=True,
        help_text="Path to generated report file"
    )
    file_format = models.CharField(
        max_length=10,
        choices=REPORT_FORMATS,
        default='json'
    )
    
    # Metadata
    parameters = models.JSONField(
        default=dict,
        help_text="Parameters used to generate the report"
    )
    generation_time = models.DurationField(
        null=True,
        blank=True,
        help_text="Time taken to generate the report"
    )
    
    class Meta:
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['report_type', 'status']),
            models.Index(fields=['generated_by', 'created_at']),
            models.Index(fields=['start_date', 'end_date']),
        ]
    
    def __str__(self):
        return f"{self.name} ({self.start_date} to {self.end_date})"
    
    @property
    def date_range_days(self):
        """Calculate the number of days in the report range."""
        return (self.end_date - self.start_date).days + 1


# Manager classes for analytics aggregation
class AnalyticsManager:
    """Manager for analytics operations and calculations."""
    
    @staticmethod
    def calculate_product_analytics(product, date, timeframe='daily'):
        """Calculate analytics for a specific product and date."""
        # Implementation would involve aggregating data from various sources
        # This is a placeholder for the actual implementation
        pass
    
    @staticmethod
    def calculate_category_analytics(category, date, timeframe='daily'):
        """Calculate analytics for a specific category and date."""
        pass
    
    @staticmethod
    def generate_sales_report(start_date, end_date, user):
        """Generate a comprehensive sales report."""
        pass
    
    @staticmethod
    def get_trending_products(timeframe='weekly', limit=10):
        """Get trending products based on various metrics."""
        pass
    
    @staticmethod
    def get_top_search_queries(date_range=7, limit=20):
        """Get top search queries for the specified date range."""
        pass
