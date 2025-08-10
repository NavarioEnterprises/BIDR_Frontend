from django.apps import AppConfig
from django.db.models.signals import post_migrate
import logging

logger = logging.getLogger(__name__)


class CoreConfig(AppConfig):
    """
    Core application configuration for the BIDR Product Management Service.
    
    This app provides foundational functionality including:
    - Base models and mixins
    - Common utilities and helpers
    - Shared business logic
    - Exception handling
    - Encryption utilities
    - Status and choice definitions
    """
    
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'core'
    verbose_name = 'Core Application'
    
    def ready(self):
        """
        Called when the app is ready.
        Sets up core configurations and connects signals.
        """
        # Import signals to ensure they are connected
        try:
            from . import signals
            logger.info(f"{self.verbose_name} signals connected successfully")
        except ImportError:
            logger.debug(f"No signals module found for {self.verbose_name}")
        
        # Connect post-migration signal for setup tasks
        post_migrate.connect(self.post_migrate_handler, sender=self)
        
        # Initialize core components
        self._initialize_core_components()
        
        logger.info(f"{self.verbose_name} is ready")
    
    def post_migrate_handler(self, sender, **kwargs):
        """
        Handle post-migration setup tasks.
        """
        if sender.name == self.name:
            logger.info(f"Running post-migration setup for {self.verbose_name}")
            
            # Setup core configurations after migration
            self._setup_core_configurations()
    
    def _initialize_core_components(self):
        """
        Initialize core application components.
        """
        try:
            # Initialize encryption if enabled
            from django.conf import settings
            encryption_settings = getattr(settings, 'ENCRYPTION_SETTINGS', {})
            
            if encryption_settings.get('USE_ENCRYPTION', False):
                logger.info("Encryption is enabled for core application")
            
            logger.debug("Core components initialized successfully")
            
        except Exception as e:
            logger.error(f"Error initializing core components: {e}")
    
    def _setup_core_configurations(self):
        """
        Setup core configurations after migrations.
        """
        try:
            logger.debug("Setting up core configurations")
            
            # Any post-migration setup can be added here
            # For example:
            # - Creating default system settings
            # - Setting up default permissions
            # - Initializing cache configurations
            
        except Exception as e:
            logger.error(f"Error setting up core configurations: {e}")
