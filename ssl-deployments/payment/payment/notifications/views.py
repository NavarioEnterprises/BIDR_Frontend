from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status


@api_view(['GET'])
def notifications_info(request):
    """
    Notifications service information
    """
    return Response({
        'service': 'Notifications Service',
        'description': 'SMS and Email notifications for payment service',
        'status': 'active',
        'supported_channels': ['sms', 'email']
    }, status=status.HTTP_200_OK)


@api_view(['POST'])
def send_notification(request):
    """
    Send notification (placeholder)
    """
    channel = request.data.get('channel', 'sms')
    recipient = request.data.get('recipient')
    message = request.data.get('message')
    
    if not recipient or not message:
        return Response({
            'error': 'Recipient and message are required'
        }, status=status.HTTP_400_BAD_REQUEST)
    
    # Placeholder for actual notification sending
    return Response({
        'message': f'Notification sent via {channel}',
        'recipient': recipient,
        'status': 'sent'
    }, status=status.HTTP_200_OK)
