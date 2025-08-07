"""
URL patterns for the roles and permissions system.
"""
from django.urls import path, include
from rest_framework.routers import DefaultRouter

from .views import (
    PermissionViewSet, UserRoleTypeViewSet, UserRoleViewSet, UserPermissionViewSet,
    assign_role_to_user, assign_permission_to_user, bulk_assign_roles, 
    bulk_assign_permissions, get_user_permissions_summary, check_user_permission,
    remove_user_role, remove_user_permission
)

# Create router and register viewsets
router = DefaultRouter()
router.register('permissions', PermissionViewSet)
router.register('role-types', UserRoleTypeViewSet)
router.register('user-roles', UserRoleViewSet)
router.register('user-permissions', UserPermissionViewSet)

urlpatterns = [
    # Router URLs
    path('', include(router.urls)),
    
    # Assignment endpoints
    path('assign-role/', assign_role_to_user, name='assign-role'),
    path('assign-permission/', assign_permission_to_user, name='assign-permission'),
    
    # Bulk assignment endpoints
    path('bulk-assign-roles/', bulk_assign_roles, name='bulk-assign-roles'),
    path('bulk-assign-permissions/', bulk_assign_permissions, name='bulk-assign-permissions'),
    
    # User permission summary
    path('user-permissions-summary/', get_user_permissions_summary, name='user-permissions-summary'),
    
    # Permission checking
    path('check-permission/', check_user_permission, name='check-permission'),
    
    # Remove assignments
    path('remove-user-role/<str:user_email>/<int:role_id>/', remove_user_role, name='remove-user-role'),
    path('remove-user-permission/<str:user_email>/<int:permission_id>/', remove_user_permission, name='remove-user-permission'),
]
