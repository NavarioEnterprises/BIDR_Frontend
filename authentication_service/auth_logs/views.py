"""
BIDR Authentication Logging Views

This module contains views for logging and analyzing authentication activities
in the BIDR platform.
"""
from django.db.models import Count, Q, Avg, Max, Min
from django.utils import timezone
from django.http import HttpResponse
from datetime import datetime, timedelta
from rest_framework import status, viewsets, permissions
from rest_framework.decorators import api_view, permission_classes, action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django_filters.rest_framework import DjangoFilterBackend
from rest_framework.filters import SearchFilter, OrderingFilter
import csv
import json
from io import StringIO

from .models import AuthenticationLog, SecurityEvent, LoginSession, AuditTrail
from .serializers import (
    AuthenticationLogSerializer, AuthenticationLogCreateSerializer,
    SecurityEventSerializer, SecurityEventDetailSerializer,
    LoginSessionSerializer, AuditTrailSerializer,
    AuthenticationAnalyticsSerializer, UserActivitySummarySerializer,
    SecurityDashboardSerializer, LogFilterSerializer, BulkLogCreateSerializer,
    ExportRequestSerializer
)
from .utils import (
    detect_suspicious_activity, get_device_info, get_location_info,
    calculate_risk_score, generate_security_recommendations
)

