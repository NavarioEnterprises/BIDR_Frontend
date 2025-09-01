from rest_framework import status, generics, permissions
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.views import APIView
from django.db.models import Q
from django.utils import timezone
from datetime import timedelta

from .models import SMSPortalConfig, SMSMessage, SMSUsageStats, SMSTemplate
from .serializers import (
    SMSPortalConfigSerializer, SMSMessageSerializer, SendSMSSerializer,
    SendOTPSMSSerializer, SMSUsageStatsSerializer, SMSTemplateSerializer,
    MessageStatusUpdateSerializer, BulkSMSSerializer
)
from .services import SMSPortalService, SMSNotificationService


class SMSPortalConfigListView(generics.ListCreateAPIView):
    """List and create SMS Portal configurations"""
    queryset = SMSPortalConfig.objects.all()
    serializer_class = SMSPortalConfigSerializer
    permission_classes = [permissions.IsAdminUser]


class SMSPortalConfigDetailView(generics.RetrieveUpdateDestroyAPIView):
    """Retrieve, update, and delete SMS Portal configuration"""
    queryset = SMSPortalConfig.objects.all()
    serializer_class = SMSPortalConfigSerializer
    permission_classes = [permissions.IsAdminUser]


class SMSMessageListView(generics.ListAPIView):
    """List SMS messages with filtering"""
    queryset = SMSMessage.objects.all()
    serializer_class = SMSMessageSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        queryset = super().get_queryset()
        
        # Filter parameters
        status_filter = self.request.query_params.get('status')
        message_type = self.request.query_params.get('message_type')
        phone_number = self.request.query_params.get('phone_number')
        date_from = self.request.query_params.get('date_from')
        date_to = self.request.query_params.get('date_to')
        
        if status_filter:
            queryset = queryset.filter(status=status_filter)
        
        if message_type:
            queryset = queryset.filter(message_type=message_type)
        
        if phone_number:
            queryset = queryset.filter(recipient_phone__icontains=phone_number)
        
        if date_from:
            queryset = queryset.filter(created_at__date__gte=date_from)
        
        if date_to:
            queryset = queryset.filter(created_at__date__lte=date_to)
        
        return queryset.order_by('-created_at')


class SMSMessageDetailView(generics.RetrieveAPIView):
    """Retrieve SMS message details"""
    queryset = SMSMessage.objects.all()
    serializer_class = SMSMessageSerializer
    permission_classes = [permissions.IsAuthenticated]


