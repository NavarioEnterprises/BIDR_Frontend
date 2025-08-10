"""
Tests for the permissions app
"""
from datetime import timedelta
from django.test import TestCase
from django.utils import timezone
from django.core.exceptions import ValidationError

# No need to import AppUser as it's not used in these tests
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
        self.assertEqual(permission.description, self.permission_data['description'])
        self.assertTrue(permission.is_active)
        
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
    
    def test_permission_clean_custom_with_description(self):
        """Test validation for custom permission with description"""
        permission = Permission(
            name='custom_permission',
            type='custom',
            module='auction_management',
            description='This is a custom permission'
        )
        # Should not raise ValidationError
        permission.clean()
        self.assertEqual(permission.description, 'This is a custom permission')


class UserRoleTypeTest(TestCase):
    """Test cases for UserRoleType model"""
    
    def setUp(self):
        self.role_type_data = {
            'role_name': 'Auction Manager',
            'company_type': 'auction_house',
            'role_level': 'middle_management',
            'role_job_function': 'auction_manager',
            'function_department': 'operations'
        }
        
        self.permission1 = Permission.objects.create(
            name='view_auctions',
            type='view_only',
            module='auction_management',
            description='Permission to view auctions'
        )
        
        self.permission2 = Permission.objects.create(
            name='create_auctions',
            type='create',
            module='auction_management',
            description='Permission to create auctions'
        )
    
    def test_create_role_type(self):
        """Test creating a new role type"""
        role_type = UserRoleType.objects.create(**self.role_type_data)
        self.assertEqual(role_type.role_name, self.role_type_data['role_name'])
        self.assertEqual(role_type.company_type, self.role_type_data['company_type'])
        self.assertEqual(role_type.role_level, self.role_type_data['role_level'])
        self.assertEqual(role_type.role_job_function, self.role_type_data['role_job_function'])
        self.assertEqual(role_type.function_department, self.role_type_data['function_department'])
        self.assertTrue(role_type.is_active)
    
    def test_role_type_str_method(self):
        """Test role type string representation"""
        role_type = UserRoleType.objects.create(**self.role_type_data)
        expected_str = f"{role_type.role_name} ({role_type.get_company_type_display()})"
        self.assertEqual(str(role_type), expected_str)
    
    def test_get_permissions_list(self):
        """Test getting permissions list for a role type"""
        role_type = UserRoleType.objects.create(**self.role_type_data)
        
        # Add permissions to role type
        RolePermission.objects.create(role=role_type, permission=self.permission1)
        RolePermission.objects.create(role=role_type, permission=self.permission2)
        
        permissions_list = role_type.get_permissions_list()
        self.assertEqual(len(permissions_list), 2)
        self.assertIn(self.permission1, permissions_list)
        self.assertIn(self.permission2, permissions_list)
    
    def test_has_permission(self):
        """Test checking if role type has a specific permission"""
        role_type = UserRoleType.objects.create(**self.role_type_data)
        
        # Add permission to role type
        RolePermission.objects.create(role=role_type, permission=self.permission1)
        
        self.assertTrue(role_type.has_permission('view_auctions'))
        self.assertFalse(role_type.has_permission('create_auctions'))
        
        # Test with module parameter
        self.assertTrue(role_type.has_permission('view_auctions', module='auction_management'))
        self.assertFalse(role_type.has_permission('view_auctions', module='bid_management'))
    
    def test_get_module_permissions(self):
        """Test getting permissions for a specific module"""
        role_type = UserRoleType.objects.create(**self.role_type_data)
        
        # Add permissions to role type
        RolePermission.objects.create(role=role_type, permission=self.permission1)
        RolePermission.objects.create(role=role_type, permission=self.permission2)
        
        # Create a permission for a different module
        permission3 = Permission.objects.create(
            name='view_bids',
            type='view_only',
            module='bid_management',
            description='Permission to view bids'
        )
        RolePermission.objects.create(role=role_type, permission=permission3)
        
        # Get permissions for auction_management module
        module_permissions = role_type.get_module_permissions('auction_management')
        self.assertEqual(module_permissions.count(), 2)
        self.assertIn(self.permission1, module_permissions)
        self.assertIn(self.permission2, module_permissions)
        self.assertNotIn(permission3, module_permissions)


