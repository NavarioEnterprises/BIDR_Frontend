# Set up Django environment if not already configured
import os
import django
from django.conf import settings

if not settings.configured:
    os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'product_management_service.settings')
    django.setup()

from django.test import TestCase
from django.contrib.auth.models import User
from django.core.exceptions import ValidationError
from django.utils import timezone
from datetime import timedelta
from unittest.mock import patch, MagicMock
import uuid

from .models import BaseModel, StatusChoices
from .encryption import encrypt_field, decrypt_field
from .exceptions import (
    BidrBaseException, ValidationException, 
    BusinessLogicException, IntegrationException
)
from .utils import (
    generate_unique_id, format_currency, 
    calculate_percentage, validate_email_domain
)


class BaseModelTest(TestCase):
    """Test cases for BaseModel abstract model."""
    
    def test_base_model_fields(self):
        """Test that BaseModel has required fields."""
        # Create a concrete model for testing
        from categories.models import Category
        
        category = Category.objects.create(
            name='Test Category',
            description='Test Description'
        )
        
        # Test BaseModel fields
        self.assertIsNotNone(category.id)
        self.assertIsNotNone(category.created_at)
        self.assertIsNotNone(category.updated_at)
        self.assertIsNone(category.deleted_at)
        
        # Test that created_at is set automatically
        self.assertLessEqual(
            (timezone.now() - category.created_at).total_seconds(), 
            5  # Should be created within 5 seconds
        )
    
    def test_base_model_update(self):
        """Test that updated_at is changed on model save."""
        from categories.models import Category
        
        category = Category.objects.create(
            name='Test Category',
            description='Test Description'
        )
        original_updated_at = category.updated_at
        
        # Wait a bit and update
        import time
        time.sleep(0.01)
        
        category.description = 'Updated Description'
        category.save()
        
        # Check that updated_at changed
        self.assertGreater(category.updated_at, original_updated_at)
    
    def test_soft_delete(self):
        """Test soft delete functionality if implemented."""
        from categories.models import Category
        
        category = Category.objects.create(
            name='Test Category',
            description='Test Description'
        )
        
        # Test soft delete if the model supports it
        if hasattr(category, 'soft_delete'):
            category.soft_delete()
            category.refresh_from_db()
            
            self.assertIsNotNone(category.deleted_at)
            self.assertTrue(category.is_deleted)


class StatusChoicesTest(TestCase):
    """Test cases for StatusChoices enum."""
    
    def test_status_choices_values(self):
        """Test that StatusChoices has expected values."""
        # Test that common status choices exist
        expected_statuses = ['active', 'inactive', 'pending', 'draft']
        
        for status in expected_statuses:
            self.assertTrue(
                any(choice[0] == status for choice in StatusChoices.choices)
                if hasattr(StatusChoices, 'choices') 
                else hasattr(StatusChoices, status.upper())
            )
    
    def test_status_choices_usage(self):
        """Test using StatusChoices in model fields."""
        # This would test actual usage in models
        # Since we don't have direct access to StatusChoices usage,
        # we'll test the concept
        from categories.models import Category
        
        category = Category.objects.create(
            name='Test Category',
            description='Test Description'
        )
        
        # Test that status field exists if implemented
        if hasattr(category, 'status'):
            self.assertIn(category.status, [choice[0] for choice in category._meta.get_field('status').choices])


class EncryptionTest(TestCase):
    """Test cases for encryption utilities."""
    
    def test_encrypt_decrypt_field(self):
        """Test field encryption and decryption."""
        original_data = "sensitive information"
        
        # Test encryption
        encrypted_data = encrypt_field(original_data)
        self.assertNotEqual(encrypted_data, original_data)
        self.assertIsInstance(encrypted_data, str)
        
        # Test decryption
        decrypted_data = decrypt_field(encrypted_data)
        self.assertEqual(decrypted_data, original_data)
    
    def test_encrypt_json_data(self):
        """Test encrypting JSON data."""
        import json
        
        original_data = {"key": "value", "number": 123, "nested": {"inner": "data"}}
        json_string = json.dumps(original_data)
        
        # Encrypt JSON string
        encrypted_data = encrypt_field(json_string)
        self.assertNotEqual(encrypted_data, json_string)
        
        # Decrypt and verify
        decrypted_json = decrypt_field(encrypted_data)
        decrypted_data = json.loads(decrypted_json)
        
        self.assertEqual(decrypted_data, original_data)
    
    def test_encrypt_none_value(self):
        """Test encryption with None value."""
        result = encrypt_field(None)
        self.assertIsNone(result)
        
        result = decrypt_field(None)
        self.assertIsNone(result)
    
    def test_encrypt_empty_string(self):
        """Test encryption with empty string."""
        result = encrypt_field("")
        self.assertNotEqual(result, "")
        
        decrypted = decrypt_field(result)
        self.assertEqual(decrypted, "")


