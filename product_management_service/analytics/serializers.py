"""
Serializers for the analytics app.
"""

from rest_framework import serializers
from .models import (
    ProductRequestAnalytics, CategoryAnalytics, UserBehaviorAnalytics,
    SearchAnalytics, SalesAnalytics, InventoryAnalytics, AnalyticsReport
)
from product_requests.serializers import ProductRequestListSerializer
from categories.serializers import CategorySerializer


class ProductRequestAnalyticsSerializer(serializers.ModelSerializer):
    """
    Serializer for ProductRequestAnalytics model.
    """
    request_details = ProductRequestListSerializer(source='request', read_only=True)
    click_through_rate = serializers.ReadOnlyField()
    response_rate = serializers.ReadOnlyField()
    
    class Meta:
        model = ProductRequestAnalytics
        fields = [
            'id', 'request', 'request_details', 'date', 'timeframe',
            'views', 'unique_views', 'search_appearances', 'search_clicks',
            'quote_responses', 'messages_sent', 'watchlist_additions',
            'average_response_time', 'supplier_interest_score',
            'click_through_rate', 'response_rate',
            'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']


class CategoryAnalyticsSerializer(serializers.ModelSerializer):
    """
    Serializer for CategoryAnalytics model.
    """
    category_details = CategorySerializer(source='category', read_only=True)
    
    class Meta:
        model = CategoryAnalytics
        fields = [
            'id', 'category', 'category_details', 'date', 'timeframe',
            'total_requests', 'active_requests', 'new_requests', 'closed_requests',
            'total_views', 'total_quote_requests', 'total_quotes', 'total_orders',
            'total_revenue', 'average_price', 'average_rating',
            'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']


class UserBehaviorAnalyticsSerializer(serializers.ModelSerializer):
    """
    Serializer for UserBehaviorAnalytics model.
    """
    
    class Meta:
        model = UserBehaviorAnalytics
        fields = [
            'id', 'date', 'timeframe',
            'total_users', 'active_users', 'new_users', 'returning_users',
            'total_sessions', 'total_pageviews', 'average_session_duration', 'bounce_rate',
            'users_with_requests', 'users_with_quotes', 'users_with_orders',
            'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']


class SearchAnalyticsSerializer(serializers.ModelSerializer):
    """
    Serializer for SearchAnalytics model.
    """
    click_through_rate = serializers.ReadOnlyField()
    
    class Meta:
        model = SearchAnalytics
        fields = [
            'id', 'query', 'query_hash', 'date',
            'search_count', 'results_count', 'clicks',
            'average_position_clicked', 'zero_results',
            'click_through_rate',
            'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'query_hash', 'created_at', 'updated_at']


class SalesAnalyticsSerializer(serializers.ModelSerializer):
    """
    Serializer for SalesAnalytics model.
    """
    top_category_details = CategorySerializer(source='top_category', read_only=True)
    
    class Meta:
        model = SalesAnalytics
        fields = [
            'id', 'date', 'timeframe',
            'total_orders', 'total_revenue', 'total_units_sold',
            'average_order_value', 'average_units_per_order',
            'total_quotes', 'accepted_quotes', 'quote_acceptance_rate',
            'top_category', 'top_category_details',
            'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']


class InventoryAnalyticsSerializer(serializers.ModelSerializer):
    """
    Serializer for InventoryAnalytics model.
    """
    
    class Meta:
        model = InventoryAnalytics
        fields = [
            'id', 'date', 'timeframe',
            'total_products', 'total_inventory_value', 'total_units',
            'in_stock_products', 'out_of_stock_products', 'low_stock_products',
            'units_received', 'units_sold', 'units_adjusted',
            'inventory_turnover', 'days_of_inventory',
            'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']


class AnalyticsReportSerializer(serializers.ModelSerializer):
    """
    Serializer for AnalyticsReport model.
    """
    generated_by_username = serializers.CharField(source='generated_by.username', read_only=True)
    date_range_days = serializers.ReadOnlyField()
    
    class Meta:
        model = AnalyticsReport
        fields = [
            'id', 'name', 'report_type', 'description',
            'start_date', 'end_date', 'date_range_days',
            'generated_by', 'generated_by_username', 'status',
            'report_data', 'file_path', 'file_format',
            'parameters', 'generation_time',
            'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'generated_by', 'generated_by_username', 'date_range_days', 'created_at', 'updated_at']


class AnalyticsSummarySerializer(serializers.Serializer):
    """
    Serializer for analytics summary data.
    """
    timeframe = serializers.CharField()
    date_range = serializers.DictField()
    summary = serializers.DictField()


class AnalyticsTrendsSerializer(serializers.Serializer):
    """
    Serializer for analytics trends data.
    """
    date_range = serializers.DictField()
    daily_requests = serializers.ListField()
    daily_analytics = serializers.ListField()