class RolePermissionTest(TestCase):
    """Test cases for RolePermission model"""
    
    def setUp(self):
        self.permission = Permission.objects.create(
            name='view_auctions',
            type='view_only',
            module='auction_management',
            description='Permission to view auctions'
        )
        
        self.role_type = UserRoleType.objects.create(
            role_name='Auction Manager',
            company_type='auction_house',
            role_level='middle_management',
            role_job_function='auction_manager',
            function_department='operations'
        )
    
    def test_create_role_permission(self):
        """Test creating a new role permission"""
        role_permission = RolePermission.objects.create(
            role=self.role_type,
            permission=self.permission,
            assigned_by='admin@example.com'
        )
        
        self.assertEqual(role_permission.role, self.role_type)
        self.assertEqual(role_permission.permission, self.permission)
        self.assertEqual(role_permission.assigned_by, 'admin@example.com')
        self.assertTrue(role_permission.is_active)
    
    def test_role_permission_str_method(self):
        """Test role permission string representation"""
        role_permission = RolePermission.objects.create(
            role=self.role_type,
            permission=self.permission
        )
        
        expected_str = f"{self.role_type.role_name} - {self.permission.name}"
        self.assertEqual(str(role_permission), expected_str)
    
    def test_unique_together_constraint(self):
        """Test unique_together constraint for role and permission"""
        RolePermission.objects.create(
            role=self.role_type,
            permission=self.permission
        )
        
        # Attempting to create another role permission with the same role and permission
        # should raise an IntegrityError
        from django.db import IntegrityError
        with self.assertRaises(IntegrityError):
            RolePermission.objects.create(
                role=self.role_type,
                permission=self.permission
            )


class UserRoleTest(TestCase):
    """Test cases for UserRole model"""
    
    def setUp(self):
        self.user_email = 'user@example.com'
        
        self.role_type = UserRoleType.objects.create(
            role_name='Auction Manager',
            company_type='auction_house',
            role_level='middle_management',
            role_job_function='auction_manager',
            function_department='operations'
        )
    
    def test_create_user_role(self):
        """Test creating a new user role"""
        user_role = UserRole.objects.create(
            user_email=self.user_email,
            role=self.role_type,
            assigned_by='admin@example.com'
        )
        
        self.assertEqual(user_role.user_email, self.user_email)
        self.assertEqual(user_role.role, self.role_type)
        self.assertEqual(user_role.assigned_by, 'admin@example.com')
        self.assertTrue(user_role.is_active)
        self.assertIsNone(user_role.end_date)
    
    def test_user_role_str_method(self):
        """Test user role string representation"""
        user_role = UserRole.objects.create(
            user_email=self.user_email,
            role=self.role_type
        )
        
        expected_str = f"{self.user_email} - {self.role_type.role_name}"
        self.assertEqual(str(user_role), expected_str)
    
    def test_deactivate_method(self):
        """Test deactivating a user role"""
        user_role = UserRole.objects.create(
            user_email=self.user_email,
            role=self.role_type
        )
        
        self.assertTrue(user_role.is_active)
        
        user_role.deactivate(deactivated_by='admin@example.com')
        
        # Refresh from database
        user_role.refresh_from_db()
        
        self.assertFalse(user_role.is_active)
        self.assertEqual(user_role.assigned_by, 'admin@example.com')
    
    def test_activate_method(self):
        """Test activating a user role"""
        user_role = UserRole.objects.create(
            user_email=self.user_email,
            role=self.role_type,
            is_active=False
        )
        
        self.assertFalse(user_role.is_active)
        
        user_role.activate(activated_by='admin@example.com')
        
        # Refresh from database
        user_role.refresh_from_db()
        
        self.assertTrue(user_role.is_active)
        self.assertEqual(user_role.assigned_by, 'admin@example.com')
    
    def test_is_expired_method_with_no_end_date(self):
        """Test is_expired method when end_date is None"""
        user_role = UserRole.objects.create(
            user_email=self.user_email,
            role=self.role_type
        )
        
        self.assertFalse(user_role.is_expired())
    
    def test_is_expired_method_with_future_end_date(self):
        """Test is_expired method when end_date is in the future"""
        future_date = timezone.now() + timedelta(days=7)
        
        user_role = UserRole.objects.create(
            user_email=self.user_email,
            role=self.role_type,
            end_date=future_date
        )
        
        self.assertFalse(user_role.is_expired())
    
    def test_is_expired_method_with_past_end_date(self):
        """Test is_expired method when end_date is in the past"""
        past_date = timezone.now() - timedelta(days=7)
        
        user_role = UserRole.objects.create(
            user_email=self.user_email,
            role=self.role_type,
            end_date=past_date
        )
        
        self.assertTrue(user_role.is_expired())


