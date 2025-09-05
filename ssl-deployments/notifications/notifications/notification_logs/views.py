from rest_framework import viewsets
from rest_framework.decorators import api_view
from rest_framework.response import Response
from .models import NotificationLog, SystemLog, ErrorLog, AuditLog, APILog


class NotificationLogViewSet(viewsets.ModelViewSet):
    queryset = NotificationLog.objects.all()
    def list(self, request):
        return Response({"message": "NotificationLog list endpoint"})


class SystemLogViewSet(viewsets.ModelViewSet):
    queryset = SystemLog.objects.all()
    def list(self, request):
        return Response({"message": "SystemLog list endpoint"})


class ErrorLogViewSet(viewsets.ModelViewSet):
    queryset = ErrorLog.objects.all()
    def list(self, request):
        return Response({"message": "ErrorLog list endpoint"})


class AuditLogViewSet(viewsets.ModelViewSet):
    queryset = AuditLog.objects.all()
    def list(self, request):
        return Response({"message": "AuditLog list endpoint"})


class APILogViewSet(viewsets.ModelViewSet):
    queryset = APILog.objects.all()
    def list(self, request):
        return Response({"message": "APILog list endpoint"})


@api_view(['GET'])
def export_logs(request):
    return Response({"message": "Export logs", "status": "success"})


@api_view(['GET'])
def search_logs(request):
    return Response({"message": "Search logs", "results": []})
