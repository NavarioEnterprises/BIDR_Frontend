# BIDR Chat Service API Testing Documentation

This document provides comprehensive API testing information including endpoints, request/response examples, and test data for the BIDR Chat Service.

## Table of Contents
1. [Authentication](#authentication)
2. [User Profile APIs](#user-profile-apis)
3. [Conversation APIs](#conversation-apis)
4. [Messaging APIs](#messaging-apis)
5. [File Upload APIs](#file-upload-apis)
6. [Notification APIs](#notification-apis)
7. [Privacy & Moderation APIs](#privacy--moderation-apis)
8. [Translation APIs](#translation-apis)
9. [WebSocket Events](#websocket-events)
10. [Test Data](#test-data)

## Authentication

### Login
```http
POST /api/auth/login/
Content-Type: application/json

{
    "username": "testuser",
    "password": "testpass123"
}
```

**Response:**
```json
{
    "token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
    "user": {
        "id": 1,
        "username": "testuser",
        "email": "test@example.com",
        "first_name": "Test",
        "last_name": "User"
    }
}
```

### Token Refresh
```http
POST /api/auth/token/refresh/
Content-Type: application/json
Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...

{
    "refresh": "refresh_token_here"
}
```

## User Profile APIs

### Get User Profile
```http
GET /api/users/profile/
Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...
```

**Response:**
```json
{
    "id": 1,
    "username": "testuser",
    "email": "test@example.com",
    "profile": {
        "display_name": "Test User",
        "bio": "Software developer passionate about chat applications",
        "avatar_url": "https://example.com/avatars/user1.jpg",
        "timezone": "UTC",
        "language_preference": "en",
        "is_online": true,
        "last_seen": "2024-01-20T10:30:00Z",
        "privacy_settings": {
            "show_online_status": true,
            "allow_message_previews": false,
            "profile_visibility": "contacts_only"
        }
    }
}
```

### Update User Profile
```http
PUT /api/users/profile/
Content-Type: application/json
Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...

{
    "display_name": "Updated Display Name",
    "bio": "Updated bio text",
    "timezone": "America/New_York",
    "language_preference": "es",
    "privacy_settings": {
        "show_online_status": false,
        "allow_message_previews": true,
        "profile_visibility": "public"
    }
}
```

### Get Language Preferences
```http
GET /api/users/language-preferences/
Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...
```

**Response:**
```json
{
    "primary_language": "en",
    "secondary_languages": ["es", "fr"],
    "auto_translate": true,
    "translation_provider": "google",
    "created_at": "2024-01-15T08:00:00Z",
    "updated_at": "2024-01-20T10:30:00Z"
}
```

## Conversation APIs

### List Conversations
```http
GET /api/conversations/
Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...
```

**Response:**
```json
{
    "count": 25,
    "next": "http://localhost:8000/api/conversations/?page=2",
    "previous": null,
    "results": [
        {
            "id": 101,
            "title": "Project Discussion",
            "conversation_type": "group",
            "created_at": "2024-01-18T14:30:00Z",
            "updated_at": "2024-01-20T11:45:00Z",
            "last_message": {
                "id": 1052,
                "content": "Let's schedule the meeting for tomorrow",
                "sender": {
                    "id": 2,
                    "username": "colleague",
                    "display_name": "John Colleague"
                },
                "created_at": "2024-01-20T11:45:00Z"
            },
            "participants_count": 5,
            "unread_count": 3,
            "is_archived": false,
            "is_pinned": true
        }
    ]
}
```

### Create Conversation
```http
POST /api/conversations/
Content-Type: application/json
Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...

{
    "title": "New Project Chat",
    "conversation_type": "group",
    "description": "Discussion about the new mobile app project",
    "participants": [2, 3, 4],
    "settings": {
        "allow_member_invites": true,
        "message_retention_days": 90,
        "auto_delete_enabled": false
    }
}
```

### Get Conversation Details
```http
GET /api/conversations/101/
Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...
```

**Response:**
```json
{
    "id": 101,
    "title": "Project Discussion",
    "conversation_type": "group",
    "description": "Team collaboration space",
    "created_at": "2024-01-18T14:30:00Z",
    "created_by": {
        "id": 1,
        "username": "testuser",
        "display_name": "Test User"
    },
    "participants": [
        {
            "id": 1,
            "user": {
                "id": 1,
                "username": "testuser",
                "display_name": "Test User"
            },
            "role": "owner",
            "joined_at": "2024-01-18T14:30:00Z",
            "is_active": true
        },
        {
            "id": 2,
            "user": {
                "id": 2,
                "username": "colleague",
                "display_name": "John Colleague"
            },
            "role": "admin",
            "joined_at": "2024-01-18T14:32:00Z",
            "is_active": true
        }
    ],
    "settings": {
        "allow_member_invites": true,
        "message_retention_days": 90,
        "auto_delete_enabled": false,
        "notification_level": "all"
    },
    "total_messages": 47,
    "last_message_at": "2024-01-20T11:45:00Z"
}
```

### Add Participants
```http
POST /api/conversations/101/participants/
Content-Type: application/json
Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...

{
    "user_ids": [5, 6],
    "role": "participant",
    "welcome_message": "Welcome to the project discussion!"
}
```

## Messaging APIs

### List Messages
```http
GET /api/conversations/101/messages/?page=1&page_size=20
Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...
```

**Response:**
```json
{
    "count": 47,
    "next": "http://localhost:8000/api/conversations/101/messages/?page=2",
    "previous": null,
    "results": [
        {
            "id": 1052,
            "content": "Let's schedule the meeting for tomorrow",
            "message_type": "text",
            "sender": {
                "id": 2,
                "username": "colleague",
                "display_name": "John Colleague",
                "avatar_url": "https://example.com/avatars/user2.jpg"
            },
            "created_at": "2024-01-20T11:45:00Z",
            "updated_at": "2024-01-20T11:45:00Z",
            "delivery_status": "delivered",
            "read_by": [
                {
                    "user_id": 1,
                    "read_at": "2024-01-20T11:46:00Z"
                }
            ],
            "reactions": [
                {
                    "reaction_type": "like",
                    "users": [1, 3],
                    "count": 2
                }
            ],
            "reply_to": null,
            "thread_id": null,
            "attachments": [],
            "mentions": [],
            "is_edited": false,
            "is_deleted": false
        }
    ]
}
```

### Send Message
```http
POST /api/conversations/101/messages/
Content-Type: application/json
Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...

{
    "content": "Thanks for the update! I'll review the documents tonight.",
    "message_type": "text",
    "mentions": [
        {
            "user_id": 2,
            "mention_text": "@colleague",
            "position_start": 45,
            "position_end": 55
        }
    ],
    "reply_to": 1051
}
```

**Response:**
```json
{
    "id": 1053,
    "content": "Thanks for the update! I'll review the documents tonight.",
    "message_type": "text",
    "sender": {
        "id": 1,
        "username": "testuser",
        "display_name": "Test User"
    },
    "created_at": "2024-01-20T12:00:00Z",
    "delivery_status": "sent",
    "message_hash": "abc123def456ghi789",
    "reply_to": {
        "id": 1051,
        "content": "Here are the project documents...",
        "sender": {
            "id": 2,
            "display_name": "John Colleague"
        }
    },
    "thread_id": 1051
}
```

### Edit Message
```http
PUT /api/messages/1053/
Content-Type: application/json
Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...

{
    "content": "Thanks for the update! I'll review the documents first thing tomorrow morning.",
    "edit_reason": "Added more specific timing"
}
```

### Add Message Reaction
```http
POST /api/messages/1053/reactions/
Content-Type: application/json
Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...

{
    "reaction_type": "love"
}
```

### Mark Message as Read
```http
POST /api/messages/1053/read/
Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...
```

### Get Message Translation
```http
POST /api/messages/1053/translate/
Content-Type: application/json
Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...

{
    "target_language": "es"
}
```

**Response:**
```json
{
    "id": 201,
    "message_id": 1053,
    "target_language": "es",
    "translated_content": "¡Gracias por la actualización! Revisaré los documentos mañana por la mañana.",
    "source_language": "en",
    "translation_service": "google",
    "confidence_score": 0.95,
    "created_at": "2024-01-20T12:05:00Z"
}
```

## File Upload APIs

### Upload File
```http
POST /api/files/upload/
Content-Type: multipart/form-data
Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...

file: [binary file data]
conversation_id: 101
message_id: 1054
filename: project_proposal.pdf
```

**Response:**
```json
{
    "id": 301,
    "file_url": "https://storage.example.com/files/abc123/project_proposal.pdf",
    "original_filename": "project_proposal.pdf",
    "file_size": 2048576,
    "file_size_display": "2.0 MB",
    "mime_type": "application/pdf",
    "file_type": "document",
    "upload_status": "completed",
    "scan_status": "pending",
    "is_safe": null,
    "created_at": "2024-01-20T12:10:00Z",
    "expires_at": null,
    "download_url": "https://api.example.com/files/301/download/",
    "thumbnail_url": "https://api.example.com/files/301/thumbnail/"
}
```

### Get File Info
```http
GET /api/files/301/
Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...
```

### Download File
```http
GET /api/files/301/download/
Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...
```

### Share File
```http
POST /api/files/301/share/
Content-Type: application/json
Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...

{
    "shared_with": [2, 3],
    "permission_level": "download",
    "expires_at": "2024-01-27T12:00:00Z",
    "is_password_protected": true,
    "password": "secure123"
}
```

**Response:**
```json
{
    "id": 401,
    "share_token": "abc123xyz789share",
    "share_url": "https://api.example.com/shared/abc123xyz789share",
    "permission_level": "download",
    "expires_at": "2024-01-27T12:00:00Z",
    "is_password_protected": true,
    "created_at": "2024-01-20T12:15:00Z"
}
```

## Notification APIs

### List Notifications
```http
GET /api/notifications/?unread_only=true
Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...
```

**Response:**
```json
{
    "count": 12,
    "unread_count": 7,
    "results": [
        {
            "id": 501,
            "notification_type": "new_message",
            "title": "New message from John Colleague",
            "message": "Let's schedule the meeting for tomorrow",
            "priority": "medium",
            "is_read": false,
            "created_at": "2024-01-20T11:45:00Z",
            "sender": {
                "id": 2,
                "username": "colleague",
                "display_name": "John Colleague"
            },
            "related_object": {
                "type": "message",
                "id": 1052,
                "conversation_id": 101
            },
            "action_url": "bidr://conversations/101/messages/1052"
        }
    ]
}
```

### Mark Notification as Read
```http
POST /api/notifications/501/read/
Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...
```

### Mark All Notifications as Read
```http
POST /api/notifications/mark-all-read/
Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...
```

### Get Notification Preferences
```http
GET /api/notifications/preferences/
Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...
```

**Response:**
```json
{
    "preferences": [
        {
            "notification_type": "new_message",
            "email_enabled": true,
            "push_enabled": true,
            "in_app_enabled": true,
            "sms_enabled": false,
            "frequency": "immediate",
            "quiet_hours_enabled": true,
            "quiet_hours_start": "22:00",
            "quiet_hours_end": "08:00"
        },
        {
            "notification_type": "mention",
            "email_enabled": true,
            "push_enabled": true,
            "in_app_enabled": true,
            "sms_enabled": true,
            "frequency": "immediate"
        }
    ]
}
```

### Update Notification Preferences
```http
PUT /api/notifications/preferences/
Content-Type: application/json
Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...

{
    "preferences": [
        {
            "notification_type": "new_message",
            "email_enabled": false,
            "push_enabled": true,
            "in_app_enabled": true,
            "frequency": "batched",
            "quiet_hours_enabled": true,
            "quiet_hours_start": "23:00",
            "quiet_hours_end": "07:00"
        }
    ]
}
```

## Privacy & Moderation APIs

### Get Data Masking Profile
```http
GET /api/privacy/masking-profile/
Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...
```

**Response:**
```json
{
    "id": 601,
    "profile_name": "Standard Protection",
    "masking_level": "partial",
    "mask_emails": true,
    "mask_phones": true,
    "mask_ssn": true,
    "mask_addresses": false,
    "mask_credit_cards": true,
    "custom_patterns": {
        "employee_id": "partial",
        "license_plate": "full"
    },
    "is_active": true,
    "created_at": "2024-01-15T10:00:00Z"
}
```

### Update Data Masking Profile
```http
PUT /api/privacy/masking-profile/
Content-Type: application/json
Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...

{
    "profile_name": "Enhanced Protection",
    "masking_level": "full",
    "mask_emails": true,
    "mask_phones": true,
    "mask_addresses": true,
    "custom_patterns": {
        "employee_id": "full"
    }
}
```

### Get Privacy Consent Status
```http
GET /api/privacy/consent/
Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...
```

**Response:**
```json
{
    "consents": [
        {
            "consent_type": "data_processing",
            "purpose": "chat_functionality",
            "consent_given": true,
            "consent_method": "explicit",
            "consent_version": "v2.0",
            "created_at": "2024-01-10T09:00:00Z",
            "expires_at": "2025-01-10T09:00:00Z"
        },
        {
            "consent_type": "analytics",
            "purpose": "service_improvement",
            "consent_given": false,
            "consent_withdrawn_at": "2024-01-15T14:30:00Z",
            "withdrawal_reason": "user_request"
        }
    ]
}
```

### Submit Data Deletion Request
```http
POST /api/privacy/deletion-request/
Content-Type: application/json
Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...

{
    "request_type": "partial_deletion",
    "reason": "user_request",
    "data_categories": ["messages", "file_attachments"],
    "additional_details": "Please delete all messages older than 6 months",
    "requested_completion_date": "2024-02-01"
}
```

**Response:**
```json
{
    "id": 701,
    "request_type": "partial_deletion",
    "status": "pending",
    "data_categories": ["messages", "file_attachments"],
    "created_at": "2024-01-20T13:00:00Z",
    "estimated_completion": "2024-01-30T00:00:00Z",
    "reference_number": "DEL-2024-701"
}
```

### Report Content
```http
POST /api/moderation/report/
Content-Type: application/json
Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...

{
    "content_type": "message",
    "content_id": 1052,
    "report_reason": "inappropriate_content",
    "description": "Contains offensive language",
    "severity": "medium"
}
```

## Translation APIs

### Detect Language
```http
POST /api/translation/detect/
Content-Type: application/json
Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...

{
    "text": "Bonjour, comment ça va?"
}
```

**Response:**
```json
{
    "detected_language": "fr",
    "confidence": 0.98,
    "alternatives": [
        {
            "language": "it",
            "confidence": 0.02
        }
    ]
}
```

### Translate Text
```http
POST /api/translation/translate/
Content-Type: application/json
Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...

{
    "text": "Hello, how are you today?",
    "target_language": "es",
    "source_language": "en"
}
```

**Response:**
```json
{
    "translated_text": "Hola, ¿cómo estás hoy?",
    "source_language": "en",
    "target_language": "es",
    "confidence_score": 0.94,
    "provider": "google",
    "cached": false
}
```

### Get Supported Languages
```http
GET /api/translation/languages/
Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...
```

**Response:**
```json
{
    "languages": [
        {
            "code": "en",
            "name": "English",
            "native_name": "English"
        },
        {
            "code": "es",
            "name": "Spanish",
            "native_name": "Español"
        },
        {
            "code": "fr",
            "name": "French",
            "native_name": "Français"
        }
    ]
}
```

## WebSocket Events

### Connection
```javascript
const ws = new WebSocket('ws://localhost:8000/ws/chat/101/');

// Authentication after connection
ws.send(JSON.stringify({
    'type': 'authenticate',
    'token': 'your_jwt_token_here'
}));
```

### Send Message
```javascript
ws.send(JSON.stringify({
    'type': 'message',
    'content': 'Hello from WebSocket!',
    'message_type': 'text',
    'reply_to': null
}));
```

### Typing Indicator
```javascript
// Start typing
ws.send(JSON.stringify({
    'type': 'typing',
    'is_typing': true
}));

// Stop typing
ws.send(JSON.stringify({
    'type': 'typing',
    'is_typing': false
}));
```

### Message Received Event
```javascript
ws.onmessage = function(event) {
    const data = JSON.parse(event.data);
    
    if (data.type === 'message') {
        console.log('New message:', data.message);
    } else if (data.type === 'typing') {
        console.log('Typing status:', data);
    }
};
```

### Request Translation
```javascript
ws.send(JSON.stringify({
    'type': 'translate_message',
    'message_id': 1052,
    'target_language': 'es'
}));
```

### User Presence Update
```javascript
ws.send(JSON.stringify({
    'type': 'presence',
    'status': 'online'
}));
```

## Test Data

### Test Users
```json
{
    "users": [
        {
            "id": 1,
            "username": "alice_buyer",
            "email": "alice@example.com",
            "password": "testpass123",
            "first_name": "Alice",
            "last_name": "Johnson",
            "profile": {
                "display_name": "Alice J.",
                "bio": "Procurement specialist",
                "timezone": "America/New_York",
                "language_preference": "en"
            }
        },
        {
            "id": 2,
            "username": "bob_seller",
            "email": "bob@example.com",
            "password": "testpass123",
            "first_name": "Bob",
            "last_name": "Smith",
            "profile": {
                "display_name": "Bob Smith",
                "bio": "Sales representative",
                "timezone": "America/Los_Angeles",
                "language_preference": "en"
            }
        },
        {
            "id": 3,
            "username": "carlos_multilingual",
            "email": "carlos@example.com",
            "password": "testpass123",
            "first_name": "Carlos",
            "last_name": "Rodriguez",
            "profile": {
                "display_name": "Carlos R.",
                "bio": "International sales",
                "timezone": "America/Mexico_City",
                "language_preference": "es"
            }
        }
    ]
}
```

### Test Conversations
```json
{
    "conversations": [
        {
            "id": 101,
            "title": "Office Supplies Procurement",
            "conversation_type": "direct",
            "participants": [1, 2],
            "created_by": 1,
            "description": "Discussion about bulk office supplies order"
        },
        {
            "id": 102,
            "title": "Marketing Team Chat",
            "conversation_type": "group",
            "participants": [1, 2, 3],
            "created_by": 1,
            "description": "Team collaboration space for marketing projects"
        }
    ]
}
```

### Test Messages
```json
{
    "messages": [
        {
            "id": 1001,
            "conversation_id": 101,
            "sender_id": 1,
            "content": "Hi Bob, I'm looking for quotes on office supplies for our new location.",
            "message_type": "text",
            "created_at": "2024-01-20T09:00:00Z"
        },
        {
            "id": 1002,
            "conversation_id": 101,
            "sender_id": 2,
            "content": "Hello Alice! I'd be happy to help. What specific items do you need?",
            "message_type": "text",
            "created_at": "2024-01-20T09:15:00Z",
            "reply_to": 1001
        },
        {
            "id": 1003,
            "conversation_id": 102,
            "sender_id": 3,
            "content": "Hola equipo, ¿cómo van los proyectos?",
            "message_type": "text",
            "created_at": "2024-01-20T10:00:00Z"
        }
    ]
}
```

### Test Files
```json
{
    "files": [
        {
            "id": 301,
            "filename": "office_supplies_catalog.pdf",
            "original_filename": "Office_Supplies_2024_Catalog.pdf",
            "file_size": 5242880,
            "mime_type": "application/pdf",
            "uploaded_by": 2,
            "conversation_id": 101,
            "message_id": 1004
        },
        {
            "id": 302,
            "filename": "budget_spreadsheet.xlsx",
            "original_filename": "Marketing_Budget_Q1.xlsx",
            "file_size": 1048576,
            "mime_type": "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
            "uploaded_by": 1,
            "conversation_id": 102,
            "message_id": 1005
        }
    ]
}
```

### Test Notifications
```json
{
    "notifications": [
        {
            "id": 501,
            "recipient_id": 1,
            "notification_type": "new_message",
            "title": "New message from Bob Smith",
            "message": "Hello Alice! I'd be happy to help...",
            "priority": "medium",
            "sender_id": 2,
            "related_object_type": "message",
            "related_object_id": 1002
        },
        {
            "id": 502,
            "recipient_id": 2,
            "notification_type": "file_shared",
            "title": "Alice shared a file",
            "message": "budget_spreadsheet.xlsx",
            "priority": "low",
            "sender_id": 1,
            "related_object_type": "file",
            "related_object_id": 302
        }
    ]
}
```

## Error Responses

### Authentication Error
```json
{
    "error": "authentication_failed",
    "message": "Invalid or expired token",
    "code": 401
}
```

### Validation Error
```json
{
    "error": "validation_error",
    "message": "Invalid input data",
    "details": {
        "content": ["This field is required."],
        "conversation_id": ["Invalid conversation ID."]
    },
    "code": 400
}
```

### Permission Error
```json
{
    "error": "permission_denied",
    "message": "You don't have permission to access this conversation",
    "code": 403
}
```

### Rate Limit Error
```json
{
    "error": "rate_limit_exceeded",
    "message": "Too many requests. Please try again later.",
    "retry_after": 60,
    "code": 429
}
```

## Testing Tools

### cURL Examples

#### Send a message
```bash
curl -X POST "http://localhost:8000/api/conversations/101/messages/" \
  -H "Authorization: Bearer your_jwt_token_here" \
  -H "Content-Type: application/json" \
  -d '{
    "content": "Test message from cURL",
    "message_type": "text"
  }'
```

#### Upload a file
```bash
curl -X POST "http://localhost:8000/api/files/upload/" \
  -H "Authorization: Bearer your_jwt_token_here" \
  -F "file=@/path/to/your/file.pdf" \
  -F "conversation_id=101"
```

### Python Test Script
```python
import requests
import json

BASE_URL = "http://localhost:8000/api"
TOKEN = "your_jwt_token_here"

headers = {
    "Authorization": f"Bearer {TOKEN}",
    "Content-Type": "application/json"
}

# Test sending a message
def test_send_message():
    url = f"{BASE_URL}/conversations/101/messages/"
    data = {
        "content": "Test message from Python script",
        "message_type": "text"
    }
    
    response = requests.post(url, headers=headers, json=data)
    print(f"Status Code: {response.status_code}")
    print(f"Response: {response.json()}")

# Test getting conversations
def test_get_conversations():
    url = f"{BASE_URL}/conversations/"
    response = requests.get(url, headers=headers)
    print(f"Status Code: {response.status_code}")
    print(f"Conversations: {len(response.json().get('results', []))}")

if __name__ == "__main__":
    test_send_message()
    test_get_conversations()
```

This comprehensive API documentation provides detailed examples for testing all major functionality of the BIDR Chat Service, including request/response formats, test data, and example implementations.
