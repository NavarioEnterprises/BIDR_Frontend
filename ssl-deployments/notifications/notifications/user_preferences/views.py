from rest_framework import viewsets
from rest_framework.decorators import api_view
from rest_framework.response import Response
from .models import UserPreference, UnsubscribeToken


class UserPreferenceViewSet(viewsets.ModelViewSet):
    queryset = UserPreference.objects.all()
    def list(self, request):
        return Response({"message": "UserPreference list endpoint"})


class UnsubscribeTokenViewSet(viewsets.ModelViewSet):
    queryset = UnsubscribeToken.objects.all()
    def list(self, request):
        return Response({"message": "UnsubscribeToken list endpoint"})


@api_view(['GET'])
def get_user_preferences(request, user_id):
    return Response({"message": f"Get preferences for user {user_id}"})


@api_view(['POST'])
def update_user_preferences(request, user_id):
    return Response({"message": f"Update preferences for user {user_id}", "status": "success"})


@api_view(['POST'])
def unsubscribe(request, token):
    return Response({"message": "Unsubscribed successfully", "status": "success"})
