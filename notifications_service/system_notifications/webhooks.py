import json
import logging
from typing import Dict, Any
from django.http import HttpResponse, JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.views.decorators.http import require_http_methods
from django.utils.decorators import method_decorator
from django.views import View
from .models import Notification, NotificationTemplate

logger = logging.getLogger(__name__)


@csrf_exempt
@require_http_methods(["POST"])
def payment_webhook(request):
    """Webhook endpoint for payment service notifications"""
    try:
        payload = json.loads(request.body)
        event_type = payload.get('event_type')
        data = payload.get('data', {})
        
        if event_type == 'payment.success':
            return handle_payment_success(data)
        elif event_type == 'payment.failed':
            return handle_payment_failed(data)
        elif event_type == 'refund.processed':
            return handle_refund_processed(data)
        elif event_type == 'escrow.released':
            return handle_escrow_released(data)
        else:
            logger.warning(f"Unhandled payment webhook event: {event_type}")
            return JsonResponse({'status': 'ignored', 'message': f'Unhandled event: {event_type}'})
    
    except Exception as e:
        logger.error(f"Payment webhook error: {e}")
        return JsonResponse({'status': 'error', 'message': str(e)}, status=400)


@csrf_exempt
@require_http_methods(["POST"])
def resolution_webhook(request):
    """Webhook endpoint for resolution service notifications"""
    try:
        payload = json.loads(request.body)
        event_type = payload.get('event_type')
        data = payload.get('data', {})
        
        if event_type == 'review.created':
            return handle_review_created(data)
        elif event_type == 'dispute.created':
            return handle_dispute_created(data)
        elif event_type == 'dispute.resolved':
            return handle_dispute_resolved(data)
        elif event_type == 'return.requested':
            return handle_return_requested(data)
        elif event_type == 'return.approved':
            return handle_return_approved(data)
        elif event_type == 'return.completed':
            return handle_return_completed(data)
        else:
            logger.warning(f"Unhandled resolution webhook event: {event_type}")
            return JsonResponse({'status': 'ignored', 'message': f'Unhandled event: {event_type}'})
    
    except Exception as e:
        logger.error(f"Resolution webhook error: {e}")
        return JsonResponse({'status': 'error', 'message': str(e)}, status=400)


def handle_payment_success(data: Dict[Any, Any]) -> JsonResponse:
    """Handle payment success webhook"""
    try:
        notification = Notification.objects.create(
            recipient_id=data.get('user_id'),
            notification_type='payment_success',
            subject='Payment Successful',
            message=f'Your payment of {data.get("currency", "NGN")} {data.get("amount")} has been processed successfully.',
            data=data,
            priority='high',
            source_service='payment_service'
        )
        
        logger.info(f"Created payment success notification: {notification.id}")
        return JsonResponse({'status': 'success', 'notification_id': str(notification.id)})
    
    except Exception as e:
        logger.error(f"Error handling payment success: {e}")
        return JsonResponse({'status': 'error', 'message': str(e)}, status=500)


def handle_payment_failed(data: Dict[Any, Any]) -> JsonResponse:
    """Handle payment failed webhook"""
    try:
        notification = Notification.objects.create(
            recipient_id=data.get('user_id'),
            notification_type='payment_failed',
            subject='Payment Failed',
            message=f'Your payment of {data.get("currency", "NGN")} {data.get("amount")} could not be processed.',
            data=data,
            priority='high',
            source_service='payment_service'
        )
        
        logger.info(f"Created payment failed notification: {notification.id}")
        return JsonResponse({'status': 'success', 'notification_id': str(notification.id)})
    
    except Exception as e:
        logger.error(f"Error handling payment failed: {e}")
        return JsonResponse({'status': 'error', 'message': str(e)}, status=500)


def handle_refund_processed(data: Dict[Any, Any]) -> JsonResponse:
    """Handle refund processed webhook"""
    try:
        notification = Notification.objects.create(
            recipient_id=data.get('user_id'),
            notification_type='refund_processed',
            subject='Refund Processed',
            message=f'Your refund of {data.get("currency", "NGN")} {data.get("amount")} has been processed.',
            data=data,
            priority='high',
            source_service='payment_service'
        )
        
        logger.info(f"Created refund processed notification: {notification.id}")
        return JsonResponse({'status': 'success', 'notification_id': str(notification.id)})
    
    except Exception as e:
        logger.error(f"Error handling refund processed: {e}")
        return JsonResponse({'status': 'error', 'message': str(e)}, status=500)


def handle_escrow_released(data: Dict[Any, Any]) -> JsonResponse:
    """Handle escrow released webhook"""
    try:
        notification = Notification.objects.create(
            recipient_id=data.get('seller_id'),
            notification_type='escrow_released',
            subject='Escrow Released',
            message=f'Escrow funds for transaction #{data.get("transaction_id")} have been released.',
            data=data,
            priority='high',
            source_service='payment_service'
        )
        
        logger.info(f"Created escrow released notification: {notification.id}")
        return JsonResponse({'status': 'success', 'notification_id': str(notification.id)})
    
    except Exception as e:
        logger.error(f"Error handling escrow released: {e}")
        return JsonResponse({'status': 'error', 'message': str(e)}, status=500)


