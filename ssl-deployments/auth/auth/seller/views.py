import random
import string

from django.db.models import Q
from django_filters.rest_framework import DjangoFilterBackend
from rest_framework import status, permissions, filters, viewsets
from rest_framework.decorators import action
from rest_framework.pagination import PageNumberPagination
from rest_framework.permissions import IsAdminUser, AllowAny
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
from user.models import AppUser
from otp.models import OTP
from auth_logs.models import AuthenticationLog, SecurityEvent, AuditTrail
from .models import (
    Seller, SellerProfile, SellerVettingLog, CompanyInfo, 
    CompanyContactInfo, BankingInfo, BusinessRegistration, SellersAddressDetails
)

from .serializers import (
    SellerRegistrationSerializer, SellerBusinessRegistrationSerializer, SellerAddressSerializer,
    SellerBankAccountSerializer, SellerVettingSerializer, SellerProfileSerializer, BulkSellerApprovalSerializer,
    CompanyInfoSerializer, CompanyContactInfoSerializer, BankingInfoSerializer, BusinessRegistrationSerializer
)

# Import required models and utilities
from security.utils import SecurityUtils
from .utils import reverse_geocode, format_location_with_address


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
    permission_classes = [AllowAny]
    filter_backends = [filters.SearchFilter, DjangoFilterBackend, filters.OrderingFilter]
    search_fields = ['seller__trading_name', 'seller__registered_company_name', 'vendor_id']
    filterset_fields = ['approval_status', 'background_check_passed']
    ordering_fields = ['average_rating', 'total_deals_completed', 'created_at']
    ordering = ['-average_rating', '-total_deals_completed']
    
    # Initialize security utils
    security_utils = SecurityUtils()

    def get_queryset(self):
        """Filter queryset based on user permissions."""
        # Handle schema generation
        if getattr(self, 'swagger_fake_view', False):
            return SellerProfile.objects.none()
        
        queryset = super().get_queryset().select_related('seller__user')

        # Non-admin users: anonymous users only see approved sellers; authenticated users can also see their own
        user = getattr(self.request, 'user', None)
        if user and not user.is_staff:
            if getattr(user, 'is_authenticated', False):
                queryset = queryset.filter(
                    Q(approval_status='approved') |
                    Q(seller__user=user)
                )
            else:
                queryset = queryset.filter(approval_status='approved')

        return queryset

    def get_permissions(self):
        """Set permissions based on action."""
        if self.action in ['create', 'update', 'partial_update']:
            permission_classes = [AllowAny, IsOwnerOrReadOnly]
        elif self.action in ['approve_seller', 'reject_seller', 'bulk_approval']:
            permission_classes = [IsAdminUser]
        else:
            permission_classes = [AllowAny]

        return [permission() for permission in permission_classes]
        
    # Remove problematic dispatch method for now
    pass

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

    @action(detail=False, methods=['get'], url_path='by-auth-user-uid/(?P<auth_user_uid>[^/.]+)')
    def by_auth_user_uid(self, request, auth_user_uid=None):
        """Get seller information by auth_user_uid (AppUser UID)."""
        try:
            # Find the AppUser by UID
            app_user = AppUser.objects.get(uid=auth_user_uid)
            
            # Get the seller by the linked AppUser
            seller = Seller.objects.select_related('user').get(user=app_user)
            
            # Try to get seller's address details if they exist
            address_details = None
            try:
                # Get the primary address or any address for the seller
                address_details = seller.sellers_address_details.filter(is_primary=True).first()
                if not address_details:
                    address_details = seller.sellers_address_details.first()
            except Exception:
                pass
            
            # Build response data with decrypted names and full AppUser info
            seller_data = {
                # AppUser information (decrypted)
                'auth_user_uid': str(app_user.uid),
                'email': app_user.email,
                'first_name': app_user.get_decrypted_first_name(),
                'last_name': app_user.get_decrypted_last_name(),
                'middle_name': app_user.get_decrypted_middle_name(),
                'phone_number': app_user.get_decrypted_phone_number(),
                'alternative_phone': app_user.get_decrypted_alternative_phone(),
                'alternative_email': app_user.alternative_email,
                'date_of_birth': app_user.get_decrypted_date_of_birth(),
                'gender': app_user.gender,
                'nationality': app_user.nationality,
                'occupation': app_user.occupation,
                'company_name': app_user.company_name,
                'profile_picture': str(app_user.profile_picture) if app_user.profile_picture else None,
                'bio': app_user.bio,
                'website': app_user.website,
                'linkedin_profile': app_user.linkedin_profile,
                'preferred_language': app_user.preferred_language,
                'user_timezone': app_user.user_timezone,
                'currency_preference': app_user.currency_preference,
                'email_notifications': app_user.email_notifications,
                'sms_notifications': app_user.sms_notifications,
                'push_notifications': app_user.push_notifications,
                'marketing_emails': app_user.marketing_emails,
                'profile_visibility': app_user.profile_visibility,
                'show_email': app_user.show_email,
                'show_phone': app_user.show_phone,
                'email_verified': app_user.email_verified,
                'phone_verified': app_user.phone_verified,
                'profile_status': app_user.profile_status,
                'role': app_user.role,
                'otp_type': app_user.otp_type,
                'is_staff': app_user.is_staff,
                'is_superuser': app_user.is_superuser,
                'is_active': app_user.is_active,
                'is_verified': app_user.is_verified,
                'is_suspended': app_user.is_suspended,
                'date_joined': app_user.date_joined,
                'user_created_at': app_user.created_at,
                'user_updated_at': app_user.updated_at,
                
                # Seller information
                'registered_company_name': seller.registered_company_name,
                'trading_name': seller.trading_name,
                'registration_number': seller.registration_number,
                'vat_number': seller.vat_number,
                'website_url': seller.website_url,
                'product_category': seller.product_category,
                'product_subcategory': seller.product_subcategory,
                'seller_created_at': seller.created_at,
                'seller_updated_at': seller.updated_at,
            }
            
            # Add address details if available
            if address_details:
                seller_data.update({
                    'postal_address': address_details.postal_address,
                    'physical_address': address_details.physical_address,
                    'contact_person_name': address_details.contact_person_name,
                    'contact_person_telephone': address_details.contact_person_telephone,
                    'contact_person_email': address_details.contact_person_email_address,
                    'platform_workflow_email': address_details.platform_workflow_email_address,
                    'latitude': address_details.latitude,
                    'longitude': address_details.longitude,
                    'city': address_details.city,
                    'province': address_details.province,
                    'postal_code': address_details.postal_code,
                    'country': address_details.country,
                })
            
            # Try to get seller profile if it exists
            try:
                seller_profile = SellerProfile.objects.get(seller=seller)
                seller_data.update({
                    'approval_status': seller_profile.approval_status,
                    'vendor_id': seller_profile.vendor_id,
                    'average_rating': seller_profile.average_rating,
                    'total_quotes_submitted': seller_profile.total_quotes_submitted,
                    'total_deals_won': seller_profile.total_deals_won,
                    'total_deals_completed': seller_profile.total_deals_completed,
                    'response_rate_percentage': seller_profile.response_rate_percentage,
                })
            except SellerProfile.DoesNotExist:
                # Add default values if no profile exists
                seller_data.update({
                    'approval_status': 'pending',
                    'vendor_id': None,
                    'average_rating': None,
                    'total_quotes_submitted': 0,
                    'total_deals_won': 0,
                    'total_deals_completed': 0,
                    'response_rate_percentage': 0.0,
                })
            
            return Response(seller_data, status=status.HTTP_200_OK)
            
        except AppUser.DoesNotExist:
            return Response({
                'error': 'AppUser with the given auth_user_uid not found'
            }, status=status.HTTP_404_NOT_FOUND)
        except Seller.DoesNotExist:
            return Response({
                'error': 'Seller profile not found for the given auth_user_uid'
            }, status=status.HTTP_404_NOT_FOUND)
        except Exception as e:
            return Response({
                'error': f'An error occurred: {str(e)}'
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
    
    @action(detail=False, methods=['patch'], url_path='update-by-auth-user-uid/(?P<auth_user_uid>[^/.]+)')
    def update_by_auth_user_uid(self, request, auth_user_uid=None):
        """Update seller information by auth_user_uid."""
        try:
            # Find the AppUser by UID
            app_user = AppUser.objects.get(uid=auth_user_uid)
            
            # Get the seller by the linked AppUser
            seller = Seller.objects.select_related('user').get(user=app_user)
            
            # Update seller basic information
            data = request.data
            
            # Update seller fields if provided
            if 'registered_company_name' in data:
                seller.registered_company_name = data['registered_company_name']
            if 'trading_name' in data:
                seller.trading_name = data['trading_name']
            if 'registration_number' in data:
                seller.registration_number = data['registration_number']
            if 'vat_number' in data:
                seller.vat_number = data['vat_number']
            if 'website_url' in data:
                seller.website_url = data['website_url']
            if 'product_category' in data:
                seller.product_category = data['product_category']
            if 'product_subcategory' in data:
                seller.product_subcategory = data['product_subcategory']
            
            seller.save()
            
            # Update AppUser fields if provided
            user_updated = False
            if 'first_name' in data:
                app_user.first_name = data['first_name']
                user_updated = True
            if 'last_name' in data:
                app_user.last_name = data['last_name']
                user_updated = True
            if 'email' in data:
                app_user.email = data['email']
                user_updated = True
            if 'phone_number' in data:
                app_user.phone_number = data['phone_number']
                user_updated = True
                
            if user_updated:
                app_user.save()
            
            # Update or create address details if provided
            address_data = {}
            if 'postal_address' in data:
                address_data['postal_address'] = data['postal_address']
            if 'physical_address' in data:
                address_data['physical_address'] = data['physical_address']
            if 'contact_person_name' in data:
                address_data['contact_person_name'] = data['contact_person_name']
            if 'contact_person_telephone' in data:
                address_data['contact_person_telephone'] = data['contact_person_telephone']
            if 'contact_person_email' in data:
                address_data['contact_person_email_address'] = data['contact_person_email']
            if 'platform_workflow_email' in data:
                address_data['platform_workflow_email_address'] = data['platform_workflow_email']
            
            if address_data:
                address_details, created = SellersAddressDetails.objects.get_or_create(
                    user=seller,  # The field name is 'user' but it references Seller model
                    defaults={**address_data, 'is_primary': True}
                )
                if not created:
                    for key, value in address_data.items():
                        setattr(address_details, key, value)
                    address_details.save()
            
            # Return success response
            return Response({
                'message': 'Seller information updated successfully',
                'updated_fields': list(data.keys())
            }, status=status.HTTP_200_OK)
            
        except AppUser.DoesNotExist:
            return Response({
                'error': 'AppUser with the given auth_user_uid not found'
            }, status=status.HTTP_404_NOT_FOUND)
        except Seller.DoesNotExist:
            return Response({
                'error': 'Seller profile not found for the given auth_user_uid'
            }, status=status.HTTP_404_NOT_FOUND)
        except Exception as e:
            return Response({
                'error': f'An error occurred: {str(e)}'
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


class SellerRegistrationView(APIView):
    """
    Seller registration endpoint (initial user creation).
    """
    permission_classes = [permissions.AllowAny]
    
    # Initialize security utils
    security_utils = SecurityUtils()

    def post(self, request):
        serializer = SellerRegistrationSerializer(data=request.data)
        if serializer.is_valid():
            # Basic password validation (without security utils for now)
            password = request.data.get('password', '')
            if len(password) < 8:
                return Response({
                    'error': 'Password must be at least 8 characters long'
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
                # Don't fail registration if email fails
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
    permission_classes = [permissions.AllowAny]
    
    # Initialize security utils
    security_utils = SecurityUtils()

    @transaction.atomic
    def post(self, request):
        app_user_id = request.data.get('auth_user_id', {})
        if not app_user_id:
            return Response({
                'error': 'Authentication user not provided'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        try:
            user = AppUser.objects.get(uid=app_user_id)
        except AppUser.DoesNotExist:
            return Response({
                'error': 'Invalid user ID'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        ip_address = request.META.get('REMOTE_ADDR', '')
        
        # Log the business registration attempt
        auth_log = AuthenticationLog.objects.create(
            user_email=user.email,
            user_id=user.id,
            user_type='business_seller',
            action='seller_verification',
            status='pending',
            ip_address=ip_address,
            user_agent=request.META.get('HTTP_USER_AGENT', ''),
            endpoint=request.path,
            method=request.method,
            response_code=200  # Will be updated later
        )
        
        # Basic rate limiting can be implemented here if needed
        # For now, we'll skip complex rate limiting and rely on Django's built-in protections

        # Ensure user has seller role
        if user.role != 'seller':
            # Log unauthorized access attempt
            SecurityEvent.objects.create(
                user_email=user.email,
                event_type='privilege_escalation',
                title='Unauthorized Business Registration Attempt',
                description=f"Non-seller user attempted business registration: {user.email}",
                ip_address=ip_address,
                user_agent=request.META.get('HTTP_USER_AGENT', ''),
                severity='medium'
            )
            
            # Update auth log status
            auth_log.status = 'failed'
            auth_log.response_code = status.HTTP_403_FORBIDDEN
            auth_log.error_message = "Only sellers can register business details"
            auth_log.save()
            
            return Response({
                'error': 'Only sellers can register business details'
            }, status=status.HTTP_403_FORBIDDEN)

        # Log successful authorization
        auth_log.details = {'step': 'authorization_passed', 'user_role': user.role}

        # Step 1: Seller Details
        seller_data = request.data.get('seller', {})
        if seller_data:
            # Transform product_subcategory display value to choice key
            if 'product_subcategory' in seller_data:
                display_to_key = {
                    'Engine Parts': 'engine_parts',
                    'Engines Parts': 'engine_parts',  # Handle both variants
                    'Body Parts': 'body_parts', 
                    'Suspension Parts': 'suspension_parts',
                    'Transmission Parts': 'transmission_parts',
                    'Batteries': 'batteries'
                }
                subcategory = seller_data['product_subcategory']
                if subcategory in display_to_key:
                    seller_data['product_subcategory'] = display_to_key[subcategory]
            
            # Handle invalid website URL by setting to None if not a valid URL
            if 'website_url' in seller_data and seller_data['website_url']:
                url = seller_data['website_url']
                if not url.startswith(('http://', 'https://')):
                    # Invalid URL format, set to None
                    seller_data['website_url'] = None
            
            # Secure sensitive seller data
            secured_seller_data = self.security_utils.secure_user_data(seller_data)
            
            seller, created = Seller.objects.get_or_create(user=user)
            company_serializer = SellerBusinessRegistrationSerializer(seller, data=secured_seller_data, partial=True)
            if company_serializer.is_valid():
                company_serializer.save()
                
                # Log successful company details update
                AuditTrail.objects.create(
                    admin_email=user.email,
                    action='user_updated',
                    ip_address=ip_address,
                    user_agent=request.META.get('HTTP_USER_AGENT', ''),
                    description=f"Company details updated for seller: {user.email}"
                )
            else:
                # Log validation error
                SecurityEvent.objects.create(
                    user_email=user.email,
                    event_type='data_breach_attempt',
                    title='Company Details Validation Error',
                    description=f"Company details validation error: {company_serializer.errors}"
                )
                
                # Update auth log status
                auth_log.status = 'failed'
                auth_log.response_code = status.HTTP_400_BAD_REQUEST
                auth_log.error_message = str(company_serializer.errors)
                auth_log.save()
                
                return Response(company_serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        # Ensure seller exists (fallback if not created in Step 1)
        if 'seller' not in locals():
            seller, created = Seller.objects.get_or_create(user=user)

        # Step 2: Contact/Address Details  
        address_data = request.data.get('contact_info', {})
        if address_data:
            # Map field names to match model expectations
            if 'contact_person_email' in address_data:
                address_data['contact_person_email_address'] = address_data.pop('contact_person_email')
            if 'platform_workflow_email' in address_data:
                address_data['platform_workflow_email_address'] = address_data.pop('platform_workflow_email')
            
            # Convert coordinates to address if coordinates are provided but no physical address
            if (address_data.get('latitude') and address_data.get('longitude') and 
                not address_data.get('physical_address')):
                try:
                    lat = float(address_data['latitude'])
                    lng = float(address_data['longitude'])
                    formatted_address = reverse_geocode(lat, lng)
                    address_data['physical_address'] = formatted_address
                    address_data['location_address'] = formatted_address
                except (ValueError, TypeError):
                    pass
            
            # Secure sensitive address data
            secured_address_data = self.security_utils.secure_user_data(address_data)
            
            address_serializer = SellerAddressSerializer(data=secured_address_data)
            if address_serializer.is_valid():
                address = address_serializer.save(user=seller)
                
                # Log successful address details update
                AuditTrail.objects.create(
                    admin_email=user.email,
                    action='user_updated',
                    ip_address=ip_address,
                    user_agent=request.META.get('HTTP_USER_AGENT', ''),
                    description=f"Address details updated for seller: {user.email}"
                )
            else:
                # Log validation error
                SecurityEvent.objects.create(
                    user_email=user.email,
                    event_type='data_breach_attempt',
                    title='Address Details Validation Error',
                    description=f"Address details validation error: {address_serializer.errors}"
                )
                
                # Update auth log status
                auth_log.status = 'failed'
                auth_log.response_code = status.HTTP_400_BAD_REQUEST
                auth_log.error_message = str(address_serializer.errors)
                auth_log.save()
                
                return Response(address_serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        # Step 3: Bank Account Details
        bank_data = request.data.get('banking_info', {})
        if bank_data:
            # Secure sensitive bank data
            secured_bank_data = self.security_utils.secure_user_data(bank_data)
            
            bank_serializer = SellerBankAccountSerializer(data=secured_bank_data)
            if bank_serializer.is_valid():
                bank_serializer.save(user=user)
                
                # Log successful bank details update
                AuditTrail.objects.create(
                    admin_email=user.email,
                    action='user_updated',
                    ip_address=ip_address,
                    user_agent=request.META.get('HTTP_USER_AGENT', ''),
                    description=f"Bank details updated for seller: {user.email}"
                )
            else:
                # Log validation error
                SecurityEvent.objects.create(
                    user_email=user.email,
                    event_type='data_breach_attempt',
                    title='Bank Details Validation Error',
                    description=f"Bank details validation error: {bank_serializer.errors}"
                )
                
                # Update auth log status
                auth_log.status = 'failed'
                auth_log.response_code = status.HTTP_400_BAD_REQUEST
                auth_log.error_message = str(bank_serializer.errors)
                auth_log.save()
                
                return Response(bank_serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        # Final fallback: Ensure seller record exists
        if 'seller' not in locals():
            seller, created = Seller.objects.get_or_create(user=user)
            if created:
                # If we had to create the seller here, populate with any available data
                seller_data = request.data.get('seller', {})
                if seller_data:
                    seller.registered_company_name = seller_data.get('registered_company_name')
                    seller.trading_name = seller_data.get('trading_name')
                    seller.registration_number = seller_data.get('registration_number')
                    seller.vat_number = seller_data.get('vat_number')
                    
                    # Handle website URL validation
                    website_url = seller_data.get('website_url')
                    if website_url and website_url.startswith(('http://', 'https://')):
                        seller.website_url = website_url
                    
                    seller.product_category = seller_data.get('product_category')
                    
                    # Handle product_subcategory transformation
                    subcategory = seller_data.get('product_subcategory')
                    if subcategory:
                        display_to_key = {
                            'Engine Parts': 'engine_parts',
                            'Engines Parts': 'engine_parts',  # Handle both variants
                            'Body Parts': 'body_parts', 
                            'Suspension Parts': 'suspension_parts',
                            'Transmission Parts': 'transmission_parts',
                            'Batteries': 'batteries'
                        }
                        seller.product_subcategory = display_to_key.get(subcategory, subcategory)
                    
                    seller.save()

        # Log successful business registration
        AuditTrail.objects.create(
            admin_email=user.email,
            action='user_created',
            ip_address=ip_address,
            user_agent=request.META.get('HTTP_USER_AGENT', ''),
            description=f"Business registration completed successfully for seller: {user.email}"
        )
        
        # Update auth log status
        auth_log.status = 'success'
        auth_log.response_code = status.HTTP_201_CREATED
        auth_log.details = {'message': 'Business registration completed successfully'}
        auth_log.save()

        return Response({
            'message': 'Business registration completed successfully'
        }, status=status.HTTP_201_CREATED)


class SellerDocumentUploadView(APIView):
    """
    Seller document upload for vetting
    """
    permission_classes = [permissions.AllowAny]
    
    # Initialize security utils
    security_utils = SecurityUtils()

    def post(self, request):
        app_user_id = request.data.get('auth_user_id', {})
        if not user:
            return Response({
                'error': 'Authentication user not provided'
            }, status=status.HTTP_400_BAD_REQUEST)
        user = AppUser.objects.get(uid=app_user_id) if app_user_id else None

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
                user_email=user.email,
                event_type='api_abuse',
                title='Document Upload Rate Limit Exceeded',
                description=f"Document upload rate limit exceeded for user: {user.email}"
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
                user_email=user.email,
                event_type='privilege_escalation',
                title='Unauthorized Document Upload Attempt',
                description=f"Non-seller user attempted document upload: {user.email}"
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
                admin_email=user.email,
                action='user_updated',
                ip_address=ip_address,
                user_agent=request.META.get('HTTP_USER_AGENT', ''),
                description=f"Document upload process started for seller: {user.email}"
            )

            # Validate document types and sizes
            # This is a simplified example - in a real implementation, you would check file types,
            # scan for malware, validate file sizes, etc.
            for key, file in request.FILES.items():
                if file.size > 10 * 1024 * 1024:  # 10MB limit
                    # Log security event for oversized file
                    SecurityEvent.objects.create(
                        user_email=user.email,
                        event_type='data_breach_attempt',
                        title='Oversized File Upload Attempt',
                        description=f"User attempted to upload oversized file: {file.name}, size: {file.size} bytes"
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
                        user_email=user.email,
                        event_type='data_breach_attempt',
                        title='Disallowed File Type Upload Attempt',
                        description=f"User attempted to upload disallowed file type: {file.name}, type: {file_ext}"
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
                AuditTrail.objects.create(
                    admin_email=user.email,
                    action='user_updated',
                    ip_address=ip_address,
                    user_agent=request.META.get('HTTP_USER_AGENT', ''),
                    description=f"Documents uploaded successfully for seller: {user.email}"
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
                user_email=user.email,
                event_type='data_breach_attempt',
                title='Document Upload Validation Error',
                description=f"Document upload validation error: {serializer.errors}"
            )
            
            # Update API request status
            api_request.status_code = status.HTTP_400_BAD_REQUEST
            api_request.response_data = str(serializer.errors)
            api_request.save()
            
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
            
        except Seller.DoesNotExist:
            # Log error
            SecurityEvent.objects.create(
                user_email=user.email,
                event_type='data_breach_attempt',
                title='Seller Profile Not Found',
                description=f"Seller profile not found for user: {user.email}"
            )
            
            # Update API request status
            api_request.status_code = status.HTTP_404_NOT_FOUND
            api_request.response_data = "Seller profile not found"
            api_request.save()
            
            return Response({
                'error': 'Seller profile not found'
            }, status=status.HTTP_404_NOT_FOUND)


class LocationGeocodeView(APIView):
    """
    API endpoint to convert coordinates to human-readable addresses
    """
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        """
        Convert latitude/longitude to formatted address
        
        Request body:
        {
            "latitude": -17.8292,
            "longitude": 31.0522
        }
        
        Response:
        {
            "formatted_address": "123 Main Street, Harare, Zimbabwe",
            "latitude": -17.8292,
            "longitude": 31.0522,
            "display_text": "123 Main Street, Harare, Zimbabwe"
        }
        """
        latitude = request.data.get('latitude')
        longitude = request.data.get('longitude')
        
        if not latitude or not longitude:
            return Response({
                'error': 'Both latitude and longitude are required'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        try:
            lat = float(latitude)
            lng = float(longitude)
        except (ValueError, TypeError):
            return Response({
                'error': 'Invalid latitude or longitude format'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Validate coordinate ranges
        if not (-90 <= lat <= 90) or not (-180 <= lng <= 180):
            return Response({
                'error': 'Invalid coordinate values. Latitude must be between -90 and 90, longitude between -180 and 180'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        location_data = format_location_with_address(lat, lng)
        
        return Response(location_data, status=status.HTTP_200_OK)
    
    def get(self, request):
        """
        Convert coordinates from query parameters
        
        Usage: /api/geocode/?lat=-17.8292&lng=31.0522
        """
        latitude = request.query_params.get('lat')
        longitude = request.query_params.get('lng') or request.query_params.get('lon')
        
        if not latitude or not longitude:
            return Response({
                'error': 'Both lat and lng query parameters are required'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        try:
            lat = float(latitude)
            lng = float(longitude)
        except (ValueError, TypeError):
            return Response({
                'error': 'Invalid latitude or longitude format'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        if not (-90 <= lat <= 90) or not (-180 <= lng <= 180):
            return Response({
                'error': 'Invalid coordinate values'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        location_data = format_location_with_address(lat, lng)
        
        return Response(location_data, status=status.HTTP_200_OK)


class DocumentVettingView(APIView):
    """
    Admin endpoint for document vetting
    """
    permission_classes = [permissions.AllowAny]

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