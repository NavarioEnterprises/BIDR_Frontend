from django.contrib import admin
from django.utils.html import format_html
from django.utils.safestring import mark_safe

# Note: Ratings models will be registered here when created
# This is a placeholder for future ratings functionality

# Example of how ratings admin might look:
# from .models import Rating, RatingResponse
# from core.admin import CoreAdminMixin

# @admin.register(Rating)
# class RatingAdmin(admin.ModelAdmin, CoreAdminMixin):
#     list_display = ['user', 'product', 'rating', 'comment_preview', 'created_at_display']
#     list_filter = ['rating', 'created_at']
#     search_fields = ['user__username', 'product__name', 'comment']
#     readonly_fields = ['created_at_display', 'updated_at_display']

#     def comment_preview(self, obj):
#         if obj.comment:
#             return obj.comment[:50] + '...' if len(obj.comment) > 50 else obj.comment
#         return "-"
#     comment_preview.short_description = 'Comment'

print("Ratings admin placeholder - implement when models are created")
