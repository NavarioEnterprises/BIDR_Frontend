"""
Views for the roles and permissions system.
"""
from django.db import transaction
from django.shortcuts import get_object_or_404
from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.viewsets import ModelViewSet
from rest_framework.decorators import action
from django_filters.rest_framework import DjangoFilterBackend
from rest_framework.filters import SearchFilter, OrderingFilter

from .models import (
    Permission, UserRoleType, RolePermission, UserRole, 
    UserPermission, UserPermissionManager
)
from .serializers import (
    PermissionSerializer, UserRoleTypeSerializer, RolePermissionSerializer,
    UserRoleSerializer, UserPermissionSerializer, UserPermissionSummarySerializer,
    AssignRoleSerializer, AssignPermissionSerializer, BulkAssignRolesSerializer,
    BulkAssignPermissionsSerializer
)


class PermissionViewSet(ModelViewSet):
    """ViewSet for managing permissions."""
    
    queryset = Permission.objects.all()
    serializer_class = PermissionSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [DjangoFilterBackend, SearchFilter, OrderingFilter]
    filterset_fields = ['type', 'module', 'is_active']
    search_fields = ['name', 'description']
    ordering_fields = ['name', 'module', 'type', 'created_at']
    ordering = ['module', 'name']

    @action(detail=False, methods=['get'])
    def modules(self, request):
        """Get all available modules."""
        modules = [{'value': choice[0], 'label': choice[1]} 
                  for choice in Permission.MODULE_TYPES]
        return Response({'modules': modules})

    @action(detail=False, methods=['get'])
    def types(self, request):
        """Get all available permission types."""
        types = [{'value': choice[0], 'label': choice[1]} 
                for choice in Permission.PERMISSION_TYPES]
        return Response({'types': types})


class UserRoleTypeViewSet(ModelViewSet):
    """ViewSet for managing role types."""
    
    queryset = UserRoleType.objects.all()
    serializer_class = UserRoleTypeSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [DjangoFilterBackend, SearchFilter, OrderingFilter]
    filterset_fields = ['company_type', 'role_level', 'role_job_function', 'function_department', 'is_active']
    search_fields = ['role_name']
    ordering_fields = ['role_name', 'company_type', 'role_level', 'created_at']
    ordering = ['company_type', 'role_level', 'role_name']

    @action(detail=True, methods=['post'])
    def assign_permissions(self, request, pk=None):
        """Assign permissions to a role."""
        role = self.get_object()
        permission_ids = request.data.get('permission_ids', [])
        assigned_by = request.data.get('assigned_by', request.user.email)

        if not permission_ids:
            return Response(
                {'error': 'permission_ids is required'}, 
                status=status.HTTP_400_BAD_REQUEST
            )

        permissions = Permission.objects.filter(
            permission_id__in=permission_ids, 
            is_active=True
        )

        if len(permissions) != len(permission_ids):
            return Response(
                {'error': 'Some permissions do not exist or are not active'}, 
                status=status.HTTP_400_BAD_REQUEST
            )

        with transaction.atomic():
            for permission in permissions:
                RolePermission.objects.get_or_create(
                    role=role,
                    permission=permission,
                    defaults={'assigned_by': assigned_by}
                )

        return Response({'message': f'Assigned {len(permissions)} permissions to role'})

    @action(detail=True, methods=['delete'])
    def remove_permissions(self, request, pk=None):
        """Remove permissions from a role."""
        role = self.get_object()
        permission_ids = request.data.get('permission_ids', [])

        if not permission_ids:
            return Response(
                {'error': 'permission_ids is required'}, 
                status=status.HTTP_400_BAD_REQUEST
            )

        deleted_count = RolePermission.objects.filter(
            role=role,
            permission__permission_id__in=permission_ids
        ).delete()[0]

        return Response({'message': f'Removed {deleted_count} permissions from role'})

    @action(detail=False, methods=['get'])
    def choices(self, request):
        """Get all choice fields for role creation."""
        return Response({
            'company_types': [{'value': choice[0], 'label': choice[1]} 
                            for choice in UserRoleType.COMPANY_TYPE_CHOICES],
            'role_levels': [{'value': choice[0], 'label': choice[1]} 
                          for choice in UserRoleType.ROLE_LEVEL_CHOICES],
            'job_functions': [{'value': choice[0], 'label': choice[1]} 
                            for choice in UserRoleType.ROLE_JOB_FUNCTION_CHOICES],
            'departments': [{'value': choice[0], 'label': choice[1]} 
                          for choice in UserRoleType.FUNCTION_DEPARTMENT_CHOICES],
        })


