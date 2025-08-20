"""
BIDR Analytics Views

API endpoints for analytics and reporting.
"""
from django.db.models import Count
from django.utils import timezone
from rest_framework import status, viewsets, permissions
from rest_framework.decorators import action
from rest_framework.response import Response
from django_filters.rest_framework import DjangoFilterBackend
from rest_framework.filters import SearchFilter, OrderingFilter

from .models import (
    AuthenticationMetric, UserBehaviorAnalytics, SystemPerformanceMetric,
    AuthenticationTrend, AnalyticsReport
)
from .serializers import (
    AuthenticationMetricSerializer, UserBehaviorAnalyticsSerializer,
    SystemPerformanceMetricSerializer, AuthenticationTrendSerializer,
    AnalyticsReportSerializer, AnalyticsReportCreateSerializer,
    MetricsSummarySerializer, TrendAnalysisSerializer
)


class AuthenticationMetricViewSet(viewsets.ReadOnlyModelViewSet):
    """
    ViewSet for viewing authentication metrics
    """
    serializer_class = AuthenticationMetricSerializer
    permission_classes = [permissions.IsAuthenticated]
    filter_backends = [DjangoFilterBackend, SearchFilter, OrderingFilter]
    filterset_fields = ['name', 'category', 'metric_type', 'period']
    search_fields = ['name', 'category']
    ordering_fields = ['timestamp', 'value']
    ordering = ['-timestamp']

    def get_queryset(self):
        return AuthenticationMetric.objects.all()

    @action(detail=False, methods=['get'])
    def summary(self, request):
        """Get metrics summary"""
        today = timezone.now().date()
        
        # Get basic counts (placeholder data)
        summary_data = {
            'total_users': 0,
            'active_users_today': 0,
            'total_logins_today': 0,
            'failed_logins_today': 0,
            'login_success_rate': 0.0,
            'total_sessions': 0,
            'active_sessions': 0,
            'avg_session_duration': 0.0,
            'security_events_today': 0,
            'api_requests_today': 0,
            'api_error_rate': 0.0,
            'system_performance_score': 85.0,
        }
        
        serializer = MetricsSummarySerializer(summary_data)
        return Response(serializer.data)


class UserBehaviorAnalyticsViewSet(viewsets.ReadOnlyModelViewSet):
    """
    ViewSet for viewing user behavior analytics
    """
    serializer_class = UserBehaviorAnalyticsSerializer
    permission_classes = [permissions.IsAuthenticated]
    filter_backends = [DjangoFilterBackend, SearchFilter, OrderingFilter]
    filterset_fields = ['user_type', 'date', 'period_type']
    search_fields = ['user__email']
    ordering_fields = ['date', 'login_count', 'session_count']
    ordering = ['-date']

    def get_queryset(self):
        return UserBehaviorAnalytics.objects.all()


class SystemPerformanceMetricViewSet(viewsets.ReadOnlyModelViewSet):
    """
    ViewSet for viewing system performance metrics
    """
    serializer_class = SystemPerformanceMetricSerializer
    permission_classes = [permissions.IsAdminUser]
    filter_backends = [DjangoFilterBackend, SearchFilter, OrderingFilter]
    filterset_fields = ['component', 'metric_name', 'period']
    search_fields = ['component', 'metric_name']
    ordering_fields = ['timestamp', 'response_time_avg', 'error_rate']
    ordering = ['-timestamp']

    def get_queryset(self):
        return SystemPerformanceMetric.objects.all()


class AuthenticationTrendViewSet(viewsets.ReadOnlyModelViewSet):
    """
    ViewSet for viewing authentication trends
    """
    serializer_class = AuthenticationTrendSerializer
    permission_classes = [permissions.IsAuthenticated]
    filter_backends = [DjangoFilterBackend, SearchFilter, OrderingFilter]
    filterset_fields = ['trend_name', 'category', 'period_type']
    search_fields = ['trend_name', 'category']
    ordering_fields = ['date', 'current_value', 'change_percentage']
    ordering = ['-date']

    def get_queryset(self):
        return AuthenticationTrend.objects.all()

    @action(detail=False, methods=['get'])
    def analysis(self, request):
        """Get trend analysis for different periods"""
        period = request.query_params.get('period', 'weekly')
        
        # Placeholder trend data
        trend_data = {
            'period': period,
            'login_trend': [],
            'registration_trend': [],
            'security_events_trend': [],
            'performance_trend': [],
            'user_growth_trend': [],
        }
        
        serializer = TrendAnalysisSerializer(trend_data)
        return Response(serializer.data)


class AnalyticsReportViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing analytics reports
    """
    serializer_class = AnalyticsReportSerializer
    permission_classes = [permissions.IsAuthenticated]
    filter_backends = [DjangoFilterBackend, SearchFilter, OrderingFilter]
    filterset_fields = ['report_type', 'status', 'generated_by']
    search_fields = ['name', 'description']
    ordering_fields = ['created_at', 'generated_at']
    ordering = ['-created_at']

    def get_queryset(self):
        """Filter reports to user's own or admin access"""
        # Handle schema generation
        if getattr(self, 'swagger_fake_view', False):
            return AnalyticsReport.objects.none()
        
        if self.request.user.is_staff:
            return AnalyticsReport.objects.all()
        return AnalyticsReport.objects.filter(generated_by=self.request.user)

    def get_serializer_class(self):
        """Use different serializers for different actions"""
        if self.action == 'create':
            return AnalyticsReportCreateSerializer
        return AnalyticsReportSerializer

    def perform_create(self, serializer):
        """Create a new analytics report"""
        report = AnalyticsReport(
            name=serializer.validated_data['name'],
            description=serializer.validated_data.get('description', ''),
            report_type=serializer.validated_data['report_type'],
            filters=serializer.validated_data.get('filters', {}),
            parameters=serializer.validated_data.get('parameters', {}),
            start_date=serializer.validated_data['start_date'],
            end_date=serializer.validated_data['end_date'],
            expires_at=serializer.validated_data.get('expires_at'),
            generated_by=self.request.user,
            status='scheduled'
        )
        report.save()
        
        # TODO: Trigger background task to generate report
        # For now, mark as completed with empty data
        report.status = 'completed'
        report.data = {'placeholder': 'Report data would be generated here'}
        report.summary = {'total_records': 0, 'generation_time': 0.1}
        report.mark_completed(generation_time=0.1)
        
        return report

    @action(detail=True, methods=['get'])
    def download(self, request, pk=None):
        """Download a generated report"""
        report = self.get_object()
        
        if report.status != 'completed':
            return Response(
                {'error': 'Report is not ready for download'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # TODO: Implement actual file download
        return Response({
            'message': 'Report download would be implemented here',
            'report_uuid': str(report.uuid),
            'file_path': report.file_path
        })

    @action(detail=False, methods=['get'])
    def dashboard(self, request):
        """Get dashboard analytics data"""
        # Placeholder dashboard data
        dashboard_data = {
            'total_reports': self.get_queryset().count(),
            'completed_reports': self.get_queryset().filter(status='completed').count(),
            'recent_reports': list(
                self.get_queryset()[:5].values('uuid', 'name', 'report_type', 'status', 'created_at')
            ),
            'report_types_breakdown': dict(
                self.get_queryset().values('report_type').annotate(count=Count('id')).values_list('report_type', 'count')
            ),
        }
        
        return Response(dashboard_data)
