import random
import string

from django.db.models import Q
from django_filters.rest_framework import DjangoFilterBackend
from rest_framework import status, permissions, filters, viewsets
from rest_framework.decorators import action
from rest_framework.pagination import PageNumberPagination
from rest_framework.permissions import IsAdminUser, IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView
from django.core.mail import send_mail
from django.conf import settings
from django.db import transaction
from django.utils import timezone

from otp.models import OTP
from .models import (
    Seller, SellerProfile, SellerVettingLog, CompanyInfo, 
    CompanyContactInfo, BankingInfo, BusinessRegistration
)

from .serializers import (
    SellerRegistrationSerializer, SellerBusinessRegistrationSerializer, SellerAddressSerializer,
    SellerBankAccountSerializer, SellerVettingSerializer, SellerProfileSerializer, BulkSellerApprovalSerializer,
    CompanyInfoSerializer, CompanyContactInfoSerializer, BankingInfoSerializer, BusinessRegistrationSerializer
)


class StandardResultsSetPagination(PageNumberPagination):
    """Standard pagination configuration."""
    page_size = 20
    page_size_query_param = 'page_size'
    max_page_size = 100


class IsOwnerOrReadOnly(permissions.BasePermission):
    """
    Custom permission to only allow owners of an object to edit it.
    """

    def has_object_permission(self, request, view, obj):
        # Read permissions for any request
        if request.method in permissions.SAFE_METHODS:
            return True

        # Write permissions only to the owner
        if hasattr(obj, 'user'):
            return obj.user == request.user
        elif hasattr(obj, 'buyer'):
            return obj.buyer == request.user
        elif hasattr(obj, 'seller'):
            return obj.seller.user == request.user

        return False


class SellerProfileViewSet(viewsets.ModelViewSet):
    """
    ViewSet for seller profile management.
    """
    queryset = SellerProfile.objects.filter(is_active=True)
    serializer_class = SellerProfileSerializer
    pagination_class = StandardResultsSetPagination
    permission_classes = [IsAuthenticated]
    filter_backends = [filters.SearchFilter, DjangoFilterBackend, filters.OrderingFilter]
    search_fields = ['seller__trading_name', 'seller__registered_company_name', 'vendor_id']
    filterset_fields = ['approval_status', 'background_check_passed']
    ordering_fields = ['average_rating', 'total_deals_completed', 'created_at']
    ordering = ['-average_rating', '-total_deals_completed']

    def get_queryset(self):
        """Filter queryset based on user permissions."""
        queryset = super().get_queryset().select_related('seller__user')

        # Non-admin user can only see approved sellers or their own profile
        if not self.request.user.is_staff:
            queryset = queryset.filter(
                Q(approval_status='approved') |
                Q(seller__user=self.request.user)
            )

        return queryset

    def get_permissions(self):
        """Set permissions based on action."""
        if self.action in ['create', 'update', 'partial_update']:
            permission_classes = [IsAuthenticated, IsOwnerOrReadOnly]
        elif self.action in ['approve_seller', 'reject_seller', 'bulk_approval']:
            permission_classes = [IsAdminUser]
        else:
            permission_classes = [IsAuthenticated]

        return [permission() for permission in permission_classes]

    @action(detail=True, methods=['post'], permission_classes=[IsAdminUser])
    def approve_seller(self, request, pk=None):
        """Approve a seller application."""
        seller_profile = self.get_object()

        if seller_profile.approval_status != 'pending':
            return Response(
                {'error': 'Seller is not in pending status'},
                status=status.HTTP_400_BAD_REQUEST
            )

        seller_profile.approval_status = 'approved'
        seller_profile.approved_at = timezone.now()
        seller_profile.save()

        return Response({'status': 'Seller approved successfully'})

    @action(detail=True, methods=['post'], permission_classes=[IsAdminUser])
    def reject_seller(self, request, pk=None):
        """Reject a seller application."""
        seller_profile = self.get_object()
        reason = request.data.get('reason', '')

        if seller_profile.approval_status != 'pending':
            return Response(
                {'error': 'Seller is not in pending status'},
                status=status.HTTP_400_BAD_REQUEST
            )

        seller_profile.approval_status = 'rejected'
        seller_profile.save()

        return Response({'status': 'Seller rejected successfully'})

    @action(detail=False, methods=['post'], permission_classes=[IsAdminUser])
    def bulk_approval(self, request):
        """Bulk approve/reject sellers."""
        serializer = BulkSellerApprovalSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(
                serializer.errors,
                status=status.HTTP_400_BAD_REQUEST
            )

        data = serializer.validated_data
        seller_profiles = SellerProfile.objects.filter(
            id__in=data['seller_ids'],
            approval_status='pending'
        )

        if data['action'] == 'approve':
            seller_profiles.update(
                approval_status='approved',
                approved_at=timezone.now()
            )
        elif data['action'] == 'reject':
            seller_profiles.update(approval_status='rejected')
        elif data['action'] == 'suspend':
            seller_profiles.update(approval_status='suspended')

        return Response({
            'status': f'{seller_profiles.count()} sellers {data["action"]}ed successfully'
        })

    @action(detail=True, methods=['get'])
    def performance_metrics(self, request, pk=None):
        """Get detailed performance metrics for a seller."""
        seller_profile = self.get_object()

        # Calculate metrics
        metrics = {
            'total_quotes_submitted': seller_profile.total_quotes_submitted,
            'total_deals_won': seller_profile.total_deals_won,
            'total_deals_completed': seller_profile.total_deals_completed,
            'win_rate': (
                (seller_profile.total_deals_won / seller_profile.total_quotes_submitted * 100)
                if seller_profile.total_quotes_submitted > 0 else 0
            ),
            'completion_rate': seller_profile.completion_rate,
            'average_rating': seller_profile.average_rating,
            'response_rate': seller_profile.response_rate_percentage,
        }

        return Response(metrics)


