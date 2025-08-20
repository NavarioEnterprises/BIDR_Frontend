"""
Roles and Permissions models for BIDR platform.
"""
from django.db import models
from django.core.exceptions import ValidationError


class Permission(models.Model):
    """
    Defines permissions that can be assigned to roles or users directly.
    """
    PERMISSION_TYPES = [
        ('view_only', 'View Only'),
        ('create', 'Create'),
        ('edit', 'Edit'),
        ('delete', 'Delete'),
        ('manage', 'Manage'),  # includes create, edit, and delete
        ('admin', 'Admin'),  # full access including manage
        ('approve', 'Approve'),  # for approval workflows
        ('reject', 'Reject'),  # for rejection workflows
        ('custom', 'Custom'),  # allows custom-defined permissions
    ]

    MODULE_TYPES = [
        ('auction_management', 'Auction Management'),
        ('bid_management', 'Bid Management'),
        ('product_management', 'Product Management'),
        ('user_management', 'User Management'),
        ('seller_management', 'Seller Management'),
        ('buyer_management', 'Buyer Management'),
        ('payment_processing', 'Payment Processing'),
        ('document_verification', 'Document Verification'),
        ('notifications_service', 'Notifications'),
        ('reporting', 'Reporting'),
        ('analytics', 'Analytics'),
        ('system_configuration', 'System Configuration'),
        ('compliance', 'Compliance'),
        ('support', 'Support'),
        ('messaging', 'Messaging'),
        ('logistics', 'Logistics'),
        ('inventory', 'Inventory'),
        ('financial_reports', 'Financial Reports'),
        ('dispute_resolution', 'Dispute Resolution'),
        ('platform_settings', 'Platform Settings'),
    ]

    permission_id = models.AutoField(primary_key=True)
    name = models.CharField(max_length=255, unique=True)
    type = models.CharField(max_length=50, choices=PERMISSION_TYPES, default='view_only')
    module = models.CharField(max_length=50, choices=MODULE_TYPES, default='auction_management')
    description = models.TextField(blank=True, null=True)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = "bidr_permissions"
        ordering = ['module', 'name']
        indexes = [
            models.Index(fields=['module', 'type']),
            models.Index(fields=['is_active']),
        ]

    def __str__(self):
        return f"{self.name} ({self.get_type_display()}) - {self.get_module_display()}"

    def clean(self):
        """Validate permission data."""
        if self.type == 'custom' and not self.description:
            raise ValidationError("Custom permissions must have a description.")


