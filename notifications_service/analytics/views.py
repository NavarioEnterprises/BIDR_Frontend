from rest_framework import viewsets
from rest_framework.decorators import api_view
from rest_framework.response import Response
from .models import NotificationAnalytics, EngagementMetrics


class NotificationAnalyticsViewSet(viewsets.ModelViewSet):
    queryset = NotificationAnalytics.objects.all()
    def list(self, request):
        return Response({"message": "NotificationAnalytics list endpoint"})


class EngagementMetricsViewSet(viewsets.ModelViewSet):
    queryset = EngagementMetrics.objects.all()
    def list(self, request):
        return Response({"message": "EngagementMetrics list endpoint"})


@api_view(['GET'])
def get_analytics_report(request):
    return Response({
        "message": "Analytics report",
        "total_notifications": 0,
        "delivery_rate": "0%",
        "engagement_rate": "0%"
    })


@api_view(['GET'])
def get_engagement_metrics(request):
    return Response({
        "message": "Engagement metrics",
        "clicks": 0,
        "opens": 0,
        "unsubscribes": 0
    })