class SellerRegistrationView(APIView):
    """
    Seller registration endpoint (initial user creation).
    """
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        serializer = SellerRegistrationSerializer(data=request.data)
        if serializer.is_valid():
            user = serializer.save()

            # Generate OTP for email verification
            otp_code = "".join(random.choices(string.digits, k=6))
            OTP.objects.create(user=user, otp=otp_code)

            # Send OTP via email
            try:
                send_mail(
                    'Verify Your Account - BIDR',
                    f'Your verification code is: {otp_code}',
                    settings.DEFAULT_FROM_EMAIL,
                    [user.email],
                    fail_silently=False,
                )
            except Exception as e:
                # Log error but don't fail registration
                pass

            return Response({
                'message': 'Seller registered successfully. Please verify your email.',
                'user_id': user.id,
                'email': user.email
            }, status=status.HTTP_201_CREATED)

        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class SellerBusinessRegistrationView(APIView):
    """
    Multi-step seller business registration
    """
    permission_classes = [permissions.IsAuthenticated]

    @transaction.atomic
    def post(self, request):
        user = request.user

        # Ensure user has seller role
        if user.role != 'seller':
            return Response({
                'error': 'Only sellers can register business details'
            }, status=status.HTTP_403_FORBIDDEN)

        # Step 1: Company Details
        company_data = request.data.get('company_details', {})
        if company_data:
            seller, created = Seller.objects.get_or_create(user=user)
            company_serializer = SellerBusinessRegistrationSerializer(seller, data=company_data, partial=True)
            if company_serializer.is_valid():
                company_serializer.save()
            else:
                return Response(company_serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        # Step 2: Address Details
        address_data = request.data.get('address_details', {})
        if address_data:
            address_serializer = SellerAddressSerializer(data=address_data)
            if address_serializer.is_valid():
                address = address_serializer.save(user=seller)
            else:
                return Response(address_serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        # Step 3: Bank Account Details
        bank_data = request.data.get('bank_details', {})
        if bank_data:
            bank_serializer = SellerBankAccountSerializer(data=bank_data)
            if bank_serializer.is_valid():
                bank_serializer.save(user=user)
            else:
                return Response(bank_serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        return Response({
            'message': 'Business registration completed successfully'
        }, status=status.HTTP_201_CREATED)


class SellerDocumentUploadView(APIView):
    """
    Seller document upload for vetting
    """
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        user = request.user

        if user.role != 'seller':
            return Response({
                'error': 'Only sellers can upload documents'
            }, status=status.HTTP_403_FORBIDDEN)

        try:
            seller = Seller.objects.get(user=user)
            vetting_log, created = SellerVettingLog.objects.get_or_create(seller=seller)

            serializer = SellerVettingSerializer(vetting_log, data=request.data, partial=True)
            if serializer.is_valid():
                serializer.save()
                return Response({
                    'message': 'Documents uploaded successfully'
                }, status=status.HTTP_200_OK)

            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        except Seller.DoesNotExist:
            return Response({
                'error': 'Seller profile not found'
            }, status=status.HTTP_404_NOT_FOUND)


class DocumentVettingView(APIView):
    """
    Admin endpoint for document vetting
    """
    permission_classes = [permissions.IsAuthenticated]

    def get_permissions(self):
        """
        Only admins can access this view
        """
        if self.request.user.role != 'administrator':
            self.permission_denied(
                self.request,
                message="Only administrators can perform document vetting"
            )
        return super().get_permissions()

    def get(self, request):
        """
        Get all pending documents for vetting
        """
        pending_documents = SellerVettingLog.objects.filter(
            certificate_of_incorporation_status='pending'
        ).select_related('seller__user')

        data = []
        for doc in pending_documents:
            data.append({
                'id': doc.id,
                'seller_email': doc.seller.user.email,
                'seller_name': doc.seller.user.first_name + ' ' + doc.seller.user.last_name,
                'company_name': doc.seller.registered_company_name,
                'documents': doc.document_status_summary(),
                'created_at': doc.created_at
            })

        return Response(data, status=status.HTTP_200_OK)

    def patch(self, request, vetting_id):
        """
        Update document vetting status
        """
        try:
            vetting_log = SellerVettingLog.objects.get(id=vetting_id)

            # Update document statuses
            for field, value in request.data.items():
                if hasattr(vetting_log, field) and field.endswith('_status'):
                    setattr(vetting_log, field, value)

            vetting_log.save()

            # Check if all documents are approved
            if vetting_log.all_documents_approved():
                seller = vetting_log.seller
                seller.user.is_verified = True
                seller.user.save(update_fields=['is_verified'])

                # Send approval email
                try:
                    send_mail(
                        'Business Verification Approved - BIDR',
                        'Congratulations! Your business has been verified and approved.',
                        settings.DEFAULT_FROM_EMAIL,
                        [seller.user.email],
                        fail_silently=False,
                    )
                except Exception as e:
                    pass

            return Response({
                'message': 'Document status updated successfully'
            }, status=status.HTTP_200_OK)

        except SellerVettingLog.DoesNotExist:
            return Response({
                'error': 'Vetting log not found'
            }, status=status.HTTP_404_NOT_FOUND)