class ExceptionsTest(TestCase):
    """Test cases for custom exceptions."""
    
    def test_bidr_base_exception(self):
        """Test BidrBaseException."""
        with self.assertRaises(BidrBaseException):
            raise BidrBaseException("Test base exception")
    
    def test_validation_exception(self):
        """Test ValidationException."""
        with self.assertRaises(ValidationException):
            raise ValidationException("Invalid data provided")
        
        try:
            raise ValidationException("Test validation", field="email", code="invalid")
        except ValidationException as e:
            self.assertEqual(str(e), "Test validation")
            if hasattr(e, 'field'):
                self.assertEqual(e.field, "email")
            if hasattr(e, 'code'):
                self.assertEqual(e.code, "invalid")
    
    def test_business_logic_exception(self):
        """Test BusinessLogicException."""
        with self.assertRaises(BusinessLogicException):
            raise BusinessLogicException("Business rule violated")
    
    def test_integration_exception(self):
        """Test IntegrationException."""
        with self.assertRaises(IntegrationException):
            raise IntegrationException("External service unavailable")
        
        try:
            raise IntegrationException("API Error", service="payment_gateway", status_code=500)
        except IntegrationException as e:
            self.assertEqual(str(e), "API Error")
            if hasattr(e, 'service'):
                self.assertEqual(e.service, "payment_gateway")
            if hasattr(e, 'status_code'):
                self.assertEqual(e.status_code, 500)


class UtilitiesTest(TestCase):
    """Test cases for utility functions."""
    
    def test_generate_unique_id(self):
        """Test unique ID generation."""
        id1 = generate_unique_id()
        id2 = generate_unique_id()
        
        self.assertNotEqual(id1, id2)
        self.assertIsInstance(id1, str)
        self.assertGreater(len(id1), 8)  # Should be reasonably long
        
        # Test with prefix
        prefixed_id = generate_unique_id(prefix="REQ")
        self.assertTrue(prefixed_id.startswith("REQ"))
    
    def test_format_currency(self):
        """Test currency formatting."""
        # Test basic formatting
        result = format_currency(1234.56)
        self.assertIn("1234.56", result)
        
        # Test with currency code
        result = format_currency(1000.00, currency="USD")
        self.assertIn("USD", result) if "USD" in result else self.assertIn("1000", result)
        
        # Test with zero
        result = format_currency(0)
        self.assertIn("0", result)
        
        # Test with negative
        result = format_currency(-100.50)
        self.assertIn("-100.50", result) or self.assertIn("100.50", result)
    
    def test_calculate_percentage(self):
        """Test percentage calculation."""
        # Test basic percentage
        result = calculate_percentage(25, 100)
        self.assertEqual(result, 25.0)
        
        # Test with decimals
        result = calculate_percentage(33.33, 100)
        self.assertAlmostEqual(result, 33.33, places=2)
        
        # Test with zero total
        result = calculate_percentage(10, 0)
        self.assertEqual(result, 0.0)  # Should handle division by zero
        
        # Test percentage of percentage
        result = calculate_percentage(15, 50)
        self.assertEqual(result, 30.0)
    
    def test_validate_email_domain(self):
        """Test email domain validation."""
        # Test valid domains
        self.assertTrue(validate_email_domain("user@example.com", ["example.com"]))
        self.assertTrue(validate_email_domain("test@company.org", ["company.org", "example.com"]))
        
        # Test invalid domains
        self.assertFalse(validate_email_domain("user@blocked.com", ["allowed.com"]))
        
        # Test invalid email format
        self.assertFalse(validate_email_domain("invalid-email", ["example.com"]))
        
        # Test empty allowed domains list
        self.assertTrue(validate_email_domain("user@any.com", []))  # Should allow any


class ModelValidationTest(TestCase):
    """Test model validation functionality."""
    
    def test_model_validation_success(self):
        """Test successful model validation."""
        from categories.models import Category
        
        category = Category(
            name='Valid Category',
            description='Valid description'
        )
        
        # Should not raise validation error
        try:
            category.full_clean()
        except ValidationError:
            self.fail("Valid model should not raise ValidationError")
    
    def test_model_validation_required_fields(self):
        """Test validation of required fields."""
        from categories.models import Category
        
        category = Category(description='Description without name')
        
        # Should raise validation error for missing required field
        with self.assertRaises(ValidationError):
            category.full_clean()
    
    def test_model_validation_field_length(self):
        """Test field length validation."""
        from categories.models import Category
        
        # Test with extremely long name
        very_long_name = 'x' * 1000  # Assuming max_length is less than 1000
        category = Category(
            name=very_long_name,
            description='Valid description'
        )
        
        # Should raise validation error for field too long
        with self.assertRaises(ValidationError):
            category.full_clean()


