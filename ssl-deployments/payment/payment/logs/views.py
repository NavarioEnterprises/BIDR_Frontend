from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status


@api_view(['GET'])
def logs_info(request):
    """
    Logs service information
    """
    return Response({
        'service': 'Logs Service',
        'description': 'Centralized logging for payment service',
        'status': 'active'
    }, status=status.HTTP_200_OK)
