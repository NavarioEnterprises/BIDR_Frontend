from django.apps import AppConfig
from django.db.models.signals import post_migrate
import logging

logger = logging.getLogger(__name__)


class CategoriesConfig(AppConfig):
    """
    Categories application configuration for the BIDR Product Management Service.
    
    This app manages product categories and provides:
    - Hierarchical category structure using MPTT
    - Category specifications and attributes
    - Category-based filtering and organization
    - Category analytics and reporting
    - Dynamic category management
    """
    
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'categories'
    verbose_name = 'Product Categories'
    
    def ready(self):
        """
        Called when the app is ready.
        Sets up category configurations and connects signals.
        """
        # Import signals to ensure they are connected
        try:
            from . import signals
            logger.info(f"{self.verbose_name} signals connected successfully")
        except ImportError:
            logger.debug(f"No signals module found for {self.verbose_name}")
        
        # Connect post-migration signal for setup tasks
        post_migrate.connect(self.post_migrate_handler, sender=self)
        
        logger.info(f"{self.verbose_name} app is ready")
    
    def post_migrate_handler(self, sender, **kwargs):
        """
        Handle post-migration setup tasks.
        """
        if sender.name == self.name:
            logger.info(f"Running post-migration setup for {self.verbose_name}")
            
            # Setup default categories and configurations
            self._setup_default_categories()
    
    def _setup_default_categories(self):
        """
        Create default categories if they don't exist.
        """
        try:
            from .models import Category
            
            # Check if we have any categories
            if not Category.objects.exists():
                logger.info("Creating default categories")
                
                # Create default top-level categories
                default_categories = [
                    {'name': 'Consumer Electronics', 'description': 'Electronic devices for personal use'},
                    {'name': 'Vehicle Parts & Accessories', 'description': 'Parts and accessories for vehicles'},
                    {'name': 'Industrial Equipment', 'description': 'Equipment for industrial use'},
                    {'name': 'Office Supplies', 'description': 'Supplies and equipment for offices'},
                    {'name': 'Home & Garden', 'description': 'Items for home and garden use'},
                ]
                
                for cat_data in default_categories:
                    Category.objects.create(**cat_data)
                
                logger.info(f"Created {len(default_categories)} default categories")
            else:
                logger.debug("Categories already exist, skipping default creation")
                
        except Exception as e:
            logger.error(f"Error setting up default categories: {e}")
