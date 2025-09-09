"""
Comprehensive tests for analytics functionality.
"""

import json
from decimal import Decimal
from datetime import date, timedelta
# Set up Django environment if not already configured
import os
import django
from django.conf import settings

if not settings.configured:
    os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'product_management_service.settings')
    django.setup()

from django.test import TestCase, Client
from django.contrib.auth.models import User
from django.urls import reverse
from django.utils import timezone
from rest_framework.test import APITestCase, APIClient
from rest_framework import status

from analytics.models import (
    ProductRequestAnalytics, CategoryAnalytics, UserBehaviorAnalytics,
    SearchAnalytics, SalesAnalytics, InventoryAnalytics, AnalyticsReport
)
from product_requests.models import ProductRequest, ConsumerElectronics, RequestWatchlist
from categories.models import Category


class AnalyticsModelsTestCase(TestCase):
    """Test analytics models functionality."""

    def setUp(self):
        self.user = User.objects.create_user(
            username='testuser',
            email='test@example.com',
            password='testpass123'
        )
        
        # Create category
        self.category = Category.objects.create(
            name='Consumer Electronics',
            description='Electronics category'
        )
        
        # Create product request
        self.electronics = ConsumerElectronics.objects.create(
            electronics_type='LAPTOP',
            brand_preference='Dell',
            condition_preference='NEW',
            quantity_needed=1,
            urgency='1_WEEK'
        )
        
        self.product_request = ProductRequest.objects.create(
            title='Gaming Laptop Request',
            description='Looking for a gaming laptop',
            category='ELECTRONICS',
            product_specifications={'type': 'laptop', 'brand': 'Dell'},
            quantity=1,
            urgency_timeline='1_WEEK',
            condition_preference='NEW',
            max_budget=1500.00,
            buyer_location={'lat': -26.2041, 'lng': 28.0473, 'address': 'Johannesburg, SA'},
            terms_accepted=True,
            contact_consent=True,
            buyer_id=self.user,
            consumer_electronics=self.electronics
        )

    def test_product_request_analytics_creation(self):
        """Test ProductRequestAnalytics model creation and properties."""
        analytics = ProductRequestAnalytics.objects.create(
            request=self.product_request,
            date=date.today(),
            timeframe='daily',
            views=100,
            unique_views=80,
            search_appearances=20,
            search_clicks=15,
            quote_responses=5,
            messages_sent=3,
            watchlist_additions=8,
            supplier_interest_score=Decimal('75.50')
        )
        
        self.assertEqual(analytics.request, self.product_request)
        self.assertEqual(analytics.views, 100)
        self.assertEqual(analytics.click_through_rate, Decimal('75.00'))  # 15/20 * 100
        self.assertEqual(analytics.response_rate, Decimal('5.00'))  # 5/100 * 100
        self.assertIn(str(self.product_request.request_id), str(analytics))

    def test_category_analytics_creation(self):
        """Test CategoryAnalytics model creation."""
        analytics = CategoryAnalytics.objects.create(
            category=self.category,
            date=date.today(),
            timeframe='daily',
            total_requests=50,
            active_requests=40,
            new_requests=10,
            closed_requests=5,
            total_views=1000,
            total_quote_requests=200,
            total_quotes=150,
            total_orders=25,
            total_revenue=Decimal('50000.00'),
            average_price=Decimal('2000.00'),
            average_rating=Decimal('4.5')
        )
        
        self.assertEqual(analytics.category, self.category)
        self.assertEqual(analytics.total_requests, 50)
        self.assertEqual(analytics.total_revenue, Decimal('50000.00'))
        self.assertIn(self.category.name, str(analytics))

    def test_search_analytics_creation(self):
        """Test SearchAnalytics model creation and properties."""
        import hashlib
        
        query = 'gaming laptop'
        query_hash = hashlib.md5(query.encode()).hexdigest()
        
        analytics = SearchAnalytics.objects.create(
            query=query,
            query_hash=query_hash,
            date=date.today(),
            search_count=100,
            results_count=50,
            clicks=25,
            average_position_clicked=Decimal('3.5'),
            zero_results=False
        )
        
        self.assertEqual(analytics.query, query)
        self.assertEqual(analytics.search_count, 100)
        self.assertEqual(analytics.click_through_rate, Decimal('25.00'))  # 25/100 * 100
        self.assertIn(query, str(analytics))

    def test_analytics_report_creation(self):
        """Test AnalyticsReport model creation and properties."""
        start_date = date.today() - timedelta(days=30)
        end_date = date.today()
        
        report = AnalyticsReport.objects.create(
            name='Monthly Product Performance Report',
            report_type='product_performance',
            description='Detailed product performance analysis',
            start_date=start_date,
            end_date=end_date,
            generated_by=self.user,
            status='completed',
            report_data={'summary': 'Test report data'},
            file_format='json'
        )
        
        self.assertEqual(report.name, 'Monthly Product Performance Report')
        self.assertEqual(report.date_range_days, 31)  # 30 days + 1
        self.assertIn('Monthly Product Performance Report', str(report))

    def test_user_behavior_analytics_creation(self):
        """Test UserBehaviorAnalytics model creation."""
        analytics = UserBehaviorAnalytics.objects.create(
            date=date.today(),
            timeframe='daily',
            total_users=1000,
            active_users=750,
            new_users=50,
            returning_users=700,
            total_sessions=2000,
            total_pageviews=15000,
            bounce_rate=Decimal('25.5'),
            users_with_requests=200,
            users_with_quotes=150,
            users_with_orders=100
        )
        
        self.assertEqual(analytics.total_users, 1000)
        self.assertEqual(analytics.bounce_rate, Decimal('25.5'))
        self.assertIn('User behavior analytics', str(analytics))

    def test_sales_analytics_creation(self):
        """Test SalesAnalytics model creation."""
        analytics = SalesAnalytics.objects.create(
            date=date.today(),
            timeframe='daily',
            total_orders=100,
            total_revenue=Decimal('250000.00'),
            total_units_sold=500,
            average_order_value=Decimal('2500.00'),
            average_units_per_order=Decimal('5.0'),
            total_quotes=300,
            accepted_quotes=120,
            quote_acceptance_rate=Decimal('40.0'),
            top_category=self.category
        )
        
        self.assertEqual(analytics.total_orders, 100)
        self.assertEqual(analytics.total_revenue, Decimal('250000.00'))
        self.assertEqual(analytics.top_category, self.category)
        self.assertIn('$250000.00', str(analytics))

    def test_inventory_analytics_creation(self):
        """Test InventoryAnalytics model creation."""
        analytics = InventoryAnalytics.objects.create(
            date=date.today(),
            timeframe='daily',
            total_products=5000,
            total_inventory_value=Decimal('2500000.00'),
            total_units=25000,
            in_stock_products=4500,
            out_of_stock_products=300,
            low_stock_products=200,
            units_received=1000,
            units_sold=800,
            units_adjusted=50,
            inventory_turnover=Decimal('8.5'),
            days_of_inventory=Decimal('42.9')
        )
        
        self.assertEqual(analytics.total_products, 5000)
        self.assertEqual(analytics.inventory_turnover, Decimal('8.5'))
        self.assertIn('Inventory analytics', str(analytics))


