"""
Views for the PaymentTransaction API.

This module provides ViewSets and API views for handling payment transaction operations,
including listing, retrieving, creating, updating, and processing payments.

API Endpoints:
-------------
- GET /api/v1/payment-transactions/ - List all payment transactions (filtered by user permissions)
- POST /api/v1/payment-transactions/ - Create a new payment transaction
- GET /api/v1/payment-transactions/{id}/ - Retrieve a specific payment transaction
- PUT/PATCH /api/v1/payment-transactions/{id}/ - Update a payment transaction
- DELETE /api/v1/payment-transactions/{id}/ - Delete a payment transaction (restricted for completed/refunded)

Custom Actions:
--------------
- POST /api/v1/payment-transactions/{id}/process/ - Process a payment
- POST /api/v1/payment-transactions/{id}/refund/ - Refund a payment
- GET /api/v1/payment-transactions/by-transaction/{transaction_id}/ - Get payments for a transaction

Permissions:
-----------
- Regular users can only access payment transactions they're involved in
- Admins can access all payment transactions
- Only admins can release payments

Throttling:
----------
- Payment transaction creation: 10/hour
- Payment processing: 5/hour
- Refund requests: 3/hour
- General user rate: 100/hour
"""

from django.db.models import Q
from django.utils import timezone
from django.shortcuts import get_object_or_404
from django.db import transaction, IntegrityError

from rest_framework import viewsets, status, filters
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from rest_framework.exceptions import PermissionDenied, ValidationError, APIException
from rest_framework.throttling import UserRateThrottle, ScopedRateThrottle
import logging

# Set up logger
logger = logging.getLogger(__name__)

# Custom throttling classes
class PaymentCreateThrottle(ScopedRateThrottle):
    """Throttle for payment transaction creation to prevent abuse."""
    scope = 'payment_create'

class PaymentProcessThrottle(ScopedRateThrottle):
    """Throttle for payment processing to prevent abuse."""
    scope = 'payment_process'

class PaymentRefundThrottle(ScopedRateThrottle):
    """Throttle for payment refund requests to prevent abuse."""
    scope = 'payment_refund'

from .models import PaymentTransaction, get_payment_gateway
from .serializers import (
    PaymentTransactionListSerializer,
    PaymentTransactionDetailSerializer,
    PaymentTransactionCreateSerializer,
    PaymentTransactionUpdateSerializer,
    ProcessPaymentSerializer,
    RefundPaymentSerializer,
    SellerEarningHistorySerializer
)


class IsPaymentParticipant(IsAuthenticated):
    """
    Custom permission to only allow participants of a payment transaction to view or edit it.
    Participants include the transaction's buyer/seller and admins.
    """
    def has_object_permission(self, request, view, obj):
        # First check if user is authenticated
        if not super().has_permission(request, view):
            return False
        
        user = request.user
        
        # Admins can access all payment transactions
        if user.is_staff or user.role == 'administrator':
            return True
        
        # Transaction participants can access payment transactions for their transactions
        transaction = obj.transaction_id
        is_transaction_participant = (
            (hasattr(transaction, 'buyer_id') and transaction.buyer_id.user == user) or
            (hasattr(transaction, 'seller_id') and transaction.seller_id.user == user)
        )
        
        return is_transaction_participant


