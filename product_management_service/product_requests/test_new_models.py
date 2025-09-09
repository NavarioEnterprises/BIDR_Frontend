"""
Comprehensive tests for the new ProductRequest model structure.
Tests based on the specifications table provided.
"""

# Set up Django environment if not already configured
import os
import django
from django.conf import settings

if not settings.configured:
    os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'product_management_service.settings')
    django.setup()

from django.test import TestCase
from django.contrib.auth.models import User
from django.utils import timezone
from django.core.exceptions import ValidationError
from decimal import Decimal
from datetime import timedelta
import uuid
import json

from .models import (
    ProductRequest, RequestImage, RequestSpecification, 
    RequestMessage, RequestWatchlist, RequestTemplate,
    ConsumerElectronics, VehicleSpares, VehicleTyresRims
)
from categories.models import Category


class NewProductRequestModelTest(TestCase):
    """Test the new ProductRequest model based on specifications."""
    
    def setUp(self):
        self.user = User.objects.create_user(
            username='testbuyer',
            email='buyer@example.com',
            password='testpass123'
        )
        
        self.category = Category.objects.create(
            name='Electronics',
            slug='electronics'
        )
    
    def test_product_request_creation_with_all_fields(self):
        """Test creating ProductRequest with all required fields according to specs."""
        
        # Sample buyer location data
        buyer_location = {
            "address": "123 Main St, Cape Town, South Africa",
            "lat": -33.9249,
            "lng": 18.4241
        }
        
        # Sample product specifications for electronics
        product_specs = {
            "electronics_type": "SMARTPHONE",
            "brand_preference": "Samsung",
            "model_series": "Galaxy S",
            "required_features": "128GB storage, dual camera"
        }
        
        # Sample product images
        product_images = [
            "https://example.com/image1.jpg",
            "https://example.com/image2.jpg"
        ]
        
        request = ProductRequest.objects.create(
            # buyer_id is set automatically via ForeignKey
            buyer_id=self.user,
            category='ELECTRONICS',
            title='Samsung Galaxy S smartphone needed',
            description='Looking for latest Samsung Galaxy S series smartphone',
            product_specifications=product_specs,
            quantity=2,
            condition_preference='NEW',
            max_budget=Decimal('15000.00'),
            currency='ZAR',
            buyer_location=buyer_location,
            max_travel_distance=100,
            urgency_timeline='1_WEEK',
            product_images=product_images,
            vin_photo_url='https://example.com/vin.jpg',
            terms_accepted=True,
            contact_consent=True,
            status='ACTIVE'
        )
        
        # Test all fields are set correctly
        self.assertEqual(request.buyer_id, self.user)
        self.assertEqual(request.category, 'ELECTRONICS')
        self.assertEqual(request.title, 'Samsung Galaxy S smartphone needed')
        self.assertEqual(request.description, 'Looking for latest Samsung Galaxy S series smartphone')
        self.assertEqual(request.product_specifications, product_specs)
        self.assertEqual(request.quantity, 2)
        self.assertEqual(request.condition_preference, 'NEW')
        self.assertEqual(request.max_budget, Decimal('15000.00'))
        self.assertEqual(request.currency, 'ZAR')
        self.assertEqual(request.buyer_location, buyer_location)
        self.assertEqual(request.max_travel_distance, 100)
        self.assertEqual(request.urgency_timeline, '1_WEEK')
        self.assertEqual(request.product_images, product_images)
        self.assertEqual(request.vin_photo_url, 'https://example.com/vin.jpg')
        self.assertTrue(request.terms_accepted)
        self.assertTrue(request.contact_consent)
        self.assertEqual(request.status, 'ACTIVE')
        
        # Test auto-generated fields
        self.assertIsInstance(request.request_id, uuid.UUID)
        self.assertIsNotNone(request.expiry_date)
        self.assertEqual(request.view_count, 0)
        self.assertIsNotNone(request.created_at)
        self.assertIsNotNone(request.updated_at)
    
    def test_product_request_default_values(self):
        """Test default values according to specifications."""
        request = ProductRequest.objects.create(
            buyer_id=self.user,
            category='ELECTRONICS',
            title='Test product request',
            product_specifications={},
            quantity=1,
            buyer_location={"address": "Test address"},
            urgency_timeline='ASAP',
            terms_accepted=True,
            contact_consent=True
        )
        
        # Test defaults from specifications
        self.assertEqual(request.condition_preference, 'ANY')  # DEFAULT 'ANY'
        self.assertEqual(request.currency, 'ZAR')  # DEFAULT 'ZAR'
        self.assertEqual(request.max_travel_distance, 50)  # DEFAULT 50
        self.assertEqual(request.status, 'ACTIVE')  # DEFAULT 'ACTIVE'
        self.assertEqual(request.view_count, 0)  # DEFAULT 0
        
        # Fields that can be null/blank
        self.assertIsNone(request.description)  # NULL allowed
        self.assertIsNone(request.max_budget)  # NULL allowed
        self.assertIsNone(request.product_images)  # NULL allowed
        self.assertIsNone(request.vin_photo_url)  # NULL allowed
        self.assertIsNotNone(request.expiry_date)  # Auto-calculated based on urgency
    
    def test_product_request_str_representation(self):
        """Test string representation."""
        request = ProductRequest.objects.create(
            buyer_id=self.user,
            category='ELECTRONICS',
            title='Test Electronics Request',
            product_specifications={},
            quantity=1,
            buyer_location={"address": "Test"},
            urgency_timeline='ASAP',
            terms_accepted=True,
            contact_consent=True
        )
        
        expected_str = f"{request.request_id} - Test Electronics Request"
        self.assertEqual(str(request), expected_str)
    
    def test_vehicle_spares_category(self):
        """Test ProductRequest with VEHICLE_SPARES category."""
        vehicle_specs = {
            "vehicle_make": "Toyota",
            "vehicle_model": "Corolla",
            "vehicle_year": 2018,
            "part_name": "Brake Pads",
            "part_category": "BRAKES"
        }
        
        request = ProductRequest.objects.create(
            buyer_id=self.user,
            category='VEHICLE_SPARES',
            title='Toyota Corolla brake pads needed',
            product_specifications=vehicle_specs,
            quantity=1,
            buyer_location={"address": "Johannesburg"},
            urgency_timeline='ASAP',
            vin_photo_url='https://example.com/vin_photo.jpg',
            terms_accepted=True,
            contact_consent=True
        )
        
        self.assertEqual(request.category, 'VEHICLE_SPARES')
        self.assertEqual(request.product_specifications['vehicle_make'], 'Toyota')
        self.assertEqual(request.vin_photo_url, 'https://example.com/vin_photo.jpg')
    
    def test_tyres_rims_category(self):
        """Test ProductRequest with TYRES_RIMS category."""
        tyre_specs = {
            "tyre_width": 205,
            "sidewall_profile": "55",
            "wheel_rim_diameter": "16",
            "select_tyres_rims": "BOTH"
        }
        
        request = ProductRequest.objects.create(
            buyer_id=self.user,
            category='TYRES_RIMS',
            title='205/55R16 tyres and rims',
            product_specifications=tyre_specs,
            quantity=4,
            buyer_location={"address": "Durban"},
            urgency_timeline='1_WEEK',
            terms_accepted=True,
            contact_consent=True
        )
        
        self.assertEqual(request.category, 'TYRES_RIMS')
        self.assertEqual(request.product_specifications['tyre_width'], 205)
        self.assertEqual(request.quantity, 4)
    
    def test_expiry_date_calculation(self):
        """Test automatic expiry date calculation based on urgency."""
        # Test ASAP urgency
        asap_request = ProductRequest.objects.create(
            buyer_id=self.user,
            category='ELECTRONICS',
            title='ASAP Request',
            product_specifications={},
            quantity=1,
            buyer_location={"address": "Test"},
            urgency_timeline='ASAP',
            terms_accepted=True,
            contact_consent=True
        )
        
        # Should expire within 1 day
        expected_expiry = timezone.now() + timedelta(days=1)
        self.assertAlmostEqual(
            asap_request.expiry_date.date(),
            expected_expiry.date()
        )
        
        # Test 1_WEEK urgency
        week_request = ProductRequest.objects.create(
            buyer_id=self.user,
            category='ELECTRONICS',
            title='Week Request',
            product_specifications={},
            quantity=1,
            buyer_location={"address": "Test"},
            urgency_timeline='1_WEEK',
            terms_accepted=True,
            contact_consent=True
        )
        
        # Should expire within 7 days
        expected_expiry = timezone.now() + timedelta(days=7)
        self.assertAlmostEqual(
            week_request.expiry_date.date(),
            expected_expiry.date()
        )
    
    def test_is_expired_property(self):
        """Test is_expired property."""
        # Create request with past expiry date
        expired_request = ProductRequest.objects.create(
            buyer_id=self.user,
            category='ELECTRONICS',
            title='Expired Request',
            product_specifications={},
            quantity=1,
            buyer_location={"address": "Test"},
            urgency_timeline='ASAP',
            terms_accepted=True,
            contact_consent=True,
            expiry_date=timezone.now() - timedelta(days=1)
        )
        
        self.assertTrue(expired_request.is_expired)
        
        # Create request with future expiry date
        active_request = ProductRequest.objects.create(
            buyer_id=self.user,
            category='ELECTRONICS',
            title='Active Request',
            product_specifications={},
            quantity=1,
            buyer_location={"address": "Test"},
            urgency_timeline='1_WEEK',
            terms_accepted=True,
            contact_consent=True
        )
        
        self.assertFalse(active_request.is_expired)
    
    def test_is_urgent_property(self):
        """Test is_urgent property based on urgency timeline."""
        # ASAP should be urgent
        asap_request = ProductRequest.objects.create(
            buyer_id=self.user,
            category='ELECTRONICS',
            title='ASAP Request',
            product_specifications={},
            quantity=1,
            buyer_location={"address": "Test"},
            urgency_timeline='ASAP',
            terms_accepted=True,
            contact_consent=True
        )
        
        self.assertTrue(asap_request.is_urgent)
        
        # 12_HOURS should be urgent
        hours_request = ProductRequest.objects.create(
            buyer_id=self.user,
            category='ELECTRONICS',
            title='12 Hours Request',
            product_specifications={},
            quantity=1,
            buyer_location={"address": "Test"},
            urgency_timeline='12_HOURS',
            terms_accepted=True,
            contact_consent=True
        )
        
        self.assertTrue(hours_request.is_urgent)
        
        # 1_WEEK should not be urgent
        week_request = ProductRequest.objects.create(
            buyer_id=self.user,
            category='ELECTRONICS',
            title='Week Request',
            product_specifications={},
            quantity=1,
            buyer_location={"address": "Test"},
            urgency_timeline='1_WEEK',
            terms_accepted=True,
            contact_consent=True
        )
        
        self.assertFalse(week_request.is_urgent)
    
    def test_can_receive_quotes_method(self):
        """Test can_receive_quotes method."""
        # Active and not expired should be able to receive quotes
        active_request = ProductRequest.objects.create(
            buyer_id=self.user,
            category='ELECTRONICS',
            title='Active Request',
            product_specifications={},
            quantity=1,
            buyer_location={"address": "Test"},
            urgency_timeline='1_WEEK',
            status='ACTIVE',
            terms_accepted=True,
            contact_consent=True
        )
        
        self.assertTrue(active_request.can_receive_quotes())
        
        # Closed request should not be able to receive quotes
        closed_request = ProductRequest.objects.create(
            buyer_id=self.user,
            category='ELECTRONICS',
            title='Closed Request',
            product_specifications={},
            quantity=1,
            buyer_location={"address": "Test"},
            urgency_timeline='1_WEEK',
            status='CLOSED',
            terms_accepted=True,
            contact_consent=True
        )
        
        self.assertFalse(closed_request.can_receive_quotes())
    
    def test_mark_as_viewed_method(self):
        """Test mark_as_viewed method increments view count."""
        request = ProductRequest.objects.create(
            buyer_id=self.user,
            category='ELECTRONICS',
            title='Test Request',
            product_specifications={},
            quantity=1,
            buyer_location={"address": "Test"},
            urgency_timeline='1_WEEK',
            terms_accepted=True,
            contact_consent=True
        )
        
        initial_count = request.view_count
        request.mark_as_viewed()
        request.refresh_from_db()
        
        self.assertEqual(request.view_count, initial_count + 1)
    
    def test_close_request_method(self):
        """Test close_request method."""
        request = ProductRequest.objects.create(
            buyer_id=self.user,
            category='ELECTRONICS',
            title='Test Request',
            product_specifications={},
            quantity=1,
            buyer_location={"address": "Test"},
            urgency_timeline='1_WEEK',
            status='ACTIVE',
            terms_accepted=True,
            contact_consent=True
        )
        
        request.close_request()
        request.refresh_from_db()
        
        self.assertEqual(request.status, 'CLOSED')
    
    def test_mark_as_expired_method(self):
        """Test mark_as_expired method."""
        request = ProductRequest.objects.create(
            buyer_id=self.user,
            category='ELECTRONICS',
            title='Test Request',
            product_specifications={},
            quantity=1,
            buyer_location={"address": "Test"},
            urgency_timeline='1_WEEK',
            status='ACTIVE',
            terms_accepted=True,
            contact_consent=True
        )
        
        request.mark_as_expired()
        request.refresh_from_db()
        
        self.assertEqual(request.status, 'EXPIRED')
    
    def test_quantity_validation(self):
        """Test quantity must be greater than 0."""
        with self.assertRaises(ValidationError):
            request = ProductRequest(
                buyer_id=self.user,
                category='ELECTRONICS',
                title='Invalid Quantity Request',
                product_specifications={},
                quantity=0,  # Should fail validation
                buyer_location={"address": "Test"},
                urgency_timeline='1_WEEK',
                terms_accepted=True,
                contact_consent=True
            )
            request.full_clean()  # This will trigger validation
    
    def test_foreign_key_relationships(self):
        """Test foreign key relationships with specialized models."""
        # Create a VehicleSpares instance
        vehicle_spare = VehicleSpares.objects.create(
            vehicle_make='BMW',
            vehicle_model='X3',
            vehicle_year=2020,
            vehicle_type='SUV',
            part_name='Air Filter',
            part_category='ENGINE',
            quantity=1,
            urgency='ASAP'
        )
        
        # Create ProductRequest with vehicle_spares relationship
        request = ProductRequest.objects.create(
            buyer_id=self.user,
            category='VEHICLE_SPARES',
            title='BMW X3 Air Filter',
            product_specifications={'vehicle_make': 'BMW'},
            quantity=1,
            buyer_location={"address": "Test"},
            urgency_timeline='ASAP',
            vehicle_spares=vehicle_spare,
            terms_accepted=True,
            contact_consent=True
        )
        
        self.assertEqual(request.vehicle_spares, vehicle_spare)
        self.assertEqual(request.vehicle_spares.vehicle_make, 'BMW')
    
    def test_json_fields_validation(self):
        """Test JSON fields accept valid JSON data."""
        buyer_location = {
            "address": "123 Test St, Test City",
            "lat": -26.2041,
            "lng": 28.0473,
            "postal_code": "2000"
        }
        
        product_specs = {
            "brand": "Apple",
            "model": "iPhone 14",
            "storage": "256GB",
            "color": "Blue"
        }
        
        product_images = [
            "https://example.com/image1.jpg",
            "https://example.com/image2.jpg"
        ]
        
        request = ProductRequest.objects.create(
            buyer_id=self.user,
            category='ELECTRONICS',
            title='iPhone Request',
            product_specifications=product_specs,
            quantity=1,
            buyer_location=buyer_location,
            product_images=product_images,
            urgency_timeline='1_WEEK',
            terms_accepted=True,
            contact_consent=True
        )
        
        # Test data is stored and retrieved correctly
        self.assertEqual(request.buyer_location, buyer_location)
        self.assertEqual(request.product_specifications, product_specs)
        self.assertEqual(request.product_images, product_images)
        self.assertEqual(request.buyer_location['lat'], -26.2041)
        self.assertEqual(request.product_specifications['brand'], 'Apple')


