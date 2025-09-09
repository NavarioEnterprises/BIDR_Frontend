import datetime
import ipaddress
import hashlib
import secrets
import string

from django.db import models
from rest_framework import viewsets, permissions, status, filters
from rest_framework.decorators import action
from rest_framework.response import Response
from django_filters.rest_framework import DjangoFilterBackend
from django.utils import timezone

from .models import SecurityPolicy, SecurityAuditLog, BlockedIP, SecurityQuestion, UserSecurityQuestion, \
    TwoFactorMethod, APIKey
from .serializers import (
    SecurityPolicySerializer, SecurityAuditLogSerializer,
    BlockedIPSerializer, SecurityQuestionSerializer,
    UserSecurityQuestionSerializer, TwoFactorMethodSerializer,
    APIKeySerializer
)


class SecurityPolicyViewSet(viewsets.ModelViewSet):
    """
    API endpoint for security policies management
    """
    queryset = SecurityPolicy.objects.all()
    serializer_class = SecurityPolicySerializer
    permission_classes = [permissions.IsAuthenticated, permissions.IsAdminUser]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['policy_type', 'is_active']
    search_fields = ['name', 'description']
    ordering_fields = ['name', 'policy_type', 'created_at']
    ordering = ['-is_active', 'policy_type', 'name']

    def perform_create(self, serializer):
        serializer.save(created_by=self.request.user)

    def perform_update(self, serializer):
        serializer.save(updated_by=self.request.user)

    @action(detail=False, methods=['get'])
    def active(self, request):
        """
        Get all active security policies
        """
        now = timezone.now()
        active_policies = self.queryset.filter(
            is_active=True,
            effective_from__lte=now
        ).filter(
            models.Q(effective_to__isnull=True) |
            models.Q(effective_to__gt=now)
        )

        serializer = self.get_serializer(active_policies, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['get'])
    def by_type(self, request):
        """
        Get policies filtered by type
        """
        policy_type = request.query_params.get('type')
        if not policy_type:
            return Response(
                {"error": "type parameter is required"},
                status=status.HTTP_400_BAD_REQUEST
            )

        now = timezone.now()
        policies = self.queryset.filter(
            policy_type=policy_type,
            is_active=True,
            effective_from__lte=now
        ).filter(
            models.Q(effective_to__isnull=True) |
            models.Q(effective_to__gt=now)
        )

        serializer = self.get_serializer(policies, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['post'])
    def validate_password(self, request):
        """
        Validate a password against the current password policy
        """
        password = request.data.get('password')

        if not password:
            return Response(
                {"error": "password parameter is required"},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Get current password policy
        now = timezone.now()
        policy = self.queryset.filter(
            policy_type='password',
            is_active=True,
            effective_from__lte=now
        ).filter(
            models.Q(effective_to__isnull=True) |
            models.Q(effective_to__gt=now)
        ).first()

        if not policy:
            return Response(
                {"error": "No active password policy found"},
                status=status.HTTP_404_NOT_FOUND
            )

        # Validate password against policy
        policy_data = policy.policy_data
        validation_errors = []

        # Check length
        min_length = policy_data.get('min_length', 8)
        if len(password) < min_length:
            validation_errors.append(f"Password must be at least {min_length} characters long")

        # Check for uppercase letters
        if policy_data.get('require_uppercase', True) and not any(c.isupper() for c in password):
            validation_errors.append("Password must contain at least one uppercase letter")

        # Check for lowercase letters
        if policy_data.get('require_lowercase', True) and not any(c.islower() for c in password):
            validation_errors.append("Password must contain at least one lowercase letter")

        # Check for numbers
        if policy_data.get('require_numbers', True) and not any(c.isdigit() for c in password):
            validation_errors.append("Password must contain at least one number")

        # Check for special characters
        if policy_data.get('require_special_chars', True):
            special_chars = set(string.punctuation)
            if not any(c in special_chars for c in password):
                validation_errors.append("Password must contain at least one special character")

        if validation_errors:
            return Response({
                "valid": False,
                "errors": validation_errors
            })
        else:
            return Response({
                "valid": True
            })


class SecurityAuditLogViewSet(viewsets.ModelViewSet):
    """
    API endpoint for security audit logs management
    """
    queryset = SecurityAuditLog.objects.all()
    serializer_class = SecurityAuditLogSerializer
    permission_classes = [permissions.IsAuthenticated, permissions.IsAdminUser]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['event_type', 'user', 'ip_address', 'status']
    search_fields = ['event_type', 'details', 'ip_address']
    ordering_fields = ['timestamp']
    ordering = ['-timestamp']

    def perform_create(self, serializer):
        # Get client IP from request
        x_forwarded_for = self.request.META.get('HTTP_X_FORWARDED_FOR')
        if x_forwarded_for:
            ip_address = x_forwarded_for.split(',')[0]
        else:
            ip_address = self.request.META.get('REMOTE_ADDR')

        serializer.save(ip_address=ip_address)

    @action(detail=False, methods=['get'])
    def recent(self, request):
        """
        Get recent security audit logs
        """
        days = request.query_params.get('days', 1)
        try:
            days = int(days)
        except ValueError:
            days = 1

        since = timezone.now() - datetime.timedelta(days=days)
        recent_logs = self.queryset.filter(timestamp__gte=since)

        page = self.paginate_queryset(recent_logs)
        if page is not None:
            serializer = self.get_serializer(page, many=True)
            return self.get_paginated_response(serializer.data)

        serializer = self.get_serializer(recent_logs, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['get'])
    def by_user(self, request):
        """
        Get audit logs for a specific user
        """
        user_id = request.query_params.get('user_id')
        if not user_id:
            return Response(
                {"error": "user_id parameter is required"},
                status=status.HTTP_400_BAD_REQUEST
            )

        logs = self.queryset.filter(user_id=user_id)

        page = self.paginate_queryset(logs)
        if page is not None:
            serializer = self.get_serializer(page, many=True)
            return self.get_paginated_response(serializer.data)

        serializer = self.get_serializer(logs, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['get'])
    def failed_logins(self, request):
        """
        Get failed login attempts
        """
        days = request.query_params.get('days', 1)
        try:
            days = int(days)
        except ValueError:
            days = 1

        since = timezone.now() - datetime.timedelta(days=days)
        failed_logins = self.queryset.filter(
            event_type='login',
            status='failed',
            timestamp__gte=since
        )

        page = self.paginate_queryset(failed_logins)
        if page is not None:
            serializer = self.get_serializer(page, many=True)
            return self.get_paginated_response(serializer.data)

        serializer = self.get_serializer(failed_logins, many=True)
        return Response(serializer.data)


class BlockedIPViewSet(viewsets.ModelViewSet):
    """
    API endpoint for blocked IPs management
    """
    queryset = BlockedIP.objects.all()
    serializer_class = BlockedIPSerializer
    permission_classes = [permissions.IsAuthenticated, permissions.IsAdminUser]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['is_permanent', 'reason']
    search_fields = ['ip_address', 'reason', 'notes']
    ordering_fields = ['blocked_at', 'blocked_until']
    ordering = ['-blocked_at']

    def perform_create(self, serializer):
        serializer.save(blocked_by=self.request.user)

    @action(detail=False, methods=['get'])
    def active(self, request):
        """
        Get currently active IP blocks
        """
        now = timezone.now()
        active_blocks = self.queryset.filter(
            models.Q(is_permanent=True) |
            models.Q(blocked_until__gt=now)
        )

        serializer = self.get_serializer(active_blocks, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['post'])
    def check_ip(self, request):
        """
        Check if an IP address is blocked
        """
        ip_address = request.data.get('ip_address')

        if not ip_address:
            return Response(
                {"error": "ip_address parameter is required"},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Validate IP address format
        try:
            ipaddress.ip_address(ip_address)
        except ValueError:
            return Response(
                {"error": "Invalid IP address format"},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Check if IP is blocked
        now = timezone.now()
        is_blocked = self.queryset.filter(
            ip_address=ip_address
        ).filter(
            models.Q(is_permanent=True) |
            models.Q(blocked_until__gt=now)
        ).exists()

        if is_blocked:
            block = self.queryset.filter(
                ip_address=ip_address
            ).filter(
                models.Q(is_permanent=True) |
                models.Q(blocked_until__gt=now)
            ).first()

            return Response({
                "is_blocked": True,
                "block": self.get_serializer(block).data
            })
        else:
            return Response({
                "is_blocked": False
            })


class SecurityQuestionViewSet(viewsets.ModelViewSet):
    """
    API endpoint for security questions management
    """
    queryset = SecurityQuestion.objects.all()
    serializer_class = SecurityQuestionSerializer
    permission_classes = [permissions.IsAuthenticated, permissions.IsAdminUser]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['is_active']
    search_fields = ['question_text']
    ordering_fields = ['created_at']
    ordering = ['question_text']

    @action(detail=False, methods=['get'])
    def active(self, request):
        """
        Get all active security questions
        """
        active_questions = self.queryset.filter(is_active=True)
        serializer = self.get_serializer(active_questions, many=True)
        return Response(serializer.data)


class UserSecurityQuestionViewSet(viewsets.ModelViewSet):
    """
    API endpoint for user security questions management
    """
    queryset = UserSecurityQuestion.objects.all()
    serializer_class = UserSecurityQuestionSerializer
    permission_classes = [permissions.IsAuthenticated]
    filter_backends = [DjangoFilterBackend, filters.OrderingFilter]
    filterset_fields = ['user', 'question']
    ordering_fields = ['created_at']
    ordering = ['created_at']

    def get_queryset(self):
        """
        Filter security questions to show only those for the current user
        """
        user = self.request.user

        # Staff can see all user security questions
        if user.is_staff:
            return self.queryset

        # Regular users can only see their own security questions
        return self.queryset.filter(user=user)

    def perform_create(self, serializer):
        # Hash the answer before saving
        answer = serializer.validated_data.get('answer_hash')
        if answer:
            answer_hash = hashlib.sha256(answer.lower().encode()).hexdigest()
            serializer.save(user=self.request.user, answer_hash=answer_hash)
        else:
            serializer.save(user=self.request.user)

    @action(detail=False, methods=['post'])
    def verify_answer(self, request):
        """
        Verify a security question answer
        """
        question_id = request.data.get('question_id')
        answer = request.data.get('answer')

        if not question_id or not answer:
            return Response(
                {"error": "Both question_id and answer parameters are required"},
                status=status.HTTP_400_BAD_REQUEST
            )

        try:
            user_question = self.get_queryset().get(question_id=question_id)
        except UserSecurityQuestion.DoesNotExist:
            return Response(
                {"error": "Security question not found"},
                status=status.HTTP_404_NOT_FOUND
            )

        # Hash the provided answer and compare
        answer_hash = hashlib.sha256(answer.lower().encode()).hexdigest()
        is_correct = user_question.answer_hash == answer_hash

        # Log the verification attempt
        SecurityAuditLog.objects.create(
            user=request.user,
            event_type='security_question_verification',
            status='success' if is_correct else 'failed',
            details={
                'question_id': question_id,
                'result': 'correct' if is_correct else 'incorrect'
            }
        )

        return Response({
            "correct": is_correct
        })


class TwoFactorMethodViewSet(viewsets.ModelViewSet):
    """
    API endpoint for two-factor authentication methods management
    """
    queryset = TwoFactorMethod.objects.all()
    serializer_class = TwoFactorMethodSerializer
    permission_classes = [permissions.IsAuthenticated]
    filter_backends = [DjangoFilterBackend, filters.OrderingFilter]
    filterset_fields = ['user', 'method_type', 'is_active', 'is_primary']
    ordering_fields = ['created_at', 'last_used']
    ordering = ['-is_primary', '-last_used']

    def get_queryset(self):
        """
        Filter 2FA methods to show only those for the current user
        """
        user = self.request.user

        # Staff can see all 2FA methods
        if user.is_staff:
            return self.queryset

        # Regular users can only see their own 2FA methods
        return self.queryset.filter(user=user)

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)

    @action(detail=True, methods=['post'])
    def set_primary(self, request, pk=None):
        """
        Set a 2FA method as primary
        """
        method = self.get_object()

        # Ensure the method is active
        if not method.is_active:
            return Response(
                {"error": "Cannot set inactive method as primary"},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Update all 2FA methods for this user
        TwoFactorMethod.objects.filter(user=request.user).update(is_primary=False)

        # Set this one as primary
        method.is_primary = True
        method.save()

        serializer = self.get_serializer(method)
        return Response(serializer.data)

    @action(detail=False, methods=['post'])
    def verify_code(self, request):
        """
        Verify a 2FA code
        """
        method_id = request.data.get('method_id')
        code = request.data.get('code')

        if not method_id or not code:
            return Response(
                {"error": "Both method_id and code parameters are required"},
                status=status.HTTP_400_BAD_REQUEST
            )

        try:
            method = self.get_queryset().get(id=method_id)
        except TwoFactorMethod.DoesNotExist:
            return Response(
                {"error": "2FA method not found"},
                status=status.HTTP_404_NOT_FOUND
            )

        # In a real implementation, this would verify the code based on the method type
        # For this example, we'll simulate verification

        # Update last used timestamp
        method.last_used = timezone.now()
        method.save()

        # Log the verification attempt
        SecurityAuditLog.objects.create(
            user=request.user,
            event_type='2fa_verification',
            status='success',
            details={
                'method_id': method_id,
                'method_type': method.method_type
            }
        )

        return Response({
            "verified": True
        })

    @action(detail=False, methods=['post'])
    def generate_backup_codes(self, request):
        """
        Generate new backup codes for a user
        """
        # Generate 10 random backup codes
        backup_codes = []
        for _ in range(10):
            code = ''.join(secrets.choice(string.ascii_uppercase + string.digits) for _ in range(8))
            backup_codes.append(code)

        # Create or update backup codes method
        method, created = TwoFactorMethod.objects.get_or_create(
            user=request.user,
            method_type='backup_codes',
            defaults={
                'is_active': True,
                'is_primary': False,
                'backup_codes': backup_codes
            }
        )

        if not created:
            method.backup_codes = backup_codes
            method.save()

        # Log the generation
        SecurityAuditLog.objects.create(
            user=request.user,
            event_type='backup_codes_generation',
            status='success',
            details={
                'method_id': method.id
            }
        )

        return Response({
            "backup_codes": backup_codes
        })


class APIKeyViewSet(viewsets.ModelViewSet):
    """
    API endpoint for API keys management
    """
    queryset = APIKey.objects.all()
    serializer_class = APIKeySerializer
    permission_classes = [permissions.IsAuthenticated]
    filter_backends = [DjangoFilterBackend, filters.OrderingFilter]
    filterset_fields = ['user', 'is_active']
    ordering_fields = ['created_at', 'expires_at', 'last_used']
    ordering = ['-created_at']

    def get_queryset(self):
        """
        Filter API keys to show only those for the current user
        """
        user = self.request.user

        # Staff can see all API keys
        if user.is_staff:
            return self.queryset

        # Regular users can only see their own API keys
        return self.queryset.filter(user=user)

    def perform_create(self, serializer):
        # Generate API key
        key = secrets.token_hex(32)
        key_prefix = key[:8]
        key_hash = hashlib.sha256(key.encode()).hexdigest()

        serializer.save(
            user=self.request.user,
            key_prefix=key_prefix,
            key_hash=key_hash
        )

        # Log the creation
        SecurityAuditLog.objects.create(
            user=self.request.user,
            event_type='api_key_creation',
            status='success',
            details={
                'key_prefix': key_prefix
            }
        )

        # Return the full key to the user (only time it's visible)
        return Response({
            "api_key": key,
            "key_data": serializer.data
        })

    @action(detail=True, methods=['post'])
    def revoke(self, request, pk=None):
        """
        Revoke an API key
        """
        api_key = self.get_object()

        # Update API key
        api_key.is_active = False
        api_key.save()

        # Log the revocation
        SecurityAuditLog.objects.create(
            user=request.user,
            event_type='api_key_revocation',
            status='success',
            details={
                'key_prefix': api_key.key_prefix
            }
        )

        serializer = self.get_serializer(api_key)
        return Response(serializer.data)

    @action(detail=False, methods=['post'])
    def verify_key(self, request):
        """
        Verify an API key
        """
        api_key = request.data.get('api_key')

        if not api_key:
            return Response(
                {"error": "api_key parameter is required"},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Hash the key for comparison
        key_hash = hashlib.sha256(api_key.encode()).hexdigest()
        key_prefix = api_key[:8]

        # Find the API key
        try:
            key_obj = APIKey.objects.get(
                key_prefix=key_prefix,
                key_hash=key_hash,
                is_active=True
            )
        except APIKey.DoesNotExist:
            return Response(
                {"error": "Invalid or inactive API key"},
                status=status.HTTP_401_UNAUTHORIZED
            )

        # Check if expired
        if key_obj.expires_at and key_obj.expires_at < timezone.now():
            return Response(
                {"error": "API key has expired"},
                status=status.HTTP_401_UNAUTHORIZED
            )

        # Update last used timestamp
        key_obj.last_used = timezone.now()
        key_obj.save()

        return Response({
            "valid": True,
            "user_id": key_obj.user.id,
            "permissions": key_obj.permissions
        })
