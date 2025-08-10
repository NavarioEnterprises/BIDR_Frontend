"""
Product Request models for the BIDR Inventory Service.

This module handles customer requests for products, including RFQs (Request for Quote).
"""
import uuid

from django.db import models
from django.contrib.auth.models import User
from django.core.validators import MinValueValidator, MaxValueValidator
from django.utils import timezone
from decimal import Decimal
from core.models import BaseModel, StatusChoices, PriorityChoices
from core.utils import calculate_expiry_date, generate_reference_number
from categories.models import Category, CategorySpecification


class ConsumerElectronics(models.Model):
    """
    Specific model for Consumer Electronics specifications.
    Based on the form fields for electronics products.
    """
    
    ELECTRONICS_TYPE_CHOICES = [
        ('WASHING_MACHINE', 'Washing Machine'),
        ('REFRIGERATOR', 'Refrigerator'),
        ('TELEVISION', 'Television'),
        ('MICROWAVE', 'Microwave'),
        ('AIR_CONDITIONER', 'Air Conditioner'),
        ('DISHWASHER', 'Dishwasher'),
        ('DRYER', 'Dryer'),
        ('OVEN', 'Oven'),
        ('VACUUM_CLEANER', 'Vacuum Cleaner'),
        ('BLENDER', 'Blender'),
        ('COFFEE_MAKER', 'Coffee Maker'),
        ('TOASTER', 'Toaster'),
        ('IRON', 'Iron'),
        ('HAIR_DRYER', 'Hair Dryer'),
        ('LAPTOP', 'Laptop'),
        ('DESKTOP', 'Desktop Computer'),
        ('SMARTPHONE', 'Smartphone'),
        ('TABLET', 'Tablet'),
        ('PRINTER', 'Printer'),
        ('CAMERA', 'Camera'),
        ('SPEAKER', 'Speaker'),
        ('HEADPHONES', 'Headphones'),
        ('GAMING_CONSOLE', 'Gaming Console'),
        ('OTHER', 'Other'),
    ]
    
    CONDITION_CHOICES = [
        ('NEW', 'New'),
        ('REFURBISHED', 'New / Refurbished'),
        ('USED', 'Used'),
        ('ANY', 'Any Condition'),
    ]
    
    URGENCY_CHOICES = [
        ('ASAP', 'ASAP'),
        ('WITHIN_WEEK', 'Within a week'),
        ('WITHIN_MONTH', 'Within a month'),
        ('FLEXIBLE', 'Flexible'),
    ]
    
    PURPOSE_CHOICES = [
        ('HOME_USE', 'Home Use'),
        ('OFFICE_USE', 'Office Use'),
        ('COMMERCIAL_USE', 'Commercial Use'),
        ('PERSONAL_USE', 'Personal Use'),
        ('BUSINESS_USE', 'Business Use'),
        ('EDUCATIONAL', 'Educational'),
        ('OTHER', 'Other'),
    ]
    
    BOOLEAN_CHOICES = [
        ('YES', 'Yes'),
        ('NO', 'No'),
    ]
    
    # Primary identification
    id = models.AutoField(primary_key=True)
    
    # Product details
    electronics_type = models.CharField(
        max_length=30,
        choices=ELECTRONICS_TYPE_CHOICES,
        help_text="Type of electronic product needed"
    )
    brand_preference = models.CharField(
        max_length=100,
        blank=True,
        help_text="Preferred brand (e.g., Samsung, LG, Apple)"
    )
    model_series = models.CharField(
        max_length=100,
        blank=True,
        help_text="Specific model or series if known"
    )
    
    # Quantity and timeline
    quantity_needed = models.IntegerField(
        validators=[MinValueValidator(1), MaxValueValidator(100)],
        help_text="How many units needed?"
    )
    
    # Budget information
    min_price = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        null=True,
        blank=True,
        validators=[MinValueValidator(Decimal('0.01'))],
        help_text="Minimum budget"
    )
    max_price = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        null=True,
        blank=True,
        validators=[MinValueValidator(Decimal('0.01'))],
        help_text="Maximum budget"
    )
    currency = models.CharField(
        max_length=3,
        default='ZAR',
        help_text="Currency code"
    )
    
    # Timeline and services
    urgency = models.CharField(
        max_length=20,
        choices=URGENCY_CHOICES,
        help_text="How soon do you need the product?"
    )
    installation_required = models.CharField(
        max_length=3,
        choices=BOOLEAN_CHOICES,
        default='NO',
        help_text="Do you need installation services?"
    )
    
    # Features and specifications
    required_features = models.TextField(
        blank=True,
        help_text="Required features or specifications (e.g., capacity, energy rating, etc.)"
    )
    condition_preference = models.CharField(
        max_length=20,
        choices=CONDITION_CHOICES,
        default='NEW',
        help_text="Preferred condition of the product"
    )
    purpose_of_purchase = models.CharField(
        max_length=20,
        choices=PURPOSE_CHOICES,
        help_text="What will this product be used for?"
    )
    
    # Additional information
    additional_comments = models.TextField(
        blank=True,
        help_text="Any additional requirements or comments"
    )
    
    # Product images and documents
    product_images = models.JSONField(
        null=True,
        blank=True,
        help_text="Array of uploaded product image URLs or documents"
    )
    
    # Location for delivery/pickup
    delivery_location = models.JSONField(
        null=True,
        blank=True,
        help_text="Delivery or pickup location information"
    )
    
    # Warranty and support preferences
    warranty_required = models.CharField(
        max_length=3,
        choices=BOOLEAN_CHOICES,
        default='YES',
        help_text="Do you require warranty coverage?"
    )
    warranty_duration = models.CharField(
        max_length=50,
        blank=True,
        help_text="Preferred warranty duration (e.g., 1 year, 2 years)"
    )
    
    # Energy efficiency preferences (for applicable electronics)
    energy_efficiency_required = models.CharField(
        max_length=3,
        choices=BOOLEAN_CHOICES,
        default='NO',
        help_text="Is energy efficiency important? (A+ rating or higher)"
    )
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'consumer_electronics'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['electronics_type']),
            models.Index(fields=['brand_preference']),
            models.Index(fields=['urgency']),
            models.Index(fields=['condition_preference']),
            models.Index(fields=['purpose_of_purchase']),
            models.Index(fields=['created_at']),
        ]
    
    def __str__(self):
        brand_info = f" - {self.brand_preference}" if self.brand_preference else ""
        model_info = f" {self.model_series}" if self.model_series else ""
        return f"{self.get_electronics_type_display()}{brand_info}{model_info}"
    
    @property
    def is_urgent(self):
        """Check if the request is urgent."""
        return self.urgency in ['ASAP']
    
    @property
    def budget_range_display(self):
        """Return formatted budget range."""
        if self.min_price and self.max_price:
            return f"{self.currency} {self.min_price} - {self.currency} {self.max_price}"
        elif self.max_price:
            return f"Up to {self.currency} {self.max_price}"
        elif self.min_price:
            return f"From {self.currency} {self.min_price}"
        return "Budget not specified"
    
    def get_preferred_brands_list(self):
        """Return preferred brands as a list."""
        if not self.brand_preference:
            return []
        return [brand.strip() for brand in self.brand_preference.split(',') if brand.strip()]
    
    def requires_professional_service(self):
        """Check if any professional services are required."""
        return any([
            self.installation_required == 'YES',
            self.warranty_required == 'YES'
        ])
    
    @property
    def is_energy_conscious(self):
        """Check if energy efficiency is a priority."""
        return self.energy_efficiency_required == 'YES'
    
    @property
    def full_product_description(self):
        """Get comprehensive product description."""
        desc = self.get_electronics_type_display()
        if self.brand_preference:
            desc += f" - {self.brand_preference}"
        if self.model_series:
            desc += f" {self.model_series}"
        if self.required_features:
            features_preview = self.required_features[:50] + "..." if len(self.required_features) > 50 else self.required_features
            desc += f" ({features_preview})"
        return desc