class ConsumerElectronicsModelTest(TestCase):
    """Test ConsumerElectronics model."""
    
    def test_consumer_electronics_creation(self):
        """Test creating ConsumerElectronics instance."""
        electronics = ConsumerElectronics.objects.create(
            electronics_type='SMARTPHONE',
            brand_preference='Samsung',
            model_series='Galaxy S23',
            quantity_needed=1,
            max_price=Decimal('15000.00'),
            currency='ZAR',
            urgency='ASAP',
            condition_preference='NEW',
            purpose_of_purchase='PERSONAL_USE'
        )
        
        self.assertEqual(electronics.electronics_type, 'SMARTPHONE')
        self.assertEqual(electronics.brand_preference, 'Samsung')
        self.assertEqual(electronics.quantity_needed, 1)
        self.assertEqual(electronics.max_price, Decimal('15000.00'))
        self.assertTrue(electronics.is_urgent)
    
    def test_electronics_str_representation(self):
        """Test string representation of ConsumerElectronics."""
        electronics = ConsumerElectronics.objects.create(
            electronics_type='LAPTOP',
            brand_preference='Apple',
            model_series='MacBook Pro',
            quantity_needed=1,
            urgency='ASAP'
        )
        
        expected_str = "Laptop - Apple MacBook Pro"
        self.assertEqual(str(electronics), expected_str)


