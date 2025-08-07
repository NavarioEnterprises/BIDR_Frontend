"""
Security utilities for encryption/decryption and password management
"""
import base64
import hashlib
import secrets
from typing import Optional, Union
from cryptography.fernet import Fernet
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC
from django.conf import settings
from django.contrib.auth.hashers import make_password, check_password
import logging

logger = logging.getLogger(__name__)


class EncryptionManager:
    """
    Manages encryption and decryption of personally identifiable information (PII)
    """
    
    def __init__(self):
        self._fernet = None
        self._key = None
        
    def _get_encryption_key(self) -> bytes:
        """
        Get or generate encryption key for PII encryption
        """
        if self._key is None:
            # In production, this should be stored securely (e.g., environment variable, key management service)
            encryption_key = getattr(settings, 'PII_ENCRYPTION_KEY', None)
            
            if encryption_key:
                # Use provided key
                self._key = encryption_key.encode()
            else:
                # Generate a key from a password (for development)
                password = getattr(settings, 'SECRET_KEY', 'default-dev-key').encode()
                salt = b'bidr_auth_salt_2025'  # In production, use a random salt stored securely
                
                kdf = PBKDF2HMAC(
                    algorithm=hashes.SHA256(),
                    length=32,
                    salt=salt,
                    iterations=100000,
                )
                self._key = base64.urlsafe_b64encode(kdf.derive(password))
                
        return self._key
    
    def _get_fernet(self) -> Fernet:
        """
        Get Fernet instance for encryption/decryption
        """
        if self._fernet is None:
            key = self._get_encryption_key()
            self._fernet = Fernet(key)
        return self._fernet
    
    def encrypt_pii(self, data: str) -> str:
        """
        Encrypt personally identifiable information
        
        Args:
            data: The PII data to encrypt
            
        Returns:
            Base64 encoded encrypted data
        """
        try:
            if not data or not data.strip():
                return ""
                
            fernet = self._get_fernet()
            encrypted_data = fernet.encrypt(data.encode())
            return base64.urlsafe_b64encode(encrypted_data).decode()
            
        except Exception as e:
            logger.error(f"Failed to encrypt PII: {str(e)}")
            raise ValueError("Encryption failed")
    
    def decrypt_pii(self, encrypted_data: str) -> str:
        """
        Decrypt personally identifiable information
        
        Args:
            encrypted_data: Base64 encoded encrypted data
            
        Returns:
            Decrypted original data
        """
        try:
            if not encrypted_data:
                return ""
                
            fernet = self._get_fernet()
            decoded_data = base64.urlsafe_b64decode(encrypted_data.encode())
            decrypted_data = fernet.decrypt(decoded_data)
            return decrypted_data.decode()
            
        except Exception as e:
            logger.error(f"Failed to decrypt PII: {str(e)}")
            raise ValueError("Decryption failed")
    
    def encrypt_if_needed(self, data: Optional[str]) -> Optional[str]:
        """
        Encrypt data only if it's not already encrypted
        
        Args:
            data: Data to potentially encrypt
            
        Returns:
            Encrypted data or original if already encrypted/empty
        """
        if not data:
            return data
            
        # Simple check to see if data is already encrypted (base64 format)
        try:
            # If we can decrypt it, it's already encrypted
            self.decrypt_pii(data)
            return data
        except:
            # If decryption fails, it's not encrypted yet
            return self.encrypt_pii(data)


class PasswordManager:
    """
    Manages password hashing and verification using Django's built-in hashers
    """
    
    @staticmethod
    def hash_password(password: str) -> str:
        """
        Hash a password using Django's password hashers
        
        Args:
            password: Plain text password
            
        Returns:
            Hashed password
        """
        if not password:
            raise ValueError("Password cannot be empty")
            
        return make_password(password)
    
    @staticmethod
    def verify_password(password: str, hashed_password: str) -> bool:
        """
        Verify a password against its hash
        
        Args:
            password: Plain text password to verify
            hashed_password: Stored hashed password
            
        Returns:
            True if password matches, False otherwise
        """
        if not password or not hashed_password:
            return False
            
        return check_password(password, hashed_password)
    
    @staticmethod
    def generate_secure_password(length: int = 12) -> str:
        """
        Generate a cryptographically secure random password
        
        Args:
            length: Length of the password to generate
            
        Returns:
            Secure random password
        """
        alphabet = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*"
        return ''.join(secrets.choice(alphabet) for _ in range(length))


