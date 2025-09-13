"""
Views for the Quotes app in BIDR Quoting Service.

This module provides API views for Quote models and related entities.
"""

from django.shortcuts import get_object_or_404
from django.db.models import Q
from django.utils import timezone
from rest_framework import viewsets, status, filters, mixins
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django_filters.rest_framework import DjangoFilterBackend

from .models import (
    Quote, QuoteItem, QuoteAttachment, QuoteMessage, QuoteComparison
)
from .serializers import (
    QuoteListSerializer, QuoteDetailSerializer, QuoteCreateUpdateSerializer,
    QuoteItemSerializer, QuoteAttachmentSerializer, QuoteMessageSerializer,
    QuoteMessageCreateSerializer, QuoteStatusUpdateSerializer,
    QuoteComparisonSerializer
)
from .serializers_with_seller import (
    QuoteListWithSellerSerializer, QuoteDetailWithSellerSerializer,
    QuoteCreateUpdateWithSellerSerializer, BulkQuoteWithSellerSerializer,
    enhance_quotes_with_seller_details, get_seller_quotes_summary
)
from .serializers_hybrid import QuoteCreateUpdateHybridSerializer
from core.auth_service import (
    get_seller_details, get_seller_basic_info, validate_seller_exists,
    get_multiple_sellers
)
from rest_framework.permissions import IsAuthenticated, IsAdminUser, BasePermission


class IsSellerOrRequester(BasePermission):
    """
    Custom permission to only allow sellers or requesters to access their quotes.
    """
    def has_object_permission(self, request, view, obj):
        # Check if user is seller or requester
        if hasattr(obj, 'seller_id'):
            if request.user == obj.seller_id:
                return True
        
        if hasattr(obj, 'request_id') and hasattr(obj.request_id, 'requester'):
            if request.user == obj.request_id.requester:
                return True
        
        # Admin permissions are checked separately
        return False


class IsSellerOrRequesterOrAdmin(BasePermission):
    """
    Permission to allow sellers, requesters, or admin users.
    """
    def has_permission(self, request, view):
        # Allow admin users
        if request.user.is_staff or request.user.is_superuser:
            return True
        
        # For object-level permissions, defer to has_object_permission
        return True
    
    def has_object_permission(self, request, view, obj):
        # Allow admin users
        if request.user.is_staff or request.user.is_superuser:
            return True
        
        # Check if user is seller or requester
        if hasattr(obj, 'seller_id'):
            if request.user == obj.seller_id:
                return True


        if hasattr(obj, 'request_id') and hasattr(obj.request_id, 'requester'):
            if request.user == obj.request_id.requester:
                return True
        
        if hasattr(obj, 'quote'):
            if request.user == obj.quote.seller_id:
                return True
            if hasattr(obj.quote.request_id, 'requester'):
                if request.user == obj.quote.request_id.requester:
                    return True
        
        return False


