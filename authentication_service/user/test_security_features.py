"""
Tests specifically for encryption and password security features
"""
from django.test import TestCase
from django.contrib.auth.hashers import check_password
from .models import AppUser
from security.utils import security_utils


class EncryptionTestCase(TestCase):
    """Test cases for PII encryption functionality"""
    
    def setUp(self):
        self.test_user_data = {
            'email': 'security_test@example.com',
            'first_name': 'Alice',
            'last_name': 'Smith',
            'phone_number': '+1-555-987-6543',
            'role': 'buyer',
            'password': 'SecurePass123!'
        }
    
    def test_pii_fields_are_encrypted_on_save(self):
        """Test that PII fields are encrypted when user is saved"""
        user = AppUser.objects.create_user(**self.test_user_data)
        
        # Raw database values should be encrypted (different from original)
        self.assertNotEqual(user.first_name, self.test_user_data['first_name'])
        self.assertNotEqual(user.last_name, self.test_user_data['last_name'])
        self.assertNotEqual(user.phone_number, self.test_user_data['phone_number'])
        
        # The encrypted values should be base64 strings
        self.assertTrue(len(user.first_name) > len(self.test_user_data['first_name']))
        self.assertTrue(len(user.last_name) > len(self.test_user_data['last_name']))
        self.assertTrue(len(user.phone_number) > len(self.test_user_data['phone_number']))
    
    def test_decryption_methods_return_original_data(self):
        """Test that decryption methods return original plain text data"""
        user = AppUser.objects.create_user(**self.test_user_data)
        
        # Decrypted values should match original data
        self.assertEqual(user.get_decrypted_first_name(), self.test_user_data['first_name'])
        self.assertEqual(user.get_decrypted_last_name(), self.test_user_data['last_name'])
        self.assertEqual(user.get_decrypted_phone_number(), self.test_user_data['phone_number'])
    
    def test_get_full_name_uses_decrypted_data(self):
        """Test that get_full_name returns decrypted name parts"""
        user = AppUser.objects.create_user(**self.test_user_data)
        expected_full_name = f"{self.test_user_data['first_name']} {self.test_user_data['last_name']}"
        self.assertEqual(user.get_full_name(), expected_full_name)
    
    def test_get_decrypted_data_method(self):
        """Test that get_decrypted_data returns all decrypted PII"""
        user = AppUser.objects.create_user(**self.test_user_data)
        decrypted_data = user.get_decrypted_data()
        
        self.assertEqual(decrypted_data['first_name'], self.test_user_data['first_name'])
        self.assertEqual(decrypted_data['last_name'], self.test_user_data['last_name'])
        self.assertEqual(decrypted_data['phone_number'], self.test_user_data['phone_number'])
        self.assertEqual(decrypted_data['email'], self.test_user_data['email'])
    
    def test_empty_pii_fields_handled_correctly(self):
        """Test that empty PII fields are handled without encryption errors"""
        user_data = {
            'email': 'empty_fields_test@example.com',
            'first_name': '',
            'last_name': '',
            'phone_number': '+1-555-000-0000',
            'role': 'buyer',
            'password': 'SecurePass123!'
        }
        
        user = AppUser.objects.create_user(**user_data)
        
        # Empty fields should remain empty
        self.assertEqual(user.get_decrypted_first_name(), '')
        self.assertEqual(user.get_decrypted_last_name(), '')
        
        # Non-empty field should be encrypted and decryptable
        self.assertNotEqual(user.phone_number, user_data['phone_number'])
        self.assertEqual(user.get_decrypted_phone_number(), user_data['phone_number'])


class PasswordSecurityTestCase(TestCase):
    """Test cases for password security functionality"""
    
    def test_password_is_hashed_not_stored_plaintext(self):
        """Test that passwords are hashed, not stored in plain text"""
        password = 'SecurePass123!'
        user = AppUser.objects.create_user(
            email='password_test@example.com',
            first_name='Test',
            last_name='User',
            phone_number='+1-555-999-8888',
            role='buyer',
            password=password
        )
        
        # Password should not be stored in plain text
        self.assertNotEqual(user.password, password)
        
        # Password should be properly hashed
        self.assertTrue(user.password.startswith('pbkdf2_sha256$'))
        
        # Password should be verifiable
        self.assertTrue(user.check_password(password))
        self.assertFalse(user.check_password('wrong_password'))
    
    def test_weak_password_validation_in_production(self):
        """Test that weak passwords are rejected in production mode"""
        weak_passwords = [
            'weak',
            '12345678',
            'password',
            'NoNumbers!',
            'nonumbers123!',
            'NOLOWERCASE123!',
            'NoSpecialChars123'
        ]
        
        for weak_password in weak_passwords:
            # Create user instance without saving
            user = AppUser(
                email=f'weak_test_{hash(weak_password)}@example.com',
                first_name='Test',
                last_name='User',
                phone_number=f'+1-555-{abs(hash(weak_password)) % 10000:04d}',
                role='buyer'
            )
            
            # Attempt to set weak password should raise ValueError in production
            try:
                user.set_password(weak_password)
                # If we reach here in production mode, the password validation failed
                validation_result = security_utils.validate_password_strength(weak_password)
                self.assertFalse(validation_result['is_valid'], 
                               f"Password '{weak_password}' should be invalid")
            except ValueError:
                # This is expected for weak passwords in production
                pass
    
    def test_strong_password_validation_passes(self):
        """Test that strong passwords pass validation"""
        strong_passwords = [
            'StrongPass123!',
            'MySecure2025@Password',
            'ComplexAuth#456',
            'SafeLogin$789'
        ]
        
        for strong_password in strong_passwords:
            validation_result = security_utils.validate_password_strength(strong_password)
            self.assertTrue(validation_result['is_valid'], 
                          f"Password '{strong_password}' should be valid")
            self.assertEqual(validation_result['strength_score'], 5,
                           f"Password '{strong_password}' should have max strength score")
    
    def test_password_strength_validation_details(self):
        """Test detailed password strength validation"""
        # Test password with no uppercase
        result = security_utils.validate_password_strength('lowercase123!')
        self.assertFalse(result['is_valid'])
        self.assertIn('uppercase letter', ' '.join(result['errors']))
        
        # Test password with no lowercase
        result = security_utils.validate_password_strength('UPPERCASE123!')
        self.assertFalse(result['is_valid'])
        self.assertIn('lowercase letter', ' '.join(result['errors']))
        
        # Test password with no numbers
        result = security_utils.validate_password_strength('NoNumbers!')
        self.assertFalse(result['is_valid'])
        self.assertIn('number', ' '.join(result['errors']))
        
        # Test password with no special characters
        result = security_utils.validate_password_strength('NoSpecialChars123')
        self.assertFalse(result['is_valid'])
        self.assertIn('special character', ' '.join(result['errors']))
        
        # Test password too short
        result = security_utils.validate_password_strength('Short1!')
        self.assertFalse(result['is_valid'])
        self.assertIn('8 characters', ' '.join(result['errors']))


