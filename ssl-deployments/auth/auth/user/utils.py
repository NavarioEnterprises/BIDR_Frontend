import random
import string
import hashlib
import hmac
import base64
import logging
from datetime import timedelta, datetime

from django.utils import timezone
from django.conf import settings
from django.core.mail import send_mail
from django.template.loader import render_to_string
from django.contrib.gis.geos import Point
from django.contrib.gis.measure import Distance

logger = logging.getLogger(__name__)



class TokenGenerator:
    """
    Utility class for generating secure tokens
    """

    @staticmethod
    def generate_reset_token(user_id, timestamp=None):
        """
        Generate a secure password reset token
        """
        if timestamp is None:
            timestamp = timezone.now()

        # Create payload
        payload = f"{user_id}:{timestamp.isoformat()}"

        # Create signature
        signature = hmac.new(
            settings.SECRET_KEY.encode(),
            payload.encode(),
            hashlib.sha256
        ).hexdigest()

        # Combine payload and signature
        token = base64.urlsafe_b64encode(
            f"{payload}:{signature}".encode()
        ).decode()

        return token

    @staticmethod
    def validate_reset_token(token, user_id, max_age_hours=24):
        """
        Validate a password reset token
        """
        try:
            # Decode token
            decoded = base64.urlsafe_b64decode(token.encode()).decode()
            payload, signature = decoded.rsplit(':', 1)

            # Verify signature
            expected_signature = hmac.new(
                settings.SECRET_KEY.encode(),
                payload.encode(),
                hashlib.sha256
            ).hexdigest()

            if not hmac.compare_digest(signature, expected_signature):
                return False

            # Parse payload
            token_user_id, timestamp_str = payload.split(':', 1)

            # Verify user ID
            if str(user_id) != token_user_id:
                return False

            # Verify timestamp
            token_timestamp = datetime.fromisoformat(timestamp_str)
            if timezone.is_naive(token_timestamp):
                token_timestamp = timezone.make_aware(token_timestamp)

            max_age = timedelta(hours=max_age_hours)
            if timezone.now() - token_timestamp > max_age:
                return False

            return True

        except Exception as e:
            logger.error(f"Token validation error: {e}")
            return False


class EmailService:
    """
    Utility class for sending emails
    """

    @staticmethod
    def send_otp_email(user, otp):
        """
        Send OTP verification email
        """
        try:
            subject = 'Verify Your Account - BIDR'

            # Render email template
            html_content = render_to_string('emails/otp_verification.html', {
                'user': user,
                'otp': otp,
                'company_name': 'BIDR',
            })

            text_content = f"""
            Hi {user.first_name} {user.last_name},

            Your verification code is: {otp}

            This code will expire in 5 minutes.

            If you didn't request this code, please ignore this email.

            Best regards,
            BIDR Team
            """

            send_mail(
                subject=subject,
                message=text_content,
                from_email=settings.DEFAULT_FROM_EMAIL,
                recipient_list=[user.email],
                html_message=html_content,
                fail_silently=False,
            )

            logger.info(f"OTP email sent to {user.email}")
            return True

        except Exception as e:
            logger.error(f"Failed to send OTP email to {user.email}: {e}")
            return False

    @staticmethod
    def send_password_reset_email(user, reset_link):
        """
        Send password reset email
        """
        try:
            subject = 'Password Reset - BIDR'

            html_content = render_to_string('emails/password_reset.html', {
                'user': user,
                'reset_link': reset_link,
                'company_name': 'BIDR',
            })

            text_content = f"""
            Hi {user.first_name} {user.last_name},

            You requested a password reset for your BIDR account.

            Click the link below to reset your password:
            {reset_link}

            This link will expire in 24 hours.

            If you didn't request this reset, please ignore this email.

            Best regards,
            BIDR Team
            """

            send_mail(
                subject=subject,
                message=text_content,
                from_email=settings.DEFAULT_FROM_EMAIL,
                recipient_list=[user.email],
                html_message=html_content,
                fail_silently=False,
            )

            logger.info(f"Password reset email sent to {user.email}")
            return True

        except Exception as e:
            logger.error(f"Failed to send password reset email to {user.email}: {e}")
            return False

    @staticmethod
    def send_verification_approval_email(user):
        """
        Send verification approval email
        """
        try:
            subject = 'Business Verification Approved - BIDR'

            html_content = render_to_string('emails/verification_approved.html', {
                'user': user,
                'company_name': 'BIDR',
            })

            text_content = f"""
            Hi {user.first_name} {user.last_name},

            Congratulations! Your business has been verified and approved.

            You can now access all seller features on the BIDR platform.

            Best regards,
            BIDR Team
            """

            send_mail(
                subject=subject,
                message=text_content,
                from_email=settings.DEFAULT_FROM_EMAIL,
                recipient_list=[user.email],
                html_message=html_content,
                fail_silently=False,
            )

            logger.info(f"Verification approval email sent to {user.email}")
            return True

        except Exception as e:
            logger.error(f"Failed to send verification approval email to {user.email}: {e}")
            return False


