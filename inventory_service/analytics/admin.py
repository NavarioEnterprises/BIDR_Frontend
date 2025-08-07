from django.contrib import admin
from .models import (
    ProductAnalytics, CategoryAnalytics, UserBehaviorAnalytics,
    SearchAnalytics, SalesAnalytics, InventoryAnalytics, AnalyticsReport
)


@admin.register(ProductAnalytics)
class ProductAnalyticsAdmin(admin.ModelAdmin):
    list_display = ['product', 'date', 'timeframe', 'views', 'unique_views', 'created_at']
    list_filter = ['timeframe', 'date', 'created_at']
    search_fields = ['product__name']
    ordering = ['-date', '-created_at']
    readonly_fields = ['id', 'created_at', 'updated_at']
    
    def has_add_permission(self, request):
        return False


@admin.register(CategoryAnalytics)
class CategoryAnalyticsAdmin(admin.ModelAdmin):
    list_display = ['category', 'date', 'timeframe', 'total_products', 'active_products', 'created_at']
    list_filter = ['timeframe', 'date', 'created_at']
    search_fields = ['category__name']
    ordering = ['-date', '-created_at']
    readonly_fields = ['id', 'created_at', 'updated_at']
    
    def has_add_permission(self, request):
        return False


@admin.register(UserBehaviorAnalytics)
class UserBehaviorAnalyticsAdmin(admin.ModelAdmin):
    list_display = ['date', 'timeframe', 'total_sessions', 'total_pageviews', 'active_users', 'created_at']
    list_filter = ['timeframe', 'date', 'created_at']
    ordering = ['-date', '-created_at']
    readonly_fields = ['id', 'created_at', 'updated_at']
    
    def has_add_permission(self, request):
        return False


@admin.register(SearchAnalytics)
class SearchAnalyticsAdmin(admin.ModelAdmin):
    list_display = ['query', 'date', 'search_count', 'results_count', 'clicks', 'created_at']
    list_filter = ['date', 'zero_results', 'created_at']
    search_fields = ['query']
    ordering = ['-search_count', '-date']
    readonly_fields = ['id', 'created_at', 'updated_at']
    
    def has_add_permission(self, request):
        return False


@admin.register(SalesAnalytics)
class SalesAnalyticsAdmin(admin.ModelAdmin):
    list_display = ['date', 'timeframe', 'total_orders', 'total_revenue', 'created_at']
    list_filter = ['timeframe', 'date', 'created_at']
    ordering = ['-date', '-created_at']
    readonly_fields = ['id', 'created_at', 'updated_at']
    
    def has_add_permission(self, request):
        return False


@admin.register(InventoryAnalytics)
class InventoryAnalyticsAdmin(admin.ModelAdmin):
    list_display = ['date', 'timeframe', 'total_products', 'low_stock_products', 'created_at']
    list_filter = ['timeframe', 'date', 'created_at']
    ordering = ['-date', '-created_at']
    readonly_fields = ['id', 'created_at', 'updated_at']
    
    def has_add_permission(self, request):
        return False


@admin.register(AnalyticsReport)
class AnalyticsReportAdmin(admin.ModelAdmin):
    list_display = ['name', 'report_type', 'status', 'created_at']
    list_filter = ['report_type', 'status', 'created_at']
    search_fields = ['name', 'description']
    ordering = ['-created_at']
    readonly_fields = ['id', 'created_at', 'updated_at']
