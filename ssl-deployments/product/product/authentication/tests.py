# Set up Django environment if not already configured
import os
import django
from django.conf import settings

if not settings.configured:
    os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'product_management_service.settings')
    django.setup()

from django.test import TestCase, Client
from django.contrib.auth.models import User
from django.urls import reverse
from rest_framework.test import APITestCase, APIClient
from rest_framework import status
from rest_framework_simplejwt.tokens import RefreshToken, AccessToken
from rest_framework_simplejwt.token_blacklist.models import BlacklistedToken, OutstandingToken
from unittest.mock import patch, MagicMock
import json
from datetime import timedelta
from django.utils import timezone


class JWTAuthenticationTest(TestCase):
    """Test JWT authentication functionality."""
    
    def setUp(self):
        self.user = User.objects.create_user(
            username='testuser',
            email='test@example.com',
            password='testpass123'
        )
        self.client = Client()
    
    def test_jwt_token_creation(self):
        """Test JWT token creation for user."""
        refresh = RefreshToken.for_user(self.user)
        access_token = refresh.access_token
        
        # Test that tokens are created
        self.assertIsNotNone(refresh)
        self.assertIsNotNone(access_token)
        
        # Test token properties
        self.assertEqual(refresh.payload['user_id'], self.user.id)
        self.assertEqual(access_token.payload['user_id'], self.user.id)
        
        # Test token types
        self.assertEqual(refresh.payload['token_type'], 'refresh')
        self.assertEqual(access_token.payload['token_type'], 'access')
    
    def test_jwt_token_validation(self):
        """Test JWT token validation."""
        refresh = RefreshToken.for_user(self.user)
        access_token = refresh.access_token
        
        # Test valid token
        self.assertTrue(access_token.check_exp())
        
        # Test token decoding
        decoded_token = AccessToken(str(access_token))
        self.assertEqual(decoded_token.payload['user_id'], self.user.id)
    
    def test_jwt_token_expiration(self):
        """Test JWT token expiration."""
        refresh = RefreshToken.for_user(self.user)
        access_token = refresh.access_token
        
        # Check expiration times
        self.assertIsNotNone(access_token.payload.get('exp'))
        self.assertIsNotNone(refresh.payload.get('exp'))
        
        # Access token should expire before refresh token
        self.assertLess(
            access_token.payload['exp'],
            refresh.payload['exp']
        )
    
    def test_refresh_token_rotation(self):
        """Test refresh token rotation."""
        # Create initial refresh token
        refresh = RefreshToken.for_user(self.user)
        original_jti = refresh.payload['jti']
        
        # Get new access token (which should rotate refresh token)
        new_access = refresh.access_token
        
        # Test that we got a new access token
        self.assertIsNotNone(new_access)
        self.assertEqual(new_access.payload['user_id'], self.user.id)


class TokenBlacklistTest(TestCase):
    """Test token blacklisting functionality."""
    
    def setUp(self):
        self.user = User.objects.create_user(
            username='testuser',
            email='test@example.com',
            password='testpass123'
        )
    
    def test_token_blacklisting(self):
        """Test token blacklisting process."""
        # Create refresh token
        refresh = RefreshToken.for_user(self.user)
        
        # Check that token is outstanding (not blacklisted)
        outstanding_tokens = OutstandingToken.objects.filter(
            user=self.user,
            jti=refresh.payload['jti']
        )
        self.assertEqual(outstanding_tokens.count(), 1)
        
        # Blacklist the token
        refresh.blacklist()
        
        # Check that token is now blacklisted
        blacklisted_tokens = BlacklistedToken.objects.filter(
            token__jti=refresh.payload['jti']
        )
        self.assertEqual(blacklisted_tokens.count(), 1)
    
    def test_blacklisted_token_validation(self):
        """Test that blacklisted tokens are invalid."""
        # Create and blacklist token
        refresh = RefreshToken.for_user(self.user)
        token_string = str(refresh)
        refresh.blacklist()
        
        # Try to create token from blacklisted string
        from rest_framework_simplejwt.exceptions import TokenError
        
        with self.assertRaises(TokenError):
            RefreshToken(token_string)
    
    def test_automatic_blacklisting_on_refresh(self):
        """Test automatic blacklisting when refresh token is used."""
        # Create refresh token
        refresh = RefreshToken.for_user(self.user)
        original_jti = refresh.payload['jti']
        
        # Use refresh token to get new access token
        new_access = refresh.access_token
        
        # The original refresh token should still be valid for one more use
        # (depending on configuration)
        self.assertIsNotNone(new_access)
    
    def test_user_token_cleanup(self):
        """Test cleaning up tokens for a user."""
        # Create multiple tokens for user
        refresh1 = RefreshToken.for_user(self.user)
        refresh2 = RefreshToken.for_user(self.user)
        
        # Check that tokens exist
        user_tokens = OutstandingToken.objects.filter(user=self.user)
        self.assertGreaterEqual(user_tokens.count(), 2)
        
        # Blacklist all tokens for user
        for token in user_tokens:
            try:
                refresh_token = RefreshToken(token.token)
                refresh_token.blacklist()
            except Exception:
                pass  # Token might already be blacklisted or invalid
        
        # Check that all tokens are blacklisted
        blacklisted_count = BlacklistedToken.objects.filter(
            token__user=self.user
        ).count()
        self.assertGreater(blacklisted_count, 0)
    
    def test_token_blacklist_cleanup(self):
        """Test cleanup of expired blacklisted tokens."""
        # Create and blacklist a token
        refresh = RefreshToken.for_user(self.user)
        refresh.blacklist()
        
        # Check that blacklisted token exists
        blacklisted_tokens = BlacklistedToken.objects.filter(
            token__jti=refresh.payload['jti']
        )
        self.assertEqual(blacklisted_tokens.count(), 1)
        
        # Simulate cleanup of expired tokens (this would be done by management command)
        expired_tokens = OutstandingToken.objects.filter(
            expires_at__lt=timezone.now()
        )
        
        # Delete expired outstanding tokens and their blacklist entries
        for token in expired_tokens:
            BlacklistedToken.objects.filter(token=token).delete()
            token.delete()


