from rest_framework import viewsets, status, filters
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import AllowAny
from django_filters.rest_framework import DjangoFilterBackend
from django.contrib.auth.models import User
from django.shortcuts import get_object_or_404

from .models import Review, ReviewHelpful, Ticket, TicketMessage
from .serializers import (
    ReviewSerializer, ReviewHelpfulSerializer, TicketSerializer,
    TicketCreateSerializer, TicketMessageSerializer
)


class ReviewViewSet(viewsets.ModelViewSet):
    queryset = Review.objects.filter(is_approved=True)
    serializer_class = ReviewSerializer
    permission_classes = [AllowAny]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['product_id', 'seller_id', 'rating', 'is_featured']
    search_fields = ['title', 'content', 'user__username']
    ordering_fields = ['created_at', 'rating']
    ordering = ['-created_at']

    def perform_create(self, serializer):
        # For now, create or get user by username from request data
        auth_user_uid = self.request.data.get('auth_user_uid', 'anonymous')
        user, created = User.objects.get_or_create(
            username=auth_user_uid,
            defaults={'email': f'{auth_user_uid}@bidr.com'}
        )
        serializer.save(user=user)

    @action(detail=True, methods=['post'])
    def mark_helpful(self, request, pk=None):
        """Mark a review as helpful or not helpful"""
        review = self.get_object()
        is_helpful = request.data.get('is_helpful', True)
        auth_user_uid = request.data.get('auth_user_uid')
        
        if not auth_user_uid:
            return Response(
                {'error': 'auth_user_uid is required'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        user, created = User.objects.get_or_create(
            username=auth_user_uid,
            defaults={'email': f'{auth_user_uid}@bidr.com'}
        )
        
        helpful_vote, created = ReviewHelpful.objects.update_or_create(
            review=review,
            user=user,
            defaults={'is_helpful': is_helpful}
        )
        
        serializer = ReviewHelpfulSerializer(helpful_vote)
        return Response(serializer.data)

    @action(detail=False, methods=['get'])
    def by_product(self, request):
        """Get reviews for a specific product"""
        product_id = request.query_params.get('product_id')
        if not product_id:
            return Response(
                {'error': 'product_id parameter is required'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        reviews = self.queryset.filter(product_id=product_id)
        serializer = self.get_serializer(reviews, many=True)
        return Response(serializer.data)


class TicketViewSet(viewsets.ModelViewSet):
    queryset = Ticket.objects.all()
    permission_classes = [AllowAny]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['status', 'priority', 'auth_user_uid']
    search_fields = ['ticket_id', 'subject', 'description']
    ordering_fields = ['created_at', 'updated_at']
    ordering = ['-created_at']

    def get_serializer_class(self):
        if self.action == 'create':
            return TicketCreateSerializer
        return TicketSerializer

    @action(detail=False, methods=['get'])
    def user_tickets(self, request):
        """Get tickets for a specific user by auth_user_uid"""
        auth_user_uid = request.query_params.get('auth_user_uid')
        if not auth_user_uid:
            return Response(
                {'error': 'auth_user_uid parameter is required'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        tickets = self.queryset.filter(auth_user_uid=auth_user_uid)
        serializer = self.get_serializer(tickets, many=True)
        return Response(serializer.data)

    @action(detail=True, methods=['post'])
    def add_message(self, request, pk=None):
        """Add a message to a ticket"""
        ticket = self.get_object()
        auth_user_uid = request.data.get('auth_user_uid')
        message_text = request.data.get('message')
        
        if not auth_user_uid or not message_text:
            return Response(
                {'error': 'auth_user_uid and message are required'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        user, created = User.objects.get_or_create(
            username=auth_user_uid,
            defaults={'email': f'{auth_user_uid}@bidr.com'}
        )
        
        message = TicketMessage.objects.create(
            ticket=ticket,
            sender=user,
            message=message_text,
            is_from_staff=user.is_staff
        )
        
        # Update ticket status if it was resolved/closed
        if ticket.status in ['resolved', 'closed']:
            ticket.status = 'open'
            ticket.save()
        
        serializer = TicketMessageSerializer(message)
        return Response(serializer.data, status=status.HTTP_201_CREATED)

    @action(detail=True, methods=['patch'])
    def update_status(self, request, pk=None):
        """Update ticket status"""
        ticket = self.get_object()
        new_status = request.data.get('status')
        
        if new_status not in ['open', 'in_progress', 'resolved', 'closed']:
            return Response(
                {'error': 'Invalid status'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        ticket.status = new_status
        if new_status == 'resolved':
            from django.utils import timezone
            ticket.resolved_at = timezone.now()
        
        ticket.save()
        serializer = self.get_serializer(ticket)
        return Response(serializer.data)
