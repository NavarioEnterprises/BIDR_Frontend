from django.contrib import admin
from django.utils.html import format_html
from django.utils.safestring import mark_safe
from django.db.models import Sum, Avg
from .models import (
    # ProductAnalytics,  # Commented out - products app removed
    ProductRequestAnalytics, CategoryAnalytics, UserBehaviorAnalytics,
    SearchAnalytics, SalesAnalytics, InventoryAnalytics, AnalyticsReport
)
from core.admin import CoreAdminMixin


# Temporarily commented out - products app removed
# @admin.register(ProductAnalytics)
# class ProductAnalyticsAdmin(admin.ModelAdmin, CoreAdminMixin):
#     list_display = [
#         'product', 'date', 'timeframe', 'views', 'unique_views', 
#         'quote_requests', 'orders', 'revenue_display', 'conversion_rate_display'
#     ]
#     list_filter = ['timeframe', 'date', 'product__category']
#     search_fields = ['product__name', 'product__sku']
#     readonly_fields = [
#         'id', 'created_at_display', 'updated_at_display', 
#         'click_through_rate_display', 'quote_conversion_rate_display'
#     ]
#     date_hierarchy = 'date'
#     
#     fieldsets = (
#         ('Product & Time', {
#             'fields': ('product', 'date', 'timeframe')
#         }),
#         ('View Metrics', {
#             'fields': ('views', 'unique_views', 'search_appearances', 'search_clicks')
#         }),
#         ('Request Metrics', {
#             'fields': ('quote_requests', 'quotes_submitted', 'quotes_accepted')
#         }),
#         ('Sales Metrics', {
#             'fields': ('orders', 'units_sold', 'revenue')
#         }),
#         ('Inventory Metrics', {
#             'fields': ('stock_level_start', 'stock_level_end', 'stock_movements'),
#             'classes': ('collapse',)
#         }),
#         ('Performance Metrics', {
#             'fields': ('conversion_rate', 'average_order_value', 
#                       'click_through_rate_display', 'quote_conversion_rate_display'),
#             'classes': ('collapse',)
#         }),
#         ('Timestamps', {
#             'fields': ('created_at_display', 'updated_at_display'),
#             'classes': ('collapse',)
#         })
#     )
#     
#     def revenue_display(self, obj):
#         return f"${obj.revenue:,.2f}"
#     revenue_display.short_description = 'Revenue'
#     revenue_display.admin_order_field = 'revenue'
#     
#     def conversion_rate_display(self, obj):
#         return f"{obj.conversion_rate}%"
#     conversion_rate_display.short_description = 'Conversion Rate'
#     conversion_rate_display.admin_order_field = 'conversion_rate'
#     
#     def click_through_rate_display(self, obj):
#         return f"{obj.click_through_rate}%"
#     click_through_rate_display.short_description = 'CTR'
#     
#     def quote_conversion_rate_display(self, obj):
#         return f"{obj.quote_conversion_rate}%"
#     quote_conversion_rate_display.short_description = 'Quote Conversion'
#     
#     def get_queryset(self, request):
#         return super().get_queryset(request).select_related('product')


@admin.register(ProductRequestAnalytics)
class ProductRequestAnalyticsAdmin(admin.ModelAdmin, CoreAdminMixin):
    list_display = [
        'request', 'date', 'timeframe', 'views', 'unique_views', 
        'quote_responses', 'messages_sent', 'supplier_interest_score', 'response_rate_display'
    ]
    list_filter = ['timeframe', 'date', 'request__category', 'request__status']
    search_fields = ['request__title', 'request__description']
    readonly_fields = [
        'id', 'created_at_display', 'updated_at_display', 
        'click_through_rate_display', 'response_rate_display'
    ]
    date_hierarchy = 'date'
    
    fieldsets = (
        ('Request & Time', {
            'fields': ('request', 'date', 'timeframe')
        }),
        ('View Metrics', {
            'fields': ('views', 'unique_views', 'search_appearances', 'search_clicks')
        }),
        ('Response Metrics', {
            'fields': ('quote_responses', 'messages_sent', 'watchlist_additions')
        }),
        ('Engagement Metrics', {
            'fields': ('average_response_time', 'supplier_interest_score')
        }),
        ('Calculated Metrics', {
            'fields': ('click_through_rate_display', 'response_rate_display'),
            'classes': ('collapse',)
        }),
        ('Timestamps', {
            'fields': ('created_at_display', 'updated_at_display'),
            'classes': ('collapse',)
        })
    )
    
    def click_through_rate_display(self, obj):
        return f"{obj.click_through_rate}%"
    click_through_rate_display.short_description = 'CTR'
    
    def response_rate_display(self, obj):
        return f"{obj.response_rate}%"
    response_rate_display.short_description = 'Response Rate'
    
    def get_queryset(self, request):
        return super().get_queryset(request).select_related('request')


