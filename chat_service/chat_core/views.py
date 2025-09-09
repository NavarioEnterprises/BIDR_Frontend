from rest_framework import viewsets, status, permissions
from rest_framework.decorators import action
from rest_framework.response import Response
from django.contrib.auth.models import User
from django.utils import timezone
from django.db.models import Q, Count, Avg
from .models import (
    UserProfile, SystemConfig, AuditLog, TranslationCache,
    ContentFilterRule, ModerationQueue, LanguagePreference
)
from .serializers import (
    UserProfileSerializer, UserProfileCreateSerializer, SystemConfigSerializer,
    AuditLogSerializer, TranslationCacheSerializer, ContentFilterRuleSerializer,
    ModerationQueueSerializer, LanguagePreferenceSerializer
)


class UserProfileViewSet(viewsets.ModelViewSet):
    """ViewSet for managing user profiles in chat service."""
    
    queryset = UserProfile.objects.all()
    permission_classes = [permissions.AllowAny]
    serializer_class = UserProfileSerializer
    
    def get_serializer_class(self):
        if self.action == 'create':
            return UserProfileCreateSerializer
        return UserProfileSerializer
    
    def get_queryset(self):
        """Filter queryset based on user permissions."""
        if self.request.user.is_staff:
            return self.queryset.all()
        if self.request.user.is_authenticated:
            return self.queryset.filter(user=self.request.user)
        # For anonymous users, return all profiles (since we set AllowAny)
        return self.queryset.all()
    
    @action(detail=True, methods=['post'])
    def update_status(self, request, pk=None):
        """Update user online status."""
        profile = self.get_object()
        if profile.user != request.user and not request.user.is_staff:
            return Response(
                {'error': 'Permission denied'}, 
                status=status.HTTP_403_FORBIDDEN
            )
        
        profile.last_seen = timezone.now()
        profile.last_activity = timezone.now()
        profile.save(update_fields=['last_seen', 'last_activity'])
        
        return Response({'status': 'updated', 'is_online': profile.is_online()})
    
    @action(detail=True, methods=['get'])
    def statistics(self, request, pk=None):
        """Get user chat statistics."""
        profile = self.get_object()
        if profile.user != request.user and not request.user.is_staff:
            return Response(
                {'error': 'Permission denied'}, 
                status=status.HTTP_403_FORBIDDEN
            )
        
        stats = {
            'total_conversations': profile.total_conversations,
            'total_messages_sent': profile.total_messages_sent,
            'average_response_time': profile.average_response_time_minutes,
            'reputation_score': float(profile.reputation_score),
            'warning_count': profile.warning_count,
            'is_online': profile.is_online(),
            'last_seen': profile.last_seen,
            'account_age_days': (timezone.now() - profile.created_at).days
        }
        
        return Response(stats)
    
    @action(detail=False, methods=['get'])
    def online_users(self, request):
        """Get list of currently online users."""
        online_profiles = self.queryset.filter(
            show_online_status=True
        ).select_related('user')
        
        online_users = [
            {
                'id': profile.id,
                'username': profile.user.username,
                'display_name': profile.get_display_name(),
                'role': profile.role,
                'last_seen': profile.last_seen
            }
            for profile in online_profiles 
            if profile.is_online()
        ]
        
        return Response(online_users)


class SystemConfigViewSet(viewsets.ReadOnlyModelViewSet):
    """ViewSet for system configuration (read-only for non-staff)."""
    
    queryset = SystemConfig.objects.all()
    permission_classes = [permissions.AllowAny]
    serializer_class = SystemConfigSerializer
    
    def get_queryset(self):
        """Filter based on user permissions."""
        if self.request.user.is_authenticated and self.request.user.is_staff:
            return self.queryset.all()
        
        # Non-staff and anonymous users can only see user-configurable settings
        return self.queryset.filter(is_user_configurable=True)
    
    @action(detail=False, methods=['get'])
    def by_category(self, request):
        """Get configurations by category."""
        category = request.query_params.get('category')
        if not category:
            return Response(
                {'error': 'Category parameter is required'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        configs = self.get_queryset().filter(category=category)
        config_data = [{
            'key': config.key,
            'value': config.get_parsed_value(),
            'description': config.description
        } for config in configs]
        
        return Response(config_data)
    
    @action(detail=False, methods=['get'])
    def translation_settings(self, request):
        """Get translation-related configurations."""
        configs = self.get_queryset().filter(category='translation')
        config_dict = {config.key: config.get_parsed_value() for config in configs}
        return Response(config_dict)
    
    @action(detail=False, methods=['get'])
    def moderation_settings(self, request):
        """Get moderation-related configurations."""
        configs = self.get_queryset().filter(category='moderation')
        config_dict = {config.key: config.get_parsed_value() for config in configs}
        return Response(config_dict)
