from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from django.utils import timezone
from datetime import timedelta, date
from .models import EscrowAccount
from transactions.models import Transaction
from .serializers import (
    EscrowAccountSerializer, EscrowCreateSerializer,
    EscrowReleaseSerializer, EscrowStatusUpdateSerializer
)
from django.conf import settings


class EscrowAccountViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing escrow accounts
    """
    queryset = EscrowAccount.objects.all().order_by('-created_at')
    serializer_class = EscrowAccountSerializer
    
    def get_queryset(self):
        queryset = EscrowAccount.objects.all().order_by('-created_at')
        transaction_id = self.request.query_params.get('transaction_id')
        status_filter = self.request.query_params.get('status')
        category = self.request.query_params.get('category')
        buyer_id = self.request.query_params.get('buyer_id')
        seller_id = self.request.query_params.get('seller_id')
        
        if transaction_id:
            queryset = queryset.filter(transaction_id=transaction_id)
        if status_filter:
            queryset = queryset.filter(status=status_filter)
        if category:
            queryset = queryset.filter(category=category)
        if buyer_id:
            queryset = queryset.filter(transaction__buyer_id=buyer_id)
        if seller_id:
            queryset = queryset.filter(transaction__seller_id=seller_id)
        
        return queryset
    
    def create(self, request):
        """
        Create a new escrow account
        """
        serializer = EscrowCreateSerializer(data=request.data)
        if serializer.is_valid():
            transaction = Transaction.objects.get(id=serializer.validated_data['transaction_id'])
            
            # Calculate escrow period
            category = serializer.validated_data.get('category', 'default')
            custom_period = serializer.validated_data.get('custom_period_days')
            
            if custom_period:
                period_days = custom_period
            else:
                period_days = settings.ESCROW_PERIODS.get(category, settings.ESCROW_PERIODS['default'])
            
            # Create escrow account
            escrow_account = EscrowAccount.objects.create(
                transaction=transaction,
                amount=serializer.validated_data['amount'],
                category=category,
                start_date=timezone.now().date(),
                end_date=timezone.now().date() + timedelta(days=period_days)
            )
            
            response_serializer = EscrowAccountSerializer(escrow_account)
            return Response(response_serializer.data, status=status.HTTP_201_CREATED)
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
    @action(detail=True, methods=['post'])
    def request_early_release(self, request, pk=None):
        """
        Request early release of escrow funds
        """
        escrow_account = self.get_object()
        
        if escrow_account.status != 'active':
            return Response({
                'error': 'Early release can only be requested for active escrow accounts'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        if escrow_account.early_release_requested:
            return Response({
                'error': 'Early release has already been requested'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        serializer = EscrowReleaseSerializer(data=request.data)
        if serializer.is_valid():
            escrow_account.early_release_requested = True
            escrow_account.save()
            
            return Response({
                'message': 'Early release requested successfully',
                'status': 'pending_approval'
            }, status=status.HTTP_200_OK)
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
    @action(detail=True, methods=['post'])
    def approve_early_release(self, request, pk=None):
        """
        Approve early release request (admin only)
        """
        escrow_account = self.get_object()
        
        if not escrow_account.early_release_requested:
            return Response({
                'error': 'No early release request found'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        if escrow_account.early_release_approved:
            return Response({
                'error': 'Early release has already been approved'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        escrow_account.early_release_approved = True
        escrow_account.status = 'released'
        escrow_account.save()
        
        # Update associated transaction
        transaction = escrow_account.transaction
        transaction.status = 'completed'
        transaction.save()
        
        return Response({
            'message': 'Early release approved successfully',
            'escrow_status': 'released',
            'transaction_status': 'completed'
        }, status=status.HTTP_200_OK)
    
    @action(detail=True, methods=['post'])
    def release_funds(self, request, pk=None):
        """
        Release escrow funds (automatic or manual)
        """
        escrow_account = self.get_object()
        
        if escrow_account.status != 'active':
            return Response({
                'error': 'Funds can only be released from active escrow accounts'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Check if escrow period has ended or early release is approved
        current_date = timezone.now().date()
        can_release = (
            current_date >= escrow_account.end_date or
            (escrow_account.early_release_requested and escrow_account.early_release_approved)
        )
        
        if not can_release:
            return Response({
                'error': f'Cannot release funds. Escrow period ends on {escrow_account.end_date}',
                'days_remaining': (escrow_account.end_date - current_date).days
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Release funds
        escrow_account.status = 'released'
        escrow_account.save()
        
        # Update associated transaction
        transaction = escrow_account.transaction
        transaction.status = 'completed'
        transaction.save()
        
        return Response({
            'message': 'Funds released successfully',
            'release_amount': escrow_account.amount,
            'release_date': current_date,
            'transaction_status': 'completed'
        }, status=status.HTTP_200_OK)
    
    @action(detail=True, methods=['post'])
    def dispute(self, request, pk=None):
        """
        Mark escrow account as disputed
        """
        escrow_account = self.get_object()
        
        if escrow_account.status not in ['active']:
            return Response({
                'error': 'Can only dispute active escrow accounts'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        reason = request.data.get('reason', '')
        
        escrow_account.status = 'disputed'
        escrow_account.save()
        
        # Update associated transaction
        transaction = escrow_account.transaction
        transaction.status = 'disputed'
        transaction.save()
        
        return Response({
            'message': 'Escrow marked as disputed',
            'status': 'disputed',
            'reason': reason
        }, status=status.HTTP_200_OK)
    
    @action(detail=True, methods=['post'])
    def refund(self, request, pk=None):
        """
        Process refund for escrow account
        """
        escrow_account = self.get_object()
        
        if escrow_account.status == 'refunded':
            return Response({
                'error': 'Escrow has already been refunded'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        reason = request.data.get('reason', '')
        
        escrow_account.status = 'refunded'
        escrow_account.save()
        
        # Update associated transaction
        transaction = escrow_account.transaction
        transaction.status = 'refunded'
        transaction.save()
        
        return Response({
            'message': 'Refund processed successfully',
            'refund_amount': escrow_account.amount,
            'reason': reason
        }, status=status.HTTP_200_OK)
    
    @action(detail=False, methods=['get'])
    def expired(self, request):
        """
        Get expired escrow accounts
        """
        current_date = timezone.now().date()
        expired_accounts = EscrowAccount.objects.filter(
            end_date__lt=current_date,
            status='active'
        ).order_by('-end_date')
        
        serializer = EscrowAccountSerializer(expired_accounts, many=True)
        return Response({
            'count': expired_accounts.count(),
            'results': serializer.data
        })
    
    @action(detail=False, methods=['get'])
    def expiring_soon(self, request):
        """
        Get escrow accounts expiring within next 3 days
        """
        current_date = timezone.now().date()
        warning_date = current_date + timedelta(days=3)
        
        expiring_accounts = EscrowAccount.objects.filter(
            end_date__lte=warning_date,
            end_date__gte=current_date,
            status='active'
        ).order_by('end_date')
        
        serializer = EscrowAccountSerializer(expiring_accounts, many=True)
        return Response({
            'count': expiring_accounts.count(),
            'results': serializer.data
        })
    
    @action(detail=True, methods=['post'])
    def update_status(self, request, pk=None):
        """
        Update escrow account status (admin only)
        """
        escrow_account = self.get_object()
        serializer = EscrowStatusUpdateSerializer(data=request.data)
        
        if serializer.is_valid():
            old_status = escrow_account.status
            new_status = serializer.validated_data['status']
            
            escrow_account.status = new_status
            escrow_account.save()
            
            # Update transaction status if needed
            transaction = escrow_account.transaction
            if new_status == 'released':
                transaction.status = 'completed'
            elif new_status == 'refunded':
                transaction.status = 'refunded'
            elif new_status == 'disputed':
                transaction.status = 'disputed'
            
            transaction.save()
            
            response_serializer = EscrowAccountSerializer(escrow_account)
            return Response(response_serializer.data)
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