class VehicleSpares(models.Model):
    """
    Specific model for Vehicle Spares specifications.
    Based on the form fields for vehicle parts and spare parts.
    """
    
    VEHICLE_TYPE_CHOICES = [
        ('PASSENGER_CAR', 'Passenger Car'),
        ('SUV', 'SUV'),
        ('TRUCK', 'Truck'),
        ('MOTORCYCLE', 'Motorcycle'),
        ('TRAILER', 'Trailer'),
        ('VAN', 'Van'),
        ('BUS', 'Bus'),
    ]
    
    PART_CONDITION_CHOICES = [
        ('NEW', 'New'),
        ('USED', 'Used'),
        ('REFURBISHED', 'Refurbished'),
        ('REMANUFACTURED', 'Remanufactured'),
    ]
    
    URGENCY_CHOICES = [
        ('ASAP', 'ASAP'),
        ('12_HOURS', '12 Hours'),
        ('24_HOURS', '24 Hours'),
        ('1_WEEK', '1 Week'),
        ('1_MONTH', '1 Month'),
    ]
    
    BOOLEAN_CHOICES = [
        ('YES', 'Yes'),
        ('NO', 'No'),
    ]
    
    PART_CATEGORY_CHOICES = [
        ('ENGINE', 'Engine Parts'),
        ('TRANSMISSION', 'Transmission'),
        ('BRAKES', 'Brake System'),
        ('SUSPENSION', 'Suspension'),
        ('ELECTRICAL', 'Electrical'),
        ('BODY', 'Body Parts'),
        ('INTERIOR', 'Interior'),
        ('EXHAUST', 'Exhaust System'),
        ('COOLING', 'Cooling System'),
        ('FUEL', 'Fuel System'),
        ('OTHER', 'Other'),
    ]
    
    # Primary identification
    id = models.AutoField(primary_key=True)
    
    # Vehicle Information
    vehicle_make = models.CharField(
        max_length=50,
        help_text="Vehicle manufacturer (e.g., Toyota, Ford)"
    )
    vehicle_model = models.CharField(
        max_length=50,
        help_text="Vehicle model (e.g., Corolla, Focus)"
    )
    vehicle_year = models.IntegerField(
        validators=[MinValueValidator(1980), MaxValueValidator(2030)],
        help_text="Manufacturing year of the vehicle"
    )
    vehicle_type = models.CharField(
        max_length=20,
        choices=VEHICLE_TYPE_CHOICES,
        help_text="Type of vehicle"
    )
    
    # Engine and VIN information
    engine_size = models.CharField(
        max_length=20,
        blank=True,
        help_text="Engine size/displacement (e.g., 1.6L, 2000cc)"
    )
    vin_number = models.CharField(
        max_length=17,
        blank=True,
        help_text="Vehicle Identification Number (optional)"
    )
    
    # Part specifications
    part_name = models.CharField(
        max_length=100,
        help_text="Name or description of the required part"
    )
    part_category = models.CharField(
        max_length=20,
        choices=PART_CATEGORY_CHOICES,
        help_text="Category of the spare part"
    )
    part_number = models.CharField(
        max_length=50,
        blank=True,
        help_text="Manufacturer part number (if known)"
    )
    
    # Request details
    quantity = models.IntegerField(
        validators=[MinValueValidator(1), MaxValueValidator(100)],
        help_text="How many pieces needed?"
    )
    condition_preference = models.CharField(
        max_length=20,
        choices=PART_CONDITION_CHOICES,
        default='NEW',
        help_text="Preferred condition of the part"
    )
    urgency = models.CharField(
        max_length=20,
        choices=URGENCY_CHOICES,
        help_text="How soon do you need this part?"
    )
    
    # Additional details
    description = models.TextField(
        blank=True,
        help_text="Additional description or specific requirements"
    )
    compatible_models = models.TextField(
        blank=True,
        help_text="Other vehicle models this part might fit"
    )
    
    # Brand preferences
    preferred_brand = models.CharField(
        max_length=100,
        blank=True,
        help_text="Preferred brand(s) - can list multiple"
    )
    avoid_brands = models.CharField(
        max_length=100,
        blank=True,
        help_text="Brands to avoid (if any)"
    )
    
    # Installation and warranty
    installation_required = models.CharField(
        max_length=3,
        choices=BOOLEAN_CHOICES,
        default='NO',
        help_text="Do you need installation service?"
    )
    warranty_required = models.CharField(
        max_length=3,
        choices=BOOLEAN_CHOICES,
        default='NO',
        help_text="Do you require warranty on the part?"
    )
    
    # Budget information
    max_budget = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        null=True,
        blank=True,
        validators=[MinValueValidator(Decimal('0.01'))],
        help_text="Maximum budget for this part"
    )
    currency = models.CharField(
        max_length=3,
        default='ZAR',
        help_text="Currency code"
    )
    
    # Product images
    product_images = models.JSONField(
        null=True,
        blank=True,
        help_text="Array of uploaded product image URLs"
    )
    vin_photo = models.URLField(
        blank=True,
        help_text="VIN plate photo URL"
    )
    
    # Location for pickup/delivery
    location_info = models.JSONField(
        null=True,
        blank=True,
        help_text="Location information for pickup or delivery"
    )
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'vehicle_spares'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['vehicle_make', 'vehicle_model']),
            models.Index(fields=['part_category']),
            models.Index(fields=['urgency']),
            models.Index(fields=['condition_preference']),
            models.Index(fields=['created_at']),
        ]
    
    def __str__(self):
        return f"{self.vehicle_make} {self.vehicle_model} ({self.vehicle_year}) - {self.part_name}"
    
    @property
    def vehicle_display(self):
        """Return formatted vehicle information."""
        return f"{self.vehicle_make} {self.vehicle_model} {self.vehicle_year}"
    
    @property
    def is_urgent(self):
        """Check if the request is urgent."""
        return self.urgency in ['ASAP', '12_HOURS', '24_HOURS']
    
    def get_preferred_brands_list(self):
        """Return preferred brands as a list."""
        if not self.preferred_brand:
            return []
        return [brand.strip() for brand in self.preferred_brand.split(',') if brand.strip()]
    
    def get_avoid_brands_list(self):
        """Return brands to avoid as a list."""
        if not self.avoid_brands:
            return []
        return [brand.strip() for brand in self.avoid_brands.split(',') if brand.strip()]
    
    def requires_professional_service(self):
        """Check if any professional services are required."""
        return any([
            self.installation_required == 'YES',
            self.warranty_required == 'YES'
        ])
    
    @property
    def full_part_description(self):
        """Get full part description including part number if available."""
        desc = self.part_name
        if self.part_number:
            desc += f" (Part #: {self.part_number})"
        return desc


