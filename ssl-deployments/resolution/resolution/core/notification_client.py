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
            'User-Agent': 'BIDR-Resolution-Service/1.0'
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
            'source_service': 'resolution_service',
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
    
    def send_review_received_notification(self, user_id: str, review_data: Dict) -> bool:
        """Send review received notification"""
        return self.send_notification(
            recipient_id=user_id,
            notification_type='review_received',
            subject='New Review Received',
            message=f'You have received a new {review_data.get("rating", "N/A")}-star review.',
            data={
                'review_id': review_data.get('id'),
                'rating': review_data.get('rating'),
                'product_id': review_data.get('product_id'),
                'reviewer_name': review_data.get('reviewer_name', 'Anonymous')
            },
            priority='normal',
            channels=['email', 'push', 'in_app']
        )
    
    def send_dispute_created_notification(self, user_id: str, dispute_data: Dict) -> bool:
        """Send dispute created notification"""
        return self.send_notification(
            recipient_id=user_id,
            notification_type='dispute_created',
            subject='New Dispute Created',
            message=f'A dispute has been created for transaction #{dispute_data.get("transaction_id", "N/A")}.',
            data={
                'dispute_id': dispute_data.get('id'),
                'transaction_id': dispute_data.get('transaction_id'),
                'dispute_type': dispute_data.get('dispute_type'),
                'amount': dispute_data.get('amount'),
                'currency': dispute_data.get('currency', 'NGN')
            },
            priority='high',
            channels=['email', 'push', 'in_app']
        )
    
    def send_dispute_resolved_notification(self, user_id: str, dispute_data: Dict) -> bool:
        """Send dispute resolved notification"""
        return self.send_notification(
            recipient_id=user_id,
            notification_type='dispute_resolved',
            subject='Dispute Resolved',
            message=f'Your dispute for transaction #{dispute_data.get("transaction_id", "N/A")} has been resolved.',
            data={
                'dispute_id': dispute_data.get('id'),
                'transaction_id': dispute_data.get('transaction_id'),
                'resolution': dispute_data.get('resolution'),
                'resolved_by': dispute_data.get('resolved_by', 'System'),
                'resolution_date': dispute_data.get('resolution_date')
            },
            priority='high',
            channels=['email', 'push', 'in_app']
        )
    
    def send_return_request_received_notification(self, user_id: str, return_data: Dict) -> bool:
        """Send return request received notification"""
        return self.send_notification(
            recipient_id=user_id,
            notification_type='return_request_received',
            subject='Return Request Received',
            message=f'A return request has been submitted for your product.',
            data={
                'return_id': return_data.get('id'),
                'product_id': return_data.get('product_id'),
                'reason': return_data.get('reason'),
                'requested_by': return_data.get('requested_by'),
                'request_date': return_data.get('request_date')
            },
            priority='normal',
            channels=['email', 'push', 'in_app']
        )
    
    def send_return_approved_notification(self, user_id: str, return_data: Dict) -> bool:
        """Send return approved notification"""
        return self.send_notification(
            recipient_id=user_id,
            notification_type='return_approved',
            subject='Return Request Approved',
            message=f'Your return request has been approved. Please ship the item back.',
            data={
                'return_id': return_data.get('id'),
                'product_id': return_data.get('product_id'),
                'shipping_address': return_data.get('shipping_address'),
                'return_deadline': return_data.get('return_deadline')
            },
            priority='normal',
            channels=['email', 'push', 'in_app']
        )
    
    def send_return_completed_notification(self, user_id: str, return_data: Dict) -> bool:
        """Send return completed notification"""
        return self.send_notification(
            recipient_id=user_id,
            notification_type='return_completed',
            subject='Return Process Completed',
            message=f'Your return has been processed and refund has been initiated.',
            data={
                'return_id': return_data.get('id'),
                'product_id': return_data.get('product_id'),
                'refund_amount': return_data.get('refund_amount'),
                'currency': return_data.get('currency', 'NGN'),
                'completion_date': return_data.get('completion_date')
            },
            priority='normal',
            channels=['email', 'push', 'in_app']
        )
    
    def send_mediation_scheduled_notification(self, user_id: str, mediation_data: Dict) -> bool:
        """Send mediation scheduled notification"""
        return self.send_notification(
            recipient_id=user_id,
            notification_type='mediation_scheduled',
            subject='Mediation Session Scheduled',
            message=f'A mediation session has been scheduled for your dispute.',
            data={
                'dispute_id': mediation_data.get('dispute_id'),
                'scheduled_date': mediation_data.get('scheduled_date'),
                'mediator': mediation_data.get('mediator'),
                'meeting_link': mediation_data.get('meeting_link')
            },
            priority='high',
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
