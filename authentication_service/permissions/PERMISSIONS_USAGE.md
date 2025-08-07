# BIDR Permissions System Usage Guide

This guide explains how to use the comprehensive roles and permissions system implemented for the BIDR platform.

## Overview

The permissions system provides:
- **Granular Permissions**: Fine-grained control over what users can do
- **Role-Based Access Control (RBAC)**: Assign permissions to roles, then roles to users
- **Direct User Permissions**: Override or extend role permissions for specific users
- **Time-Based Permissions**: Set expiration dates for roles and permissions
- **Module-Based Organization**: Permissions are organized by functional modules

## Key Components

### 1. Permissions
- Permissions define what actions can be performed
- Each permission has a type (view_only, create, edit, delete, manage, admin, approve, reject, custom)
- Permissions are organized by modules (auction_management, bid_management, user_management, etc.)

### 2. Role Types
- Role types define different user roles in the system
- Each role type has company type, role level, job function, and department
- Roles can have multiple permissions assigned to them

### 3. User Roles
- Users are assigned roles which give them all permissions associated with that role
- Role assignments can have expiration dates for temporary access

### 4. User Permissions
- Direct permission assignments to users
- Can be used to grant additional permissions or deny permissions even if the role has them
- Support for both "grant" and "deny" types

## API Endpoints

### Authentication
All permission management endpoints require authentication.

### Permission Management

#### List Permissions
```http
GET /permissions/permissions/
```

#### Create Permission
```http
POST /permissions/permissions/
Content-Type: application/json

{
    "name": "Create Auctions",
    "type": "create",
    "module": "auction_management",
    "description": "Allows user to create new auctions"
}
```

### Role Management

#### List Role Types
```http
GET /permissions/role-types/
```

#### Create Role Type
```http
POST /permissions/role-types/
Content-Type: application/json

{
    "role_name": "Auction Manager",
    "company_type": "auction_house",
    "role_level": "middle_management",
    "role_job_function": "auction_manager",
    "function_department": "operations"
}
```

#### Assign Permissions to Role
```http
POST /permissions/role-types/{role_id}/assign_permissions/
Content-Type: application/json

{
    "permission_ids": [1, 2, 3],
    "assigned_by": "admin@bidr.com"
}
```

### User Role Assignment

#### Assign Role to User
```http
POST /permissions/assign-role/
Content-Type: application/json

{
    "user_email": "user@example.com",
    "role_id": 1,
    "assigned_by": "admin@bidr.com",
    "end_date": "2024-12-31T23:59:59Z"  // Optional
}
```

#### Bulk Assign Roles
```http
POST /permissions/bulk-assign-roles/
Content-Type: application/json

{
    "user_emails": ["user1@example.com", "user2@example.com"],
    "role_id": 1,
    "assigned_by": "admin@bidr.com"
}
```

### Direct User Permissions

#### Assign Permission to User
```http
POST /permissions/assign-permission/
Content-Type: application/json

{
    "user_email": "user@example.com",
    "permission_id": 1,
    "permission_type": "grant",  // or "deny"
    "assigned_by": "admin@bidr.com"
}
```

### Permission Checking

#### Check User Permission
```http
POST /permissions/check-permission/
Content-Type: application/json

{
    "user_email": "user@example.com",
    "permission_name": "Create Auctions",
    "module": "auction_management"
}
```

#### Get User Permission Summary
```http
GET /permissions/user-permissions-summary/?email=user@example.com
```

## Using Permission Decorators in Views

### Function-Based Views

```python
from permissions.decorators import require_permission, require_any_permission, require_all_permissions

@require_permission('Create Auctions', 'auction_management')
def create_auction(request):
    # This view requires the "Create Auctions" permission in the auction_management module
    pass

@require_any_permission(
    ('Create Auctions', 'auction_management'),
    ('Edit Auctions', 'auction_management')
)
def auction_view(request):
    # This view requires either "Create Auctions" OR "Edit Auctions" permission
    pass

@require_all_permissions(
    ('Create Auctions', 'auction_management'),
    ('Manage Users', 'user_management')
)
def admin_view(request):
    # This view requires BOTH permissions
    pass
```

### Class-Based Views

