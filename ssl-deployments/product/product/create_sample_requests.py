#!/usr/bin/env python
"""
Script to create sample product requests for all categories.

This script creates 3 sample requests for each category:
- Consumer Electronics
- Vehicle Spares  
- Tyres & Rims
"""

import os
import sys
import django
from decimal import Decimal

# Setup Django environment
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'product_management_service.settings')
django.setup()

from django.contrib.auth.models import User
from product_requests.models import (
    ConsumerElectronics, VehicleSpares, VehicleTyresRims, ProductRequest
)


def create_test_users():
    """Create test users for the sample requests."""
    users = []
    
    user_data = [
        {'username': 'john_buyer', 'email': 'john@example.com', 'first_name': 'John', 'last_name': 'Smith'},
        {'username': 'sarah_tech', 'email': 'sarah@example.com', 'first_name': 'Sarah', 'last_name': 'Johnson'},
        {'username': 'mike_auto', 'email': 'mike@example.com', 'first_name': 'Mike', 'last_name': 'Wilson'},
        {'username': 'lisa_home', 'email': 'lisa@example.com', 'first_name': 'Lisa', 'last_name': 'Brown'},
        {'username': 'david_car', 'email': 'david@example.com', 'first_name': 'David', 'last_name': 'Davis'},
        {'username': 'emma_office', 'email': 'emma@example.com', 'first_name': 'Emma', 'last_name': 'Miller'},
    ]
    
    for user_info in user_data:
        user, created = User.objects.get_or_create(
            username=user_info['username'],
            defaults=user_info
        )
        if created:
            user.set_password('testpass123')
            user.save()
            print(f"✓ Created user: {user.username}")
        else:
            print(f"• User exists: {user.username}")
        users.append(user)
    
    return users


def create_consumer_electronics_requests(users):
    """Create 3 sample consumer electronics requests."""
    print("\n=== Creating Consumer Electronics Requests ===")
    
    electronics_requests = [
        {
            'user': users[0],
            'title': 'Looking for Samsung 65" 4K Smart TV',
            'description': 'Need a high-quality smart TV for my living room. Prefer QLED technology with good smart features.',
            'electronics_data': {
                'electronics_type': 'TELEVISION',
                'brand_preference': 'Samsung',
                'model_series': 'QLED Q80C',
                'quantity_needed': 1,
                'max_price': Decimal('25000.00'),
                'currency': 'ZAR',
                'urgency': 'WITHIN_WEEK',
                'condition_preference': 'NEW',
                'purpose_of_purchase': 'HOME_USE',
                'required_features': '65 inch, 4K resolution, QLED, Smart TV features, HDR support',
                'warranty_required': 'YES',
                'warranty_duration': '2 years',
                'energy_efficiency_required': 'YES',
                'additional_comments': 'Looking for wall mounting service as well'
            },
            'quantity': 1,
            'max_budget': Decimal('25000.00'),
            'urgency_timeline': '1_WEEK'
        },
        {
            'user': users[1],
            'title': 'MacBook Pro for Software Development',
            'description': 'Need a powerful laptop for software development work. Must have excellent performance and battery life.',
            'electronics_data': {
                'electronics_type': 'LAPTOP',
                'brand_preference': 'Apple',
                'model_series': 'MacBook Pro 16"',
                'quantity_needed': 1,
                'min_price': Decimal('40000.00'),
                'max_price': Decimal('60000.00'),
                'currency': 'ZAR',
                'urgency': 'ASAP',
                'condition_preference': 'NEW',
                'purpose_of_purchase': 'BUSINESS_USE',
                'required_features': '16GB RAM minimum, 512GB SSD, M2 or M3 chip, excellent battery life',
                'warranty_required': 'YES',
                'warranty_duration': '3 years',
                'additional_comments': 'Need AppleCare+ coverage. Can collect from Cape Town area.'
            },
            'quantity': 1,
            'max_budget': Decimal('60000.00'),
            'urgency_timeline': 'ASAP'
        },
        {
            'user': users[2],
            'title': 'Commercial Grade Washing Machine',
            'description': 'Looking for a heavy-duty washing machine for our guesthouse. Must handle large loads efficiently.',
            'electronics_data': {
                'electronics_type': 'WASHING_MACHINE',
                'brand_preference': 'LG, Bosch',
                'model_series': 'Front-loading',
                'quantity_needed': 2,
                'max_price': Decimal('15000.00'),
                'currency': 'ZAR',
                'urgency': 'WITHIN_MONTH',
                'condition_preference': 'NEW',
                'purpose_of_purchase': 'COMMERCIAL_USE',
                'required_features': 'Large capacity (8kg+), energy efficient, multiple wash programs, durable',
                'installation_required': 'YES',
                'warranty_required': 'YES',
                'warranty_duration': '5 years',
                'energy_efficiency_required': 'YES',
                'additional_comments': 'Need installation and removal of old units. Located in Johannesburg.'
            },
            'quantity': 2,
            'max_budget': Decimal('30000.00'),  # Total for 2 units
            'urgency_timeline': '1_MONTH'
        }
    ]
    
    created_requests = []
    
    for i, request_data in enumerate(electronics_requests, 1):
        # Create the ConsumerElectronics instance
        electronics = ConsumerElectronics.objects.create(**request_data['electronics_data'])
        
        # Create the ProductRequest
        product_request = ProductRequest.objects.create(
            buyer_id=request_data['user'],
            category='ELECTRONICS',
            title=request_data['title'],
            description=request_data['description'],
            product_specifications={},  # Will be filled by sync method
            quantity=request_data['quantity'],
            condition_preference=request_data['electronics_data']['condition_preference'],
            max_budget=request_data['max_budget'],
            currency=request_data['electronics_data']['currency'],
            buyer_location={
                'address': f'Sample Address {i}, South Africa',
                'lat': -26.2041 + (i * 0.1),
                'lng': 28.0473 + (i * 0.1)
            },
            max_travel_distance=50,
            urgency_timeline=request_data['urgency_timeline'],
            terms_accepted=True,
            contact_consent=True,
            consumer_electronics=electronics
        )
        
        # Sync the data
        product_request.sync_consumer_electronics_data()
        product_request.save()
        
        created_requests.append(product_request)
        print(f"✓ Created Electronics Request {i}: {product_request.title}")
    
    return created_requests


