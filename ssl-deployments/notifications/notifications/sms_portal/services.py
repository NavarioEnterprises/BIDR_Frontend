import requests
import json
import logging
from datetime import datetime, timedelta
from decimal import Decimal
from typing import Dict, Optional, Tuple
from django.conf import settings
from django.utils import timezone
from django.db import transaction

from .models import SMSPortalConfig, SMSMessage, SMSUsageStats, SMSTemplate

logger = logging.getLogger(__name__)


class SMSPortalService:
    """Service class for SMS Portal API integration"""
    
    def __init__(self, config_name: str = "SMS Portal"):
        """Initialize with SMS Portal configuration"""
        try:
            self.config = SMSPortalConfig.objects.get(name=config_name, is_active=True)
        except SMSPortalConfig.DoesNotExist:
            # If no config exists, use settings
            from django.conf import settings
            self.use_settings = True
            self.username = getattr(settings, 'SMS_PORTAL_USERNAME', None)
            self.password = getattr(settings, 'SMS_PORTAL_PASSWORD', None)
            self.endpoint = getattr(settings, 'SMS_PORTAL_ENDPOINT', None)
            self.from_name = getattr(settings, 'SMS_PORTAL_FROM_NAME', 'BIDR')
            
            if not all([self.username, self.password, self.endpoint]):
                raise ValueError("SMS Portal configuration not found in database or settings")
        else:
            self.use_settings = False
        
        self.session = requests.Session()
        self.session.headers.update({
            'Content-Type': 'application/x-www-form-urlencoded',
            'User-Agent': 'BIDR-Notifications/1.0'
        })
    
    def send_sms(
        self, 
        phone_number: str, 
        message: str, 
        sender_id: Optional[str] = None,
        message_type: str = 'notification',
        notification_id: Optional[str] = None
    ) -> Tuple[bool, SMSMessage]:
        """
        Send SMS message through SMS Portal API
        
        Args:
            phone_number: Recipient phone number
            message: Message content
            sender_id: Optional sender ID (uses default if not provided)
            message_type: Type of message (otp, notification, etc.)
            notification_id: Optional notification ID for tracking
            
        Returns:
            Tuple of (success, SMSMessage instance)
        """
        # Create SMS message record
        sms_message = SMSMessage.objects.create(
            recipient_phone=phone_number,
            message_content=message,
            sender_id=sender_id or self.config.default_sender_id,
            message_type=message_type,
            notification_id=notification_id,
            status='queued'
        )
        
        try:
            # Update status to sending
            sms_message.status = 'sending'
            sms_message.save()
            
            # Prepare API request
            if self.use_settings:
                # Use SMS Portal v5 API format
                params = {
                    'Type': 'sendparam',
                    'Username': self.username,
                    'Password': self.password,
                    'Numto': phone_number.replace('+', ''),  # Remove + prefix
                    'Data1': message,
                    'customerID': sender_id or self.from_name
                }
                
                # Send request to SMS Portal API
                response = self.session.get(
                    self.endpoint,
                    params=params,
                    timeout=30
                )
            else:
                # Use database config
                headers = {**self.session.headers}
                if hasattr(self.config, 'api_key') and self.config.api_key:
                    headers['Authorization'] = f'Bearer {self.config.api_key}'
                if hasattr(self.config, 'api_secret') and self.config.api_secret:
                    headers['X-API-Secret'] = self.config.api_secret
                
                # SMS Portal API payload structure
                payload = {
                    'messages': [{
                        'content': message,
                        'destination': phone_number,
                        'source': sender_id or self.config.default_sender_id
                    }]
                }
                
                # Send request to SMS Portal API
                response = self.session.post(
                    f"{self.config.api_url}/messages",
                    headers=headers,
                    json=payload,
                    timeout=30
                )
            
            # Parse response
            if self.use_settings:
                # SMS Portal v5 returns plain text response
                response_text = response.text.strip()
                response_data = {'response': response_text}
                
                # Check if response indicates success (starts with message ID)
                if response.status_code == 200 and response_text and not response_text.startswith('ERR'):
                    # Success - response is the message ID
                    external_id = response_text
                    external_status = 'sent'
                    cost = 0.1  # Default cost per SMS
                    success_response = True
                else:
                    success_response = False
                    error_message = response_text if response_text.startswith('ERR') else f'HTTP {response.status_code}'
            else:
                response_data = response.json() if response.content else {}
                success_response = response.status_code == 200
            
            if success_response:
                # Success - extract message ID and status
                if self.use_settings:
                    # Already handled above
                    pass
                else:
                    message_data = response_data.get('messages', [{}])[0]
                    external_id = message_data.get('id', '')
                    external_status = message_data.get('status', 'sent')
                    cost = message_data.get('cost', 0)
                
                # Update SMS message record
                sms_message.external_message_id = external_id
                sms_message.external_status = external_status
                sms_message.status = 'sent'
                sms_message.sent_at = timezone.now()
                sms_message.response_data = response_data
                sms_message.cost = Decimal(str(cost)) if cost else None
                sms_message.save()
                
                # Update config last used
                if not self.use_settings:
                    self.config.last_used = timezone.now()
                    self.config.save()
                
                # Update usage statistics
                self._update_usage_stats(message_type, True, cost)
                
                logger.info(f"SMS sent successfully to {phone_number}, Message ID: {external_id}")
                return True, sms_message
                
            else:
                # Failure - log error and update record
                if self.use_settings:
                    # Already set error_message above
                    error_code = 'SMS_PORTAL_ERROR'
                else:
                    error_message = response_data.get('error', f'HTTP {response.status_code}')
                    error_code = response_data.get('error_code', str(response.status_code))
                
                sms_message.status = 'failed'
                sms_message.error_message = error_message
                sms_message.error_code = error_code
                sms_message.response_data = response_data
                sms_message.save()
                
                # Update usage statistics
                self._update_usage_stats(message_type, False, 0)
                
                logger.error(f"Failed to send SMS to {phone_number}: {error_message}")
                return False, sms_message
                
        except requests.exceptions.RequestException as e:
            # Network or request error
            sms_message.status = 'failed'
            sms_message.error_message = f"Request error: {str(e)}"
            sms_message.error_code = 'REQUEST_ERROR'
            sms_message.save()
            
            self._update_usage_stats(message_type, False, 0)
            
            logger.error(f"Request error sending SMS to {phone_number}: {str(e)}")
            return False, sms_message
            
        except Exception as e:
            # Unexpected error
            sms_message.status = 'failed'
            sms_message.error_message = f"Unexpected error: {str(e)}"
            sms_message.error_code = 'UNKNOWN_ERROR'
            sms_message.save()
            
            self._update_usage_stats(message_type, False, 0)
            
            logger.error(f"Unexpected error sending SMS to {phone_number}: {str(e)}")
            return False, sms_message
    
    def send_otp_sms(
        self, 
        phone_number: str, 
        otp_code: str, 
        template_name: str = 'otp_verification',
        context: Optional[Dict] = None
    ) -> Tuple[bool, SMSMessage]:
        """
        Send OTP SMS using template
        
        Args:
            phone_number: Recipient phone number
            otp_code: OTP code to send
            template_name: Template name to use
            context: Additional context for template
            
        Returns:
            Tuple of (success, SMSMessage instance)
        """
        try:
            # Get template
            template = SMSTemplate.objects.get(
                name=template_name, 
                message_type='otp',
                is_active=True
            )
            
            # Prepare context
            template_context = {
                'code': otp_code,
                'otp': otp_code,
                **(context or {})
            }
            
            # Render message
            message = template.render_content(template_context)
            sender_id = template.sender_id or self.config.default_sender_id
            
            # Send SMS
            success, sms_message = self.send_sms(
                phone_number=phone_number,
                message=message,
                sender_id=sender_id,
                message_type='otp'
            )
            
            if success:
                # Update template usage
                template.usage_count += 1
                template.last_used = timezone.now()
                template.save()
            
            return success, sms_message
            
        except SMSTemplate.DoesNotExist:
            # Create default OTP message if template doesn't exist
            default_message = f"Your verification code is: {otp_code}. This code expires in 5 minutes."
            return self.send_sms(
                phone_number=phone_number,
                message=default_message,
                message_type='otp'
            )
    
    def _update_usage_stats(self, message_type: str, success: bool, cost: float):
        """Update daily usage statistics"""
        today = timezone.now().date()
        
        with transaction.atomic():
            stats, created = SMSUsageStats.objects.get_or_create(
                date=today,
                defaults={
                    'total_sent': 0,
                    'total_delivered': 0,
                    'total_failed': 0,
                    'total_cost': Decimal('0'),
                    'total_credits_used': 0,
                    'otp_count': 0,
                    'notification_count': 0,
                    'alert_count': 0,
                    'marketing_count': 0,
                    'system_count': 0,
                }
            )
            
            # Update counts
            stats.total_sent += 1
            if success:
                stats.total_delivered += 1
            else:
                stats.total_failed += 1
            
            stats.total_cost += Decimal(str(cost))
            stats.total_credits_used += 1
            
            # Update message type count
            type_field = f"{message_type}_count"
            if hasattr(stats, type_field):
                setattr(stats, type_field, getattr(stats, type_field) + 1)
            
            stats.save()
    
    def check_message_status(self, message_id: str) -> Optional[Dict]:
        """
        Check delivery status of a message from SMS Portal
        
        Args:
            message_id: External message ID from SMS Portal
            
        Returns:
            Status information dict or None if error
        """
        try:
            headers = {**self.session.headers, **self._authenticate()}
            
            response = self.session.get(
                f"{self.config.api_url}/messages/{message_id}/status",
                headers=headers,
                timeout=30
            )
            
            if response.status_code == 200:
                return response.json()
            else:
                logger.error(f"Failed to check message status for {message_id}: HTTP {response.status_code}")
                return None
                
        except Exception as e:
            logger.error(f"Error checking message status for {message_id}: {str(e)}")
            return None
    
    def update_message_statuses(self):
        """Update status of pending messages by checking with SMS Portal API"""
        pending_messages = SMSMessage.objects.filter(
            status__in=['sent', 'queued'],
            external_message_id__isnull=False
        ).exclude(external_message_id='')
        
        updated_count = 0
        for message in pending_messages:
            status_info = self.check_message_status(message.external_message_id)
            
            if status_info:
                new_status = status_info.get('status', '').lower()
                
                # Map SMS Portal status to our status
                status_mapping = {
                    'delivered': 'delivered',
                    'failed': 'failed',
                    'bounced': 'bounced',
                    'rejected': 'rejected',
                }
                
                if new_status in status_mapping:
                    message.external_status = new_status
                    message.status = status_mapping[new_status]
                    
                    if new_status == 'delivered' and not message.delivered_at:
                        message.delivered_at = timezone.now()
                    
                    message.response_data.update(status_info)
                    message.save()
                    updated_count += 1
        
        logger.info(f"Updated status for {updated_count} SMS messages")
        return updated_count
    
    def get_account_balance(self) -> Optional[Dict]:
        """Get account balance from SMS Portal"""
        try:
            headers = {**self.session.headers, **self._authenticate()}
            
            response = self.session.get(
                f"{self.config.api_url}/account/balance",
                headers=headers,
                timeout=30
            )
            
            if response.status_code == 200:
                return response.json()
            else:
                logger.error(f"Failed to get account balance: HTTP {response.status_code}")
                return None
                
        except Exception as e:
            logger.error(f"Error getting account balance: {str(e)}")
            return None