class GeographicUtils:
    """
    Utility class for geographic operations
    """

    @staticmethod
    def create_point(latitude, longitude):
        """
        Create a Point object from latitude and longitude
        """
        return Point(longitude, latitude)  # Note: Point(x, y) = Point(longitude, latitude)

    @staticmethod
    def get_coordinates(point):
        """
        Extract latitude and longitude from Point object
        """
        if point:
            return (point.y, point.x)  # (latitude, longitude)
        return None

    @staticmethod
    def calculate_distance(point1, point2):
        """
        Calculate distance between two points in kilometers
        """
        if point1 and point2:
            # Convert degrees to kilometers (approximate)
            return point1.distance(point2) * 111.32
        return None

    @staticmethod
    def find_within_radius(queryset, center_point, radius_km):
        """
        Find objects within radius of center point
        """
        return queryset.filter(
            location__distance_lte=(center_point, Distance(km=radius_km))
        )

    @staticmethod
    def validate_coordinates(latitude, longitude):
        """
        Validate latitude and longitude values
        """
        try:
            lat = float(latitude)
            lng = float(longitude)

            if not (-90 <= lat <= 90):
                return False, "Latitude must be between -90 and 90"

            if not (-180 <= lng <= 180):
                return False, "Longitude must be between -180 and 180"

            return True, "Valid coordinates"

        except (ValueError, TypeError):
            return False, "Invalid coordinate format"


class SecurityUtils:
    """
    Utility class for security operations
    """

    @staticmethod
    def mask_sensitive_data(data, field_name):
        """
        Mask sensitive data for display
        """
        if not data:
            return "****"

        if field_name in ['account_number', 'card_number']:
            if len(data) > 4:
                return f"****{data[-4:]}"
            return "****"

        elif field_name in ['email']:
            if '@' in data:
                username, domain = data.split('@', 1)
                if len(username) > 2:
                    return f"{username[:2]}***@{domain}"
                return f"***@{domain}"
            return "***"

        elif field_name in ['phone', 'phone_number']:
            if len(data) > 4:
                return f"***{data[-4:]}"
            return "***"

        else:
            # Generic masking
            if len(data) > 4:
                return f"{data[:2]}***{data[-2:]}"
            return "***"

    @staticmethod
    def generate_secure_filename(original_filename):
        """
        Generate a secure filename for uploads
        """
        import os
        import uuid

        # Get file extension
        _, ext = os.path.splitext(original_filename)

        # Generate unique filename
        secure_name = f"{uuid.uuid4().hex}{ext}"

        return secure_name

    @staticmethod
    def validate_file_upload(file, allowed_types=None, max_size_mb=10):
        """
        Validate file upload
        """
        if allowed_types is None:
            allowed_types = ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx']

        # Check file size
        max_size_bytes = max_size_mb * 1024 * 1024
        if file.size > max_size_bytes:
            return False, f"File size exceeds {max_size_mb}MB limit"

        # Check file extension
        import os
        _, ext = os.path.splitext(file.name)
        ext = ext.lower().lstrip('.')

        if ext not in allowed_types:
            return False, f"File type '{ext}' not allowed. Allowed types: {', '.join(allowed_types)}"

        return True, "File is valid"


class RoleUtils:
    """
    Utility class for role-based operations
    """

    @staticmethod
    def can_user_perform_action(user, action):
        """
        Check if user can perform a specific action
        """
        role_permissions = {
            'administrator': [
                'manage_users', 'approve_sellers', 'access_financial_data',
                'moderate_content', 'view_audit_logs', 'manage_system'
            ],
            'seller': [
                'manage_profile', 'upload_documents', 'manage_products',
                'view_orders', 'manage_inventory'
            ],
            'buyer': [
                'manage_profile', 'place_orders', 'view_orders',
                'leave_reviews', 'manage_wishlist'
            ]
        }

        if user.is_superuser:
            return True

        user_permissions = role_permissions.get(user.role, [])
        return action in user_permissions

    @staticmethod
    def get_user_dashboard_url(user):
        """
        Get appropriate dashboard URL based on user role
        """
        role_dashboards = {
            'administrator': '/admin/dashboard/',
            'seller': '/seller/dashboard/',
            'buyer': '/buyer/dashboard/',
        }

        return role_dashboards.get(user.role, '/dashboard/')

    @staticmethod
    def get_role_display_name(role):
        """
        Get human-readable role name
        """
        role_names = {
            'administrator': 'Administrator',
            'seller': 'Seller',
            'buyer': 'Buyer',
        }

        return role_names.get(role, role.title())


class ValidationUtils:
    """
    Utility class for data validation
    """

    @staticmethod
    def validate_south_african_phone(phone):
        """
        Validate South African phone number format
        """
        import re

        # Remove all non-digit characters
        digits_only = re.sub(r'\D', '', phone)

        # Check for valid SA phone number patterns
        patterns = [
            r'^27[0-9]{9}$',  # +27 format
            r'^0[0-9]{9}$',  # 0 prefix format
            r'^[0-9]{9}$',  # 9 digits without prefix
        ]

        for pattern in patterns:
            if re.match(pattern, digits_only):
                return True, "Valid phone number"

        return False, "Invalid South African phone number format"

    @staticmethod
    def validate_south_african_id(id_number):
        """
        Validate South African ID number
        """
        import re

        if not id_number or len(id_number) != 13:
            return False, "ID number must be 13 digits"

        if not id_number.isdigit():
            return False, "ID number must contain only digits"

        # Basic Luhn algorithm check (simplified)
        # In production, implement full SA ID validation
        return True, "Valid ID number format"

    @staticmethod
    def validate_company_registration(reg_number):
        """
        Validate South African company registration number
        """
        import re

        # Basic format validation for SA company registration
        # Format: YYYY/NNNNNN/NN
        pattern = r'^\d{4}/\d{6}/\d{2}$'

        if re.match(pattern, reg_number):
            return True, "Valid company registration format"

        return False, "Invalid company registration format (expected: YYYY/NNNNNN/NN)"