@admin.register(CategoryAnalytics)
class CategoryAnalyticsAdmin(admin.ModelAdmin, CoreAdminMixin):
    list_display = [
        'category', 'date', 'timeframe', 'total_requests', 'active_requests',
        'total_views', 'total_orders', 'total_revenue_display', 'average_rating'
    ]
    list_filter = ['timeframe', 'date', 'category']
    search_fields = ['category__name']
    readonly_fields = ['id', 'created_at_display', 'updated_at_display']
    date_hierarchy = 'date'
    
    fieldsets = (
        ('Category & Time', {
            'fields': ('category', 'date', 'timeframe')
        }),
        ('Request Metrics', {
            'fields': ('total_requests', 'active_requests', 'new_requests', 'closed_requests')
        }),
        ('Activity Metrics', {
            'fields': ('total_views', 'total_quote_requests', 'total_quotes', 'total_orders')
        }),
        ('Performance Metrics', {
            'fields': ('total_revenue', 'average_price', 'average_rating')
        }),
        ('Timestamps', {
            'fields': ('created_at_display', 'updated_at_display'),
            'classes': ('collapse',)
        })
    )
    
    def total_revenue_display(self, obj):
        return f"${obj.total_revenue:,.2f}"
    total_revenue_display.short_description = 'Revenue'
    total_revenue_display.admin_order_field = 'total_revenue'
    
    def get_queryset(self, request):
        return super().get_queryset(request).select_related('category')


@admin.register(UserBehaviorAnalytics)
class UserBehaviorAnalyticsAdmin(admin.ModelAdmin, CoreAdminMixin):
    list_display = [
        'date', 'timeframe', 'total_users', 'active_users', 'new_users',
        'total_sessions', 'bounce_rate_display', 'users_with_orders'
    ]
    list_filter = ['timeframe', 'date']
    readonly_fields = ['id', 'created_at_display', 'updated_at_display']
    date_hierarchy = 'date'
    
    fieldsets = (
        ('Time Period', {
            'fields': ('date', 'timeframe')
        }),
        ('User Metrics', {
            'fields': ('total_users', 'active_users', 'new_users', 'returning_users')
        }),
        ('Activity Metrics', {
            'fields': ('total_sessions', 'total_pageviews', 'average_session_duration', 'bounce_rate')
        }),
        ('Conversion Metrics', {
            'fields': ('users_with_requests', 'users_with_quotes', 'users_with_orders')
        }),
        ('Timestamps', {
            'fields': ('created_at_display', 'updated_at_display'),
            'classes': ('collapse',)
        })
    )
    
    def bounce_rate_display(self, obj):
        return f"{obj.bounce_rate}%"
    bounce_rate_display.short_description = 'Bounce Rate'
    bounce_rate_display.admin_order_field = 'bounce_rate'


@admin.register(SearchAnalytics)
class SearchAnalyticsAdmin(admin.ModelAdmin, CoreAdminMixin):
    list_display = [
        'query_truncated', 'date', 'search_count', 'results_count',
        'clicks', 'click_through_rate_display', 'zero_results'
    ]
    list_filter = ['zero_results', 'date']
    search_fields = ['query']
    readonly_fields = [
        'id', 'created_at_display', 'updated_at_display', 
        'query_hash', 'click_through_rate_display'
    ]
    date_hierarchy = 'date'
    
    fieldsets = (
        ('Search Query', {
            'fields': ('query', 'query_hash', 'date')
        }),
        ('Search Metrics', {
            'fields': ('search_count', 'results_count', 'clicks', 'zero_results')
        }),
        ('Performance Metrics', {
            'fields': ('average_position_clicked', 'click_through_rate_display')
        }),
        ('Timestamps', {
            'fields': ('created_at_display', 'updated_at_display'),
            'classes': ('collapse',)
        })
    )
    
    def query_truncated(self, obj):
        return obj.query[:50] + '...' if len(obj.query) > 50 else obj.query
    query_truncated.short_description = 'Query'
    query_truncated.admin_order_field = 'query'
    
    def click_through_rate_display(self, obj):
        return f"{obj.click_through_rate}%"
    click_through_rate_display.short_description = 'CTR'