class SendSMSView(APIView):
    """Send SMS message"""
    permission_classes = [permissions.AllowAny]
    
    def post(self, request):
        serializer = SendSMSSerializer(data=request.data)
        if serializer.is_valid():
            try:
                sms_service = SMSPortalService()
                
                success, sms_message = sms_service.send_sms(
                    phone_number=serializer.validated_data['phone_number'],
                    message=serializer.validated_data['message'],
                    sender_id=serializer.validated_data.get('sender_id'),
                    message_type=serializer.validated_data.get('message_type', 'notification'),
                    notification_id=serializer.validated_data.get('notification_id')
                )
                
                if success:
                    return Response({
                        'success': True,
                        'message': 'SMS sent successfully',
                        'sms_id': sms_message.id,
                        'external_id': sms_message.external_message_id
                    }, status=status.HTTP_200_OK)
                else:
                    return Response({
                        'success': False,
                        'message': 'Failed to send SMS',
                        'error': sms_message.error_message,
                        'sms_id': sms_message.id
                    }, status=status.HTTP_400_BAD_REQUEST)
                    
            except ValueError as e:
                return Response({
                    'success': False,
                    'message': str(e)
                }, status=status.HTTP_400_BAD_REQUEST)
            except Exception as e:
                return Response({
                    'success': False,
                    'message': f'Internal error: {str(e)}'
                }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
        
        return Response({
            'success': False,
            'message': 'Validation failed',
            'errors': serializer.errors
        }, status=status.HTTP_400_BAD_REQUEST)


class SendOTPSMSView(APIView):
    """Send OTP SMS with template support"""
    permission_classes = [permissions.AllowAny]
    
    def post(self, request):
        serializer = SendOTPSMSSerializer(data=request.data)
        if serializer.is_valid():
            try:
                sms_service = SMSPortalService()
                
                success, sms_message = sms_service.send_otp_sms(
                    phone_number=serializer.validated_data['phone_number'],
                    otp_code=serializer.validated_data['otp_code'],
                    template_name=serializer.validated_data.get('template_name', 'otp_verification'),
                    context=serializer.validated_data.get('context', {})
                )
                
                if success:
                    return Response({
                        'success': True,
                        'message': 'OTP SMS sent successfully',
                        'sms_id': sms_message.id,
                        'external_id': sms_message.external_message_id
                    }, status=status.HTTP_200_OK)
                else:
                    return Response({
                        'success': False,
                        'message': 'Failed to send OTP SMS',
                        'error': sms_message.error_message,
                        'sms_id': sms_message.id
                    }, status=status.HTTP_400_BAD_REQUEST)
                    
            except ValueError as e:
                return Response({
                    'success': False,
                    'message': str(e)
                }, status=status.HTTP_400_BAD_REQUEST)
            except Exception as e:
                return Response({
                    'success': False,
                    'message': f'Internal error: {str(e)}'
                }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
        
        return Response({
            'success': False,
            'message': 'Validation failed',
            'errors': serializer.errors
        }, status=status.HTTP_400_BAD_REQUEST)


class BulkSMSView(APIView):
    """Send bulk SMS messages"""
    permission_classes = [permissions.AllowAny]
    
    def post(self, request):
        serializer = BulkSMSSerializer(data=request.data)
        if serializer.is_valid():
            try:
                sms_service = SMSPortalService()
                recipients = serializer.validated_data['recipients']
                message = serializer.validated_data['message']
                sender_id = serializer.validated_data.get('sender_id')
                message_type = serializer.validated_data.get('message_type', 'notification')
                
                results = []
                success_count = 0
                failed_count = 0
                
                for phone_number in recipients:
                    success, sms_message = sms_service.send_sms(
                        phone_number=phone_number,
                        message=message,
                        sender_id=sender_id,
                        message_type=message_type
                    )
                    
                    results.append({
                        'phone_number': phone_number,
                        'success': success,
                        'sms_id': sms_message.id,
                        'external_id': sms_message.external_message_id if success else None,
                        'error': sms_message.error_message if not success else None
                    })
                    
                    if success:
                        success_count += 1
                    else:
                        failed_count += 1
                
                return Response({
                    'success': True,
                    'message': f'Bulk SMS completed. {success_count} sent, {failed_count} failed.',
                    'total_recipients': len(recipients),
                    'success_count': success_count,
                    'failed_count': failed_count,
                    'results': results
                }, status=status.HTTP_200_OK)
                
            except ValueError as e:
                return Response({
                    'success': False,
                    'message': str(e)
                }, status=status.HTTP_400_BAD_REQUEST)
            except Exception as e:
                return Response({
                    'success': False,
                    'message': f'Internal error: {str(e)}'
                }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
        
        return Response({
            'success': False,
            'message': 'Validation failed',
            'errors': serializer.errors
        }, status=status.HTTP_400_BAD_REQUEST)


class UpdateMessageStatusView(APIView):
    """Update message statuses from SMS Portal"""
    permission_classes = [permissions.IsAuthenticated]
    
    def post(self, request):
        serializer = MessageStatusUpdateSerializer(data=request.data)
        if serializer.is_valid():
            try:
                sms_service = SMSPortalService()
                message_ids = serializer.validated_data['message_ids']
                
                updated_messages = []
                for message_id in message_ids:
                    try:
                        sms_message = SMSMessage.objects.get(id=message_id)
                        if sms_message.external_message_id:
                            status_info = sms_service.check_message_status(
                                sms_message.external_message_id
                            )
                            if status_info:
                                old_status = sms_message.status
                                # Update status based on SMS Portal response
                                new_status = status_info.get('status', '').lower()
                                status_mapping = {
                                    'delivered': 'delivered',
                                    'failed': 'failed',
                                    'bounced': 'bounced',
                                    'rejected': 'rejected',
                                }
                                
                                if new_status in status_mapping:
                                    sms_message.status = status_mapping[new_status]
                                    sms_message.external_status = new_status
                                    
                                    if new_status == 'delivered' and not sms_message.delivered_at:
                                        sms_message.delivered_at = timezone.now()
                                    
                                    sms_message.response_data.update(status_info)
                                    sms_message.save()
                                    
                                    updated_messages.append({
                                        'message_id': message_id,
                                        'old_status': old_status,
                                        'new_status': sms_message.status,
                                        'updated': True
                                    })
                                else:
                                    updated_messages.append({
                                        'message_id': message_id,
                                        'status': old_status,
                                        'updated': False,
                                        'reason': 'Unknown status from provider'
                                    })
                            else:
                                updated_messages.append({
                                    'message_id': message_id,
                                    'status': sms_message.status,
                                    'updated': False,
                                    'reason': 'Failed to get status from provider'
                                })
                        else:
                            updated_messages.append({
                                'message_id': message_id,
                                'status': sms_message.status,
                                'updated': False,
                                'reason': 'No external message ID'
                            })
                    except SMSMessage.DoesNotExist:
                        updated_messages.append({
                            'message_id': message_id,
                            'updated': False,
                            'reason': 'Message not found'
                        })
                
                return Response({
                    'success': True,
                    'message': 'Status update completed',
                    'results': updated_messages
                }, status=status.HTTP_200_OK)
                
            except Exception as e:
                return Response({
                    'success': False,
                    'message': f'Internal error: {str(e)}'
                }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
        
        return Response({
            'success': False,
            'message': 'Validation failed',
            'errors': serializer.errors
        }, status=status.HTTP_400_BAD_REQUEST)


class SMSUsageStatsListView(generics.ListAPIView):
    """List SMS usage statistics"""
    queryset = SMSUsageStats.objects.all()
    serializer_class = SMSUsageStatsSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        queryset = super().get_queryset()
        
        # Filter parameters
        date_from = self.request.query_params.get('date_from')
        date_to = self.request.query_params.get('date_to')
        
        if date_from:
            queryset = queryset.filter(date__gte=date_from)
        
        if date_to:
            queryset = queryset.filter(date__lte=date_to)
        
        return queryset.order_by('-date')


class SMSTemplateListView(generics.ListCreateAPIView):
    """List and create SMS templates"""
    queryset = SMSTemplate.objects.all()
    serializer_class = SMSTemplateSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        queryset = super().get_queryset()
        
        # Filter parameters
        message_type = self.request.query_params.get('message_type')
        is_active = self.request.query_params.get('is_active')
        
        if message_type:
            queryset = queryset.filter(message_type=message_type)
        
        if is_active is not None:
            queryset = queryset.filter(is_active=is_active.lower() == 'true')
        
        return queryset.order_by('name')


class SMSTemplateDetailView(generics.RetrieveUpdateDestroyAPIView):
    """Retrieve, update, and delete SMS template"""
    queryset = SMSTemplate.objects.all()
    serializer_class = SMSTemplateSerializer
    permission_classes = [permissions.IsAuthenticated]


@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def sms_dashboard_stats(request):
    """Get SMS dashboard statistics"""
    try:
        # Get date range
        days = int(request.query_params.get('days', 30))
        start_date = timezone.now().date() - timedelta(days=days)
        
        # Get statistics
        messages = SMSMessage.objects.filter(created_at__date__gte=start_date)
        
        # Basic stats
        total_messages = messages.count()
        sent_messages = messages.filter(status__in=['sent', 'delivered']).count()
        failed_messages = messages.filter(status='failed').count()
        delivered_messages = messages.filter(status='delivered').count()
        
        # Calculate rates
        success_rate = (sent_messages / total_messages * 100) if total_messages > 0 else 0
        delivery_rate = (delivered_messages / sent_messages * 100) if sent_messages > 0 else 0
        
        # Message type breakdown
        message_types = messages.values('message_type').distinct()
        type_breakdown = {}
        for msg_type in message_types:
            type_name = msg_type['message_type']
            count = messages.filter(message_type=type_name).count()
            type_breakdown[type_name] = count
        
        # Recent activity (last 7 days)
        recent_start = timezone.now().date() - timedelta(days=7)
        recent_messages = SMSMessage.objects.filter(created_at__date__gte=recent_start)
        daily_stats = {}
        
        for i in range(7):
            date = recent_start + timedelta(days=i)
            daily_count = recent_messages.filter(created_at__date=date).count()
            daily_stats[date.isoformat()] = daily_count
        
        # Cost information
        total_cost = sum(
            msg.cost for msg in messages.filter(cost__isnull=False)
        ) or 0
        
        return Response({
            'success': True,
            'data': {
                'period_days': days,
                'total_messages': total_messages,
                'sent_messages': sent_messages,
                'failed_messages': failed_messages,
                'delivered_messages': delivered_messages,
                'success_rate': round(success_rate, 1),
                'delivery_rate': round(delivery_rate, 1),
                'total_cost': float(total_cost),
                'message_type_breakdown': type_breakdown,
                'daily_activity': daily_stats
            }
        }, status=status.HTTP_200_OK)
        
    except Exception as e:
        return Response({
            'success': False,
            'message': f'Error getting dashboard stats: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([permissions.IsAdminUser])
def account_balance(request):
    """Get SMS Portal account balance"""
    try:
        sms_service = SMSPortalService()
        balance_info = sms_service.get_account_balance()
        
        if balance_info:
            return Response({
                'success': True,
                'data': balance_info
            }, status=status.HTTP_200_OK)
        else:
            return Response({
                'success': False,
                'message': 'Failed to get account balance'
            }, status=status.HTTP_400_BAD_REQUEST)
            
    except Exception as e:
        return Response({
            'success': False,
            'message': f'Error getting account balance: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)