def create_vehicle_spares_requests(users):
    """Create 3 sample vehicle spares requests."""
    print("\n=== Creating Vehicle Spares Requests ===")
    
    spares_requests = [
        {
            'user': users[3],
            'title': 'Toyota Corolla 2018 Brake Pads',
            'description': 'Need replacement brake pads for my Toyota Corolla. Urgent as current ones are worn out.',
            'spares_data': {
                'vehicle_make': 'Toyota',
                'vehicle_model': 'Corolla',
                'vehicle_year': 2018,
                'vehicle_type': 'PASSENGER_CAR',
                'engine_size': '1.6L',
                'part_name': 'Front Brake Pads',
                'part_category': 'BRAKES',
                'quantity': 1,
                'condition_preference': 'NEW',
                'urgency': 'ASAP',
                'description': 'OEM or equivalent quality brake pads needed urgently',
                'preferred_brand': 'Bosch, Brembo, Toyota OEM',
                'installation_required': 'YES',
                'warranty_required': 'YES',
                'max_budget': Decimal('800.00'),
                'currency': 'ZAR'
            },
            'quantity': 1,
            'max_budget': Decimal('800.00'),
            'urgency_timeline': 'ASAP'
        },
        {
            'user': users[4],
            'title': 'Ford Ranger 2020 Alternator',
            'description': 'Alternator failure on my Ford Ranger bakkie. Need replacement part with installation.',
            'spares_data': {
                'vehicle_make': 'Ford',
                'vehicle_model': 'Ranger',
                'vehicle_year': 2020,
                'vehicle_type': 'TRUCK',
                'engine_size': '2.2L',
                'part_name': 'Alternator',
                'part_category': 'ELECTRICAL',
                'part_number': 'AB39-10300-BB',
                'quantity': 1,
                'condition_preference': 'REFURBISHED',
                'urgency': '24_HOURS',
                'description': 'Alternator completely failed, need replacement urgently',
                'compatible_models': 'Ford Ranger 2019-2022, Mazda BT-50',
                'preferred_brand': 'Ford OEM, Bosch',
                'avoid_brands': 'Cheap Chinese brands',
                'installation_required': 'YES',
                'warranty_required': 'YES',
                'max_budget': Decimal('3500.00'),
                'currency': 'ZAR'
            },
            'quantity': 1,
            'max_budget': Decimal('3500.00'),
            'urgency_timeline': '12_HOURS'
        },
        {
            'user': users[5],
            'title': 'BMW 320i E90 Suspension Components',
            'description': 'Need front suspension overhaul parts for BMW 320i. Multiple components required.',
            'spares_data': {
                'vehicle_make': 'BMW',
                'vehicle_model': '320i',
                'vehicle_year': 2010,
                'vehicle_type': 'PASSENGER_CAR',
                'engine_size': '2.0L',
                'vin_number': 'WBAVA31030NL12345',
                'part_name': 'Front Suspension Kit',
                'part_category': 'SUSPENSION',
                'quantity': 1,
                'condition_preference': 'NEW',
                'urgency': '1_WEEK',
                'description': 'Complete front suspension overhaul kit including shocks, springs, and bushings',
                'compatible_models': 'BMW 320i E90, E91, E92, E93 (2005-2013)',
                'preferred_brand': 'BMW OEM, Bilstein, Sachs',
                'installation_required': 'NO',
                'warranty_required': 'YES',
                'max_budget': Decimal('8000.00'),
                'currency': 'ZAR'
            },
            'quantity': 1,
            'max_budget': Decimal('8000.00'),
            'urgency_timeline': '1_WEEK'
        }
    ]
    
    created_requests = []
    
    for i, request_data in enumerate(spares_requests, 1):
        # Create the VehicleSpares instance
        spares = VehicleSpares.objects.create(**request_data['spares_data'])
        
        # Create the ProductRequest
        product_request = ProductRequest.objects.create(
            buyer_id=request_data['user'],
            category='VEHICLE_SPARES',
            title=request_data['title'],
            description=request_data['description'],
            product_specifications={},  # Will be filled by sync method
            quantity=request_data['quantity'],
            condition_preference=request_data['spares_data']['condition_preference'],
            max_budget=request_data['max_budget'],
            currency=request_data['spares_data']['currency'],
            buyer_location={
                'address': f'Auto Shop {i}, South Africa',
                'lat': -33.9249 + (i * 0.1),
                'lng': 18.4241 + (i * 0.1)
            },
            max_travel_distance=30,
            urgency_timeline=request_data['urgency_timeline'],
            terms_accepted=True,
            contact_consent=True,
            vehicle_spares=spares
        )
        
        # Sync the data
        product_request.sync_vehicle_spares_data()
        product_request.save()
        
        created_requests.append(product_request)
        print(f"✓ Created Vehicle Spares Request {i}: {product_request.title}")
    
    return created_requests


