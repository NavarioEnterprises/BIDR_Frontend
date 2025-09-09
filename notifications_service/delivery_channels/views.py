from rest_framework import viewsets
from rest_framework.decorators import api_view
from rest_framework.response import Response
from .models import NotificationChannel, ChannelCredential, DeliveryAttempt, ChannelRateLimit


class NotificationChannelViewSet(viewsets.ModelViewSet):
    queryset = NotificationChannel.objects.all()
    def list(self, request):
        return Response({"message": "NotificationChannel list endpoint"})


class ChannelCredentialViewSet(viewsets.ModelViewSet):
    queryset = ChannelCredential.objects.all()
    def list(self, request):
        return Response({"message": "ChannelCredential list endpoint"})


class DeliveryAttemptViewSet(viewsets.ModelViewSet):
    queryset = DeliveryAttempt.objects.all()
    def list(self, request):
        return Response({"message": "DeliveryAttempt list endpoint"})


class ChannelRateLimitViewSet(viewsets.ModelViewSet):
    queryset = ChannelRateLimit.objects.all()
    def list(self, request):
        return Response({"message": "ChannelRateLimit list endpoint"})


@api_view(['POST'])
def test_channel(request, channel_id):
    return Response({"message": f"Test channel {channel_id}", "status": "success"})


@api_view(['GET'])
def channel_statistics(request):
    return Response({"message": "Channel statistics", "data": {}})