class SMSNotificationService:
    """High-level service for sending notifications via SMS"""
    
    def __init__(self):
        self.sms_service = SMSPortalService()
    
    def send_notification_sms(
        self, 
        user_phone: str, 
        notification_type: str, 
        context: Dict,
        template_name: Optional[str] = None,
        notification_id: Optional[str] = None
    ) -> bool:
        """
        Send notification SMS with template support
        
        Args:
            user_phone: User's phone number
            notification_type: Type of notification
            context: Context data for template
            template_name: Optional specific template name
            notification_id: Optional notification ID
            
        Returns:
            True if sent successfully, False otherwise
        """
        try:
            # Try to find appropriate template
            if template_name:
                template_query = SMSTemplate.objects.filter(name=template_name)
            else:
                template_query = SMSTemplate.objects.filter(message_type=notification_type)
            
            template = template_query.filter(is_active=True).first()
            
            if template:
                # Use template
                message = template.render_content(context)
                sender_id = template.sender_id or self.sms_service.config.default_sender_id
                
                success, sms_message = self.sms_service.send_sms(
                    phone_number=user_phone,
                    message=message,
                    sender_id=sender_id,
                    message_type=notification_type,
                    notification_id=notification_id
                )
                
                if success and template:
                    template.usage_count += 1
                    template.last_used = timezone.now()
                    template.save()
                
                return success
            else:
                # No template found, create basic message
                message = self._create_default_message(notification_type, context)
                success, _ = self.sms_service.send_sms(
                    phone_number=user_phone,
                    message=message,
                    message_type=notification_type,
                    notification_id=notification_id
                )
                return success
                
        except Exception as e:
            logger.error(f"Error sending notification SMS to {user_phone}: {str(e)}")
            return False
    
    def _create_default_message(self, notification_type: str, context: Dict) -> str:
        """Create default message when no template is available"""
        default_messages = {
            'otp': f"Your verification code is: {context.get('code', 'N/A')}",
            'notification': f"You have a new notification: {context.get('message', 'Check your account')}",
            'alert': f"Alert: {context.get('message', 'Important notification')}",
            'system': f"System notification: {context.get('message', 'Please check your account')}",
        }
        
        return default_messages.get(
            notification_type, 
            f"Notification: {context.get('message', 'You have a new notification')}"
        )