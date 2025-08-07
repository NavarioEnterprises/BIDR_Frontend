# BIDR Authentication Service - Comprehensive Test Documentation

## Overview
This document provides detailed information about all test cases, endpoints, parameters, and expected outputs for the BIDR Authentication Service. The service includes the following apps:

- **User App**: User management, authentication, and profile management
- **OTP App**: One-time password verification and management
- **Permissions App**: Role-based access control and permissions
- **User Sessions App**: Session management and tracking
- **API Management App**: API key management and access control
- **Analytics App**: Authentication and usage analytics
- **Security App**: Security monitoring and audit logs
- **Auth Logs App**: Authentication event logging

---

## Test Environment Setup

### Prerequisites
```bash
# Install dependencies
pip install -r requirements.txt

# Run migrations
python manage.py makemigrations
python manage.py migrate

# Create test database
python manage.py test --keepdb
```

### Running Tests
```bash
# Run all tests
python manage.py test

# Run tests for specific app
python manage.py test user
python manage.py test otp
python manage.py test permissions

# Run with coverage
coverage run --source='.' manage.py test
coverage report
```

---

## 1. USER APP TESTS

### 1.1 Authentication Endpoints

#### User Login
- **Endpoint**: `POST /login/`
- **Purpose**: Authenticate user and return JWT tokens
- **Test Cases**:

| Test Name | Input Parameters | Expected Status | Expected Output |
|-----------|-----------------|----------------|-----------------|
| `test_successful_login` | `{"email": "test@example.com", "password": "testpass123"}` | 200 | `{"message": "Login successful", "access_token": "...", "refresh_token": "...", "user": {...}}` |
| `test_login_with_invalid_credentials` | `{"email": "test@example.com", "password": "wrongpass"}` | 400 | `{"error": "Invalid credentials"}` |
| `test_login_unverified_email` | `{"email": "unverified@example.com", "password": "testpass123"}` | 400 | `{"error": "Please verify your email before logging in."}` |
| `test_login_missing_fields` | `{"email": "test@example.com"}` | 400 | `{"error": "Must include email and password"}` |

#### User Logout
- **Endpoint**: `POST /logout/`
- **Purpose**: Invalidate user session and blacklist refresh token
- **Authentication**: Required (Bearer token)

| Test Name | Input Parameters | Expected Status | Expected Output |
|-----------|-----------------|----------------|-----------------|
| `test_successful_logout` | `{"refresh_token": "..."}` | 200 | `{"message": "Logout successful"}` |
| `test_logout_without_authentication` | `{}` | 401 | `{"detail": "Authentication credentials were not provided."}` |
| `test_logout_invalid_token` | `{"refresh_token": "invalid"}` | 400 | `{"error": "Invalid token"}` |

#### Password Reset Request
- **Endpoint**: `POST /password-reset-request/`
- **Purpose**: Send password reset email to user

| Test Name | Input Parameters | Expected Status | Expected Output |
|-----------|-----------------|----------------|-----------------|
| `test_password_reset_request` | `{"email": "test@example.com"}` | 200 | `{"message": "Password reset link sent to your email"}` |
| `test_password_reset_request_invalid_email` | `{"email": "nonexistent@example.com"}` | 400 | `{"error": "User with this email does not exist"}` |

#### Password Reset
- **Endpoint**: `POST /password-reset/`
- **Purpose**: Reset user password with valid token

| Test Name | Input Parameters | Expected Status | Expected Output |
|-----------|-----------------|----------------|-----------------|
| `test_password_reset_with_valid_token` | `{"uid": "...", "token": "...", "password": "newpass123", "confirm_password": "newpass123"}` | 200 | `{"message": "Password reset successful"}` |
| `test_password_reset_with_invalid_token` | `{"uid": "...", "token": "invalid", "password": "newpass123", "confirm_password": "newpass123"}` | 400 | `{"error": "Invalid or expired token"}` |
| `test_password_reset_password_mismatch` | `{"uid": "...", "token": "...", "password": "pass1", "confirm_password": "pass2"}` | 400 | `{"error": "Passwords don't match"}` |

### 1.2 Profile Management

#### User Profile
- **Endpoint**: `GET/PATCH /profile/`
- **Purpose**: Retrieve or update user profile
- **Authentication**: Required