@api_view(["POST"])
def log_action(request):
    try:
        cec_client_id = request.data.get('cec_client_id')
        employee_id = request.data.get('employee_id')
        employee_name = request.data.get('employee_name')
        action = request.data.get('action')
        details = request.data.get('details')
        policy_or_reference = request.data.get('policy_or_reference')
        device_id = request.data.get('device_id')
        ip_address = request.META.get('REMOTE_ADDR', '')
        is_payment = request.data.get('is_payment', False)
        payload = request.data.get('payload')
        response_text = request.data.get('response')
        status_code = request.data.get('status_code')
        latitude = request.data.get('latitude')
        longitude = request.data.get('longitude')
        app_name = request.data.get('app_name')
        app_version = request.data.get('app_version')

        log = AppLog(
            cec_client_id=cec_client_id,
            employee_id=employee_id,
            employee_name=employee_name,
            action=action,
            app_name=app_name,
            app_version=app_version,
            details=details,
            latitude=latitude,
            longitude=longitude,
            policy_or_reference=policy_or_reference,
            device_id=device_id,
            ip_address=ip_address,
            is_payment=is_payment,
            payload=payload,
            response=response_text,
            status_code=status_code,
            timestamp=now()
        )
        log.save()

        return Response({"success": True, "message": "Log saved successfully"}, status=status.HTTP_201_CREATED)
    except Exception as e:
        return Response({"success": False, "error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(["POST"])
def normalize_app_logs(request):
    client_id = request.data.get('client_id')
    start_date = request.data.get('start_date')
    end_date = request.data.get('end_date')

    try:
        logs = AppLog.objects.filter(
            cec_client_id=client_id,
            timestamp__date__range=[start_date, end_date]
        ).values(
            'employee_id', 'employee_name', 'action', 'timestamp'
        )

        df = pd.DataFrame(logs)
        if df.empty:
            return Response({'message': "No logs found for the given date range"}, status=status.HTTP_200_OK)

        df['timestamp'] = pd.to_datetime(df['timestamp']).dt.date
        daily_summary = df.groupby(['timestamp', 'employee_name', 'action']).size().reset_index(name='count')
        total_actions_per_day = daily_summary.groupby(['timestamp', 'employee_name'])['count'].sum().reset_index(
            name='total_actions')
        daily_summary = daily_summary.merge(total_actions_per_day, on=['timestamp', 'employee_name'])
        daily_summary['percentage'] = (daily_summary['count'] / daily_summary['total_actions']) * 100

        daily_summary_list = daily_summary.to_dict(orient='records')

        return Response({
            'message': "Logs normalized successfully",
            'data': daily_summary_list,
            'success': True
        }, status=status.HTTP_200_OK)

    except Exception as e:
        return Response({"error": str(e), "success": False}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


def get_branch_name(employee_id):
    return ""


@api_view(["POST"])
def get_most_active_app_users_and_branches(request):
    client_id = request.data.get('client_id')
    start_date = request.data.get('start_date')
    end_date = request.data.get('end_date')

    try:
        logs = AppLog.objects.filter(
            cec_client_id=client_id,
            timestamp__date__range=[start_date, end_date]
        ).values(
            'employee_id', 'employee_name', 'action', 'timestamp'
        )

        df = pd.DataFrame(logs)
        if df.empty:
            return Response({'message': "No logs found for the given date range"}, status=status.HTTP_200_OK)


        user_activity = df.groupby('employee_name').size().reset_index(name='count').sort_values(by='count',
                                                                                                 ascending=False)
        most_active_users = user_activity.head(10).to_dict(orient='records')


        branch_activity = df.groupby('employee_id').size().reset_index(name='count').sort_values(by='count',
                                                                                                 ascending=False)
        branch_activity['branch_name'] = branch_activity['employee_id'].apply(
            lambda x: get_branch_name(x))
        most_active_branches = branch_activity.groupby('branch_name')['count'].sum().reset_index().sort_values(
            by='count', ascending=False).head(10).to_dict(orient='records')

        return Response({
            'message': "Most active users and branches retrieved successfully",
            'most_active_users': most_active_users,
            'most_active_branches': most_active_branches,
            'success': True
        }, status=status.HTTP_200_OK)

    except Exception as e:
        return Response({"error": str(e), "success": False}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

def check_suspicious_activity(employee_id, latitude=None, longitude=None):
    suspicious_activities = []

    # Get today's logs for the employee
    today_start = datetime.combine(datetime.today(), datetime.min.time())
    today_end = datetime.combine(datetime.today(), datetime.max.time())
    today_logs = AppLog.objects.filter(employee_id=employee_id, timestamp__range=(today_start, today_end))

    # Check if the employee logged in with more than 5 devices on the same day
    device_count = today_logs.values('device_id').distinct().count()
    if device_count > 5:
        suspicious_activities.append("Logged in with more than 3 devices on the same day.")

    # Check if the latitude and longitude distance is more than 20km in the last 10 minutes
    if latitude and longitude:
        ten_minutes_ago = timezone.now() - timedelta(minutes=10)
        recent_logs = today_logs.filter(timestamp__gte=ten_minutes_ago)
        for log in recent_logs:
            if log.latitude and log.longitude:
                distance = services.haversine(float(log.latitude), float(log.longitude), float(latitude), float(longitude))
                if distance > 10:
                    suspicious_activities.append("Logged in from a location more than 10km away in the last 10 minutes.")
                    break

    # Check if the user tried to log in with a different password more than 3 times without successful login
    failed_login_attempts = today_logs.filter(action='login_failed').count()
    if failed_login_attempts > 3:
        suspicious_activities.append("More than 10 failed login attempts with different passwords.")

    # Check if the last login was 1000km away from the current login location
    last_login_log = today_logs.filter(action='login_success').last()
    if last_login_log and last_login_log.latitude and last_login_log.longitude:
        distance = services.haversine(float(last_login_log.latitude), float(last_login_log.longitude), float(latitude), float(longitude))
        if distance > 1000:
            suspicious_activities.append("Last login was more than 1000km away from the current login location.")

    # Log suspicious activities
    if suspicious_activities:
        new_activity = SuspiciousActivity.objects.create(
            cec_client_id=today_logs.first().cec_client_id,
            employee_id=employee_id,
            description="\n".join(suspicious_activities)
        )
        new_activity.logs.set(today_logs)
        new_activity.save()

    return suspicious_activities
