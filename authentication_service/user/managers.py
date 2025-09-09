"""
Custom User Manager for BIDR Authentication Service
"""
from django.contrib.auth.models import BaseUserManager
from django.conf import settings
import sys


class AppUserManager(BaseUserManager):
    """
    Custom user manager for AppUser model
    """
    
    def create_user(self, email, password=None, **extra_fields):
        """
        Create and return a regular user with an email and password.
        """
        if not email:
            raise ValueError('The Email field must be set')
        
        email = self.normalize_email(email).lower()
        user = self.model(email=email, **extra_fields)
        
        # Use test-friendly password setting during tests
        if 'test' in sys.argv or hasattr(settings, 'TESTING'):
            user.set_password_for_testing(password)
        else:
            user.set_password(password)
            
        user.save(using=self._db)
        return user
    
    def create_superuser(self, email, password=None, **extra_fields):
        """
        Create and return a superuser with an email and password.
        """
        extra_fields.setdefault('is_staff', True)
        extra_fields.setdefault('is_superuser', True)
        extra_fields.setdefault('is_active', True)
        
        if extra_fields.get('is_staff') is not True:
            raise ValueError('Superuser must have is_staff=True.')
        if extra_fields.get('is_superuser') is not True:
            raise ValueError('Superuser must have is_superuser=True.')
        
        return self.create_user(email, password, **extra_fields)
    
    def get_by_email(self, email):
        """
        Get user by email (case-insensitive)
        """
        return self.get(email__iexact=email.lower().strip())
    
    def email_exists(self, email):
        """
        Check if email exists (case-insensitive)
        """
        return self.filter(email__iexact=email.lower().strip()).exists()
