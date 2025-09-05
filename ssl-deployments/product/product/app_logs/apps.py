from django.apps import AppConfig
from django.db.models.signals import post_migrate
import logging

logger = logging.getLogger(__name__)


class AppLogsConfig(AppConfig):
    """
    Application configuration for the App Logs application.
    
    This app provides comprehensive logging functionality for the BIDR
    Product Management Service, including:
    - API request logging and monitoring
    - Application event logging
    - Error and exception tracking
    - Performance monitoring
    - Category and product request logging
    """
    
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'app_logs'
    verbose_name = 'Application Logs'
    
    def ready(self):
        """
        Called when the app is ready.
        Sets up logging configurations and connects signals.
        """
        # Import signals to ensure they are connected
        try:
            from . import signals
            logger.info(f"{self.verbose_name} app signals connected successfully")
        except ImportError:
            logger.debug(f"No signals module found for {self.verbose_name} app")
        
        # Connect post-migration signal for setup tasks
        post_migrate.connect(self.post_migrate_handler, sender=self)
        
        logger.info(f"{self.verbose_name} app is ready")
    
    def post_migrate_handler(self, sender, **kwargs):
        """
        Handle post-migration setup tasks.
        """
        if sender.name == self.name:
            logger.info(f"Running post-migration setup for {self.verbose_name}")
            
            # Any setup tasks after migration can be added here
            # For example: creating default log categories, cleanup tasks, etc.
            self._setup_default_configurations()
    
    def _setup_default_configurations(self):
        """
        Setup default configurations for the logging system.
        """
        try:
            # Example: Create default log retention policies
            # This could be expanded based on requirements
            logger.debug("Setting up default logging configurations")
            
            # You can add default setup logic here
            # For example:
            # - Creating default log retention policies
            # - Setting up log cleanup schedules
            # - Configuring default alert thresholds
            
        except Exception as e:
            logger.error(f"Error setting up default configurations: {e}")
