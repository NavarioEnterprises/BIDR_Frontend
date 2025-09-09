"""
User Signals for BIDR Authentication Service

Handles user-related signals like user creation, profile updates, etc.
"""
from django.db.models.signals import post_save
from django.dispatch import receiver
from django.contrib.auth import get_user_model

User = get_user_model()


@receiver(post_save, sender=User)
def user_post_save(sender, instance, created, **kwargs):
    """
    Signal receiver for when a user is created or updated
    """
    if created:
        # Handle new user creation
        # You can add logic here like:
        # - Send welcome email
        # - Create user profile
        # - Set default permissions
        pass
    else:
        # Handle user updates
        pass
