# BIDR Authentication Service API Documentation

## Overview

The BIDR Authentication Service provides comprehensive user management with encrypted personally identifiable information (PII), role-based access control, address management, and secure authentication flows.

## Base URL

```
http://localhost:8000/
```


## Authentication

Most endpoints require JWT authentication. Include the token in the Authorization header:

```
Authorization: Bearer <your_jwt_token>
```

---

## 🔐 **Authentication Flow**

The complete user authentication flow consists of:
1. **Role Selection** → Select user type (buyer/seller)
2. **User Registration** → Create account with email verification
3. **OTP Verification** → Verify email with OTP code
4. **User Login** → Authenticate and receive JWT tokens
5. **Access Protected Resources** → Use access token for API calls
6. **Session Management** → Track and manage user sessions
7. **User Logout** → Invalidate tokens and end session

---

## 📋 **Table of Contents**

1. [Health Check Endpoints](#health-check-endpoints)
2. [Authentication Endpoints](#authentication-endpoints)
3. [User Management Endpoints](#user-management-endpoints)
4. [Seller Management Endpoints](#seller-management-endpoints)
5. [OTP Management Endpoints](#otp-management-endpoints)
6. [Password Reset Endpoints](#password-reset-endpoints)
7. [Address Management Endpoints](#address-management-endpoints)
8. [Error Handling](#error-handling)
9. [Authentication & Authorization](#authentication--authorization)
10. [Rate Limiting](#rate-limiting)
11. [Examples & Use Cases](#examples--use-cases)

---

## 🏥 **Health Check Endpoints**

### 1. Basic Health Check
**Endpoint**: `GET /health/`  
**Purpose**: Check if the service is running  
**Authentication**: None required

#### Request Example:
```bash
curl -X GET http://localhost:8000/health/
```

#### Response Example:
```json
{
    "status": "healthy",
    "service": "authentication_service",
    "timestamp": 1754099500.506977
}
```

**Response Codes:**
- `200 OK` - Service is healthy
- `500 Internal Server Error` - Service is down

---

### 2. Readiness Check
**Endpoint**: `GET /health/ready/`  
**Purpose**: Check if service is ready to accept requests  
**Authentication**: None required

#### Request Example:
```bash
curl -X GET http://localhost:8000/health/ready/
```

#### Response Example:
```json
{
    "database": true,
    "status": "ready",
    "timestamp": 1754099662.0236
}
```

**Response Codes:**
- `200 OK` - Service is ready
- `503 Service Unavailable` - Service is not ready

---

### 3. Liveness Check
**Endpoint**: `GET /health/live/`  
**Purpose**: Check if service is alive  
**Authentication**: None required

#### Request Example:
```bash
curl -X GET http://localhost:8000/health/live/
```

#### Response Example:
```json
{
    "status": "alive",
    "service": "authentication_service",
    "timestamp": 1754099581.718163
}
```

---

## 🔐 **Authentication Endpoints**

### 1. Role Selection
**Endpoint**: `POST /role-selection/`  
**Purpose**: Select user role before registration  
**Authentication**: None required

#### Request Parameters:
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `role` | string | Yes | User role: "buyer" or "seller" |

#### Request Example:
```bash
curl -X POST http://localhost:8000/role-selection/ \
  -H "Content-Type: application/json" \
  -d '{"role": "buyer"}'
```

#### Response Example (Success):
```json
{
    "message": "Role 'buyer' selected. Proceed to registration.",
    "role": "buyer"
}
```

#### Response Example (Error):
```json
{
    "role": ["Invalid role selected. Must be 'buyer' or 'seller'."]
}
```

**Response Codes:**
- `200 OK` - Role selected successfully
- `400 Bad Request` - Invalid role or validation error

---

### 2. User Registration
**Endpoint**: `POST /register/`  
**Purpose**: Register a new user account  
**Authentication**: None required

#### Request Parameters:
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `email` | string | Yes | User's email address |
| `first_name` | string | Yes | User's first name |
| `last_name` | string | Yes | User's last name |
| `phone_number` | string | Yes | User's phone number |
| `role` | string | Yes | User role: "buyer" or "seller" |
| `password` | string | Yes | Password (min 8 chars, complex) |
| `confirm_password` | string | Yes | Password confirmation |

#### Request Example:
```bash
curl -X POST http://localhost:8000/register/ \
  -H "Content-Type: application/json" \
  -d '{
    "email": "alice.smith@example.com",
    "first_name": "Alice",
    "last_name": "Smith", 
    "phone_number": "+1987654321",
    "role": "buyer",
    "password": "SecurePass123!",
    "confirm_password": "SecurePass123!"
}'
```

#### Response Example (Success):
```json
{
    "message": "User registered successfully. Please verify your email.",
    "user_id": 2,
    "email": "alice.smith@example.com",
    "otp_code": "992638",
    "note": "OTP code included for testing purposes"
}
```

#### Response Example (Error):
```json
{
    "phone_number": ["App User with this phone number already exists."]
}
```

**Response Codes:**
- `201 Created` - User registered successfully
- `400 Bad Request` - Validation errors

---

### 3. User Login
**Endpoint**: `POST /login/`  
**Purpose**: Authenticate user and receive JWT tokens  
**Authentication**: None required

#### Request Parameters:
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `email` | string | Yes | User's email address |
| `password` | string | Yes | User's password |

#### Request Example:
```bash
curl -X POST http://localhost:8000/login/ \
  -H "Content-Type: application/json" \
  -d '{
    "email": "alice.smith@example.com",
    "password": "SecurePass123!"
}'
```

#### Response Example (Success):
```json
{
    "message": "Login successful",
    "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoiYWNjZXNzIiwiZXhwIjoxNzU0MTAzMjMxLCJpYXQiOjE3NTQwOTk2MzEsImp0aSI6ImM2MGFkZDFlNWFlYjQ2YzY4MTgwOWU0MjY5MTE2MjE5IiwidXNlcl9pZCI6IjIifQ.kA2eTeaUwGnCOw9FM23pGRPJ7myyU6Wj8EU0fdTPUME",
    "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc1NDcwNDQzMSwiaWF0IjoxNzU0MDk5NjMxLCJqdGkiOiJmZTQ2YzgwOGU1OTc0MDIxODM3NzNhZjM4ZGIxZDMzMSIsInVzZXJfaWQiOiIyIn0.qIsZKVMUJeEjPbWBT0dzBPxG1wOnFlMz3dLnCBT9W7g",
    "user": {
        "id": 2,
        "uid": "54787e81-10e1-4d34-95cc-43b25930dd81",
        "email": "alice.smith@example.com",
        "first_name": "Alice",
        "last_name": "Smith",
        "phone_number": "+1987654321",
        "email_verified": true,
        "phone_verified": false,
        "role": "buyer",
        "is_verified": true,
        "is_suspended": false,
        "created_at": "2025-08-02T01:53:25.299279Z"
    }
}
```

#### Response Example (Error - Email Not Verified):
```json
{
    "error": "Please verify your email before logging in."
}
```

#### Response Example (Error - Invalid Credentials):
```json
{
    "non_field_errors": ["Invalid credentials"]
}
```

**Response Codes:**
- `200 OK` - Login successful
- `400 Bad Request` - Invalid credentials or email not verified

---

### 4. User Logout
**Endpoint**: `POST /logout/`  
**Purpose**: Logout user and blacklist refresh token  
**Authentication**: Required (Bearer token)

#### Request Parameters:
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `refresh_token` | string | Yes | JWT refresh token to blacklist |

#### Request Example:
```bash
curl -X POST http://localhost:8000/logout/ \
  -H "Authorization: Bearer ACCESS_TOKEN_HERE" \
  -H "Content-Type: application/json" \
  -d '{
    "refresh_token": "REFRESH_TOKEN_HERE"
}'
```

#### Response Example (Success):
```json
{
    "message": "Logout successful"
}
```

#### Response Example (Error):
```json
{
    "error": "Invalid token"
}
```

**Response Codes:**
- `200 OK` - Logout successful
- `400 Bad Request` - Invalid token
- `401 Unauthorized` - Authentication required

---

## 👤 **User Management Endpoints**

### 1. Get User Profile
**Endpoint**: `GET /profile/`  
**Purpose**: Retrieve current user's profile information  
**Authentication**: Required (Bearer token)

#### Request Example:
```bash
curl -X GET http://localhost:8000/profile/ \
  -H "Authorization: Bearer ACCESS_TOKEN_HERE"
```

#### Response Example (Success):
```json
{
    "id": 2,
    "uid": "54787e81-10e1-4d34-95cc-43b25930dd81",
    "email": "alice.smith@example.com",
    "first_name": "Alice",
    "last_name": "Smith",
    "phone_number": "+1987654321",
    "email_verified": true,
    "phone_verified": false,
    "role": "buyer",
    "is_verified": true,
    "is_suspended": false,
    "created_at": "2025-08-02T01:53:25.299279Z"
}
```

**Response Codes:**
- `200 OK` - Profile retrieved successfully
- `401 Unauthorized` - Authentication required

---

### 2. Update User Profile
**Endpoint**: `PATCH /profile/`  
**Purpose**: Update current user's profile information  
**Authentication**: Required (Bearer token)

#### Request Parameters:
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `first_name` | string | No | User's first name |
| `last_name` | string | No | User's last name |
| `phone_number` | string | No | User's phone number |

#### Request Example:
```bash
curl -X PATCH http://localhost:8000/profile/ \
  -H "Authorization: Bearer ACCESS_TOKEN_HERE" \
  -H "Content-Type: application/json" \
  -d '{
    "first_name": "Alice Updated",
    "last_name": "Smith Updated"
}'
```

#### Response Example (Success):
```json
{
    "id": 2,
    "uid": "54787e81-10e1-4d34-95cc-43b25930dd81",
    "email": "alice.smith@example.com",
    "first_name": "Alice Updated",
    "last_name": "Smith Updated",
    "phone_number": "+1987654321",
    "email_verified": true,
    "phone_verified": false,
    "role": "buyer",
    "is_verified": true,
    "is_suspended": false,
    "created_at": "2025-08-02T01:53:25.299279Z"
}
```

**Response Codes:**
- `200 OK` - Profile updated successfully
- `400 Bad Request` - Validation errors
- `401 Unauthorized` - Authentication required

---

## 📧 **OTP Management Endpoints**

### 1. Verify OTP
**Endpoint**: `POST /verify-otp/`  
**Purpose**: Verify OTP code for email verification  
**Authentication**: None required

#### Request Parameters:
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `email` | string | Yes | User's email address |
| `otp` | string | Yes | 6-digit OTP code |

#### Request Example:
```bash
curl -X POST http://localhost:8000/verify-otp/ \
  -H "Content-Type: application/json" \
  -d '{
    "email": "alice.smith@example.com",
    "otp": "992638"
}'
```

#### Response Example (Success):
```json
{
    "message": "OTP verified successfully"
}
```

#### Response Example (Error):
```json
{
    "non_field_errors": ["Invalid OTP code"]
}
```

**Response Codes:**
- `200 OK` - OTP verified successfully
- `400 Bad Request` - Invalid OTP or expired

---

### 2. Resend OTP
**Endpoint**: `POST /resend-otp/`  
**Purpose**: Resend OTP code to user's email  
**Authentication**: None required

#### Request Parameters:
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `email` | string | Yes | User's email address |

#### Request Example:
```bash
curl -X POST http://localhost:8000/resend-otp/ \
  -H "Content-Type: application/json" \
  -d '{
    "email": "alice.smith@example.com"
}'
```

#### Response Example (Success):
```json
{
    "message": "OTP sent successfully"
}
```

#### Response Example (Error):
```json
{
    "error": "User not found"
}
```

**Response Codes:**
- `200 OK` - OTP sent successfully
- `404 Not Found` - User not found
- `500 Internal Server Error` - Failed to send OTP

---

## 🔑 **Password Reset Endpoints**

### 1. Request Password Reset
**Endpoint**: `POST /password-reset-request/`  
**Purpose**: Request password reset link via email  
**Authentication**: None required

#### Request Parameters:
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `email` | string | Yes | User's email address |

#### Request Example:
```bash
curl -X POST http://localhost:8000/password-reset-request/ \
  -H "Content-Type: application/json" \
  -d '{
    "email": "alice.smith@example.com"
}'
```

#### Response Example (Success):
```json
{
    "message": "Password reset link sent to your email"
}
```

#### Response Example (Error):
```json
{
    "email": ["User with this email does not exist"]
}
```

**Response Codes:**
- `200 OK` - Reset link sent successfully
- `400 Bad Request` - User not found

---

### 2. Reset Password
**Endpoint**: `POST /password-reset/`  
**Purpose**: Reset password using token from email  
**Authentication**: None required

#### Request Parameters:
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `uid` | string | Yes | User ID (base64 encoded) |
| `token` | string | Yes | Password reset token |
| `password` | string | Yes | New password |
| `confirm_password` | string | Yes | Password confirmation |

#### Request Example:
```bash
curl -X POST http://localhost:8000/password-reset/ \
  -H "Content-Type: application/json" \
  -d '{
    "uid": "MQ",
    "token": "reset_token_here",
    "password": "NewSecurePass123!",
    "confirm_password": "NewSecurePass123!"
}'
```

#### Response Example (Success):
```json
{
    "message": "Password reset successful"
}
```

#### Response Example (Error):
```json
{
    "error": "Invalid or expired token"
}
```

**Response Codes:**
- `200 OK` - Password reset successful
- `400 Bad Request` - Invalid token or validation errors

---

## ⚠️ **Error Handling**

### Common Error Response Format:
```json
{
    "error": "Error description",
    "field_errors": {
        "field_name": ["Field-specific error message"]
    },
    "timestamp": "2025-08-02T01:53:25.299279Z"
}
```

### HTTP Status Codes:

| Status Code | Description | Common Causes |
|-------------|-------------|---------------|
| `200 OK` | Request successful | Valid request processed |
| `201 Created` | Resource created | User registration, etc. |
| `400 Bad Request` | Invalid request | Validation errors, invalid data |
| `401 Unauthorized` | Authentication required | Missing or invalid token |
| `403 Forbidden` | Access denied | Insufficient permissions |
| `404 Not Found` | Resource not found | Invalid endpoint or user |
| `429 Too Many Requests` | Rate limit exceeded | Too many requests |
| `500 Internal Server Error` | Server error | System issues |

### Common Error Scenarios:

#### 1. Authentication Errors:
```json
{
    "detail": "Authentication credentials were not provided."
}
```

#### 2. Validation Errors:
```json
{
    "email": ["This field is required."],
    "password": ["This password is too short."]
}
```

#### 3. Business Logic Errors:
```json
{
    "error": "Please verify your email before logging in."
}
```

---

## 🔐 **Authentication & Authorization**

### JWT Token Usage:

#### 1. Include in Request Headers:
```bash
Authorization: Bearer YOUR_ACCESS_TOKEN_HERE
```

#### 2. Token Structure:
- **Access Token**: Short-lived (1 hour), used for API requests
- **Refresh Token**: Long-lived (7 days), used to get new access tokens

#### 3. Token Refresh (Implementation needed):
```bash
curl -X POST http://localhost:8000/token/refresh/ \
  -H "Content-Type: application/json" \
  -d '{"refresh": "REFRESH_TOKEN_HERE"}'
```

### Protected Endpoints:
- `GET/PATCH /profile/` - User profile management
- `POST /logout/` - User logout
- Future: Session management, API key management, etc.

---

## 🚦 **Rate Limiting**

### Current Implementation:
- No explicit rate limiting implemented
- Django's built-in protections apply

### Recommended Limits:
- **Authentication endpoints**: 5 requests/minute
- **OTP endpoints**: 3 requests/5 minutes
- **General API**: 100 requests/hour

---

## 📝 **Examples & Use Cases**

### Complete User Registration Flow:

#### Step 1: Select Role
```bash
curl -X POST http://localhost:8000/role-selection/ \
  -H "Content-Type: application/json" \
  -d '{"role": "buyer"}'
```

#### Step 2: Register User
```bash
curl -X POST http://localhost:8000/register/ \
  -H "Content-Type: application/json" \
  -d '{
    "email": "newuser@example.com",
    "first_name": "New",
    "last_name": "User",
    "phone_number": "+1555123456",
    "role": "buyer",
    "password": "SecurePass123!",
    "confirm_password": "SecurePass123!"
}'
```

#### Step 3: Verify Email with OTP
```bash
curl -X POST http://localhost:8000/verify-otp/ \
  -H "Content-Type: application/json" \
  -d '{
    "email": "newuser@example.com",
    "otp": "123456"
}'
```

#### Step 4: Login
```bash
curl -X POST http://localhost:8000/login/ \
  -H "Content-Type: application/json" \
  -d '{
    "email": "newuser@example.com",
    "password": "SecurePass123!"
}'
```

#### Step 5: Access Protected Resources
```bash
curl -X GET http://localhost:8000/profile/ \
  -H "Authorization: Bearer ACCESS_TOKEN_FROM_LOGIN"
```

### Session Management Flow:

#### 1. Login creates session tracking
- JWT tokens issued
- Session stored in user_sessions table
- Device and location info captured

#### 2. API calls with session tracking
- Access token validates requests
- Session activity updated
- Security monitoring active

#### 3. Logout ends session
- Refresh token blacklisted
- Session marked as terminated
- Security audit logged

---

## 🔧 **Development & Testing**

### Running the Service:
```bash
cd /path/to/authentication_service
python3 manage.py runserver 8000
```

### Testing Endpoints:
```bash
# Health check
curl http://localhost:8000/health/

# Complete auth flow
curl -X POST http://localhost:8000/role-selection/ -H "Content-Type: application/json" -d '{"role": "buyer"}'
curl -X POST http://localhost:8000/register/ -H "Content-Type: application/json" -d '{"email": "test@example.com", "first_name": "Test", "last_name": "User", "phone_number": "+1234567890", "role": "buyer", "password": "SecurePass123!", "confirm_password": "SecurePass123!"}'
curl -X POST http://localhost:8000/verify-otp/ -H "Content-Type: application/json" -d '{"email": "test@example.com", "otp": "OTP_FROM_REGISTRATION"}'
curl -X POST http://localhost:8000/login/ -H "Content-Type: application/json" -d '{"email": "test@example.com", "password": "SecurePass123!"}'
```

---

## 📚 **Additional Resources**

### Related Documentation:
- [Test Documentation](TEST_DOCUMENTATION.md)
- [Database Schema](SCHEMA.md)
- [Security Guidelines](SECURITY.md)

### API Collections:
- **Postman Collection**: Available for import
- **Insomnia Collection**: Available for import
- **OpenAPI/Swagger**: `/api/docs/` (if enabled)

### Support:
- **Issues**: GitHub Issues
- **Documentation**: This file
- **Testing**: Comprehensive test suite available

---

## 📊 **Data Models**

### AppUser Model

The core user model with encrypted PII fields and comprehensive profile management.

#### Basic Fields
- `id` (BigAutoField): Primary key
- `uid` (UUIDField): Unique identifier
- `email` (EmailField): User email (unique)
- `first_name` (CharField): Encrypted first name
- `last_name` (CharField): Encrypted last name
- `phone_number` (CharField): Encrypted primary phone number (unique)

#### Profile Information (Encrypted PII)
- `middle_name` (CharField): Encrypted middle name
- `date_of_birth` (CharField): Encrypted date of birth
- `gender` (CharField): Gender (male, female, other, prefer_not_to_say)
- `nationality` (CharField): User nationality
- `occupation` (CharField): User occupation
- `company_name` (CharField): Company name

#### Contact Information
- `alternative_phone` (CharField): Encrypted alternative phone
- `alternative_email` (EmailField): Alternative email address

#### Profile Settings
- `profile_picture` (ImageField): Profile picture upload
- `bio` (TextField): User biography (max 500 chars)
- `website` (URLField): Personal website
- `linkedin_profile` (URLField): LinkedIn profile URL

#### Preferences
- `preferred_language` (CharField): Language code (default: 'en')
- `user_timezone` (CharField): User timezone (default: 'UTC')
- `currency_preference` (CharField): ISO currency code (default: 'USD')

#### Notification Preferences
- `email_notifications` (BooleanField): Email notifications enabled (default: True)
- `sms_notifications` (BooleanField): SMS notifications enabled (default: False)
- `push_notifications` (BooleanField): Push notifications enabled (default: True)
- `marketing_emails` (BooleanField): Marketing emails enabled (default: False)

#### Privacy Settings
- `profile_visibility` (CharField): Profile visibility (public, private, friends - default: public)
- `show_email` (BooleanField): Show email in profile (default: False)
- `show_phone` (BooleanField): Show phone in profile (default: False)

#### Status and Verification
- `email_verified` (BooleanField): Email verification status
- `phone_verified` (BooleanField): Phone verification status
- `profile_status` (CharField): Profile completion status (incomplete, complete, verified)
- `role` (CharField): User role (administrator, buyer, seller)
- `is_active` (BooleanField): Account active status
- `is_verified` (BooleanField): Overall verification status
- `is_suspended` (BooleanField): Account suspension status

### Address Model

User address model with encrypted PII fields and primary address logic.

#### Primary Keys and Relationships
- `address_id` (UUIDField): Primary key
- `user` (ForeignKey): Related user
- `business_id` (UUIDField): Optional business ID

#### Address Information (Encrypted PII)
- `address_line_1` (CharField): Encrypted address line 1
- `address_line_2` (CharField): Encrypted address line 2 (optional)
- `city` (CharField): Encrypted city
- `state_province` (CharField): Encrypted state/province
- `postal_code` (CharField): Encrypted postal code
- `country` (CharField): Encrypted country

#### Geographic Coordinates
- `latitude` (DecimalField): Address latitude (optional)
- `longitude` (DecimalField): Address longitude (optional)

#### Address Metadata
- `address_type` (CharField): Address type (home, business, shipping, billing - default: home)
- `is_primary` (BooleanField): Primary address flag (default: False)
- `address_name` (CharField): Optional address name
- `delivery_instructions` (TextField): Special delivery instructions

---

## 🏠 **Address Management Endpoints**

### 1. List User Addresses
**Endpoint**: `GET /addresses/`  
**Purpose**: Get all addresses for the authenticated user  
**Authentication**: Required (Bearer token)

#### Request Example:
```bash
curl -X GET http://localhost:8000/addresses/ \
  -H "Authorization: Bearer ACCESS_TOKEN_HERE"
```

#### Response Example (Success):
```json
{
    "count": 2,
    "results": [
        {
            "address_id": "456e7890-e89b-12d3-a456-426614174001",
            "address_line_1": "123 Main St",
            "address_line_2": "Apt 4B",
            "city": "New York",
            "state_province": "NY",
            "postal_code": "10001",
            "country": "USA",
            "address_type": "home",
            "is_primary": true,
            "address_name": "Home",
            "delivery_instructions": "Ring doorbell",
            "latitude": "40.7128",
            "longitude": "-74.0060",
            "created_at": "2025-01-01T10:00:00Z",
            "updated_at": "2025-01-01T10:00:00Z"
        }
    ]
}
```

**Response Codes:**
- `200 OK` - Addresses retrieved successfully
- `401 Unauthorized` - Authentication required

---

### 2. Create New Address
**Endpoint**: `POST /addresses/`  
**Purpose**: Create a new address for the authenticated user  
**Authentication**: Required (Bearer token)

#### Request Parameters:
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `address_line_1` | string | Yes | Street address line 1 |
| `address_line_2` | string | No | Street address line 2 |
| `city` | string | Yes | City name |
| `state_province` | string | Yes | State or province |
| `postal_code` | string | Yes | Postal/ZIP code |
| `country` | string | Yes | Country name |
| `address_type` | string | No | home, business, shipping, billing (default: home) |
| `is_primary` | boolean | No | Set as primary address (default: false) |
| `address_name` | string | No | Custom name for address |
| `delivery_instructions` | string | No | Special delivery instructions |
| `latitude` | decimal | No | Address latitude |
| `longitude` | decimal | No | Address longitude |

#### Request Example:
```bash
curl -X POST http://localhost:8000/addresses/ \
  -H "Authorization: Bearer ACCESS_TOKEN_HERE" \
  -H "Content-Type: application/json" \
  -d '{
    "address_line_1": "789 New Street",
    "address_line_2": "Floor 3",
    "city": "Boston",
    "state_province": "MA",
    "postal_code": "02101",
    "country": "USA",
    "address_type": "shipping",
    "address_name": "Shipping Address",
    "delivery_instructions": "Leave at front door"
}'
```

#### Response Example (Success):
```json
{
    "message": "Address created successfully",
    "address": {
        "address_id": "456e7890-e89b-12d3-a456-426614174003",
        "address_line_1": "789 New Street",
        "address_line_2": "Floor 3",
        "city": "Boston",
        "state_province": "MA",
        "postal_code": "02101",
        "country": "USA",
        "address_type": "shipping",
        "is_primary": false,
        "address_name": "Shipping Address",
        "delivery_instructions": "Leave at front door",
        "created_at": "2025-01-02T10:00:00Z",
        "updated_at": "2025-01-02T10:00:00Z"
    }
}
```

**Response Codes:**
- `201 Created` - Address created successfully
- `400 Bad Request` - Validation errors
- `401 Unauthorized` - Authentication required

---

### 3. Get Specific Address
**Endpoint**: `GET /addresses/{address_id}/`  
**Purpose**: Get details of a specific address  
**Authentication**: Required (Bearer token)

#### Request Example:
```bash
curl -X GET http://localhost:8000/addresses/456e7890-e89b-12d3-a456-426614174001/ \
  -H "Authorization: Bearer ACCESS_TOKEN_HERE"
```

#### Response Example (Success):
```json
{
    "address_id": "456e7890-e89b-12d3-a456-426614174001",
    "address_line_1": "123 Main St",
    "address_line_2": "Apt 4B",
    "city": "New York",
    "state_province": "NY",
    "postal_code": "10001",
    "country": "USA",
    "address_type": "home",
    "is_primary": true,
    "address_name": "Home",
    "delivery_instructions": "Ring doorbell",
    "latitude": "40.7128",
    "longitude": "-74.0060",
    "created_at": "2025-01-01T10:00:00Z",
    "updated_at": "2025-01-01T10:00:00Z"
}
```

**Response Codes:**
- `200 OK` - Address retrieved successfully
- `404 Not Found` - Address not found
- `401 Unauthorized` - Authentication required

---

### 4. Update Address
**Endpoint**: `PUT /addresses/{address_id}/`  
**Purpose**: Update an existing address  
**Authentication**: Required (Bearer token)

#### Request Example:
```bash
curl -X PUT http://localhost:8000/addresses/456e7890-e89b-12d3-a456-426614174001/ \
  -H "Authorization: Bearer ACCESS_TOKEN_HERE" \
  -H "Content-Type: application/json" \
  -d '{
    "address_line_1": "123 Main Street Updated",
    "address_line_2": "Apartment 4B",
    "city": "New York",
    "state_province": "NY",
    "postal_code": "10001",
    "country": "USA",
    "address_name": "Primary Home",
    "delivery_instructions": "Ring doorbell twice"
}'
```

#### Response Example (Success):
```json
{
    "message": "Address updated successfully",
    "address": {
        "address_id": "456e7890-e89b-12d3-a456-426614174001",
        "address_line_1": "123 Main Street Updated",
        "address_line_2": "Apartment 4B",
        "city": "New York",
        "state_province": "NY",
        "postal_code": "10001",
        "country": "USA",
        "address_type": "home",
        "is_primary": true,
        "address_name": "Primary Home",
        "delivery_instructions": "Ring doorbell twice",
        "updated_at": "2025-01-02T10:30:00Z"
    }
}
```

**Response Codes:**
- `200 OK` - Address updated successfully
- `400 Bad Request` - Validation errors
- `404 Not Found` - Address not found
- `401 Unauthorized` - Authentication required

---

### 5. Delete Address
**Endpoint**: `DELETE /addresses/{address_id}/`  
**Purpose**: Soft delete an address  
**Authentication**: Required (Bearer token)

#### Request Example:
```bash
curl -X DELETE http://localhost:8000/addresses/456e7890-e89b-12d3-a456-426614174001/ \
  -H "Authorization: Bearer ACCESS_TOKEN_HERE"
```

#### Response Example (Success):
```json
{
    "message": "Address deleted successfully"
}
```

**Response Codes:**
- `200 OK` - Address deleted successfully
- `404 Not Found` - Address not found
- `401 Unauthorized` - Authentication required

---

### 6. Set Primary Address
**Endpoint**: `POST /addresses/{address_id}/set-primary/`  
**Purpose**: Set an address as primary for its type  
**Authentication**: Required (Bearer token)

#### Request Example:
```bash
curl -X POST http://localhost:8000/addresses/456e7890-e89b-12d3-a456-426614174001/set-primary/ \
  -H "Authorization: Bearer ACCESS_TOKEN_HERE"
```

#### Response Example (Success):
```json
{
    "message": "Address set as primary successfully",
    "address": {
        "address_id": "456e7890-e89b-12d3-a456-426614174001",
        "address_type": "home",
        "is_primary": true,
        "address_name": "Home"
    }
}
```

**Response Codes:**
- `200 OK` - Address set as primary successfully
- `404 Not Found` - Address not found
- `401 Unauthorized` - Authentication required

---

### 7. Get Primary Address
**Endpoint**: `GET /addresses/primary/`  
**Purpose**: Get the user's primary address  
**Authentication**: Required (Bearer token)

#### Request Example:
```bash
curl -X GET http://localhost:8000/addresses/primary/ \
  -H "Authorization: Bearer ACCESS_TOKEN_HERE"
```

#### Response Example (Success):
```json
{
    "address_id": "456e7890-e89b-12d3-a456-426614174001",
    "address_line_1": "123 Main St",
    "address_line_2": "Apt 4B",
    "city": "New York",
    "state_province": "NY",
    "postal_code": "10001",
    "country": "USA",
    "address_type": "home",
    "is_primary": true,
    "address_name": "Home"
}
```

**Response Codes:**
- `200 OK` - Primary address retrieved successfully
- `404 Not Found` - No primary address found
- `401 Unauthorized` - Authentication required

---

### 8. Get Addresses by Type
**Endpoint**: `GET /addresses/type/{address_type}/`  
**Purpose**: Get addresses filtered by type  
**Authentication**: Required (Bearer token)

#### Request Example:
```bash
curl -X GET http://localhost:8000/addresses/type/home/ \
  -H "Authorization: Bearer ACCESS_TOKEN_HERE"
```

#### Response Example (Success):
```json
{
    "address_type": "home",
    "count": 1,
    "addresses": [
        {
            "address_id": "456e7890-e89b-12d3-a456-426614174001",
            "address_line_1": "123 Main St",
            "address_line_2": "Apt 4B",
            "city": "New York",
            "state_province": "NY",
            "postal_code": "10001",
            "country": "USA",
            "address_type": "home",
            "is_primary": true,
            "address_name": "Home"
        }
    ]
}
```

**Response Codes:**
- `200 OK` - Addresses retrieved successfully
- `400 Bad Request` - Invalid address type
- `401 Unauthorized` - Authentication required

---

## 🔒 **Enhanced Profile Endpoints**

### 1. Get Comprehensive Profile
**Endpoint**: `GET /profile/comprehensive/`  
**Purpose**: Get complete user profile with all details including addresses  
**Authentication**: Required (Bearer token)

#### Request Example:
```bash
curl -X GET http://localhost:8000/profile/comprehensive/ \
  -H "Authorization: Bearer ACCESS_TOKEN_HERE"
```

#### Response Example (Success):
```json
{
    "id": 1,
    "uid": "123e4567-e89b-12d3-a456-426614174000",
    "email": "user@example.com",
    "first_name": "John",
    "middle_name": "Michael",
    "last_name": "Doe",
    "phone_number": "+1234567890",
    "alternative_phone": "+0987654321",
    "alternative_email": "john.alt@example.com",
    "date_of_birth": "1990-01-01",
    "gender": "male",
    "nationality": "American",
    "occupation": "Software Engineer",
    "company_name": "Tech Corp",
    "profile_picture": "/media/profile_pictures/user123.jpg",
    "bio": "Experienced software engineer with passion for technology.",
    "website": "https://johndoe.dev",
    "linkedin_profile": "https://linkedin.com/in/johndoe",
    "preferred_language": "en",
    "timezone": "America/New_York",
    "currency_preference": "USD",
    "email_notifications": true,
    "sms_notifications": false,
    "push_notifications": true,
    "marketing_emails": false,
    "profile_visibility": "public",
    "show_email": false,
    "show_phone": false,
    "email_verified": true,
    "phone_verified": true,
    "profile_status": "complete",
    "role": "buyer",
    "is_active": true,
    "is_verified": true,
    "is_suspended": false,
    "addresses": [
        {
            "address_id": "456e7890-e89b-12d3-a456-426614174001",
            "address_line_1": "123 Main St",
            "address_line_2": "Apt 4B",
            "city": "New York",
            "state_province": "NY",
            "postal_code": "10001",
            "country": "USA",
            "address_type": "home",
            "is_primary": true,
            "address_name": "Home"
        }
    ],
    "primary_address": {
        "address_id": "456e7890-e89b-12d3-a456-426614174001",
        "address_line_1": "123 Main St",
        "city": "New York",
        "country": "USA",
        "is_primary": true
    }
}
```

**Response Codes:**
- `200 OK` - Profile retrieved successfully
- `401 Unauthorized` - Authentication required

---

### 2. Update Profile Comprehensive
**Endpoint**: `PUT /profile/update/`  
**Purpose**: Update comprehensive user profile information  
**Authentication**: Required (Bearer token)

#### Request Parameters:
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `first_name` | string | No | User's first name |
| `middle_name` | string | No | User's middle name |
| `last_name` | string | No | User's last name |
| `date_of_birth` | string | No | Date of birth (YYYY-MM-DD) |
| `gender` | string | No | Gender (male, female, other, prefer_not_to_say) |
| `nationality` | string | No | User nationality |
| `occupation` | string | No | User occupation |
| `company_name` | string | No | Company name |
| `bio` | string | No | User biography (max 500 chars) |
| `website` | string | No | Personal website URL |
| `linkedin_profile` | string | No | LinkedIn profile URL |
| `preferred_language` | string | No | Language code (e.g., 'en', 'es') |
| `timezone` | string | No | User timezone |
| `currency_preference` | string | No | ISO currency code |
| `email_notifications` | boolean | No | Email notifications preference |
| `sms_notifications` | boolean | No | SMS notifications preference |
| `push_notifications` | boolean | No | Push notifications preference |
| `marketing_emails` | boolean | No | Marketing emails preference |
| `profile_visibility` | string | No | Profile visibility (public, private, friends) |
| `show_email` | boolean | No | Show email in profile |
| `show_phone` | boolean | No | Show phone in profile |

#### Request Example:
```bash
curl -X PUT http://localhost:8000/profile/update/ \
  -H "Authorization: Bearer ACCESS_TOKEN_HERE" \
  -H "Content-Type: application/json" \
  -d '{
    "first_name": "John",
    "middle_name": "Michael",
    "last_name": "Doe",
    "date_of_birth": "1990-01-01",
    "gender": "male",
    "occupation": "Senior Software Engineer",
    "bio": "Senior software engineer with 10+ years experience.",
    "preferred_language": "en",
    "timezone": "America/New_York",
    "email_notifications": true,
    "profile_visibility": "public"
}'
```

#### Response Example (Success):
```json
{
    "message": "Profile updated successfully",
    "user": {
        "uid": "123e4567-e89b-12d3-a456-426614174000",
        "email": "user@example.com",
        "first_name": "John",
        "middle_name": "Michael",
        "last_name": "Doe",
        "occupation": "Senior Software Engineer",
        "bio": "Senior software engineer with 10+ years experience.",
        "profile_status": "complete"
    }
}
```

**Response Codes:**
- `200 OK` - Profile updated successfully
- `400 Bad Request` - Validation errors
- `401 Unauthorized` - Authentication required

---

### 3. Get User Preferences
**Endpoint**: `GET /profile/preferences/`  
**Purpose**: Get user preferences and settings  
**Authentication**: Required (Bearer token)

#### Request Example:
```bash
curl -X GET http://localhost:8000/profile/preferences/ \
  -H "Authorization: Bearer ACCESS_TOKEN_HERE"
```

#### Response Example (Success):
```json
{
    "preferred_language": "en",
    "timezone": "America/New_York",
    "currency_preference": "USD",
    "email_notifications": true,
    "sms_notifications": false,
    "push_notifications": true,
    "marketing_emails": false,
    "profile_visibility": "public",
    "show_email": false,
    "show_phone": false
}
```

**Response Codes:**
- `200 OK` - Preferences retrieved successfully
- `401 Unauthorized` - Authentication required

---

### 4. Get Profile Completion
**Endpoint**: `GET /profile/completion/`  
**Purpose**: Get profile completion status and percentage  
**Authentication**: Required (Bearer token)

#### Request Example:
```bash
curl -X GET http://localhost:8000/profile/completion/ \
  -H "Authorization: Bearer ACCESS_TOKEN_HERE"
```

#### Response Example (Success):
```json
{
    "completion_percentage": 85.5,
    "profile_status": "complete",
    "missing_fields": [
        "profile_picture",
        "linkedin_profile"
    ],
    "completed_sections": {
        "basic_info": true,
        "contact_info": true,
        "personal_info": true,
        "preferences": true,
        "address": true
    }
}
```

**Response Codes:**
- `200 OK` - Completion status retrieved successfully
- `401 Unauthorized` - Authentication required

---

## 🔐 **Data Encryption**

### Encrypted Fields

The following fields are automatically encrypted before storage:

**User Model:**
- `first_name`
- `last_name`
- `middle_name`
- `phone_number`
- `alternative_phone`
- `date_of_birth`

**Address Model:**
- `address_line_1`
- `address_line_2`
- `city`
- `state_province`
- `postal_code`
- `country`

### Security Features

1. **JWT Authentication**: Secure token-based authentication
2. **PII Encryption**: Automatic encryption of sensitive data
3. **Role-based Access Control**: User roles with appropriate permissions
4. **Input Validation**: Comprehensive validation of all inputs
5. **Rate Limiting**: Protection against abuse and brute force attacks
6. **CORS Configuration**: Proper cross-origin resource sharing setup
7. **Secure Password Hashing**: Django's built-in password hashing
8. **Token Blacklisting**: Logout functionality with token invalidation

---

## 🔒 **Seller Management Endpoints**

### 1. Seller Registration
**Endpoint**: `POST /api/seller/register/`  
**Purpose**: Register a new seller account  
**Authentication**: None required

#### Request Parameters:
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `email` | string | Yes | Seller's email address |
| `fullname` | string | Yes | Full name of the seller |
| `phone_number` | string | Yes | Seller's phone number |
| `password` | string | Yes | Secure password |
| `confirm_password` | string | Yes | Password confirmation |

#### Request Example:
```bash
curl -X POST http://localhost:8000/api/seller/register/ \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test.seller@example.com",
    "fullname": "Test Seller",
    "phone_number": "0123456789",
    "password": "TestStrong@Password123",
    "confirm_password": "TestStrong@Password123"
}'
```

#### Response Example (Success):
```json
{
    "message": "Seller registered successfully. Please verify your email.",
    "user_id": 3,
    "email": "test.seller@example.com"
}
```

**Response Codes:**
- `201 Created` - Seller registered successfully
- `400 Bad Request` - Validation errors

---

### 2. Seller Login
**Endpoint**: `POST /login/`  
**Purpose**: Authenticate seller and receive JWT tokens  
**Authentication**: None required

#### Request Parameters:
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `email` | string | Yes | Seller's email address |
| `password` | string | Yes | Seller's password |

#### Request Example:
```bash
curl -X POST http://localhost:8000/login/ \
  -H "Content-Type: application/json" \
  -d '{
    "email": "verified.seller@example.com",
    "password": "TestStrong@Password123"
}'
```

#### Response Example (Success):
```json
{
    "message": "Login successful",
    "access_token": "<JWT_ACCESS_TOKEN>",
    "refresh_token": "<JWT_REFRESH_TOKEN>",
    "user": {
        "id": 4,
        "email": "verified.seller@example.com",
        "role": "seller",
        "email_verified": true,
        "profile_completion_percentage": 33.33
    }
}
```

**Response Codes:**
- `200 OK` - Login successful
- `400 Bad Request` - Invalid credentials

---

### 3. Business Registration
**Endpoint**: `POST /api/seller/business-registration/`  
**Purpose**: Register business details for seller  
**Authentication**: Required (Bearer token)

#### Request Example:
```bash
curl -X POST http://localhost:8000/api/seller/business-registration/ \
  -H "Authorization: Bearer ACCESS_TOKEN_HERE" \
  -H "Content-Type: application/json" \
  -d '{
    "company_details": {
        "registered_company_name": "Test Company Ltd",
        "trading_name": "Test Company",
        "registration_number": "12345678",
        "vat_number": "4567890123",
        "website_url": "https://testcompany.com",
        "product_category": "Automotive Parts",
        "product_subcategory": "engine_parts"
    },
    "address_details": {
        "physical_address": "123 Business Street, Business District",
        "postal_address": "PO Box 456, Business City",
        "city": "Cape Town",
        "province": "Western Cape",
        "postal_code": "8000",
        "country": "South Africa",
        "contact_person_name": "John Doe",
        "contact_person_telephone": "0123456789",
        "contact_person_email_address": "john@testcompany.com",
        "platform_workflow_email_address": "workflow@testcompany.com",
        "latitude": -33.9249,
        "longitude": 18.4241
    },
    "bank_details": {
        "bank_name": "Standard Bank",
        "bank_account_number": "1234567890",
        "bank_branch_code": "051001",
        "bank_account_type": "Business Cheque Account"
    }
}'
```

#### Response Example (Success):
```json
{
    "message": "Business registration completed successfully"
}
```

**Response Codes:**
- `201 Created` - Business registered successfully
- `400 Bad Request` - Validation errors

---

### 4. Seller Profiles List
**Endpoint**: `GET /api/seller/profiles/`  
**Purpose**: List all seller profiles  
**Authentication**: Required (Bearer token)

#### Request Example:
```bash
curl -X GET http://localhost:8000/api/seller/profiles/ \
  -H "Authorization: Bearer ACCESS_TOKEN_HERE"
```

#### Response Example (Success):
```json
{
  "count": 1,
  "results": [{
    "id": "059c4b5b-cd8e-471b-8a74-7e8ba42c10f1",
    "seller": 1,
    "seller_email": "verified.seller@example.com",
    "approval_status": "pending",
    "vendor_id": "V63D148B9",
    "display_name": "Test Company",
    "background_check_authorized": false,
    "total_quotes_submitted": 0,
    "total_deals_won": 0,
    "average_rating": null,
    "created_at": "2025-08-02T10:45:29.132833Z"
  }]
}
```

**Response Codes:**
- `200 OK` - Profiles retrieved successfully
- `401 Unauthorized` - Authentication required

---

### 5. Document Upload
**Endpoint**: `POST /api/seller/document-upload/`  
**Purpose**: Upload seller documents  
**Authentication**: Required (Bearer token)

#### Request Example:
```bash
curl -X POST http://localhost:8000/api/seller/document-upload/ \
  -H "Authorization: Bearer ACCESS_TOKEN_HERE" \
  -H "Content-Type: application/json" \
  -d '{
    "certificate_of_incorporation_status": "pending",
    "company_extract_status": "pending"
}'
```

#### Response Example (Success):
```json
{
    "message": "Documents uploaded successfully"
}
```

**Response Codes:**
- `200 OK` - Documents uploaded successfully
- `400 Bad Request` - Validation errors

---

### 6. Performance Metrics
**Endpoint**: `GET /api/seller/profiles/{profile_id}/performance_metrics/`  
**Purpose**: Get seller performance metrics  
**Authentication**: Required (Bearer token)

#### Request Example:
```bash
curl -X GET http://localhost:8000/api/seller/profiles/059c4b5b-cd8e-471b-8a74-7e8ba42c10f1/performance_metrics/ \
  -H "Authorization: Bearer ACCESS_TOKEN_HERE"
```

#### Response Example (Success):
```json
{
  "total_quotes_submitted": 0,
  "total_deals_won": 0,
  "total_deals_completed": 0,
  "win_rate": 0,
  "completion_rate": 0.0,
  "average_rating": null,
  "response_rate": 0.0
}
```

**Response Codes:**
- `200 OK` - Performance metrics retrieved successfully
- `401 Unauthorized` - Authentication required

---

## 🧪 **Testing**

The API includes comprehensive test coverage:
- Unit tests for models and business logic
- Integration tests for API endpoints
- Authentication and authorization tests
- Data validation and encryption tests

Run tests with:
```bash
python manage.py test user.tests -v 2
```

---

## 🔧 **Admin Interface**

A comprehensive Django admin interface is available at `/admin/` with:
- User management with encrypted field support
- Address management with inline editing
- Role-based permissions for admin users
- Bulk operations for user and address management
- Visual indicators for verification and status

---

**Last Updated**: August 2, 2025  
**Version**: 2.0.0  
**Service Status**: Production Ready ✅