| Test Name | HTTP Method | Input Parameters | Expected Status | Expected Output |
|-----------|-------------|-----------------|----------------|-----------------|
| `test_get_user_profile` | GET | `{}` | 200 | `{"id": 1, "email": "test@example.com", "first_name": "John", ...}` |
| `test_update_user_profile` | PATCH | `{"first_name": "Jane", "last_name": "Smith"}` | 200 | `{"id": 1, "first_name": "Jane", "last_name": "Smith", ...}` |
| `test_profile_unauthorized_access` | GET | `{}` (no auth) | 401 | `{"detail": "Authentication credentials were not provided."}` |

### 1.3 Role Selection

#### Role Selection
- **Endpoint**: `POST /role-selection/`
- **Purpose**: Select user role before registration

| Test Name | Input Parameters | Expected Status | Expected Output |
|-----------|-----------------|----------------|-----------------|
| `test_valid_role_selection` | `{"role": "buyer"}` | 200 | `{"message": "Role 'buyer' selected. Proceed to registration.", "role": "buyer"}` |
| `test_invalid_role_selection` | `{"role": "invalid_role"}` | 400 | `{"error": "Invalid role selected"}` |
| `test_administrator_role_selection` | `{"role": "administrator"}` | 400 | `{"error": "Invalid role selected. Must be 'buyer' or 'seller'."}` |

---

## 2. OTP APP TESTS

### 2.1 OTP Verification

#### OTP Verification
- **Endpoint**: `POST /verify-otp/`
- **Purpose**: Verify one-time password for email verification

| Test Name | Input Parameters | Expected Status | Expected Output |
|-----------|-----------------|----------------|-----------------|
| `test_successful_otp_verification` | `{"email": "test@example.com", "otp": "123456"}` | 200 | `{"message": "OTP verified successfully"}` |
| `test_otp_verification_with_invalid_code` | `{"email": "test@example.com", "otp": "999999"}` | 400 | `{"error": "Invalid OTP code"}` |
| `test_otp_verification_with_invalid_email` | `{"email": "nonexistent@example.com", "otp": "123456"}` | 400 | `{"error": "User not found"}` |
| `test_otp_verification_with_expired_otp` | `{"email": "test@example.com", "otp": "654321"}` (expired) | 400 | `{"error": "OTP has expired"}` |
| `test_otp_verification_missing_fields` | `{"email": "test@example.com"}` | 400 | `{"error": "OTP is required"}` |

#### Resend OTP
- **Endpoint**: `POST /resend-otp/`
- **Purpose**: Resend OTP to user's email

| Test Name | Input Parameters | Expected Status | Expected Output |
|-----------|-----------------|----------------|-----------------|
| `test_successful_otp_resend` | `{"email": "test@example.com"}` | 200 | `{"message": "OTP sent successfully"}` |
| `test_otp_resend_with_invalid_email` | `{"email": "nonexistent@example.com"}` | 404 | `{"error": "User not found"}` |
| `test_otp_resend_missing_email` | `{}` | 404 | `{"error": "User not found"}` |

### 2.2 OTP Model Tests

| Test Name | Test Scenario | Expected Result |
|-----------|---------------|-----------------|
| `test_create_otp` | Create new OTP instance | OTP created with valid UUID and expiration |
| `test_otp_is_expired_false` | Check unexpired OTP | `otp.is_expired()` returns `False` |
| `test_otp_is_expired_true` | Check expired OTP | `otp.is_expired()` returns `True` |
| `test_validate_for_device` | Device-specific validation | Returns `True` for valid device, `False` for invalid |
| `test_default_expires_at` | Default expiration time | OTP expires 5 minutes from creation |

---

## 3. PERMISSIONS APP TESTS

### 3.1 Permission Management

#### Permission Model Tests

| Test Name | Test Scenario | Expected Result |
|-----------|---------------|-----------------|
| `test_create_permission` | Create new permission | Permission created with correct attributes |
| `test_permission_clean_custom_without_description` | Custom permission without description | Raises `ValidationError` |
| `test_permission_clean_custom_with_description` | Custom permission with description | Validation passes |

### 3.2 Role Management

#### UserRoleType Model Tests