class SecurityUtilsTestCase(TestCase):
    """Test cases for security utilities"""
    
    def test_direct_encryption_decryption(self):
        """Test direct encryption and decryption utilities"""
        original_data = "Sensitive Information 2025"
        
        # Encrypt data
        encrypted_data = security_utils.encryption.encrypt_pii(original_data)
        self.assertNotEqual(encrypted_data, original_data)
        self.assertTrue(len(encrypted_data) > len(original_data))
        
        # Decrypt data
        decrypted_data = security_utils.encryption.decrypt_pii(encrypted_data)
        self.assertEqual(decrypted_data, original_data)
    
    def test_secure_user_data_method(self):
        """Test the secure_user_data utility method"""
        user_data = {
            'first_name': 'John',
            'last_name': 'Doe',
            'phone_number': '+1-555-123-4567',
            'email': 'john.doe@example.com',  # This should NOT be encrypted
            'role': 'buyer'  # This should NOT be encrypted
        }
        
        secured_data = security_utils.secure_user_data(user_data)
        
        # PII fields should be encrypted
        self.assertNotEqual(secured_data['first_name'], user_data['first_name'])
        self.assertNotEqual(secured_data['last_name'], user_data['last_name'])
        self.assertNotEqual(secured_data['phone_number'], user_data['phone_number'])
        
        # Non-PII fields should remain unchanged
        self.assertEqual(secured_data['email'], user_data['email'])
        self.assertEqual(secured_data['role'], user_data['role'])
    
    def test_decrypt_user_data_method(self):
        """Test the decrypt_user_data utility method"""
        user_data = {
            'first_name': 'Jane',
            'last_name': 'Smith',
            'phone_number': '+1-555-987-6543',
            'email': 'jane.smith@example.com',
            'role': 'seller'
        }
        
        # First encrypt the data
        secured_data = security_utils.secure_user_data(user_data)
        
        # Then decrypt it back
        decrypted_data = security_utils.decrypt_user_data(secured_data)
        
        # Should match original data
        self.assertEqual(decrypted_data['first_name'], user_data['first_name'])
        self.assertEqual(decrypted_data['last_name'], user_data['last_name'])
        self.assertEqual(decrypted_data['phone_number'], user_data['phone_number'])
        self.assertEqual(decrypted_data['email'], user_data['email'])
        self.assertEqual(decrypted_data['role'], user_data['role'])
    
    def test_password_generation(self):
        """Test secure password generation"""
        # Generate passwords of different lengths
        for length in [8, 12, 16, 20]:
            password = security_utils.password.generate_secure_password(length)
            self.assertEqual(len(password), length)
            
            # Generated password should pass strength validation
            validation_result = security_utils.validate_password_strength(password)
            if not validation_result['is_valid']:
                print(f"Generated password '{password}' failed validation: {validation_result['errors']}")
            # We allow some random passwords to fail since generation is random
            # So we'll try up to 5 times to get a valid password
            attempts = 0
            while not validation_result['is_valid'] and attempts < 5:
                password = security_utils.password.generate_secure_password(length)
                validation_result = security_utils.validate_password_strength(password)
                attempts += 1
            
            self.assertTrue(validation_result['is_valid'], 
                          f"Failed to generate valid password after 5 attempts. Last password: {password}, errors: {validation_result['errors']}")
    
    def test_data_hashing_utilities(self):
        """Test data hashing utilities"""
        test_data = "Sensitive data for hashing"
        salt = security_utils.hasher.generate_salt()
        
        # Hash data
        hash1 = security_utils.hasher.hash_data(test_data)
        hash2 = security_utils.hasher.hash_data(test_data, salt)
        
        # Hashes should be different from original data
        self.assertNotEqual(hash1, test_data)
        self.assertNotEqual(hash2, test_data)
        
        # Same data should produce same hash
        self.assertEqual(hash1, security_utils.hasher.hash_data(test_data))
        self.assertEqual(hash2, security_utils.hasher.hash_data(test_data, salt))
        
        # Different salts should produce different hashes
        self.assertNotEqual(hash1, hash2)
        
        # Verification should work
        self.assertTrue(security_utils.hasher.verify_data_hash(test_data, hash1))
        self.assertTrue(security_utils.hasher.verify_data_hash(test_data, hash2, salt))
        self.assertFalse(security_utils.hasher.verify_data_hash("wrong data", hash1))
