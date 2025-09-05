"""
BIDR Sessions Views

API endpoints for session management and monitoring.
"""
from django.db.models import Count, Avg, Max, Min, Q
from django.utils import timezone
from django.http import HttpResponse
from datetime import datetime, timedelta
from rest_framework import status, viewsets, permissions
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django_filters.rest_framework import DjangoFilterBackend
from rest_framework.filters import SearchFilter, OrderingFilter

from .models import (
    UserSession, SessionActivity, TrustedDevice, 
    SessionSecurityEvent, SessionStatus
)
from .serializers import (
    UserSessionSerializer, SessionActivitySerializer, TrustedDeviceSerializer,
    SessionSecurityEventSerializer, SessionCreateSerializer, SessionTerminateSerializer,
    SessionListSerializer, SessionAnalyticsSerializer, DeviceManagementSerializer
)


class UserSessionViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing user sessions
    """
    serializer_class = UserSessionSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [DjangoFilterBackend, SearchFilter, OrderingFilter]
    filterset_fields = ['status', 'device_type', 'is_trusted', 'country']
    search_fields = ['device_name', 'ip_address', 'browser', 'operating_system']
    ordering_fields = ['created_at', 'last_activity', 'expires_at']
    ordering = ['-last_activity']

    def get_queryset(self):
        """Filter sessions to current user only"""
        # Handle schema generation
        if getattr(self, 'swagger_fake_view', False):
            return UserSession.objects.none()
        
        return UserSession.objects.filter(user=self.request.user)

    def get_serializer_class(self):
        """Use different serializers for different actions"""
        if self.action == 'list':
            return SessionListSerializer
        return UserSessionSerializer

    @action(detail=False, methods=['get'])
    def active(self, request):
        """Get all active sessions for the current user"""
        active_sessions = self.get_queryset().filter(
            status=SessionStatus.ACTIVE,
            expires_at__gt=timezone.now()
        )
        serializer = SessionListSerializer(active_sessions, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['post'])
    def terminate_all(self, request):
        """Terminate all sessions except the current one"""
        current_session_key = request.session.session_key
        sessions_to_terminate = self.get_queryset().filter(
            status=SessionStatus.ACTIVE
        ).exclude(session_key=current_session_key)
        
        reason = request.data.get('reason', 'Terminated by user')
        count = 0
        for session in sessions_to_terminate:
            session.terminate(reason=reason)
            count += 1
        
        return Response({
            'message': f'Terminated {count} sessions',
            'terminated_count': count
        })

    @action(detail=True, methods=['post'])
    def terminate(self, request, pk=None):
        """Terminate a specific session"""
        session = self.get_object()
        reason = request.data.get('reason', 'Terminated by user')
        session.terminate(reason=reason)
        
        return Response({
            'message': 'Session terminated successfully',
            'session_uuid': str(session.uuid)
        })

    @action(detail=True, methods=['get'])
    def activities(self, request, pk=None):
        """Get activities for a specific session"""
        session = self.get_object()
        activities = SessionActivity.objects.filter(session=session)
        serializer = SessionActivitySerializer(activities, many=True)
        return Response(serializer.data)

    @action(detail=True, methods=['get'])
    def security_events(self, request, pk=None):
        """Get security events for a specific session"""
        session = self.get_object()
        events = SessionSecurityEvent.objects.filter(session=session)
        serializer = SessionSecurityEventSerializer(events, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['get'])
    def analytics(self, request):
        """Get session analytics for the current user"""
        queryset = self.get_queryset()
        
        # Basic counts
        total_sessions = queryset.count()
        active_sessions = queryset.filter(
            status=SessionStatus.ACTIVE,
            expires_at__gt=timezone.now()
        ).count()
        
        # Device analytics
        unique_devices = queryset.values('device_id').distinct().count()
        device_type_breakdown = dict(
            queryset.values('device_type').annotate(count=Count('id')).values_list('device_type', 'count')
        )
        
        # Browser analytics
        browser_breakdown = dict(
            queryset.exclude(browser__isnull=True).values('browser').annotate(count=Count('id')).values_list('browser', 'count')
        )
        
        # Location analytics
        unique_locations = queryset.exclude(country__isnull=True).values('country', 'city').distinct().count()
        country_breakdown = dict(
            queryset.exclude(country__isnull=True).values('country').annotate(count=Count('id')).values_list('country', 'count')
        )
        
        # Session duration (in seconds)
        avg_duration = 0
        if total_sessions > 0:
            durations = [session.calculate_session_duration().total_seconds() for session in queryset[:100]]  # Sample for performance
            avg_duration = sum(durations) / len(durations) if durations else 0
        
        # Security metrics
        security_events_count = SessionSecurityEvent.objects.filter(session__in=queryset).count()
        trusted_devices_count = TrustedDevice.objects.filter(user=request.user, is_active=True).count()
        
        analytics_data = {
            'total_sessions': total_sessions,
            'active_sessions': active_sessions,
            'unique_devices': unique_devices,
            'unique_locations': unique_locations,
            'average_session_duration': avg_duration,
            'device_type_breakdown': device_type_breakdown,
            'browser_breakdown': browser_breakdown,
            'country_breakdown': country_breakdown,
            'security_events_count': security_events_count,
            'trusted_devices_count': trusted_devices_count,
        }
        
        serializer = SessionAnalyticsSerializer(analytics_data)
        return Response(serializer.data)


class TrustedDeviceViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing trusted devices
    """
    serializer_class = TrustedDeviceSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [DjangoFilterBackend, SearchFilter, OrderingFilter]
    filterset_fields = ['device_type', 'is_active']
    search_fields = ['device_name', 'device_id']
    ordering_fields = ['trusted_at', 'last_used']
    ordering = ['-last_used']

    def get_queryset(self):
        """Filter devices to current user only"""
        # Handle schema generation
        if getattr(self, 'swagger_fake_view', False):
            return TrustedDevice.objects.none()
        
        return TrustedDevice.objects.filter(user=self.request.user)

    @action(detail=False, methods=['post'])
    def manage(self, request):
        """Perform bulk operations on trusted devices"""
        serializer = DeviceManagementSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        
        data = serializer.validated_data
        action_type = data['action']
        device_uuids = data['device_uuids']
        
        devices = self.get_queryset().filter(uuid__in=device_uuids)
        if not devices.exists():
            return Response({'error': 'No devices found'}, status=status.HTTP_404_NOT_FOUND)
        
        results = []
        for device in devices:
            if action_type == 'trust':
                device.is_active = True
                if data.get('expires_at'):
                    device.expires_at = data['expires_at']
                device.save()
                results.append(f"Trusted device {device.device_name}")
            elif action_type == 'revoke_trust':
                device.revoke_trust()
                results.append(f"Revoked trust for device {device.device_name}")
            elif action_type == 'remove':
                device_name = device.device_name
                device.delete()
                results.append(f"Removed device {device_name}")
        
        return Response({
            'message': f'Successfully performed {action_type} on {len(results)} devices',
            'results': results
        })

    @action(detail=True, methods=['post'])
    def revoke_trust(self, request, pk=None):
        """Revoke trust for a specific device"""
        device = self.get_object()
        device.revoke_trust()
        
        return Response({
            'message': f'Trust revoked for device {device.device_name}',
            'device_uuid': str(device.uuid)
        })