class UserRoleViewSet(ModelViewSet):
    """ViewSet for managing user role assignments."""
    
    queryset = UserRole.objects.all()
    serializer_class = UserRoleSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [DjangoFilterBackend, SearchFilter, OrderingFilter]
    filterset_fields = ['user_email', 'role', 'is_active']
    search_fields = ['user_email', 'role__role_name']
    ordering_fields = ['user_email', 'assigned_at', 'updated_at']
    ordering = ['-assigned_at']

    @action(detail=True, methods=['post'])
    def activate(self, request, pk=None):
        """Activate a user role."""
        user_role = self.get_object()
        user_role.activate(activated_by=request.user.email)
        return Response({'message': 'User role activated successfully'})

    @action(detail=True, methods=['post'])
    def deactivate(self, request, pk=None):
        """Deactivate a user role."""
        user_role = self.get_object()
        user_role.deactivate(deactivated_by=request.user.email)
        return Response({'message': 'User role deactivated successfully'})

    @action(detail=False, methods=['get'])
    def by_user(self, request):
        """Get roles for a specific user."""
        user_email = request.query_params.get('email')
        if not user_email:
            return Response(
                {'error': 'email parameter is required'}, 
                status=status.HTTP_400_BAD_REQUEST
            )

        user_roles = self.queryset.filter(user_email=user_email, is_active=True)
        serializer = self.get_serializer(user_roles, many=True)
        return Response(serializer.data)


