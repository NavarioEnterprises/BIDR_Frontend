from django.apps import AppConfig
from django.db.models.signals import post_migrate
import logging

logger = logging.getLogger(__name__)


class ProductRequestsConfig(AppConfig):
    """
    Product Requests application configuration for the BIDR Product Management Service.
    
    This app manages product requests and provides:
    - Product request creation and management
    - Request specifications for different categories
    - Request workflow and status tracking
    - Request messaging and communication
    - Request analytics and reporting
    - Integration with categories and suppliers
    """
    
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'product_requests'
    verbose_name = 'Product Requests'
    
    def ready(self):
        """
        Called when the app is ready.
        Sets up product request configurations and connects signals.
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
            
            # Setup default configurations
            self._setup_default_configurations()
    
    def _setup_default_configurations(self):
        """
        Setup default configurations for product requests.
        """
        try:
            logger.debug("Setting up default product request configurations")
            
            # Any default setup can be added here
            # For example:
            # - Creating default request statuses
            # - Setting up default urgency levels
            # - Configuring default notification preferences
            # - Creating sample request templates
            
        except Exception as e:
            logger.error(f"Error setting up product request configurations: {e}")
