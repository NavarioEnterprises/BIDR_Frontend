"""
Django management command to add sample product requests for testing.
"""
import random
from decimal import Decimal
from django.core.management.base import BaseCommand
from django.contrib.auth import get_user_model
from categories.models import Category, CategorySpecification
from product_requests.models import ProductRequest, ConsumerElectronics, VehicleSpares, VehicleTyresRims

User = get_user_model()


class Command(BaseCommand):
    help = 'Add sample product requests for ConsumerElectronics, VehicleSpares, and VehicleTyresRims'

    def add_arguments(self, parser):
        parser.add_argument(
            '--count',
            type=int,
            default=10,
            help='Number of sample requests per category (default: 10)'
        )

    def handle(self, *args, **options):
        count = options['count']
        
        # Create test user if doesn't exist
        user, created = User.objects.get_or_create(
            username='sample_user',
            defaults={
                'email': 'sample@test.com',
                'first_name': 'Sample',
                'last_name': 'User'
            }
        )
        
        if created:
            user.set_password('samplepass123')
            user.save()
            self.stdout.write(
                self.style.SUCCESS(f'Created test user: {user.username}')
            )
        else:
            self.stdout.write(f'Using existing user: {user.username}')

        # Create categories if they don't exist
        electronics_category = self.create_category(
            'Consumer Electronics',
            'consumer-electronics',
            'Electronics'
        )
        
        vehicle_spares_category = self.create_category(
            'Vehicle Spares',
            'vehicle-spares',
            'Vehicle'
        )
        
        tyres_rims_category = self.create_category(
            'Vehicle Tyres & Rims',
            'vehicle-tyres-rims',
            'Vehicle'
        )

        # Create sample requests
        self.create_electronics_requests(user, electronics_category, count)
        self.create_vehicle_spares_requests(user, vehicle_spares_category, count)
        self.create_tyres_rims_requests(user, tyres_rims_category, count)
        
        total_created = count * 3
        self.stdout.write(
            self.style.SUCCESS(
                f'Successfully created {total_created} sample product requests '
                f'({count} per category)'
            )
        )

    def create_category(self, name, slug, description):
        """Create or get category."""
        category, created = Category.objects.get_or_create(
            slug=slug,
            defaults={
                'name': name,
                'description': description
            }
        )
        
        if created:
            self.stdout.write(f'Created category: {name}')
        
        return category

    def create_electronics_requests(self, user, category, count):
        """Create sample consumer electronics requests."""
        electronics_types = [
            'SMARTPHONE', 'LAPTOP', 'TELEVISION', 'REFRIGERATOR',
            'WASHING_MACHINE', 'MICROWAVE', 'CAMERA', 'TABLET'
        ]
        
        brands = ['Samsung', 'Apple', 'Sony', 'LG', 'Dell', 'HP', 'Canon']
        urgencies = ['ASAP', 'WITHIN_WEEK', 'WITHIN_MONTH', 'FLEXIBLE']
        
        for i in range(count):
            electronics_type = random.choice(electronics_types)
            brand = random.choice(brands)
            
            # Create ConsumerElectronics specification
            electronics_spec = ConsumerElectronics.objects.create(
                electronics_type=electronics_type,
                brand_preference=brand,
                model_series=f'{brand} Series {i+1}',
                quantity_needed=random.randint(1, 20),
                min_price=Decimal(str(random.randint(100, 500))),
                max_price=Decimal(str(random.randint(600, 2000))),
                urgency=random.choice(urgencies),
                condition_preference='NEW',
                purpose_of_purchase='OFFICE_USE',
                warranty_required='YES',
                energy_efficiency_required=random.choice(['YES', 'NO'])
            )
            
            # Create ProductRequest
            product_request = ProductRequest.objects.create(
                buyer_id=user,
                category='ELECTRONICS',
                title=f'{brand} {electronics_type.replace("_", " ").title()} Request {i+1}',
                description=f'Looking for {electronics_spec.quantity_needed} units of {brand} {electronics_type.replace("_", " ").lower()} for office use.',
                product_specifications={
                    'electronics_type': electronics_type,
                    'brand_preference': brand,
                    'quantity_needed': electronics_spec.quantity_needed,
                    'urgency': electronics_spec.urgency
                },
                quantity=electronics_spec.quantity_needed,
                max_budget=electronics_spec.max_price,
                buyer_location={
                    'lat': -17.8292 + random.uniform(-0.1, 0.1),
                    'lng': 31.0522 + random.uniform(-0.1, 0.1),
                    'address': f'Test Address {i+1}, Harare, Zimbabwe'
                },
                urgency_timeline=random.choice(['ASAP', '1_WEEK', '1_MONTH']),
                terms_accepted=True,
                contact_consent=True,
                consumer_electronics=electronics_spec
            )
            
            self.stdout.write(f'Created electronics request: {product_request.title}')

    def create_vehicle_spares_requests(self, user, category, count):
        """Create sample vehicle spares requests."""
        makes = ['Toyota', 'Ford', 'BMW', 'Mercedes', 'Audi', 'Honda', 'Nissan']
        models = ['Corolla', 'Camry', 'Focus', 'Fiesta', '320i', 'C-Class', 'Civic']
        parts = ['Brake Pads', 'Oil Filter', 'Air Filter', 'Spark Plugs', 'Battery', 'Headlights']
        categories_parts = ['BRAKES', 'ENGINE', 'ELECTRICAL', 'BODY', 'SUSPENSION']
        
        for i in range(count):
            make = random.choice(makes)
            model = random.choice(models)
            part = random.choice(parts)
            year = random.randint(2010, 2023)
            
            # Create VehicleSpares specification
            spare_spec = VehicleSpares.objects.create(
                vehicle_make=make,
                vehicle_model=model,
                vehicle_year=year,
                vehicle_type='PASSENGER_CAR',
                part_name=part,
                part_category=random.choice(categories_parts),
                quantity=random.randint(1, 10),
                condition_preference='NEW',
                urgency=random.choice(['ASAP', '1_WEEK', '1_MONTH']),
                max_budget=Decimal(str(random.randint(50, 500)))
            )
            
            # Create ProductRequest
            product_request = ProductRequest.objects.create(
                buyer_id=user,
                category='VEHICLE_SPARES',
                title=f'{make} {model} {year} - {part} Request {i+1}',
                description=f'Need {spare_spec.quantity} pieces of {part} for {make} {model} {year}.',
                product_specifications={
                    'vehicle_make': make,
                    'vehicle_model': model,
                    'vehicle_year': year,
                    'part_name': part,
                    'quantity': spare_spec.quantity
                },
                quantity=spare_spec.quantity,
                max_budget=spare_spec.max_budget,
                buyer_location={
                    'lat': -17.8292 + random.uniform(-0.1, 0.1),
                    'lng': 31.0522 + random.uniform(-0.1, 0.1),
                    'address': f'Test Address {i+1}, Harare, Zimbabwe'
                },
                urgency_timeline=random.choice(['ASAP', '1_WEEK', '1_MONTH']),
                terms_accepted=True,
                contact_consent=True,
                vehicle_spares=spare_spec
            )
            
            self.stdout.write(f'Created vehicle spares request: {product_request.title}')

    def create_tyres_rims_requests(self, user, category, count):
        """Create sample tyres and rims requests."""
        widths = [185, 195, 205, 215, 225, 235, 245, 255]
        profiles = ['35', '40', '45', '50', '55', '60', '65']
        diameters = ['15', '16', '17', '18', '19', '20']
        types = ['TYRES', 'RIMS', 'BOTH']
        brands = ['Michelin', 'Bridgestone', 'Continental', 'Pirelli', 'Goodyear']
        
        for i in range(count):
            width = random.choice(widths)
            profile = random.choice(profiles)
            diameter = random.choice(diameters)
            tyre_type = random.choice(types)
            brand = random.choice(brands)
            
            # Create VehicleTyresRims specification
            tyres_spec = VehicleTyresRims.objects.create(
                tyre_width=width,
                sidewall_profile=profile,
                wheel_rim_diameter=diameter,
                select_tyres_rims=tyre_type,
                quantity=random.randint(2, 8),
                urgency=random.choice(['ASAP', '1_WEEK', '1_MONTH']),
                vehicle_type='PASSENGER_CAR',
                preferred_brand=brand,
                balancing_required=random.choice(['YES', 'NO']),
                fitment_required=random.choice(['YES', 'NO'])
            )
            
            # Create ProductRequest
            product_request = ProductRequest.objects.create(
                buyer_id=user,
                category='TYRES_RIMS',
                title=f'{brand} {width}/{profile}R{diameter} - {tyre_type} Request {i+1}',
                description=f'Looking for {tyres_spec.quantity} pieces of {width}/{profile}R{diameter} {tyre_type.lower()}.',
                product_specifications={
                    'tyre_width': width,
                    'sidewall_profile': profile,
                    'wheel_rim_diameter': diameter,
                    'select_tyres_rims': tyre_type,
                    'quantity': tyres_spec.quantity,
                    'preferred_brand': brand
                },
                quantity=tyres_spec.quantity,
                max_budget=Decimal(str(random.randint(200, 1500))),
                buyer_location={
                    'lat': -17.8292 + random.uniform(-0.1, 0.1),
                    'lng': 31.0522 + random.uniform(-0.1, 0.1),
                    'address': f'Test Address {i+1}, Harare, Zimbabwe'
                },
                urgency_timeline=random.choice(['ASAP', '1_WEEK', '1_MONTH']),
                terms_accepted=True,
                contact_consent=True,
                vehicle_tyres_rims=tyres_spec
            )
            
            self.stdout.write(f'Created tyres/rims request: {product_request.title}')