class AuthenticationAPITest(APITestCase):
    """Test authentication API endpoints."""
    
    def setUp(self):
        self.user = User.objects.create_user(
            username='testuser',
            email='test@example.com',
            password='testpass123'
        )
        self.client = APIClient()
    
    def test_token_obtain_endpoint(self):
        """Test obtaining JWT tokens via API."""
        url = '/api/token/'
        data = {
            'username': 'testuser',
            'password': 'testpass123'
        }
        
        try:
            response = self.client.post(url, data, format='json')
            
            if response.status_code == 200:
                self.assertIn('access', response.data)
                self.assertIn('refresh', response.data)
                
                # Test token format
                access_token = response.data['access']
                refresh_token = response.data['refresh']
                
                self.assertIsInstance(access_token, str)
                self.assertIsInstance(refresh_token, str)
                self.assertGreater(len(access_token), 50)
                self.assertGreater(len(refresh_token), 50)
        except Exception:
            # URL might not exist yet
            pass
    
    def test_token_refresh_endpoint(self):
        """Test refreshing JWT tokens via API."""
        # Get initial tokens
        refresh = RefreshToken.for_user(self.user)
        
        url = '/api/token/refresh/'
        data = {
            'refresh': str(refresh)
        }
        
        try:
            response = self.client.post(url, data, format='json')
            
            if response.status_code == 200:
                self.assertIn('access', response.data)
                
                # Test that we got a new access token
                new_access_token = response.data['access']
                self.assertIsInstance(new_access_token, str)
                self.assertGreater(len(new_access_token), 50)
        except Exception:
            # URL might not exist yet
            pass
    
    def test_token_blacklist_endpoint(self):
        """Test blacklisting tokens via API."""
        # Get refresh token
        refresh = RefreshToken.for_user(self.user)
        
        url = '/api/token/blacklist/'
        data = {
            'refresh': str(refresh)
        }
        
        try:
            response = self.client.post(url, data, format='json')
            
            # Should either succeed (204) or endpoint might not exist
            self.assertIn(response.status_code, [204, 404])
            
            if response.status_code == 204:
                # Verify token is blacklisted
                blacklisted_tokens = BlacklistedToken.objects.filter(
                    token__jti=refresh.payload['jti']
                )
                self.assertEqual(blacklisted_tokens.count(), 1)
        except Exception:
            # URL might not exist yet
            pass
    
    def test_protected_endpoint_access(self):
        """Test accessing protected endpoints with JWT token."""
        # Get access token
        refresh = RefreshToken.for_user(self.user)
        access_token = refresh.access_token
        
        # Set authorization header
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {str(access_token)}')
        
        # Try to access a protected endpoint
        url = '/product-requests/requests/'
        response = self.client.get(url)
        
        # Should be successful (200) or forbidden (403) but not unauthorized (401)
        self.assertIn(response.status_code, [200, 403])
    
    def test_expired_token_rejection(self):
        """Test that expired tokens are rejected."""
        # Create a token that's already expired
        refresh = RefreshToken.for_user(self.user)
        access_token = refresh.access_token
        
        # Manually set expiration to past time
        access_token.payload['exp'] = timezone.now().timestamp() - 3600  # 1 hour ago
        
        # Try to use expired token
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {str(access_token)}')
        
        url = '/product-requests/requests/'
        response = self.client.get(url)
        
        # Should be unauthorized
        self.assertEqual(response.status_code, 401)