class QuoteViewSet(viewsets.ModelViewSet):
    """
    API endpoint for quotes.
    
    Provides CRUD operations for quotes with different serializers for list and detail views.
    """
    queryset = Quote.objects.all().select_related(
        'request_id',
        'request_id__consumer_electronics',
        'request_id__vehicle_spares', 
        'request_id__vehicle_tyres_rims'
    ).prefetch_related('items', 'attachments', 'messages')
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['status', 'currency', 'estimated_delivery_days']
    search_fields = ['id']
    ordering_fields = ['created_at', 'updated_at', 'valid_until', 'total_amount']
    ordering = ['-created_at']
    permission_classes = []  # Remove authentication requirements
    
    def get_serializer_class(self):
        """
        Return appropriate serializer class based on action.
        """
        if self.action == 'list':
            return QuoteListWithSellerSerializer
        elif self.action in ['create', 'update', 'partial_update']:
            # Use hybrid serializer that supports both User IDs and seller UUIDs
            return QuoteCreateUpdateHybridSerializer
        return QuoteDetailWithSellerSerializer
    
    def get_queryset(self):
        """
        Filter quotes based on user role.
        """
        user = self.request.user
        queryset = super().get_queryset()
        
        # Admin users can see all quotes
        if user.is_staff or user.is_superuser:
            return queryset
        
        # For anonymous users or when permissions are disabled, return all quotes
        if not user.is_authenticated:
            return queryset
        
        # Sellers can see their own quotes
        seller_quotes = queryset.filter(seller_id=user)
        
        # Requesters can see quotes for their requests
        # This assumes the ProductRequest model has a requester field
        requester_quotes = queryset.filter(request_id__requester=user)
        
        # Combine the querysets
        return (seller_quotes | requester_quotes).distinct()
    
    def perform_create(self, serializer):
        """
        Set seller_id to current user if not provided.
        Handle seller UUID to User mapping for placeholder users.
        """
        seller_id = serializer.validated_data.get('seller_id')
        
        if not seller_id:
            # Only set to current user if user is authenticated
            if self.request.user and self.request.user.is_authenticated:
                serializer.save(seller_id=self.request.user)
            else:
                # For anonymous requests, seller_id must be provided
                serializer.save()
        else:
            # If seller_id is a UUID string, ensure we have a placeholder user
            if isinstance(seller_id, str) and len(seller_id) > 10:  # Likely a UUID
                from django.contrib.auth.models import User
                try:
                    placeholder_user = User.objects.get(username=f"seller_{seller_id}")
                    serializer.save(seller_id=placeholder_user)
                except User.DoesNotExist:
                    # Create placeholder user if it doesn't exist
                    placeholder_user = User.objects.create_user(
                        username=f"seller_{seller_id}",
                        email=f"seller_{seller_id}@placeholder.com"
                    )
                    serializer.save(seller_id=placeholder_user)
            else:
                serializer.save()
    
    @action(detail=True, methods=['post'])
    def mark_as_viewed(self, request, pk=None):
        """
        Mark a quote as viewed by the requester.
        """
        quote = self.get_object()
        
        # Only the requester can mark a quote as viewed
        if not hasattr(quote.request_id, 'requester') or request.user != quote.request_id.requester:
            return Response(
                {"detail": "Only the requester can mark a quote as viewed."},
                status=status.HTTP_403_FORBIDDEN
            )
        
        # Since we've removed the mark_as_viewed method, we'll implement it directly here
        # This assumes we've added viewed_by_requester and requester_view_date fields to the model
        if hasattr(quote, 'viewed_by_requester'):
            quote.viewed_by_requester = True
            quote.requester_view_date = timezone.now()
            quote.save(update_fields=['viewed_by_requester', 'requester_view_date'])
        
        return Response({"status": "quote marked as viewed"})
    
    @action(detail=True, methods=['post'])
    def update_status(self, request, pk=None):
        """
        Update the status of a quote.
        """
        quote = self.get_object()
        serializer = QuoteStatusUpdateSerializer(quote, data=request.data)
        
        if serializer.is_valid():
            new_status = serializer.validated_data['status']
            notes = serializer.validated_data.get('notes', '')
            
            # Check permissions for status changes
            if new_status == 'ACCEPTED':
                # Only requester can accept quotes
                if hasattr(quote.request_id, 'requester') and request.user != quote.request_id.requester:
                    return Response(
                        {"detail": "Only the requester can accept quotes."},
                        status=status.HTTP_403_FORBIDDEN
                    )
            elif new_status == 'REJECTED':
                # Only requester can reject quotes
                if hasattr(quote.request_id, 'requester') and request.user != quote.request_id.requester:
                    return Response(
                        {"detail": "Only the requester can reject quotes."},
                        status=status.HTTP_403_FORBIDDEN
                    )
            elif new_status == 'EXPIRED':
                # Only admin can expire quotes
                if not request.user.is_staff:
                    return Response(
                        {"detail": "Only administrators can expire quotes."},
                        status=status.HTTP_403_FORBIDDEN
                    )
            
            # Update status
            quote.status = new_status
            
            # Add a system message if notes provided
            if notes:
                QuoteMessage.objects.create(
                    quote=quote,
                    sender=request.user,
                    message_type='system',
                    subject=f"Status changed to {dict(Quote.STATUS_CHOICES)[new_status]}",
                    message=notes
                )
            
            quote.save()
            
            # If quote is accepted, update other quotes for this request
            if new_status == 'ACCEPTED':
                # Update other quotes for this request
                Quote.objects.filter(
                    request_id=quote.request_id,
                    status='PENDING'
                ).exclude(id=quote.id).update(
                    status='REJECTED'
                )
            
            return Response(QuoteDetailSerializer(quote, context={'request': request}).data)
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
    @action(detail=True, methods=['get'])
    def items(self, request, pk=None):
        """
        List all items for a quote.
        """
        quote = self.get_object()
        items = quote.items.all()
        serializer = QuoteItemSerializer(items, many=True)
        return Response(serializer.data)
    
    @action(detail=True, methods=['get'])
    def attachments(self, request, pk=None):
        """
        List all attachments for a quote.
        """
        quote = self.get_object()
        attachments = quote.attachments.all()
        serializer = QuoteAttachmentSerializer(attachments, many=True)
        return Response(serializer.data)
    
    @action(detail=True, methods=['get', 'post'])
    def messages(self, request, pk=None):
        """
        List all messages for a quote or create a new message.
        """
        quote = self.get_object()
        
        if request.method == 'GET':
            # Filter messages based on user role
            if request.user == quote.supplier:
                messages = quote.messages.filter(
                    Q(is_internal=False) | 
                    Q(is_internal=True, sender=request.user)
                )
            elif request.user == quote.request.requester:
                messages = quote.messages.filter(
                    Q(is_internal=False) | 
                    Q(is_internal=True, sender=request.user)
                )
            else:
                messages = quote.messages.all()
                
            serializer = QuoteMessageSerializer(messages, many=True, context={'request': request})
            return Response(serializer.data)
        
        elif request.method == 'POST':
            serializer = QuoteMessageCreateSerializer(data=request.data)
            if serializer.is_valid():
                serializer.save(
                    quote=quote,
                    sender=request.user
                )
                return Response(serializer.data, status=status.HTTP_201_CREATED)
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
    @action(detail=False, methods=['get'])
    def by_seller(self, request):
        """
        Get quotes by seller using auth_user_uid from authentication service.
        """
        seller_id = request.query_params.get('seller_id')
        auth_user_uid = request.query_params.get('auth_user_uid')
        
        if not seller_id and not auth_user_uid:
            return Response(
                {'error': 'Either seller_id or auth_user_uid parameter is required'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # If auth_user_uid is provided, find the corresponding User object
        if auth_user_uid:
            from django.contrib.auth.models import User
            try:
                # First try to find if we have a placeholder user for this UUID
                placeholder_user = User.objects.get(username=f"seller_{auth_user_uid}")
                seller_id = placeholder_user.id
            except User.DoesNotExist:
                # If no placeholder user exists, no quotes can exist
                return Response({
                    'count': 0,
                    'next': None,
                    'previous': None,
                    'results': []
                })
        
        # If we have a seller_id string (UUID), try to find the corresponding User
        if seller_id and isinstance(seller_id, str) and len(seller_id) > 10:  # Likely a UUID
            from django.contrib.auth.models import User
            try:
                placeholder_user = User.objects.get(username=f"seller_{seller_id}")
                seller_id = placeholder_user.id
            except User.DoesNotExist:
                # If no placeholder user exists, no quotes can exist
                return Response({
                    'count': 0,
                    'next': None,
                    'previous': None,
                    'results': []
                })
        
        # Convert seller_id to integer if it's a string number
        try:
            seller_id = int(seller_id)
        except (ValueError, TypeError):
            return Response(
                {'error': 'Invalid seller_id format'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Filter quotes by seller
        queryset = self.get_queryset().filter(seller_id=seller_id)
        page = self.paginate_queryset(queryset)
        
        if page is not None:
            serializer = self.get_serializer(page, many=True)
            return self.get_paginated_response(serializer.data)
        
        serializer = self.get_serializer(queryset, many=True)
        return Response(serializer.data)


class QuoteItemViewSet(viewsets.ModelViewSet):
    """
    API endpoint for quote items.
    """
    queryset = QuoteItem.objects.all()
    serializer_class = QuoteItemSerializer
    permission_classes = []  # Remove authentication requirements
    
    def get_queryset(self):
        """
        Filter items based on user role.
        """
        user = self.request.user
        queryset = super().get_queryset()
        
        # Admin users can see all items
        if user.is_staff or user.is_superuser:
            return queryset
        
        # Sellers can see items for their quotes
        seller_items = queryset.filter(quote__seller_id=user)
        
        # Requesters can see items for quotes on their requests
        requester_items = queryset.filter(quote__request_id__requester=user)
        
        # Combine the querysets
        return (seller_items | requester_items).distinct()
    
    def perform_create(self, serializer):
        """
        Ensure the user has permission to create items for this quote.
        """
        quote = serializer.validated_data.get('quote')
        if quote and quote.seller_id != self.request.user and not self.request.user.is_staff:
            raise PermissionError("You don't have permission to add items to this quote.")
        serializer.save()


class QuoteAttachmentViewSet(viewsets.ModelViewSet):
    """
    API endpoint for quote attachments.
    """
    queryset = QuoteAttachment.objects.all()
    serializer_class = QuoteAttachmentSerializer
    permission_classes = []  # Remove authentication requirements
    
    def get_queryset(self):
        """
        Filter attachments based on user role.
        """
        user = self.request.user
        queryset = super().get_queryset()
        
        # Admin users can see all attachments
        if user.is_staff or user.is_superuser:
            return queryset
        
        # Sellers can see attachments for their quotes
        seller_attachments = queryset.filter(quote__seller_id=user)
        
        # Requesters can see attachments for quotes on their requests
        requester_attachments = queryset.filter(quote__request_id__requester=user)
        
        # Combine the querysets
        return (seller_attachments | requester_attachments).distinct()
    
    def perform_create(self, serializer):
        """
        Set file metadata and ensure the user has permission to add attachments.
        """
        quote = serializer.validated_data.get('quote')
        if quote and quote.seller_id != self.request.user and not self.request.user.is_staff:
            raise PermissionError("You don't have permission to add attachments to this quote.")
        
        file_obj = self.request.FILES.get('file')
        if file_obj:
            serializer.save(
                file_size=file_obj.size,
                content_type=file_obj.content_type
            )
        else:
            serializer.save()


class QuoteMessageViewSet(viewsets.ModelViewSet):
    """
    API endpoint for quote messages.
    """
    queryset = QuoteMessage.objects.all()
    permission_classes = []  # Remove authentication requirements
    
    def get_serializer_class(self):
        """
        Return appropriate serializer class based on action.
        """
        if self.action in ['create', 'update', 'partial_update']:
            return QuoteMessageCreateSerializer
        return QuoteMessageSerializer
    
    def get_queryset(self):
        """
        Filter messages based on user role.
        """
        user = self.request.user
        queryset = super().get_queryset()
        
        # Admin users can see all messages
        if user.is_staff or user.is_superuser:
            return queryset
        
        # Sellers can see non-internal messages and their own internal messages
        seller_messages = queryset.filter(
            Q(quote__seller_id=user, is_internal=False) |
            Q(quote__seller_id=user, is_internal=True, sender=user)
        )
        
        # Requesters can see non-internal messages and their own internal messages
        requester_messages = queryset.filter(
            Q(quote__request_id__requester=user, is_internal=False) |
            Q(quote__request_id__requester=user, is_internal=True, sender=user)
        )
        
        # Combine the querysets
        return (seller_messages | requester_messages).distinct()
    
    def perform_create(self, serializer):
        """
        Set sender to current user.
        """
        serializer.save(sender=self.request.user)
    
    @action(detail=True, methods=['post'])
    def mark_as_read(self, request, pk=None):
        """
        Mark a message as read.
        """
        message = self.get_object()
        message.mark_as_read()
        return Response({"status": "message marked as read"})


class QuoteComparisonViewSet(viewsets.ReadOnlyModelViewSet):
    """
    API endpoint for quote comparisons.
    """
    queryset = QuoteComparison.objects.all()
    serializer_class = QuoteComparisonSerializer
    permission_classes = []  # Remove authentication requirements
    
    def get_queryset(self):
        """
        Filter comparisons based on user role.
        """
        user = self.request.user
        queryset = super().get_queryset()
        
        # Admin users can see all comparisons
        if user.is_staff or user.is_superuser:
            return queryset
        
        # Requesters can see comparisons for their requests
        return queryset.filter(request__requester=user)  # This assumes the ProductRequest model has a requester field
    
    @action(detail=True, methods=['post'])
    def refresh(self, request, pk=None):
        """
        Refresh the comparison data.
        """
        comparison = self.get_object()
        
        # Only requester or admin can refresh comparison
        if hasattr(comparison.request, 'requester') and request.user != comparison.request.requester and not request.user.is_staff:
            return Response(
                {"detail": "Only the requester or admin can refresh the comparison."},
                status=status.HTTP_403_FORBIDDEN
            )
        
        comparison.refresh_comparison()
        serializer = self.get_serializer(comparison)
        return Response(serializer.data)
    
    @action(detail=False, methods=['get'])
    def seller_summary(self, request):
        """
        Get quote summary for a seller.
        """
        seller_id = request.query_params.get('seller_id')
        auth_user_uid = request.query_params.get('auth_user_uid')
        
        if not seller_id and not auth_user_uid:
            return Response(
                {'error': 'Either seller_id or auth_user_uid parameter is required'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # If auth_user_uid is provided, get seller details first
        if auth_user_uid and not seller_id:
            from core.auth_service import auth_client
            seller_data = auth_client.get_seller_by_auth_user_uid(auth_user_uid)
            if seller_data:
                seller_id = (
                    seller_data.get('id') or 
                    seller_data.get('seller_id') or 
                    seller_data.get('seller', {}).get('id')
                )
        
        if not seller_id:
            return Response(
                {'error': 'Seller not found in authentication service'}, 
                status=status.HTTP_404_NOT_FOUND
            )
        
        summary = get_seller_quotes_summary(seller_id)
        return Response(summary)
    
    @action(detail=False, methods=['post'])
    def validate_seller(self, request):
        """
        Validate that a seller exists in the authentication service.
        """
        seller_id = request.data.get('seller_id')
        auth_user_uid = request.data.get('auth_user_uid')
        
        if not seller_id and not auth_user_uid:
            return Response(
                {'error': 'Either seller_id or auth_user_uid is required'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        result = {'valid': False, 'seller_info': None}
        
        if seller_id:
            seller_info = get_seller_basic_info(seller_id)
            if seller_info and seller_info.get('seller_id'):
                result['valid'] = True
                result['seller_info'] = seller_info
        
        if auth_user_uid and not result['valid']:
            from core.auth_service import auth_client
            seller_data = auth_client.get_seller_by_auth_user_uid(auth_user_uid)
            if seller_data:
                result['valid'] = True
                result['seller_info'] = seller_data
        
        return Response(result)