| Test Name | Test Scenario | Expected Result |
|-----------|---------------|-----------------|
| `test_create_role_type` | Create new role type | Role created successfully |
| `test_get_permissions_list` | Get role permissions | Returns list of active permissions |
| `test_has_permission` | Check role permission | Returns `True` if permission exists |
| `test_get_module_permissions` | Get permissions by module | Returns permissions for specific module |

### 3.3 User Permission Management

#### UserPermissionManager Tests

| Test Name | Test Scenario | Expected Result |
|-----------|---------------|-----------------|
| `test_get_user_permissions` | Get effective user permissions | Returns combined role and direct permissions |
| `test_user_has_permission_true` | Check user has permission | Returns `True` for granted permission |
| `test_user_has_permission_denied` | Check denied permission | Returns `False` for denied permission |
| `test_expired_role_excluded` | Expired role permissions | Excludes permissions from expired roles |
| `test_expired_permission_excluded` | Expired direct permissions | Excludes expired direct permissions |

---

## 4. USER SESSIONS APP TESTS

### 4.1 Session Management

#### UserSession Model Tests

| Test Name | Test Scenario | Expected Result |
|-----------|---------------|-----------------|
| `test_create_user_session` | Create new session | Session created with correct attributes |
| `test_session_is_expired_false` | Check active session | Returns `False` for active session |
| `test_session_is_expired_true` | Check expired session | Returns `True` for expired session |
| `test_end_session` | End session | Sets `is_active=False` and `logged_out_at` |

### 4.2 Session API Endpoints

#### Session List
- **Endpoint**: `GET /api/sessions/`
- **Purpose**: List user's active sessions
- **Authentication**: Required

| Test Name | Expected Status | Expected Output |
|-----------|----------------|-----------------|
| `test_list_user_sessions` | 200 | Array of session objects |
| `test_unauthorized_access` | 401 | Authentication error |

#### End Session
- **Endpoint**: `POST /api/sessions/{id}/end/`
- **Purpose**: End specific session
- **Authentication**: Required

| Test Name | Expected Status | Expected Output |
|-----------|----------------|-----------------|
| `test_end_session` | 200 | `{"message": "Session ended successfully"}` |

#### End All Sessions
- **Endpoint**: `POST /api/sessions/end-all/`
- **Purpose**: End all user sessions
- **Authentication**: Required

| Test Name | Expected Status | Expected Output |
|-----------|----------------|-----------------|
| `test_end_all_sessions` | 200 | `{"message": "All sessions ended successfully"}` |

---

## 5. API MANAGEMENT APP TESTS

### 5.1 API Key Management

#### API Key Model Tests

| Test Name | Test Scenario | Expected Result |
|-----------|---------------|-----------------|
| `test_create_api_key` | Create new API key | Key created with valid attributes |
| `test_api_key_is_expired` | Check key expiration | Returns correct expiration status |
| `test_api_key_rate_limit` | Rate limiting check | Enforces configured rate limits |

### 5.2 API Key Endpoints

#### Create API Key
- **Endpoint**: `POST /api/api-management/keys/`
- **Purpose**: Create new API key
- **Authentication**: Required

| Test Name | Input Parameters | Expected Status | Expected Output |
|-----------|-----------------|----------------|-----------------|
| `test_create_api_key` | `{"name": "Test Key", "permissions": ["read"]}` | 201 | `{"key": "...", "name": "Test Key", "created_at": "..."}` |

#### List API Keys
- **Endpoint**: `GET /api/api-management/keys/`
- **Purpose**: List user's API keys
- **Authentication**: Required

| Test Name | Expected Status | Expected Output |
|-----------|----------------|-----------------|
| `test_list_api_keys` | 200 | Array of API key objects |

#### Revoke API Key
- **Endpoint**: `DELETE /api/api-management/keys/{id}/`
- **Purpose**: Revoke API key
- **Authentication**: Required

| Test Name | Expected Status | Expected Output |
|-----------|----------------|-----------------|
| `test_revoke_api_key` | 200 | `{"message": "API key revoked successfully"}` |

---

## 6. ANALYTICS APP TESTS

### 6.1 Authentication Analytics

#### Login Analytics
- **Endpoint**: `GET /api/analytics/login-stats/`
- **Purpose**: Get login statistics
- **Authentication**: Required (Admin)

