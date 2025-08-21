"""
Views for the EscrowPeriod API.

This module provides ViewSets and API views for handling escrow period operations,
including listing, retrieving, creating, updating, and filtering escrow periods.

API Endpoints:
-------------
- GET /api/v1/escrow-periods/ - List all escrow periods (filtered by user permissions)
- POST /api/v1/escrow-periods/ - Create a new escrow period
- GET /api/v1/escrow-periods/{id}/ - Retrieve a specific escrow period
- PUT/PATCH /api/v1/escrow-periods/{id}/ - Update an escrow period
- DELETE /api/v1/escrow-periods/{id}/ - Delete an escrow period (restricted for released/disputed)

Custom Actions:
--------------
- POST /api/v1/escrow-periods/{id}/request-early-release/ - Request early release
- POST /api/v1/escrow-periods/{id}/approve-early-release/ - Approve early release (admin only)
- POST /api/v1/escrow-periods/{id}/release/ - Release an escrow period (admin only)
- GET /api/v1/escrow-periods/due-for-release/ - Get escrow periods due for release

Permissions:
-----------
- Regular users can only access escrow periods they're involved in
- Admins can access all escrow periods
- Only admins can approve early release or release escrow periods

Throttling:
----------
- Escrow period creation: 10/hour
- Escrow period updates: 20/hour
- Early release requests: 5/hour
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
class EscrowPeriodCreateThrottle(ScopedRateThrottle):
    """Throttle for escrow period creation to prevent abuse."""
    scope = 'escrow_create'

class EscrowPeriodUpdateThrottle(ScopedRateThrottle):
    """Throttle for escrow period updates to prevent abuse."""
    scope = 'escrow_update'

class EarlyReleaseRequestThrottle(ScopedRateThrottle):
    """Throttle for early release requests to prevent abuse."""
    scope = 'early_release_request'

from .models import EscrowPeriod
from .serializers import (
    EscrowPeriodListSerializer,
    EscrowPeriodDetailSerializer,
    EscrowPeriodCreateSerializer,
    EscrowPeriodUpdateSerializer,
    EarlyReleaseRequestSerializer
)


class IsEscrowParticipant(IsAuthenticated):
    """
    Custom permission to only allow participants of an escrow period to view or edit it.
    Participants include the transaction's buyer/seller and admins.
    """
    def has_object_permission(self, request, view, obj):
        # First check if user is authenticated
        if not super().has_permission(request, view):
            return False
        
        user = request.user
        
        # Admins can access all escrow periods
        if user.is_staff or user.role == 'administrator':
            return True
        
        # Transaction participants can access escrow periods for their transactions
        transaction = obj.transaction_id
        is_transaction_participant = (
            (hasattr(transaction, 'buyer_id') and transaction.buyer_id.user == user) or
            (hasattr(transaction, 'seller_id') and transaction.seller_id.user == user)
        )
        
        return is_transaction_participant


class EscrowPeriodViewSet(viewsets.ModelViewSet):
    """
    ViewSet for handling escrow period operations.
    
    Provides CRUD operations for escrow periods with appropriate permissions and
    serializers for different actions. Includes throttling to prevent abuse.
    
    list:
        Return a list of all escrow periods the user has access to.
        Admins can see all escrow periods, while regular users can only see escrow periods they're involved in.
        Supports filtering by status, category, date range, and transaction ID.
        
    create:
        Create a new escrow period.
        Validates that the transaction exists and can have an escrow period.
        
    retrieve:
        Return the details of a specific escrow period.
        Only accessible to escrow participants and admins.
        
    update:
        Update an escrow period.
        Only certain fields can be updated, and some transitions (like status changes)
        are restricted to admins.
        
    partial_update:
        Partially update an escrow period.
        Same restrictions as update apply.
        
    destroy:
        Delete an escrow period.
        Restricted for released or disputed escrow periods.
    """
    queryset = EscrowPeriod.objects.all()
    permission_classes = [IsAuthenticated]
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = ['escrow_id', 'transaction_id__transaction_id', 'category']
    ordering_fields = ['created_at', 'start_date', 'end_date', 'status']
    ordering = ['-created_at']
    throttle_classes = [UserRateThrottle]
    
    def get_queryset(self):
        """
        Filter escrow periods based on user role and query parameters.
        """
        user = self.request.user
        queryset = super().get_queryset()
        
        # Admins can see all escrow periods
        if user.is_staff or user.role == 'administrator':
            pass  # No filtering needed
        else:
            # Regular users can only see escrow periods they're involved in
            queryset = queryset.filter(
                Q(transaction_id__buyer_id__user=user) |
                Q(transaction_id__seller_id__user=user)
            )
        
        # Apply filters from query parameters
        status = self.request.query_params.get('status')
        if status:
            queryset = queryset.filter(status=status.upper())
        
        category = self.request.query_params.get('category')
        if category:
            queryset = queryset.filter(category=category.upper())
        
        # Filter by date range
        start_date = self.request.query_params.get('start_date')
        end_date = self.request.query_params.get('end_date')
        
        if start_date:
            queryset = queryset.filter(start_date__gte=start_date)
        
        if end_date:
            queryset = queryset.filter(end_date__lte=end_date)
        
        # Filter by transaction ID
        transaction_id = self.request.query_params.get('transaction_id')
        if transaction_id:
            queryset = queryset.filter(transaction_id=transaction_id)
        
        # Filter by early release requested
        early_release = self.request.query_params.get('early_release_requested')
        if early_release:
            queryset = queryset.filter(early_release_requested=early_release.lower() == 'true')
        
        return queryset
    
    def get_serializer_class(self):
        """
        Return appropriate serializer class based on the action.
        """
        if self.action == 'list':
            return EscrowPeriodListSerializer
        elif self.action == 'create':
            return EscrowPeriodCreateSerializer
        elif self.action == 'update' or self.action == 'partial_update':
            return EscrowPeriodUpdateSerializer
        elif self.action == 'request_early_release':
            return EarlyReleaseRequestSerializer
        else:
            return EscrowPeriodDetailSerializer
    
    def get_permissions(self):
        """
        Return appropriate permissions based on the action.
        """
        if self.action in ['retrieve', 'update', 'partial_update', 'request_early_release']:
            self.permission_classes = [IsEscrowParticipant]
        return super().get_permissions()
        
    def get_throttles(self):
        """
        Return appropriate throttle classes based on the action.
        """
        if self.action == 'create':
            self.throttle_classes = [EscrowPeriodCreateThrottle]
        elif self.action in ['update', 'partial_update', 'release', 'approve_early_release']:
            self.throttle_classes = [EscrowPeriodUpdateThrottle]
        elif self.action == 'request_early_release':
            self.throttle_classes = [EarlyReleaseRequestThrottle]
        return super().get_throttles()
    
    def create(self, request, *args, **kwargs):
        """
        Create a new escrow period.
        Uses transaction.atomic() to ensure database integrity.
        """
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        
        try:
            with transaction.atomic():
                self.perform_create(serializer)
                
                # Log the escrow period creation
                logger.info(
                    f"Escrow period created: {serializer.instance.escrow_id} for transaction "
                    f"{serializer.instance.transaction_id} by user {request.user.id}"
                )
                
                headers = self.get_success_headers(serializer.data)
                return Response(serializer.data, status=status.HTTP_201_CREATED, headers=headers)
        except IntegrityError as e:
            logger.error(f"Failed to create escrow period: {str(e)}")
            raise APIException("Failed to create escrow period due to database integrity error")
    
    def update(self, request, *args, **kwargs):
        """
        Update an escrow period with permission checks for status transitions.
        Uses transaction.atomic() to ensure database integrity.
        """
        partial = kwargs.pop('partial', False)
        instance = self.get_object()
        
        # Only admins can change status to RELEASED or approve early release
        if 'status' in request.data and request.data['status'] == 'RELEASED':
            if not (request.user.is_staff or request.user.role == 'administrator'):
                raise PermissionDenied("Only administrators can release escrow periods")
        
        if 'early_release_approved' in request.data and request.data['early_release_approved']:
            if not (request.user.is_staff or request.user.role == 'administrator'):
                raise PermissionDenied("Only administrators can approve early release")
        
        serializer = self.get_serializer(instance, data=request.data, partial=partial)
        serializer.is_valid(raise_exception=True)
        
        try:
            with transaction.atomic():
                self.perform_update(serializer)
                
                # Log the escrow period update
                status_change = ''
                if 'status' in request.data:
                    status_change = f" Status changed to {request.data['status']}"
                
                logger.info(
                    f"Escrow period updated: {instance.escrow_id} by user {request.user.id}.{status_change}"
                )
                
                if getattr(instance, '_prefetched_objects_cache', None):
                    # If 'prefetch_related' has been applied to a queryset, we need to
                    # forcibly invalidate the prefetch cache on the instance.
                    instance._prefetched_objects_cache = {}
                
                return Response(serializer.data)
        except IntegrityError as e:
            logger.error(f"Failed to update escrow period {instance.escrow_id}: {str(e)}")
            raise APIException("Failed to update escrow period due to database integrity error")
        except Exception as e:
            logger.error(f"Unexpected error updating escrow period {instance.escrow_id}: {str(e)}")
            raise APIException("An unexpected error occurred while updating the escrow period")
    
    def destroy(self, request, *args, **kwargs):
        """
        Delete an escrow period with validation to prevent deletion of released or disputed escrow periods.
        Uses transaction.atomic() to ensure database integrity.
        """
        instance = self.get_object()
        
        # Prevent deletion of released or disputed escrow periods
        if instance.status in ['RELEASED', 'DISPUTED']:
            return Response(
                {"detail": f"Cannot delete an escrow period with status '{instance.status.lower()}'"},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        try:
            with transaction.atomic():
                # Log the deletion
                logger.info(f"Escrow period {instance.escrow_id} deleted by user {request.user.id}")
                
                # Perform the deletion
                self.perform_destroy(instance)
                
                return Response(status=status.HTTP_204_NO_CONTENT)
        except Exception as e:
            logger.error(f"Error deleting escrow period {instance.escrow_id}: {str(e)}")
            raise APIException("An error occurred while deleting the escrow period")
    
    @action(detail=True, methods=['post'], url_path='request-early-release')
    def request_early_release(self, request, pk=None):
        """
        Request early release for an escrow period.
        Uses transaction.atomic() to ensure database integrity.
        """
        escrow_period = self.get_object()
        
        # Check if escrow period can be updated
        if escrow_period.status != 'ACTIVE':
            return Response(
                {"detail": "Early release can only be requested for active escrow periods"},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        if escrow_period.early_release_requested:
            return Response(
                {"detail": "Early release has already been requested for this escrow period"},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        serializer = EarlyReleaseRequestSerializer(escrow_period, data={'early_release_requested': True})
        serializer.is_valid(raise_exception=True)
        
        try:
            with transaction.atomic():
                serializer.save()
                
                # Log the early release request
                logger.info(
                    f"Early release requested for escrow period {escrow_period.escrow_id} by user {request.user.id}"
                )
                
                return Response(serializer.data)
        except IntegrityError as e:
            logger.error(f"Failed to request early release for escrow period {escrow_period.escrow_id}: {str(e)}")
            raise APIException("Failed to request early release due to database integrity error")
        except Exception as e:
            logger.error(f"Unexpected error requesting early release for escrow period {escrow_period.escrow_id}: {str(e)}")
            raise APIException("An unexpected error occurred while requesting early release")
    
    @action(detail=True, methods=['post'], url_path='approve-early-release')
    def approve_early_release(self, request, pk=None):
        """
        Approve early release for an escrow period (admin only).
        Uses transaction.atomic() to ensure database integrity.
        """
        escrow_period = self.get_object()
        
        # Only admins can approve early release
        if not (request.user.is_staff or request.user.role == 'administrator'):
            raise PermissionDenied("Only administrators can approve early release")
        
        # Check if escrow period can be updated
        if escrow_period.status != 'ACTIVE':
            return Response(
                {"detail": "Early release can only be approved for active escrow periods"},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        if not escrow_period.early_release_requested:
            return Response(
                {"detail": "Early release has not been requested for this escrow period"},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        if escrow_period.early_release_approved:
            return Response(
                {"detail": "Early release has already been approved for this escrow period"},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        serializer = EscrowPeriodUpdateSerializer(
            escrow_period, 
            data={'early_release_approved': True},
            partial=True,
            context={'request': request}
        )
        serializer.is_valid(raise_exception=True)
        
        try:
            with transaction.atomic():
                serializer.save()
                
                # Log the early release approval
                logger.info(
                    f"Early release approved for escrow period {escrow_period.escrow_id} by admin {request.user.id}"
                )
                
                return Response(serializer.data)
        except IntegrityError as e:
            logger.error(f"Failed to approve early release for escrow period {escrow_period.escrow_id}: {str(e)}")
            raise APIException("Failed to approve early release due to database integrity error")
        except Exception as e:
            logger.error(f"Unexpected error approving early release for escrow period {escrow_period.escrow_id}: {str(e)}")
            raise APIException("An unexpected error occurred while approving early release")
    
    @action(detail=True, methods=['post'], url_path='release')
    def release(self, request, pk=None):
        """
        Release an escrow period (admin only).
        Uses transaction.atomic() to ensure database integrity.
        """
        escrow_period = self.get_object()
        
        # Only admins can release escrow periods
        if not (request.user.is_staff or request.user.role == 'administrator'):
            raise PermissionDenied("Only administrators can release escrow periods")
        
        # Check if escrow period can be released
        if escrow_period.status != 'ACTIVE':
            return Response(
                {"detail": f"Escrow period is already {escrow_period.status.lower()}"},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # If early release is requested but not approved, check if admin is forcing release
        force_release = request.data.get('force_release', False)
        if escrow_period.early_release_requested and not escrow_period.early_release_approved and not force_release:
            return Response(
                {"detail": "Early release must be approved before releasing. Set force_release=true to override."},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        serializer = EscrowPeriodUpdateSerializer(
            escrow_period, 
            data={'status': 'RELEASED'},
            partial=True,
            context={'request': request}
        )
        serializer.is_valid(raise_exception=True)
        
        try:
            with transaction.atomic():
                serializer.save()
                
                # Log the release
                logger.info(
                    f"Escrow period {escrow_period.escrow_id} released by admin {request.user.id}"
                )
                
                return Response(serializer.data)
        except IntegrityError as e:
            logger.error(f"Failed to release escrow period {escrow_period.escrow_id}: {str(e)}")
            raise APIException("Failed to release escrow period due to database integrity error")
        except Exception as e:
            logger.error(f"Unexpected error releasing escrow period {escrow_period.escrow_id}: {str(e)}")
            raise APIException("An unexpected error occurred while releasing the escrow period")
    
    @action(detail=False, methods=['get'], url_path='due-for-release')
    def due_for_release(self, request):
        """
        Get escrow periods that are due for release.
        Only accessible to admins.
        """
        # Only admins can access this endpoint
        if not (request.user.is_staff or request.user.role == 'administrator'):
            raise PermissionDenied("Only administrators can access escrow periods due for release")
        
        # Get escrow periods that are due for release
        now = timezone.now()
        queryset = EscrowPeriod.objects.filter(
            status='ACTIVE',
            end_date__lte=now
        )
        
        page = self.paginate_queryset(queryset)
        if page is not None:
            serializer = EscrowPeriodListSerializer(page, many=True)
            return self.get_paginated_response(serializer.data)
        
        serializer = EscrowPeriodListSerializer(queryset, many=True)
        return Response(serializer.data)