class VehicleTyresRims(models.Model):
    """
    Specific model for Vehicle Tyres and Rims specifications.
    Based on the form fields shown in the user interface.
    """
    
    SIDEWALL_PROFILE_CHOICES = [
        ('35', '35'),
        ('40', '40'),
        ('45', '45'),
        ('50', '50'),
        ('55', '55'),
        ('60', '60'),
        ('65', '65'),
        ('70', '70'),
    ]
    
    RIM_DIAMETER_CHOICES = [
        ('13', '13"'),
        ('14', '14"'),
        ('15', '15"'),
        ('16', '16"'),
        ('17', '17"'),
        ('18', '18"'),
        ('19', '19"'),
        ('20', '20"'),
        ('21', '21"'),
        ('22', '22"'),
    ]
    
    TYRE_RIM_TYPE_CHOICES = [
        ('TYRES', 'Tyres'),
        ('RIMS', 'Rims'),
        ('BOTH', 'Both Tyres and Rims'),
    ]
    
    URGENCY_CHOICES = [
        ('ASAP', 'ASAP'),
        ('12_HOURS', '12 Hours'),
        ('24_HOURS', '24 Hours'),
        ('1_WEEK', '1 Week'),
        ('1_MONTH', '1 Month'),
    ]
    
    VEHICLE_TYPE_CHOICES = [
        ('PASSENGER_CAR', 'Passenger Car'),
        ('SUV', 'SUV'),
        ('TRUCK', 'Truck'),
        ('MOTORCYCLE', 'Motorcycle'),
        ('TRAILER', 'Trailer'),
    ]
    
    TYRE_CONSTRUCTION_CHOICES = [
        ('RADIAL', 'Radial'),
        ('BIAS', 'Bias'),
        ('BELTED_BIAS', 'Belted Bias'),
    ]
    
    BOOLEAN_CHOICES = [
        ('YES', 'Yes'),
        ('NO', 'No'),
    ]
    
    # Primary identification
    id = models.AutoField(primary_key=True)
    
    # Basic tyre/rim specifications
    tyre_width = models.IntegerField(
        help_text="Tyre width in millimeters (e.g., 205)",
        validators=[MinValueValidator(100), MaxValueValidator(500)]
    )
    sidewall_profile = models.CharField(
        max_length=3,
        choices=SIDEWALL_PROFILE_CHOICES,
        help_text="Sidewall profile (e.g., 55)"
    )
    wheel_rim_diameter = models.CharField(
        max_length=2,
        choices=RIM_DIAMETER_CHOICES,
        help_text="Wheel rim diameter in inches"
    )
    
    # Product type and quantity
    select_tyres_rims = models.CharField(
        max_length=20,
        choices=TYRE_RIM_TYPE_CHOICES,
        help_text="What are you looking for?"
    )
    quantity = models.IntegerField(
        validators=[MinValueValidator(1), MaxValueValidator(100)],
        help_text="How many pieces needed?"
    )
    urgency = models.CharField(
        max_length=20,
        choices=URGENCY_CHOICES,
        help_text="How soon do you need to buy this product?"
    )
    
    # Additional specifications
    description = models.TextField(
        blank=True,
        help_text="Description of the item needed"
    )
    vehicle_type = models.CharField(
        max_length=20,
        choices=VEHICLE_TYPE_CHOICES,
        help_text="Type of vehicle"
    )
    pitch_circle_diameter = models.CharField(
        max_length=10,
        blank=True,
        help_text="PCD measurement (e.g., 5x100)"
    )
    
    # Brand and construction preferences
    preferred_brand = models.CharField(
        max_length=100,
        blank=True,
        help_text="Preferred brand(s) - can list multiple"
    )
    tyre_construction_type = models.CharField(
        max_length=20,
        choices=TYRE_CONSTRUCTION_CHOICES,
        blank=True,
        help_text="Construction type preference"
    )
    
    # Service requirements
    balancing_required = models.CharField(
        max_length=3,
        choices=BOOLEAN_CHOICES,
        default='NO',
        help_text="Do you need balancing service?"
    )
    tyre_rotation_required = models.CharField(
        max_length=3,
        choices=BOOLEAN_CHOICES,
        default='NO',
        help_text="Do you need tyre rotation service?"
    )
    fitment_required = models.CharField(
        max_length=3,
        choices=BOOLEAN_CHOICES,
        default='NO',
        help_text="Do you need fitment service?"
    )
    
    # Product images
    product_images = models.JSONField(
        null=True,
        blank=True,
        help_text="Array of uploaded product image URLs"
    )
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'vehicle_tyres_rims'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['select_tyres_rims']),
            models.Index(fields=['vehicle_type']),
            models.Index(fields=['urgency']),
            models.Index(fields=['created_at']),
        ]
    
    def __str__(self):
        return f"{self.tyre_width}/{self.sidewall_profile}R{self.wheel_rim_diameter} - {self.select_tyres_rims}"
    
    @property
    def tyre_size_display(self):
        """Return the formatted tyre size."""
        return f"{self.tyre_width}/{self.sidewall_profile}R{self.wheel_rim_diameter}"
    
    @property
    def is_urgent(self):
        """Check if the request is urgent."""
        return self.urgency in ['ASAP', '12_HOURS', '24_HOURS']
    
    def get_preferred_brands_list(self):
        """Return preferred brands as a list."""
        if not self.preferred_brand:
            return []
        # Split by comma and clean up whitespace
        return [brand.strip() for brand in self.preferred_brand.split(',') if brand.strip()]
    
    def requires_professional_service(self):
        """Check if any professional services are required."""
        return any([
            self.balancing_required == 'YES',
            self.tyre_rotation_required == 'YES',
            self.fitment_required == 'YES'
        ])