| Test Name | Query Parameters | Expected Status | Expected Output |
|-----------|------------------|----------------|-----------------|
| `test_login_stats_daily` | `{"period": "daily", "days": 7}` | 200 | `{"labels": [...], "data": [...]}` |
| `test_login_stats_monthly` | `{"period": "monthly", "months": 6}` | 200 | `{"labels": [...], "data": [...]}` |

#### User Activity Analytics
- **Endpoint**: `GET /api/analytics/user-activity/`
- **Purpose**: Get user activity metrics
- **Authentication**: Required (Admin)

| Test Name | Query Parameters | Expected Status | Expected Output |
|-----------|------------------|----------------|-----------------|
| `test_user_activity` | `{"user_id": 1, "days": 30}` | 200 | `{"total_logins": 45, "avg_session_duration": "25m", ...}` |

### 6.2 Security Analytics

#### Failed Login Attempts
- **Endpoint**: `GET /api/analytics/failed-logins/`
- **Purpose**: Monitor failed login attempts
- **Authentication**: Required (Admin)

| Test Name | Query Parameters | Expected Status | Expected Output |
|-----------|------------------|----------------|-----------------|
| `test_failed_login_stats` | `{"hours": 24}` | 200 | `{"total_attempts": 23, "unique_ips": 5, "top_ips": [...]}` |

---

## 7. SECURITY APP TESTS

### 7.1 Security Monitoring

#### Security Alert Model Tests

| Test Name | Test Scenario | Expected Result |
|-----------|---------------|-----------------|
| `test_create_security_alert` | Create security alert | Alert created with correct severity |
| `test_resolve_security_alert` | Resolve alert | Alert marked as resolved |
| `test_escalate_security_alert` | Escalate alert | Alert severity increased |

### 7.2 Audit Logging

#### Audit Log Tests

| Test Name | Test Scenario | Expected Result |
|-----------|---------------|-----------------|
| `test_create_audit_log` | Create audit entry | Log entry created with user action |
| `test_filter_audit_logs` | Filter by user/action | Returns filtered results |
| `test_audit_log_retention` | Log retention policy | Old logs archived/deleted |

---

## 8. AUTH LOGS APP TESTS

### 8.1 Authentication Event Logging

#### AuthLog Model Tests

| Test Name | Test Scenario | Expected Result |
|-----------|---------------|-----------------|
| `test_log_successful_login` | Log successful login | Creates log entry with success status |
| `test_log_failed_login` | Log failed login attempt | Creates log entry with failure details |
| `test_log_logout_event` | Log user logout | Creates log entry for logout event |

### 8.2 Log Analysis

#### Log Analytics Tests

| Test Name | Test Scenario | Expected Result |
|-----------|---------------|-----------------|
| `test_get_login_patterns` | Analyze login patterns | Returns user login frequency data |
| `test_detect_anomalies` | Detect unusual activity | Identifies suspicious login patterns |
| `test_generate_security_report` | Generate security reports | Creates comprehensive security summary |

---

## Test Data Setup

### Sample User Data
```json
{
  "email": "test@example.com",
  "password": "testpass123",
  "first_name": "John",
  "last_name": "Doe",
  "phone_number": "+1234567890",
  "role": "buyer"
}
```

### Sample Admin User Data
```json
{
  "email": "admin@example.com",
  "password": "adminpass123",
  "first_name": "Admin",
  "last_name": "User",
  "phone_number": "+1234567891",
  "role": "administrator",
  "is_superuser": true
}
```

### Sample API Key Data
```json
{
  "name": "Test API Key",
  "permissions": ["read", "write"],
  "rate_limit": 1000,
  "expires_at": "2024-12-31T23:59:59Z"
}
```

---

## Performance Test Scenarios

### Load Testing Parameters

| Scenario | Concurrent Users | Duration | Expected Response Time |
|----------|------------------|----------|----------------------|
| Login Load Test | 100 | 5 minutes | < 500ms |
| OTP Verification Load | 50 | 3 minutes | < 200ms |
| Profile Update Load | 25 | 2 minutes | < 300ms |
| API Key Creation Load | 10 | 1 minute | < 100ms |

### Stress Testing Parameters

| Scenario | Peak Users | Ramp-up Time | Expected Behavior |
|----------|------------|--------------|-------------------|
| Authentication Stress | 500 | 60 seconds | Graceful degradation |
| Database Stress | 1000 queries/sec | 30 seconds | No data corruption |
| Memory Stress | 95% memory usage | 120 seconds | No crashes |

