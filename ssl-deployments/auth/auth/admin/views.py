from django.shortcuts import get_object_or_404
from rest_framework import status, permissions
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.viewsets import ModelViewSet, ReadOnlyModelViewSet
from rest_framework.permissions import IsAdminUser

from .models import AdminProfile, AdminActivityLog, AdminNotification
from .serializers import (
    AdminProfileSerializer, AdminActivityLogSerializer, AdminNotificationSerializer,
    AdminCreateSerializer, AdminActivityLogCreateSerializer, AdminNotificationCreateSerializer
)


class IsSuperAdminOrSelf(permissions.BasePermission):
    """Custom permission for admin operations"""

    def has_permission(self, request, view):
        if not request.user.is_authenticated:
            return False

        # Super admins can access everything
        if request.user.is_superuser:
            return True

        # Regular admins can only access their own profile
        if hasattr(request.user, 'admin_profile'):
            return True

        return False

    def has_object_permission(self, request, view, obj):
        if request.user.is_superuser:
            return True

        # Admins can only access their own data
        if hasattr(obj, 'user'):
            return obj.user == request.user
        elif hasattr(obj, 'admin'):
            return obj.admin.user == request.user

        return False


class AdminProfileViewSet(ModelViewSet):
    """ViewSet for managing admin profiles"""
    permission_classes = [IsAdminUser, IsSuperAdminOrSelf]

    def get_queryset(self):
        """Get admin profiles based on user permissions"""
        if self.request.user.is_superuser:
            return AdminProfile.objects.all()
        else:
            return AdminProfile.objects.filter(user=self.request.user)

    def get_serializer_class(self):
        if self.action == 'create':
            return AdminCreateSerializer
        return AdminProfileSerializer

    def get_object(self):
        """Get admin profile for current user or by ID for superuser"""
        if self.request.user.is_superuser and 'pk' in self.kwargs:
            return get_object_or_404(AdminProfile, pk=self.kwargs['pk'])
        return get_object_or_404(AdminProfile, user=self.request.user)

    def list(self, request, *args, **kwargs):
        """List admin profiles"""
        if request.user.is_superuser:
            return super().list(request, *args, **kwargs)
        else:
            # Regular admins only see their own profile
            try:
                admin_profile = self.get_object()
                serializer = self.get_serializer(admin_profile)
                return Response([serializer.data])
            except:
                return Response([])

    def create(self, request, *args, **kwargs):
        """Create admin profile (superuser only)"""
        if not request.user.is_superuser:
            return Response(
                {'error': 'Only superusers can create admin profiles'},
                status=status.HTTP_403_FORBIDDEN
            )

        if AdminProfile.objects.filter(user=request.user).exists():
            return Response(
                {'error': 'Admin profile already exists for this user'},
                status=status.HTTP_400_BAD_REQUEST
            )

        return super().create(request, *args, **kwargs)

    @action(detail=False, methods=['get'])
    def my_profile(self, request):
        """Get current user's admin profile"""
        admin_profile = get_object_or_404(AdminProfile, user=request.user)
        serializer = self.get_serializer(admin_profile)
        return Response(serializer.data)

    @action(detail=True, methods=['post'])
    def unlock_account(self, request, pk=None):
        """Unlock an admin account (superuser only)"""
        if not request.user.is_superuser:
            return Response(
                {'error': 'Only superusers can unlock accounts'},
                status=status.HTTP_403_FORBIDDEN
            )

        admin_profile = self.get_object()
        admin_profile.unlock_account()

        return Response({'message': 'Account unlocked successfully'})


class AdminActivityLogViewSet(ReadOnlyModelViewSet):
    """ViewSet for viewing admin activity logs"""
    serializer_class = AdminActivityLogSerializer
    permission_classes = [IsAdminUser, IsSuperAdminOrSelf]

    def get_queryset(self):
        """Get activity logs based on user permissions"""
        if self.request.user.is_superuser:
            return AdminActivityLog.objects.all()
        else:
            admin_profile = get_object_or_404(AdminProfile, user=self.request.user)
            return AdminActivityLog.objects.filter(admin=admin_profile)

    @action(detail=False, methods=['post'])
    def create_log(self, request):
        """Create a new activity log entry"""
        admin_profile = get_object_or_404(AdminProfile, user=request.user)

        # Add IP address from request
        ip_address = request.META.get('REMOTE_ADDR', '127.0.0.1')
        user_agent = request.META.get('HTTP_USER_AGENT', '')

        data = request.data.copy()
        data['ip_address'] = ip_address
        data['user_agent'] = user_agent

        serializer = AdminActivityLogCreateSerializer(
            data=data,
            context={'admin': admin_profile}
        )

        if serializer.is_valid():
            activity_log = serializer.save()
            response_serializer = AdminActivityLogSerializer(activity_log)
            return Response(response_serializer.data, status=status.HTTP_201_CREATED)

        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class AdminNotificationViewSet(ModelViewSet):
    """ViewSet for managing admin notifications_service"""
    serializer_class = AdminNotificationSerializer
    permission_classes = [IsAdminUser, IsSuperAdminOrSelf]

    def get_queryset(self):
        """Get notifications_service based on user permissions"""
        if self.request.user.is_superuser:
            return AdminNotification.objects.all()
        else:
            admin_profile = get_object_or_404(AdminProfile, user=self.request.user)
            return AdminNotification.objects.filter(admin=admin_profile)

    def get_serializer_class(self):
        if self.action == 'create':
            return AdminNotificationCreateSerializer
        return AdminNotificationSerializer

    @action(detail=False, methods=['get'])
    def unread(self, request):
        """Get unread notifications_service for current admin"""
        admin_profile = get_object_or_404(AdminProfile, user=request.user)
        notifications = AdminNotification.objects.filter(
            admin=admin_profile, is_read=False
        ).order_by('-created_at')

        serializer = self.get_serializer(notifications, many=True)
        return Response(serializer.data)

    @action(detail=True, methods=['post'])
    def mark_read(self, request, pk=None):
        """Mark a notification as read"""
        notification = self.get_object()
        notification.mark_as_read()

        serializer = self.get_serializer(notification)
        return Response(serializer.data)

    @action(detail=False, methods=['post'])
    def mark_all_read(self, request):
        """Mark all notifications_service as read for current admin"""
        admin_profile = get_object_or_404(AdminProfile, user=request.user)

        count = AdminNotification.objects.filter(
            admin=admin_profile, is_read=False
        ).update(is_read=True)

        return Response({'message': f'{count} notifications_service marked as read'})