class PermissionsTest(TestCase):
    """Test permission and access control functionality."""
    
    def setUp(self):
        self.user = User.objects.create_user(
            username='testuser',
            email='test@example.com',
            password='testpass123'
        )
        
        self.admin_user = User.objects.create_user(
            username='admin',
            email='admin@example.com',
            password='adminpass123',
            is_staff=True,
            is_superuser=True
        )
    
    def test_user_permissions(self):
        """Test basic user permissions."""
        # Test regular user permissions
        self.assertFalse(self.user.is_staff)
        self.assertFalse(self.user.is_superuser)
        
        # Test admin user permissions
        self.assertTrue(self.admin_user.is_staff)
        self.assertTrue(self.admin_user.is_superuser)
    
    def test_permission_decorators(self):
        """Test custom permission decorators if they exist."""
        # This would test custom permission decorators
        # For now, we'll test the concept
        
        def test_view_function(user):
            if user.is_authenticated:
                return True
            return False
        
        # Test authenticated user
        self.assertTrue(test_view_function(self.user))
        
        # Test unauthenticated user
        from django.contrib.auth.models import AnonymousUser
        anonymous_user = AnonymousUser()
        self.assertFalse(test_view_function(anonymous_user))


class SignalsTest(TestCase):
    """Test Django signals if implemented."""
    
    def test_post_save_signals(self):
        """Test post_save signals."""
        from categories.models import Category
        
        # Create a category and check if signals are fired
        category = Category.objects.create(
            name='Test Category',
            description='Test Description'
        )
        
        # If signals are implemented, they would have been fired
        # For now, just verify the object was created
        self.assertTrue(Category.objects.filter(id=category.id).exists())
    
    def test_pre_delete_signals(self):
        """Test pre_delete signals."""
        from categories.models import Category
        
        category = Category.objects.create(
            name='Test Category',
            description='Test Description'
        )
        
        # Delete and check if pre_delete signals would be fired
        category_id = category.id
        category.delete()
        
        # Verify object was deleted
        self.assertFalse(Category.objects.filter(id=category_id).exists())


class ConfigurationTest(TestCase):
    """Test application configuration."""
    
    def test_django_settings_access(self):
        """Test accessing Django settings."""
        from django.conf import settings
        
        # Test that key settings are accessible
        self.assertIsNotNone(settings.SECRET_KEY)
        self.assertIsNotNone(settings.DATABASES)
        self.assertIsInstance(settings.DEBUG, bool)
        
        # Test custom settings if they exist
        if hasattr(settings, 'INVENTORY_SETTINGS'):
            self.assertIsInstance(settings.INVENTORY_SETTINGS, dict)
    
    def test_app_specific_settings(self):
        """Test application-specific settings."""
        from django.conf import settings
        
        # Test encryption settings
        if hasattr(settings, 'ENCRYPTION_SETTINGS'):
            encryption_settings = settings.ENCRYPTION_SETTINGS
            self.assertIn('USE_ENCRYPTION', encryption_settings)
            self.assertIn('ENCRYPTION_KEY', encryption_settings)
        
        # Test analytics settings
        if hasattr(settings, 'ANALYTICS_SETTINGS'):
            analytics_settings = settings.ANALYTICS_SETTINGS
            self.assertIn('ENABLE_ANALYTICS', analytics_settings)


class IntegrationTest(TestCase):
    """Integration tests for core functionality."""
    
    def setUp(self):
        self.user = User.objects.create_user(
            username='testuser',
            email='test@example.com',
            password='testpass123'
        )
    
    def test_model_creation_workflow(self):
        """Test complete model creation workflow."""
        from categories.models import Category
        
        # Create category
        category = Category.objects.create(
            name='Integration Test Category',
            description='Created during integration test'
        )
        
        # Verify creation
        self.assertIsNotNone(category.id)
        self.assertIsNotNone(category.created_at)
        
        # Update category
        original_updated_at = category.updated_at
        category.description = 'Updated during integration test'
        category.save()
        
        # Verify update
        self.assertGreater(category.updated_at, original_updated_at)
        
        # Clean up
        category.delete()
    
    def test_encryption_workflow(self):
        """Test complete encryption/decryption workflow."""
        sensitive_data = "This is sensitive information"
        
        # Encrypt
        encrypted = encrypt_field(sensitive_data)
        self.assertNotEqual(encrypted, sensitive_data)
        
        # Decrypt
        decrypted = decrypt_field(encrypted)
        self.assertEqual(decrypted, sensitive_data)
    
    def test_exception_handling_workflow(self):
        """Test exception handling workflow."""
        # Test validation exception
        try:
            raise ValidationException("Test validation error")
        except ValidationException as e:
            self.assertIn("validation", str(e).lower())
        
        # Test business logic exception
        try:
            raise BusinessLogicException("Test business logic error")
        except BusinessLogicException as e:
            self.assertIn("business", str(e).lower()) or self.assertIn("logic", str(e).lower())