class PaymentTransactionViewSet(viewsets.ModelViewSet):
    """
    ViewSet for handling payment transaction operations.
    
    Provides CRUD operations for payment transactions with appropriate permissions and
    serializers for different actions. Includes throttling to prevent abuse.
    
    list:
        Return a list of all payment transactions the user has access to.
        Admins can see all payment transactions, while regular users can only see payment transactions they're involved in.
        Supports filtering by status, gateway, date range, and transaction ID.
        
    create:
        Create a new payment transaction.
        Validates that the transaction exists and can have a payment transaction.
        
    retrieve:
        Return the details of a specific payment transaction.
        Only accessible to payment participants and admins.
        
    update:
        Update a payment transaction.
        Only certain fields can be updated, and some transitions (like status changes)
        are restricted to admins.
        
    partial_update:
        Partially update a payment transaction.
        Same restrictions as update apply.
        
    destroy:
        Delete a payment transaction.
        Restricted for completed or refunded payment transactions.
    """
    queryset = PaymentTransaction.objects.all()
    permission_classes = [IsAuthenticated]
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = ['payment_id', 'transaction_id__transaction_id', 'gateway_transaction_id']
    ordering_fields = ['created_at', 'status', 'amount']
    ordering = ['-created_at']
    throttle_classes = [UserRateThrottle]
    
    def get_queryset(self):
        """
        Filter payment transactions based on user role and query parameters.
        """
        user = self.request.user
        queryset = super().get_queryset()
        
        # Admins can see all payment transactions
        if user.is_staff or user.role == 'administrator':
            pass  # No filtering needed
        else:
            # Regular users can only see payment transactions they're involved in
            queryset = queryset.filter(
                Q(transaction_id__buyer_id__user=user) |
                Q(transaction_id__seller_id__user=user)
            )
        
        # Apply filters from query parameters
        status = self.request.query_params.get('status')
        if status:
            queryset = queryset.filter(status=status.upper())
        
        payment_gateway = self.request.query_params.get('gateway')
        if payment_gateway:
            queryset = queryset.filter(payment_gateway=payment_gateway.upper())
        
        # Filter by date range
        start_date = self.request.query_params.get('start_date')
        end_date = self.request.query_params.get('end_date')
        
        if start_date:
            queryset = queryset.filter(created_at__gte=start_date)
        
        if end_date:
            queryset = queryset.filter(created_at__lte=end_date)
        
        # Filter by transaction ID
        transaction_id = self.request.query_params.get('transaction_id')
        if transaction_id:
            queryset = queryset.filter(transaction_id=transaction_id)
        
        # Filter by amount range
        min_amount = self.request.query_params.get('min_amount')
        max_amount = self.request.query_params.get('max_amount')
        
        if min_amount:
            queryset = queryset.filter(amount__gte=min_amount)
        
        if max_amount:
            queryset = queryset.filter(amount__lte=max_amount)
        
        return queryset
    
    def get_serializer_class(self):
        """
        Return appropriate serializer class based on the action.
        """
        if self.action == 'list':
            return PaymentTransactionListSerializer
        elif self.action == 'create':
            return PaymentTransactionCreateSerializer
        elif self.action == 'update' or self.action == 'partial_update':
            return PaymentTransactionUpdateSerializer
        elif self.action == 'process_payment':
            return ProcessPaymentSerializer
        elif self.action == 'refund_payment':
            return RefundPaymentSerializer
        else:
            return PaymentTransactionDetailSerializer
    
    def get_permissions(self):
        """
        Return appropriate permissions based on the action.
        """
        if self.action in ['retrieve', 'update', 'partial_update', 'process_payment', 'refund_payment']:
            self.permission_classes = [IsPaymentParticipant]
        return super().get_permissions()
        
    def get_throttles(self):
        """
        Return appropriate throttle classes based on the action.
        """
        if self.action == 'create':
            self.throttle_classes = [PaymentCreateThrottle]
        elif self.action == 'process_payment':
            self.throttle_classes = [PaymentProcessThrottle]
        elif self.action == 'refund_payment':
            self.throttle_classes = [PaymentRefundThrottle]
        return super().get_throttles()
    
    def create(self, request, *args, **kwargs):
        """
        Create a new payment transaction.
        Uses transaction.atomic() to ensure database integrity.
        """
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        
        try:
            with transaction.atomic():
                self.perform_create(serializer)
                
                # Log the payment transaction creation
                logger.info(
                    f"Payment transaction created: {serializer.instance.payment_id} for transaction "
                    f"{serializer.instance.transaction_id} by user {request.user.id}"
                )
                
                headers = self.get_success_headers(serializer.data)
                return Response(serializer.data, status=status.HTTP_201_CREATED, headers=headers)
        except IntegrityError as e:
            logger.error(f"Failed to create payment transaction: {str(e)}")
            raise APIException("Failed to create payment transaction due to database integrity error")
    
    def update(self, request, *args, **kwargs):
        """
        Update a payment transaction with permission checks for status transitions.
        Uses transaction.atomic() to ensure database integrity.
        """
        partial = kwargs.pop('partial', False)
        instance = self.get_object()
        
        # Only admins can change status to RELEASED
        if 'status' in request.data and request.data['status'] == 'RELEASED':
            if not (request.user.is_staff or request.user.role == 'administrator'):
                raise PermissionDenied("Only administrators can release payments")
        
        serializer = self.get_serializer(instance, data=request.data, partial=partial)
        serializer.is_valid(raise_exception=True)
        
        try:
            with transaction.atomic():
                self.perform_update(serializer)
                
                # Log the payment transaction update
                status_change = ''
                if 'status' in request.data:
                    status_change = f" Status changed to {request.data['status']}"
                
                logger.info(
                    f"Payment transaction updated: {instance.payment_id} by user {request.user.id}.{status_change}"
                )
                
                if getattr(instance, '_prefetched_objects_cache', None):
                    # If 'prefetch_related' has been applied to a queryset, we need to
                    # forcibly invalidate the prefetch cache on the instance.
                    instance._prefetched_objects_cache = {}
                
                return Response(serializer.data)
        except IntegrityError as e:
            logger.error(f"Failed to update payment transaction {instance.payment_id}: {str(e)}")
            raise APIException("Failed to update payment transaction due to database integrity error")
        except Exception as e:
            logger.error(f"Unexpected error updating payment transaction {instance.payment_id}: {str(e)}")
            raise APIException("An unexpected error occurred while updating the payment transaction")
    
    def destroy(self, request, *args, **kwargs):
        """
        Delete a payment transaction with validation to prevent deletion of completed or refunded payment transactions.
        Uses transaction.atomic() to ensure database integrity.
        """
        instance = self.get_object()
        
        # Prevent deletion of completed or refunded payment transactions
        if instance.status in ['CAPTURED', 'RELEASED', 'REFUNDED']:
            return Response(
                {"detail": f"Cannot delete a payment transaction with status '{instance.status.lower()}'"},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        try:
            with transaction.atomic():
                # Log the deletion
                logger.info(f"Payment transaction {instance.payment_id} deleted by user {request.user.id}")
                
                # Perform the deletion
                self.perform_destroy(instance)
                
                return Response(status=status.HTTP_204_NO_CONTENT)
        except Exception as e:
            logger.error(f"Error deleting payment transaction {instance.payment_id}: {str(e)}")
            raise APIException("An error occurred while deleting the payment transaction")
    
    @action(detail=True, methods=['post'], url_path='process')
    def process_payment(self, request, pk=None):
        """
        Process a payment through the appropriate gateway.
        Uses transaction.atomic() to ensure database integrity.
        """
        payment_transaction = self.get_object()
        
        # Check if payment can be processed
        if payment_transaction.status != 'PENDING':
            return Response(
                {"detail": f"Payment cannot be processed. Current status: {payment_transaction.status}"},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Create serializer with payment_id from URL and data from request
        data = request.data.copy()
        data['payment_id'] = payment_transaction.payment_id
        serializer = ProcessPaymentSerializer(data=data)
        serializer.is_valid(raise_exception=True)
        
        try:
            with transaction.atomic():
                # Process the payment
                success, result = serializer.process_payment()
                
                if success:
                    # Log the successful payment processing
                    logger.info(
                        f"Payment {payment_transaction.payment_id} processed successfully by user {request.user.id}"
                    )
                    
                    return Response(result, status=status.HTTP_200_OK)
                else:
                    # Log the failed payment processing
                    logger.error(
                        f"Payment {payment_transaction.payment_id} processing failed: {result.get('error')}"
                    )
                    
                    return Response(result, status=status.HTTP_400_BAD_REQUEST)
        except Exception as e:
            logger.error(f"Unexpected error processing payment {payment_transaction.payment_id}: {str(e)}")
            raise APIException("An unexpected error occurred while processing the payment")
    
    @action(detail=True, methods=['post'], url_path='refund')
    def refund_payment(self, request, pk=None):
        """
        Refund a payment through the appropriate gateway.
        Uses transaction.atomic() to ensure database integrity.
        """
        payment_transaction = self.get_object()
        
        # Check if payment can be refunded
        if payment_transaction.status not in ['CAPTURED', 'RELEASED']:
            return Response(
                {"detail": f"Payment cannot be refunded. Current status: {payment_transaction.status}"},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Create serializer with payment_id from URL and data from request
        data = request.data.copy()
        data['payment_id'] = payment_transaction.payment_id
        serializer = RefundPaymentSerializer(data=data)
        serializer.is_valid(raise_exception=True)
        
        try:
            with transaction.atomic():
                # Refund the payment
                success, result = serializer.refund_payment()
                
                if success:
                    # Log the successful payment refund
                    logger.info(
                        f"Payment {payment_transaction.payment_id} refunded successfully by user {request.user.id}"
                    )
                    
                    return Response(result, status=status.HTTP_200_OK)
                else:
                    # Log the failed payment refund
                    logger.error(
                        f"Payment {payment_transaction.payment_id} refund failed: {result.get('error')}"
                    )
                    
                    return Response(result, status=status.HTTP_400_BAD_REQUEST)
        except Exception as e:
            logger.error(f"Unexpected error refunding payment {payment_transaction.payment_id}: {str(e)}")
            raise APIException("An unexpected error occurred while refunding the payment")
    
    @action(detail=False, methods=['get'], url_path='by-transaction/(?P<transaction_id>[^/.]+)')
    def by_transaction(self, request, transaction_id=None):
        """
        Get all payment transactions for a specific transaction.
        """
        # Filter queryset by transaction_id
        queryset = self.get_queryset().filter(transaction_id=transaction_id)
        
        # Check if user has permission to access the transaction
        if not queryset.exists():
            return Response(
                {"detail": "No payment transactions found for this transaction ID"},
                status=status.HTTP_404_NOT_FOUND
            )
        
        # Check if user has permission to access the first payment transaction
        # This will implicitly check if the user has permission to access the transaction
        self.check_object_permissions(request, queryset.first())
        
        page = self.paginate_queryset(queryset)
        if page is not None:
            serializer = PaymentTransactionListSerializer(page, many=True)
            return self.get_paginated_response(serializer.data)
        
        serializer = PaymentTransactionListSerializer(queryset, many=True)
        return Response(serializer.data)
    
    @action(detail=False, methods=['get'], url_path='pending-release')
    def pending_release(self, request):
        """
        Get payment transactions that are due for release.
        Only accessible to admins.
        """
        # Only admins can access this endpoint
        if not (request.user.is_staff or request.user.role == 'administrator'):
            raise PermissionDenied("Only administrators can access payments pending release")
        
        # Get payment transactions that are due for release
        now = timezone.now()
        queryset = PaymentTransaction.objects.filter(
            status='CAPTURED',
            escrow_release_date__lte=now
        )
        
        page = self.paginate_queryset(queryset)
        if page is not None:
            serializer = PaymentTransactionListSerializer(page, many=True)
            return self.get_paginated_response(serializer.data)
        
        serializer = PaymentTransactionListSerializer(queryset, many=True)
        return Response(serializer.data)
    
    @action(detail=False, methods=['get'], url_path='seller-earnings')
    def seller_earning_history(self, request):
        """
        Get earning history for sellers - shows all successful/paid payments.
        Only accessible to sellers and admins.
        Filters payments with status 'CAPTURED', 'RELEASED', 'PAID'.
        """
        user = request.user
        
        # Check if user is a seller or admin
        if not (user.is_staff or user.role in ['seller', 'administrator']):
            raise PermissionDenied("Only sellers and administrators can access earning history")
        
        # Get payment transactions with successful status
        successful_statuses = ['CAPTURED', 'RELEASED', 'PAID']
        queryset = PaymentTransaction.objects.filter(
            status__in=successful_statuses
        )
        
        # If not admin, filter by seller
        if not (user.is_staff or user.role == 'administrator'):
            queryset = queryset.filter(
                transaction_id__seller_id__username=user.username
            )
        
        # Optional filtering by seller_id for admins
        seller_id = request.query_params.get('seller_id')
        if seller_id and (user.is_staff or user.role == 'administrator'):
            queryset = queryset.filter(transaction_id__seller_id__id=seller_id)
        
        # Optional date filtering
        start_date = request.query_params.get('start_date')
        end_date = request.query_params.get('end_date')
        
        if start_date:
            queryset = queryset.filter(created_at__gte=start_date)
        
        if end_date:
            queryset = queryset.filter(created_at__lte=end_date)
        
        # Optional status filtering
        status_filter = request.query_params.get('status')
        if status_filter and status_filter.upper() in successful_statuses:
            queryset = queryset.filter(status=status_filter.upper())
        
        # Order by most recent first
        queryset = queryset.order_by('-created_at')
        
        # Log the earning history access
        seller_filter = f" for seller {seller_id}" if seller_id else ""
        logger.info(f"Earning history accessed by user {user.id}{seller_filter}")
        
        # Paginate results
        page = self.paginate_queryset(queryset)
        if page is not None:
            serializer = SellerEarningHistorySerializer(page, many=True)
            return self.get_paginated_response(serializer.data)
        
        serializer = SellerEarningHistorySerializer(queryset, many=True)
        return Response(serializer.data)