"""
Management command to generate sample analytics data.
"""

import random
import hashlib
from datetime import datetime, timedelta
from decimal import Decimal
from django.core.management.base import BaseCommand
from django.utils import timezone
from django.contrib.auth.models import User

from analytics.models import (
    ProductRequestAnalytics, CategoryAnalytics, UserBehaviorAnalytics,
    SearchAnalytics, SalesAnalytics, InventoryAnalytics, AnalyticsReport
)
from product_requests.models import ProductRequest
from categories.models import Category


class Command(BaseCommand):
    help = 'Generate sample analytics data for testing'

    def add_arguments(self, parser):
        parser.add_argument(
            '--days',
            type=int,
            default=30,
            help='Number of days of data to generate'
        )
        parser.add_argument(
            '--clear',
            action='store_true',
            help='Clear existing analytics data first'
        )

    def handle(self, *args, **options):
        days = options['days']
        clear = options['clear']

        if clear:
            self.stdout.write('Clearing existing analytics data...')
            ProductRequestAnalytics.objects.all().delete()
            CategoryAnalytics.objects.all().delete()
            UserBehaviorAnalytics.objects.all().delete()
            SearchAnalytics.objects.all().delete()
            SalesAnalytics.objects.all().delete()
            InventoryAnalytics.objects.all().delete()
            AnalyticsReport.objects.all().delete()
            self.stdout.write(self.style.SUCCESS('Existing data cleared.'))

        self.stdout.write(f'Generating {days} days of sample analytics data...')

        # Generate data for each day
        end_date = timezone.now().date()
        start_date = end_date - timedelta(days=days)

        for i in range(days):
            current_date = start_date + timedelta(days=i)
            self._generate_daily_data(current_date)

        self.stdout.write(self.style.SUCCESS(f'Successfully generated {days} days of analytics data.'))

    def _generate_daily_data(self, date):
        """Generate analytics data for a specific date."""
        
        # Generate ProductRequest analytics
        self._generate_product_request_analytics(date)
        
        # Generate Category analytics
        self._generate_category_analytics(date)
        
        # Generate User Behavior analytics
        self._generate_user_behavior_analytics(date)
        
        # Generate Search analytics
        self._generate_search_analytics(date)
        
        # Generate Sales analytics
        self._generate_sales_analytics(date)
        
        # Generate Inventory analytics
        self._generate_inventory_analytics(date)

    def _generate_product_request_analytics(self, date):
        """Generate ProductRequest analytics for a date."""
        requests = ProductRequest.objects.all()[:10]  # Sample some requests
        
        for request in requests:
            ProductRequestAnalytics.objects.create(
                request=request,
                date=date,
                timeframe='daily',
                views=random.randint(5, 100),
                unique_views=random.randint(3, 80),
                search_appearances=random.randint(1, 20),
                search_clicks=random.randint(0, 15),
                quote_responses=random.randint(0, 10),
                messages_sent=random.randint(0, 5),
                watchlist_additions=random.randint(0, 8),
                supplier_interest_score=Decimal(str(random.uniform(0, 100))).quantize(Decimal('0.01'))
            )

    def _generate_category_analytics(self, date):
        """Generate Category analytics for a date."""
        categories = Category.objects.all()[:5]  # Sample some categories
        
        for category in categories:
            CategoryAnalytics.objects.create(
                category=category,
                date=date,
                timeframe='daily',
                total_requests=random.randint(5, 50),
                active_requests=random.randint(3, 40),
                new_requests=random.randint(0, 10),
                closed_requests=random.randint(0, 8),
                total_views=random.randint(50, 500),
                total_quote_requests=random.randint(10, 100),
                total_quotes=random.randint(5, 80),
                total_orders=random.randint(1, 20),
                total_revenue=Decimal(str(random.uniform(1000, 50000))).quantize(Decimal('0.01')),
                average_price=Decimal(str(random.uniform(10, 1000))).quantize(Decimal('0.01')),
                average_rating=Decimal(str(random.uniform(3.0, 5.0))).quantize(Decimal('0.01'))
            )

    def _generate_user_behavior_analytics(self, date):
        """Generate User Behavior analytics for a date."""
        UserBehaviorAnalytics.objects.create(
            date=date,
            timeframe='daily',
            total_users=random.randint(50, 500),
            active_users=random.randint(20, 300),
            new_users=random.randint(0, 50),
            returning_users=random.randint(15, 200),
            total_sessions=random.randint(100, 800),
            total_pageviews=random.randint(500, 5000),
            bounce_rate=Decimal(str(random.uniform(20, 80))).quantize(Decimal('0.01')),
            users_with_requests=random.randint(5, 100),
            users_with_quotes=random.randint(2, 50),
            users_with_orders=random.randint(1, 25)
        )

    def _generate_search_analytics(self, date):
        """Generate Search analytics for a date."""
        search_queries = [
            'electronics laptop', 'vehicle tires', 'consumer electronics',
            'car parts', 'mobile phones', 'office equipment',
            'industrial machinery', 'computer accessories',
            'automotive parts', 'home appliances'
        ]
        
        for query in random.sample(search_queries, random.randint(3, 7)):
            query_hash = hashlib.md5(query.encode()).hexdigest()
            SearchAnalytics.objects.create(
                query=query,
                query_hash=query_hash,
                date=date,
                search_count=random.randint(1, 50),
                results_count=random.randint(0, 100),
                clicks=random.randint(0, 30),
                average_position_clicked=Decimal(str(random.uniform(1, 10))).quantize(Decimal('0.01')),
                zero_results=random.choice([True, False]) if random.random() < 0.1 else False
            )

    def _generate_sales_analytics(self, date):
        """Generate Sales analytics for a date."""
        top_category = Category.objects.first() if Category.objects.exists() else None
        
        SalesAnalytics.objects.create(
            date=date,
            timeframe='daily',
            total_orders=random.randint(5, 50),
            total_revenue=Decimal(str(random.uniform(5000, 100000))).quantize(Decimal('0.01')),
            total_units_sold=random.randint(20, 200),
            average_order_value=Decimal(str(random.uniform(100, 2000))).quantize(Decimal('0.01')),
            average_units_per_order=Decimal(str(random.uniform(1, 10))).quantize(Decimal('0.01')),
            total_quotes=random.randint(10, 100),
            accepted_quotes=random.randint(2, 50),
            quote_acceptance_rate=Decimal(str(random.uniform(10, 80))).quantize(Decimal('0.01')),
            top_category=top_category
        )

    def _generate_inventory_analytics(self, date):
        """Generate Inventory analytics for a date."""
        InventoryAnalytics.objects.create(
            date=date,
            timeframe='daily',
            total_products=random.randint(100, 1000),
            total_inventory_value=Decimal(str(random.uniform(50000, 1000000))).quantize(Decimal('0.01')),
            total_units=random.randint(1000, 10000),
            in_stock_products=random.randint(80, 900),
            out_of_stock_products=random.randint(0, 50),
            low_stock_products=random.randint(5, 100),
            units_received=random.randint(10, 200),
            units_sold=random.randint(20, 300),
            units_adjusted=random.randint(-50, 50),
            inventory_turnover=Decimal(str(random.uniform(0.5, 12.0))).quantize(Decimal('0.01')),
            days_of_inventory=Decimal(str(random.uniform(30, 365))).quantize(Decimal('0.01'))
        )