---

## Security Test Cases

### Authentication Security

| Test Case | Attack Vector | Expected Defense |
|-----------|---------------|------------------|
| Brute Force Login | 100 failed attempts | Account lockout after 5 attempts |
| SQL Injection | Malicious SQL in login | Parameterized queries prevent injection |
| XSS Attack | Script tags in user input | Input sanitization and escaping |
| CSRF Attack | Cross-site request forgery | CSRF tokens required |
| JWT Token Manipulation | Modified JWT payload | Token validation fails |

### Data Security

| Test Case | Scenario | Expected Result |
|-----------|----------|-----------------|
| Password Hashing | Store user password | Password is hashed with salt |
| Sensitive Data Logging | Log user actions | Passwords/tokens not logged |
| Data Encryption | Store API keys | Keys encrypted at rest |
| Secure Headers | HTTP responses | Security headers present |

---

## Test Coverage Requirements

### Minimum Coverage Targets

| App | Line Coverage | Branch Coverage | Function Coverage |
|-----|---------------|-----------------|-------------------|
| User App | 95% | 90% | 100% |
| OTP App | 90% | 85% | 95% |
| Permissions App | 95% | 90% | 100% |
| User Sessions App | 85% | 80% | 90% |
| API Management App | 90% | 85% | 95% |
| Analytics App | 80% | 75% | 85% |
| Security App | 95% | 90% | 100% |
| Auth Logs App | 85% | 80% | 90% |

### Coverage Commands
```bash
# Generate coverage report
coverage run --source='.' manage.py test
coverage html
coverage report --show-missing

# Check coverage for specific app
coverage run --source='user' manage.py test user
coverage report
```

---

## Continuous Integration Test Pipeline

### Test Stages

1. **Unit Tests**: Individual component testing
2. **Integration Tests**: Component interaction testing
3. **API Tests**: Endpoint functionality testing
4. **Security Tests**: Vulnerability scanning
5. **Performance Tests**: Load and stress testing
6. **End-to-End Tests**: Complete workflow testing

### CI/CD Configuration Example
```yaml
# .github/workflows/tests.yml
name: Django Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    
    services:
      postgres:
        image: postgres:13
        env:
          POSTGRES_PASSWORD: postgres
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
    
    steps:
    - uses: actions/checkout@v2
    - name: Set up Python
      uses: actions/setup-python@v2
      with:
        python-version: 3.9
    
    - name: Install dependencies
      run: |
        pip install -r requirements.txt
        pip install coverage
    
    - name: Run tests with coverage
      run: |
        coverage run --source='.' manage.py test
        coverage report --fail-under=85
        coverage html
    
    - name: Upload coverage reports
      uses: codecov/codecov-action@v1
```

---

## Test Environment Configuration

### Test Settings
```python
# settings/test.py
from .base import *

# Test database
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': ':memory:',
    }
}

# Disable migrations for faster tests
class DisableMigrations:
    def __contains__(self, item):
        return True
    def __getitem__(self, item):
        return None

MIGRATION_MODULES = DisableMigrations()

# Test-specific settings
EMAIL_BACKEND = 'django.core.mail.backends.locmem.EmailBackend'
CELERY_TASK_ALWAYS_EAGER = True
CACHES = {
    'default': {
        'BACKEND': 'django.core.cache.backends.locmem.LocMemCache',
    }
}
```

### Test Fixtures
```python
# fixtures/test_data.py
import pytest
from django.contrib.auth import get_user_model
from user.models import AppUser

@pytest.fixture
def test_user():
    return AppUser.objects.create_user(
        email='test@example.com',
        password='testpass123',
        first_name='Test',
        last_name='User',
        phone_number='+1234567890',
        role='buyer'
    )

@pytest.fixture
def admin_user():
    return AppUser.objects.create_superuser(
        email='admin@example.com',
        password='adminpass123',
        first_name='Admin',
        last_name='User',
        phone_number='+1234567891'
    )
```

---

This comprehensive test documentation provides detailed information about all test cases, endpoints, parameters, and expected outputs for the BIDR Authentication Service. Use this document as a reference for writing, maintaining, and executing tests across all applications in the service.
