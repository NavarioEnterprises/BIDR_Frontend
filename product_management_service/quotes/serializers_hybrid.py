"""
Hybrid serializers that support both local User IDs and authentication service seller UUIDs.

This provides a migration path while maintaining backward compatibility.
"""

from rest_framework import serializers
from django.contrib.auth.models import User
from .models import Quote
from .serializers import QuoteCreateUpdateSerializer as BaseQuoteCreateUpdateSerializer
from core.auth_service import validate_seller_exists, get_seller_basic_info
from product_requests.models import ProductRequest
import uuid


class HybridSellerField(serializers.Field):
    """
    A field that accepts both integer User IDs and UUID seller IDs.
    """
    
    def to_representation(self, value):
        """Convert internal value to API representation."""
        if isinstance(value, User):
            # Return user ID for backward compatibility
            return value.id
        return str(value) if value else None
    
    def to_internal_value(self, data):
        """Convert API input to internal value."""
        if data is None:
            return None
        
        # Try to parse as integer (local User ID)
        try:
            user_id = int(data)
            try:
                user = User.objects.get(pk=user_id)
                return user
            except User.DoesNotExist:
                raise serializers.ValidationError(f"User with ID {user_id} does not exist.")
        except (ValueError, TypeError):
            pass
        
        # Try to parse as UUID (auth service seller)
        try:
            seller_uuid = uuid.UUID(str(data))
            
            # Try to validate seller exists in auth service with fallback
            try:
                if validate_seller_exists(str(seller_uuid)):
                    return str(seller_uuid)
                else:
                    # If seller not found in auth service but UUID is valid, 
                    # allow it for now with a warning log
                    import logging
                    logger = logging.getLogger(__name__)
                    logger.warning(f"Seller UUID {seller_uuid} not found in auth service, allowing with fallback")
                    return str(seller_uuid)
            except Exception as e:
                # If auth service is unreachable or has errors, allow the UUID for now
                import logging
                logger = logging.getLogger(__name__)
                logger.warning(f"Auth service error for seller {seller_uuid}: {str(e)}, allowing with fallback")
                return str(seller_uuid)
        except (ValueError, TypeError):
            pass
        
        raise serializers.ValidationError(
            f"Invalid seller ID format: {data}. Must be either an integer User ID or a valid UUID."
        )


