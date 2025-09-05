from rest_framework import viewsets, status, permissions
from rest_framework.decorators import api_view, action, permission_classes
from rest_framework.response import Response
from rest_framework.views import APIView
from django.http import JsonResponse
from django.utils import timezone
from .models import (
    NotificationTemplate, Notification, NotificationPreference, 
    NotificationBatch, NotificationQueue
)
from .services import NotificationDeliveryService


class NotificationTemplateViewSet(viewsets.ModelViewSet):
    """ViewSet for notification templates"""
    queryset = NotificationTemplate.objects.all()
    
    def list(self, request):
        return Response({"message": "NotificationTemplate list endpoint"})


class NotificationViewSet(viewsets.ModelViewSet):
    """ViewSet for notifications"""
    queryset = Notification.objects.all()
    permission_classes = [permissions.AllowAny]
    
    def list(self, request):
        return Response({"message": "Notification list endpoint"})


class NotificationPreferenceViewSet(viewsets.ModelViewSet):
    """ViewSet for notification preferences"""
    queryset = NotificationPreference.objects.all()
    
    def list(self, request):
        return Response({"message": "NotificationPreference list endpoint"})


class NotificationBatchViewSet(viewsets.ModelViewSet):
    """ViewSet for notification batches"""
    queryset = NotificationBatch.objects.all()
    
    def list(self, request):
        return Response({"message": "NotificationBatch list endpoint"})


class NotificationQueueViewSet(viewsets.ModelViewSet):
    """ViewSet for notification queue"""
    queryset = NotificationQueue.objects.all()
    
    def list(self, request):
        return Response({"message": "NotificationQueue list endpoint"})