@admin.register(SalesAnalytics)
class SalesAnalyticsAdmin(admin.ModelAdmin, CoreAdminMixin):
    list_display = [
        'date', 'timeframe', 'total_orders', 'total_revenue_display',
        'total_units_sold', 'average_order_value_display', 'quote_acceptance_rate_display'
    ]
    list_filter = ['timeframe', 'date']
    readonly_fields = ['id', 'created_at_display', 'updated_at_display']
    date_hierarchy = 'date'
    
    fieldsets = (
        ('Time Period', {
            'fields': ('date', 'timeframe')
        }),
        ('Sales Metrics', {
            'fields': ('total_orders', 'total_revenue', 'total_units_sold')
        }),
        ('Order Metrics', {
            'fields': ('average_order_value', 'average_units_per_order')
        }),
        ('Quote Metrics', {
            'fields': ('total_quotes', 'accepted_quotes', 'quote_acceptance_rate')
        }),
        ('Top Performers', {
            'fields': ('top_category',),  # 'top_product' commented out - products app removed
            'classes': ('collapse',)
        }),
        ('Timestamps', {
            'fields': ('created_at_display', 'updated_at_display'),
            'classes': ('collapse',)
        })
    )
    
    def total_revenue_display(self, obj):
        return f"${obj.total_revenue:,.2f}"
    total_revenue_display.short_description = 'Revenue'
    total_revenue_display.admin_order_field = 'total_revenue'
    
    def average_order_value_display(self, obj):
        return f"${obj.average_order_value:,.2f}"
    average_order_value_display.short_description = 'AOV'
    average_order_value_display.admin_order_field = 'average_order_value'
    
    def quote_acceptance_rate_display(self, obj):
        return f"{obj.quote_acceptance_rate}%"
    quote_acceptance_rate_display.short_description = 'Quote Accept Rate'
    quote_acceptance_rate_display.admin_order_field = 'quote_acceptance_rate'


@admin.register(InventoryAnalytics)
class InventoryAnalyticsAdmin(admin.ModelAdmin, CoreAdminMixin):
    list_display = [
        'date', 'timeframe', 'total_products', 'total_inventory_value_display',
        'in_stock_products', 'out_of_stock_products', 'inventory_turnover'
    ]
    list_filter = ['timeframe', 'date']
    readonly_fields = ['id', 'created_at_display', 'updated_at_display']
    date_hierarchy = 'date'
    
    fieldsets = (
        ('Time Period', {
            'fields': ('date', 'timeframe')
        }),
        ('Inventory Levels', {
            'fields': ('total_products', 'total_inventory_value', 'total_units')
        }),
        ('Stock Status', {
            'fields': ('in_stock_products', 'out_of_stock_products', 'low_stock_products')
        }),
        ('Movement Metrics', {
            'fields': ('units_received', 'units_sold', 'units_adjusted')
        }),
        ('Performance Metrics', {
            'fields': ('inventory_turnover', 'days_of_inventory')
        }),
        ('Timestamps', {
            'fields': ('created_at_display', 'updated_at_display'),
            'classes': ('collapse',)
        })
    )
    
    def total_inventory_value_display(self, obj):
        return f"${obj.total_inventory_value:,.2f}"
    total_inventory_value_display.short_description = 'Inventory Value'
    total_inventory_value_display.admin_order_field = 'total_inventory_value'


@admin.register(AnalyticsReport)
class AnalyticsReportAdmin(admin.ModelAdmin, CoreAdminMixin):
    list_display = [
        'name', 'report_type', 'generated_by', 'status_display',
        'start_date', 'end_date', 'date_range_days_display', 'created_at_display'
    ]
    list_filter = ['report_type', 'status', 'file_format', 'created_at']
    search_fields = ['name', 'description', 'generated_by__username']
    readonly_fields = [
        'id', 'created_at_display', 'updated_at_display',
        'generation_time', 'date_range_days_display'
    ]
    date_hierarchy = 'created_at'
    
    fieldsets = (
        ('Report Information', {
            'fields': ('name', 'report_type', 'description')
        }),
        ('Time Range', {
            'fields': ('start_date', 'end_date', 'date_range_days_display')
        }),
        ('Generation Details', {
            'fields': ('generated_by', 'status', 'generation_time')
        }),
        ('Report Data & Files', {
            'fields': ('report_data', 'file_path', 'file_format'),
            'classes': ('collapse',)
        }),
        ('Metadata', {
            'fields': ('parameters',),
            'classes': ('collapse',)
        }),
        ('Timestamps', {
            'fields': ('created_at_display', 'updated_at_display'),
            'classes': ('collapse',)
        })
    )
    
    def date_range_days_display(self, obj):
        return f"{obj.date_range_days} days"
    date_range_days_display.short_description = 'Range'
    
    def get_queryset(self, request):
        return super().get_queryset(request).select_related('generated_by')