class UserRoleType(models.Model):
    """
    Defines role types available in the BIDR platform.
    """
    COMPANY_TYPE_CHOICES = [
        ('individual_seller', 'Individual Seller'),
        ('business_seller', 'Business Seller'),
        ('corporate_seller', 'Corporate Seller'),
        ('individual_buyer', 'Individual Buyer'),
        ('business_buyer', 'Business Buyer'),
        ('corporate_buyer', 'Corporate Buyer'),
        ('auction_house', 'Auction House'),
        ('platform_admin', 'Platform Admin'),
        ('super_admin', 'Super Admin'),
        ('moderator', 'Moderator'),
        ('support_agent', 'Support Agent'),
        ('financial_officer', 'Financial Officer'),
        ('compliance_officer', 'Compliance Officer'),
    ]

    ROLE_LEVEL_CHOICES = [
        ('super_admin', 'Super Admin'),
        ('platform_admin', 'Platform Admin'),
        ('senior_management', 'Senior Management'),
        ('middle_management', 'Middle Management'),
        ('operational', 'Operational'),
        ('specialist', 'Specialist'),
        ('basic_user', 'Basic User'),
        ('guest', 'Guest'),
        ('temporary', 'Temporary'),
    ]

    ROLE_JOB_FUNCTION_CHOICES = [
        ('super_admin', 'Super Administrator'),
        ('platform_admin', 'Platform Administrator'),
        ('auction_manager', 'Auction Manager'),
        ('seller_manager', 'Seller Manager'),
        ('buyer_manager', 'Buyer Manager'),
        ('payment_processor', 'Payment Processor'),
        ('document_verifier', 'Document Verifier'),
        ('compliance_manager', 'Compliance Manager'),
        ('support_manager', 'Support Manager'),
        ('financial_analyst', 'Financial Analyst'),
        ('marketing_manager', 'Marketing Manager'),
        ('system_analyst', 'System Analyst'),
        ('quality_assurance', 'Quality Assurance'),
        ('customer_service', 'Customer Service'),
        ('logistics_coordinator', 'Logistics Coordinator'),
        ('dispute_resolver', 'Dispute Resolver'),
        ('content_moderator', 'Content Moderator'),
        ('data_analyst', 'Data Analyst'),
        ('security_officer', 'Security Officer'),
    ]

    FUNCTION_DEPARTMENT_CHOICES = [
        ('administration', 'Administration'),
        ('operations', 'Operations'),
        ('sales_marketing', 'Sales & Marketing'),
        ('customer_service', 'Customer Service'),
        ('finance_accounting', 'Finance & Accounting'),
        ('compliance_legal', 'Compliance & Legal'),
        ('technology', 'Technology'),
        ('quality_assurance', 'Quality Assurance'),
        ('logistics_fulfillment', 'Logistics & Fulfillment'),
        ('business_development', 'Business Development'),
        ('product_management', 'Product Management'),
        ('data_analytics', 'Data & Analytics'),
        ('security', 'Security'),
        ('human_resources', 'Human Resources'),
        ('vendor_management', 'Vendor Management'),
    ]

    role_id = models.AutoField(primary_key=True)
    role_name = models.CharField(max_length=255, unique=True)
    company_type = models.CharField(max_length=50, choices=COMPANY_TYPE_CHOICES)
    role_level = models.CharField(max_length=50, choices=ROLE_LEVEL_CHOICES)
    role_job_function = models.CharField(max_length=50, choices=ROLE_JOB_FUNCTION_CHOICES)
    function_department = models.CharField(max_length=50, choices=FUNCTION_DEPARTMENT_CHOICES)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    permissions = models.ManyToManyField(Permission, through='RolePermission', related_name='role_types')

    class Meta:
        db_table = "bidr_user_role_types"
        ordering = ['company_type', 'role_level', 'role_name']
        indexes = [
            models.Index(fields=['company_type', 'role_level']),
            models.Index(fields=['is_active']),
        ]

    def __str__(self):
        return f"{self.role_name} ({self.get_company_type_display()})"

    def get_permissions_list(self):
        """Return a list of permissions associated with this role type."""
        return list(self.permissions.filter(is_active=True))

    def has_permission(self, permission_name, module=None):
        """Check if this role has a specific permission."""
        query = {'name': permission_name, 'is_active': True}
        if module:
            query['module'] = module
        return self.permissions.filter(**query).exists()

    def get_module_permissions(self, module):
        """Get all permissions for a specific module."""
        return self.permissions.filter(module=module, is_active=True)


class RolePermission(models.Model):
    """
    Through table for Role-Permission many-to-many relationship.
    """
    id = models.BigAutoField(primary_key=True)
    role = models.ForeignKey(UserRoleType, related_name='role_permissions', on_delete=models.CASCADE)
    permission = models.ForeignKey(Permission, related_name='role_permissions', on_delete=models.CASCADE)
    assigned_by = models.EmailField(blank=True, null=True)  # Who assigned this permission
    assigned_at = models.DateTimeField(auto_now_add=True)
    is_active = models.BooleanField(default=True)

    class Meta:
        db_table = "bidr_role_permissions"
        unique_together = ('role', 'permission')
        indexes = [
            models.Index(fields=['role', 'is_active']),
            models.Index(fields=['permission', 'is_active']),
        ]

    def __str__(self):
        return f"{self.role.role_name} - {self.permission.name}"


class UserRole(models.Model):
    """
    Assigns roles to users.
    """
    user_role_id = models.AutoField(primary_key=True)
    user_email = models.EmailField(db_index=True)
    role = models.ForeignKey(UserRoleType, related_name='user_roles', on_delete=models.CASCADE)
    assigned_by = models.EmailField(blank=True, null=True)  # Who assigned this role
    is_active = models.BooleanField(default=True)
    start_date = models.DateTimeField(auto_now_add=True)
    end_date = models.DateTimeField(blank=True, null=True)  # For temporary roles
    assigned_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = "bidr_user_roles"
        unique_together = ('user_email', 'role')
        indexes = [
            models.Index(fields=['user_email', 'is_active']),
            models.Index(fields=['role', 'is_active']),
        ]

    def __str__(self):
        return f"{self.user_email} - {self.role.role_name}"

    def deactivate(self, deactivated_by=None):
        """Deactivate this user role."""
        self.is_active = False
        if deactivated_by:
            self.assigned_by = deactivated_by
        self.save()

    def activate(self, activated_by=None):
        """Activate this user role."""
        self.is_active = True
        if activated_by:
            self.assigned_by = activated_by
        self.save()

    def is_expired(self):
        """Check if the role has expired."""
        if self.end_date:
            from django.utils import timezone
            return timezone.now() > self.end_date
        return False


