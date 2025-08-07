"""
Permission decorators for views and API endpoints.
"""
from functools import wraps
from django.http import JsonResponse
from django.contrib.auth.decorators import login_required
from rest_framework.response import Response
from rest_framework import status

from .models import UserPermissionManager


def require_permission(permission_name, module=None):
    """
    Decorator to check if a user has a specific permission.
    
    Args:
        permission_name (str): The name of the permission to check
        module (str, optional): The module to check the permission in
    
    Usage:
        @require_permission('Create Auctions', 'auction_management')
        def create_auction_view(request):
            # View logic here
            pass
    """
    def decorator(view_func):
        @wraps(view_func)
        def wrapper(request, *args, **kwargs):
            # Check if user is authenticated
            if not request.user.is_authenticated:
                if hasattr(request, 'accepted_renderer'):
                    # DRF request
                    return Response(
                        {'error': 'Authentication required'}, 
                        status=status.HTTP_401_UNAUTHORIZED
                    )
                else:
                    # Django request
                    return JsonResponse(
                        {'error': 'Authentication required'}, 
                        status=401
                    )
            
            # Get user email
            user_email = getattr(request.user, 'email', None)
            if not user_email:
                if hasattr(request, 'accepted_renderer'):
                    return Response(
                        {'error': 'User email not found'}, 
                        status=status.HTTP_400_BAD_REQUEST
                    )
                else:
                    return JsonResponse(
                        {'error': 'User email not found'}, 
                        status=400
                    )
            
            # Check permission
            has_permission = UserPermissionManager.user_has_permission(
                user_email, permission_name, module
            )
            
            if not has_permission:
                if hasattr(request, 'accepted_renderer'):
                    return Response(
                        {
                            'error': 'Permission denied',
                            'required_permission': permission_name,
                            'module': module
                        }, 
                        status=status.HTTP_403_FORBIDDEN
                    )
                else:
                    return JsonResponse(
                        {
                            'error': 'Permission denied',
                            'required_permission': permission_name,
                            'module': module
                        }, 
                        status=403
                    )
            
            return view_func(request, *args, **kwargs)
        return wrapper
    return decorator


def require_any_permission(*permissions):
    """
    Decorator to check if a user has any of the specified permissions.
    
    Args:
        *permissions: Tuples of (permission_name, module) or just permission_name strings
    
    Usage:
        @require_any_permission(
            ('Create Auctions', 'auction_management'),
            ('Edit Auctions', 'auction_management')
        )
        def auction_view(request):
            # View logic here
            pass
    """
    def decorator(view_func):
        @wraps(view_func)
        def wrapper(request, *args, **kwargs):
            # Check if user is authenticated
            if not request.user.is_authenticated:
                if hasattr(request, 'accepted_renderer'):
                    return Response(
                        {'error': 'Authentication required'}, 
                        status=status.HTTP_401_UNAUTHORIZED
                    )
                else:
                    return JsonResponse(
                        {'error': 'Authentication required'}, 
                        status=401
                    )
            
            # Get user email
            user_email = getattr(request.user, 'email', None)
            if not user_email:
                if hasattr(request, 'accepted_renderer'):
                    return Response(
                        {'error': 'User email not found'}, 
                        status=status.HTTP_400_BAD_REQUEST
                    )
                else:
                    return JsonResponse(
                        {'error': 'User email not found'}, 
                        status=400
                    )
            
            # Check if user has any of the required permissions
            has_permission = False
            for perm in permissions:
                if isinstance(perm, tuple):
                    permission_name, module = perm
                else:
                    permission_name, module = perm, None
                
                if UserPermissionManager.user_has_permission(user_email, permission_name, module):
                    has_permission = True
                    break
            
            if not has_permission:
                required_perms = []
                for perm in permissions:
                    if isinstance(perm, tuple):
                        required_perms.append(f"{perm[0]} ({perm[1]})")
                    else:
                        required_perms.append(perm)
                
                if hasattr(request, 'accepted_renderer'):
                    return Response(
                        {
                            'error': 'Permission denied',
                            'required_permissions': required_perms
                        }, 
                        status=status.HTTP_403_FORBIDDEN
                    )
                else:
                    return JsonResponse(
                        {
                            'error': 'Permission denied',
                            'required_permissions': required_perms
                        }, 
                        status=403
                    )
            
            return view_func(request, *args, **kwargs)
        return wrapper
    return decorator


