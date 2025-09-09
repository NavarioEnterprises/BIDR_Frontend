"""
Serializers for the roles and permissions system.
"""
from rest_framework import serializers

from .models import Permission, UserRoleType, RolePermission, UserRole, UserPermission, UserPermissionManager


class PermissionSerializer(serializers.ModelSerializer):
    """Serializer for Permission model."""
    
    type_display = serializers.CharField(source='get_type_display', read_only=True)
    module_display = serializers.CharField(source='get_module_display', read_only=True)
    
    class Meta:
        model = Permission
        fields = [
            'permission_id', 'name', 'type', 'type_display', 
            'module', 'module_display', 'description', 'is_active',
            'created_at', 'updated_at'
        ]
        read_only_fields = ['permission_id', 'created_at', 'updated_at']


class UserRoleTypeSerializer(serializers.ModelSerializer):
    """Serializer for UserRoleType model."""
    
    company_type_display = serializers.CharField(source='get_company_type_display', read_only=True)
    role_level_display = serializers.CharField(source='get_role_level_display', read_only=True)
    role_job_function_display = serializers.CharField(source='get_role_job_function_display', read_only=True)
    function_department_display = serializers.CharField(source='get_function_department_display', read_only=True)
    permissions_count = serializers.SerializerMethodField()
    permissions_list = PermissionSerializer(source='get_permissions_list', many=True, read_only=True)
    
    class Meta:
        model = UserRoleType
        fields = [
            'role_id', 'role_name', 'company_type', 'company_type_display',
            'role_level', 'role_level_display', 'role_job_function', 
            'role_job_function_display', 'function_department', 
            'function_department_display', 'is_active', 'created_at', 
            'updated_at', 'permissions_count', 'permissions_list'
        ]
        read_only_fields = ['role_id', 'created_at', 'updated_at']
    
    def get_permissions_count(self, obj):
        """Get the count of active permissions for this role."""
        return obj.permissions.filter(is_active=True).count()


class RolePermissionSerializer(serializers.ModelSerializer):
    """Serializer for RolePermission model."""
    
    role_name = serializers.CharField(source='role.role_name', read_only=True)
    permission_name = serializers.CharField(source='permission.name', read_only=True)
    permission_module = serializers.CharField(source='permission.module', read_only=True)
    permission_type = serializers.CharField(source='permission.type', read_only=True)
    
    class Meta:
        model = RolePermission
        fields = [
            'id', 'role', 'role_name', 'permission', 'permission_name',
            'permission_module', 'permission_type', 'assigned_by',
            'assigned_at', 'is_active'
        ]
        read_only_fields = ['id', 'assigned_at']


class UserRoleSerializer(serializers.ModelSerializer):
    """Serializer for UserRole model."""
    
    role_name = serializers.CharField(source='role.role_name', read_only=True)
    role_details = UserRoleTypeSerializer(source='role', read_only=True)
    is_expired = serializers.SerializerMethodField()
    
    class Meta:
        model = UserRole
        fields = [
            'user_role_id', 'user_email', 'role', 'role_name', 'role_details',
            'assigned_by', 'is_active', 'start_date', 'end_date',
            'assigned_at', 'updated_at', 'is_expired'
        ]
        read_only_fields = ['user_role_id', 'assigned_at', 'updated_at']
    
    def get_is_expired(self, obj):
        """Check if the role has expired."""
        return obj.is_expired()


class UserPermissionSerializer(serializers.ModelSerializer):
    """Serializer for UserPermission model."""
    
    permission_name = serializers.CharField(source='permission.name', read_only=True)
    permission_details = PermissionSerializer(source='permission', read_only=True)
    is_expired = serializers.SerializerMethodField()
    
    class Meta:
        model = UserPermission
        fields = [
            'user_permission_id', 'user_email', 'permission', 'permission_name',
            'permission_details', 'permission_type', 'assigned_by', 'is_active',
            'start_date', 'end_date', 'assigned_at', 'updated_at', 'is_expired'
        ]
        read_only_fields = ['user_permission_id', 'assigned_at', 'updated_at']
    
    def get_is_expired(self, obj):
        """Check if the permission has expired."""
        return obj.is_expired()


