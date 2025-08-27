"""
Management command to populate sample quotes for product requests.
This adds 1-3 quotes to existing product requests, skipping some to show variety.
"""
import random
from decimal import Decimal
from django.core.management.base import BaseCommand, CommandError
from django.contrib.auth.models import User
from django.utils import timezone
from datetime import timedelta
from product_requests.models import ProductRequest
from quotes.models import Quote


class Command(BaseCommand):
    help = 'Populate sample quotes for existing product requests'

    def add_arguments(self, parser):
        parser.add_argument(
            '--clear',
            action='store_true',
            help='Clear existing quotes before adding new ones',
        )
        parser.add_argument(
            '--count',
            type=int,
            default=None,
            help='Number of requests to add quotes to (default: all active requests)',
        )

    def handle(self, *args, **options):
        if options['clear']:
            self.stdout.write('Clearing existing quotes...')
            Quote.objects.all().delete()
            self.stdout.write(self.style.SUCCESS('Existing quotes cleared.'))

        # Get active product requests
        requests = ProductRequest.objects.filter(status='ACTIVE').order_by('-created_at')
        
        if options['count']:
            requests = requests[:options['count']]

        self.stdout.write(f'Found {requests.count()} active product requests.')

        # Get or create sample sellers
        sellers = self.create_sample_sellers()
        self.stdout.write(f'Created/found {len(sellers)} sample sellers.')

        quotes_created = 0
        requests_with_quotes = 0

        for i, request in enumerate(requests):
            # Skip some requests to show variety (skip every 3rd and 4th request)
            should_skip = (i % 3 == 0) or (i % 7 == 0)
            
            if should_skip:
                self.stdout.write(f'Skipping request {request.request_id} (showing variety)')
                continue

            # Create 1-3 quotes for this request
            num_quotes = random.randint(1, 3)
            selected_sellers = random.sample(sellers, min(num_quotes, len(sellers)))
            
            request_quotes_created = 0
            for j, seller in enumerate(selected_sellers):
                quote = self.create_quote(request, seller, j)
                if quote:
                    request_quotes_created += 1
                    quotes_created += 1

            if request_quotes_created > 0:
                requests_with_quotes += 1
                self.stdout.write(
                    f'Created {request_quotes_created} quotes for request {request.request_id}'
                )

        self.stdout.write(
            self.style.SUCCESS(
                f'Successfully created {quotes_created} quotes across {requests_with_quotes} requests.'
            )
        )

    def create_sample_sellers(self):
        """Create or get sample seller users"""
        seller_data = [
            {'username': 'auto_parts_express', 'first_name': 'Auto Parts', 'last_name': 'Express'},
            {'username': 'quality_spares_co', 'first_name': 'Quality Spares', 'last_name': 'Co'},
            {'username': 'speed_motors', 'first_name': 'Speed', 'last_name': 'Motors'},
            {'username': 'premium_parts', 'first_name': 'Premium', 'last_name': 'Parts'},
            {'username': 'city_auto_supply', 'first_name': 'City Auto', 'last_name': 'Supply'},
            {'username': 'reliable_parts_hub', 'first_name': 'Reliable Parts', 'last_name': 'Hub'},
            {'username': 'fast_track_spares', 'first_name': 'Fast Track', 'last_name': 'Spares'},
            {'username': 'elite_auto_parts', 'first_name': 'Elite Auto', 'last_name': 'Parts'},
            {'username': 'metro_motors', 'first_name': 'Metro', 'last_name': 'Motors'},
            {'username': 'superior_supplies', 'first_name': 'Superior', 'last_name': 'Supplies'},
        ]

        sellers = []
        for data in seller_data:
            seller, created = User.objects.get_or_create(
                username=data['username'],
                defaults={
                    'email': f"{data['username']}@example.com",
                    'first_name': data['first_name'],
                    'last_name': data['last_name'],
                    'is_active': True,
                }
            )
            sellers.append(seller)
            if created:
                self.stdout.write(f'Created seller: {seller.get_full_name()}')

        return sellers

    def create_quote(self, request, seller, position):
        """Create a sample quote for a request"""
        try:
            # Calculate base amount based on request category and position
            base_amounts = {
                'VEHICLE_SPARES': random.randint(200, 800),
                'TYRES_RIMS': random.randint(800, 2500),
                'ELECTRONICS': random.randint(500, 3000),
            }
            
            base_amount = base_amounts.get(request.category, 500)
            # Add variation based on seller position (first quote is usually more expensive)
            variation = random.randint(-100, 150) + (position * 50)
            total_amount = max(base_amount + variation, 100)  # Minimum 100

            # Create quote
            quote = Quote.objects.create(
                request_id=request,
                seller_id=seller,
                total_amount=Decimal(str(total_amount)),
                currency='ZAR',
                delivery_cost=Decimal(str(random.randint(50, 200))) if random.random() > 0.3 else None,
                installation_cost=Decimal(str(random.randint(100, 300))) if random.random() > 0.6 else None,
                estimated_delivery_days=random.randint(1, 14),
                terms_conditions=self.get_sample_terms(),
                seller_notes=self.get_sample_seller_notes(seller, request.category),
                warranty_info={
                    'duration': f"{random.randint(6, 24)} months",
                    'coverage': 'parts and labor' if random.random() > 0.5 else 'parts only',
                    'conditions': 'Standard warranty terms apply'
                } if random.random() > 0.4 else None,
                status='PENDING',
                valid_until=timezone.now() + timedelta(days=random.randint(7, 30)),
                created_at=timezone.now() - timedelta(
                    hours=random.randint(1, 48),
                    minutes=random.randint(0, 59)
                )
            )

            return quote

        except Exception as e:
            self.stderr.write(f'Error creating quote for request {request.request_id}: {e}')
            return None

    def get_sample_terms(self):
        """Get sample terms and conditions"""
        terms_options = [
            "Payment due within 30 days. All sales final.",
            "50% deposit required, balance on completion. 30-day warranty.",
            "Cash on delivery. Installation available at extra cost.",
            "Payment terms negotiable. Bulk discounts available.",
            "Net 15 payment terms. Extended warranty options available.",
        ]
        return random.choice(terms_options)

    def get_sample_seller_notes(self, seller, category):
        """Get sample seller notes based on category"""
        notes_by_category = {
            'VEHICLE_SPARES': [
                "Genuine OEM parts in stock. Professional installation available.",
                "High-quality aftermarket option with 12-month warranty.",
                "Brand new parts with manufacturer warranty. Quick delivery.",
                "Certified parts dealer with 15+ years experience.",
                "Competitive pricing with quality guarantee. Same-day service available.",
            ],
            'TYRES_RIMS': [
                "Premium brand tyres with excellent grip and durability.",
                "Professional fitment and balancing included in price.",
                "New tyres with manufacturer warranty. Mobile fitting available.",
                "Quality rims with perfect finish. Variety of styles available.",
                "Complete wheel and tyre packages. Expert installation.",
            ],
            'ELECTRONICS': [
                "Latest model with full manufacturer warranty.",
                "Energy efficient with A+ rating. Free delivery included.",
                "Professional installation and setup service available.",
                "Extended warranty options available. Trade-in accepted.",
                "Bulk pricing available for multiple units. Technical support included.",
            ]
        }

        category_notes = notes_by_category.get(category, [
            "Quality products at competitive prices.",
            "Professional service with customer satisfaction guarantee.",
            "Fast delivery and reliable service.",
        ])

        return random.choice(category_notes)