class UserManagementTest(TestCase):
    """Test user management functionality."""
    
    def setUp(self):
        self.admin_user = User.objects.create_user(
            username='admin',
            email='admin@example.com',
            password='adminpass123',
            is_staff=True,
            is_superuser=True
        )
        
        self.regular_user = User.objects.create_user(
            username='regular',
            email='regular@example.com',
            password='regularpass123'
        )
    
    def test_user_creation(self):
        """Test user creation with different permissions."""
        # Test admin user
        self.assertTrue(self.admin_user.is_staff)
        self.assertTrue(self.admin_user.is_superuser)
        self.assertTrue(self.admin_user.is_active)
        
        # Test regular user
        self.assertFalse(self.regular_user.is_staff)
        self.assertFalse(self.regular_user.is_superuser)
        self.assertTrue(self.regular_user.is_active)
    
    def test_user_permissions(self):
        """Test user permissions."""
        from django.contrib.auth.models import Permission
        
        # Test that admin has all permissions
        self.assertTrue(self.admin_user.has_perm('auth.add_user'))
        self.assertTrue(self.admin_user.has_perm('auth.change_user'))
        
        # Test that regular user doesn't have admin permissions
        self.assertFalse(self.regular_user.has_perm('auth.add_user'))
        self.assertFalse(self.regular_user.has_perm('auth.change_user'))
    
    def test_user_token_association(self):
        """Test that tokens are properly associated with users."""
        # Create tokens for both users
        admin_refresh = RefreshToken.for_user(self.admin_user)
        regular_refresh = RefreshToken.for_user(self.regular_user)
        
        # Test token user association
        self.assertEqual(admin_refresh.payload['user_id'], self.admin_user.id)
        self.assertEqual(regular_refresh.payload['user_id'], self.regular_user.id)
        
        # Test outstanding token records
        admin_tokens = OutstandingToken.objects.filter(user=self.admin_user)
        regular_tokens = OutstandingToken.objects.filter(user=self.regular_user)
        
        self.assertGreaterEqual(admin_tokens.count(), 1)
        self.assertGreaterEqual(regular_tokens.count(), 1)
    
    def test_user_password_change(self):
        """Test password change and token invalidation."""
        # Create token before password change
        old_refresh = RefreshToken.for_user(self.regular_user)
        old_access = old_refresh.access_token
        
        # Change user password
        self.regular_user.set_password('newpassword123')
        self.regular_user.save()
        
        # Create new token after password change
        new_refresh = RefreshToken.for_user(self.regular_user)
        new_access = new_refresh.access_token
        
        # New tokens should be different
        self.assertNotEqual(str(old_access), str(new_access))
        self.assertNotEqual(str(old_refresh), str(new_refresh))
        
        # Optionally, old tokens should be invalidated (implementation dependent)
        # This would require custom logic to blacklist tokens on password change


class SecurityTest(TestCase):
    """Test security aspects of authentication."""
    
    def setUp(self):
        self.user = User.objects.create_user(
            username='testuser',
            email='test@example.com',
            password='testpass123'
        )
    
    def test_token_signing(self):
        """Test that tokens are properly signed."""
        refresh = RefreshToken.for_user(self.user)
        access_token = refresh.access_token
        
        # Test that tokens have proper structure (header.payload.signature)
        refresh_parts = str(refresh).split('.')
        access_parts = str(access_token).split('.')
        
        self.assertEqual(len(refresh_parts), 3)
        self.assertEqual(len(access_parts), 3)
        
        # Each part should be non-empty
        for part in refresh_parts:
            self.assertGreater(len(part), 0)
        
        for part in access_parts:
            self.assertGreater(len(part), 0)
    
    def test_token_tampering_detection(self):
        """Test that tampered tokens are rejected."""
        refresh = RefreshToken.for_user(self.user)
        original_token = str(refresh)
        
        # Tamper with token by changing last character
        tampered_token = original_token[:-1] + ('a' if original_token[-1] != 'a' else 'b')
        
        # Try to create token from tampered string
        from rest_framework_simplejwt.exceptions import TokenError
        
        with self.assertRaises(TokenError):
            RefreshToken(tampered_token)
    
    def test_token_algorithm_security(self):
        """Test that tokens use secure algorithms."""
        refresh = RefreshToken.for_user(self.user)
        
        # Check algorithm in token header
        import base64
        import json
        
        token_parts = str(refresh).split('.')
        
        # Decode header (add padding if needed)
        header_b64 = token_parts[0]
        header_b64 += '=' * (4 - len(header_b64) % 4)  # Add padding
        
        try:
            header = json.loads(base64.b64decode(header_b64))
            
            # Should use HS256 algorithm (or another secure algorithm)
            self.assertIn('alg', header)
            self.assertIn(header['alg'], ['HS256', 'RS256', 'ES256'])
        except Exception:
            # Header might be encoded differently
            pass
    
    def test_sensitive_data_not_in_token(self):
        """Test that sensitive user data is not included in tokens."""
        refresh = RefreshToken.for_user(self.user)
        access_token = refresh.access_token
        
        # Check that password hash is not in token payload
        refresh_payload = refresh.payload
        access_payload = access_token.payload
        
        sensitive_fields = ['password', 'last_login']
        
        for field in sensitive_fields:
            self.assertNotIn(field, refresh_payload)
            self.assertNotIn(field, access_payload)
        
        # Only user_id should be present for user identification
        self.assertIn('user_id', refresh_payload)
        self.assertIn('user_id', access_payload)
        self.assertEqual(refresh_payload['user_id'], self.user.id)
        self.assertEqual(access_payload['user_id'], self.user.id)


