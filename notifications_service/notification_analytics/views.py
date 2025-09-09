from rest_framework import viewsets
from rest_framework.decorators import api_view
from rest_framework.response import Response


class NotificationStatisticsViewSet(viewsets.ViewSet):
    def list(self, request):
        return Response({"message": "NotificationStatistics list endpoint"})


class ChannelAnalyticsViewSet(viewsets.ViewSet):
    def list(self, request):
        return Response({"message": "ChannelAnalytics list endpoint"})


class UserEngagementMetricsViewSet(viewsets.ViewSet):
    def list(self, request):
        return Response({"message": "UserEngagementMetrics list endpoint"})


class NotificationTypeAnalyticsViewSet(viewsets.ViewSet):
    def list(self, request):
        return Response({"message": "NotificationTypeAnalytics list endpoint"})


class SystemPerformanceMetricsViewSet(viewsets.ViewSet):
    def list(self, request):
        return Response({"message": "SystemPerformanceMetrics list endpoint"})


class TrendAnalysisViewSet(viewsets.ViewSet):
    def list(self, request):
        return Response({"message": "TrendAnalysis list endpoint"})


class DeliveryMetricsViewSet(viewsets.ViewSet):
    def list(self, request):
        return Response({"message": "DeliveryMetrics list endpoint"})


class EngagementStatsViewSet(viewsets.ViewSet):
    def list(self, request):
        return Response({"message": "EngagementStats list endpoint"})


@api_view(['GET'])
def analytics_dashboard(request):
    return Response({
        "message": "Analytics dashboard",
        "total_notifications": 0,
        "successful_deliveries": 0,
        "failed_deliveries": 0,
        "pending_notifications": 0
    })


@api_view(['GET'])
def daily_report(request):
    return Response({"message": "Daily report", "data": []})


@api_view(['GET'])
def weekly_report(request):
    return Response({"message": "Weekly report", "data": []})


@api_view(['GET'])
def monthly_report(request):
    return Response({"message": "Monthly report", "data": []})


@api_view(['GET'])
def get_dashboard_stats(request):
    return Response({
        "message": "Dashboard statistics",
        "total_notifications": 0,
        "successful_deliveries": 0,
        "failed_deliveries": 0,
        "pending_notifications": 0
    })


@api_view(['GET'])
def export_analytics(request):
    return Response({"message": "Export analytics data", "status": "success"})
