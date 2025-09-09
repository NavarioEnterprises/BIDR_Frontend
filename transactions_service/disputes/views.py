"""
Views for the Dispute API.

This module provides ViewSets and API views for handling dispute operations,
including listing, retrieving, creating, updating, and filtering disputes.

API Endpoints:
-------------
- GET /api/v1/disputes/ - List all disputes (filtered by user permissions)
- POST /api/v1/disputes/ - Create a new dispute
- GET /api/v1/disputes/{id}/ - Retrieve a specific dispute
- PUT/PATCH /api/v1/disputes/{id}/ - Update a dispute
- DELETE /api/v1/disputes/{id}/ - Delete a dispute (restricted for resolved/closed)

Custom Actions:
--------------
- POST /api/v1/disputes/{id}/evidence/ - Add evidence to a dispute
- POST /api/v1/disputes/{id}/resolve/ - Resolve a dispute (admin only)
- POST /api/v1/disputes/{id}/close/ - Close a dispute (admin only)
- GET /api/v1/disputes/stats/ - Get dispute statistics (admin only)

Permissions:
-----------
- Regular users can only access disputes they're involved in
- Admins can access all disputes
- Only admins can resolve or close disputes

Throttling:
----------
- Dispute creation: 10/hour
- Dispute updates: 20/hour
- Adding evidence: 30/hour
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
class DisputeCreateThrottle(ScopedRateThrottle):
    """Throttle for dispute creation to prevent abuse."""
    scope = 'dispute_create'

class DisputeUpdateThrottle(ScopedRateThrottle):
    """Throttle for dispute updates to prevent abuse."""
    scope = 'dispute_update'

class DisputeEvidenceThrottle(ScopedRateThrottle):
    """Throttle for adding evidence to disputes to prevent abuse."""
    scope = 'dispute_evidence'

from .models import Dispute
from .serializers import (
    DisputeListSerializer,
    DisputeDetailSerializer,
    DisputeCreateSerializer,
    DisputeUpdateSerializer,
    DisputeEvidenceSerializer
)


class IsDisputeParticipant(IsAuthenticated):
    """
    Custom permission to only allow participants of a dispute to view or edit it.
    Participants include the initiator, the transaction's buyer/seller, and admins.
    """
    def has_object_permission(self, request, view, obj):
        # First check if user is authenticated
        if not super().has_permission(request, view):
            return False
        
        user = request.user
        
        # Admins can access all disputes
        if user.is_staff or user.role == 'administrator':
            return True
        
        # Initiator can access their own disputes
        if obj.initiator_id == user:
            return True
        
        # Transaction participants can access disputes for their transactions
        transaction = obj.transaction_id
        is_transaction_participant = (
            (hasattr(transaction, 'buyer_id') and transaction.buyer_id.user == user) or
            (hasattr(transaction, 'seller_id') and transaction.seller_id.user == user)
        )
        
        return is_transaction_participant


class DisputeViewSet(viewsets.ModelViewSet):
    """
    ViewSet for handling dispute operations.
    
    Provides CRUD operations for disputes with appropriate permissions and
    serializers for different actions. Includes throttling to prevent abuse.
    
    list:
        Return a list of all disputes the user has access to.
        Admins can see all disputes, while regular users can only see disputes they're involved in.
        Supports filtering by status, type, date range, and transaction ID.
        
    create:
        Create a new dispute.
        The initiator will default to the current user if not specified.
        Validates that the transaction exists and can be disputed.
        
    retrieve:
        Return the details of a specific dispute.
        Only accessible to dispute participants and admins.
        
    update:
        Update a dispute.
        Only certain fields can be updated, and some transitions (like status changes)
        are restricted to admins.
        
    partial_update:
        Partially update a dispute.
        Same restrictions as update apply.
        
    destroy:
        Delete a dispute.
        Restricted for resolved or closed disputes.
    """
    queryset = Dispute.objects.all()
    permission_classes = [IsAuthenticated]
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = ['dispute_id', 'description', 'resolution']
    ordering_fields = ['created_at', 'updated_at', 'status']
    ordering = ['-created_at']
    throttle_classes = [UserRateThrottle]
    
    def get_queryset(self):
        """
        Filter disputes based on user role and query parameters.
        """
        user = self.request.user
        queryset = super().get_queryset()
        
        # Admins can see all disputes
        if user.is_staff or user.role == 'administrator':
            pass  # No filtering needed
        else:
            # Regular users can only see disputes they're involved in
            queryset = queryset.filter(
                Q(initiator_id=user) |
                Q(transaction_id__buyer_id__user=user) |
                Q(transaction_id__seller_id__user=user)
            )
        
        # Apply filters from query parameters
        status = self.request.query_params.get('status')
        if status:
            queryset = queryset.filter(status=status.upper())
        
        dispute_type = self.request.query_params.get('type')
        if dispute_type:
            queryset = queryset.filter(dispute_type=dispute_type.upper())
        
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
        
        return queryset
    
    def get_serializer_class(self):
        """
        Return appropriate serializer class based on the action.
        """
        if self.action == 'list':
            return DisputeListSerializer
        elif self.action == 'create':
            return DisputeCreateSerializer
        elif self.action == 'update' or self.action == 'partial_update':
            return DisputeUpdateSerializer
        elif self.action == 'add_evidence':
            return DisputeEvidenceSerializer
        else:
            return DisputeDetailSerializer
    
    def get_permissions(self):
        """
        Return appropriate permissions based on the action.
        """
        if self.action in ['retrieve', 'update', 'partial_update', 'add_evidence']:
            self.permission_classes = [IsDisputeParticipant]
        return super().get_permissions()
        
    def get_throttles(self):
        """
        Return appropriate throttle classes based on the action.
        """
        if self.action == 'create':
            self.throttle_classes = [DisputeCreateThrottle]
        elif self.action in ['update', 'partial_update', 'resolve_dispute', 'close_dispute']:
            self.throttle_classes = [DisputeUpdateThrottle]
        elif self.action == 'add_evidence':
            self.throttle_classes = [DisputeEvidenceThrottle]
        return super().get_throttles()
    
    def create(self, request, *args, **kwargs):
        """
        Create a new dispute with the current user as initiator if not specified.
        Uses transaction.atomic() to ensure database integrity.
        """
        data = request.data.copy()
        
        # Set initiator to current user if not provided
        if 'initiator_id' not in data:
            data['initiator_id'] = request.user.id
        
        serializer = self.get_serializer(data=data)
        serializer.is_valid(raise_exception=True)
        
        # Check if initiator is the current user or admin
        if (str(data['initiator_id']) != str(request.user.id) and 
            not (request.user.is_staff or request.user.role == 'administrator')):
            raise PermissionDenied("You can only create disputes for yourself")
        
        try:
            with transaction.atomic():
                self.perform_create(serializer)
                
                # Log the dispute creation
                logger.info(
                    f"Dispute created: {serializer.instance.dispute_id} for transaction "
                    f"{serializer.instance.transaction_id} by user {request.user.id}"
                )
                
                headers = self.get_success_headers(serializer.data)
                return Response(serializer.data, status=status.HTTP_201_CREATED, headers=headers)
        except IntegrityError as e:
            logger.error(f"Failed to create dispute: {str(e)}")
            raise APIException("Failed to create dispute due to database integrity error")
    
    def update(self, request, *args, **kwargs):
        """
        Update a dispute with permission checks for status transitions.
        Uses transaction.atomic() to ensure database integrity.
        """
        partial = kwargs.pop('partial', False)
        instance = self.get_object()
        
        # Only admins can change status to RESOLVED or CLOSED
        if 'status' in request.data:
            new_status = request.data['status']
            if new_status in ['RESOLVED', 'CLOSED'] and not (
                request.user.is_staff or request.user.role == 'administrator'
            ):
                raise PermissionDenied(
                    "Only administrators can resolve or close disputes"
                )
        
        serializer = self.get_serializer(instance, data=request.data, partial=partial)
        serializer.is_valid(raise_exception=True)
        
        try:
            with transaction.atomic():
                self.perform_update(serializer)
                
                # Log the dispute update
                status_change = ''
                if 'status' in request.data:
                    status_change = f" Status changed to {request.data['status']}"
                
                logger.info(
                    f"Dispute updated: {instance.dispute_id} by user {request.user.id}.{status_change}"
                )
                
                if getattr(instance, '_prefetched_objects_cache', None):
                    # If 'prefetch_related' has been applied to a queryset, we need to
                    # forcibly invalidate the prefetch cache on the instance.
                    instance._prefetched_objects_cache = {}
                
                return Response(serializer.data)
        except IntegrityError as e:
            logger.error(f"Failed to update dispute {instance.dispute_id}: {str(e)}")
            raise APIException("Failed to update dispute due to database integrity error")
        except Exception as e:
            logger.error(f"Unexpected error updating dispute {instance.dispute_id}: {str(e)}")
            raise APIException("An unexpected error occurred while updating the dispute")
    
    @action(detail=True, methods=['post'], url_path='evidence')
    def add_evidence(self, request, pk=None):
        """
        Add evidence files to a dispute.
        Uses transaction.atomic() to ensure database integrity.
        """
        dispute = self.get_object()
        
        # Check if dispute can be updated
        if dispute.status in ['RESOLVED', 'CLOSED']:
            return Response(
                {"detail": "Cannot add evidence to resolved or closed disputes"},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        serializer = DisputeEvidenceSerializer(dispute, data=request.data)
        serializer.is_valid(raise_exception=True)
        
        try:
            with transaction.atomic():
                serializer.save()
                
                # Log the evidence addition
                logger.info(
                    f"Evidence added to dispute {dispute.dispute_id} by user {request.user.id}"
                )
                
                return Response(serializer.data)
        except IntegrityError as e:
            logger.error(f"Failed to add evidence to dispute {dispute.dispute_id}: {str(e)}")
            raise APIException("Failed to add evidence due to database integrity error")
        except Exception as e:
            logger.error(f"Unexpected error adding evidence to dispute {dispute.dispute_id}: {str(e)}")
            raise APIException("An unexpected error occurred while adding evidence")
    
    @action(detail=True, methods=['post'], url_path='resolve')
    def resolve_dispute(self, request, pk=None):
        """
        Resolve a dispute with resolution details.
        Uses transaction.atomic() to ensure database integrity.
        """
        dispute = self.get_object()
        
        # Only admins can resolve disputes
        if not (request.user.is_staff or request.user.role == 'administrator'):
            raise PermissionDenied("Only administrators can resolve disputes")
        
        # Check if dispute can be resolved
        if dispute.status in ['RESOLVED', 'CLOSED']:
            return Response(
                {"detail": f"Dispute is already {dispute.status.lower()}"},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Validate resolution text
        resolution_text = request.data.get('resolution')
        if not resolution_text:
            return Response(
                {"detail": "Resolution details are required"},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        try:
            with transaction.atomic():
                # Resolve the dispute
                dispute.resolve(resolution_text, request.user)
                
                # Log the resolution
                logger.info(
                    f"Dispute {dispute.dispute_id} resolved by admin {request.user.id}"
                )
                
                # Return updated dispute
                serializer = DisputeDetailSerializer(dispute)
                return Response(serializer.data)
        except IntegrityError as e:
            logger.error(f"Failed to resolve dispute {dispute.dispute_id}: {str(e)}")
            raise APIException("Failed to resolve dispute due to database integrity error")
        except Exception as e:
            logger.error(f"Unexpected error resolving dispute {dispute.dispute_id}: {str(e)}")
            raise APIException("An unexpected error occurred while resolving the dispute")
    
    @action(detail=True, methods=['post'], url_path='close')
    def close_dispute(self, request, pk=None):
        """
        Close a dispute.
        Uses transaction.atomic() to ensure database integrity.
        """
        dispute = self.get_object()
        
        # Only admins can close disputes
        if not (request.user.is_staff or request.user.role == 'administrator'):
            raise PermissionDenied("Only administrators can close disputes")
        
        # Check if dispute can be closed
        if dispute.status == 'CLOSED':
            return Response(
                {"detail": "Dispute is already closed"},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        try:
            with transaction.atomic():
                # Close the dispute
                dispute.close()
                
                # Log the closure
                logger.info(
                    f"Dispute {dispute.dispute_id} closed by admin {request.user.id}"
                )
                
                # Return updated dispute
                serializer = DisputeDetailSerializer(dispute)
                return Response(serializer.data)
        except IntegrityError as e:
            logger.error(f"Failed to close dispute {dispute.dispute_id}: {str(e)}")
            raise APIException("Failed to close dispute due to database integrity error")
        except Exception as e:
            logger.error(f"Unexpected error closing dispute {dispute.dispute_id}: {str(e)}")
            raise APIException("An unexpected error occurred while closing the dispute")
    
    def destroy(self, request, *args, **kwargs):
        """
        Delete a dispute with validation to prevent deletion of resolved or closed disputes.
        Uses transaction.atomic() to ensure database integrity.
        """
        instance = self.get_object()
        
        # Prevent deletion of resolved or closed disputes
        if instance.status in ['RESOLVED', 'CLOSED']:
            return Response(
                {"detail": f"Cannot delete a dispute with status '{instance.status.lower()}'"},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        try:
            with transaction.atomic():
                # Log the deletion
                logger.info(f"Dispute {instance.dispute_id} deleted by user {request.user.id}")
                
                # Perform the deletion
                self.perform_destroy(instance)
                
                return Response(status=status.HTTP_204_NO_CONTENT)
        except Exception as e:
            logger.error(f"Error deleting dispute {instance.dispute_id}: {str(e)}")
            raise APIException("An error occurred while deleting the dispute")
    
    @action(detail=False, methods=['get'], url_path='stats')
    def get_stats(self, request):
        """
        Get statistics about disputes.
        Handles potential errors and provides comprehensive statistics.
        """
        # Only admins can access statistics
        if not (request.user.is_staff or request.user.role == 'administrator'):
            raise PermissionDenied("Only administrators can access dispute statistics")
        
        try:
            # Get base queryset
            queryset = self.get_queryset()
            
            # Calculate statistics
            total_disputes = queryset.count()
            open_disputes = queryset.filter(status='OPEN').count()
            investigating_disputes = queryset.filter(status='INVESTIGATING').count()
            resolved_disputes = queryset.filter(status='RESOLVED').count()
            closed_disputes = queryset.filter(status='CLOSED').count()
            
            # Calculate average resolution time for resolved disputes
            resolved_queryset = queryset.filter(
                status__in=['RESOLVED', 'CLOSED'],
                resolved_at__isnull=False
            )
            
            # Calculate average resolution time
            if resolved_queryset.exists():
                total_resolution_days = 0
                for dispute in resolved_queryset:
                    delta = dispute.resolved_at - dispute.created_at
                    total_resolution_days += delta.days
                
                avg_resolution_days = total_resolution_days / resolved_queryset.count()
            else:
                avg_resolution_days = 0
            
            # Count disputes by type
            disputes_by_type = {}
            for dispute_type, _ in Dispute.DISPUTE_TYPE_CHOICES:
                disputes_by_type[dispute_type] = queryset.filter(dispute_type=dispute_type).count()
            
            # Calculate additional statistics
            today = timezone.now().date()
            disputes_today = queryset.filter(created_at__date=today).count()
            
            # Get disputes created in the last 7 days
            week_ago = timezone.now() - timezone.timedelta(days=7)
            disputes_last_week = queryset.filter(created_at__gte=week_ago).count()
            
            # Get disputes created in the last 30 days
            month_ago = timezone.now() - timezone.timedelta(days=30)
            disputes_last_month = queryset.filter(created_at__gte=month_ago).count()
            
            # Log the statistics access
            logger.info(f"Dispute statistics accessed by admin {request.user.id}")
            
            # Return statistics
            return Response({
                'total_disputes': total_disputes,
                'by_status': {
                    'open': open_disputes,
                    'investigating': investigating_disputes,
                    'resolved': resolved_disputes,
                    'closed': closed_disputes
                },
                'by_type': disputes_by_type,
                'avg_resolution_days': round(avg_resolution_days, 1),
                'time_periods': {
                    'today': disputes_today,
                    'last_7_days': disputes_last_week,
                    'last_30_days': disputes_last_month
                }
            })
        except Exception as e:
            logger.error(f"Error generating dispute statistics: {str(e)}")
            raise APIException("An error occurred while generating dispute statistics")