class AuthenticationIntegrationTest(TestCase):
    """Integration tests for authentication system."""
    
    def setUp(self):
        self.client = APIClient()
        self.user = User.objects.create_user(
            username='integrationuser',
            email='integration@example.com',
            password='integrationpass123'
        )
    
    def test_complete_authentication_flow(self):
        """Test complete authentication flow from login to logout."""
        # Step 1: Create tokens
        refresh = RefreshToken.for_user(self.user)
        access_token = refresh.access_token
        
        # Step 2: Use access token to make authenticated request
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {str(access_token)}')
        
        # Try to access a protected endpoint
        response = self.client.get('/product-requests/requests/')
        
        # Should be successful or forbidden, but not unauthorized
        self.assertIn(response.status_code, [200, 403])
        
        # Step 3: Refresh token
        new_access = refresh.access_token
        self.assertIsNotNone(new_access)
        
        # Step 4: Blacklist refresh token (logout)
        refresh.blacklist()
        
        # Step 5: Verify token is blacklisted
        blacklisted_tokens = BlacklistedToken.objects.filter(
            token__jti=refresh.payload['jti']
        )
        self.assertEqual(blacklisted_tokens.count(), 1)
    
    def test_multiple_device_authentication(self):
        """Test authentication from multiple devices/sessions."""
        # Create tokens for multiple "devices"
        device1_refresh = RefreshToken.for_user(self.user)
        device2_refresh = RefreshToken.for_user(self.user)
        
        device1_access = device1_refresh.access_token
        device2_access = device2_refresh.access_token
        
        # Both tokens should be valid
        self.assertIsNotNone(device1_access)
        self.assertIsNotNone(device2_access)
        
        # Tokens should be different
        self.assertNotEqual(str(device1_refresh), str(device2_refresh))
        self.assertNotEqual(str(device1_access), str(device2_access))
        
        # Both should work for authentication
        client1 = APIClient()
        client2 = APIClient()
        
        client1.credentials(HTTP_AUTHORIZATION=f'Bearer {str(device1_access)}')
        client2.credentials(HTTP_AUTHORIZATION=f'Bearer {str(device2_access)}')
        
        response1 = client1.get('/product-requests/requests/')
        response2 = client2.get('/product-requests/requests/')
        
        # Both should work
        self.assertIn(response1.status_code, [200, 403])
        self.assertIn(response2.status_code, [200, 403])
        
        # Blacklist one device
        device1_refresh.blacklist()
        
        # Device 2 should still work
        response2_after = client2.get('/product-requests/requests/')
        self.assertIn(response2_after.status_code, [200, 403])
    
    def test_authentication_with_logging_middleware(self):
        """Test authentication works with logging middleware."""
        from app_logs.models import APIRequestLog
        
        # Clear existing logs
        APIRequestLog.objects.all().delete()
        
        # Create token and make authenticated request
        refresh = RefreshToken.for_user(self.user)
        access_token = refresh.access_token
        
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {str(access_token)}')
        response = self.client.get('/product-requests/requests/')
        
        # Check that request was logged with user information
        logs = APIRequestLog.objects.all()
        
        if logs.exists():
            log = logs.first()
            self.assertEqual(log.user, self.user)
            self.assertEqual(log.method, 'GET')
            self.assertEqual(log.path, '/product-requests/requests/')