class ProductRequest(models.Model):
    """
    Customer requests for products or quotes - aligned with final specifications.
    """

    # Category choices as per specifications
    CATEGORY_CHOICES = [
        ('VEHICLE_SPARES', 'Vehicle Spares'),
        ('TYRES_RIMS', 'Tyres & Rims'),
        ('ELECTRONICS', 'Electronics'),
    ]

    # Condition preference choices
    CONDITION_CHOICES = [
        ('NEW', 'New'),
        ('USED', 'Used'),
        ('REFURBISHED', 'Refurbished'),
        ('ANY', 'Any'),
    ]

    # Status choices
    STATUS_CHOICES = [
        ('ACTIVE', 'Active'),
        ('CLOSED', 'Closed'),
        ('EXPIRED', 'Expired'),
    ]

    # Urgency timeline choices
    URGENCY_TIMELINE_CHOICES = [
        ('ASAP', 'ASAP'),
        ('12_HOURS', '12 Hours'),
        ('1_WEEK', '1 Week'),
        ('1_MONTH', '1 Month'),
    ]

    # Primary key and foreign key fields
    request_id = models.UUIDField(
        primary_key=True,
        default=uuid.uuid4,
        editable=False
    )
    buyer_id = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='product_requests'
    )

    # Category and basic info
    category = models.CharField(
        max_length=20,
        choices=CATEGORY_CHOICES
    )
    title = models.CharField(
        max_length=200,
        help_text="Auto-generated from specifications"
    )
    description = models.TextField(
        null=True,
        blank=True,
        help_text="Buyer-provided product description"
    )

    # Product specifications (JSON field)
    product_specifications = models.JSONField(
        help_text="Category-specific specifications"
    )

    # Quantity and condition
    quantity = models.IntegerField(
        validators=[MinValueValidator(1)],
        help_text="Required quantity"
    )
    condition_preference = models.CharField(
        max_length=20,
        choices=CONDITION_CHOICES,
        default='ANY'
    )

    # Budget information
    max_budget = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        null=True,
        blank=True,
        help_text="Maximum budget limit"
    )
    currency = models.CharField(
        max_length=3,
        default='ZAR',
        help_text="Currency code"
    )

    # Location information (JSON field)
    buyer_location = models.JSONField(
        help_text="Lat/lng and address details"
    )
    max_travel_distance = models.IntegerField(
        default=50,
        help_text="Maximum distance willing to travel (km)"
    )

    # Timeline and urgency
    urgency_timeline = models.CharField(
        max_length=50,
        choices=URGENCY_TIMELINE_CHOICES,
        help_text="ASAP, 12 Hours, 1 Week, 1 Month, etc."
    )

    # Images and VIN
    product_images = models.JSONField(
        null=True,
        blank=True,
        help_text="Array of uploaded image URLs"
    )
    vin_photo_url = models.CharField(
        max_length=500,
        null=True,
        blank=True,
        help_text="VIN photo for vehicle spares"
    )

    # Related tyres and rims specification (optional)
    vehicle_tyres_rims = models.ForeignKey(
        VehicleTyresRims,
        on_delete=models.CASCADE,
        null=True,
        blank=True,
        related_name='product_requests',
        help_text="Detailed tyres and rims specifications if applicable"
    )
    
    # Related vehicle spares specification (optional)
    vehicle_spares = models.ForeignKey(
        VehicleSpares,
        on_delete=models.CASCADE,
        null=True,
        blank=True,
        related_name='product_requests',
        help_text="Detailed vehicle spares specifications if applicable"
    )
    
    # Related consumer electronics specification (optional)
    consumer_electronics = models.ForeignKey(
        ConsumerElectronics,
        on_delete=models.CASCADE,
        null=True,
        blank=True,
        related_name='product_requests',
        help_text="Detailed consumer electronics specifications if applicable"
    )
    
    # Terms and consent
    terms_accepted = models.BooleanField(
        help_text="Must accept terms and conditions"
    )
    contact_consent = models.BooleanField(
        help_text="Consent to be contacted for quotes"
    )

    # System fields
    expiry_date = models.DateTimeField(
        null=True,
        blank=True,
        help_text="Auto-calculated based on urgency"
    )
    status = models.CharField(
        max_length=20,
        choices=STATUS_CHOICES,
        default='ACTIVE'
    )
    view_count = models.IntegerField(
        default=0,
        help_text="Number of views by sellers"
    )

    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'product_request'  # Explicit table name if needed
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['status', 'category']),
            models.Index(fields=['buyer_id', 'status']),
            models.Index(fields=['category', 'status']),
            models.Index(fields=['expiry_date']),
            models.Index(fields=['urgency_timeline']),
            models.Index(fields=['created_at']),
        ]

    def __str__(self):
        return f"{self.request_id} - {self.title}"

    def save(self, *args, **kwargs):
        # Auto-calculate expiry date based on urgency_timeline if not provided
        if not self.expiry_date:
            self.expiry_date = self.calculate_expiry_date()
            
        # Auto-generate title from specifications if not provided
        if not self.title and self.product_specifications:
            self.title = self.generate_title_from_specifications()
            
        # Validate specifications against schema
        if 'validate_specs' not in kwargs or kwargs.pop('validate_specs'):
            is_valid, error_message = self.validate_specifications()
            if not is_valid:
                # Log the error but don't prevent saving
                # In a real application, you might want to raise an exception
                print(f"Warning: {error_message}")

        super().save(*args, **kwargs)

    def calculate_expiry_date(self):
        """Calculate expiry date based on urgency timeline."""
        now = timezone.now()
        urgency_map = {
            'ASAP': 1,  # 1 day
            '12_HOURS': 0.5,  # 12 hours
            '1_WEEK': 7,  # 7 days
            '1_MONTH': 30,  # 30 days
        }

        days = urgency_map.get(self.urgency_timeline, 7)  # Default to 7 days
        return now + timezone.timedelta(days=days)

    @property
    def is_expired(self):
        """Check if the request has expired."""
        if not self.expiry_date:
            return False
        return timezone.now() > self.expiry_date

    @property
    def is_urgent(self):
        """Check if the request is urgent based on urgency timeline."""
        return self.urgency_timeline in ['ASAP', '12_HOURS']

    def can_receive_quotes(self):
        """Check if request can still receive quotes."""
        return (
                self.status == 'ACTIVE' and
                not self.is_expired
        )

    def mark_as_viewed(self):
        """Increment view count."""
        self.view_count += 1
        self.save(update_fields=['view_count'])

    def close_request(self):
        """Close the request."""
        self.status = 'CLOSED'
        self.save(update_fields=['status'])

    def mark_as_expired(self):
        """Mark request as expired."""
        self.status = 'EXPIRED'
        self.save(update_fields=['status'])
        
    def get_category_object(self):
        """
        Get the Category object associated with this request's category.
        
        Returns:
            Category object or None if not found
        """
        try:
            # Try to find a category with a matching name from the CATEGORY_CHOICES
            category_name = dict(self.CATEGORY_CHOICES).get(self.category)
            return Category.objects.filter(name=category_name).first()
        except Exception:
            return None
            
    def get_specification_type(self):
        """
        Get the specification type for this request's category.
        
        Returns:
            String representing the category type or None if not found
        """
        category = self.get_category_object()
        if category:
            return category.get_specification_type()
        return None
        
    def get_specification_schema(self):
        """
        Get the specification schema for this request's category.
        
        Returns:
            JSON schema for the category or None if not found
        """
        category = self.get_category_object()
        if category:
            return category.get_specification_schema()
        return None
        
    def validate_specifications(self):
        """
        Validate that the product_specifications conform to the category's schema.
        
        Returns:
            Tuple of (is_valid, error_message)
        """
        schema = self.get_specification_schema()
        if not schema:
            return False, "No specification schema found for this category"
            
        # Basic validation - check if required fields are present
        if 'required' in schema:
            for field in schema['required']:
                if field not in self.product_specifications:
                    return False, f"Required field '{field}' is missing"
                    
        # More detailed validation could be implemented here
        return True, "Specifications are valid"
        
    def get_template_for_category(self):
        """
        Get a suitable template for this request's category.
        
        Returns:
            RequestTemplate object or None if not found
        """
        # from products.models import ProductSpecificationTemplate
        
        category = self.get_category_object()
        if not category:
            return None
            
        # Try to find a template for this category
        # Return None since we're temporarily disabling the ProductSpecificationTemplate usage
        return None
        
    def generate_title_from_specifications(self):
        """
        Generate a title for the request based on its specifications.
        
        Returns:
            Generated title string
        """
        spec_type = self.get_specification_type()
        
        if spec_type == 'VEHICLE_SPARES':
            # For vehicle spares, use make, model, and part name
            make = self.product_specifications.get('manufacturer', '')
            model = self.product_specifications.get('make_model', '')
            part = self.product_specifications.get('part_name', '')
            
            if make and model and part:
                return f"{make} {model} - {part}"
            elif part:
                return f"Vehicle Part: {part}"
                
        elif spec_type == 'ELECTRONICS':
            # For electronics, use type and brand
            e_type = self.product_specifications.get('electronics_type', '')
            brand = self.product_specifications.get('brand_preference', '')
            
            if e_type and brand:
                return f"{brand} {e_type}"
            elif e_type:
                return f"Electronics: {e_type}"
                
        elif spec_type == 'TYRES_RIMS':
            # For tyres/rims, use dimensions and type
            width = self.product_specifications.get('tyre_width', '')
            profile = self.product_specifications.get('sidewall_profile', '')
            diameter = self.product_specifications.get('rim_diameter', '')
            type_str = self.product_specifications.get('select_type', '')
            
            if width and profile and diameter:
                return f"{type_str}: {width}/{profile}R{diameter}"
            elif type_str:
                return f"{type_str} Request"
        
        # Default title if we can't generate a specific one
        return f"{dict(self.CATEGORY_CHOICES).get(self.category, 'Product')} Request"
        
    def apply_template(self, template_id=None):
        """
        Apply a template to this request.
        
        Args:
            template_id: Optional ID of the template to apply
            
        Returns:
            Boolean indicating success
        """
        # from products.models import ProductSpecificationTemplate
        
        # If template_id is provided, use that specific template
        if template_id:
            try:
                template = ProductSpecificationTemplate.objects.get(id=template_id)
            except ProductSpecificationTemplate.DoesNotExist:
                return False
        else:
            # Otherwise try to find a suitable template
            template = self.get_template_for_category()
            
        if not template:
            return False
            
        # Apply the template data
        if template.example_data:
            # Merge with existing specifications, template takes precedence
            self.product_specifications.update(template.example_data)
            
        # Increment template usage count
        template.increment_usage()
        
        return True
    
    def sync_vehicle_tyres_rims_data(self):
        """
        Synchronize data between VehicleTyresRims instance and product_specifications JSON.
        This ensures data consistency between the structured model and JSON fields.
        """
        if self.vehicle_tyres_rims and self.category == 'TYRES_RIMS':
            # Update product_specifications with VehicleTyresRims data
            tyres_rims_data = {
                'tyre_width': self.vehicle_tyres_rims.tyre_width,
                'sidewall_profile': self.vehicle_tyres_rims.sidewall_profile,
                'wheel_rim_diameter': self.vehicle_tyres_rims.wheel_rim_diameter,
                'select_tyres_rims': self.vehicle_tyres_rims.select_tyres_rims,
                'quantity': self.vehicle_tyres_rims.quantity,
                'urgency': self.vehicle_tyres_rims.urgency,
                'description': self.vehicle_tyres_rims.description,
                'vehicle_type': self.vehicle_tyres_rims.vehicle_type,
                'pitch_circle_diameter': self.vehicle_tyres_rims.pitch_circle_diameter,
                'preferred_brand': self.vehicle_tyres_rims.preferred_brand,
                'tyre_construction_type': self.vehicle_tyres_rims.tyre_construction_type,
                'balancing_required': self.vehicle_tyres_rims.balancing_required,
                'tyre_rotation_required': self.vehicle_tyres_rims.tyre_rotation_required,
                'fitment_required': self.vehicle_tyres_rims.fitment_required,
                'product_images': self.vehicle_tyres_rims.product_images,
            }
            
            # Merge with existing specifications
            if not self.product_specifications:
                self.product_specifications = {}
            self.product_specifications.update(tyres_rims_data)
            
            # Update general fields from VehicleTyresRims if not set
            if not self.quantity:
                self.quantity = self.vehicle_tyres_rims.quantity
            if not self.product_images:
                self.product_images = self.vehicle_tyres_rims.product_images
    
    def create_vehicle_tyres_rims_from_specs(self):
        """
        Create a VehicleTyresRims instance from product_specifications data.
        Useful when creating a ProductRequest with JSON data that should be structured.
        
        Returns:
            VehicleTyresRims instance or None if not applicable
        """
        if (self.category == 'TYRES_RIMS' and 
            self.product_specifications and 
            not self.vehicle_tyres_rims):
            
            specs = self.product_specifications
            
            # Extract required fields
            try:
                tyres_rims = VehicleTyresRims(
                    tyre_width=specs.get('tyre_width', 205),
                    sidewall_profile=specs.get('sidewall_profile', '55'),
                    wheel_rim_diameter=specs.get('wheel_rim_diameter', '16'),
                    select_tyres_rims=specs.get('select_tyres_rims', 'TYRES'),
                    quantity=specs.get('quantity', self.quantity or 1),
                    urgency=specs.get('urgency', 'ASAP'),
                    description=specs.get('description', self.description or ''),
                    vehicle_type=specs.get('vehicle_type', 'PASSENGER_CAR'),
                    pitch_circle_diameter=specs.get('pitch_circle_diameter', ''),
                    preferred_brand=specs.get('preferred_brand', ''),
                    tyre_construction_type=specs.get('tyre_construction_type', ''),
                    balancing_required=specs.get('balancing_required', 'NO'),
                    tyre_rotation_required=specs.get('tyre_rotation_required', 'NO'),
                    fitment_required=specs.get('fitment_required', 'NO'),
                    product_images=specs.get('product_images', self.product_images),
                )
                tyres_rims.save()
                self.vehicle_tyres_rims = tyres_rims
                return tyres_rims
            except Exception as e:
                print(f"Error creating VehicleTyresRims from specs: {e}")
                return None
        return None
    
    @property
    def tyres_rims_summary(self):
        """
        Get a summary of the tyres and rims specifications.
        
        Returns:
            String summary or None if not applicable
        """
        if self.vehicle_tyres_rims:
            return self.vehicle_tyres_rims.tyre_size_display
        elif (self.category == 'TYRES_RIMS' and self.product_specifications):
            specs = self.product_specifications
            width = specs.get('tyre_width', '')
            profile = specs.get('sidewall_profile', '')
            diameter = specs.get('wheel_rim_diameter', '')
            if width and profile and diameter:
                return f"{width}/{profile}R{diameter}"
        return None
    
    def sync_vehicle_spares_data(self):
        """
        Synchronize data between VehicleSpares instance and product_specifications JSON.
        This ensures data consistency between the structured model and JSON fields.
        """
        if self.vehicle_spares and self.category == 'VEHICLE_SPARES':
            # Update product_specifications with VehicleSpares data
            spares_data = {
                'vehicle_make': self.vehicle_spares.vehicle_make,
                'vehicle_model': self.vehicle_spares.vehicle_model,
                'vehicle_year': self.vehicle_spares.vehicle_year,
                'vehicle_type': self.vehicle_spares.vehicle_type,
                'engine_size': self.vehicle_spares.engine_size,
                'vin_number': self.vehicle_spares.vin_number,
                'part_name': self.vehicle_spares.part_name,
                'part_category': self.vehicle_spares.part_category,
                'part_number': self.vehicle_spares.part_number,
                'quantity': self.vehicle_spares.quantity,
                'condition_preference': self.vehicle_spares.condition_preference,
                'urgency': self.vehicle_spares.urgency,
                'description': self.vehicle_spares.description,
                'compatible_models': self.vehicle_spares.compatible_models,
                'preferred_brand': self.vehicle_spares.preferred_brand,
                'avoid_brands': self.vehicle_spares.avoid_brands,
                'installation_required': self.vehicle_spares.installation_required,
                'warranty_required': self.vehicle_spares.warranty_required,
                'max_budget': str(self.vehicle_spares.max_budget) if self.vehicle_spares.max_budget else None,
                'currency': self.vehicle_spares.currency,
                'product_images': self.vehicle_spares.product_images,
                'vin_photo': self.vehicle_spares.vin_photo,
                'location_info': self.vehicle_spares.location_info,
            }
            
            # Merge with existing specifications
            if not self.product_specifications:
                self.product_specifications = {}
            self.product_specifications.update(spares_data)
            
            # Update general fields from VehicleSpares if not set
            if not self.quantity:
                self.quantity = self.vehicle_spares.quantity
            if not self.product_images:
                self.product_images = self.vehicle_spares.product_images
            if not self.max_budget and self.vehicle_spares.max_budget:
                self.max_budget = self.vehicle_spares.max_budget
            if not self.vin_photo_url and self.vehicle_spares.vin_photo:
                self.vin_photo_url = self.vehicle_spares.vin_photo
    
    def create_vehicle_spares_from_specs(self):
        """
        Create a VehicleSpares instance from product_specifications data.
        Useful when creating a ProductRequest with JSON data that should be structured.
        
        Returns:
            VehicleSpares instance or None if not applicable
        """
        if (self.category == 'VEHICLE_SPARES' and 
            self.product_specifications and 
            not self.vehicle_spares):
            
            specs = self.product_specifications
            
            # Extract required fields
            try:
                spares = VehicleSpares(
                    vehicle_make=specs.get('vehicle_make', 'Unknown'),
                    vehicle_model=specs.get('vehicle_model', 'Unknown'),
                    vehicle_year=specs.get('vehicle_year', 2020),
                    vehicle_type=specs.get('vehicle_type', 'PASSENGER_CAR'),
                    engine_size=specs.get('engine_size', ''),
                    vin_number=specs.get('vin_number', ''),
                    part_name=specs.get('part_name', 'Part'),
                    part_category=specs.get('part_category', 'OTHER'),
                    part_number=specs.get('part_number', ''),
                    quantity=specs.get('quantity', self.quantity or 1),
                    condition_preference=specs.get('condition_preference', 'NEW'),
                    urgency=specs.get('urgency', 'ASAP'),
                    description=specs.get('description', self.description or ''),
                    compatible_models=specs.get('compatible_models', ''),
                    preferred_brand=specs.get('preferred_brand', ''),
                    avoid_brands=specs.get('avoid_brands', ''),
                    installation_required=specs.get('installation_required', 'NO'),
                    warranty_required=specs.get('warranty_required', 'NO'),
                    max_budget=Decimal(specs['max_budget']) if specs.get('max_budget') else self.max_budget,
                    currency=specs.get('currency', 'ZAR'),
                    product_images=specs.get('product_images', self.product_images),
                    vin_photo=specs.get('vin_photo', self.vin_photo_url or ''),
                    location_info=specs.get('location_info', {}),
                )
                spares.save()
                self.vehicle_spares = spares
                return spares
            except Exception as e:
                print(f"Error creating VehicleSpares from specs: {e}")
                return None
        return None
    
    @property
    def vehicle_spares_summary(self):
        """
        Get a summary of the vehicle spares specifications.
        
        Returns:
            String summary or None if not applicable
        """
        if self.vehicle_spares:
            return f"{self.vehicle_spares.vehicle_display} - {self.vehicle_spares.part_name}"
        elif (self.category == 'VEHICLE_SPARES' and self.product_specifications):
            specs = self.product_specifications
            make = specs.get('vehicle_make', '')
            model = specs.get('vehicle_model', '')
            year = specs.get('vehicle_year', '')
            part = specs.get('part_name', '')
            if make and model and year and part:
                return f"{make} {model} {year} - {part}"
            elif part:
                return part
        return None
    
    def sync_consumer_electronics_data(self):
        """
        Synchronize data between ConsumerElectronics instance and product_specifications JSON.
        This ensures data consistency between the structured model and JSON fields.
        """
        if self.consumer_electronics and self.category == 'ELECTRONICS':
            # Update product_specifications with ConsumerElectronics data
            electronics_data = {
                'electronics_type': self.consumer_electronics.electronics_type,
                'brand_preference': self.consumer_electronics.brand_preference,
                'model_series': self.consumer_electronics.model_series,
                'quantity_needed': self.consumer_electronics.quantity_needed,
                'min_price': str(self.consumer_electronics.min_price) if self.consumer_electronics.min_price else None,
                'max_price': str(self.consumer_electronics.max_price) if self.consumer_electronics.max_price else None,
                'currency': self.consumer_electronics.currency,
                'urgency': self.consumer_electronics.urgency,
                'installation_required': self.consumer_electronics.installation_required,
                'required_features': self.consumer_electronics.required_features,
                'condition_preference': self.consumer_electronics.condition_preference,
                'purpose_of_purchase': self.consumer_electronics.purpose_of_purchase,
                'additional_comments': self.consumer_electronics.additional_comments,
                'product_images': self.consumer_electronics.product_images,
                'delivery_location': self.consumer_electronics.delivery_location,
                'warranty_required': self.consumer_electronics.warranty_required,
                'warranty_duration': self.consumer_electronics.warranty_duration,
                'energy_efficiency_required': self.consumer_electronics.energy_efficiency_required,
            }
            
            # Merge with existing specifications
            if not self.product_specifications:
                self.product_specifications = {}
            self.product_specifications.update(electronics_data)
            
            # Update general fields from ConsumerElectronics if not set
            if not self.quantity:
                self.quantity = self.consumer_electronics.quantity_needed
            if not self.product_images:
                self.product_images = self.consumer_electronics.product_images
            if not self.max_budget and self.consumer_electronics.max_price:
                self.max_budget = self.consumer_electronics.max_price
            if self.consumer_electronics.condition_preference != 'NEW':
                self.condition_preference = self.consumer_electronics.condition_preference
    
    def create_consumer_electronics_from_specs(self):
        """
        Create a ConsumerElectronics instance from product_specifications data.
        Useful when creating a ProductRequest with JSON data that should be structured.
        
        Returns:
            ConsumerElectronics instance or None if not applicable
        """
        if (self.category == 'ELECTRONICS' and 
            self.product_specifications and 
            not self.consumer_electronics):
            
            specs = self.product_specifications
            
            # Extract required fields
            try:
                electronics = ConsumerElectronics(
                    electronics_type=specs.get('electronics_type', 'OTHER'),
                    brand_preference=specs.get('brand_preference', ''),
                    model_series=specs.get('model_series', ''),
                    quantity_needed=specs.get('quantity_needed', self.quantity or 1),
                    min_price=Decimal(specs['min_price']) if specs.get('min_price') else None,
                    max_price=Decimal(specs['max_price']) if specs.get('max_price') else self.max_budget,
                    currency=specs.get('currency', 'ZAR'),
                    urgency=specs.get('urgency', 'ASAP'),
                    installation_required=specs.get('installation_required', 'NO'),
                    required_features=specs.get('required_features', ''),
                    condition_preference=specs.get('condition_preference', 'NEW'),
                    purpose_of_purchase=specs.get('purpose_of_purchase', 'PERSONAL_USE'),
                    additional_comments=specs.get('additional_comments', self.description or ''),
                    product_images=specs.get('product_images', self.product_images),
                    delivery_location=specs.get('delivery_location', {}),
                    warranty_required=specs.get('warranty_required', 'YES'),
                    warranty_duration=specs.get('warranty_duration', ''),
                    energy_efficiency_required=specs.get('energy_efficiency_required', 'NO'),
                )
                electronics.save()
                self.consumer_electronics = electronics
                return electronics
            except Exception as e:
                print(f"Error creating ConsumerElectronics from specs: {e}")
                return None
        return None
    
    @property
    def consumer_electronics_summary(self):
        """
        Get a summary of the consumer electronics specifications.
        
        Returns:
            String summary or None if not applicable
        """
        if self.consumer_electronics:
            return self.consumer_electronics.full_product_description
        elif (self.category == 'ELECTRONICS' and self.product_specifications):
            specs = self.product_specifications
            electronics_type = specs.get('electronics_type', '')
            brand = specs.get('brand_preference', '')
            model = specs.get('model_series', '')
            if electronics_type and brand and model:
                return f"{brand} {model} {electronics_type}"
            elif electronics_type and brand:
                return f"{brand} {electronics_type}"
            elif electronics_type:
                return electronics_type
        return None