class UserPermission(models.Model):
    """
    Direct permission assignments to users (overrides or additions to role permissions).
    """
    user_permission_id = models.AutoField(primary_key=True)
    user_email = models.EmailField(db_index=True)
    permission = models.ForeignKey(Permission, related_name='user_permissions', on_delete=models.CASCADE)
    permission_type = models.CharField(
        max_length=20,
        choices=[('grant', 'Grant'), ('deny', 'Deny')],
        default='grant',
        help_text="Grant adds permission, Deny removes it even if role has it"
    )
    assigned_by = models.EmailField(blank=True, null=True)
    is_active = models.BooleanField(default=True)
    start_date = models.DateTimeField(auto_now_add=True)
    end_date = models.DateTimeField(blank=True, null=True)  # For temporary permissions
    assigned_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = "bidr_user_permissions"
        unique_together = ('user_email', 'permission')
        indexes = [
            models.Index(fields=['user_email', 'is_active']),
            models.Index(fields=['permission', 'is_active']),
        ]

    def __str__(self):
        return f"{self.user_email} - {self.permission.name} ({self.permission_type})"

    def deactivate(self, deactivated_by=None):
        """Deactivate this user permission."""
        self.is_active = False
        if deactivated_by:
            self.assigned_by = deactivated_by
        self.save()

    def activate(self, activated_by=None):
        """Activate this user permission."""
        self.is_active = True
        if activated_by:
            self.assigned_by = activated_by
        self.save()

    def is_expired(self):
        """Check if the permission has expired."""
        if self.end_date:
            from django.utils import timezone
            return timezone.now() > self.end_date
        return False


class UserPermissionManager:
    """
    Utility class to manage user permissions combining roles and direct permissions.
    """

    @staticmethod
    def get_user_permissions(user_email):
        """
        Get all effective permissions for a user.
        Combines role permissions and direct user permissions.
        """
        from django.utils import timezone
        now = timezone.now()

        # Get permissions from active roles
        role_permissions = Permission.objects.filter(
            role_permissions__role__user_roles__user_email=user_email,
            role_permissions__role__user_roles__is_active=True,
            role_permissions__role__is_active=True,
            role_permissions__is_active=True,
            is_active=True
        ).filter(
            models.Q(role_permissions__role__user_roles__end_date__isnull=True) |
            models.Q(role_permissions__role__user_roles__end_date__gt=now)
        ).distinct()

        # Get direct user permissions (grants)
        direct_grant_permissions = Permission.objects.filter(
            user_permissions__user_email=user_email,
            user_permissions__permission_type='grant',
            user_permissions__is_active=True,
            is_active=True
        ).filter(
            models.Q(user_permissions__end_date__isnull=True) |
            models.Q(user_permissions__end_date__gt=now)
        ).distinct()

        # Get direct user permissions (denies)
        direct_deny_permissions = Permission.objects.filter(
            user_permissions__user_email=user_email,
            user_permissions__permission_type='deny',
            user_permissions__is_active=True,
            is_active=True
        ).filter(
            models.Q(user_permissions__end_date__isnull=True) |
            models.Q(user_permissions__end_date__gt=now)
        ).distinct()

        # Combine role permissions and direct grants, then exclude denies
        all_permissions = (role_permissions | direct_grant_permissions).exclude(
            id__in=direct_deny_permissions.values_list('id', flat=True)
        )

        return all_permissions.distinct()

    @staticmethod
    def user_has_permission(user_email, permission_name, module=None):
        """
        Check if a user has a specific permission.
        """
        query = {'name': permission_name}
        if module:
            query['module'] = module
            
        user_permissions = UserPermissionManager.get_user_permissions(user_email)
        return user_permissions.filter(**query).exists()

    @staticmethod
    def get_user_roles(user_email):
        """
        Get all active roles for a user.
        """
        from django.utils import timezone
        now = timezone.now()
        
        return UserRoleType.objects.filter(
            user_roles__user_email=user_email,
            user_roles__is_active=True,
            is_active=True
        ).filter(
            models.Q(user_roles__end_date__isnull=True) |
            models.Q(user_roles__end_date__gt=now)
        ).distinct()

    @staticmethod
    def get_user_module_permissions(user_email, module):
        """
        Get all permissions for a user in a specific module.
        """
        return UserPermissionManager.get_user_permissions(user_email).filter(module=module)
