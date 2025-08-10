from django.db import transaction
from django.shortcuts import get_object_or_404
from rest_framework import viewsets, status, permissions
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated, IsAdminUser
from django_filters.rest_framework import DjangoFilterBackend
from rest_framework.filters import SearchFilter, OrderingFilter

from .models import Buyer, BuyersAddressDetails
from .serializer import (
    BuyerRegistrationSerializer, BuyerSerializer, BuyersAddressDetailsSerializer,
    BuyerCreateSerializer, BuyerAddressCreateSerializer, BuyerProfileDetailSerializer
)


class IsBuyerOrAdmin(permissions.BasePermission):
    """
    Custom permission to only allow buyers to access their own data or admins to access any data
    """
    def has_permission(self, request, view):
        # Allow admin users
        if request.user.is_staff:
            return True
        # Allow authenticated users with buyer role
        return request.user.is_authenticated and request.user.role == 'buyer'

    def has_object_permission(self, request, view, obj):
        # Allow admin users
        if request.user.is_staff:
            return True
        # Allow buyers to access only their own data
        if hasattr(obj, 'user'):
            return obj.user == request.user
        return obj.user == request.user


class BuyerViewSet(viewsets.ModelViewSet):
    """
    API endpoint for managing buyer profiles
    """
    queryset = Buyer.objects.all()
    serializer_class = BuyerSerializer
    filter_backends = [DjangoFilterBackend, SearchFilter, OrderingFilter]
    filterset_fields = ['is_active']
    search_fields = ['user__email', 'user__first_name', 'user__last_name']
    ordering_fields = ['created_at', 'updated_at']
    ordering = ['-created_at']

    def get_serializer_class(self):
        """
        Return appropriate serializer class based on the action
        """
        if self.action == 'create':
            return BuyerCreateSerializer
        elif self.action == 'register':
            return BuyerRegistrationSerializer
        elif self.action in ['retrieve', 'profile']:
            return BuyerProfileDetailSerializer
        return self.serializer_class

    def get_permissions(self):
        """
        Return appropriate permissions based on the action
        """
        if self.action == 'register':
            return []
        elif self.action in ['list', 'retrieve', 'update', 'partial_update', 'destroy']:
            return [IsAdminUser()]
        return [IsAuthenticated(), IsBuyerOrAdmin()]

    def get_queryset(self):
        """
        Filter queryset based on user role
        """
        if self.request.user.is_staff:
            return self.queryset
        return self.queryset.filter(user=self.request.user)

    @action(detail=False, methods=['post'])
    def register(self, request):
        """
        Register a new buyer
        """
        serializer = self.get_serializer(data=request.data)
        if serializer.is_valid():
            with transaction.atomic():
                user = serializer.save()
                buyer = Buyer.objects.create(user=user)
                return Response(
                    {
                        'message': 'Buyer registered successfully',
                        'buyer_id': buyer.uid
                    },
                    status=status.HTTP_201_CREATED
                )
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    @action(detail=False, methods=['get'])
    def profile(self, request):
        """
        Get the profile of the authenticated buyer
        """
        buyer = get_object_or_404(Buyer, user=request.user)
        serializer = self.get_serializer(buyer)
        return Response(serializer.data)


class BuyerAddressViewSet(viewsets.ModelViewSet):
    """
    API endpoint for managing buyer addresses
    """
    queryset = BuyersAddressDetails.objects.all()
    serializer_class = BuyersAddressDetailsSerializer
    filter_backends = [DjangoFilterBackend, SearchFilter, OrderingFilter]
    filterset_fields = ['is_primary']
    search_fields = ['physical_address', 'contact_person_name', 'contact_person_email_address']
    ordering_fields = ['created_at', 'updated_at']
    ordering = ['-created_at']

    def get_serializer_class(self):
        """
        Return appropriate serializer class based on the action
        """
        if self.action == 'create':
            return BuyerAddressCreateSerializer
        return self.serializer_class

    def get_permissions(self):
        """
        Return appropriate permissions based on the action
        """
        return [IsAuthenticated(), IsBuyerOrAdmin()]

    def get_queryset(self):
        """
        Filter queryset based on user role
        """
        if self.request.user.is_staff:
            return self.queryset
        return self.queryset.filter(user=self.request.user)

    @action(detail=False, methods=['get'])
    def primary(self, request):
        """
        Get the primary address of the authenticated buyer
        """
        address = get_object_or_404(BuyersAddressDetails, user=request.user, is_primary=True)
        serializer = self.get_serializer(address)
        return Response(serializer.data)

    @action(detail=True, methods=['post'])
    def set_primary(self, request, pk=None):
        """
        Set an address as primary
        """
        address = self.get_object()
        
        # Ensure the address belongs to the requesting user
        if address.user != request.user and not request.user.is_staff:
            return Response(
                {'detail': 'You do not have permission to perform this action.'},
                status=status.HTTP_403_FORBIDDEN
            )
        
        # Update all addresses to not be primary
        BuyersAddressDetails.objects.filter(user=address.user).update(is_primary=False)
        
        # Set this address as primary
        address.is_primary = True
        address.save()
        
        return Response({'detail': 'Address set as primary successfully.'}, status=status.HTTP_200_OK)
