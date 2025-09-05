"""
BIDR Authentication Logging Views

This module contains views for logging and analyzing authentication activities
in the BIDR platform.
"""
import csv
import json
from datetime import timedelta

from django.db.models import Count, Q, Avg
from django.utils import timezone
from django.http import HttpResponse
from rest_framework import status, viewsets
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated, IsAdminUser
from django_filters.rest_framework import DjangoFilterBackend
from rest_framework.filters import SearchFilter, OrderingFilter

from .models import AuthenticationLog, SecurityEvent, LoginSession, AuditTrail, SuspiciousActivity
from .serializers import (
    AuthenticationLogSerializer, AuthenticationLogCreateSerializer,
    SecurityEventSerializer, SecurityEventDetailSerializer,
    LoginSessionSerializer, AuditTrailSerializer,
    SuspiciousActivitySerializer, SuspiciousActivityDetailSerializer,
    AuthenticationAnalyticsSerializer,
    SecurityDashboardSerializer, BulkLogCreateSerializer, ExportRequestSerializer
)


class AuthenticationLogViewSet(viewsets.ModelViewSet):
    """
    API endpoint for authentication logs.
    
    Provides CRUD operations for authentication logs with appropriate filtering
    and permission controls.
    """
    queryset = AuthenticationLog.objects.all().order_by('-timestamp')
    filter_backends = [DjangoFilterBackend, SearchFilter, OrderingFilter]
    search_fields = ['user_email', 'ip_address', 'country', 'device_id']
    filterset_fields = ['action', 'status', 'user_type', 'country']
    ordering_fields = ['timestamp', 'user_email', 'response_code']
    ordering = ['-timestamp']
    
    def get_serializer_class(self):
        if self.action == 'create':
            return AuthenticationLogCreateSerializer
        return AuthenticationLogSerializer
    
    def get_permissions(self):
        if self.action in ['create', 'list', 'retrieve']:
            permission_classes = [IsAuthenticated]
        else:
            permission_classes = [IsAdminUser]
        return [permission() for permission in permission_classes]
    
    @action(detail=False, methods=['post'])
    def bulk_create(self, request):
        """Create multiple authentication logs at once."""
        serializer = BulkLogCreateSerializer(data=request.data)
        if serializer.is_valid():
            logs_data = serializer.validated_data['logs']
            logs = [AuthenticationLog(**log_data) for log_data in logs_data]
            AuthenticationLog.objects.bulk_create(logs)
            return Response({"message": f"Successfully created {len(logs)} logs"}, 
                           status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
    @action(detail=False, methods=['post'])
    def export(self, request):
        """Export authentication logs in various formats."""
        serializer = ExportRequestSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        
        data = serializer.validated_data
        export_format = data.get('format', 'csv')
        max_records = data.get('max_records', 10000)
        
        # Apply filters if provided
        queryset = self.filter_queryset(self.get_queryset())[:max_records]
        
        if export_format == 'csv':
            response = HttpResponse(content_type='text/csv')
            response['Content-Disposition'] = 'attachment; filename="auth_logs.csv"'
            
            writer = csv.writer(response)
            # Write header
            writer.writerow(['log_id', 'user_email', 'action', 'status', 'timestamp', 
                            'ip_address', 'country', 'device_type'])
            
            # Write data
            for log in queryset:
                writer.writerow([
                    log.log_id, log.user_email, log.action, log.status, 
                    log.timestamp, log.ip_address, log.country, log.device_type
                ])
            return response
            
        elif export_format == 'json':
            serializer = AuthenticationLogSerializer(queryset, many=True)
            response = HttpResponse(json.dumps(serializer.data), content_type='application/json')
            response['Content-Disposition'] = 'attachment; filename="auth_logs.json"'
            return response
            
        return Response({"error": "Unsupported export format"}, 
                       status=status.HTTP_400_BAD_REQUEST)
    
    @action(detail=False, methods=['get'])
    def analytics(self, request):
        """Get analytics data for authentication logs."""
        # Get time range from query params or use last 30 days
        days = int(request.query_params.get('days', 30))
        start_date = timezone.now() - timedelta(days=days)
        
        # Base queryset
        queryset = AuthenticationLog.objects.filter(timestamp__gte=start_date)
        
        # Basic counts
        total_logs = queryset.count()
        successful_logins = queryset.filter(action='login_success').count()
        failed_logins = queryset.filter(action='login_failed').count()
        registrations = queryset.filter(action__in=[
            'registration_attempt', 'registration_success', 'registration_failed'
        ]).count()
        password_resets = queryset.filter(action__in=[
            'password_reset_request', 'password_reset_success', 'password_reset_failed'
        ]).count()
        
        # Unique counts
        unique_users = queryset.values('user_email').distinct().count()
        unique_ips = queryset.values('ip_address').distinct().count()
        
        # Security events count
        security_events = SecurityEvent.objects.filter(detected_at__gte=start_date).count()
        
        # Time series data - daily stats
        daily_stats = list(queryset.values('timestamp__date')
                          .annotate(date=Count('timestamp__date'))
                          .annotate(
                              total=Count('log_id'),
                              successful=Count('log_id', filter=Q(status='success')),
                              failed=Count('log_id', filter=Q(status='failed'))
                          )
                          .order_by('timestamp__date'))
        
        # Top stats
        top_actions = list(queryset.values('action')
                          .annotate(count=Count('action'))
                          .order_by('-count')[:10])
        
        top_user_types = list(queryset.values('user_type')
                             .annotate(count=Count('user_type'))
                             .order_by('-count')[:5])
        
        top_countries = list(queryset.values('country')
                            .annotate(count=Count('country'))
                            .order_by('-count')[:10])
        
        top_devices = list(queryset.values('device_type')
                          .annotate(count=Count('device_type'))
                          .order_by('-count')[:5])
        
        # Prepare response data
        analytics_data = {
            'total_logs': total_logs,
            'successful_logins': successful_logins,
            'failed_logins': failed_logins,
            'registrations': registrations,
            'password_resets': password_resets,
            'security_events': security_events,
            'unique_users': unique_users,
            'unique_ips': unique_ips,
            'daily_stats': daily_stats,
            'top_actions': top_actions,
            'top_user_types': top_user_types,
            'top_countries': top_countries,
            'top_devices': top_devices,
        }
        
        serializer = AuthenticationAnalyticsSerializer(analytics_data)
        return Response(serializer.data)


class SecurityEventViewSet(viewsets.ModelViewSet):
    """
    API endpoint for security events.
    
    Provides CRUD operations for security events with appropriate filtering
    and permission controls.
    """
    queryset = SecurityEvent.objects.all().order_by('-detected_at')
    filter_backends = [DjangoFilterBackend, SearchFilter, OrderingFilter]
    search_fields = ['user_email', 'title', 'description']
    filterset_fields = ['event_type', 'severity', 'status']
    ordering_fields = ['detected_at', 'risk_score', 'severity']
    ordering = ['-detected_at']
    
    def get_serializer_class(self):
        if self.action == 'retrieve':
            return SecurityEventDetailSerializer
        return SecurityEventSerializer
    
    def get_permissions(self):
        if self.action in ['list', 'retrieve']:
            permission_classes = [IsAuthenticated]
        else:
            permission_classes = [IsAdminUser]
        return [permission() for permission in permission_classes]
    
    @action(detail=True, methods=['post'])
    def resolve(self, request, pk=None):
        """Mark a security event as resolved."""
        event = self.get_object()
        notes = request.data.get('notes', '')
        
        event.mark_resolved(resolved_by=request.user.email, notes=notes)
        
        serializer = self.get_serializer(event)
        return Response(serializer.data)
    
    @action(detail=False, methods=['get'])
    def dashboard(self, request):
        """Get security dashboard data."""
        # Get time range from query params or use last 30 days
        days = int(request.query_params.get('days', 30))
        start_date = timezone.now() - timedelta(days=days)
        today_start = timezone.now().replace(hour=0, minute=0, second=0, microsecond=0)
        
        # Security events stats
        active_security_events = SecurityEvent.objects.exclude(status='resolved').count()
        high_risk_events = SecurityEvent.objects.filter(
            severity__in=['high', 'critical']
        ).exclude(status='resolved').count()
        
        # Authentication logs stats
        failed_login_attempts_today = AuthenticationLog.objects.filter(
            action='login_failed',
            timestamp__gte=today_start
        ).count()
        
        suspicious_activities_today = SuspiciousActivity.objects.filter(
            detected_at__gte=today_start
        ).count()
        
        # Login success rate
        login_attempts = AuthenticationLog.objects.filter(
            action__in=['login_attempt', 'login_success', 'login_failed'],
            timestamp__gte=start_date
        ).count()
        
        successful_logins = AuthenticationLog.objects.filter(
            action='login_success',
            timestamp__gte=start_date
        ).count()
        
        login_success_rate = (successful_logins / login_attempts * 100) if login_attempts > 0 else 0
        
        # Response time
        avg_response_time = AuthenticationLog.objects.filter(
            timestamp__gte=start_date,
            response_time_ms__isnull=False
        ).aggregate(avg=Avg('response_time_ms'))['avg'] or 0
        
        # Unique users today
        unique_users_today = AuthenticationLog.objects.filter(
            timestamp__gte=today_start
        ).values('user_email').distinct().count()
        
        # Recent critical events
        recent_critical_events = SecurityEvent.objects.filter(
            severity__in=['high', 'critical']
        ).order_by('-detected_at')[:5]
        
        # Geographic distribution
        geo_distribution = list(AuthenticationLog.objects.filter(
            timestamp__gte=start_date,
            country__isnull=False
        ).values('country').annotate(count=Count('country')).order_by('-count')[:10])
        
        # Device stats
        device_stats = list(AuthenticationLog.objects.filter(
            timestamp__gte=start_date,
            device_type__isnull=False
        ).values('device_type').annotate(count=Count('device_type')).order_by('-count')[:5])
        
        # Browser stats
        browser_stats = list(AuthenticationLog.objects.filter(
            timestamp__gte=start_date,
            browser__isnull=False
        ).values('browser').annotate(count=Count('browser')).order_by('-count')[:5])
        
        # Prepare response data
        dashboard_data = {
            'active_security_events': active_security_events,
            'high_risk_events': high_risk_events,
            'failed_login_attempts_today': failed_login_attempts_today,
            'suspicious_activities_today': suspicious_activities_today,
            'login_success_rate': login_success_rate,
            'average_response_time': avg_response_time,
            'unique_users_today': unique_users_today,
            'recent_critical_events': recent_critical_events,
            'geographic_distribution': geo_distribution,
            'device_stats': device_stats,
            'browser_stats': browser_stats,
        }
        
        serializer = SecurityDashboardSerializer(dashboard_data)
        return Response(serializer.data)


class LoginSessionViewSet(viewsets.ModelViewSet):
    """
    API endpoint for login sessions.
    
    Provides CRUD operations for login sessions with appropriate filtering
    and permission controls.
    """
    queryset = LoginSession.objects.all().order_by('-login_timestamp')
    serializer_class = LoginSessionSerializer
    filter_backends = [DjangoFilterBackend, SearchFilter, OrderingFilter]
    search_fields = ['user_email', 'session_id', 'ip_address', 'device_id']
    filterset_fields = ['is_active', 'user_email']
    ordering_fields = ['login_timestamp', 'last_activity']
    ordering = ['-login_timestamp']
    
    def get_permissions(self):
        if self.action in ['list', 'retrieve']:
            permission_classes = [IsAuthenticated]
        else:
            permission_classes = [IsAdminUser]
        return [permission() for permission in permission_classes]
    
    @action(detail=True, methods=['post'])
    def terminate(self, request, pk=None):
        """Terminate a login session."""
        session = self.get_object()
        session.terminate_session()
        
        serializer = self.get_serializer(session)
        return Response(serializer.data)
    
    @action(detail=False, methods=['get'])
    def active(self, request):
        """Get all active login sessions."""
        queryset = self.filter_queryset(self.get_queryset().filter(is_active=True))
        page = self.paginate_queryset(queryset)
        
        if page is not None:
            serializer = self.get_serializer(page, many=True)
            return self.get_paginated_response(serializer.data)
        
        serializer = self.get_serializer(queryset, many=True)
        return Response(serializer.data)
    
    @action(detail=False, methods=['post'])
    def terminate_all(self, request):
        """Terminate all active sessions for a user."""
        user_email = request.data.get('user_email')
        if not user_email:
            return Response(
                {"error": "user_email is required"}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        sessions = LoginSession.objects.filter(user_email=user_email, is_active=True)
        count = sessions.count()
        
        for session in sessions:
            session.terminate_session()
        
        return Response({
            "message": f"Terminated {count} active sessions for {user_email}"
        })


class AuditTrailViewSet(viewsets.ReadOnlyModelViewSet):
    """
    API endpoint for audit trail.
    
    Provides read-only operations for audit trail with appropriate filtering
    and permission controls.
    """
    queryset = AuditTrail.objects.all().order_by('-timestamp')
    serializer_class = AuditTrailSerializer
    filter_backends = [DjangoFilterBackend, SearchFilter, OrderingFilter]
    search_fields = ['admin_email', 'target_user_email', 'description']
    filterset_fields = ['action', 'admin_email', 'target_user_email']
    ordering_fields = ['timestamp', 'admin_email', 'action']
    ordering = ['-timestamp']
    permission_classes = [IsAdminUser]


class SuspiciousActivityViewSet(viewsets.ModelViewSet):
    """
    API endpoint for suspicious activities.
    
    Provides CRUD operations for suspicious activities with appropriate filtering
    and permission controls.
    """
    queryset = SuspiciousActivity.objects.all().order_by('-detected_at')
    filter_backends = [DjangoFilterBackend, SearchFilter, OrderingFilter]
    search_fields = ['user_email', 'description', 'source_ip']
    filterset_fields = ['activity_type', 'severity', 'status', 'country']
    ordering_fields = ['detected_at', 'severity']
    ordering = ['-detected_at']
    
    def get_serializer_class(self):
        if self.action == 'retrieve':
            return SuspiciousActivityDetailSerializer
        return SuspiciousActivitySerializer
    
    def get_permissions(self):
        if self.action in ['list', 'retrieve']:
            permission_classes = [IsAuthenticated]
        else:
            permission_classes = [IsAdminUser]
        return [permission() for permission in permission_classes]
    
    @action(detail=True, methods=['post'])
    def resolve(self, request, pk=None):
        """Mark a suspicious activity as resolved."""
        activity = self.get_object()
        notes = request.data.get('notes', '')
        
        activity.mark_resolved(resolved_by=request.user.email, notes=notes)
        
        serializer = self.get_serializer(activity)
        return Response(serializer.data)
    
    @action(detail=True, methods=['post'])
    def mark_false_positive(self, request, pk=None):
        """Mark a suspicious activity as a false positive."""
        activity = self.get_object()
        notes = request.data.get('notes', '')
        
        activity.status = 'false_positive'
        activity.resolved_at = timezone.now()
        activity.resolved_by = request.user.email
        if notes:
            activity.resolution_notes = notes
        activity.save()
        
        serializer = self.get_serializer(activity)
        return Response(serializer.data)
    
    @action(detail=False, methods=['get'])
    def by_user(self, request):
        """Get suspicious activities for a specific user."""
        user_email = request.query_params.get('user_email')
        if not user_email:
            return Response(
                {"error": "user_email query parameter is required"}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        queryset = self.filter_queryset(self.get_queryset().filter(user_email=user_email))
        page = self.paginate_queryset(queryset)
        
        if page is not None:
            serializer = self.get_serializer(page, many=True)
            return self.get_paginated_response(serializer.data)
        
        serializer = self.get_serializer(queryset, many=True)
        return Response(serializer.data)