def create_tyres_rims_requests(users):
    """Create 3 sample tyres and rims requests."""
    print("\n=== Creating Tyres & Rims Requests ===")
    
    tyres_requests = [
        {
            'user': users[0],
            'title': '205/55R16 Tyres for Honda Civic',
            'description': 'Need new tyres for my Honda Civic. Looking for good quality with balanced performance and price.',
            'tyres_data': {
                'tyre_width': 205,
                'sidewall_profile': '55',
                'wheel_rim_diameter': '16',
                'select_tyres_rims': 'TYRES',
                'quantity': 4,
                'urgency': 'WITHIN_WEEK',
                'description': 'All-season tyres with good wet grip and durability',
                'vehicle_type': 'PASSENGER_CAR',
                'preferred_brand': 'Michelin, Bridgestone, Continental',
                'tyre_construction_type': 'RADIAL',
                'balancing_required': 'YES',
                'fitment_required': 'YES'
            },
            'quantity': 4,
            'max_budget': Decimal('4000.00'),
            'urgency_timeline': '1_WEEK'
        },
        {
            'user': users[1],
            'title': '18" Alloy Rims for Audi A4',
            'description': 'Looking for stylish alloy rims to upgrade my Audi A4. Prefer OEM or OEM-style design.',
            'tyres_data': {
                'tyre_width': 225,
                'sidewall_profile': '40',
                'wheel_rim_diameter': '18',
                'select_tyres_rims': 'RIMS',
                'quantity': 4,
                'urgency': 'FLEXIBLE',
                'description': 'OEM-style alloy rims, 5-spoke or similar design',
                'vehicle_type': 'PASSENGER_CAR',
                'pitch_circle_diameter': '5x112',
                'preferred_brand': 'Audi OEM, BBS, Rotiform',
                'fitment_required': 'YES'
            },
            'quantity': 4,
            'max_budget': Decimal('12000.00'),
            'urgency_timeline': '1_MONTH'
        },
        {
            'user': users[2],
            'title': '265/70R16 All-Terrain Tyres & Rims for Ford Ranger',
            'description': 'Complete wheel setup for my Ford Ranger. Need robust all-terrain tyres and strong rims for off-road use.',
            'tyres_data': {
                'tyre_width': 265,
                'sidewall_profile': '70',
                'wheel_rim_diameter': '16',
                'select_tyres_rims': 'BOTH',
                'quantity': 5,  # Including spare
                'urgency': 'WITHIN_WEEK',
                'description': 'All-terrain tyres with steel or alloy rims suitable for off-road driving',
                'vehicle_type': 'TRUCK',
                'pitch_circle_diameter': '6x139.7',
                'preferred_brand': 'BFGoodrich, General Tire, Cooper',
                'tyre_construction_type': 'RADIAL',
                'balancing_required': 'YES',
                'fitment_required': 'YES'
            },
            'quantity': 5,
            'max_budget': Decimal('15000.00'),
            'urgency_timeline': '1_WEEK'
        }
    ]
    
    created_requests = []
    
    for i, request_data in enumerate(tyres_requests, 1):
        # Create the VehicleTyresRims instance
        tyres_rims = VehicleTyresRims.objects.create(**request_data['tyres_data'])
        
        # Create the ProductRequest
        product_request = ProductRequest.objects.create(
            buyer_id=request_data['user'],
            category='TYRES_RIMS',
            title=request_data['title'],
            description=request_data['description'],
            product_specifications={},  # Will be filled by sync method
            quantity=request_data['quantity'],
            condition_preference='NEW',  # Tyres/rims are typically new
            max_budget=request_data['max_budget'],
            currency='ZAR',
            buyer_location={
                'address': f'Tyre Shop {i}, South Africa',
                'lat': -29.8587 + (i * 0.1),
                'lng': 31.0218 + (i * 0.1)
            },
            max_travel_distance=25,
            urgency_timeline=request_data['urgency_timeline'],
            terms_accepted=True,
            contact_consent=True,
            vehicle_tyres_rims=tyres_rims
        )
        
        # Sync the data
        product_request.sync_vehicle_tyres_rims_data()
        product_request.save()
        
        created_requests.append(product_request)
        print(f"✓ Created Tyres & Rims Request {i}: {product_request.title}")
    
    return created_requests


