#!/usr/bin/env python
"""
Test the improved phone number decryption with better error handling
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
    
    print("=== Testing Improved Phone Number Decryption ===")
    print("===============================================\n")
    
    # Get a few test users
    users = AppUser.objects.all()[:5]
    
    for user in users:
        print(f"Testing user: {user.email}")
        
        if user.phone_number:
            print(f"  Raw phone_number: '{user.phone_number[:50]}...'")
            
            try:
                decrypted = user.get_decrypted_phone_number()
                print(f"  Decrypted result: '{decrypted}'")
                
                if decrypted == "[ENCRYPTED - CORRUPTED]":
                    print(f"  Status: ⚠️  Corrupted encryption detected and handled gracefully")
                elif decrypted and not decrypted.startswith('Z0FBQUFB'):  # Not the base64 encrypted string
                    print(f"  Status: ✅ Successfully decrypted or plain text")
                else:
                    print(f"  Status: ❓ Unexpected result")
                    
            except Exception as e:
                print(f"  Error: {str(e)}")
                print(f"  Status: ❌ Exception occurred")
        else:
            print("  No phone number")
            
        print()

except ImportError as e:
    print(f"Import error: {e}")
except Exception as e:
    print(f"Unexpected error: {e}")
    import traceback
    traceback.print_exc()