class VehicleSparesModelTest(TestCase):
    """Test VehicleSpares model."""
    
    def test_vehicle_spares_creation(self):
        """Test creating VehicleSpares instance."""
        spares = VehicleSpares.objects.create(
            vehicle_make='Toyota',
            vehicle_model='Hilux',
            vehicle_year=2020,
            vehicle_type='TRUCK',
            part_name='Brake Disc',
            part_category='BRAKES',
            quantity=2,
            urgency='24_HOURS',
            condition_preference='NEW'
        )
        
        self.assertEqual(spares.vehicle_make, 'Toyota')
        self.assertEqual(spares.vehicle_model, 'Hilux')
        self.assertEqual(spares.part_name, 'Brake Disc')
        self.assertTrue(spares.is_urgent)  # 24_HOURS should be urgent
    
    def test_vehicle_spares_str_representation(self):
        """Test string representation of VehicleSpares."""
        spares = VehicleSpares.objects.create(
            vehicle_make='Ford',
            vehicle_model='Focus',
            vehicle_year=2018,
            vehicle_type='PASSENGER_CAR',
            part_name='Oil Filter',
            part_category='ENGINE',
            quantity=1,
            urgency='1_WEEK'
        )
        
        expected_str = "Ford Focus (2018) - Oil Filter"
        self.assertEqual(str(spares), expected_str)