def require_all_permissions(*permissions):
    """
    Decorator to check if a user has all of the specified permissions.
    
    Args:
        *permissions: Tuples of (permission_name, module) or just permission_name strings
    
    Usage:
        @require_all_permissions(
            ('Create Auctions', 'auction_management'),
            ('Manage Users', 'user_management')
        )
        def admin_view(request):
            # View logic here
            pass
    """
    def decorator(view_func):
        @wraps(view_func)
        def wrapper(request, *args, **kwargs):
            # Check if user is authenticated
            if not request.user.is_authenticated:
                if hasattr(request, 'accepted_renderer'):
                    return Response(
                        {'error': 'Authentication required'}, 
                        status=status.HTTP_401_UNAUTHORIZED
                    )
                else:
                    return JsonResponse(
                        {'error': 'Authentication required'}, 
                        status=401
                    )
            
            # Get user email
            user_email = getattr(request.user, 'email', None)
            if not user_email:
                if hasattr(request, 'accepted_renderer'):
                    return Response(
                        {'error': 'User email not found'}, 
                        status=status.HTTP_400_BAD_REQUEST
                    )
                else:
                    return JsonResponse(
                        {'error': 'User email not found'}, 
                        status=400
                    )
            
            # Check if user has all required permissions
            missing_permissions = []
            for perm in permissions:
                if isinstance(perm, tuple):
                    permission_name, module = perm
                else:
                    permission_name, module = perm, None
                
                if not UserPermissionManager.user_has_permission(user_email, permission_name, module):
                    if isinstance(perm, tuple):
                        missing_permissions.append(f"{perm[0]} ({perm[1]})")
                    else:
                        missing_permissions.append(perm)
            
            if missing_permissions:
                if hasattr(request, 'accepted_renderer'):
                    return Response(
                        {
                            'error': 'Insufficient permissions',
                            'missing_permissions': missing_permissions
                        }, 
                        status=status.HTTP_403_FORBIDDEN
                    )
                else:
                    return JsonResponse(
                        {
                            'error': 'Insufficient permissions',
                            'missing_permissions': missing_permissions
                        }, 
                        status=403
                    )
            
            return view_func(request, *args, **kwargs)
        return wrapper
    return decorator


class PermissionRequiredMixin:
    """
    Mixin for class-based views to check permissions.
    
    Usage:
        class MyView(PermissionRequiredMixin, APIView):
            required_permission = 'Create Auctions'
            required_module = 'auction_management'
            
            def get(self, request):
                # View logic here
                pass
    """
    required_permission = None
    required_module = None
    required_permissions = None  # List of (permission, module) tuples
    require_all_permissions = True  # If False, require any permission
    
    def dispatch(self, request, *args, **kwargs):
        """Check permissions before dispatching the view."""
        # Check if user is authenticated
        if not request.user.is_authenticated:
            if hasattr(request, 'accepted_renderer'):
                return Response(
                    {'error': 'Authentication required'}, 
                    status=status.HTTP_401_UNAUTHORIZED
                )
            else:
                return JsonResponse(
                    {'error': 'Authentication required'}, 
                    status=401
                )
        
        # Get user email
        user_email = getattr(request.user, 'email', None)
        if not user_email:
            if hasattr(request, 'accepted_renderer'):
                return Response(
                    {'error': 'User email not found'}, 
                    status=status.HTTP_400_BAD_REQUEST
                )
            else:
                return JsonResponse(
                    {'error': 'User email not found'}, 
                    status=400
                )
        
        # Check single permission
        if self.required_permission:
            has_permission = UserPermissionManager.user_has_permission(
                user_email, self.required_permission, self.required_module
            )
            
            if not has_permission:
                if hasattr(request, 'accepted_renderer'):
                    return Response(
                        {
                            'error': 'Permission denied',
                            'required_permission': self.required_permission,
                            'module': self.required_module
                        }, 
                        status=status.HTTP_403_FORBIDDEN
                    )
                else:
                    return JsonResponse(
                        {
                            'error': 'Permission denied',
                            'required_permission': self.required_permission,
                            'module': self.required_module
                        }, 
                        status=403
                    )
        
        # Check multiple permissions
        elif self.required_permissions:
            if self.require_all_permissions:
                # Require all permissions
                missing_permissions = []
                for perm_info in self.required_permissions:
                    if isinstance(perm_info, tuple):
                        permission_name, module = perm_info
                    else:
                        permission_name, module = perm_info, None
                    
                    if not UserPermissionManager.user_has_permission(user_email, permission_name, module):
                        if isinstance(perm_info, tuple):
                            missing_permissions.append(f"{perm_info[0]} ({perm_info[1]})")
                        else:
                            missing_permissions.append(perm_info)
                
                if missing_permissions:
                    if hasattr(request, 'accepted_renderer'):
                        return Response(
                            {
                                'error': 'Insufficient permissions',
                                'missing_permissions': missing_permissions
                            }, 
                            status=status.HTTP_403_FORBIDDEN
                        )
                    else:
                        return JsonResponse(
                            {
                                'error': 'Insufficient permissions',
                                'missing_permissions': missing_permissions
                            }, 
                            status=403
                        )
            else:
                # Require any permission
                has_permission = False
                for perm_info in self.required_permissions:
                    if isinstance(perm_info, tuple):
                        permission_name, module = perm_info
                    else:
                        permission_name, module = perm_info, None
                    
                    if UserPermissionManager.user_has_permission(user_email, permission_name, module):
                        has_permission = True
                        break
                
                if not has_permission:
                    required_perms = []
                    for perm_info in self.required_permissions:
                        if isinstance(perm_info, tuple):
                            required_perms.append(f"{perm_info[0]} ({perm_info[1]})")
                        else:
                            required_perms.append(perm_info)
                    
                    if hasattr(request, 'accepted_renderer'):
                        return Response(
                            {
                                'error': 'Permission denied',
                                'required_permissions': required_perms
                            }, 
                            status=status.HTTP_403_FORBIDDEN
                        )
                    else:
                        return JsonResponse(
                            {
                                'error': 'Permission denied',
                                'required_permissions': required_perms
                            }, 
                            status=403
                        )
        
        return super().dispatch(request, *args, **kwargs)