class AnalyticsAPITestCase(APITestCase):
    """Test analytics API endpoints."""

    def setUp(self):
        self.client = APIClient()
        self.user = User.objects.create_user(
            username='apiuser',
            email='api@example.com',
            password='apipass123'
        )
        self.client.force_authenticate(user=self.user)
        
        # Create test data
        self.category = Category.objects.create(
            name='Consumer Electronics',
            description='Electronics category'
        )
        
        self.electronics = ConsumerElectronics.objects.create(
            electronics_type='LAPTOP',
            brand_preference='Dell',
            condition_preference='NEW',
            quantity_needed=1,
            urgency='1_WEEK'
        )
        
        self.product_request = ProductRequest.objects.create(
            title='Gaming Laptop Request',
            description='Looking for a gaming laptop',
            category='ELECTRONICS',
            product_specifications={'type': 'laptop', 'brand': 'Dell'},
            quantity=1,
            urgency_timeline='1_WEEK',
            condition_preference='NEW',
            max_budget=1500.00,
            buyer_location={'lat': -26.2041, 'lng': 28.0473, 'address': 'Johannesburg, SA'},
            terms_accepted=True,
            contact_consent=True,
            buyer_id=self.user,
            consumer_electronics=self.electronics
        )

    def test_product_request_analytics_api(self):
        """Test ProductRequestAnalytics API endpoints."""
        # Create analytics data
        analytics = ProductRequestAnalytics.objects.create(
            request=self.product_request,
            date=date.today(),
            timeframe='daily',
            views=100,
            unique_views=80,
            quote_responses=5,
            supplier_interest_score=Decimal('75.50')
        )
        
        # Test list endpoint
        url = '/analytics/api/v1/product-request-analytics/'
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertGreater(len(response.data['results']), 0)
        
        # Test detail endpoint
        url = f'/analytics/api/v1/product-request-analytics/{analytics.id}/'
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['id'], analytics.id)
        
        # Test top performing requests endpoint
        url = '/analytics/api/v1/product-request-analytics/top_performing_requests/'
        response = self.client.get(url, {'metric': 'views', 'limit': 5})
        self.assertEqual(response.status_code, status.HTTP_200_OK)

    def test_category_analytics_api(self):
        """Test CategoryAnalytics API endpoints."""
        # Create analytics data
        analytics = CategoryAnalytics.objects.create(
            category=self.category,
            date=date.today(),
            timeframe='daily',
            total_requests=50,
            total_views=1000,
            total_revenue=Decimal('50000.00')
        )
        
        # Test list endpoint
        url = '/analytics/api/v1/category-analytics/'
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        # Test top categories endpoint
        url = '/analytics/api/v1/category-analytics/top_categories/'
        response = self.client.get(url, {'metric': 'total_revenue', 'limit': 10})
        self.assertEqual(response.status_code, status.HTTP_200_OK)

    def test_search_analytics_api(self):
        """Test SearchAnalytics API endpoints."""
        import hashlib
        
        query = 'gaming laptop'
        query_hash = hashlib.md5(query.encode()).hexdigest()
        
        # Create analytics data
        analytics = SearchAnalytics.objects.create(
            query=query,
            query_hash=query_hash,
            date=date.today(),
            search_count=100,
            results_count=50,
            clicks=25
        )
        
        # Test list endpoint
        url = '/analytics/api/v1/search-analytics/'
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        # Test top queries endpoint
        url = '/analytics/api/v1/search-analytics/top_queries/'
        response = self.client.get(url, {'days': 7, 'limit': 20})
        self.assertEqual(response.status_code, status.HTTP_200_OK)

    def test_dashboard_overview_api(self):
        """Test analytics dashboard overview endpoint."""
        # Create some analytics data
        ProductRequestAnalytics.objects.create(
            request=self.product_request,
            date=date.today(),
            timeframe='daily',
            views=100,
            quote_responses=5
        )
        
        url = '/analytics/api/v1/dashboard/overview/'
        response = self.client.get(url, {'timeframe': 'weekly'})
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('summary', response.data)
        self.assertIn('total_requests', response.data['summary'])

    def test_dashboard_trends_api(self):
        """Test analytics dashboard trends endpoint."""
        # Create analytics data
        ProductRequestAnalytics.objects.create(
            request=self.product_request,
            date=date.today(),
            timeframe='daily',
            views=100,
            quote_responses=5
        )
        
        url = '/analytics/api/v1/dashboard/trends/'
        response = self.client.get(url, {'days': 30})
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('daily_requests', response.data)
        self.assertIn('daily_analytics', response.data)

    def test_analytics_report_api(self):
        """Test AnalyticsReport API endpoints."""
        # Test create report
        url = '/analytics/api/v1/reports/'
        data = {
            'name': 'Test Report',
            'report_type': 'product_performance',
            'description': 'A test report',
            'start_date': '2025-08-01',
            'end_date': '2025-08-31',
            'file_format': 'json'
        }
        response = self.client.post(url, data)
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        
        # Test list reports
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        # Test generate report
        report_id = response.data['results'][0]['id']
        generate_url = f'/analytics/api/v1/reports/{report_id}/generate/'
        response = self.client.post(generate_url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)

    def test_authentication_required(self):
        """Test that analytics endpoints require authentication."""
        self.client.force_authenticate(user=None)
        
        endpoints = [
            '/analytics/api/v1/product-request-analytics/',
            '/analytics/api/v1/category-analytics/',
            '/analytics/api/v1/dashboard/overview/',
            '/analytics/api/v1/reports/',
        ]
        
        for endpoint in endpoints:
            response = self.client.get(endpoint)
            self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)