class SessionSecurityEventViewSet(viewsets.ReadOnlyModelViewSet):
    """
    ViewSet for viewing session security events
    """
    serializer_class = SessionSecurityEventSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [DjangoFilterBackend, SearchFilter, OrderingFilter]
    filterset_fields = ['event_type', 'severity', 'is_resolved']
    search_fields = ['description']
    ordering_fields = ['detected_at', 'risk_score']
    ordering = ['-detected_at']

    def get_queryset(self):
        """Filter events to current user's sessions only"""
        # Handle schema generation
        if getattr(self, 'swagger_fake_view', False):
            return SessionSecurityEvent.objects.none()
        
        user_sessions = UserSession.objects.filter(user=self.request.user)
        return SessionSecurityEvent.objects.filter(session__in=user_sessions)

    @action(detail=True, methods=['post'])
    def resolve(self, request, pk=None):
        """Mark a security event as resolved"""
        event = self.get_object()
        notes = request.data.get('notes', '')
        event.resolve(notes=notes)
        
        return Response({
            'message': 'Security event marked as resolved',
            'event_uuid': str(event.uuid)
        })

    @action(detail=False, methods=['get'])
    def unresolved(self, request):
        """Get all unresolved security events"""
        unresolved_events = self.get_queryset().filter(is_resolved=False)
        serializer = self.get_serializer(unresolved_events, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['get'])
    def summary(self, request):
        """Get security events summary"""
        queryset = self.get_queryset()
        
        summary = {
            'total_events': queryset.count(),
            'unresolved_events': queryset.filter(is_resolved=False).count(),
            'high_severity_events': queryset.filter(severity='high').count(),
            'critical_events': queryset.filter(severity='critical').count(),
            'events_by_type': dict(
                queryset.values('event_type').annotate(count=Count('id')).values_list('event_type', 'count')
            ),
            'events_by_severity': dict(
                queryset.values('severity').annotate(count=Count('id')).values_list('severity', 'count')
            ),
        }
        
        return Response(summary)


class SessionActivityViewSet(viewsets.ReadOnlyModelViewSet):
    """
    ViewSet for viewing session activities
    """
    serializer_class = SessionActivitySerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [DjangoFilterBackend, SearchFilter, OrderingFilter]
    filterset_fields = ['action', 'method', 'status_code']
    search_fields = ['action', 'endpoint']
    ordering_fields = ['timestamp', 'response_time']
    ordering = ['-timestamp']

    def get_queryset(self):
        """Filter activities to current user's sessions only"""
        # Handle schema generation
        if getattr(self, 'swagger_fake_view', False):
            return SessionActivity.objects.none()
        
        user_sessions = UserSession.objects.filter(user=self.request.user)
        return SessionActivity.objects.filter(session__in=user_sessions)

    @action(detail=False, methods=['get'])
    def summary(self, request):
        """Get activity summary"""
        queryset = self.get_queryset()
        
        # Time-based filters
        today = timezone.now().date()
        week_ago = today - timedelta(days=7)
        
        summary = {
            'total_activities': queryset.count(),
            'today_activities': queryset.filter(timestamp__date=today).count(),
            'week_activities': queryset.filter(timestamp__date__gte=week_ago).count(),
            'top_actions': list(
                queryset.values('action').annotate(count=Count('id')).order_by('-count')[:10]
            ),
            'top_endpoints': list(
                queryset.values('endpoint').annotate(count=Count('id')).order_by('-count')[:10]
            ),
            'avg_response_time': queryset.aggregate(avg_response_time=Avg('response_time'))['avg_response_time'] or 0,
        }
        
        return Response(summary)
