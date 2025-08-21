import requests
import logging
import json
from django.conf import settings
from typing import Dict, Any, Optional, List

logger = logging.getLogger(__name__)


class NotificationClient:
    """Client for communicating with the notification service"""
    
    def __init__(self):
        self.config = settings.NOTIFICATION_SERVICE
        self.base_url = self.config['BASE_URL']
        self.api_key = self.config.get('API_KEY')
        self.timeout = self.config.get('TIMEOUT', 30)
        self.retry_attempts = self.config.get('RETRY_ATTEMPTS', 3)
        self.enabled = self.config.get('ENABLED', True)
    
    def _make_request(self, method: str, endpoint: str, data: Dict[Any, Any] = None) -> Optional[Dict]:
        """Make HTTP request to notification service"""
        if not self.enabled:
            logger.info("Notification service is disabled")
            return None
        
        url = f"{self.base_url}{endpoint}"
        headers = {
            'Content-Type': 'application/json',
            'User-Agent': 'BIDR-Payment-Service/1.0'
        }
        
        if self.api_key:
            headers['Authorization'] = f'Bearer {self.api_key}'
        
        for attempt in range(self.retry_attempts):
            try:
                response = requests.request(
                    method=method,
                    url=url,
                    headers=headers,
                    json=data,
                    timeout=self.timeout
                )
                
                if response.status_code in [200, 201]:
                    return response.json()
                elif response.status_code == 404:
                    logger.error(f"Notification service endpoint not found: {url}")
                    return None
                else:
                    logger.warning(f"Notification service returned {response.status_code}: {response.text}")
                    
            except requests.exceptions.RequestException as e:
                logger.error(f"Notification service request failed (attempt {attempt + 1}): {e}")
                if attempt == self.retry_attempts - 1:
                    logger.error("Max retry attempts reached for notification service")
        
        return None
    
    def send_notification(self, 
                         recipient_id: str,
                         notification_type: str,
                         subject: str,
                         message: str,
                         data: Dict[Any, Any] = None,
                         priority: str = 'normal',
                         channels: List[str] = None) -> bool:
        """Send a single notification"""
        payload = {
            'recipient_id': recipient_id,
            'notification_type': notification_type,
            'subject': subject,
            'message': message,
            'priority': priority,
            'source_service': 'payment_service',
            'data': data or {},
        }
        
        if channels:
            payload['channels'] = channels
        
        result = self._make_request('POST', '/api/v1/notifications/send/', payload)
        
        if result:
            logger.info(f"Notification sent successfully: {notification_type} to {recipient_id}")
            return True
        else:
            logger.error(f"Failed to send notification: {notification_type} to {recipient_id}")
            return False
    
    def send_payment_success_notification(self, user_id: str, payment_data: Dict) -> bool:
        """Send payment success notification"""
        return self.send_notification(
            recipient_id=user_id,
            notification_type='payment_success',
            subject='Payment Successful',
            message=f'Your payment of {payment_data.get("currency", "NGN")} {payment_data.get("amount")} has been processed successfully.',
            data={
                'payment_id': payment_data.get('id'),
                'amount': payment_data.get('amount'),
                'currency': payment_data.get('currency', 'NGN'),
                'reference': payment_data.get('reference'),
                'gateway': payment_data.get('gateway', 'paystack')
            },
            priority='high',
            channels=['email', 'push', 'in_app']
        )
    
    def send_payment_failed_notification(self, user_id: str, payment_data: Dict) -> bool:
        """Send payment failed notification"""
        return self.send_notification(
            recipient_id=user_id,
            notification_type='payment_failed',
            subject='Payment Failed',
            message=f'Your payment of {payment_data.get("currency", "NGN")} {payment_data.get("amount")} could not be processed. Please try again.',
            data={
                'payment_id': payment_data.get('id'),
                'amount': payment_data.get('amount'),
                'currency': payment_data.get('currency', 'NGN'),
                'reference': payment_data.get('reference'),
                'error_message': payment_data.get('error_message', 'Unknown error')
            },
            priority='high',
            channels=['email', 'push', 'in_app']
        )
    
    def send_refund_processed_notification(self, user_id: str, refund_data: Dict) -> bool:
        """Send refund processed notification"""
        return self.send_notification(
            recipient_id=user_id,
            notification_type='refund_processed',
            subject='Refund Processed',
            message=f'Your refund of {refund_data.get("currency", "NGN")} {refund_data.get("amount")} has been processed and will reflect in your account within 3-5 business days.',
            data={
                'refund_id': refund_data.get('id'),
                'payment_id': refund_data.get('payment_id'),
                'amount': refund_data.get('amount'),
                'currency': refund_data.get('currency', 'NGN'),
                'reason': refund_data.get('reason')
            },
            priority='normal',
            channels=['email', 'push', 'in_app']
        )
    
    def send_escrow_released_notification(self, user_id: str, escrow_data: Dict) -> bool:
        """Send escrow released notification"""
        return self.send_notification(
            recipient_id=user_id,
            notification_type='escrow_released',
            subject='Escrow Payment Released',
            message=f'Your escrow payment of {escrow_data.get("currency", "NGN")} {escrow_data.get("amount")} has been released.',
            data={
                'escrow_id': escrow_data.get('id'),
                'transaction_id': escrow_data.get('transaction_id'),
                'amount': escrow_data.get('amount'),
                'currency': escrow_data.get('currency', 'NGN'),
                'release_type': escrow_data.get('release_type', 'automatic')
            },
            priority='normal',
            channels=['email', 'push', 'in_app']
        )
    
    def get_user_preferences(self, user_id: str) -> Optional[Dict]:
        """Get user notification preferences"""
        result = self._make_request('GET', f'/api/v1/notifications/preferences/{user_id}/')
        return result
    
    def update_user_preferences(self, user_id: str, preferences: Dict) -> bool:
        """Update user notification preferences"""
        result = self._make_request('PUT', f'/api/v1/notifications/preferences/{user_id}/', preferences)
        return bool(result)


# Singleton instance
notification_client = NotificationClient()