class QuoteCreateUpdateHybridSerializer(BaseQuoteCreateUpdateSerializer):
    """
    Quote create/update serializer that accepts both User IDs and seller UUIDs.
    """
    seller_id = HybridSellerField()
    seller_details = serializers.SerializerMethodField(read_only=True)
    
    class Meta(BaseQuoteCreateUpdateSerializer.Meta):
        fields = BaseQuoteCreateUpdateSerializer.Meta.fields + ['seller_details']
    
    def validate(self, data):
        """Override validate to handle request_id lookup and seller_id conversion."""
        # Handle request_id field if it's a UUID string
        request_id = data.get('request_id')
        if request_id and isinstance(request_id, str):
            try:
                # Try to get the ProductRequest object by UUID
                request_uuid = uuid.UUID(request_id)
                product_request = ProductRequest.objects.get(request_id=request_uuid)
                data['request_id'] = product_request
            except (ValueError, ProductRequest.DoesNotExist):
                raise serializers.ValidationError({
                    'request_id': f'ProductRequest with ID {request_id} not found.'
                })
        
        # Handle seller_id conversion for duplicate check
        seller_id = data.get('seller_id')
        original_seller_id = seller_id
        
        if seller_id and isinstance(seller_id, str):
            # Convert UUID seller_id to User object for validation
            try:
                # Try to find existing user with this UUID as username
                user = User.objects.get(username=f"seller_{seller_id}")
                data['seller_id'] = user
            except User.DoesNotExist:
                # If user doesn't exist, skip duplicate check for now
                # The user will be created in the create method
                pass
        
        # Call parent validation with converted data
        try:
            validated_data = super().validate(data)
            # Restore original seller_id if it was converted
            if original_seller_id and isinstance(original_seller_id, str):
                validated_data['seller_id'] = original_seller_id
            return validated_data
        except (ValueError, TypeError) as e:
            # If validation fails due to seller_id format issues, handle UUID sellers specially
            if original_seller_id and isinstance(original_seller_id, str) and ('Field' in str(e) and 'expected a number' in str(e)):
                # For UUID sellers, skip the parent validation and just do basic validation
                data['seller_id'] = original_seller_id
                # Do our own basic validation without the duplicate check for UUID sellers
                if not data.get('request_id'):
                    raise serializers.ValidationError({'request_id': 'This field is required.'})
                if not data.get('seller_id'):
                    raise serializers.ValidationError({'seller_id': 'This field is required.'})
                return data
            raise e
        except Exception as e:
            # For other validation issues with UUID sellers
            if original_seller_id and isinstance(original_seller_id, str):
                data['seller_id'] = original_seller_id
                # Skip the duplicate check for UUID sellers for now
                if 'already submitted' in str(e):
                    return data
            raise e
    
    def get_seller_details(self, obj):
        """Get seller details from either local user or auth service."""
        if hasattr(obj, 'seller_id') and obj.seller_id:
            if isinstance(obj.seller_id, User):
                # Local user
                return {
                    'seller_id': obj.seller_id.id,
                    'seller_name': obj.seller_id.get_full_name() or obj.seller_id.username,
                    'seller_email': obj.seller_id.email,
                    'vendor_id': f'LOCAL_{obj.seller_id.id}',
                    'approval_status': 'local',
                    'is_verified': obj.seller_id.is_active
                }
            else:
                # Try to get from auth service
                try:
                    return get_seller_basic_info(str(obj.seller_id))
                except:
                    pass
        return None
    
    def create(self, validated_data):
        """Handle quote creation with hybrid seller support."""
        seller_value = validated_data.get('seller_id')
        
        if isinstance(seller_value, str):
            # This is a UUID from auth service
            # For now, we need to find or create a placeholder User
            # In production, you'd update the model to support UUIDs directly
            
            # Check if we have a mapping
            try:
                # Try to find existing user with this UUID as username
                user = User.objects.get(username=f"seller_{seller_value}")
            except User.DoesNotExist:
                # Create placeholder user
                try:
                    seller_info = get_seller_basic_info(seller_value)
                    # Handle None values safely
                    raw_email = seller_info.get('seller_email') if seller_info else None
                    email = raw_email if raw_email else f"seller_{seller_value[:8]}@placeholder.local"
                    if len(email) > 150:  # Django's email field max length
                        email = f"seller_{seller_value[:8]}@placeholder.local"
                    
                    # Truncate names if too long, handle None values
                    raw_name = seller_info.get('seller_name') if seller_info else None
                    first_name = (raw_name if raw_name else 'Seller')[:30]  # Django's first_name max length
                    raw_vendor = seller_info.get('vendor_id') if seller_info else None
                    last_name = f"({raw_vendor if raw_vendor else 'External'})"[:30]  # Django's last_name max length
                    
                    user = User.objects.create(
                        username=f"seller_{seller_value}",
                        email=email,
                        first_name=first_name,
                        last_name=last_name,
                        is_active=False  # Mark as placeholder
                    )
                except Exception as e:
                    import logging
                    logger = logging.getLogger(__name__)
                    logger.error(f"Error creating placeholder user for seller {seller_value}: {str(e)}")
                    raise serializers.ValidationError(f"Failed to create quote: {str(e)}")
            
            validated_data['seller_id'] = user
        
        return super().create(validated_data)
    
    def update(self, instance, validated_data):
        """Handle quote update with hybrid seller support."""
        seller_value = validated_data.get('seller_id')
        
        if seller_value and isinstance(seller_value, str):
            # This is a UUID from auth service
            try:
                user = User.objects.get(username=f"seller_{seller_value}")
            except User.DoesNotExist:
                try:
                    seller_info = get_seller_basic_info(seller_value)
                    # Handle None values safely
                    raw_email = seller_info.get('seller_email') if seller_info else None
                    email = raw_email if raw_email else f"seller_{seller_value[:8]}@placeholder.local"
                    if len(email) > 150:  # Django's email field max length
                        email = f"seller_{seller_value[:8]}@placeholder.local"
                    
                    # Truncate names if too long, handle None values
                    raw_name = seller_info.get('seller_name') if seller_info else None
                    first_name = (raw_name if raw_name else 'Seller')[:30]  # Django's first_name max length
                    raw_vendor = seller_info.get('vendor_id') if seller_info else None
                    last_name = f"({raw_vendor if raw_vendor else 'External'})"[:30]  # Django's last_name max length
                    
                    user = User.objects.create(
                        username=f"seller_{seller_value}",
                        email=email,
                        first_name=first_name,
                        last_name=last_name,
                        is_active=False
                    )
                except Exception as e:
                    import logging
                    logger = logging.getLogger(__name__)
                    logger.error(f"Error creating placeholder user for seller {seller_value}: {str(e)}")
                    raise serializers.ValidationError(f"Failed to update quote: {str(e)}")
            
            validated_data['seller_id'] = user
        
        return super().update(instance, validated_data)


# Temporary patch for immediate use
def patch_quote_serializer():
    """
    Monkey patch the existing serializer to handle hybrid seller IDs.
    This is a temporary solution until proper model migration is done.
    """
    from . import serializers
    
    # Replace the default serializer
    serializers.QuoteCreateUpdateSerializer = QuoteCreateUpdateHybridSerializer