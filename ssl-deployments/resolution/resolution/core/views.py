from django.shortcuts import render
from django.http import JsonResponse
from django.utils import timezone
from rest_framework import viewsets, status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from .models import (
    UserProfile, SystemConfiguration, ServiceHealth, 
    APIKey, TransactionReference
)
from .serializers import (
    UserProfileSerializer, SystemConfigurationSerializer,
    ServiceHealthSerializer, APIKeySerializer, TransactionReferenceSerializer
)


class UserProfileViewSet(viewsets.ModelViewSet):
    queryset = UserProfile.objects.all()
    serializer_class = UserProfileSerializer
    permission_classes = [IsAuthenticated]


class SystemConfigurationViewSet(viewsets.ModelViewSet):
    queryset = SystemConfiguration.objects.all()
    serializer_class = SystemConfigurationSerializer
    permission_classes = [IsAuthenticated]


class ServiceHealthViewSet(viewsets.ModelViewSet):
    queryset = ServiceHealth.objects.all()
    serializer_class = ServiceHealthSerializer
    permission_classes = [IsAuthenticated]


class APIKeyViewSet(viewsets.ModelViewSet):
    queryset = APIKey.objects.all()
    serializer_class = APIKeySerializer
    permission_classes = [IsAuthenticated]


class TransactionReferenceViewSet(viewsets.ModelViewSet):
    queryset = TransactionReference.objects.all()
    serializer_class = TransactionReferenceSerializer
    permission_classes = [IsAuthenticated]


@api_view(['GET'])
@permission_classes([AllowAny])
def health_check(request):
    """Health check endpoint"""
    return Response({
        'status': 'healthy',
        'service': 'resolution_service',
        'timestamp': timezone.now(),
        'version': '1.0.0'
    })


@api_view(['GET'])
@permission_classes([AllowAny])
def service_info(request):
    """Service information endpoint"""
    return Response({
        'service_name': 'BIDR Resolution Service',
        'description': 'Post-transaction resolution service for reviews, returns, and disputes',
        'version': '1.0.0',
        'features': [
            'Review Management',
            'Return Processing',
            'Dispute Resolution',
            'Notification System',
            'Activity Logging'
        ],
        'endpoints': {
            'reviews': '/api/v1/reviews/',
            'returns': '/api/v1/returns/',
            'disputes': '/api/v1/disputes/',
            'notifications_service': '/api/v1/notifications_service/',
            'logs': '/api/v1/logs/'
        }
    })


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def service_statistics(request):
    """Service statistics endpoint"""
    stats = {
        'users': UserProfile.objects.count(),
        'transactions': TransactionReference.objects.count(),
        'active_api_keys': APIKey.objects.filter(is_active=True).count(),
        'service_health': ServiceHealth.objects.filter(status='healthy').count()
    }
    return Response(stats)
