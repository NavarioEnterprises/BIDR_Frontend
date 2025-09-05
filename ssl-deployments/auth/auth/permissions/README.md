# BIDR Permissions & Roles App

This Django app provides a comprehensive permissions and role-based access control (RBAC) system for the BIDR platform.

## Features

- **Granular Permissions**: Fine-grained control over user actions
- **Role-Based Access Control**: Assign permissions to roles, then roles to users
- **Direct User Permissions**: Override or extend role permissions for specific users
- **Time-Based Access**: Set expiration dates for roles and permissions
- **Module-Based Organization**: Permissions organized by functional modules
- **Django Admin Integration**: Full admin interface for managing permissions
- **REST API**: Complete API for permissions management
- **Permission Decorators**: Easy-to-use decorators for views
- **Audit Trail**: Track who assigned permissions and when

## Installation

1. The app is already included in the `INSTALLED_APPS` setting
2. Run migrations to create the database tables:
   ```bash
   python manage.py makemigrations permissions
   python manage.py migrate
   ```
3. Seed the database with default permissions and roles:
   ```bash
   python manage.py seed_permissions
   ```

## Quick Start

### 1. Create a Permission
```python
from permissions.models import Permission

permission = Permission.objects.create(
    name='Create Auctions',
    type='create',
    module='auction_management',
    description='Allows user to create new auctions'
)
```

### 2. Create a Role
```python
from permissions.models import UserRoleType, RolePermission

role = UserRoleType.objects.create(
    role_name='Auction Manager',
    company_type='auction_house',
    role_level='middle_management',
    role_job_function='auction_manager',
    function_department='operations'
)

# Assign permission to role
RolePermission.objects.create(role=role, permission=permission)
```

### 3. Assign Role to User
```python
from permissions.models import UserRole

UserRole.objects.create(
    user_email='user@example.com',
    role=role,
    assigned_by='admin@bidr.com'
)
```

### 4. Check Permissions in Views
```python
from permissions.decorators import require_permission

@require_permission('Create Auctions', 'auction_management')
def create_auction_view(request):
    # Your view logic here
    pass
```

## API Endpoints

All API endpoints are available under `/permissions/`:

- `/permissions/permissions/` - Manage permissions
- `/permissions/role-types/` - Manage role types
- `/permissions/user-roles/` - Manage user role assignments
- `/permissions/user-permissions/` - Manage direct user permissions
- `/permissions/assign-role/` - Assign role to user
- `/permissions/assign-permission/` - Assign permission to user
- `/permissions/check-permission/` - Check user permissions
- `/permissions/user-permissions-summary/` - Get user permission summary

## Models

### Core Models
- **Permission**: Defines what actions can be performed
- **UserRoleType**: Defines different user roles in the system
- **RolePermission**: Links roles to permissions
- **UserRole**: Assigns roles to users
- **UserPermission**: Direct permission assignments to users

### Utility Classes
- **UserPermissionManager**: Manages user permissions combining roles and direct permissions

## Permission Types

- `view_only`: Read-only access
- `create`: Can create new items
- `edit`: Can modify existing items
- `delete`: Can remove items
- `manage`: Includes create, edit, and delete
- `admin`: Full access including manage
- `approve`: Can approve items (for workflows)
- `reject`: Can reject items (for workflows)
- `custom`: Custom-defined permissions

## Modules

The system supports the following modules:
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

## Management Commands

### seed_permissions
Seeds the database with default permissions and roles for the BIDR platform.

```bash
python manage.py seed_permissions
```

## Usage Examples

See [PERMISSIONS_USAGE.md](./PERMISSIONS_USAGE.md) for comprehensive usage examples and API documentation.

## Development

### Adding New Permissions
1. Add the permission to the seed command in `management/commands/seed_permissions.py`
2. Run the seed command to create the permission
3. Assign the permission to appropriate roles

### Adding New Modules
1. Add the module to `MODULE_TYPES` in `models.py`
2. Create permissions for the new module
3. Update the seed command

### Testing
```bash
python manage.py test permissions
```

## Security Considerations

1. Always use the permission decorators or check permissions programmatically
2. Regularly audit user permissions and remove unnecessary access
3. Use expiration dates for temporary access
4. Follow the principle of least privilege
5. Keep sensitive permissions restricted to admin roles

## Contributing

When adding new features to the permissions system:
1. Update the models if needed
2. Add appropriate API endpoints
3. Update the admin interface
4. Add tests
5. Update documentation

## Support

For questions about the permissions system, refer to:
- [PERMISSIONS_USAGE.md](./PERMISSIONS_USAGE.md) - Comprehensive usage guide
- Django admin interface at `/admin/`
- API documentation at `/permissions/` endpoints
