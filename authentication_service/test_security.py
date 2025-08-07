#!/usr/bin/env python
"""
Test script for encryption and password security functionality
"""
import os
import sys

# Add the authentication_service to Python path
sys.path.append('/Users/thulanimoyo/BIDR_Backend/authentication_service')

# Set up Django settings
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'authentication_service.settings')

import django
django.setup()

from security.utils import security_utils
from user.models import AppUser
from django.contrib.auth.hashers import make_password, check_password

def test_encryption():
    """Test PII encryption and decryption"""
    print("=== Testing PII Encryption/Decryption ===")
    
    # Test data
    test_data = {
        'first_name': 'John',
        'last_name': 'Doe',
        'phone_number': '+1-555-123-4567'
    }
    
    # Test encryption
    encrypted_data = security_utils.secure_user_data(test_data)
    print(f"Original data: {test_data}")
    print(f"Encrypted data: {encrypted_data}")
    
    # Test decryption
    decrypted_data = security_utils.decrypt_user_data(encrypted_data)
    print(f"Decrypted data: {decrypted_data}")
    
    # Verify data integrity
    for key in test_data:
        if test_data[key] == decrypted_data[key]:
            print(f"✓ {key}: Encryption/decryption successful")
        else:
            print(f"✗ {key}: Encryption/decryption failed")
    
    print()

def test_password_hashing():
    """Test password hashing and verification"""
    print("=== Testing Password Hashing ===")
    
    test_password = "TestPassword123!"
    
    # Hash password
    hashed_password = security_utils.password.hash_password(test_password)
    print(f"Original password: {test_password}")
    print(f"Hashed password: {hashed_password}")
    
    # Verify correct password
    is_valid = security_utils.password.verify_password(test_password, hashed_password)
    print(f"Password verification (correct): {is_valid}")
    
    # Verify incorrect password
    is_invalid = security_utils.password.verify_password("WrongPassword", hashed_password)
    print(f"Password verification (incorrect): {is_invalid}")
    
    print()

def test_password_strength():
    """Test password strength validation"""
    print("=== Testing Password Strength Validation ===")
    
    test_passwords = [
        "weak",
        "StrongPass123!",
        "NoNumbers!",
        "nonumbers123!",
        "NOLOWERCASE123!",
        "NoSpecialChars123"
    ]
    
    for password in test_passwords:
        result = security_utils.validate_password_strength(password)
        print(f"Password: '{password}'")
        print(f"  Valid: {result['is_valid']}")
        print(f"  Strength Score: {result['strength_score']}/5")
        if result['errors']:
            print(f"  Errors: {', '.join(result['errors'])}")
        print()

def test_direct_encryption():
    """Test direct encryption methods"""
    print("=== Testing Direct Encryption Methods ===")
    
    original_text = "Sensitive PII Data 123"
    
    # Encrypt
    encrypted_text = security_utils.encryption.encrypt_pii(original_text)
    print(f"Original: {original_text}")
    print(f"Encrypted: {encrypted_text}")
    
    # Decrypt
    decrypted_text = security_utils.encryption.decrypt_pii(encrypted_text)
    print(f"Decrypted: {decrypted_text}")
    
    # Verify
    if original_text == decrypted_text:
        print("✓ Direct encryption/decryption successful")
    else:
        print("✗ Direct encryption/decryption failed")
    
    print()

def test_user_model_integration():
    """Test AppUser model with encryption"""
    print("=== Testing AppUser Model Integration ===")
    
    try:
        # Note: This is a simulation - we won't actually save to database
        # Create a user instance (without saving)
        test_user_data = {
            'email': 'test@example.com',
            'first_name': 'Alice',
            'last_name': 'Smith',
            'phone_number': '+1-555-987-6543',
            'role': 'buyer'
        }
        
        print(f"Test user data: {test_user_data}")
        
        # Test password validation
        try:
            validation_result = security_utils.validate_password_strength("ValidPass123!")
            print(f"Password validation: {validation_result}")
        except Exception as e:
            print(f"Password validation error: {e}")
        
        # Test encryption methods directly
        encrypted_first_name = security_utils.encryption.encrypt_pii(test_user_data['first_name'])
        encrypted_last_name = security_utils.encryption.encrypt_pii(test_user_data['last_name'])
        encrypted_phone = security_utils.encryption.encrypt_pii(test_user_data['phone_number'])
        
        print(f"Encrypted first name: {encrypted_first_name}")
        print(f"Encrypted last name: {encrypted_last_name}")
        print(f"Encrypted phone: {encrypted_phone}")
        
        # Test decryption
        decrypted_first_name = security_utils.encryption.decrypt_pii(encrypted_first_name)
        decrypted_last_name = security_utils.encryption.decrypt_pii(encrypted_last_name)
        decrypted_phone = security_utils.encryption.decrypt_pii(encrypted_phone)
        
        print(f"Decrypted first name: {decrypted_first_name}")
        print(f"Decrypted last name: {decrypted_last_name}")
        print(f"Decrypted phone: {decrypted_phone}")
        
        # Verify integrity
        if (test_user_data['first_name'] == decrypted_first_name and
            test_user_data['last_name'] == decrypted_last_name and
            test_user_data['phone_number'] == decrypted_phone):
            print("✓ User model encryption integration test successful")
        else:
            print("✗ User model encryption integration test failed")
        
    except Exception as e:
        print(f"User model integration test error: {e}")
    
    print()

if __name__ == "__main__":
    print("Starting Security System Tests...")
    print("=" * 50)
    
    try:
        test_direct_encryption()
        test_encryption()
        test_password_hashing()
        test_password_strength()
        test_user_model_integration()
        
        print("=" * 50)
        print("All security tests completed!")
        
    except Exception as e:
        print(f"Test failed with error: {e}")
        import traceback
        traceback.print_exc()
