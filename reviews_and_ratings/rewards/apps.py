from django.apps import AppConfig


class RewardsConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'rewards'
    verbose_name = 'Rewards & Referrals'
    
    def ready(self):
        # Import signal handlers
        import rewards.signals