class SendNotificationView(APIView):
    """Send a single notification with email and SMS support"""
    
    def post(self, request):
        """Send notification through multiple channels"""
        try:
            # Extract data from request
            data = request.data
            
            # Required fields
            recipient_id = data.get('recipient_id')
            notification_type = data.get('type', 'notification')
            subject = data.get('subject')
            message = data.get('message')
            
            if not all([recipient_id, subject, message]):
                return Response({
                    'success': False,
                    'error': 'recipient_id, subject, and message are required'
                }, status=status.HTTP_400_BAD_REQUEST)
            
            # Optional fields
            context = data.get('context', {})
            priority = data.get('priority', 'normal')
            channels = data.get('channels')  # ['email', 'sms', 'in_app']
            recipient_email = data.get('recipient_email')
            recipient_phone = data.get('recipient_phone')
            
            # Initialize service
            delivery_service = NotificationDeliveryService()
            
            # Send notification
            success, notification = delivery_service.send_notification(
                recipient_id=recipient_id,
                notification_type=notification_type,
                subject=subject,
                message=message,
                context=context,
                priority=priority,
                channels=channels,
                recipient_email=recipient_email,
                recipient_phone=recipient_phone
            )
            
            if success:
                return Response({
                    'success': True,
                    'message': 'Notification sent successfully',
                    'notification_id': str(notification.id),
                    'channels': {
                        'email': notification.email_sent,
                        'sms': notification.sms_sent,
                        'in_app': notification.in_app_sent
                    }
                }, status=status.HTTP_200_OK)
            else:
                return Response({
                    'success': False,
                    'message': 'Failed to send notification',
                    'notification_id': str(notification.id)
                }, status=status.HTTP_400_BAD_REQUEST)
                
        except Exception as e:
            return Response({
                'success': False,
                'error': f'Internal error: {str(e)}'
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


class SendOTPNotificationView(APIView):
    """Send OTP through multiple channels"""
    
    def post(self, request):
        """Send OTP via email and/or SMS"""
        try:
            data = request.data
            
            # Required fields
            recipient_id = data.get('recipient_id')
            otp_code = data.get('otp_code')
            
            if not all([recipient_id, otp_code]):
                return Response({
                    'success': False,
                    'error': 'recipient_id and otp_code are required'
                }, status=status.HTTP_400_BAD_REQUEST)
            
            # Optional fields
            recipient_email = data.get('recipient_email')
            recipient_phone = data.get('recipient_phone')
            channels = data.get('channels')  # ['email', 'sms']
            
            if not recipient_email and not recipient_phone:
                return Response({
                    'success': False,
                    'error': 'At least one of recipient_email or recipient_phone is required'
                }, status=status.HTTP_400_BAD_REQUEST)
            
            # Initialize service
            delivery_service = NotificationDeliveryService()
            
            # Send OTP
            result = delivery_service.send_otp_notification(
                recipient_id=recipient_id,
                otp_code=otp_code,
                recipient_email=recipient_email,
                recipient_phone=recipient_phone,
                channels=channels
            )
            
            if result['overall_success']:
                return Response({
                    'success': True,
                    'message': 'OTP sent successfully',
                    'notification_id': result['notification_id'],
                    'channels': result['channels']
                }, status=status.HTTP_200_OK)
            else:
                return Response({
                    'success': False,
                    'message': 'Failed to send OTP',
                    'notification_id': result['notification_id'],
                    'channels': result['channels']
                }, status=status.HTTP_400_BAD_REQUEST)
                
        except Exception as e:
            return Response({
                'success': False,
                'error': f'Internal error: {str(e)}'
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


class BulkSendNotificationsView(APIView):
    """Send bulk notifications"""
    
    def post(self, request):
        """Send notifications in bulk"""
        try:
            data = request.data
            
            # Required fields
            notifications = data.get('notifications', [])
            batch_name = data.get('batch_name', f'Bulk notification {timezone.now()}')
            
            if not notifications:
                return Response({
                    'success': False,
                    'error': 'notifications list is required'
                }, status=status.HTTP_400_BAD_REQUEST)
            
            # Initialize service
            delivery_service = NotificationDeliveryService()
            
            # Send bulk notifications
            result = delivery_service.send_bulk_notifications(
                notifications=notifications,
                batch_name=batch_name,
                template_id=data.get('template_id')
            )
            
            return Response({
                'success': True,
                'message': f"Bulk notification completed. {result['success_count']} sent, {result['failed_count']} failed.",
                'batch_id': result['batch_id'],
                'total': result['total'],
                'success_count': result['success_count'],
                'failed_count': result['failed_count'],
                'results': result.get('results', [])
            }, status=status.HTTP_200_OK)
            
        except Exception as e:
            return Response({
                'success': False,
                'error': f'Internal error: {str(e)}'
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([permissions.AllowAny])
def mark_as_read(request, notification_id):
    """Mark notification as read"""
    return Response({
        "message": f"Mark notification {notification_id} as read",
        "status": "success"
    })


@api_view(['GET'])
@permission_classes([permissions.AllowAny])
def get_user_notifications(request, user_id):
    """Get user notifications"""
    # Return sample notifications for testing
    sample_notifications = [
        {
            "id": "550e8400-e29b-41d4-a716-446655440000",
            "subject": "Welcome to BIDR!",
            "message": "Your account has been successfully created.",
            "html_content": "Your account has been successfully created. Welcome to the BIDR platform!",
            "notification_type": "account_update",
            "is_read": False,
            "created_at": "2024-01-15T10:30:00Z"
        },
        {
            "id": "550e8400-e29b-41d4-a716-446655440001", 
            "subject": "New Order Received",
            "message": "You have received a new order from a customer.",
            "html_content": "You have received a new order from a customer. Please check your dashboard for details.",
            "notification_type": "payment_success",
            "is_read": False,
            "created_at": "2024-01-14T15:45:00Z"
        },
        {
            "id": "550e8400-e29b-41d4-a716-446655440002",
            "subject": "Payment Processed",
            "message": "Your payment has been successfully processed.",
            "html_content": "Your payment has been successfully processed. Transaction ID: TXN123456",
            "notification_type": "payment_success", 
            "is_read": True,
            "created_at": "2024-01-13T09:15:00Z"
        }
    ]
    
    return Response({
        "message": f"Get notifications for user {user_id}",
        "notifications": sample_notifications
    })


@api_view(['GET'])
@permission_classes([permissions.AllowAny])
def get_unread_notifications(request, user_id):
    """Get unread notifications for user"""
    # Return sample unread notifications
    unread_notifications = [
        {
            "id": "550e8400-e29b-41d4-a716-446655440000",
            "subject": "Welcome to BIDR!",
            "message": "Your account has been successfully created.",
            "html_content": "Your account has been successfully created. Welcome to the BIDR platform!",
            "notification_type": "account_update",
            "is_read": False,
            "created_at": "2024-01-15T10:30:00Z"
        },
        {
            "id": "550e8400-e29b-41d4-a716-446655440001", 
            "subject": "New Order Received",
            "message": "You have received a new order from a customer.",
            "html_content": "You have received a new order from a customer. Please check your dashboard for details.",
            "notification_type": "payment_success",
            "is_read": False,
            "created_at": "2024-01-14T15:45:00Z"
        }
    ]
    
    return Response({
        "message": f"Get unread notifications for user {user_id}",
        "unread_count": len(unread_notifications),
        "notifications": unread_notifications
    })
