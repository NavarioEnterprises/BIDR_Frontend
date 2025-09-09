"""
Encryption utilities for sensitive data in the BIDR Inventory Service.

This module provides encryption/decryption functions for protecting sensitive
information like personal data, financial information, and other PII.
"""

import base64
import hashlib
import secrets
from cryptography.fernet import Fernet
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC
from django.conf import settings
from django.core.exceptions import ImproperlyConfigured
import logging

logger = logging.getLogger(__name__)


class EncryptionService:
    """Service for encrypting and decrypting sensitive data."""
    
    def __init__(self):
        self._fernet = None
        self._initialize_encryption()
    
    def _initialize_encryption(self):
        """Initialize the encryption service with proper key derivation."""
        try:
            # Get encryption settings
            encryption_settings = getattr(settings, 'ENCRYPTION_SETTINGS', {})
            encryption_key = encryption_settings.get('ENCRYPTION_KEY')
            
            # Fallback to old-style setting for backward compatibility
            if not encryption_key:
                encryption_key = getattr(settings, 'ENCRYPTION_KEY', None)
            
            # Use default development key if not set
            if not encryption_key:
                encryption_key = 'dev-key-change-in-production-32-chars'
                logger.warning("Using default encryption key - change for production!")
            
            # Derive key using PBKDF2
            salt = getattr(settings, 'ENCRYPTION_SALT', b'default_salt_change_in_production')
            if isinstance(salt, str):
                salt = salt.encode('utf-8')
            
            kdf = PBKDF2HMAC(
                algorithm=hashes.SHA256(),
                length=32,
                salt=salt,
                iterations=100000,
            )
            
            if isinstance(encryption_key, str):
                encryption_key = encryption_key.encode('utf-8')
            
            key = base64.urlsafe_b64encode(kdf.derive(encryption_key))
            self._fernet = Fernet(key)
            
        except Exception as e:
            # Use minimal encryption for development
            logger.warning(f"Encryption initialization failed: {e}. Using fallback encryption.")
            key = base64.urlsafe_b64encode(b'dev-key-change-in-production-32-chars'[:32].ljust(32, b'0'))
            self._fernet = Fernet(key)
    
    def encrypt(self, data: str) -> str:
        """
        Encrypt sensitive data.
        
        Args:
            data: Plain text data to encrypt
            
        Returns:
            Base64 encoded encrypted data
        """
        if not data:
            return data
        
        try:
            if isinstance(data, str):
                data = data.encode('utf-8')
            
            encrypted_data = self._fernet.encrypt(data)
            return base64.urlsafe_b64encode(encrypted_data).decode('utf-8')
        
        except Exception as e:
            logger.error(f"Encryption failed: {e}")
            raise
    
    def decrypt(self, encrypted_data: str) -> str:
        """
        Decrypt sensitive data.
        
        Args:
            encrypted_data: Base64 encoded encrypted data
            
        Returns:
            Decrypted plain text data
        """
        if not encrypted_data:
            return encrypted_data
        
        try:
            encrypted_bytes = base64.urlsafe_b64decode(encrypted_data.encode('utf-8'))
            decrypted_data = self._fernet.decrypt(encrypted_bytes)
            return decrypted_data.decode('utf-8')
        
        except Exception as e:
            logger.error(f"Decryption failed: {e}")
            # Return encrypted data if decryption fails (for debugging)
            return f"[ENCRYPTED_DATA_DECRYPT_FAILED]"
    
    def hash_data(self, data: str, salt: str = None) -> tuple:
        """
        Hash data with salt for secure storage.
        
        Args:
            data: Data to hash
            salt: Optional salt (will generate if not provided)
            
        Returns:
            Tuple of (hashed_data, salt)
        """
        if salt is None:
            salt = secrets.token_hex(16)
        
        # Combine data and salt
        salted_data = f"{data}{salt}".encode('utf-8')
        
        # Create hash
        hash_obj = hashlib.sha256(salted_data)
        hashed_data = hash_obj.hexdigest()
        
        return hashed_data, salt
    
    def verify_hash(self, data: str, hashed_data: str, salt: str) -> bool:
        """
        Verify data against its hash.
        
        Args:
            data: Original data to verify
            hashed_data: Stored hash
            salt: Salt used for hashing
            
        Returns:
            True if data matches hash, False otherwise
        """
        new_hash, _ = self.hash_data(data, salt)
        return new_hash == hashed_data


# Global encryption service instance
encryption_service = EncryptionService()


def encrypt_field(data: str) -> str:
    """Encrypt a field value."""
    return encryption_service.encrypt(data)


def decrypt_field(encrypted_data: str) -> str:
    """Decrypt a field value."""
    return encryption_service.decrypt(encrypted_data)


def hash_sensitive_field(data: str, salt: str = None) -> tuple:
    """Hash sensitive field data."""
    return encryption_service.hash_data(data, salt)


def verify_sensitive_field(data: str, hashed_data: str, salt: str) -> bool:
    """Verify sensitive field data."""
    return encryption_service.verify_hash(data, hashed_data, salt)


class EncryptedTextField:
    """
    Custom field descriptor for encrypting text fields.
    """
    
    def __init__(self, field_name):
        self.field_name = field_name
        self.encrypted_field_name = f"_encrypted_{field_name}"
    
    def __get__(self, instance, owner):
        if instance is None:
            return self
        
        encrypted_value = getattr(instance, self.encrypted_field_name, None)
        if encrypted_value:
            return decrypt_field(encrypted_value)
        return None
    
    def __set__(self, instance, value):
        if value:
            encrypted_value = encrypt_field(str(value))
            setattr(instance, self.encrypted_field_name, encrypted_value)
        else:
            setattr(instance, self.encrypted_field_name, None)


# Decorator for marking sensitive fields
def encrypt_sensitive_fields(*field_names):
    """
    Class decorator to automatically encrypt specified fields.
    
    Usage:
        @encrypt_sensitive_fields('email', 'phone', 'ssn')
        class MyModel(models.Model):
            email = models.CharField(max_length=255)
            phone = models.CharField(max_length=20)
            ssn = models.CharField(max_length=11)
    """
    def decorator(cls):
        for field_name in field_names:
            # Create encrypted field storage
            encrypted_field_name = f"_encrypted_{field_name}"
            
            # Add the encrypted storage field if it doesn't exist
            if not hasattr(cls, encrypted_field_name):
                from django.db import models
                encrypted_field = models.TextField(blank=True, null=True)
                encrypted_field.contribute_to_class(cls, encrypted_field_name)
            
            # Replace the original field with encrypted descriptor
            setattr(cls, field_name, EncryptedTextField(field_name))
        
        return cls
    
    return decorator
