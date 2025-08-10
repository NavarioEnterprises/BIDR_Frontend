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

# Import the helper and set up the path
import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from import_helper import setup_imports
setup_imports()

# Now we can import from any app in the project
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

# Import security, logging, and API management components
from security.utils import SecurityUtils
from security.models import SecurityAuditLog, APIKey
from auth_logs.models import AuthenticationLog, SecurityEvent, AuditTrail
from api_management.models import APIRequest, RateLimitBucket


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
    
    # Initialize security utils
    security_utils = SecurityUtils()

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
        
    def dispatch(self, request, *args, **kwargs):
        """
        Override dispatch to add security checks and logging.
        """
        # Log the API request
        APIRequest.objects.create(
            user=request.user if request.user.is_authenticated else None,
            endpoint=request.path,
            method=request.method,
            ip_address=request.META.get('REMOTE_ADDR', ''),
            user_agent=request.META.get('HTTP_USER_AGENT', ''),
            request_data=str(request.data) if hasattr(request, 'data') else '',
            status_code=200  # Will be updated in the response
        )
        
        # Check for rate limiting
        ip_address = request.META.get('REMOTE_ADDR', '')
        rate_limit_bucket, created = RateLimitBucket.objects.get_or_create(
            ip_address=ip_address,
            defaults={'request_count': 0}
        )
        
        if rate_limit_bucket.is_rate_limited(100):  # Limit to 100 requests per bucket period
            # Log the rate limiting event
            SecurityEvent.objects.create(
                user=request.user if request.user.is_authenticated else None,
                event_type='RATE_LIMIT_EXCEEDED',
                ip_address=ip_address,
                details=f"Rate limit exceeded for IP: {ip_address}"
            )
            return Response(
                {"error": "Rate limit exceeded. Please try again later."},
                status=status.HTTP_429_TOO_MANY_REQUESTS
            )
            
        # Add request to rate limit bucket
        rate_limit_bucket.add_request()
        
        # Log authentication
        if request.user.is_authenticated:
            AuthenticationLog.objects.create(
                user=request.user,
                ip_address=ip_address,
                user_agent=request.META.get('HTTP_USER_AGENT', ''),
                action='API_ACCESS',
                status='SUCCESS',
                details=f"Accessed seller profile API: {request.path}"
            )
            
        return super().dispatch(request, *args, **kwargs)

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
    
    # Initialize security utils
    security_utils = SecurityUtils()

    def post(self, request):
        # Log the API request
        api_request = APIRequest.objects.create(
            user=None,  # User not authenticated yet
            endpoint=request.path,
            method=request.method,
            ip_address=request.META.get('REMOTE_ADDR', ''),
            user_agent=request.META.get('HTTP_USER_AGENT', ''),
            request_data=str(request.data) if hasattr(request, 'data') else '',
            status_code=200  # Will be updated in the response
        )
        
        # Check for rate limiting to prevent registration abuse
        ip_address = request.META.get('REMOTE_ADDR', '')
        rate_limit_bucket, created = RateLimitBucket.objects.get_or_create(
            ip_address=ip_address,
            defaults={'request_count': 0}
        )
        
        if rate_limit_bucket.is_rate_limited(10):  # Stricter limit for registration
            # Log the rate limiting event
            SecurityEvent.objects.create(
                user=None,
                event_type='REGISTRATION_RATE_LIMIT_EXCEEDED',
                ip_address=ip_address,
                details=f"Registration rate limit exceeded for IP: {ip_address}"
            )
            
            # Update API request status
            api_request.status_code = status.HTTP_429_TOO_MANY_REQUESTS
            api_request.response_data = "Rate limit exceeded for registration"
            api_request.save()
            
            return Response({
                "error": "Too many registration attempts. Please try again later."
            }, status=status.HTTP_429_TOO_MANY_REQUESTS)
            
        # Add request to rate limit bucket
        rate_limit_bucket.add_request()
        
        serializer = SellerRegistrationSerializer(data=request.data)
        if serializer.is_valid():
            # Validate password strength
            password = request.data.get('password', '')
            password_validation = self.security_utils.validate_password_strength(password)
            if not password_validation['valid']:
                # Log the security event
                SecurityEvent.objects.create(
                    user=None,
                    event_type='WEAK_PASSWORD_ATTEMPT',
                    ip_address=ip_address,
                    details=f"Weak password attempt: {password_validation['message']}"
                )
                
                # Update API request status
                api_request.status_code = status.HTTP_400_BAD_REQUEST
                api_request.response_data = password_validation['message']
                api_request.save()
                
                return Response({
                    'error': password_validation['message']
                }, status=status.HTTP_400_BAD_REQUEST)
            
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
                SecurityEvent.objects.create(
                    user=user,
                    event_type='EMAIL_SEND_FAILURE',
                    ip_address=ip_address,
                    details=f"Failed to send verification email: {str(e)}"
                )
            
            # Log successful registration
            AuthenticationLog.objects.create(
                user=user,
                ip_address=ip_address,
                user_agent=request.META.get('HTTP_USER_AGENT', ''),
                action='REGISTRATION',
                status='SUCCESS',
                details=f"Seller registered successfully"
            )
            
            # Create audit trail
            AuditTrail.objects.create(
                user=user,
                action='USER_CREATED',
                ip_address=ip_address,
                details=f"Seller account created"
            )
            
            # Update API request status
            api_request.status_code = status.HTTP_201_CREATED
            api_request.user = user
            api_request.response_data = "Registration successful"
            api_request.save()

            return Response({
                'message': 'Seller registered successfully. Please verify your email.',
                'user_id': user.id,
                'email': user.email
            }, status=status.HTTP_201_CREATED)

        # Log failed registration attempt
        SecurityEvent.objects.create(
            user=None,
            event_type='REGISTRATION_FAILURE',
            ip_address=ip_address,
            details=f"Registration failed: {serializer.errors}"
        )
        
        # Update API request status
        api_request.status_code = status.HTTP_400_BAD_REQUEST
        api_request.response_data = str(serializer.errors)
        api_request.save()

        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class SellerBusinessRegistrationView(APIView):
    """
    Multi-step seller business registration
    """
    permission_classes = [permissions.IsAuthenticated]
    
    # Initialize security utils
    security_utils = SecurityUtils()

    @transaction.atomic
    def post(self, request):
        user = request.user
        ip_address = request.META.get('REMOTE_ADDR', '')
        
        # Log the API request
        api_request = APIRequest.objects.create(
            user=user,
            endpoint=request.path,
            method=request.method,
            ip_address=ip_address,
            user_agent=request.META.get('HTTP_USER_AGENT', ''),
            request_data=str(request.data) if hasattr(request, 'data') else '',
            status_code=200  # Will be updated in the response
        )
        
        # Check for rate limiting
        rate_limit_bucket, created = RateLimitBucket.objects.get_or_create(
            ip_address=ip_address,
            defaults={'request_count': 0}
        )
        
        if rate_limit_bucket.is_rate_limited(20):  # Limit for business registration
            # Log the rate limiting event
            SecurityEvent.objects.create(
                user=user,
                event_type='BUSINESS_REG_RATE_LIMIT_EXCEEDED',
                ip_address=ip_address,
                details=f"Business registration rate limit exceeded for user: {user.email}"
            )
            
            # Update API request status
            api_request.status_code = status.HTTP_429_TOO_MANY_REQUESTS
            api_request.response_data = "Rate limit exceeded for business registration"
            api_request.save()
            
            return Response({
                "error": "Too many registration attempts. Please try again later."
            }, status=status.HTTP_429_TOO_MANY_REQUESTS)
            
        # Add request to rate limit bucket
        rate_limit_bucket.add_request()

        # Ensure user has seller role
        if user.role != 'seller':
            # Log unauthorized access attempt
            SecurityEvent.objects.create(
                user=user,
                event_type='UNAUTHORIZED_BUSINESS_REG_ATTEMPT',
                ip_address=ip_address,
                details=f"Non-seller user attempted business registration: {user.email}"
            )
            
            # Update API request status
            api_request.status_code = status.HTTP_403_FORBIDDEN
            api_request.response_data = "Only sellers can register business details"
            api_request.save()
            
            return Response({
                'error': 'Only sellers can register business details'
            }, status=status.HTTP_403_FORBIDDEN)

        # Create audit trail for business registration attempt
        AuditTrail.objects.create(
            user=user,
            action='BUSINESS_REGISTRATION_STARTED',
            ip_address=ip_address,
            details=f"Business registration process started"
        )

        # Step 1: Company Details
        company_data = request.data.get('company_details', {})
        if company_data:
            # Secure sensitive company data
            secured_company_data = self.security_utils.secure_user_data(company_data)
            
            seller, created = Seller.objects.get_or_create(user=user)
            company_serializer = SellerBusinessRegistrationSerializer(seller, data=secured_company_data, partial=True)
            if company_serializer.is_valid():
                company_serializer.save()
                
                # Log successful company details update
                AuditTrail.objects.create(
                    user=user,
                    action='COMPANY_DETAILS_UPDATED',
                    ip_address=ip_address,
                    details=f"Company details updated for seller: {user.email}"
                )
            else:
                # Log validation error
                SecurityEvent.objects.create(
                    user=user,
                    event_type='BUSINESS_REG_VALIDATION_ERROR',
                    ip_address=ip_address,
                    details=f"Company details validation error: {company_serializer.errors}"
                )
                
                # Update API request status
                api_request.status_code = status.HTTP_400_BAD_REQUEST
                api_request.response_data = str(company_serializer.errors)
                api_request.save()
                
                return Response(company_serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        # Step 2: Address Details
        address_data = request.data.get('address_details', {})
        if address_data:
            # Secure sensitive address data
            secured_address_data = self.security_utils.secure_user_data(address_data)
            
            address_serializer = SellerAddressSerializer(data=secured_address_data)
            if address_serializer.is_valid():
                address = address_serializer.save(user=seller)
                
                # Log successful address details update
                AuditTrail.objects.create(
                    user=user,
                    action='ADDRESS_DETAILS_UPDATED',
                    ip_address=ip_address,
                    details=f"Address details updated for seller: {user.email}"
                )
            else:
                # Log validation error
                SecurityEvent.objects.create(
                    user=user,
                    event_type='BUSINESS_REG_VALIDATION_ERROR',
                    ip_address=ip_address,
                    details=f"Address details validation error: {address_serializer.errors}"
                )
                
                # Update API request status
                api_request.status_code = status.HTTP_400_BAD_REQUEST
                api_request.response_data = str(address_serializer.errors)
                api_request.save()
                
                return Response(address_serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        # Step 3: Bank Account Details
        bank_data = request.data.get('bank_details', {})
        if bank_data:
            # Secure sensitive bank data
            secured_bank_data = self.security_utils.secure_user_data(bank_data)
            
            bank_serializer = SellerBankAccountSerializer(data=secured_bank_data)
            if bank_serializer.is_valid():
                bank_serializer.save(user=user)
                
                # Log successful bank details update
                AuditTrail.objects.create(
                    user=user,
                    action='BANK_DETAILS_UPDATED',
                    ip_address=ip_address,
                    details=f"Bank details updated for seller: {user.email}"
                )
            else:
                # Log validation error
                SecurityEvent.objects.create(
                    user=user,
                    event_type='BUSINESS_REG_VALIDATION_ERROR',
                    ip_address=ip_address,
                    details=f"Bank details validation error: {bank_serializer.errors}"
                )
                
                # Update API request status
                api_request.status_code = status.HTTP_400_BAD_REQUEST
                api_request.response_data = str(bank_serializer.errors)
                api_request.save()
                
                return Response(bank_serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        # Log successful business registration
        SecurityAuditLog.objects.create(
            user=user,
            action='BUSINESS_REGISTRATION_COMPLETED',
            ip_address=ip_address,
            details=f"Business registration completed successfully for seller: {user.email}"
        )
        
        # Update API request status
        api_request.status_code = status.HTTP_201_CREATED
        api_request.response_data = "Business registration completed successfully"
        api_request.save()

        return Response({
            'message': 'Business registration completed successfully'
        }, status=status.HTTP_201_CREATED)


class SellerDocumentUploadView(APIView):
    """
    Seller document upload for vetting
    """
    permission_classes = [permissions.IsAuthenticated]
    
    # Initialize security utils
    security_utils = SecurityUtils()

    def post(self, request):
        user = request.user
        ip_address = request.META.get('REMOTE_ADDR', '')
        
        # Log the API request
        api_request = APIRequest.objects.create(
            user=user,
            endpoint=request.path,
            method=request.method,
            ip_address=ip_address,
            user_agent=request.META.get('HTTP_USER_AGENT', ''),
            request_data="Document upload request",  # Don't log actual document data for security
            status_code=200  # Will be updated in the response
        )
        
        # Check for rate limiting
        rate_limit_bucket, created = RateLimitBucket.objects.get_or_create(
            ip_address=ip_address,
            defaults={'request_count': 0}
        )
        
        if rate_limit_bucket.is_rate_limited(15):  # Limit for document uploads
            # Log the rate limiting event
            SecurityEvent.objects.create(
                user=user,
                event_type='DOCUMENT_UPLOAD_RATE_LIMIT_EXCEEDED',
                ip_address=ip_address,
                details=f"Document upload rate limit exceeded for user: {user.email}"
            )
            
            # Update API request status
            api_request.status_code = status.HTTP_429_TOO_MANY_REQUESTS
            api_request.response_data = "Rate limit exceeded for document uploads"
            api_request.save()
            
            return Response({
                "error": "Too many document upload attempts. Please try again later."
            }, status=status.HTTP_429_TOO_MANY_REQUESTS)
            
        # Add request to rate limit bucket
        rate_limit_bucket.add_request()

        if user.role != 'seller':
            # Log unauthorized access attempt
            SecurityEvent.objects.create(
                user=user,
                event_type='UNAUTHORIZED_DOCUMENT_UPLOAD_ATTEMPT',
                ip_address=ip_address,
                details=f"Non-seller user attempted document upload: {user.email}"
            )
            
            # Update API request status
            api_request.status_code = status.HTTP_403_FORBIDDEN
            api_request.response_data = "Only sellers can upload documents"
            api_request.save()
            
            return Response({
                'error': 'Only sellers can upload documents'
            }, status=status.HTTP_403_FORBIDDEN)

        try:
            seller = Seller.objects.get(user=user)
            vetting_log, created = SellerVettingLog.objects.get_or_create(seller=seller)
            
            # Log document upload attempt
            AuditTrail.objects.create(
                user=user,
                action='DOCUMENT_UPLOAD_STARTED',
                ip_address=ip_address,
                details=f"Document upload process started for seller: {user.email}"
            )

            # Validate document types and sizes
            # This is a simplified example - in a real implementation, you would check file types,
            # scan for malware, validate file sizes, etc.
            for key, file in request.FILES.items():
                if file.size > 10 * 1024 * 1024:  # 10MB limit
                    # Log security event for oversized file
                    SecurityEvent.objects.create(
                        user=user,
                        event_type='OVERSIZED_FILE_UPLOAD_ATTEMPT',
                        ip_address=ip_address,
                        details=f"User attempted to upload oversized file: {file.name}, size: {file.size} bytes"
                    )
                    
                    # Update API request status
                    api_request.status_code = status.HTTP_400_BAD_REQUEST
                    api_request.response_data = "File size exceeds maximum allowed (10MB)"
                    api_request.save()
                    
                    return Response({
                        'error': f'File {file.name} exceeds maximum allowed size of 10MB'
                    }, status=status.HTTP_400_BAD_REQUEST)
                
                # Check file extension (basic security check)
                allowed_extensions = ['.pdf', '.jpg', '.jpeg', '.png', '.doc', '.docx']
                file_ext = os.path.splitext(file.name)[1].lower()
                if file_ext not in allowed_extensions:
                    # Log security event for disallowed file type
                    SecurityEvent.objects.create(
                        user=user,
                        event_type='DISALLOWED_FILE_TYPE_UPLOAD_ATTEMPT',
                        ip_address=ip_address,
                        details=f"User attempted to upload disallowed file type: {file.name}, type: {file_ext}"
                    )
                    
                    # Update API request status
                    api_request.status_code = status.HTTP_400_BAD_REQUEST
                    api_request.response_data = f"File type {file_ext} is not allowed"
                    api_request.save()
                    
                    return Response({
                        'error': f'File type {file_ext} is not allowed. Allowed types: {", ".join(allowed_extensions)}'
                    }, status=status.HTTP_400_BAD_REQUEST)

            serializer = SellerVettingSerializer(vetting_log, data=request.data, partial=True)
            if serializer.is_valid():
                serializer.save()
                
                # Log successful document upload
                SecurityAuditLog.objects.create(
                    user=user,
                    action='DOCUMENT_UPLOAD_COMPLETED',
                    ip_address=ip_address,
                    details=f"Documents uploaded successfully for seller: {user.email}"
                )
                
                # Update API request status
                api_request.status_code = status.HTTP_200_OK
                api_request.response_data = "Documents uploaded successfully"
                api_request.save()
                
                return Response({
                    'message': 'Documents uploaded successfully'
                }, status=status.HTTP_200_OK)

            # Log validation error
            SecurityEvent.objects.create(
                user=user,
                event_type='DOCUMENT_UPLOAD_VALIDATION_ERROR',
                ip_address=ip_address,
                details=f"Document upload validation error: {serializer.errors}"
            )
            
            # Update API request status
            api_request.status_code = status.HTTP_400_BAD_REQUEST
            api_request.response_data = str(serializer.errors)
            api_request.save()
            
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
            
        except Seller.DoesNotExist:
            # Log error
            SecurityEvent.objects.create(
                user=user,
                event_type='SELLER_PROFILE_NOT_FOUND',
                ip_address=ip_address,
                details=f"Seller profile not found for user: {user.email}"
            )
            
            # Update API request status
            api_request.status_code = status.HTTP_404_NOT_FOUND
            api_request.response_data = "Seller profile not found"
            api_request.save()
            
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