"""
BIDR API Management Views

API endpoints for API key management and monitoring.
"""
from django.utils import timezone
from django.db.models import Count, Avg
from rest_framework import status, viewsets, permissions
from rest_framework.decorators import action
from rest_framework.response import Response
from django_filters.rest_framework import DjangoFilterBackend
from rest_framework.filters import SearchFilter, OrderingFilter

from .models import APIKey, APIScope, APIRequest, RateLimitBucket, APIKeyUsageQuota, APIKeyStatus
from .serializers import (
    APIKeySerializer, APIScopeSerializer, APIKeyCreateSerializer,
    APIKeyResponseSerializer, APIRequestSerializer, APIKeyAnalyticsSerializer, 
    RateLimitBucketSerializer, APIKeyUsageQuotaSerializer, APIKeyBulkActionSerializer
)


class APIKeyViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing API keys
    """
    serializer_class = APIKeySerializer
    permission_classes = [permissions.IsAuthenticated]
    filter_backends = [DjangoFilterBackend, SearchFilter, OrderingFilter]
    filterset_fields = ['status', 'user', 'created_at']
    search_fields = ['name', 'description', 'key_id']
    ordering_fields = ['created_at', 'last_used_at']
    ordering = ['-created_at']

    def get_queryset(self):
        """Filter API keys to current user or admin access"""
        if self.request.user.is_staff:
            return APIKey.objects.all()
        return APIKey.objects.filter(user=self.request.user)

    def get_serializer_class(self):
        """Use different serializers for different actions"""
        if self.action == 'create':
            return APIKeyCreateSerializer
        return APIKeySerializer

    def perform_create(self, serializer):
        """Override to create API key and return secret key"""
        api_key, secret_key = APIKey.create_api_key(
            user=self.request.user,
            name=serializer.validated_data['name'],
            description=serializer.validated_data.get('description'),
            scopes=serializer.validated_data.get('scopes', [])
        )
        # Associate relevant fields from the serializer
        api_key.allowed_ips = serializer.validated_data.get('allowed_ips', [])
        api_key.allowed_origins = serializer.validated_data.get('allowed_origins', [])
        api_key.rate_limit_requests = serializer.validated_data['rate_limit_requests']
        api_key.rate_limit_period = serializer.validated_data['rate_limit_period']
        api_key.daily_request_limit = serializer.validated_data.get('daily_request_limit')
        api_key.monthly_request_limit = serializer.validated_data.get('monthly_request_limit')
        api_key.expires_at = serializer.validated_data.get('expires_at')
        api_key.save()
        serializer.save(user=self.request.user, key_hash=api_key.key_hash)
        response_serializer = APIKeyResponseSerializer(
            {'api_key': api_key, 'secret_key': secret_key}
        )
        return Response(response_serializer.data, status=status.HTTP_201_CREATED)

    @action(detail=True, methods=['post'])
    def revoke(self, request, pk=None):
        """Revoke an API key"""
        api_key = self.get_object()
        api_key.revoke(reason=request.data.get('reason'))
        return Response({'message': 'API key revoked successfully'})

    @action(detail=True, methods=['post'])
    def rotate(self, request, pk=None):
        """Rotate an API key and return a new secret key"""
        api_key = self.get_object()
        new_secret_key = api_key.rotate()
        api_key.save()
        return Response({'message': 'API key rotated successfully', 'new_secret_key': new_secret_key})

    @action(detail=True, methods=['get'])
    def analytics(self, request, pk=None):
        """Get API key usage analytics"""
        api_key = self.get_object()
        requests = APIRequest.objects.filter(api_key=api_key)
        
        # Analytics data
        total_requests = requests.count()
        successful_requests = requests.filter(status_code__lt=400).count()
        failed_requests = total_requests - successful_requests
        error_rate = (failed_requests / total_requests) * 100 if total_requests else 0
        avg_response_time = requests.aggregate(avg_response_time=Avg('response_time'))['avg_response_time'] or 0
        requests_by_endpoint = requests.values('endpoint').annotate(count=Count('id')).order_by('-count')
        requests_by_status_code = requests.values('status_code').annotate(count=Count('id')).order_by('status_code')
        requests_by_day = requests.extra({'day': "date(timestamp)"}).values('day').annotate(count=Count('id')).order_by('day')
        top_ips = requests.values('ip_address').annotate(count=Count('id')).order_by('-count')[:10]
        usage_by_hour = requests.extra({'hour': "date_part('hour', timestamp)"}).values('hour').annotate(count=Count('id')).order_by('hour')

        analytics_data = {
            'total_requests': total_requests,
            'successful_requests': successful_requests,
            'failed_requests': failed_requests,
            'error_rate': error_rate,
            'avg_response_time': avg_response_time,
            'requests_by_endpoint': dict(requests_by_endpoint.values_list('endpoint', 'count')),
            'requests_by_status_code': dict(requests_by_status_code.values_list('status_code', 'count')),
            'requests_by_day': dict(requests_by_day.values_list('day', 'count')),
            'top_ips': list(top_ips.values_list('ip_address', flat=True)),
            'usage_by_hour': dict(usage_by_hour.values_list('hour', 'count')),
        }
        serializer = APIKeyAnalyticsSerializer(analytics_data)
        return Response(serializer.data)


class APIScopeViewSet(viewsets.ReadOnlyModelViewSet):
    """
    ViewSet for viewing API scopes
    """
    serializer_class = APIScopeSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        """Allow all users to view accessible scopes"""
        return APIScope.objects.all()


class APIRequestViewSet(viewsets.ReadOnlyModelViewSet):
    """
    ViewSet for viewing API requests
    """
    serializer_class = APIRequestSerializer
    permission_classes = [permissions.IsAuthenticated]
    filter_backends = [DjangoFilterBackend, SearchFilter, OrderingFilter]
    filterset_fields = ['method', 'endpoint', 'status_code', 'ip_address']
    search_fields = ['endpoint', 'api_key__name']
    ordering_fields = ['timestamp', 'response_time', 'status_code']
    ordering = ['-timestamp']

    def get_queryset(self):
        """Allow users to view their own requests or all if admin"""
        if self.request.user.is_staff:
            return APIRequest.objects.all()
        user_keys = APIKey.objects.filter(user=self.request.user)
        return APIRequest.objects.filter(api_key__in=user_keys)


class RateLimitBucketViewSet(viewsets.ReadOnlyModelViewSet):
    """
    ViewSet for viewing rate limit buckets
    """
    serializer_class = RateLimitBucketSerializer
    permission_classes = [permissions.IsAdminUser]
    
    def get_queryset(self):
        """Admin access to all rate limit buckets"""
        return RateLimitBucket.objects.all()


class APIKeyUsageQuotaViewSet(viewsets.ReadOnlyModelViewSet):
    """
    ViewSet for viewing API key usage quotas
    """
    serializer_class = APIKeyUsageQuotaSerializer
    permission_classes = [permissions.IsAuthenticated]
    filter_backends = [DjangoFilterBackend, SearchFilter, OrderingFilter]
    filterset_fields = ['quota_type', 'period_start', 'period_end']
    search_fields = ['api_key__name']
    ordering_fields = ['request_count', 'quota_limit', 'created_at']
    ordering = ['-created_at']

    def get_queryset(self):
        """Allow users to view their own quotas or all if admin"""
        if self.request.user.is_staff:
            return APIKeyUsageQuota.objects.all()
        user_keys = APIKey.objects.filter(user=self.request.user)
        return APIKeyUsageQuota.objects.filter(api_key__in=user_keys)


class APIKeyBulkActionViewSet(viewsets.ViewSet):
    """
    ViewSet for bulk actions on API keys
    """
    permission_classes = [permissions.IsAuthenticated]

    @action(detail=False, methods=['post'])
    def bulk_action(self, request):
        """Perform bulk actions on API keys"""
        serializer = APIKeyBulkActionSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        data = serializer.validated_data
        action_type = data['action']
        api_key_uuids = data['api_key_uuids']

        keys = APIKey.objects.filter(uuid__in=api_key_uuids, user=request.user)
        count = 0
        for key in keys:
            if action_type == 'activate':
                key.status = APIKeyStatus.ACTIVE
            elif action_type == 'deactivate':
                key.status = APIKeyStatus.INACTIVE
            elif action_type == 'revoke':
                key.revoke(reason=data.get('reason'))
            elif action_type == 'rotate':
                key.rotate()
            key.save()
            count += 1

        return Response({
            'message': f'Successfully performed {action_type} on {count} API keys',
            'count': count
        })

