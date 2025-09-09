import requests
import json
import logging
from typing import Dict, Optional, Tuple
from django.core.mail import send_mail
from django.conf import settings
from django.utils import timezone

logger = logging.getLogger(__name__)


class OTPDeliveryService:
    """Service for sending OTPs via email and SMS"""
    
    def __init__(self):
        # SMS Portal configuration
        self.sms_api_url = getattr(settings, 'SMS_PORTAL_API_URL', 'https://rest.smsportal.com/v1')
        self.sms_api_key = getattr(settings, 'SMS_PORTAL_API_KEY', '')
        self.sms_api_secret = getattr(settings, 'SMS_PORTAL_API_SECRET', '')
        self.sms_sender_id = getattr(settings, 'SMS_PORTAL_SENDER_ID', 'BIDR')
        
        # Notification service URL (if available)
        self.notification_service_url = getattr(
            settings, 
            'NOTIFICATION_SERVICE_URL', 
            'https://notifications.bidr.co.za'
        )
    
    def send_otp_email(self, email: str, otp_code: str, user_name: str = '') -> bool:
        """Send OTP via email"""
        try:
            subject = 'Verify Your Account - BIDR'
            message = f"""
Hello {user_name or 'User'},

Your verification code is: {otp_code}

This code will expire in 5 minutes. Please use it to complete your verification.

If you didn't request this code, please ignore this email.

Best regards,
BIDR Team
            """.strip()
            
            send_mail(
                subject=subject,
                message=message,
                from_email=getattr(settings, 'DEFAULT_FROM_EMAIL', 'noreply@bidr.com'),
                recipient_list=[email],
                fail_silently=False,
            )
            
            logger.info(f"OTP email sent successfully to {email}")
            return True
            
        except Exception as e:
            logger.error(f"Failed to send OTP email to {email}: {str(e)}")
            return False
    
    def send_otp_sms(self, phone_number: str, otp_code: str) -> bool:
        """Send OTP via SMS using SMS Portal API"""
        if not self.sms_api_key or not self.sms_api_secret:
            logger.warning("SMS Portal credentials not configured")
            return False
        
        try:
            message = f"Your BIDR verification code is: {otp_code}. Valid for 5 minutes."
            
            # SMS Portal API payload (adjust based on actual API documentation)
            headers = {
                'Content-Type': 'application/json',
                'Authorization': f'Bearer {self.sms_api_key}',
                'X-API-Secret': self.sms_api_secret
            }
            
            payload = {
                'messages': [{
                    'content': message,
                    'destination': phone_number,
                    'source': self.sms_sender_id
                }]
            }
            
            response = requests.post(
                f"{self.sms_api_url}/messages",
                headers=headers,
                json=payload,
                timeout=30
            )
            
            if response.status_code == 200:
                response_data = response.json()
                logger.info(f"OTP SMS sent successfully to {phone_number}")
                return True
            else:
                logger.error(f"Failed to send OTP SMS to {phone_number}: HTTP {response.status_code}")
                return False
                
        except Exception as e:
            logger.error(f"Error sending OTP SMS to {phone_number}: {str(e)}")
            return False
    
    def send_otp_via_notification_service(
        self, 
        user_id: str, 
        otp_code: str, 
        email: str = None, 
        phone: str = None,
        channels: list = None
    ) -> Tuple[bool, Dict]:
        """Send OTP via the notifications service (if available)"""
        if not channels:
            channels = []
            if email:
                channels.append('email')
            if phone:
                channels.append('sms')
        
        if not channels:
            return False, {'error': 'No delivery channels specified'}
        
        results = {'email': {'success': False}, 'sms': {'success': False}}
        overall_success = False
        
        try:
            # Send SMS via notification service if phone is provided
            if phone:
                sms_payload = {
                    'phone_number': phone,
                    'otp_code': otp_code,
                    'template_name': 'otp_verification'
                }
                
                sms_response = requests.post(
                    f"{self.notification_service_url}/api/v1/sms/send/otp/",
                    json=sms_payload,
                    timeout=30
                )
                
                if sms_response.status_code == 200:
                    results['sms']['success'] = True
                    overall_success = True
                    logger.info(f"OTP SMS sent via notification service to {phone}")
                else:
                    logger.error(f"SMS notification service failed: HTTP {sms_response.status_code}")
                    logger.error(f"SMS response: {sms_response.text}")
            
            # Send email via notification service if email is provided
            # For now, we'll fall back to direct email since we don't have email service implemented
            if email:
                email_success = self.send_otp_email(email, otp_code, '')
                results['email']['success'] = email_success
                if email_success:
                    overall_success = True
                    
            return overall_success, results
                
        except Exception as e:
            logger.error(f"Error calling notification service: {str(e)}")
            return False, {'error': str(e)}
    
    def send_otp_multi_channel(
        self, 
        user_id: str,
        otp_code: str, 
        email: str = None, 
        phone: str = None,
        user_name: str = '',
        prefer_notification_service: bool = True
    ) -> Dict:
        """
        Send OTP via multiple channels with fallback
        
        Returns:
            Dict with delivery results for each channel
        """
        results = {
            'email': {'attempted': False, 'success': False, 'method': None},
            'sms': {'attempted': False, 'success': False, 'method': None},
            'overall_success': False
        }
        
        # Try notification service first if available and preferred
        if prefer_notification_service and (email or phone):
            try:
                success, response = self.send_otp_via_notification_service(
                    user_id=user_id,
                    otp_code=otp_code,
                    email=email,
                    phone=phone
                )
                
                if success:
                    if email and response.get('email', {}).get('success'):
                        results['email'] = {'attempted': True, 'success': True, 'method': 'notification_service'}
                    if phone and response.get('sms', {}).get('success'):
                        results['sms'] = {'attempted': True, 'success': True, 'method': 'notification_service'}
                    
                    results['overall_success'] = any(
                        results[channel]['success'] for channel in ['email', 'sms']
                    )
                    
                    if results['overall_success']:
                        return results
                    
            except Exception as e:
                logger.warning(f"Notification service failed, falling back to direct methods: {str(e)}")
        
        # Fallback to direct methods
        if email:
            results['email']['attempted'] = True
            email_success = self.send_otp_email(email, otp_code, user_name)
            results['email']['success'] = email_success
            results['email']['method'] = 'direct_email'
        
        if phone:
            results['sms']['attempted'] = True
            sms_success = self.send_otp_sms(phone, otp_code)
            results['sms']['success'] = sms_success
            results['sms']['method'] = 'direct_sms'
        
        # Overall success if any channel succeeded
        results['overall_success'] = any(
            results[channel]['success'] for channel in ['email', 'sms']
        )
        
        return results