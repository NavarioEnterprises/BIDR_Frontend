"""
Command to seed the permissions and roles system with default data for BIDR platform.
"""
from django.core.management.base import BaseCommand
from django.db import transaction

from ...models import Permission, UserRoleType, RolePermission


class Command(BaseCommand):
    help = 'Seed the database with default roles and permissions for the BIDR platform.'

    @transaction.atomic
    def handle(self, *args, **kwargs):
        self.stdout.write(self.style.SUCCESS('Starting to seed the database with default roles and permissions for BIDR platform.'))

        # Seed permissions for BIDR platform
        permissions_data = [
            # Auction Management
            {'name': 'View Auctions', 'type': 'view_only', 'module': 'auction_management', 'description': 'View auction listings'},
            {'name': 'Create Auctions', 'type': 'create', 'module': 'auction_management', 'description': 'Create new auctions'},
            {'name': 'Edit Auctions', 'type': 'edit', 'module': 'auction_management', 'description': 'Edit existing auctions'},
            {'name': 'Delete Auctions', 'type': 'delete', 'module': 'auction_management', 'description': 'Delete auctions'},
            {'name': 'Manage Auctions', 'type': 'manage', 'module': 'auction_management', 'description': 'Full auction management'},
            
            # Bid Management
            {'name': 'View Bids', 'type': 'view_only', 'module': 'bid_management', 'description': 'View bids on auctions'},
            {'name': 'Place Bids', 'type': 'create', 'module': 'bid_management', 'description': 'Place bids on auctions'},
            {'name': 'Manage Bids', 'type': 'manage', 'module': 'bid_management', 'description': 'Manage bid processes'},
            
            # Product Management
            {'name': 'View Products', 'type': 'view_only', 'module': 'product_management', 'description': 'View product listings'},
            {'name': 'Create Products', 'type': 'create', 'module': 'product_management', 'description': 'Add new products'},
            {'name': 'Edit Products', 'type': 'edit', 'module': 'product_management', 'description': 'Edit product details'},
            {'name': 'Delete Products', 'type': 'delete', 'module': 'product_management', 'description': 'Remove products'},
            
            # User Management
            {'name': 'View Users', 'type': 'view_only', 'module': 'user_management', 'description': 'View user profiles'},
            {'name': 'Manage Users', 'type': 'manage', 'module': 'user_management', 'description': 'Manage user accounts'},
            
            # Payment Processing
            {'name': 'View Payments', 'type': 'view_only', 'module': 'payment_processing', 'description': 'View payment records'},
            {'name': 'Process Payments', 'type': 'manage', 'module': 'payment_processing', 'description': 'Process payments'},
            
            # Document Verification
            {'name': 'View Documents', 'type': 'view_only', 'module': 'document_verification', 'description': 'View submitted documents'},
            {'name': 'Verify Documents', 'type': 'approve', 'module': 'document_verification', 'description': 'Verify user documents'},
            {'name': 'Reject Documents', 'type': 'reject', 'module': 'document_verification', 'description': 'Reject invalid documents'},
            
            # Reporting & Analytics
            {'name': 'View Reports', 'type': 'view_only', 'module': 'reporting', 'description': 'View system reports'},
            {'name': 'View Analytics', 'type': 'view_only', 'module': 'analytics', 'description': 'View platform analytics'},
            
            # System Administration
            {'name': 'System Configuration', 'type': 'admin', 'module': 'system_configuration', 'description': 'Configure system settings'},
            {'name': 'Platform Settings', 'type': 'admin', 'module': 'platform_settings', 'description': 'Manage platform settings'},
            
            # Support & Compliance
            {'name': 'Manage Support', 'type': 'manage', 'module': 'support', 'description': 'Handle customer support'},
            {'name': 'Compliance Management', 'type': 'manage', 'module': 'compliance', 'description': 'Manage compliance issues'},
        ]

        for perm_data in permissions_data:
            permission, created = Permission.objects.get_or_create(
                name=perm_data['name'], defaults=perm_data
            )
            if created:
                self.stdout.write(self.style.SUCCESS(f'Permission created: {permission.name} ({permission.type})'))
            else:
                self.stdout.write(self.style.NOTICE(f'Permission already exists: {permission.name} ({permission.type})'))

        # Seed roles for BIDR platform
        roles_data = [
            # Admin Roles
            {
                'role_name': 'Super Administrator',
                'company_type': 'super_admin',
                'role_level': 'super_admin',
                'role_job_function': 'super_admin',
                'function_department': 'administration'
            },
            {
                'role_name': 'Platform Administrator',
                'company_type': 'platform_admin',
                'role_level': 'platform_admin',
                'role_job_function': 'platform_admin',
                'function_department': 'administration'
            },
            
            # Business User Roles
            {
                'role_name': 'Individual Seller',
                'company_type': 'individual_seller',
                'role_level': 'basic_user',
                'role_job_function': 'seller_manager',
                'function_department': 'sales_marketing'
            },
            {
                'role_name': 'Business Seller',
                'company_type': 'business_seller',
                'role_level': 'basic_user',
                'role_job_function': 'seller_manager',
                'function_department': 'sales_marketing'
            },
            {
                'role_name': 'Individual Buyer',
                'company_type': 'individual_buyer',
                'role_level': 'basic_user',
                'role_job_function': 'buyer_manager',
                'function_department': 'sales_marketing'
            },
            {
                'role_name': 'Business Buyer',
                'company_type': 'business_buyer',
                'role_level': 'basic_user',
                'role_job_function': 'buyer_manager',
                'function_department': 'sales_marketing'
            },
            
            # Operational Roles
            {
                'role_name': 'Auction Manager',
                'company_type': 'auction_house',
                'role_level': 'middle_management',
                'role_job_function': 'auction_manager',
                'function_department': 'operations'
            },
            {
                'role_name': 'Document Verifier',
                'company_type': 'platform_admin',
                'role_level': 'specialist',
                'role_job_function': 'document_verifier',
                'function_department': 'compliance_legal'
            },
            {
                'role_name': 'Compliance Officer',
                'company_type': 'compliance_officer',
                'role_level': 'specialist',
                'role_job_function': 'compliance_manager',
                'function_department': 'compliance_legal'
            },
            {
                'role_name': 'Support Agent',
                'company_type': 'support_agent',
                'role_level': 'operational',
                'role_job_function': 'customer_service',
                'function_department': 'customer_service'
            },
        ]

        for role_data in roles_data:
            role, created = UserRoleType.objects.get_or_create(
                role_name=role_data['role_name'], defaults=role_data
            )
            if created:
                self.stdout.write(self.style.SUCCESS(f'Role created: {role.role_name}'))
            else:
                self.stdout.write(self.style.NOTICE(f'Role already exists: {role.role_name}'))

        # Assign permissions to roles
        role_permissions_data = [
            # Super Administrator - All permissions
            {
                'role': 'Super Administrator',
                'permissions': [
                    'System Configuration', 'Platform Settings', 'Manage Users',
                    'Manage Auctions', 'Manage Bids', 'Process Payments',
                    'Verify Documents', 'Reject Documents', 'View Reports',
                    'View Analytics', 'Compliance Management', 'Manage Support'
                ]
            },
            
            # Platform Administrator
            {
                'role': 'Platform Administrator',
                'permissions': [
                    'Manage Users', 'Manage Auctions', 'View Reports',
                    'View Analytics', 'Manage Support', 'View Documents'
                ]
            },
            
            # Individual Seller
            {
                'role': 'Individual Seller',
                'permissions': [
                    'View Auctions', 'Create Auctions', 'Edit Auctions',
                    'View Products', 'Create Products', 'Edit Products',
                    'View Bids', 'View Payments'
                ]
            },
            
            # Business Seller
            {
                'role': 'Business Seller',
                'permissions': [
                    'View Auctions', 'Create Auctions', 'Edit Auctions',
                    'View Products', 'Create Products', 'Edit Products', 'Delete Products',
                    'View Bids', 'View Payments'
                ]
            },
            
            # Individual Buyer
            {
                'role': 'Individual Buyer',
                'permissions': [
                    'View Auctions', 'View Products', 'View Bids', 'Place Bids',
                    'View Payments'
                ]
            },
            
            # Business Buyer
            {
                'role': 'Business Buyer',
                'permissions': [
                    'View Auctions', 'View Products', 'View Bids', 'Place Bids',
                    'View Payments'
                ]
            },
            
            # Auction Manager
            {
                'role': 'Auction Manager',
                'permissions': [
                    'Manage Auctions', 'Manage Bids', 'View Products',
                    'View Reports', 'View Analytics'
                ]
            },
            
            # Document Verifier
            {
                'role': 'Document Verifier',
                'permissions': [
                    'View Documents', 'Verify Documents', 'Reject Documents',
                    'View Users'
                ]
            },
            
            # Compliance Officer
            {
                'role': 'Compliance Officer',
                'permissions': [
                    'Compliance Management', 'View Documents', 'Verify Documents',
                    'Reject Documents', 'View Reports', 'View Users'
                ]
            },
            
            # Support Agent
            {
                'role': 'Support Agent',
                'permissions': [
                    'Manage Support', 'View Users', 'View Auctions',
                    'View Products', 'View Bids'
                ]
            },
        ]

        for rp_data in role_permissions_data:
            try:
                role = UserRoleType.objects.get(role_name=rp_data['role'])
                for perm_name in rp_data['permissions']:
                    try:
                        permission = Permission.objects.get(name=perm_name)
                        role_perm, created = RolePermission.objects.get_or_create(
                            role=role, permission=permission
                        )
                        if created:
                            self.stdout.write(self.style.SUCCESS(f'Assigned permission "{permission.name}" to role "{role.role_name}"'))
                        else:
                            self.stdout.write(self.style.NOTICE(f'Permission "{permission.name}" already assigned to role "{role.role_name}"'))
                    except Permission.DoesNotExist:
                        self.stdout.write(self.style.ERROR(f'Permission "{perm_name}" not found'))
            except UserRoleType.DoesNotExist:
                self.stdout.write(self.style.ERROR(f'Role "{rp_data["role"]}" not found'))

        self.stdout.write(self.style.SUCCESS('Successfully seeded the database with default roles and permissions for BIDR platform.'))