class UserPermissionViewSet(ModelViewSet):
    """ViewSet for managing user permission assignments."""
    
    queryset = UserPermission.objects.all()
    serializer_class = UserPermissionSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [DjangoFilterBackend, SearchFilter, OrderingFilter]
    filterset_fields = ['user_email', 'permission', 'permission_type', 'is_active']
    search_fields = ['user_email', 'permission__name']
    ordering_fields = ['user_email', 'assigned_at', 'updated_at']
    ordering = ['-assigned_at']

    @action(detail=True, methods=['post'])
    def activate(self, request, pk=None):
        """Activate a user permission."""
        user_permission = self.get_object()
        user_permission.activate(activated_by=request.user.email)
        return Response({'message': 'User permission activated successfully'})

    @action(detail=True, methods=['post'])
    def deactivate(self, request, pk=None):
        """Deactivate a user permission."""
        user_permission = self.get_object()
        user_permission.deactivate(deactivated_by=request.user.email)
        return Response({'message': 'User permission deactivated successfully'})

    @action(detail=False, methods=['get'])
    def by_user(self, request):
        """Get permissions for a specific user."""
        user_email = request.query_params.get('email')
        if not user_email:
            return Response(
                {'error': 'email parameter is required'}, 
                status=status.HTTP_400_BAD_REQUEST
            )

        user_permissions = self.queryset.filter(user_email=user_email, is_active=True)
        serializer = self.get_serializer(user_permissions, many=True)
        return Response(serializer.data)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def assign_role_to_user(request):
    """Assign a role to a user."""
    serializer = AssignRoleSerializer(data=request.data)
    if serializer.is_valid():
        # Check if user already has this role
        existing_role = UserRole.objects.filter(
            user_email=serializer.validated_data['user_email'],
            role_id=serializer.validated_data['role_id'],
            is_active=True
        ).first()

        if existing_role:
            return Response(
                {'error': 'User already has this role assigned'}, 
                status=status.HTTP_400_BAD_REQUEST
            )

        # Set assigned_by to current user if not provided
        if 'assigned_by' not in serializer.validated_data:
            serializer.validated_data['assigned_by'] = request.user.email

        user_role = serializer.save()
        response_serializer = UserRoleSerializer(user_role)
        return Response(response_serializer.data, status=status.HTTP_201_CREATED)
    
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def assign_permission_to_user(request):
    """Assign a permission to a user."""
    serializer = AssignPermissionSerializer(data=request.data)
    if serializer.is_valid():
        # Check if user already has this permission
        existing_permission = UserPermission.objects.filter(
            user_email=serializer.validated_data['user_email'],
            permission_id=serializer.validated_data['permission_id'],
            is_active=True
        ).first()

        if existing_permission:
            # Update the existing permission
            for key, value in serializer.validated_data.items():
                setattr(existing_permission, key, value)
            existing_permission.save()
            response_serializer = UserPermissionSerializer(existing_permission)
            return Response(response_serializer.data)

        # Set assigned_by to current user if not provided
        if 'assigned_by' not in serializer.validated_data:
            serializer.validated_data['assigned_by'] = request.user.email

        user_permission = serializer.save()
        response_serializer = UserPermissionSerializer(user_permission)
        return Response(response_serializer.data, status=status.HTTP_201_CREATED)
    
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def bulk_assign_roles(request):
    """Bulk assign roles to multiple users."""
    serializer = BulkAssignRolesSerializer(data=request.data)
    if serializer.is_valid():
        user_emails = serializer.validated_data['user_emails']
        role_id = serializer.validated_data['role_id']
        assigned_by = serializer.validated_data.get('assigned_by', request.user.email)
        end_date = serializer.validated_data.get('end_date')

        role = UserRoleType.objects.get(role_id=role_id)
        created_assignments = []
        skipped_assignments = []

        with transaction.atomic():
            for user_email in user_emails:
                existing_role = UserRole.objects.filter(
                    user_email=user_email,
                    role=role,
                    is_active=True
                ).first()

                if existing_role:
                    skipped_assignments.append(user_email)
                else:
                    user_role = UserRole.objects.create(
                        user_email=user_email,
                        role=role,
                        assigned_by=assigned_by,
                        end_date=end_date
                    )
                    created_assignments.append(user_email)

        return Response({
            'message': f'Bulk role assignment completed',
            'created': len(created_assignments),
            'skipped': len(skipped_assignments),
            'created_assignments': created_assignments,
            'skipped_assignments': skipped_assignments
        })
    
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def bulk_assign_permissions(request):
    """Bulk assign permissions to multiple users."""
    serializer = BulkAssignPermissionsSerializer(data=request.data)
    if serializer.is_valid():
        user_emails = serializer.validated_data['user_emails']
        permission_ids = serializer.validated_data['permission_ids']
        permission_type = serializer.validated_data['permission_type']
        assigned_by = serializer.validated_data.get('assigned_by', request.user.email)
        end_date = serializer.validated_data.get('end_date')

        permissions = Permission.objects.filter(permission_id__in=permission_ids)
        created_assignments = []
        updated_assignments = []

        with transaction.atomic():
            for user_email in user_emails:
                for permission in permissions:
                    user_permission, created = UserPermission.objects.update_or_create(
                        user_email=user_email,
                        permission=permission,
                        defaults={
                            'permission_type': permission_type,
                            'assigned_by': assigned_by,
                            'end_date': end_date,
                            'is_active': True
                        }
                    )
                    
                    if created:
                        created_assignments.append(f"{user_email} - {permission.name}")
                    else:
                        updated_assignments.append(f"{user_email} - {permission.name}")

        return Response({
            'message': f'Bulk permission assignment completed',
            'created': len(created_assignments),
            'updated': len(updated_assignments),
            'created_assignments': created_assignments,
            'updated_assignments': updated_assignments
        })
    
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_user_permissions_summary(request):
    """Get comprehensive permissions summary for a user."""
    user_email = request.query_params.get('email')
    if not user_email:
        return Response(
            {'error': 'email parameter is required'}, 
            status=status.HTTP_400_BAD_REQUEST
        )

    serializer = UserPermissionSummarySerializer({'user_email': user_email})
    return Response(serializer.data)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def check_user_permission(request):
    """Check if a user has a specific permission."""
    user_email = request.data.get('user_email')
    permission_name = request.data.get('permission_name')
    module = request.data.get('module')

    if not user_email or not permission_name:
        return Response(
            {'error': 'user_email and permission_name are required'}, 
            status=status.HTTP_400_BAD_REQUEST
        )

    has_permission = UserPermissionManager.user_has_permission(
        user_email, permission_name, module
    )

    return Response({
        'user_email': user_email,
        'permission_name': permission_name,
        'module': module,
        'has_permission': has_permission
    })


@api_view(['DELETE'])
@permission_classes([IsAuthenticated])
def remove_user_role(request, user_email, role_id):
    """Remove a role from a user."""
    user_role = get_object_or_404(
        UserRole,
        user_email=user_email,
        role_id=role_id,
        is_active=True
    )
    
    user_role.deactivate(deactivated_by=request.user.email)
    return Response({'message': 'Role removed from user successfully'})


@api_view(['DELETE'])
@permission_classes([IsAuthenticated])
def remove_user_permission(request, user_email, permission_id):
    """Remove a permission from a user."""
    user_permission = get_object_or_404(
        UserPermission,
        user_email=user_email,
        permission_id=permission_id,
        is_active=True
    )
    
    user_permission.deactivate(deactivated_by=request.user.email)
    return Response({'message': 'Permission removed from user successfully'})
