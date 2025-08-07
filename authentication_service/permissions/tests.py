"""
Tests for the permissions app
"""
from datetime import timedelta
from django.test import TestCase
from django.utils import timezone
from django.core.exceptions import ValidationError

from user.models import AppUser
from .models import (
    Permission, UserRoleType, RolePermission, UserRole, 
    UserPermission, UserPermissionManager
)


class PermissionModelTest(TestCase):
    """Test cases for Permission model"""
    
    def setUp(self):
        self.permission_data = {
            'name': 'view_auctions',
            'type': 'view_only',
            'module': 'auction_management',
            'description': 'Permission to view auctions'
        }
    
    def test_create_permission(self):
        """Test creating a new permission"""
        permission = Permission.objects.create(**self.permission_data)
        self.assertEqual(permission.name, self.permission_data['name'])
        self.assertEqual(permission.type, self.permission_data['type'])
        self.assertEqual(permission.module, self.permission_data['module'])
        
    def test_permission_str_method(self):
        """Test permission string representation"""
        permission = Permission.objects.create(**self.permission_data)
        expected_str = f"{permission.name} ({permission.get_type_display()}) - {permission.get_module_display()}"
        self.assertEqual(str(permission), expected_str)
        
    def test_permission_clean_custom_without_description(self):
        """Test validation for custom permission without description"""
        permission = Permission(
            name='custom_permission',
            type='custom',
            module='auction_management'
        )
        with self.assertRaises(ValidationError):
            permission.clean()