def handle_review_created(data: Dict[Any, Any]) -> JsonResponse:
    """Handle review created webhook"""
    try:
        notification = Notification.objects.create(
            recipient_id=data.get('seller_id'),
            notification_type='review_created',
            subject='New Review Received',
            message=f'You have received a new review for transaction #{data.get("transaction_id")}.',
            data=data,
            priority='medium',
            source_service='resolution_service'
        )
        
        logger.info(f"Created review created notification: {notification.id}")
        return JsonResponse({'status': 'success', 'notification_id': str(notification.id)})
    
    except Exception as e:
        logger.error(f"Error handling review created: {e}")
        return JsonResponse({'status': 'error', 'message': str(e)}, status=500)


def handle_dispute_resolved(data: Dict[Any, Any]) -> JsonResponse:
    """Handle dispute resolved webhook"""
    try:
        # Notify both buyer and seller
        buyer_notification = Notification.objects.create(
            recipient_id=data.get('buyer_id'),
            notification_type='dispute_resolved',
            subject='Dispute Resolved',
            message=f'Your dispute for transaction #{data.get("transaction_id")} has been resolved.',
            data=data,
            priority='high',
            source_service='resolution_service'
        )
        
        seller_notification = Notification.objects.create(
            recipient_id=data.get('seller_id'),
            notification_type='dispute_resolved',
            subject='Dispute Resolved',
            message=f'The dispute for transaction #{data.get("transaction_id")} has been resolved.',
            data=data,
            priority='high',
            source_service='resolution_service'
        )
        
        logger.info(f"Created dispute resolved notifications: {buyer_notification.id}, {seller_notification.id}")
        return JsonResponse({'status': 'success', 'notification_ids': [str(buyer_notification.id), str(seller_notification.id)]})
    
    except Exception as e:
        logger.error(f"Error handling dispute resolved: {e}")
        return JsonResponse({'status': 'error', 'message': str(e)}, status=500)


def handle_return_requested(data: Dict[Any, Any]) -> JsonResponse:
    """Handle return requested webhook"""
    try:
        notification = Notification.objects.create(
            recipient_id=data.get('seller_id'),
            notification_type='return_requested',
            subject='Return Requested',
            message=f'A return has been requested for transaction #{data.get("transaction_id")}.',
            data=data,
            priority='high',
            source_service='resolution_service'
        )
        
        logger.info(f"Created return requested notification: {notification.id}")
        return JsonResponse({'status': 'success', 'notification_id': str(notification.id)})
    
    except Exception as e:
        logger.error(f"Error handling return requested: {e}")
        return JsonResponse({'status': 'error', 'message': str(e)}, status=500)


def handle_return_approved(data: Dict[Any, Any]) -> JsonResponse:
    """Handle return approved webhook"""
    try:
        notification = Notification.objects.create(
            recipient_id=data.get('buyer_id'),
            notification_type='return_approved',
            subject='Return Approved',
            message=f'Your return request for transaction #{data.get("transaction_id")} has been approved.',
            data=data,
            priority='high',
            source_service='resolution_service'
        )
        
        logger.info(f"Created return approved notification: {notification.id}")
        return JsonResponse({'status': 'success', 'notification_id': str(notification.id)})
    
    except Exception as e:
        logger.error(f"Error handling return approved: {e}")
        return JsonResponse({'status': 'error', 'message': str(e)}, status=500)


def handle_return_completed(data: Dict[Any, Any]) -> JsonResponse:
    """Handle return completed webhook"""
    try:
        # Notify both buyer and seller
        buyer_notification = Notification.objects.create(
            recipient_id=data.get('buyer_id'),
            notification_type='return_completed',
            subject='Return Completed',
            message=f'Your return for transaction #{data.get("transaction_id")} has been completed.',
            data=data,
            priority='medium',
            source_service='resolution_service'
        )
        
        seller_notification = Notification.objects.create(
            recipient_id=data.get('seller_id'),
            notification_type='return_completed',
            subject='Return Completed',
            message=f'The return for transaction #{data.get("transaction_id")} has been completed.',
            data=data,
            priority='medium',
            source_service='resolution_service'
        )
        
        logger.info(f"Created return completed notifications: {buyer_notification.id}, {seller_notification.id}")
        return JsonResponse({'status': 'success', 'notification_ids': [str(buyer_notification.id), str(seller_notification.id)]})
    
    except Exception as e:
        logger.error(f"Error handling return completed: {e}")
        return JsonResponse({'status': 'error', 'message': str(e)}, status=500)


def handle_dispute_created(data: Dict[Any, Any]) -> JsonResponse:
    """Handle dispute created webhook"""
    try:
        # Notify both buyer and seller
        buyer_notification = Notification.objects.create(
            recipient_id=data.get('buyer_id'),
            notification_type='dispute_created',
            subject='Dispute Created',
            message=f'Your dispute for transaction #{data.get("transaction_id")} has been created.',
            data=data,
            priority='high',
            source_service='resolution_service'
        )
        
        logger.info(f"Created dispute notifications: {buyer_notification.id}")
        return JsonResponse({'status': 'success', 'notification_id': str(buyer_notification.id)})
    
    except Exception as e:
        logger.error(f"Error handling dispute created: {e}")
        return JsonResponse({'status': 'error', 'message': str(e)}, status=500)