class VehicleTyresRimsModelTest(TestCase):
    """Test VehicleTyresRims model."""
    
    def test_tyres_rims_creation(self):
        """Test creating VehicleTyresRims instance."""
        tyres_rims = VehicleTyresRims.objects.create(
            tyre_width=205,
            sidewall_profile='55',
            wheel_rim_diameter='16',
            select_tyres_rims='BOTH',
            quantity=4,
            urgency='1_WEEK',
            vehicle_type='PASSENGER_CAR'
        )
        
        self.assertEqual(tyres_rims.tyre_width, 205)
        self.assertEqual(tyres_rims.sidewall_profile, '55')
        self.assertEqual(tyres_rims.wheel_rim_diameter, '16')
        self.assertEqual(tyres_rims.quantity, 4)
        self.assertFalse(tyres_rims.is_urgent)  # 1_WEEK should not be urgent
    
    def test_tyres_rims_str_representation(self):
        """Test string representation of VehicleTyresRims."""
        tyres_rims = VehicleTyresRims.objects.create(
            tyre_width=225,
            sidewall_profile='45',
            wheel_rim_diameter='18',
            select_tyres_rims='TYRES',
            quantity=4,
            urgency='ASAP',
            vehicle_type='SUV'
        )
        
        expected_str = "225/45R18 - TYRES"
        self.assertEqual(str(tyres_rims), expected_str)
    
    def test_tyre_size_display_property(self):
        """Test tyre_size_display property."""
        tyres_rims = VehicleTyresRims.objects.create(
            tyre_width=195,
            sidewall_profile='65',
            wheel_rim_diameter='15',
            select_tyres_rims='BOTH',
            quantity=4,
            urgency='1_MONTH',
            vehicle_type='PASSENGER_CAR'
        )
        
        expected_size = "195/65R15"
        self.assertEqual(tyres_rims.tyre_size_display, expected_size)