class RequestImage(models.Model):
    """
    Images attached to product requests for reference.
    """
    request = models.ForeignKey(
        ProductRequest,
        on_delete=models.CASCADE,
        related_name='images'
    )
    image = models.ImageField(upload_to='requests/')
    caption = models.CharField(max_length=200, blank=True)
    sort_order = models.IntegerField(default=0)
    
    class Meta:
        ordering = ['sort_order', 'id']
    
    def __str__(self):
        return f"{self.request.request_id} - Image {self.id}"


class RequestSpecification(models.Model):
    """
    Detailed specifications for product requests.
    """
    request = models.ForeignKey(
        ProductRequest,
        on_delete=models.CASCADE,
        related_name='specifications'
    )
    name = models.CharField(max_length=100)
    value = models.TextField()
    is_required = models.BooleanField(default=False)
    sort_order = models.IntegerField(default=0)
    
    class Meta:
        unique_together = ['request', 'name']
        ordering = ['sort_order', 'name']
    
    def __str__(self):
        return f"{self.request.request_id} - {self.name}: {self.value}"


class RequestMessage(models.Model):
    """
    Messages/communications related to product requests.
    """
    MESSAGE_TYPES = [
        ('inquiry', 'Inquiry'),
        ('clarification', 'Clarification'),
        ('update', 'Update'),
        ('quote_submission', 'Quote Submission'),
        ('system', 'System Message'),
    ]
    
    request = models.ForeignKey(
        ProductRequest,
        on_delete=models.CASCADE,
        related_name='messages'
    )
    sender = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='sent_request_messages'
    )
    message_type = models.CharField(max_length=20, choices=MESSAGE_TYPES, default='inquiry')
    subject = models.CharField(max_length=200, blank=True)
    message = models.TextField()
    is_internal = models.BooleanField(
        default=False,
        help_text="Internal messages not visible to requester"
    )
    created_at = models.DateTimeField(auto_now_add=True)
    read_at = models.DateTimeField(null=True, blank=True)
    
    class Meta:
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['request', 'created_at']),
            models.Index(fields=['sender']),
        ]
    
    def __str__(self):
        return f"{self.request.request_id} - {self.sender.username}: {self.subject or 'Message'}"
    
    @property
    def is_read(self):
        """Check if message has been read."""
        return self.read_at is not None
    
    def mark_as_read(self):
        """Mark message as read."""
        if not self.is_read:
            self.read_at = timezone.now()
            self.save(update_fields=['read_at'])


