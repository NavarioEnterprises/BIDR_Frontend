from django.core.management.base import BaseCommand
from django.utils.text import slugify
from product_management_service.categories.models import Category, CategorySpecification
from product_management_service.products.models import ProductSpecificationTemplate


class Command(BaseCommand):
    help = 'Setup category specifications and templates for existing categories'

    def handle(self, *args, **options):
        self.setup_category_specifications()
        self.setup_specification_templates()
        self.stdout.write(
            self.style.SUCCESS('Successfully setup category specifications and templates')
        )

    def setup_category_specifications(self):
        """Create or update category specifications for your three main categories."""

        # Vehicle Spares Specification Schema
        vehicle_spares_schema = {
            "type": "object",
            "required": ["manufacturer", "make_model", "year", "part_name"],
            "properties": {
                "vin_number": {"type": "string"},
                "vin_photo_url": {"type": "string", "format": "uri"},
                "manufacturer": {"type": "string"},
                "make_model": {"type": "string"},
                "year": {"type": "string"},
                "vehicle_type": {"type": "string"},
                "part_condition": {"type": "string", "enum": ["New", "Used", "Refurbished"]},
                "part_name": {"type": "string"},
                "part_description": {"type": "string"},
                "oem_part_number": {"type": "string"},
                "compatible_models": {"type": "array", "items": {"type": "string"}},
                "warranty_period": {"type": "string"}
            }
        }

        # Electronics Specification Schema
        electronics_schema = {
            "type": "object",
            "required": ["electronics_type", "brand_preference"],
            "properties": {
                "electronics_type": {"type": "string"},
                "brand_preference": {"type": "string"},
                "model_series": {"type": "string"},
                "features_required": {"type": "array", "items": {"type": "string"}},
                "specifications": {
                    "type": "object",
                    "properties": {
                        "capacity": {"type": "string"},
                        "type": {"type": "string"},
                        "energy_rating": {"type": "string"},
                        "power_consumption": {"type": "string"},
                        "dimensions": {"type": "string"},
                        "color": {"type": "string"}
                    }
                },
                "warranty_required": {"type": "boolean"},
                "installation_required": {"type": "boolean"}
            }
        }

        # Tyres & Rims Specification Schema
        tyres_rims_schema = {
            "type": "object",
            "required": ["select_type", "vehicle_type"],
            "properties": {
                "tyre_width": {"type": "string"},
                "sidewall_profile": {"type": "string"},
                "rim_diameter": {"type": "string"},
                "select_type": {"type": "string", "enum": ["Tyres", "Rims", "Both"]},
                "vehicle_type": {"type": "string"},
                "pitch_circle_diameter": {"type": "string"},
                "preferred_brand": {"type": "string"},
                "construction_type": {"type": "string", "enum": ["Radial", "Bias"]},
                "tyre_condition": {"type": "string", "enum": ["New", "Used"]},
                "fitment_required": {"type": "boolean"},
                "balancing_required": {"type": "boolean"},
                "rotation_required": {"type": "boolean"},
                "alignment_required": {"type": "boolean"},
                "load_index": {"type": "string"},
                "speed_rating": {"type": "string"}
            }
        }

        # Define the specifications for each category type
        specification_configs = [
            {
                'category_type': 'VEHICLE_SPARES',
                'category_names': ['Vehicle Spares', 'Auto Parts', 'Car Parts'],
                'schema': vehicle_spares_schema,
                'form_template': {
                    "sections": [
                        {
                            "title": "Vehicle Information",
                            "fields": ["manufacturer", "make_model", "year", "vehicle_type", "vin_number"]
                        },
                        {
                            "title": "Part Details",
                            "fields": ["part_name", "part_description", "part_condition", "oem_part_number"]
                        }
                    ]
                }
            },
            {
                'category_type': 'ELECTRONICS',
                'category_names': ['Electronics', 'Consumer Electronics', 'Appliances'],
                'schema': electronics_schema,
                'form_template': {
                    "sections": [
                        {
                            "title": "Product Details",
                            "fields": ["electronics_type", "brand_preference", "model_series"]
                        },
                        {
                            "title": "Specifications",
                            "fields": ["specifications", "features_required"]
                        }
                    ]
                }
            },
            {
                'category_type': 'TYRES_RIMS',
                'category_names': ['Tyres & Rims', 'Tyres', 'Rims', 'Wheels'],
                'schema': tyres_rims_schema,
                'form_template': {
                    "sections": [
                        {
                            "title": "Tyre/Rim Specifications",
                            "fields": ["tyre_width", "sidewall_profile", "rim_diameter", "select_type"]
                        },
                        {
                            "title": "Vehicle & Services",
                            "fields": ["vehicle_type", "fitment_required", "balancing_required"]
                        }
                    ]
                }
            }
        ]

        # Create category specifications for existing categories
        for config in specification_configs:
            # Find matching categories by name
            matching_categories = Category.objects.filter(
                name__in=config['category_names'],
                status='active'  # Assuming you use 'active' status
            )

            for category in matching_categories:
                spec, created = CategorySpecification.objects.get_or_create(
                    category=category,
                    defaults={
                        'category_type': config['category_type'],
                        'specification_schema': config['schema'],
                        'form_template': config['form_template']
                    }
                )

                if created:
                    self.stdout.write(f"Created specification for category: {category.name}")
                else:
                    # Update existing specification
                    spec.specification_schema = config['schema']
                    spec.form_template = config['form_template']
                    spec.save()
                    self.stdout.write(f"Updated specification for category: {category.name}")

            # If no matching categories found, create a parent category
            if not matching_categories.exists():
                category_name = config['category_names'][0]  # Use first name as default
                category, cat_created = Category.objects.get_or_create(
                    name=category_name,
                    defaults={
                        'slug': slugify(category_name),
                        'description': f'{category_name} category with specifications',
                        'status': 'active',
                        'show_in_menu': True
                    }
                )

                if cat_created:
                    self.stdout.write(f"Created new category: {category.name}")

                # Create specification for the new category
                spec, created = CategorySpecification.objects.get_or_create(
                    category=category,
                    defaults={
                        'category_type': config['category_type'],
                        'specification_schema': config['schema'],
                        'form_template': config['form_template']
                    }
                )

                if created:
                    self.stdout.write(f"Created specification for new category: {category.name}")

    def setup_specification_templates(self):
        """Create specification templates for categories with specifications."""

        # Get all categories that have specifications
        categories_with_specs = Category.objects.filter(
            specification__isnull=False
        ).select_related('specification')

        for category in categories_with_specs:
            category_type = category.specification.category_type

            # Vehicle Spares Templates
            if category_type == 'VEHICLE_SPARES':
                templates = [
                    {
                        'name': 'Engine Parts',
                        'description': 'Engine components and related parts',
                        'template_schema': {
                            "engine_type": {"type": "string", "required": True},
                            "engine_size": {"type": "string"},
                            "fuel_type": {"type": "string", "enum": ["Petrol", "Diesel", "Hybrid", "Electric"]},
                            "part_category": {"type": "string", "enum": ["Filter", "Belt", "Gasket", "Sensor", "Other"]}
                        },
                        'example_data': {
                            "manufacturer": "Toyota",
                            "make_model": "Corolla 2018",
                            "part_name": "Oil Filter",
                            "engine_type": "1.8L 4-cylinder",
                            "engine_size": "1.8L",
                            "fuel_type": "Petrol",
                            "part_category": "Filter"
                        }
                    },
                    {
                        'name': 'Brake System',
                        'description': 'Brake pads, discs, and brake system components',
                        'template_schema': {
                            "brake_type": {"type": "string", "enum": ["Disc", "Drum", "ABS"]},
                            "position": {"type": "string", "enum": ["Front", "Rear", "All"]},
                            "material": {"type": "string", "enum": ["Ceramic", "Semi-metallic", "Organic"]}
                        },
                        'example_data': {
                            "manufacturer": "Toyota",
                            "make_model": "Corolla 2018",
                            "part_name": "Brake Pads Front",
                            "brake_type": "Disc",
                            "position": "Front",
                            "material": "Ceramic"
                        }
                    }
                ]

            # Electronics Templates
            elif category_type == 'ELECTRONICS':
                templates = [
                    {
                        'name': 'Home Appliances',
                        'description': 'Washing machines, refrigerators, dishwashers',
                        'template_schema': {
                            "appliance_category": {"type": "string",
                                                   "enum": ["Washing Machine", "Refrigerator", "Dishwasher",
                                                            "Microwave"]},
                            "capacity": {"type": "string"},
                            "energy_rating": {"type": "string"},
                            "color_preference": {"type": "array", "items": {"type": "string"}}
                        },
                        'example_data': {
                            "electronics_type": "Washing Machine",
                            "brand_preference": "Samsung",
                            "appliance_category": "Washing Machine",
                            "capacity": "7kg",
                            "energy_rating": "A+++",
                            "color_preference": ["White", "Silver"]
                        }
                    }
                ]

            # Tyres & Rims Templates
            elif category_type == 'TYRES_RIMS':
                templates = [
                    {
                        'name': 'Passenger Car Tyres',
                        'description': 'Standard tyres for passenger vehicles',
                        'template_schema': {
                            "season_type": {"type": "string", "enum": ["All Season", "Summer", "Winter"]},
                            "tyre_brand_preference": {"type": "array", "items": {"type": "string"}},
                            "performance_category": {"type": "string",
                                                     "enum": ["Economy", "Performance", "Ultra-High Performance"]}
                        },
                        'example_data': {
                            "tyre_width": "205",
                            "sidewall_profile": "55",
                            "rim_diameter": "16",
                            "select_type": "Tyres",
                            "vehicle_type": "Passenger Car",
                            "season_type": "All Season",
                            "performance_category": "Economy"
                        }
                    }
                ]

            else:
                continue  # Skip unknown category types

            # Create templates for this category
            for template_data in templates:
                template, created = ProductSpecificationTemplate.objects.get_or_create(
                    category=category,
                    name=template_data['name'],
                    defaults={
                        'description': template_data['description'],
                        'template_schema': template_data['template_schema'],
                        'example_data': template_data['example_data']
                    }
                )

                if created:
                    self.stdout.write(f"Created template: {category.name} - {template.name}")
                else:
                    self.stdout.write(f"Template already exists: {category.name} - {template.name}")