class DataHasher:
    """
    Provides hashing utilities for data integrity and comparison
    """
    
    @staticmethod
    def hash_data(data: str, salt: Optional[str] = None) -> str:
        """
        Hash data using SHA-256
        
        Args:
            data: Data to hash
            salt: Optional salt for the hash
            
        Returns:
            Hexadecimal hash string
        """
        if salt:
            data = data + salt
            
        return hashlib.sha256(data.encode()).hexdigest()
    
    @staticmethod
    def verify_data_hash(data: str, hash_value: str, salt: Optional[str] = None) -> bool:
        """
        Verify data against its hash
        
        Args:
            data: Original data
            hash_value: Hash to verify against
            salt: Optional salt used in original hash
            
        Returns:
            True if data matches hash, False otherwise
        """
        return DataHasher.hash_data(data, salt) == hash_value
    
    @staticmethod
    def generate_salt(length: int = 16) -> str:
        """
        Generate a random salt for hashing
        
        Args:
            length: Length of the salt
            
        Returns:
            Random salt string
        """
        return secrets.token_hex(length)


class SecurityUtils:
    """
    Combined security utilities for the authentication service
    """
    
    def __init__(self):
        self.encryption = EncryptionManager()
        self.password = PasswordManager()
        self.hasher = DataHasher()
    
    def secure_user_data(self, user_data: dict) -> dict:
        """
        Secure user data by encrypting PII fields
        
        Args:
            user_data: Dictionary containing user data
            
        Returns:
            Dictionary with PII fields encrypted
        """
        # Fields that should be encrypted
        pii_fields = ['first_name', 'last_name', 'phone_number', 'address', 'ssn', 'date_of_birth']
        
        secured_data = user_data.copy()
        
        for field in pii_fields:
            if field in secured_data and secured_data[field]:
                secured_data[field] = self.encryption.encrypt_pii(str(secured_data[field]))
                
        return secured_data
    
    def decrypt_user_data(self, encrypted_data: dict) -> dict:
        """
        Decrypt user data PII fields
        
        Args:
            encrypted_data: Dictionary containing encrypted user data
            
        Returns:
            Dictionary with PII fields decrypted
        """
        pii_fields = ['first_name', 'last_name', 'phone_number', 'address', 'ssn', 'date_of_birth']
        
        decrypted_data = encrypted_data.copy()
        
        for field in pii_fields:
            if field in decrypted_data and decrypted_data[field]:
                try:
                    decrypted_data[field] = self.encryption.decrypt_pii(decrypted_data[field])
                except ValueError:
                    # Field might not be encrypted, leave as is
                    pass
                    
        return decrypted_data
    
    def validate_password_strength(self, password: str) -> dict:
        """
        Validate password strength
        
        Args:
            password: Password to validate
            
        Returns:
            Dictionary with validation results
        """
        result = {
            'is_valid': True,
            'errors': [],
            'strength_score': 0
        }
        
        if len(password) < 8:
            result['errors'].append('Password must be at least 8 characters long')
            result['is_valid'] = False
        else:
            result['strength_score'] += 1
            
        if not any(c.isupper() for c in password):
            result['errors'].append('Password must contain at least one uppercase letter')
            result['is_valid'] = False
        else:
            result['strength_score'] += 1
            
        if not any(c.islower() for c in password):
            result['errors'].append('Password must contain at least one lowercase letter')
            result['is_valid'] = False
        else:
            result['strength_score'] += 1
            
        if not any(c.isdigit() for c in password):
            result['errors'].append('Password must contain at least one number')
            result['is_valid'] = False
        else:
            result['strength_score'] += 1
            
        special_chars = "!@#$%^&*()_+-=[]{}|;:,.<>?"
        if not any(c in special_chars for c in password):
            result['errors'].append('Password must contain at least one special character')
            result['is_valid'] = False
        else:
            result['strength_score'] += 1
            
        return result


# Global security utilities instance
security_utils = SecurityUtils()
