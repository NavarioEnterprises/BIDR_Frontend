from rest_framework import viewsets, status
from rest_framework.decorators import api_view, action
from rest_framework.response import Response
from django.conf import settings
from django.http import HttpResponse
from .models import Payment, PaymentWebhook, RefundRequest
from core.models import PaymentGateway
from .serializers import (
    PaymentSerializer, PaymentInitiationSerializer,
    PaymentWebhookSerializer, RefundRequestSerializer
)
import uuid
import requests
import json
import hashlib
import hmac
from decimal import Decimal
from django.views.decorators.csrf import csrf_exempt
from django.utils.decorators import method_decorator
from django.utils import timezone


class PaymentViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing payments
    """
    queryset = Payment.objects.all().order_by('-created_at')
    serializer_class = PaymentSerializer
    
    def get_queryset(self):
        queryset = Payment.objects.all().order_by('-created_at')
        user_id = self.request.query_params.get('user_id')
        status_filter = self.request.query_params.get('status')
        
        if user_id:
            queryset = queryset.filter(user_id=user_id)
        if status_filter:
            queryset = queryset.filter(status=status_filter)
        
        return queryset
    
    @action(detail=False, methods=['post'])
    def initiate(self, request):
        """
        Initiate a new payment
        """
        serializer = PaymentInitiationSerializer(data=request.data)
        if serializer.is_valid():
            # Get Paystack gateway
            try:
                paystack_gateway = PaymentGateway.objects.get(
                    slug='paystack', is_active=True
                )
            except PaymentGateway.DoesNotExist:
                return Response({
                    'error': 'Paystack gateway not available'
                }, status=status.HTTP_400_BAD_REQUEST)
            
            # Create payment record
            payment = Payment.objects.create(
                user_id=serializer.validated_data['user_id'],
                payment_gateway=paystack_gateway,
                reference=str(uuid.uuid4()),
                amount=serializer.validated_data['amount'],
                currency=serializer.validated_data.get('currency', 'NGN'),
                payment_method=serializer.validated_data.get('payment_method', 'card'),
                metadata=serializer.validated_data.get('metadata', {})
            )
            
            # Initialize payment with Paystack
            try:
                paystack_response = self._initialize_paystack_payment(payment)
                
                payment.gateway_response = paystack_response
                payment.save()
                
                return Response({
                    'payment_id': payment.id,
                    'reference': payment.reference,
                    'authorization_url': paystack_response.get('data', {}).get('authorization_url'),
                    'access_code': paystack_response.get('data', {}).get('access_code')
                }, status=status.HTTP_201_CREATED)
                
            except Exception as e:
                payment.status = 'failed'
                payment.save()
                return Response({
                    'error': f'Payment initialization failed: {str(e)}'
                }, status=status.HTTP_400_BAD_REQUEST)
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
    @action(detail=True, methods=['post'])
    def verify(self, request, pk=None):
        """
        Verify payment status
        """
        payment = self.get_object()
        
        try:
            verification_response = self._verify_paystack_payment(payment.reference)
            
            # Update payment status based on verification
            if verification_response.get('data', {}).get('status') == 'success':
                payment.status = 'completed'
            elif verification_response.get('data', {}).get('status') == 'failed':
                payment.status = 'failed'
            
            payment.gateway_response = verification_response
            payment.save()
            
            serializer = PaymentSerializer(payment)
            return Response(serializer.data)
            
        except Exception as e:
            return Response({
                'error': f'Payment verification failed: {str(e)}'
            }, status=status.HTTP_400_BAD_REQUEST)
    
    def _initialize_paystack_payment(self, payment):
        """
        Initialize payment with Paystack
        """
        url = 'https://api.paystack.co/transaction/initialize'
        
        headers = {
            'Authorization': f'Bearer {settings.PAYSTACK_SECRET_KEY}',
            'Content-Type': 'application/json'
        }
        
        data = {
            'reference': payment.reference,
            'amount': int(payment.amount * 100),  # Convert to kobo
            'currency': payment.currency,
            'callback_url': settings.PAYSTACK_CALLBACK_URL,
            'metadata': payment.metadata
        }
        
        response = requests.post(url, headers=headers, json=data)
        return response.json()
    
    def _verify_paystack_payment(self, reference):
        """
        Verify payment with Paystack
        """
        url = f'https://api.paystack.co/transaction/verify/{reference}'
        
        headers = {
            'Authorization': f'Bearer {settings.PAYSTACK_SECRET_KEY}',
            'Content-Type': 'application/json'
        }
        
        response = requests.get(url, headers=headers)
        return response.json()


class RefundRequestViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing refund requests
    """
    queryset = RefundRequest.objects.all().order_by('-created_at')
    serializer_class = RefundRequestSerializer
    
    def get_queryset(self):
        queryset = RefundRequest.objects.all().order_by('-created_at')
        payment_id = self.request.query_params.get('payment_id')
        status_filter = self.request.query_params.get('status')
        
        if payment_id:
            queryset = queryset.filter(payment_id=payment_id)
        if status_filter:
            queryset = queryset.filter(status=status_filter)
        
        return queryset
    
    @action(detail=True, methods=['post'])
    def process(self, request, pk=None):
        """
        Process a refund request
        """
        refund_request = self.get_object()
        
        if refund_request.status != 'pending':
            return Response({
                'error': 'Refund request already processed'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        try:
            # Process refund with Paystack
            refund_response = self._process_paystack_refund(refund_request)
            
            refund_request.status = 'approved'
            refund_request.gateway_response = refund_response
            refund_request.processed_at = timezone.now()
            refund_request.save()
            
            serializer = RefundRequestSerializer(refund_request)
            return Response(serializer.data)
            
        except Exception as e:
            refund_request.status = 'rejected'
            refund_request.save()
            return Response({
                'error': f'Refund processing failed: {str(e)}'
            }, status=status.HTTP_400_BAD_REQUEST)
    
    def _process_paystack_refund(self, refund_request):
        """
        Process refund with Paystack
        """
        url = 'https://api.paystack.co/refund'
        
        headers = {
            'Authorization': f'Bearer {settings.PAYSTACK_SECRET_KEY}',
            'Content-Type': 'application/json'
        }
        
        data = {
            'transaction': refund_request.payment.reference,
            'amount': int(refund_request.amount * 100),  # Convert to kobo
        }
        
        response = requests.post(url, headers=headers, json=data)
        return response.json()


@csrf_exempt
@api_view(['POST'])
def paystack_webhook(request):
    """
    Handle Paystack webhook notifications_service
    """
    # Verify webhook signature
    signature = request.META.get('HTTP_X_PAYSTACK_SIGNATURE')
    
    if not signature:
        return HttpResponse('Missing signature', status=400)
    
    # Verify signature
    expected_signature = hmac.new(
        settings.PAYSTACK_SECRET_KEY.encode('utf-8'),
        request.body,
        hashlib.sha512
    ).hexdigest()
    
    if not hmac.compare_digest(signature, expected_signature):
        return HttpResponse('Invalid signature', status=400)
    
    # Process webhook
    try:
        payload = json.loads(request.body)
        event_type = payload.get('event')
        
        if event_type == 'charge.success':
            reference = payload.get('data', {}).get('reference')
            
            try:
                payment = Payment.objects.get(reference=reference)
                payment.status = 'completed'
                payment.gateway_response = payload
                payment.save()
                
                # Create webhook record
                PaymentWebhook.objects.create(
                    payment=payment,
                    event_type=event_type,
                    payload=payload,
                    processed=True
                )
                
            except Payment.DoesNotExist:
                # Create webhook record for unknown payment
                PaymentWebhook.objects.create(
                    event_type=event_type,
                    payload=payload,
                    processed=False
                )
        
        return HttpResponse('OK', status=200)
        
    except Exception as e:
        return HttpResponse(f'Error: {str(e)}', status=400)
