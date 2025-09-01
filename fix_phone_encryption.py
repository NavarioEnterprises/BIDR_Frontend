#!/usr/bin/env python
"""
Script to fix corrupted phone number encryption in the database
"""
import os
import sys
import django

# Add authentication service to Python path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'authentication_service'))

# Setup Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'authentication_service.settings')

try:
    django.setup()
    
    from user.models import AppUser
    from security.utils import security_utils
    import base64
    
    print("=== Phone Number Encryption Fix ===")
    print("===================================\n")
    
    # Get all users
    users = AppUser.objects.all()
    
    print(f"Total users in database: {users.count()}")
    
    fixed_count = 0
    plain_text_count = 0
    already_encrypted_count = 0
    error_count = 0
    
    for user in users:
        if not user.phone_number:
            continue
            
        print(f"Processing user: {user.email}")
        
        # Check current status
        try:
            # Try to decrypt - if this works, it's already properly encrypted
            decrypted = security_utils.encryption.decrypt_pii(user.phone_number)
            print(f"  ✅ Already properly encrypted: '{decrypted}'")
            already_encrypted_count += 1
            continue
            
        except Exception:
            pass
        
        # Check if it's base64 encoded (corrupted encryption) or plain text
        try:
            base64.urlsafe_b64decode(user.phone_number.encode())
            print(f"  ❌ Corrupted encrypted data detected")
            
            # This appears to be corrupted encrypted data
            # We need to determine what the original phone number was
            # Since we can't decrypt it, we'll mark it for manual review
            print(f"  ⚠️  Cannot recover original phone number from corrupted data")
            print(f"     Raw value: {user.phone_number[:50]}...")
            error_count += 1
            continue
            
        except Exception:
            # This is likely plain text
            phone_number = user.phone_number.strip()
            print(f"  ⚠️  Plain text detected: '{phone_number}'")
            
            # Re-encrypt the plain text phone number
            try:
                # Temporarily disable automatic encryption during save
                original_phone = user.phone_number
                
                # Clear the phone number and manually encrypt it
                user.phone_number = None
                encrypted_phone = security_utils.encryption.encrypt_pii(original_phone)
                
                # Update directly in database to avoid double encryption
                AppUser.objects.filter(id=user.id).update(phone_number=encrypted_phone)
                
                # Verify the fix worked
                user.refresh_from_db()
                test_decrypt = user.get_decrypted_phone_number()
                
                if test_decrypt == original_phone:
                    print(f"  ✅ Successfully re-encrypted: '{original_phone}'")
                    fixed_count += 1
                else:
                    print(f"  ❌ Re-encryption verification failed")
                    error_count += 1
                    
            except Exception as e:
                print(f"  ❌ Failed to re-encrypt: {str(e)}")
                error_count += 1
    
    print(f"\n=== Summary ===")
    print(f"Already properly encrypted: {already_encrypted_count}")
    print(f"Fixed plain text entries: {fixed_count}")
    print(f"Corrupted entries (need manual review): {error_count - fixed_count if error_count > fixed_count else 0}")
    print(f"Total errors encountered: {error_count}")
    
    if fixed_count > 0:
        print(f"\n✅ Successfully fixed {fixed_count} phone number encryption issues!")
        
    if error_count > fixed_count:
        corrupted_count = error_count - fixed_count
        print(f"\n⚠️  {corrupted_count} entries have corrupted encryption that cannot be automatically fixed.")
        print("   These entries will fall back to returning the encrypted string as-is.")
        print("   You may need to ask users to re-enter their phone numbers.")

except ImportError as e:
    print(f"Import error: {e}")
except Exception as e:
    print(f"Unexpected error: {e}")
    import traceback
    traceback.print_exc()