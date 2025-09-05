from django.apps import AppConfig
from django.db.models.signals import post_migrate
import logging

logger = logging.getLogger(__name__)


class AnalyticsConfig(AppConfig):
    """
    Analytics application configuration for the BIDR Product Management Service.
    
    This app provides comprehensive analytics and reporting functionality:
    - Product request analytics and metrics
    - Category performance analysis
    - User behavior tracking
    - Search analytics and optimization
    - Sales and conversion tracking
    - Business intelligence dashboards
    - Real-time and historical reporting
    """
    
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'analytics'
    verbose_name = 'Analytics & Reporting'
    
    def ready(self):
        """
        Called when the app is ready.
        Sets up analytics configurations and connects signals.
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
            
            # Setup analytics configurations
            self._setup_analytics_configurations()
    
    def _setup_analytics_configurations(self):
        """
        Setup analytics configurations and default settings.
        """
        try:
            from django.conf import settings
            
            analytics_settings = getattr(settings, 'ANALYTICS_SETTINGS', {})
            
            if analytics_settings.get('ENABLE_ANALYTICS', True):
                logger.info("Analytics tracking is enabled")
                
                # Setup default analytics configurations
                batch_size = analytics_settings.get('ANALYTICS_BATCH_SIZE', 100)
                processing_interval = analytics_settings.get('ANALYTICS_PROCESSING_INTERVAL', 3600)
                
                logger.debug(f"Analytics batch size: {batch_size}")
                logger.debug(f"Analytics processing interval: {processing_interval}s")
            else:
                logger.info("Analytics tracking is disabled")
            
        except Exception as e:
            logger.error(f"Error setting up analytics configurations: {e}")
