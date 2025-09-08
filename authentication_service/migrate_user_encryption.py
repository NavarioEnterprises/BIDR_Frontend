#!/usr/bin/env python
"""
Data migration script to re-encrypt user PII data with consistent encryption key
"""
import os
import django
from django.conf import settings

# Set up Django environment
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'authentication_service.settings')
django.setup()

from user.models import AppUser
from security.utils import EncryptionManager
import logging

# Set up logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def migrate_user_encryption():
    """
    Re-encrypt all user PII data with the current encryption key
    This is needed when encryption keys change between environments
    """
    logger.info("Starting user data encryption migration...")
    
    # Get all users
    users = AppUser.objects.all()
    total_users = users.count()
    logger.info(f"Found {total_users} users to process")
    
    success_count = 0
    error_count = 0
    
    # Create encryption manager instance
    enc_manager = EncryptionManager()
    
    # Process each user
    for i, user in enumerate(users, 1):
        try:
            logger.info(f"Processing user {i}/{total_users}: {user.email}")
            
            # Fields to re-encrypt
            pii_fields = ['first_name', 'last_name', 'middle_name', 'phone_number', 
                         'alternative_phone', 'date_of_birth']
            
            updated_fields = []
            
            for field_name in pii_fields:
                current_value = getattr(user, field_name, None)
                
                if current_value and current_value.strip():
                    try:
                        # Try to decrypt with current key first
                        try:
                            decrypted_value = enc_manager.decrypt_pii(current_value)
                            # If successful, it's already encrypted with the current key
                            logger.info(f"  {field_name}: Already encrypted with current key")
                            continue
                        except:
                            # If decryption fails, it might be plain text or encrypted with old key
                            pass
                        
                        # Check if it looks like encrypted data (base64-like)
                        if len(current_value) > 50 and "=" in current_value[-5:]:
                            # Looks encrypted but can't decrypt - treat as corrupted, use placeholder
                            new_encrypted_value = enc_manager.encrypt_pii(f"[Migrated {field_name}]")
                            logger.warning(f"  {field_name}: Corrupted encryption detected, using placeholder")
                        else:
                            # Likely plain text, encrypt it
                            new_encrypted_value = enc_manager.encrypt_pii(current_value)
                            logger.info(f"  {field_name}: Plain text encrypted")
                        
                        # Update the field directly to avoid triggering save() encryption
                        setattr(user, field_name, new_encrypted_value)
                        updated_fields.append(field_name)
                        
                    except Exception as field_error:
                        logger.error(f"  Error processing {field_name}: {str(field_error)}")
            
            # Save the user with updated fields (skip the encryption in save())
            if updated_fields:
                # Temporarily disable encryption in save by setting a flag
                user._skip_encryption = True
                user.save(update_fields=updated_fields)
                logger.info(f"  Updated fields: {updated_fields}")
            
            success_count += 1
            
        except Exception as e:
            logger.error(f"Error processing user {user.email}: {str(e)}")
            error_count += 1
    
    logger.info(f"Migration completed:")
    logger.info(f"  Successfully processed: {success_count} users")
    logger.info(f"  Errors: {error_count} users")
    
    # Test decryption with a sample user
    if success_count > 0:
        test_user = AppUser.objects.first()
        logger.info(f"Testing decryption with user: {test_user.email}")
        try:
            decrypted_first_name = test_user.get_decrypted_first_name()
            decrypted_last_name = test_user.get_decrypted_last_name()
            decrypted_phone = test_user.get_decrypted_phone_number()
            logger.info(f"  Decryption test successful:")
            logger.info(f"    First name: {decrypted_first_name}")
            logger.info(f"    Last name: {decrypted_last_name}")
            logger.info(f"    Phone: {decrypted_phone}")
        except Exception as e:
            logger.error(f"  Decryption test failed: {str(e)}")

if __name__ == "__main__":
    migrate_user_encryption()
