#!/usr/bin/env python3
"""
Management command to generate sample orders from existing product requests.
This creates realistic sample data for testing the order management system.
"""

import random
from decimal import Decimal
from django.core.management.base import BaseCommand, CommandError
from django.contrib.auth.models import User
from django.utils import timezone
from datetime import timedelta

from product_requests.models import ProductRequest, Order
from quotes.models import Quote


class Command(BaseCommand):
    help = 'Generate sample orders from existing product requests and quotes'

    def add_arguments(self, parser):
        parser.add_argument(
            '--count',
            type=int,
            default=10,
            help='Number of sample orders to create (default: 10)',
        )
        parser.add_argument(
            '--days-back',
            type=int,
            default=30,
            help='How many days back to create orders (default: 30)',
        )
        parser.add_argument(
            '--clear-existing',
            action='store_true',
            help='Clear existing orders before creating new ones',
        )

    def handle(self, *args, **options):
        count = options['count']
        days_back = options['days_back']
        clear_existing = options['clear_existing']

        if clear_existing:
            self.stdout.write(self.style.WARNING('Clearing existing orders...'))
            deleted_count = Order.objects.count()
            Order.objects.all().delete()
            self.stdout.write(self.style.SUCCESS(f'Deleted {deleted_count} existing orders'))

        # Get existing product requests
        requests = ProductRequest.objects.filter(status='ACTIVE')
        if not requests.exists():
            raise CommandError('No active product requests found. Create some requests first.')

        # Get existing users for sellers
        users = User.objects.all()
        if users.count() < 2:
            raise CommandError('Need at least 2 users (buyer and seller) to create orders')

        # Create sample orders
        created_orders = []
        
        for i in range(count):
            try:
                order = self.create_sample_order(requests, users, days_back)
                if order:
                    created_orders.append(order)
                    self.stdout.write(
                        self.style.SUCCESS(f'Created order {i+1}/{count}: {order.order_number}')
                    )
            except Exception as e:
                self.stdout.write(
                    self.style.WARNING(f'Failed to create order {i+1}: {str(e)}')
                )

        self.stdout.write(
            self.style.SUCCESS(f'\nSuccessfully created {len(created_orders)} sample orders!')
        )

        # Display summary
        if created_orders:
            self.stdout.write('\nOrder Summary:')
            for order in created_orders[:5]:  # Show first 5
                self.stdout.write(f'  - {order.order_number}: {order.status} - R{order.total_amount}')
            if len(created_orders) > 5:
                self.stdout.write(f'  ... and {len(created_orders) - 5} more')

    def create_sample_order(self, requests, users, days_back):
        """Create a single sample order."""
        # Pick a random request
        request = random.choice(requests)
        
        # Pick random buyer (different from request buyer if possible)
        available_buyers = [u for u in users if u != request.buyer_id]
        buyer = request.buyer_id if not available_buyers else random.choice(available_buyers)
        
        # Pick random seller (different from buyer)
        available_sellers = [u for u in users if u != buyer]
        if not available_sellers:
            return None
        seller = random.choice(available_sellers)

        # Create or get a quote for this request
        quote = self.create_sample_quote(request, seller)
        
        # Random order date within the specified range
        order_date = timezone.now() - timedelta(
            days=random.randint(0, days_back)
        )
        
        # Generate order details
        total_amount = self.generate_price_from_request(request)
        delivery_cost = random.choice([None, Decimal('50.00'), Decimal('100.00'), Decimal('150.00')])
        installation_cost = random.choice([None, Decimal('200.00'), Decimal('350.00')])
        
        # Random status with realistic distribution
        status = random.choices(
            ['PENDING', 'PAID', 'PROCESSING', 'SHIPPED', 'DELIVERED', 'COMPLETED', 'CANCELLED', 'REFUNDED'],
            weights=[5, 10, 15, 20, 25, 15, 7, 3],  # More likely to be in middle stages
            k=1
        )[0]
        
        # Payment status based on order status
        if status in ['PENDING']:
            payment_status = 'PENDING'
        elif status in ['CANCELLED']:
            payment_status = random.choice(['PENDING', 'FAILED'])
        elif status in ['REFUNDED']:
            payment_status = 'REFUNDED'
        else:
            payment_status = 'COMPLETED'
        
        # Payment method
        payment_method = random.choice([
            'Credit Card', 'EFT', 'Debit Card', 'PayPal', 'Bank Transfer', 
            'Apple Pay', 'Google Pay', 'Cash', 'Zapper', 'SnapScan'
        ])
        
        # Create order
        order = Order.objects.create(
            request_id=request,
            quote_id=quote,
            buyer_id=buyer,
            seller_id=seller,
            status=status,
            total_amount=total_amount,
            delivery_cost=delivery_cost,
            installation_cost=installation_cost,
            currency=request.currency,
            payment_status=payment_status,
            payment_method=payment_method,
            payment_reference=f'PAY-{random.randint(100000, 999999)}' if payment_status == 'COMPLETED' else None,
            payment_date=order_date + timedelta(hours=random.randint(1, 24)) if payment_status == 'COMPLETED' else None,
            delivery_address=self.generate_delivery_address(),
            estimated_delivery_date=order_date + timedelta(days=random.randint(3, 14)) if status not in ['CANCELLED', 'REFUNDED'] else None,
            actual_delivery_date=order_date + timedelta(days=random.randint(2, 10)) if status in ['DELIVERED', 'COMPLETED'] else None,
            tracking_number=f'TRK{random.randint(100000000, 999999999)}' if status in ['SHIPPED', 'DELIVERED', 'COMPLETED'] else None,
            special_instructions=random.choice([None, 'Handle with care', 'Call before delivery', 'Leave at gate']),
            created_at=order_date,
        )
        
        # Update timestamps manually since auto_now_add doesn't work with explicit dates
        Order.objects.filter(pk=order.pk).update(created_at=order_date, updated_at=order_date)
        
        return order

    def create_sample_quote(self, request, seller):
        """Create a sample quote for the request if none exists."""
        # Try to get existing quote
        try:
            quote = Quote.objects.filter(request_id=request, seller_id=seller).first()
            if quote:
                return quote
        except:
            pass
        
        # Create a mock quote object (since we might not have the quotes app fully set up)
        # For now, we'll create a simple object that satisfies the foreign key requirement
        try:
            from quotes.models import Quote
            
            total_amount = self.generate_price_from_request(request)
            quote = Quote.objects.create(
                request_id=request,
                seller_id=seller,
                total_amount=total_amount,
                currency=request.currency,
                delivery_cost=random.choice([None, Decimal('50.00'), Decimal('100.00')]),
                installation_cost=random.choice([None, Decimal('150.00'), Decimal('300.00')]),
                estimated_delivery_days=random.randint(3, 14),
                seller_notes=f"Competitive quote for {request.title}",
                status='ACCEPTED',
            )
            
            # Manually set creation time for older orders
            Quote.objects.filter(pk=quote.pk).update(
                created_at=timezone.now() - timedelta(days=random.randint(1, 5))
            )
            
            return quote
        except Exception as e:
            # If quotes app is not available, we need to handle this differently
            self.stdout.write(
                self.style.WARNING(f'Could not create quote: {str(e)}. You may need to set up the quotes app first.')
            )
            raise CommandError('Quotes app is required to create orders. Please set up the quotes model first.')

    def generate_price_from_request(self, request):
        """Generate a realistic price based on the request."""
        if request.max_budget:
            # Use max budget as upper limit
            min_price = float(request.max_budget) * 0.6  # 60% of max budget
            max_price = float(request.max_budget)
            return Decimal(str(round(random.uniform(min_price, max_price), 2)))
        
        # Default price ranges by category
        price_ranges = {
            'VEHICLE_SPARES': (200, 5000),
            'TYRES_RIMS': (800, 8000),
            'ELECTRONICS': (500, 15000),
        }
        
        min_price, max_price = price_ranges.get(request.category, (100, 2000))
        return Decimal(str(round(random.uniform(min_price, max_price), 2)))

    def generate_delivery_address(self):
        """Generate a realistic delivery address."""
        addresses = [
            {
                "street": "123 Main Road",
                "suburb": "Sandton",
                "city": "Johannesburg",
                "province": "Gauteng",
                "postal_code": "2196",
                "country": "South Africa"
            },
            {
                "street": "456 Ocean Drive",
                "suburb": "Sea Point",
                "city": "Cape Town",
                "province": "Western Cape",
                "postal_code": "8005",
                "country": "South Africa"
            },
            {
                "street": "789 Church Street",
                "suburb": "Pretoria Central",
                "city": "Pretoria",
                "province": "Gauteng",
                "postal_code": "0002",
                "country": "South Africa"
            },
            {
                "street": "321 Victoria Road",
                "suburb": "Durban North",
                "city": "Durban",
                "province": "KwaZulu-Natal",
                "postal_code": "4051",
                "country": "South Africa"
            },
        ]
        
        return random.choice(addresses)