```python
from permissions.decorators import PermissionRequiredMixin
from rest_framework.views import APIView

class AuctionCreateView(PermissionRequiredMixin, APIView):
    required_permission = 'Create Auctions'
    required_module = 'auction_management'
    
    def post(self, request):
        # View logic here
        pass

class AdminView(PermissionRequiredMixin, APIView):
    required_permissions = [
        ('Create Auctions', 'auction_management'),
        ('Manage Users', 'user_management')
    ]
    require_all_permissions = True  # Require ALL permissions
    
    def get(self, request):
        # View logic here
        pass

class ModeratorView(PermissionRequiredMixin, APIView):
    required_permissions = [
        ('Edit Auctions', 'auction_management'),
        ('Delete Auctions', 'auction_management')
    ]
    require_all_permissions = False  # Require ANY permission
    
    def get(self, request):
        # View logic here
        pass
```

## Programmatic Permission Checking

```python
from permissions.models import UserPermissionManager

# Check if user has a specific permission
has_permission = UserPermissionManager.user_has_permission(
    'user@example.com', 
    'Create Auctions', 
    'auction_management'
)

# Get all permissions for a user
user_permissions = UserPermissionManager.get_user_permissions('user@example.com')

# Get user's roles
user_roles = UserPermissionManager.get_user_roles('user@example.com')

# Get permissions for a specific module
module_permissions = UserPermissionManager.get_user_module_permissions(
    'user@example.com', 
    'auction_management'
)
```

## Django Admin Integration

The system includes comprehensive Django admin interfaces for:
- Managing permissions
- Creating and editing role types
- Assigning permissions to roles
- Managing user role assignments
- Managing direct user permissions

Access the admin at `/admin/` after creating a superuser.

## Setting Up Default Data

Run the management command to seed the database with default permissions and roles:

```bash
python manage.py seed_permissions
```

## Permission Types

- **view_only**: Read-only access
- **create**: Can create new items
- **edit**: Can modify existing items
- **delete**: Can remove items
- **manage**: Includes create, edit, and delete
- **admin**: Full access including manage
- **approve**: Can approve items (for workflows)
- **reject**: Can reject items (for workflows)
- **custom**: Custom-defined permissions

## Modules

The system is organized into the following modules:
- auction_management
- bid_management
- product_management
- user_management
- seller_management
- buyer_management
- payment_processing
- document_verification
- notifications
- reporting
- analytics
- system_configuration
- compliance
- support
- messaging
- logistics
- inventory
- financial_reports
- dispute_resolution
- platform_settings

## Best Practices

1. **Use Role-Based Access**: Assign permissions to roles rather than individual users where possible
2. **Principle of Least Privilege**: Give users only the minimum permissions they need
3. **Regular Auditing**: Regularly review user permissions and remove unnecessary access
4. **Temporary Access**: Use expiration dates for temporary access needs
5. **Module Organization**: Keep related permissions in the same module
6. **Clear Naming**: Use descriptive names for permissions and roles
7. **Documentation**: Document what each permission allows users to do

## Examples

### Creating a New Seller Role
```python
# Create the role
seller_role = UserRoleType.objects.create(
    role_name='Product Seller',
    company_type='business_seller',
    role_level='basic_user',
    role_job_function='seller_manager',
    function_department='sales_marketing'
)

# Assign permissions
permissions = Permission.objects.filter(
    name__in=['Create Products', 'Edit Products', 'View Bids'],
    module__in=['product_management', 'bid_management']
)

for permission in permissions:
    RolePermission.objects.create(
        role=seller_role,
        permission=permission,
        assigned_by='admin@bidr.com'
    )
```

### Assigning Role to User
```python
UserRole.objects.create(
    user_email='seller@example.com',
    role=seller_role,
    assigned_by='admin@bidr.com'
)
```

### Granting Temporary Admin Access
```python
from datetime import datetime, timedelta

admin_role = UserRoleType.objects.get(role_name='Platform Admin')
UserRole.objects.create(
    user_email='temp-admin@example.com',
    role=admin_role,
    assigned_by='admin@bidr.com',
    end_date=datetime.now() + timedelta(days=7)  # Access for 7 days
)
```

This permissions system provides comprehensive access control for the BIDR platform while maintaining flexibility and ease of use.
