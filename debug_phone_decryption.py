#!/usr/bin/env python
"""
Debug script to investigate phone number decryption issues
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
    
    print("=== Phone Number Decryption Debug ===")
    print("=====================================\n")
    
    # Get all users
    users = AppUser.objects.all()[:10]  # Limit to first 10 users
    
    print(f"Total users in database: {AppUser.objects.count()}")
    print(f"Checking first {len(users)} users:\n")
    
    for i, user in enumerate(users, 1):
        print(f"User {i}: {user.email}")
        print(f"  Raw phone_number: '{user.phone_number}'")
        
        if user.phone_number:
            # Check if the phone number looks like base64 encoded data
            try:
                # Try to decode as base64 to see if it's encrypted data
                decoded = base64.urlsafe_b64decode(user.phone_number.encode())
                print(f"  Base64 decodable: Yes (length: {len(decoded)} bytes)")
                
                # Try to decrypt using the security utils
                try:
                    decrypted = security_utils.encryption.decrypt_pii(user.phone_number)
                    print(f"  Decrypted phone: '{decrypted}'")
                    print(f"  Status: ✅ Properly encrypted and decryptable")
                except Exception as e:
                    print(f"  Decryption error: {str(e)}")
                    print(f"  Status: ❌ Encrypted but not decryptable")
                    
                    # Try the model's method
                    try:
                        decrypted_via_model = user.get_decrypted_phone_number()
                        print(f"  Model method result: '{decrypted_via_model}'")
                        print(f"  Status: ⚠️  Model fallback worked")
                    except Exception as e2:
                        print(f"  Model method error: {str(e2)}")
                        print(f"  Status: ❌ Both methods failed")
                
            except Exception as e:
                print(f"  Base64 decodable: No ({str(e)})")
                print(f"  Status: ⚠️  Likely unencrypted plain text")
                
                # Try using the model method which has fallback logic
                try:
                    result = user.get_decrypted_phone_number()
                    print(f"  Model method result: '{result}'")
                    print(f"  Status: ✅ Fallback to plain text worked")
                except Exception as e2:
                    print(f"  Model method error: {str(e2)}")
                    print(f"  Status: ❌ Complete failure")
        else:
            print(f"  Status: ⚠️  Empty/null phone number")
            
        print()
    
    print("=== Encryption Test ===")
    print("=======================\n")
    
    # Test encryption and decryption with a sample phone number
    test_phone = "0683289404"
    print(f"Test phone number: '{test_phone}'")
    
    try:
        encrypted = security_utils.encryption.encrypt_pii(test_phone)
        print(f"Encrypted: '{encrypted}'")
        
        decrypted = security_utils.encryption.decrypt_pii(encrypted)
        print(f"Decrypted: '{decrypted}'")
        
        if decrypted == test_phone:
            print("Status: ✅ Encryption/decryption working correctly")
        else:
            print("Status: ❌ Encryption/decryption mismatch")
            
    except Exception as e:
        print(f"Encryption test failed: {str(e)}")
        print("Status: ❌ Encryption system not working")
    
    print("\n=== Analysis Summary ===")
    print("========================")
    
    encrypted_count = 0
    unencrypted_count = 0
    error_count = 0
    
    for user in users:
        if not user.phone_number:
            continue
            
        try:
            # Check if it's properly encrypted by trying to decrypt
            security_utils.encryption.decrypt_pii(user.phone_number)
            encrypted_count += 1
        except:
            try:
                # Check if it's base64 encoded but corrupted
                base64.urlsafe_b64decode(user.phone_number.encode())
                error_count += 1  # Base64 but not decryptable
            except:
                unencrypted_count += 1  # Plain text
    
    print(f"Properly encrypted: {encrypted_count}")
    print(f"Unencrypted (plain text): {unencrypted_count}")
    print(f"Corrupted/invalid encryption: {error_count}")
    
    if error_count > 0:
        print("\n⚠️  ISSUE FOUND: Some phone numbers are in corrupted encrypted format!")
        print("   This is likely causing the 'Incorrect padding' errors.")
        print("   These need to be re-encrypted or migrated.")
    
    if unencrypted_count > 0:
        print("\n⚠️  ISSUE FOUND: Some phone numbers are stored as plain text!")
        print("   These should be encrypted for security compliance.")

except ImportError as e:
    print(f"Import error: {e}")
except Exception as e:
    print(f"Unexpected error: {e}")
    import traceback
    traceback.print_exc()