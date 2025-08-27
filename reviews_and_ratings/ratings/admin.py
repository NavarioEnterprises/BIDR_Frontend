from django.contrib import admin
from .models import Rating, AverageRating


@admin.register(Rating)
class RatingAdmin(admin.ModelAdmin):
    list_display = ['user', 'product_id', 'overall_rating', 'quality_rating', 'service_rating', 'delivery_rating', 'created_at']
    list_filter = ['overall_rating', 'quality_rating', 'service_rating', 'delivery_rating', 'created_at', 'seller_id']
    search_fields = ['user__username', 'product_id', 'seller_id']
    readonly_fields = ['created_at', 'updated_at']
    ordering = ['-created_at']
    
    fieldsets = (
        ('Rating Information', {
            'fields': ('user', 'product_id', 'seller_id')
        }),
        ('Ratings', {
            'fields': ('overall_rating', 'quality_rating', 'service_rating', 'delivery_rating')
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )


@admin.register(AverageRating)
class AverageRatingAdmin(admin.ModelAdmin):
    list_display = ['product_id', 'seller_id', 'overall_avg', 'quality_avg', 'service_avg', 'delivery_avg', 'total_ratings', 'total_reviews']
    list_filter = ['overall_avg', 'total_ratings', 'total_reviews', 'created_at']
    search_fields = ['product_id', 'seller_id']
    readonly_fields = ['created_at', 'updated_at']
    ordering = ['-overall_avg']
    
    fieldsets = (
        ('Product Information', {
            'fields': ('product_id', 'seller_id')
        }),
        ('Average Ratings', {
            'fields': ('overall_avg', 'quality_avg', 'service_avg', 'delivery_avg')
        }),
        ('Statistics', {
            'fields': ('total_ratings', 'total_reviews')
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )
