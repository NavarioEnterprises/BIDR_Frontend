"""
Simple test script for analytics functionality.
"""

import os
import sys
import django

# Setup Django environment
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'product_management_service.settings')
django.setup()

from analytics.models import (
    ProductRequestAnalytics, CategoryAnalytics, UserBehaviorAnalytics,
    SearchAnalytics, SalesAnalytics, InventoryAnalytics
)
from product_requests.models import ProductRequest
from categories.models import Category


def test_analytics_models():
    """Test analytics models functionality."""
    
    print("Testing Analytics Models...")
    print("=" * 50)
    
    # Test ProductRequestAnalytics
    print("\n1. ProductRequestAnalytics:")
    request_analytics = ProductRequestAnalytics.objects.all()[:3]
    for analytics in request_analytics:
        print(f"   - {analytics}")
        print(f"     CTR: {analytics.click_through_rate}%, Response Rate: {analytics.response_rate}%")
    
    # Test CategoryAnalytics
    print("\n2. CategoryAnalytics:")
    category_analytics = CategoryAnalytics.objects.all()[:3]
    for analytics in category_analytics:
        print(f"   - {analytics}")
        print(f"     Requests: {analytics.total_requests}, Revenue: ${analytics.total_revenue}")
    
    # Test UserBehaviorAnalytics
    print("\n3. UserBehaviorAnalytics:")
    user_analytics = UserBehaviorAnalytics.objects.all()[:3]
    for analytics in user_analytics:
        print(f"   - {analytics}")
        print(f"     Users: {analytics.total_users}, Active: {analytics.active_users}")
    
    # Test SearchAnalytics
    print("\n4. SearchAnalytics:")
    search_analytics = SearchAnalytics.objects.all()[:5]
    for analytics in search_analytics:
        print(f"   - {analytics}")
        print(f"     CTR: {analytics.click_through_rate}%, Results: {analytics.results_count}")
    
    # Test SalesAnalytics
    print("\n5. SalesAnalytics:")
    sales_analytics = SalesAnalytics.objects.all()[:3]
    for analytics in sales_analytics:
        print(f"   - {analytics}")
    
    # Test InventoryAnalytics
    print("\n6. InventoryAnalytics:")
    inventory_analytics = InventoryAnalytics.objects.all()[:3]
    for analytics in inventory_analytics:
        print(f"   - {analytics}")
        print(f"     Value: ${analytics.total_inventory_value}, Turnover: {analytics.inventory_turnover}")
    
    print("\n" + "=" * 50)
    print("Analytics Models Test Completed!")
    

def test_aggregations():
    """Test analytics aggregations."""
    
    print("\nTesting Analytics Aggregations...")
    print("=" * 50)
    
    from django.db.models import Sum, Avg, Count
    
    # Test ProductRequest analytics aggregations
    request_summary = ProductRequestAnalytics.objects.aggregate(
        total_views=Sum('views'),
        total_quotes=Sum('quote_responses'),
        avg_interest_score=Avg('supplier_interest_score'),
        count=Count('id')
    )
    print(f"\nProductRequest Summary:")
    print(f"  Total Views: {request_summary.get('total_views', 0)}")
    print(f"  Total Quotes: {request_summary.get('total_quotes', 0)}")
    print(f"  Avg Interest Score: {request_summary.get('avg_interest_score', 0):.2f}")
    print(f"  Records: {request_summary.get('count', 0)}")
    
    # Test Category analytics aggregations
    category_summary = CategoryAnalytics.objects.aggregate(
        total_revenue=Sum('total_revenue'),
        avg_rating=Avg('average_rating'),
        total_requests=Sum('total_requests')
    )
    print(f"\nCategory Summary:")
    print(f"  Total Revenue: ${category_summary.get('total_revenue', 0)}")
    print(f"  Avg Rating: {category_summary.get('avg_rating', 0):.2f}")
    print(f"  Total Requests: {category_summary.get('total_requests', 0)}")
    
    # Test Search analytics aggregations  
    from django.db import models as django_models
    search_summary = SearchAnalytics.objects.aggregate(
        total_searches=Sum('search_count'),
        total_clicks=Sum('clicks'),
        zero_result_count=Count('id', filter=django_models.Q(zero_results=True))
    )
    print(f"\nSearch Summary:")
    print(f"  Total Searches: {search_summary.get('total_searches', 0)}")
    print(f"  Total Clicks: {search_summary.get('total_clicks', 0)}")
    print(f"  Zero Results: {search_summary.get('zero_result_count', 0)}")
    
    print("\n" + "=" * 50)
    print("Analytics Aggregations Test Completed!")


if __name__ == '__main__':
    test_analytics_models()
    test_aggregations()
