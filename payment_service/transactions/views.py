from rest_framework import viewsets, status
from rest_framework.decorators import api_view, action
from rest_framework.response import Response
from django.utils import timezone
from datetime import timedelta
from .models import Transaction, TransactionPIN, TransactionLog
from payments.models import Payment
from .serializers import (
    TransactionSerializer, TransactionCreateSerializer,
    TransactionPINSerializer, PINGenerationSerializer,
    PINVerificationSerializer, TransactionLogSerializer,
    TransactionStatusUpdateSerializer
)
import random
import string
from django.conf import settings


class TransactionViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing transactions
    """
    queryset = Transaction.objects.all().order_by('-created_at')
    serializer_class = TransactionSerializer
    
    def get_queryset(self):
        queryset = Transaction.objects.all().order_by('-created_at')
        buyer_id = self.request.query_params.get('buyer_id')
        seller_id = self.request.query_params.get('seller_id')
        status_filter = self.request.query_params.get('status')
        transaction_type = self.request.query_params.get('type')
        
        if buyer_id:
            queryset = queryset.filter(buyer_id=buyer_id)
        if seller_id:
            queryset = queryset.filter(seller_id=seller_id)
        if status_filter:
            queryset = queryset.filter(status=status_filter)
        if transaction_type:
            queryset = queryset.filter(transaction_type=transaction_type)
        
        return queryset
    
    def create(self, request):
        """
        Create a new transaction
        """
        serializer = TransactionCreateSerializer(data=request.data)
        if serializer.is_valid():
            # Create transaction
            transaction = Transaction.objects.create(
                buyer_id=serializer.validated_data['buyer_id'],
                seller_id=serializer.validated_data['seller_id'],
                amount=serializer.validated_data['amount'],
                transaction_type=serializer.validated_data.get('transaction_type', 'escrow'),
                description=serializer.validated_data.get('description', ''),
                metadata=serializer.validated_data.get('metadata', {})
            )
            
            # Log transaction creation
            self._log_transaction_action(
                transaction=transaction,
                action='created',
                user_id=serializer.validated_data['buyer_id'],
                request=request
            )
            
            response_serializer = TransactionSerializer(transaction)
            return Response(response_serializer.data, status=status.HTTP_201_CREATED)
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
    @action(detail=True, methods=['post'])
    def generate_pin(self, request, pk=None):
        """
        Generate a PIN for transaction verification
        """
        transaction = self.get_object()
        
        if transaction.status != 'pending':
            return Response({
                'error': 'PIN can only be generated for pending transactions'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Check if there's already an active PIN
        existing_pin = TransactionPIN.objects.filter(
            transaction=transaction,
            is_used=False,
            expires_at__gt=timezone.now()
        ).first()
        
        if existing_pin:
            return Response({
                'error': 'Active PIN already exists for this transaction'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Generate new PIN
        pin_code = self._generate_pin_code()
        expires_at = timezone.now() + timedelta(minutes=settings.PIN_EXPIRY_MINUTES)
        
        transaction_pin = TransactionPIN.objects.create(
            transaction=transaction,
            pin_code=pin_code,
            expires_at=expires_at
        )
        
        # Log PIN generation
        self._log_transaction_action(
            transaction=transaction,
            action='pin_generated',
            request=request
        )
        
        # In a real implementation, you would send the PIN via SMS/email
        # For now, we'll return it in the response (NOT recommended for production)
        return Response({
            'message': 'PIN generated successfully',
            'pin_id': transaction_pin.id,
            'expires_at': transaction_pin.expires_at,
            'pin_code': pin_code  # Remove this in production
        }, status=status.HTTP_201_CREATED)
    
    @action(detail=True, methods=['post'])
    def verify_pin(self, request, pk=None):
        """
        Verify PIN for transaction completion
        """
        transaction = self.get_object()
        serializer = PINVerificationSerializer(data=request.data)
        
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        
        pin_code = serializer.validated_data['pin_code']
        
        try:
            transaction_pin = TransactionPIN.objects.get(
                transaction=transaction,
                is_used=False
            )
        except TransactionPIN.DoesNotExist:
            return Response({
                'error': 'No active PIN found for this transaction'
            }, status=status.HTTP_404_NOT_FOUND)
        
        # Check if PIN is expired
        if transaction_pin.expires_at < timezone.now():
            return Response({
                'error': 'PIN has expired'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Check if max attempts exceeded
        if transaction_pin.attempts >= settings.MAX_PIN_ATTEMPTS:
            transaction_pin.is_used = True  # Lock the PIN
            transaction_pin.save()
            return Response({
                'error': 'Maximum PIN attempts exceeded'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Verify PIN
        transaction_pin.attempts += 1
        
        if transaction_pin.pin_code == pin_code:
            # PIN is correct
            transaction_pin.is_used = True
            transaction_pin.save()
            
            # Update transaction status
            transaction.status = 'completed'
            transaction.save()
            
            # Log successful verification
            self._log_transaction_action(
                transaction=transaction,
                action='pin_verified',
                status='success',
                request=request
            )
            
            return Response({
                'message': 'PIN verified successfully',
                'transaction_status': 'completed'
            }, status=status.HTTP_200_OK)
        else:
            # PIN is incorrect
            transaction_pin.save()
            
            # Log failed verification
            self._log_transaction_action(
                transaction=transaction,
                action='pin_verification_failed',
                status='failed',
                details=f'Attempt {transaction_pin.attempts}/{settings.MAX_PIN_ATTEMPTS}',
                request=request
            )
            
            remaining_attempts = settings.MAX_PIN_ATTEMPTS - transaction_pin.attempts
            
            return Response({
                'error': 'Invalid PIN',
                'remaining_attempts': remaining_attempts
            }, status=status.HTTP_400_BAD_REQUEST)
    
    @action(detail=True, methods=['post'])
    def update_status(self, request, pk=None):
        """
        Update transaction status
        """
        transaction = self.get_object()
        serializer = TransactionStatusUpdateSerializer(data=request.data)
        
        if serializer.is_valid():
            old_status = transaction.status
            new_status = serializer.validated_data['status']
            reason = serializer.validated_data.get('reason', '')
            
            transaction.status = new_status
            transaction.save()
            
            # Log status update
            self._log_transaction_action(
                transaction=transaction,
                action='status_updated',
                details=f'Status changed from {old_status} to {new_status}. Reason: {reason}',
                request=request
            )
            
            response_serializer = TransactionSerializer(transaction)
            return Response(response_serializer.data)
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
    @action(detail=True, methods=['get'])
    def logs(self, request, pk=None):
        """
        Get transaction logs
        """
        transaction = self.get_object()
        logs = TransactionLog.objects.filter(transaction=transaction).order_by('-created_at')
        
        serializer = TransactionLogSerializer(logs, many=True)
        return Response(serializer.data)
    
    def _generate_pin_code(self):
        """
        Generate a random PIN code
        """
        return ''.join(random.choices(string.digits, k=settings.PIN_LENGTH))
    
    def _log_transaction_action(self, transaction, action, status='success', details='', user_id=None, request=None):
        """
        Log transaction action
        """
        ip_address = None
        if request:
            x_forwarded_for = request.META.get('HTTP_X_FORWARDED_FOR')
            if x_forwarded_for:
                ip_address = x_forwarded_for.split(',')[0]
            else:
                ip_address = request.META.get('REMOTE_ADDR')
        
        TransactionLog.objects.create(
            transaction=transaction,
            action=action,
            status=status,
            details=details,
            user_id=user_id,
            ip_address=ip_address
        )


class TransactionLogViewSet(viewsets.ReadOnlyModelViewSet):
    """
    ViewSet for viewing transaction logs
    """
    queryset = TransactionLog.objects.all().order_by('-created_at')
    serializer_class = TransactionLogSerializer
    
    def get_queryset(self):
        queryset = TransactionLog.objects.all().order_by('-created_at')
        transaction_id = self.request.query_params.get('transaction_id')
        user_id = self.request.query_params.get('user_id')
        action = self.request.query_params.get('action')
        
        if transaction_id:
            queryset = queryset.filter(transaction_id=transaction_id)
        if user_id:
            queryset = queryset.filter(user_id=user_id)
        if action:
            queryset = queryset.filter(action=action)
        
        return queryset
