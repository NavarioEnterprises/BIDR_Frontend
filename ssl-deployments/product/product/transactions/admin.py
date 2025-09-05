from django.contrib import admin
from django.utils.html import format_html
from django.utils.safestring import mark_safe

# Note: Transaction models will be registered here when created
# This is a placeholder for future transaction functionality

# Example of how transaction admin might look:
# from .models import Transaction, Quote, Order
# from core.admin import CoreAdminMixin

# @admin.register(Transaction)
# class TransactionAdmin(admin.ModelAdmin, CoreAdminMixin):
#     list_display = ['transaction_id', 'buyer', 'seller', 'amount', 'status_display', 'created_at_display']
#     list_filter = ['status', 'transaction_type', 'created_at']
#     search_fields = ['transaction_id', 'buyer__username', 'seller__username']
#     readonly_fields = ['transaction_id', 'created_at_display', 'updated_at_display']

# @admin.register(Quote)
# class QuoteAdmin(admin.ModelAdmin, CoreAdminMixin):
#     list_display = ['quote_number', 'request', 'seller', 'quoted_price', 'status_display', 'created_at_display']
#     list_filter = ['status', 'created_at']
#     search_fields = ['quote_number', 'request__title', 'seller__username']

print("Transactions admin placeholder - implement when models are created")
