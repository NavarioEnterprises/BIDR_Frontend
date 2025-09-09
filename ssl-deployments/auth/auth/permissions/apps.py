from django.apps import AppConfig


class PermissionsConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'permissions'
    verbose_name = 'BIDR Permissions & Roles'
    
    def ready(self):
        """Perform initialization tasks when the app is ready."""
        pass