class RequestWatchlist(models.Model):
    """
    Users can watch product requests to get notifications.
    """
    request = models.ForeignKey(
        ProductRequest,
        on_delete=models.CASCADE,
        related_name='watchers'
    )
    user = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='watched_requests'
    )
    created_at = models.DateTimeField(auto_now_add=True)
    
    # Notification preferences
    notify_on_quotes = models.BooleanField(default=True)
    notify_on_updates = models.BooleanField(default=True)
    notify_on_messages = models.BooleanField(default=False)
    
    class Meta:
        unique_together = ['request', 'user']
        indexes = [
            models.Index(fields=['user', 'created_at']),
        ]
    
    def __str__(self):
        return f"{self.user.username} watching {self.request.request_id}"


class RequestTemplate(models.Model):
    """
    Templates for common product request types.
    """
    name = models.CharField(max_length=100)
    description = models.TextField(blank=True)
    category = models.ForeignKey(
        Category,
        on_delete=models.CASCADE,
        related_name='request_templates'
    )
    # Temporarily comment out the choices reference
    request_type = models.CharField(
        max_length=30
    )
    
    # Template data
    template_data = models.JSONField(
        default=dict,
        help_text="JSON data for pre-filling request forms"
    )
    
    # Usage tracking
    usage_count = models.IntegerField(default=0)
    is_active = models.BooleanField(default=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['category__name', 'name']
        indexes = [
            models.Index(fields=['category', 'is_active']),
            models.Index(fields=['request_type', 'is_active']),
        ]
    
    def __str__(self):
        return f"{self.category.name} - {self.name}"
    
    def increment_usage(self):
        """Increment usage count when template is used."""
        self.usage_count += 1
        self.save(update_fields=['usage_count'])