class ModelValidationTest(TestCase):
    """Test model field validations."""
    
    def setUp(self):
        self.user = User.objects.create_user(
            username='testuser',
            email='test@example.com',
            password='testpass123'
        )
    
    def test_required_fields_validation(self):
        """Test that required fields are properly validated."""
        # Missing buyer_id should fail
        with self.assertRaises(Exception):
            ProductRequest.objects.create(
                category='ELECTRONICS',
                title='Test',
                product_specifications={},
                quantity=1,
                buyer_location={"address": "Test"},
                urgency_timeline='1_WEEK',
                terms_accepted=True,
                contact_consent=True
                # Missing buyer_id
            )
    
    def test_choice_field_validation(self):
        """Test choice fields only accept valid choices."""
        # Invalid category should fail
        with self.assertRaises(ValidationError):
            request = ProductRequest(
                buyer_id=self.user,
                category='INVALID_CATEGORY',  # Not in CATEGORY_CHOICES
                title='Test',
                product_specifications={},
                quantity=1,
                buyer_location={"address": "Test"},
                urgency_timeline='1_WEEK',
                terms_accepted=True,
                contact_consent=True
            )
            request.full_clean()
    
    def test_boolean_field_requirements(self):
        """Test boolean fields are required."""
        # Missing terms_accepted should fail
        with self.assertRaises(Exception):
            ProductRequest.objects.create(
                buyer_id=self.user,
                category='ELECTRONICS',
                title='Test',
                product_specifications={},
                quantity=1,
                buyer_location={"address": "Test"},
                urgency_timeline='1_WEEK',
                contact_consent=True
                # Missing terms_accepted
            )