class ProductRequestAnalyticsIntegrationTestCase(APITestCase):
    """Test analytics integration with product requests."""

    def setUp(self):
        self.client = APIClient()
        self.user = User.objects.create_user(
            username='integrationuser',
            email='integration@example.com',
            password='integrationpass123'
        )
        self.client.force_authenticate(user=self.user)
        
        self.category = Category.objects.create(
            name='Consumer Electronics',
            description='Electronics category'
        )

    def test_analytics_updated_on_request_creation(self):
        """Test that analytics are updated when creating a product request."""
        initial_count = ProductRequestAnalytics.objects.count()
        
        # Create product request via API
        url = '/product-requests/api/v1/requests/'
        data = {
            'title': 'Test Laptop Request',
            'description': 'Looking for a test laptop',
            'category': 'CONSUMER_ELECTRONICS',
            'urgency_timeline': '1_WEEK',
            'condition_preference': 'NEW',
            'max_budget': 1000.00,
            'product_specifications': {
                'electronics_type': 'LAPTOP',
                'brand_preference': 'Dell'
            }
        }
        
        response = self.client.post(url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        
        # Check that analytics were created
        self.assertGreater(ProductRequestAnalytics.objects.count(), initial_count)

    def test_click_tracking_api(self):
        """Test click tracking API endpoint."""
        # Create a product request first
        electronics = ConsumerElectronics.objects.create(
            electronics_type='LAPTOP',
            brand_preference='Dell',
            condition_preference='NEW',
            quantity_needed=1,
            urgency='1_WEEK'
        )
        
        product_request = ProductRequest.objects.create(
            title='Test Request',
            description='Test description',
            category='ELECTRONICS',
            product_specifications={'type': 'laptop', 'brand': 'Dell'},
            quantity=1,
            urgency_timeline='1_WEEK',
            buyer_location={'lat': -26.2041, 'lng': 28.0473, 'address': 'Johannesburg, SA'},
            terms_accepted=True,
            contact_consent=True,
            buyer_id=self.user,
            consumer_electronics=electronics
        )
        
        # Test click tracking
        url = f'/product-requests/api/v1/requests/{product_request.request_id}/track_click/'
        data = {'source': 'search'}
        response = self.client.post(url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['message'], 'Click tracked successfully')
        
        # Verify analytics were updated
        analytics = ProductRequestAnalytics.objects.filter(request=product_request).first()
        self.assertIsNotNone(analytics)

    def test_search_appearance_tracking_api(self):
        """Test search appearance tracking API endpoint."""
        # Create a product request
        electronics = ConsumerElectronics.objects.create(
            electronics_type='LAPTOP',
            brand_preference='Dell',
            condition_preference='NEW',
            quantity_needed=1,
            urgency='1_WEEK'
        )
        
        product_request = ProductRequest.objects.create(
            title='Test Request',
            description='Test description',
            category='ELECTRONICS',
            product_specifications={'type': 'laptop', 'brand': 'Dell'},
            quantity=1,
            urgency_timeline='1_WEEK',
            buyer_location={'lat': -26.2041, 'lng': 28.0473, 'address': 'Johannesburg, SA'},
            terms_accepted=True,
            contact_consent=True,
            buyer_id=self.user,
            consumer_electronics=electronics
        )
        
        # Test search appearance tracking
        url = f'/product-requests/api/v1/requests/{product_request.request_id}/track_search_appearance/'
        data = {
            'query': 'laptop dell',
            'position': 3
        }
        response = self.client.post(url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['message'], 'Search appearance tracked successfully')
        
        # Verify analytics were updated
        analytics = ProductRequestAnalytics.objects.filter(request=product_request).first()
        self.assertIsNotNone(analytics)
        
        # Verify search analytics were created
        search_analytics = SearchAnalytics.objects.filter(query='laptop dell').first()
        self.assertIsNotNone(search_analytics)

    def test_watchlist_analytics_integration(self):
        """Test analytics integration with watchlist additions."""
        # Create a product request
        electronics = ConsumerElectronics.objects.create(
            electronics_type='LAPTOP',
            brand_preference='Dell',
            condition_preference='NEW',
            quantity_needed=1,
            urgency='1_WEEK'
        )
        
        product_request = ProductRequest.objects.create(
            title='Test Request',
            description='Test description',
            category='ELECTRONICS',
            product_specifications={'type': 'laptop', 'brand': 'Dell'},
            quantity=1,
            urgency_timeline='1_WEEK',
            buyer_location={'lat': -26.2041, 'lng': 28.0473, 'address': 'Johannesburg, SA'},
            terms_accepted=True,
            contact_consent=True,
            buyer_id=self.user,
            consumer_electronics=electronics
        )
        
        # Add to watchlist via API
        url = '/product-requests/api/v1/watchlist/'
        data = {'request': product_request.request_id}
        response = self.client.post(url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        
        # Verify watchlist analytics were updated
        analytics = ProductRequestAnalytics.objects.filter(request=product_request).first()
        self.assertIsNotNone(analytics)
