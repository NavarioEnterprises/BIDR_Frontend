"""
Updated Quote model with hybrid seller field support.

This provides a migration path from local User ForeignKey to 
authentication service seller UUIDs.
"""

from django.db import models
from .models import Quote as BaseQuote
from .fields import HybridSellerField
import uuid


class QuoteWithHybridSeller(BaseQuote):
    """
    Quote model with hybrid seller field that supports both local users and auth service sellers.
    
    This is a transitional model to help migrate from ForeignKey(User) to UUID-based sellers.
    """
    
    # Override the seller_id field with hybrid field
    seller_id_hybrid = HybridSellerField(
        db_column='seller_id_text',  # New column to avoid conflicts
        null=True,
        blank=True,
        help_text="Seller reference (UUID or local user ID)"
    )
    
    class Meta:
        db_table = 'quotes_quote'  # Use same table
        managed = False  # Don't create migrations yet
    
    def get_seller_info(self):
        """Get seller information from hybrid field."""
        if self.seller_id_hybrid:
            field = self._meta.get_field('seller_id_hybrid')
            return field.get_seller_info(self.seller_id_hybrid)
        elif self.seller_id:
            # Fallback to original ForeignKey
            return {
                'seller_id': str(self.seller_id.id),
                'seller_name': self.seller_id.get_full_name() or self.seller_id.username,
                'seller_email': self.seller_id.email,
                'vendor_id': f'LOCAL_{self.seller_id.id}',
                'approval_status': 'local',
                'average_rating': None,
                'is_verified': self.seller_id.is_active
            }
        return None
    
    def set_seller_from_auth_service(self, seller_uuid):
        """Set seller from authentication service UUID."""
        self.seller_id_hybrid = str(seller_uuid)
    
    def set_seller_from_user(self, user):
        """Set seller from local User object (backward compatibility)."""
        self.seller_id_hybrid = str(user.id)
        self.seller_id = user  # Also set ForeignKey for compatibility
    
    @property
    def seller_uuid(self):
        """Get seller UUID if available."""
        if self.seller_id_hybrid:
            try:
                return uuid.UUID(self.seller_id_hybrid)
            except ValueError:
                return None
        return None
    
    @property
    def is_auth_service_seller(self):
        """Check if this quote uses auth service seller."""
        if self.seller_id_hybrid:
            try:
                uuid.UUID(self.seller_id_hybrid)
                return True
            except ValueError:
                return False
        return False


# Helper function for migration
def migrate_seller_references(batch_size=100):
    """
    Migrate existing quotes from User ForeignKey to hybrid seller field.
    
    This should be run as a data migration.
    """
    from django.db import transaction
    from .models import Quote
    
    quotes_to_update = Quote.objects.filter(
        seller_id__isnull=False,
        seller_id_hybrid__isnull=True
    )[:batch_size]
    
    with transaction.atomic():
        for quote in quotes_to_update:
            # Try to find seller in auth service
            from core.auth_service import auth_client
            
            seller_data = auth_client.get_seller_by_auth_user_uid(str(quote.seller_id.id))
            if seller_data:
                seller_uuid = (
                    seller_data.get('id') or 
                    seller_data.get('seller_id') or 
                    seller_data.get('seller', {}).get('id')
                )
                if seller_uuid:
                    quote.seller_id_hybrid = str(seller_uuid)
                else:
                    # Fallback to local user ID
                    quote.seller_id_hybrid = f"local_user_{quote.seller_id.id}"
            else:
                # No auth service seller found, use local ID
                quote.seller_id_hybrid = f"local_user_{quote.seller_id.id}"
            
            quote.save(update_fields=['seller_id_hybrid'])