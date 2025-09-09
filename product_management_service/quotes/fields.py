"""
Custom fields for handling seller references from authentication service.
"""

from django.db import models
from django.contrib.auth.models import User
import uuid


class SellerReferenceField(models.CharField):
    """
    A field that stores seller references as UUIDs from the authentication service.
    Provides backward compatibility with integer User IDs during migration.
    """
    
    def __init__(self, *args, **kwargs):
        kwargs['max_length'] = 255  # UUID string length + buffer
        kwargs['help_text'] = kwargs.get('help_text', 'Seller UUID from authentication service')
        super().__init__(*args, **kwargs)
    
    def to_python(self, value):
        """Convert the value to a string UUID."""
        if value is None:
            return value
        
        # Handle UUID objects
        if isinstance(value, uuid.UUID):
            return str(value)
        
        # Handle User objects (for backward compatibility)
        if isinstance(value, User):
            # Try to get the seller UUID from auth service
            from core.auth_service import auth_client
            
            # First check if we have an auth_user_uid stored
            seller_data = auth_client.get_seller_by_auth_user_uid(str(value.id))
            if seller_data:
                seller_id = (
                    seller_data.get('id') or 
                    seller_data.get('seller_id') or 
                    seller_data.get('seller', {}).get('id')
                )
                if seller_id:
                    return str(seller_id)
            
            # Fallback to user ID as string
            return f"local_user_{value.id}"
        
        # Convert to string
        return str(value)
    
    def from_db_value(self, value, expression, connection):
        """Convert from database value."""
        return value
    
    def get_prep_value(self, value):
        """Prepare value for database storage."""
        value = super().get_prep_value(value)
        return self.to_python(value)


class HybridSellerField(models.CharField):
    """
    A transitional field that can handle both integer User IDs and UUID seller IDs.
    This helps during migration from local users to authentication service.
    """
    
    def __init__(self, *args, **kwargs):
        kwargs['max_length'] = 255
        kwargs['help_text'] = kwargs.get(
            'help_text', 
            'Seller reference (UUID from auth service or local user ID)'
        )
        super().__init__(*args, **kwargs)
    
    def to_python(self, value):
        """Convert value to appropriate format."""
        if value is None:
            return value
        
        # If it's already a string, return it
        if isinstance(value, str):
            return value
        
        # If it's a User object, convert to ID string
        if isinstance(value, User):
            return str(value.id)
        
        # If it's a UUID, convert to string
        if isinstance(value, uuid.UUID):
            return str(value)
        
        # Convert any other type to string
        return str(value)
    
    def get_seller_info(self, value):
        """
        Get seller information from either local user or auth service.
        
        Returns:
            dict: Seller information or None
        """
        if not value:
            return None
        
        from core.auth_service import get_seller_basic_info
        
        # First try as UUID from auth service
        try:
            uuid.UUID(value)
            return get_seller_basic_info(value)
        except ValueError:
            pass
        
        # Check if it's a local user ID format
        if value.startswith('local_user_'):
            user_id = value.replace('local_user_', '')
            try:
                user = User.objects.get(id=int(user_id))
                return {
                    'seller_id': value,
                    'seller_name': user.get_full_name() or user.username,
                    'seller_email': user.email,
                    'vendor_id': f'LOCAL_{user.id}',
                    'approval_status': 'local',
                    'average_rating': None,
                    'is_verified': user.is_active
                }
            except (User.DoesNotExist, ValueError):
                pass
        
        # Try as integer user ID (backward compatibility)
        try:
            user_id = int(value)
            user = User.objects.get(id=user_id)
            return {
                'seller_id': str(user_id),
                'seller_name': user.get_full_name() or user.username,
                'seller_email': user.email,
                'vendor_id': f'LOCAL_{user.id}',
                'approval_status': 'local',
                'average_rating': None,
                'is_verified': user.is_active
            }
        except (ValueError, User.DoesNotExist):
            pass
        
        # Fallback
        return {
            'seller_id': value,
            'seller_name': f'Seller {value}',
            'seller_email': None,
            'vendor_id': None,
            'approval_status': 'unknown',
            'average_rating': None,
            'is_verified': False
        }