class UserPermissionTest(TestCase):
    """Test cases for UserPermission model"""
    
    def setUp(self):
        self.user_email = 'user@example.com'
        
        self.permission = Permission.objects.create(
            name='view_auctions',
            type='view_only',
            module='auction_management',
            description='Permission to view auctions'
        )
    
    def test_create_user_permission(self):
        """Test creating a new user permission"""
        user_permission = UserPermission.objects.create(
            user_email=self.user_email,
            permission=self.permission,
            permission_type='grant',
            assigned_by='admin@example.com'
        )
        
        self.assertEqual(user_permission.user_email, self.user_email)
        self.assertEqual(user_permission.permission, self.permission)
        self.assertEqual(user_permission.permission_type, 'grant')
        self.assertEqual(user_permission.assigned_by, 'admin@example.com')
        self.assertTrue(user_permission.is_active)
        self.assertIsNone(user_permission.end_date)
    
    def test_user_permission_str_method(self):
        """Test user permission string representation"""
        user_permission = UserPermission.objects.create(
            user_email=self.user_email,
            permission=self.permission,
            permission_type='grant'
        )
        
        expected_str = f"{self.user_email} - {self.permission.name} (grant)"
        self.assertEqual(str(user_permission), expected_str)
    
    def test_deactivate_method(self):
        """Test deactivating a user permission"""
        user_permission = UserPermission.objects.create(
            user_email=self.user_email,
            permission=self.permission,
            permission_type='grant'
        )
        
        self.assertTrue(user_permission.is_active)
        
        user_permission.deactivate(deactivated_by='admin@example.com')
        
        # Refresh from database
        user_permission.refresh_from_db()
        
        self.assertFalse(user_permission.is_active)
        self.assertEqual(user_permission.assigned_by, 'admin@example.com')
    
    def test_activate_method(self):
        """Test activating a user permission"""
        user_permission = UserPermission.objects.create(
            user_email=self.user_email,
            permission=self.permission,
            permission_type='grant',
            is_active=False
        )
        
        self.assertFalse(user_permission.is_active)
        
        user_permission.activate(activated_by='admin@example.com')
        
        # Refresh from database
        user_permission.refresh_from_db()
        
        self.assertTrue(user_permission.is_active)
        self.assertEqual(user_permission.assigned_by, 'admin@example.com')
    
    def test_is_expired_method_with_no_end_date(self):
        """Test is_expired method when end_date is None"""
        user_permission = UserPermission.objects.create(
            user_email=self.user_email,
            permission=self.permission,
            permission_type='grant'
        )
        
        self.assertFalse(user_permission.is_expired())
    
    def test_is_expired_method_with_future_end_date(self):
        """Test is_expired method when end_date is in the future"""
        future_date = timezone.now() + timedelta(days=7)
        
        user_permission = UserPermission.objects.create(
            user_email=self.user_email,
            permission=self.permission,
            permission_type='grant',
            end_date=future_date
        )
        
        self.assertFalse(user_permission.is_expired())
    
    def test_is_expired_method_with_past_end_date(self):
        """Test is_expired method when end_date is in the past"""
        past_date = timezone.now() - timedelta(days=7)
        
        user_permission = UserPermission.objects.create(
            user_email=self.user_email,
            permission=self.permission,
            permission_type='grant',
            end_date=past_date
        )
        
        self.assertTrue(user_permission.is_expired())
    
    def test_deny_permission_type(self):
        """Test creating a user permission with 'deny' permission_type"""
        user_permission = UserPermission.objects.create(
            user_email=self.user_email,
            permission=self.permission,
            permission_type='deny'
        )
        
        self.assertEqual(user_permission.permission_type, 'deny')


