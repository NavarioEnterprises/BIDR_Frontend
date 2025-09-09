import logging
from typing import Dict, List, Optional, Tuple
from django.core.mail import send_mail
from django.conf import settings
from django.utils import timezone
from django.db import transaction

from .models import (
    NotificationTemplate, Notification, NotificationPreference,
    NotificationBatch, NotificationQueue
)

# Import SMS service
try:
    from sms_portal.services import SMSNotificationService
    SMS_AVAILABLE = True
except ImportError:
    SMS_AVAILABLE = False

logger = logging.getLogger(__name__)


class NotificationDeliveryService:
    """Enhanced notification delivery service with email and SMS support"""
    
    def __init__(self):
        if SMS_AVAILABLE:
            self.sms_service = SMSNotificationService()
        else:
            self.sms_service = None
            logger.warning("SMS service not available")
    
    def send_notification(
        self,
        recipient_id: str,
        notification_type: str,
        subject: str,
        message: str,
        context: Optional[Dict] = None,
        template_id: Optional[str] = None,
        priority: str = 'normal',
        channels: Optional[List[str]] = None,
        recipient_email: Optional[str] = None,
        recipient_phone: Optional[str] = None
    ) -> Tuple[bool, Notification]:
        """
        Send notification through multiple channels (email, SMS, in-app)
        
        Args:
            recipient_id: User ID
            notification_type: Type of notification
            subject: Notification subject
            message: Notification message
            context: Additional context for templates
            template_id: Optional template ID
            priority: Notification priority
            channels: List of channels to use ['email', 'sms', 'in_app']
            recipient_email: Recipient email address
            recipient_phone: Recipient phone number
            
        Returns:
            Tuple of (success, Notification instance)
        """
        try:
            # Get user preferences if not specified
            if not channels:
                preferences = self._get_user_preferences(recipient_id)
                channels = self._determine_channels(preferences, notification_type)
            
            # Create notification record
            notification = Notification.objects.create(
                recipient_id=recipient_id,
                notification_type=notification_type,
                subject=subject,
                message=message,
                data=context or {},
                priority=priority,
                source_service='notification_service'
            )
            
            # Track delivery success for each channel
            delivery_success = {}
            overall_success = False
            
            # Send via in-app (always successful as it's just database storage)
            if 'in_app' in channels:
                notification.in_app_sent = True
                delivery_success['in_app'] = True
                overall_success = True
            
            # Send via email
            if 'email' in channels and recipient_email:
                email_success = self._send_email_notification(
                    recipient_email, subject, message, notification.id
                )
                notification.email_sent = email_success
                notification.email_status = 'sent' if email_success else 'failed'
                delivery_success['email'] = email_success
                if email_success:
                    overall_success = True
            
            # Send via SMS
            if 'sms' in channels and recipient_phone and self.sms_service:
                sms_success = self._send_sms_notification(
                    recipient_phone, message, notification_type, 
                    context, str(notification.id)
                )
                notification.sms_sent = sms_success
                notification.sms_status = 'sent' if sms_success else 'failed'
                delivery_success['sms'] = sms_success
                if sms_success:
                    overall_success = True
            
            # Update notification status
            notification.is_sent = overall_success
            if overall_success:
                notification.sent_at = timezone.now()
            
            notification.save()
            
            logger.info(
                f"Notification {notification.id} sent to {recipient_id}. "
                f"Channels: {delivery_success}"
            )
            
            return overall_success, notification
            
        except Exception as e:
            logger.error(f"Error sending notification to {recipient_id}: {str(e)}")
            # Still create notification record for tracking
            notification = Notification.objects.create(
                recipient_id=recipient_id,
                notification_type=notification_type,
                subject=subject,
                message=message,
                data=context or {},
                priority=priority,
                source_service='notification_service'
            )
            return False, notification
    
    def send_otp_notification(
        self,
        recipient_id: str,
        otp_code: str,
        recipient_email: Optional[str] = None,
        recipient_phone: Optional[str] = None,
        channels: Optional[List[str]] = None
    ) -> Dict[str, bool]:
        """
        Send OTP through multiple channels
        
        Args:
            recipient_id: User ID
            otp_code: OTP code to send
            recipient_email: Email address
            recipient_phone: Phone number
            channels: Channels to use (defaults to both email and SMS if available)
            
        Returns:
            Dict with channel success status
        """
        if not channels:
            channels = []
            if recipient_email:
                channels.append('email')
            if recipient_phone and self.sms_service:
                channels.append('sms')
        
        subject = "Your Verification Code - BIDR"
        message = f"Your verification code is: {otp_code}. This code expires in 5 minutes."
        context = {'code': otp_code, 'otp': otp_code}
        
        success, notification = self.send_notification(
            recipient_id=recipient_id,
            notification_type='otp',
            subject=subject,
            message=message,
            context=context,
            priority='high',
            channels=channels,
            recipient_email=recipient_email,
            recipient_phone=recipient_phone
        )
        
        return {
            'overall_success': success,
            'notification_id': str(notification.id),
            'channels': {
                'email': notification.email_sent,
                'sms': notification.sms_sent,
                'in_app': notification.in_app_sent
            }
        }
    
    def _send_email_notification(
        self, 
        email: str, 
        subject: str, 
        message: str, 
        notification_id: str
    ) -> bool:
        """Send email notification"""
        try:
            send_mail(
                subject=subject,
                message=message,
                from_email=settings.NOTIFICATION_SETTINGS.get(
                    'DEFAULT_FROM_EMAIL', 
                    'notifications@bidr.com'
                ),
                recipient_list=[email],
                fail_silently=False,
            )
            logger.info(f"Email sent successfully to {email} for notification {notification_id}")
            return True
        except Exception as e:
            logger.error(f"Failed to send email to {email}: {str(e)}")
            return False
    
    def _send_sms_notification(
        self,
        phone: str,
        message: str,
        notification_type: str,
        context: Optional[Dict],
        notification_id: str
    ) -> bool:
        """Send SMS notification"""
        if not self.sms_service:
            logger.warning("SMS service not available")
            return False
        
        try:
            success = self.sms_service.send_notification_sms(
                user_phone=phone,
                notification_type=notification_type,
                context=context or {'message': message},
                notification_id=notification_id
            )
            
            if success:
                logger.info(f"SMS sent successfully to {phone} for notification {notification_id}")
            else:
                logger.error(f"Failed to send SMS to {phone} for notification {notification_id}")
            
            return success
        except Exception as e:
            logger.error(f"Error sending SMS to {phone}: {str(e)}")
            return False
    
    def _get_user_preferences(self, user_id: str) -> Optional[NotificationPreference]:
        """Get user notification preferences"""
        try:
            return NotificationPreference.objects.get(user_id=user_id)
        except NotificationPreference.DoesNotExist:
            # Return default preferences
            return NotificationPreference(
                user_id=user_id,
                email_enabled=True,
                sms_enabled=False,
                push_enabled=True,
                in_app_enabled=True
            )
    
    def _determine_channels(
        self, 
        preferences: NotificationPreference, 
        notification_type: str
    ) -> List[str]:
        """Determine which channels to use based on user preferences"""
        channels = []
        
        # Check global preferences
        if preferences.in_app_enabled:
            channels.append('in_app')
        
        if preferences.email_enabled:
            channels.append('email')
        
        if preferences.sms_enabled and self.sms_service:
            channels.append('sms')
        
        # Check type-specific preferences
        type_prefs = preferences.type_preferences.get(notification_type, {})
        
        # Override with type-specific settings
        filtered_channels = []
        for channel in channels:
            if channel in type_prefs:
                if type_prefs[channel]:
                    filtered_channels.append(channel)
            else:
                filtered_channels.append(channel)
        
        return filtered_channels
    
    def send_bulk_notifications(
        self,
        notifications: List[Dict],
        batch_name: str,
        template_id: Optional[str] = None
    ) -> Dict:
        """
        Send notifications in bulk
        
        Args:
            notifications: List of notification dicts with recipient info
            batch_name: Name for the batch
            template_id: Optional template ID
            
        Returns:
            Batch processing results
        """
        try:
            # Create batch record
            batch = NotificationBatch.objects.create(
                name=batch_name,
                notification_type='bulk',
                total_recipients=len(notifications),
                status='processing',
                template_id=template_id,
                batch_data={'notifications': notifications}
            )
            
            success_count = 0
            failed_count = 0
            results = []
            
            for notification_data in notifications:
                try:
                    success, notification = self.send_notification(
                        recipient_id=notification_data['recipient_id'],
                        notification_type=notification_data.get('type', 'notification'),
                        subject=notification_data['subject'],
                        message=notification_data['message'],
                        context=notification_data.get('context'),
                        channels=notification_data.get('channels'),
                        recipient_email=notification_data.get('email'),
                        recipient_phone=notification_data.get('phone')
                    )
                    
                    if success:
                        success_count += 1
                    else:
                        failed_count += 1
                    
                    results.append({
                        'recipient_id': notification_data['recipient_id'],
                        'success': success,
                        'notification_id': str(notification.id)
                    })
                    
                except Exception as e:
                    failed_count += 1
                    results.append({
                        'recipient_id': notification_data.get('recipient_id', 'unknown'),
                        'success': False,
                        'error': str(e)
                    })
            
            # Update batch status
            batch.processed_count = len(notifications)
            batch.success_count = success_count
            batch.failed_count = failed_count
            batch.status = 'completed'
            batch.completed_at = timezone.now()
            batch.save()
            
            return {
                'batch_id': str(batch.id),
                'total': len(notifications),
                'success_count': success_count,
                'failed_count': failed_count,
                'results': results
            }
            
        except Exception as e:
            logger.error(f"Error in bulk notification sending: {str(e)}")
            return {
                'success': False,
                'error': str(e)
            }
    
    def get_notification_status(self, notification_id: str) -> Optional[Dict]:
        """Get detailed notification delivery status"""
        try:
            notification = Notification.objects.get(id=notification_id)
            
            return {
                'id': str(notification.id),
                'recipient_id': notification.recipient_id,
                'type': notification.notification_type,
                'subject': notification.subject,
                'status': {
                    'is_sent': notification.is_sent,
                    'is_read': notification.is_read,
                    'sent_at': notification.sent_at,
                    'read_at': notification.read_at
                },
                'channels': {
                    'email': {
                        'sent': notification.email_sent,
                        'status': notification.email_status
                    },
                    'sms': {
                        'sent': notification.sms_sent,
                        'status': notification.sms_status
                    },
                    'in_app': {
                        'sent': notification.in_app_sent
                    }
                },
                'priority': notification.priority,
                'retry_count': notification.retry_count,
                'created_at': notification.created_at
            }
        except Notification.DoesNotExist:
            return None