class UserPermissionSummarySerializer(serializers.Serializer):
    """Serializer for user permission summary."""
    
    user_email = serializers.EmailField()
    roles = UserRoleSerializer(many=True, read_only=True)
    direct_permissions = UserPermissionSerializer(many=True, read_only=True)
    effective_permissions = PermissionSerializer(many=True, read_only=True)
    permissions_by_module = serializers.DictField(read_only=True)
    
    def to_representation(self, instance):
        """Custom representation to include computed fields."""
        user_email = instance.get('user_email')
        
        # Get user roles
        user_roles = UserRole.objects.filter(
            user_email=user_email, 
            is_active=True
        ).select_related('role')
        
        # Get direct permissions
        direct_permissions = UserPermission.objects.filter(
            user_email=user_email,
            is_active=True
        ).select_related('permission')
        
        # Get effective permissions
        effective_permissions = UserPermissionManager.get_user_permissions(user_email)
        
        # Group permissions by module
        permissions_by_module = {}
        for permission in effective_permissions:
            module = permission.get_module_display()
            if module not in permissions_by_module:
                permissions_by_module[module] = []
            permissions_by_module[module].append({
                'name': permission.name,
                'type': permission.get_type_display(),
                'description': permission.description
            })
        
        return {
            'user_email': user_email,
            'roles': UserRoleSerializer(user_roles, many=True).data,
            'direct_permissions': UserPermissionSerializer(direct_permissions, many=True).data,
            'effective_permissions': PermissionSerializer(effective_permissions, many=True).data,
            'permissions_by_module': permissions_by_module
        }


class AssignRoleSerializer(serializers.Serializer):
    """Serializer for assigning roles to users."""
    
    user_email = serializers.EmailField()
    role_id = serializers.IntegerField()
    assigned_by = serializers.EmailField(required=False)
    end_date = serializers.DateTimeField(required=False)
    
    def validate_role_id(self, value):
        """Validate that the role exists and is active."""
        try:
            role = UserRoleType.objects.get(role_id=value, is_active=True)
            return value
        except UserRoleType.DoesNotExist:
            raise serializers.ValidationError("Role does not exist or is not active.")
    
    def create(self, validated_data):
        """Create a new user role assignment."""
        return UserRole.objects.create(**validated_data)


class AssignPermissionSerializer(serializers.Serializer):
    """Serializer for assigning permissions to users."""
    
    user_email = serializers.EmailField()
    permission_id = serializers.IntegerField()
    permission_type = serializers.ChoiceField(choices=[('grant', 'Grant'), ('deny', 'Deny')])
    assigned_by = serializers.EmailField(required=False)
    end_date = serializers.DateTimeField(required=False)
    
    def validate_permission_id(self, value):
        """Validate that the permission exists and is active."""
        try:
            permission = Permission.objects.get(permission_id=value, is_active=True)
            return value
        except Permission.DoesNotExist:
            raise serializers.ValidationError("Permission does not exist or is not active.")
    
    def create(self, validated_data):
        """Create a new user permission assignment."""
        return UserPermission.objects.create(**validated_data)


class BulkAssignRolesSerializer(serializers.Serializer):
    """Serializer for bulk role assignments."""
    
    user_emails = serializers.ListField(
        child=serializers.EmailField(),
        min_length=1,
        max_length=100
    )
    role_id = serializers.IntegerField()
    assigned_by = serializers.EmailField(required=False)
    end_date = serializers.DateTimeField(required=False)
    
    def validate_role_id(self, value):
        """Validate that the role exists and is active."""
        try:
            role = UserRoleType.objects.get(role_id=value, is_active=True)
            return value
        except UserRoleType.DoesNotExist:
            raise serializers.ValidationError("Role does not exist or is not active.")


class BulkAssignPermissionsSerializer(serializers.Serializer):
    """Serializer for bulk permission assignments."""
    
    user_emails = serializers.ListField(
        child=serializers.EmailField(),
        min_length=1,
        max_length=100
    )
    permission_ids = serializers.ListField(
        child=serializers.IntegerField(),
        min_length=1,
        max_length=50
    )
    permission_type = serializers.ChoiceField(choices=[('grant', 'Grant'), ('deny', 'Deny')])
    assigned_by = serializers.EmailField(required=False)
    end_date = serializers.DateTimeField(required=False)
    
    def validate_permission_ids(self, value):
        """Validate that all permissions exist and are active."""
        existing_permissions = Permission.objects.filter(
            permission_id__in=value, 
            is_active=True
        ).values_list('permission_id', flat=True)
        
        if len(existing_permissions) != len(value):
            missing_ids = set(value) - set(existing_permissions)
            raise serializers.ValidationError(
                f"The following permission IDs do not exist or are not active: {list(missing_ids)}"
            )
        
        return value