class UserPermissionManagerTest(TestCase):
    """Test cases for UserPermissionManager"""
    
    def setUp(self):
        self.user_email = 'user@example.com'
        self.another_user_email = 'another_user@example.com'
        
        # Create permissions
        self.view_permission = Permission.objects.create(
            name='view_auctions',
            type='view_only',
            module='auction_management',
            description='Permission to view auctions'
        )
        
        self.create_permission = Permission.objects.create(
            name='create_auctions',
            type='create',
            module='auction_management',
            description='Permission to create auctions'
        )
        
        self.edit_permission = Permission.objects.create(
            name='edit_auctions',
            type='edit',
            module='auction_management',
            description='Permission to edit auctions'
        )
        
        self.view_bids_permission = Permission.objects.create(
            name='view_bids',
            type='view_only',
            module='bid_management',
            description='Permission to view bids'
        )
        
        self.delete_permission = Permission.objects.create(
            name='delete_auctions',
            type='delete',
            module='auction_management',
            description='Permission to delete auctions'
        )
        
        # Create role types
        self.auction_manager_role = UserRoleType.objects.create(
            role_name='Auction Manager',
            company_type='auction_house',
            role_level='middle_management',
            role_job_function='auction_manager',
            function_department='operations'
        )
        
        self.bid_manager_role = UserRoleType.objects.create(
            role_name='Bid Manager',
            company_type='auction_house',
            role_level='middle_management',
            role_job_function='buyer_manager',
            function_department='operations'
        )
        
        self.admin_role = UserRoleType.objects.create(
            role_name='Admin',
            company_type='platform_admin',
            role_level='super_admin',
            role_job_function='platform_admin',
            function_department='administration'
        )
        
        # Assign permissions to roles
        RolePermission.objects.create(
            role=self.auction_manager_role,
            permission=self.view_permission
        )
        
        RolePermission.objects.create(
            role=self.auction_manager_role,
            permission=self.create_permission
        )
        
        RolePermission.objects.create(
            role=self.bid_manager_role,
            permission=self.view_bids_permission
        )
        
        RolePermission.objects.create(
            role=self.admin_role,
            permission=self.view_permission
        )
        
        RolePermission.objects.create(
            role=self.admin_role,
            permission=self.create_permission
        )
        
        RolePermission.objects.create(
            role=self.admin_role,
            permission=self.edit_permission
        )
        
        RolePermission.objects.create(
            role=self.admin_role,
            permission=self.delete_permission
        )
        
        # Assign roles to user
        UserRole.objects.create(
            user_email=self.user_email,
            role=self.auction_manager_role
        )
        
        # Assign direct permissions to user
        UserPermission.objects.create(
            user_email=self.user_email,
            permission=self.edit_permission,
            permission_type='grant'
        )
        
        # Deny a permission that comes from a role
        UserPermission.objects.create(
            user_email=self.user_email,
            permission=self.create_permission,
            permission_type='deny'
        )
    
    def test_get_user_permissions(self):
        """Test getting all effective permissions for a user"""
        user_permissions = UserPermissionManager.get_user_permissions(self.user_email)
        
        # User should have:
        # - view_auctions (from role)
        # - edit_auctions (direct grant)
        # - NOT create_auctions (denied despite being in role)
        
        self.assertEqual(user_permissions.count(), 2)
        self.assertIn(self.view_permission, user_permissions)
        self.assertIn(self.edit_permission, user_permissions)
        self.assertNotIn(self.create_permission, user_permissions)
        self.assertNotIn(self.view_bids_permission, user_permissions)
    
    def test_user_has_permission(self):
        """Test checking if a user has a specific permission"""
        # User should have view_auctions permission
        self.assertTrue(
            UserPermissionManager.user_has_permission(
                self.user_email, 'view_auctions'
            )
        )
        
        # User should have edit_auctions permission
        self.assertTrue(
            UserPermissionManager.user_has_permission(
                self.user_email, 'edit_auctions'
            )
        )
        
        # User should NOT have create_auctions permission (denied)
        self.assertFalse(
            UserPermissionManager.user_has_permission(
                self.user_email, 'create_auctions'
            )
        )
        
        # User should NOT have view_bids permission (not assigned)
        self.assertFalse(
            UserPermissionManager.user_has_permission(
                self.user_email, 'view_bids'
            )
        )
        
        # Test with module parameter
        self.assertTrue(
            UserPermissionManager.user_has_permission(
                self.user_email, 'view_auctions', module='auction_management'
            )
        )
        
        self.assertFalse(
            UserPermissionManager.user_has_permission(
                self.user_email, 'view_auctions', module='bid_management'
            )
        )
    
    def test_get_user_roles(self):
        """Test getting all active roles for a user"""
        user_roles = UserPermissionManager.get_user_roles(self.user_email)
        
        self.assertEqual(user_roles.count(), 1)
        self.assertIn(self.auction_manager_role, user_roles)
        self.assertNotIn(self.bid_manager_role, user_roles)
        
        # Assign another role to the user
        UserRole.objects.create(
            user_email=self.user_email,
            role=self.bid_manager_role
        )
        
        # Get roles again
        user_roles = UserPermissionManager.get_user_roles(self.user_email)
        
        self.assertEqual(user_roles.count(), 2)
        self.assertIn(self.auction_manager_role, user_roles)
        self.assertIn(self.bid_manager_role, user_roles)
    
    def test_get_user_module_permissions(self):
        """Test getting all permissions for a user in a specific module"""
        # Get permissions for auction_management module
        module_permissions = UserPermissionManager.get_user_module_permissions(
            self.user_email, 'auction_management'
        )
        
        self.assertEqual(module_permissions.count(), 2)
        self.assertIn(self.view_permission, module_permissions)
        self.assertIn(self.edit_permission, module_permissions)
        self.assertNotIn(self.create_permission, module_permissions)  # Denied
        self.assertNotIn(self.view_bids_permission, module_permissions)  # Different module
        
        # Get permissions for bid_management module
        module_permissions = UserPermissionManager.get_user_module_permissions(
            self.user_email, 'bid_management'
        )
        
        self.assertEqual(module_permissions.count(), 0)
        
        # Assign bid_manager_role to user
        UserRole.objects.create(
            user_email=self.user_email,
            role=self.bid_manager_role
        )
        
        # Get permissions for bid_management module again
        module_permissions = UserPermissionManager.get_user_module_permissions(
            self.user_email, 'bid_management'
        )
        
        self.assertEqual(module_permissions.count(), 1)
        self.assertIn(self.view_bids_permission, module_permissions)
    
    def test_expired_roles_not_included(self):
        """Test that expired roles are not included in permissions"""
        # Create a role with an expired end_date
        past_date = timezone.now() - timedelta(days=7)
        
        expired_role = UserRoleType.objects.create(
            role_name='Expired Role',
            company_type='auction_house',
            role_level='middle_management',
            role_job_function='auction_manager',
            function_department='operations'
        )
        
        expired_permission = Permission.objects.create(
            name='expired_permission',
            type='view_only',
            module='auction_management',
            description='This permission comes from an expired role'
        )
        
        RolePermission.objects.create(
            role=expired_role,
            permission=expired_permission
        )
        
        UserRole.objects.create(
            user_email=self.user_email,
            role=expired_role,
            end_date=past_date
        )
        
        # Get user permissions
        user_permissions = UserPermissionManager.get_user_permissions(self.user_email)
        
        # The expired permission should not be included
        self.assertNotIn(expired_permission, user_permissions)
    
    def test_expired_direct_permissions_not_included(self):
        """Test that expired direct permissions are not included"""
        # Create a direct permission with an expired end_date
        past_date = timezone.now() - timedelta(days=7)
        
        expired_permission = Permission.objects.create(
            name='expired_direct_permission',
            type='view_only',
            module='auction_management',
            description='This direct permission is expired'
        )
        
        UserPermission.objects.create(
            user_email=self.user_email,
            permission=expired_permission,
            permission_type='grant',
            end_date=past_date
        )
        
        # Get user permissions
        user_permissions = UserPermissionManager.get_user_permissions(self.user_email)
        
        # The expired permission should not be included
        self.assertNotIn(expired_permission, user_permissions)
    
    def test_inactive_permissions_not_included(self):
        """Test that inactive permissions are not included"""
        # Create an inactive permission
        inactive_permission = Permission.objects.create(
            name='inactive_permission',
            type='view_only',
            module='auction_management',
            description='This permission is inactive',
            is_active=False
        )
        
        # Assign it to a role
        RolePermission.objects.create(
            role=self.auction_manager_role,
            permission=inactive_permission
        )
        
        # Get user permissions
        user_permissions = UserPermissionManager.get_user_permissions(self.user_email)
        
        # The inactive permission should not be included
        self.assertNotIn(inactive_permission, user_permissions)
    
    def test_inactive_role_permissions_not_included(self):
        """Test that permissions from inactive roles are not included"""
        # Deactivate the auction_manager_role
        self.auction_manager_role.is_active = False
        self.auction_manager_role.save()
        
        # Get user permissions
        user_permissions = UserPermissionManager.get_user_permissions(self.user_email)
        
        # Permissions from the inactive role should not be included
        self.assertNotIn(self.view_permission, user_permissions)
        # But direct permissions should still be included
        self.assertIn(self.edit_permission, user_permissions)
        
        # Reactivate the role for other tests
        self.auction_manager_role.is_active = True
        self.auction_manager_role.save()
    
    def test_inactive_role_permission_relationship_not_included(self):
        """Test that inactive role-permission relationships are not included"""
        # Get the role-permission relationship and deactivate it
        role_permission = RolePermission.objects.get(
            role=self.auction_manager_role,
            permission=self.view_permission
        )
        role_permission.is_active = False
        role_permission.save()
        
        # Get user permissions
        user_permissions = UserPermissionManager.get_user_permissions(self.user_email)
        
        # The permission from the inactive relationship should not be included
        self.assertNotIn(self.view_permission, user_permissions)
        
        # Reactivate for other tests
        role_permission.is_active = True
        role_permission.save()
    
    def test_inactive_user_role_not_included(self):
        """Test that permissions from inactive user-role relationships are not included"""
        # Get the user-role relationship and deactivate it
        user_role = UserRole.objects.get(
            user_email=self.user_email,
            role=self.auction_manager_role
        )
        user_role.is_active = False
        user_role.save()
        
        # Get user permissions
        user_permissions = UserPermissionManager.get_user_permissions(self.user_email)
        
        # Permissions from the inactive user-role should not be included
        self.assertNotIn(self.view_permission, user_permissions)
        # But direct permissions should still be included
        self.assertIn(self.edit_permission, user_permissions)
        
        # Reactivate for other tests
        user_role.is_active = True
        user_role.save()
    
    def test_multiple_roles_with_same_permission(self):
        """Test that a user with multiple roles having the same permission still works correctly"""
        # Assign the admin role to the user
        UserRole.objects.create(
            user_email=self.user_email,
            role=self.admin_role
        )
        
        # Get user permissions
        user_permissions = UserPermissionManager.get_user_permissions(self.user_email)
        
        # User should have all permissions from both roles (except denied ones)
        self.assertIn(self.view_permission, user_permissions)
        self.assertIn(self.edit_permission, user_permissions)
        self.assertIn(self.delete_permission, user_permissions)
        self.assertNotIn(self.create_permission, user_permissions)  # Still denied
        self.assertNotIn(self.view_bids_permission, user_permissions)  # Not assigned
        
        # The count should be 3 (view, edit, delete)
        self.assertEqual(user_permissions.count(), 3)
    
    def test_user_without_permissions(self):
        """Test behavior for a user with no roles or direct permissions"""
        # Get permissions for a user that doesn't have any roles or permissions
        user_permissions = UserPermissionManager.get_user_permissions(self.another_user_email)
        
        # Should return an empty queryset
        self.assertEqual(user_permissions.count(), 0)
        
        # Check has_permission should return False
        self.assertFalse(
            UserPermissionManager.user_has_permission(
                self.another_user_email, 'view_auctions'
            )
        )
        
        # Get roles should return an empty queryset
        user_roles = UserPermissionManager.get_user_roles(self.another_user_email)
        self.assertEqual(user_roles.count(), 0)
        
        # Get module permissions should return an empty queryset
        module_permissions = UserPermissionManager.get_user_module_permissions(
            self.another_user_email, 'auction_management'
        )
        self.assertEqual(module_permissions.count(), 0)