def main():
    """Main function to create all sample data."""
    print("🚀 Creating Sample Product Requests")
    print("=" * 50)
    
    # Create test users
    users = create_test_users()
    
    # Create sample requests for each category
    electronics_requests = create_consumer_electronics_requests(users)
    spares_requests = create_vehicle_spares_requests(users)
    tyres_requests = create_tyres_rims_requests(users)
    
    # Summary
    print("\n" + "=" * 50)
    print("📊 SUMMARY")
    print("=" * 50)
    print(f"✓ Created {len(users)} test users")
    print(f"✓ Created {len(electronics_requests)} Consumer Electronics requests")
    print(f"✓ Created {len(spares_requests)} Vehicle Spares requests")
    print(f"✓ Created {len(tyres_requests)} Tyres & Rims requests")
    print(f"✓ Total: {len(electronics_requests + spares_requests + tyres_requests)} product requests")
    
    print("\n🎉 Sample data creation completed successfully!")
    print("\n📡 API Endpoints Available:")
    print("- GET /product-requests/requests/ - List all requests")
    print("- POST /product-requests/requests/ - Create new request")
    print("- GET /product-requests/requests/categories/ - Get category counts")
    print("- GET /product-requests/requests/urgent_requests/ - Get urgent requests")
    print("- GET /product-requests/consumer-electronics/ - List electronics")
    print("- GET /product-requests/vehicle-spares/ - List vehicle spares")
    print("- GET /product-requests/tyres-rims/ - List tyres & rims")


if __name__ == '__main__':
    main()
