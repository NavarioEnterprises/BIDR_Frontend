# BIDR Chat Service - API Testing Documentation

## Overview
This document contains comprehensive API requests and responses for the BIDR Chat Service. The service provides real-time chat functionality for buyers and sellers in the BIDR marketplace.

**Base URL**: `http://localhost:8001`
**API Version**: v1
**Authentication**: Token-based authentication required for most endpoints

## Table of Contents
1. [Authentication](#authentication)
2. [User Profiles](#user-profiles)
3. [System Configuration](#system-configuration)
4. [Chat Conversations](#chat-conversations)
5. [Messages](#messages)
6. [File Handling](#file-handling)
7. [Moderation](#moderation)
8. [Notifications](#notifications)

---

## Authentication

### 1. API Root - Health Check
**Request:**
```bash
curl -X GET http://localhost:8000/
```

**Expected Response:**
```json
{
  "message": "BIDR Chat Service API",
  "version": "1.0.0",
  "status": "active",
  "endpoints": {
    "conversations": "/api/v1/chat/conversations/",
    "messages": "/api/v1/chat/messages/",
    "bidding": "/api/v1/chat/bidding/",
    "moderation": "/api/v1/chat/moderation/",
    "files": "/api/v1/chat/files/"
  },
  "documentation": {
    "swagger": "/swagger/",
    "redoc": "/redoc/",
    "openapi": "/swagger.json"
  }
}
```

### 2. Login (Django Admin Authentication)
**Request:**
```bash
curl -X POST http://localhost:8000/admin/login/ \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=admin&password=admin123"
```

---

## User Profiles

### 3. Get User Profiles List
**Request:**
```bash
curl -X GET http://localhost:8000/api/v1/core/profiles/ \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json"
```

**Expected Response:**
```json
{
  "count": 0,
  "next": null,
  "previous": null,
  "results": []
}
```

### 4. Create User Profile
**Request:**
```bash
curl -X POST http://localhost:8000/api/v1/core/profiles/ \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "role": "buyer",
    "display_name": "John Buyer",
    "bio": "Looking for great deals on electronics",
    "location": "New York, NY",
    "allow_direct_messages": true,
    "show_online_status": true,
    "phone_number": "+1234567890",
    "business_email": "john@example.com"
  }'
```

**Expected Response:**
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "role": "buyer",
  "verification_status": "unverified",
  "display_name": "John Buyer",
  "bio": "Looking for great deals on electronics",
  "location": "New York, NY",
  "allow_direct_messages": true,
  "show_online_status": true,
  "phone_number": "+1234567890",
  "business_email": "john@example.com",
  "created_at": "2023-12-10T10:30:00Z"
}
```

### 5. Get User Profile Details
**Request:**
```bash
curl -X GET http://localhost:8000/api/v1/core/profiles/{profile_id}/ \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json"
```

**Expected Response:**
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "user": {
    "id": 1,
    "username": "johnbuyer",
    "email": "john@example.com",
    "first_name": "John",
    "last_name": "Buyer",
    "date_joined": "2023-12-01T10:00:00Z"
  },
  "role": "buyer",
  "verification_status": "email_verified",
  "display_name": "John Buyer",
  "avatar": null,
  "bio": "Looking for great deals on electronics",
  "location": "New York, NY",
  "allow_direct_messages": true,
  "show_online_status": true,
  "allow_read_receipts": true,
  "mask_personal_info": true,
  "status": "active",
  "is_banned": false,
  "warning_count": 0,
  "total_conversations": 5,
  "total_messages_sent": 47,
  "average_response_time_minutes": 15,
  "reputation_score": "4.5",
  "last_seen": "2023-12-10T10:25:00Z",
  "last_activity": "2023-12-10T10:28:00Z",
  "is_online": true,
  "can_send_messages": true,
  "created_at": "2023-12-01T10:30:00Z",
  "updated_at": "2023-12-10T10:28:00Z"
}
```

### 6. Update User Status
**Request:**
```bash
curl -X POST http://localhost:8000/api/v1/core/profiles/{profile_id}/update_status/ \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json"
```

**Expected Response:**
```json
{
  "status": "updated",
  "is_online": true
}
```

### 7. Get User Statistics
**Request:**
```bash
curl -X GET http://localhost:8000/api/v1/core/profiles/{profile_id}/statistics/ \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json"
```

**Expected Response:**
```json
{
  "total_conversations": 5,
  "total_messages_sent": 47,
  "average_response_time": 15,
  "reputation_score": 4.5,
  "warning_count": 0,
  "is_online": true,
  "last_seen": "2023-12-10T10:25:00Z",
  "account_age_days": 9
}
```

### 8. Get Online Users
**Request:**
```bash
curl -X GET http://localhost:8000/api/v1/core/profiles/online_users/ \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json"
```

**Expected Response:**
```json
[
  {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "username": "johnbuyer",
    "display_name": "John Buyer",
    "role": "buyer",
    "last_seen": "2023-12-10T10:25:00Z"
  },
  {
    "id": "550e8400-e29b-41d4-a716-446655440001",
    "username": "janeseller",
    "display_name": "Jane's Electronics Store",
    "role": "seller",
    "last_seen": "2023-12-10T10:23:00Z"
  }
]
```

---

## System Configuration

### 9. Get System Configurations
**Request:**
```bash
curl -X GET http://localhost:8000/api/v1/core/config/ \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json"
```

**Expected Response:**
```json
{
  "count": 3,
  "next": null,
  "previous": null,
  "results": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440010",
      "category": "translation",
      "key": "default_provider",
      "value": "google",
      "parsed_value": "google",
      "description": "Default translation service provider",
      "is_system_managed": false,
      "is_user_configurable": true,
      "created_at": "2023-12-01T10:00:00Z",
      "updated_at": "2023-12-01T10:00:00Z"
    }
  ]
}
```

### 10. Get Configurations by Category
**Request:**
```bash
curl -X GET "http://localhost:8000/api/v1/core/config/by_category/?category=translation" \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json"
```

**Expected Response:**
```json
[
  {
    "key": "default_provider",
    "value": "google",
    "description": "Default translation service provider"
  },
  {
    "key": "auto_detect_language",
    "value": true,
    "description": "Automatically detect message language"
  }
]
```

### 11. Get Translation Settings
**Request:**
```bash
curl -X GET http://localhost:8000/api/v1/core/config/translation_settings/ \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json"
```

**Expected Response:**
```json
{
  "default_provider": "google",
  "auto_detect_language": true,
  "supported_languages": ["en", "es", "fr", "de", "it", "pt", "zh", "ja"],
  "cache_translations": true,
  "max_translation_length": 5000
}
```

### 12. Get Moderation Settings
**Request:**
```bash
curl -X GET http://localhost:8000/api/v1/core/config/moderation_settings/ \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json"
```

**Expected Response:**
```json
{
  "auto_moderation_enabled": true,
  "profanity_filter_enabled": true,
  "spam_detection_enabled": true,
  "personal_info_detection": true,
  "warning_threshold": 3,
  "auto_ban_threshold": 5,
  "appeal_window_hours": 24
}
```

---

## Chat Conversations

### 13. Create New Conversation
**Request:**
```bash
curl -X POST http://localhost:8000/api/v1/conversations/ \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "iPhone 15 Pro Inquiry",
    "description": "Interested in purchasing iPhone 15 Pro",
    "conversation_type": "direct",
    "seller": 2,
    "auction_id": "AUC001",
    "category": "electronics",
    "tags": ["iphone", "smartphone", "electronics"]
  }'
```

**Expected Response:**
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440020",
  "title": "iPhone 15 Pro Inquiry",
  "description": "Interested in purchasing iPhone 15 Pro",
  "conversation_type": "direct",
  "status": "active",
  "buyer": {
    "id": 1,
    "username": "johnbuyer",
    "email": "john@example.com"
  },
  "seller": {
    "id": 2,
    "username": "janeseller",
    "email": "jane@electronics.com"
  },
  "auction_id": "AUC001",
  "category": "electronics",
  "tags": ["iphone", "smartphone", "electronics"],
  "is_encrypted": false,
  "is_archived": false,
  "total_messages": 0,
  "participant_count": 2,
  "is_user_participant": true,
  "user_role": "owner",
  "created_at": "2023-12-10T10:30:00Z"
}
```

### 14. Get Conversations List
**Request:**
```bash
curl -X GET http://localhost:8000/api/v1/conversations/ \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json"
```

**Expected Response:**
```json
{
  "count": 5,
  "next": null,
  "previous": null,
  "results": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440020",
      "title": "iPhone 15 Pro Inquiry",
      "conversation_type": "direct",
      "status": "active",
      "buyer": {
        "id": 1,
        "username": "johnbuyer"
      },
      "seller": {
        "id": 2,
        "username": "janeseller"
      },
      "total_messages": 15,
      "last_message_at": "2023-12-10T09:45:00Z",
      "participant_count": 2,
      "unread_count": 3,
      "last_message_preview": {
        "content": "When can we schedule the pickup?",
        "sender": "janeseller",
        "created_at": "2023-12-10T09:45:00Z"
      },
      "is_archived": false,
      "created_at": "2023-12-09T14:20:00Z"
    }
  ]
}
```

### 15. Get Conversation Details
**Request:**
```bash
curl -X GET http://localhost:8000/api/v1/conversations/{conversation_id}/ \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json"
```

**Expected Response:**
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440020",
  "title": "iPhone 15 Pro Inquiry",
  "description": "Interested in purchasing iPhone 15 Pro",
  "conversation_type": "direct",
  "status": "active",
  "buyer": {
    "id": 1,
    "username": "johnbuyer",
    "email": "john@example.com"
  },
  "seller": {
    "id": 2,
    "username": "janeseller",
    "email": "jane@electronics.com"
  },
  "auction_id": "AUC001",
  "category": "electronics",
  "tags": ["iphone", "smartphone", "electronics"],
  "participants": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440021",
      "user": {
        "id": 1,
        "username": "johnbuyer"
      },
      "role": "owner",
      "joined_at": "2023-12-09T14:20:00Z",
      "is_muted": false,
      "notification_level": "all",
      "last_read_at": "2023-12-10T09:30:00Z",
      "unread_count": 3
    }
  ],
  "metrics": {
    "total_messages": 15,
    "total_participants": 2,
    "active_participants_24h": 2,
    "average_response_time_minutes": 12,
    "peak_activity_hour": 14,
    "last_activity_at": "2023-12-10T09:45:00Z"
  },
  "last_message_preview": {
    "id": "550e8400-e29b-41d4-a716-446655440030",
    "content": "When can we schedule the pickup?",
    "sender": "janeseller",
    "message_type": "text",
    "created_at": "2023-12-10T09:45:00Z"
  }
}
```

---

## Messages

### 16. Send Message
**Request:**
```bash
curl -X POST http://localhost:8000/api/v1/messages/ \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "conversation": "550e8400-e29b-41d4-a716-446655440020",
    "message_type": "text",
    "content": "Hello! I am interested in the iPhone 15 Pro. Is it still available?",
    "client_message_id": "msg_12345"
  }'
```

**Expected Response:**
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440030",
  "sender": {
    "id": 1,
    "username": "johnbuyer",
    "email": "john@example.com"
  },
  "conversation": "550e8400-e29b-41d4-a716-446655440020",
  "message_type": "text",
  "content": "Hello! I am interested in the iPhone 15 Pro. Is it still available?",
  "delivery_status": "sent",
  "is_edited": false,
  "is_flagged": false,
  "reaction_count": 0,
  "client_message_id": "msg_12345",
  "message_hash": "a1b2c3d4e5f6...",
  "attachments": [],
  "reactions": [],
  "mentions": [],
  "translations": [],
  "read_receipts": [],
  "read_by_count": 0,
  "is_read_by_user": false,
  "reply_to_message": null,
  "is_active": true,
  "created_at": "2023-12-10T10:35:00Z",
  "updated_at": "2023-12-10T10:35:00Z"
}
```

### 17. Get Messages in Conversation
**Request:**
```bash
curl -X GET "http://localhost:8000/api/v1/messages/?conversation=550e8400-e29b-41d4-a716-446655440020" \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json"
```

**Expected Response:**
```json
{
  "count": 15,
  "next": null,
  "previous": null,
  "results": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440030",
      "sender": {
        "id": 1,
        "username": "johnbuyer"
      },
      "message_type": "text",
      "content": "Hello! I am interested in the iPhone 15 Pro. Is it still available?",
      "delivery_status": "read",
      "is_edited": false,
      "reaction_count": 1,
      "read_by_count": 1,
      "is_read_by_user": false,
      "created_at": "2023-12-10T10:35:00Z"
    },
    {
      "id": "550e8400-e29b-41d4-a716-446655440031",
      "sender": {
        "id": 2,
        "username": "janeseller"
      },
      "message_type": "text",
      "content": "Yes, it's still available! The condition is excellent, barely used.",
      "delivery_status": "delivered",
      "is_edited": false,
      "reaction_count": 0,
      "reply_to_message": {
        "id": "550e8400-e29b-41d4-a716-446655440030",
        "content": "Hello! I am interested in the iPhone 15 Pro. Is it still available?",
        "sender": "johnbuyer",
        "created_at": "2023-12-10T10:35:00Z"
      },
      "created_at": "2023-12-10T10:37:00Z"
    }
  ]
}
```

### 18. Update Message
**Request:**
```bash
curl -X PATCH http://localhost:8000/api/v1/messages/{message_id}/ \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "content": "Hello! I am interested in the iPhone 15 Pro Max. Is it still available?"
  }'
```

**Expected Response:**
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440030",
  "content": "Hello! I am interested in the iPhone 15 Pro Max. Is it still available?",
  "is_edited": true,
  "edited_at": "2023-12-10T10:40:00Z",
  "original_content": "Hello! I am interested in the iPhone 15 Pro. Is it still available?",
  "updated_at": "2023-12-10T10:40:00Z"
}
```

### 19. Mark Message as Read
**Request:**
```bash
curl -X POST http://localhost:8000/api/v1/messages/{message_id}/mark_read/ \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json"
```

**Expected Response:**
```json
{
  "status": "marked_as_read",
  "read_at": "2023-12-10T10:42:00Z"
}
```

### 20. Add Message Reaction
**Request:**
```bash
curl -X POST http://localhost:8000/api/v1/messages/{message_id}/react/ \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "reaction_type": "like"
  }'
```

**Expected Response:**
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440040",
  "user": {
    "id": 2,
    "username": "janeseller"
  },
  "reaction_type": "like",
  "created_at": "2023-12-10T10:43:00Z"
}
```

---

## File Handling

### 21. Upload File Attachment
**Request:**
```bash
curl -X POST http://localhost:8000/api/v1/files/upload/ \
  -H "Authorization: Bearer <token>" \
  -F "file=@/path/to/iphone_photo.jpg" \
  -F "message=550e8400-e29b-41d4-a716-446655440030" \
  -F "filename=iphone_photo.jpg"
```

**Expected Response:**
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440050",
  "original_filename": "iphone_photo.jpg",
  "file_size": 2048576,
  "file_category": "image",
  "mime_type": "image/jpeg",
  "status": "processing",
  "virus_scan_result": "pending",
  "width": 1920,
  "height": 1080,
  "is_public": false,
  "download_count": 0,
  "upload_ip": "192.168.1.100",
  "created_at": "2023-12-10T10:45:00Z"
}
```

### 22. Get File Details
**Request:**
```bash
curl -X GET http://localhost:8000/api/v1/files/{file_id}/ \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json"
```

**Expected Response:**
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440050",
  "original_filename": "iphone_photo.jpg",
  "file_size": 2048576,
  "file_size_display": "2.0 MB",
  "file_category": "image",
  "mime_type": "image/jpeg",
  "status": "available",
  "virus_scan_result": "clean",
  "scan_details": {
    "scan_engine": "clamav",
    "scan_time": "2023-12-10T10:45:30Z"
  },
  "width": 1920,
  "height": 1080,
  "thumbnails": [
    {
      "size_type": "small",
      "width": 150,
      "height": 84,
      "url": "/media/thumbnails/2023/12/10/iphone_photo_small.jpg"
    }
  ],
  "download_count": 3,
  "last_accessed": "2023-12-10T10:50:00Z",
  "expires_at": "2023-12-17T10:45:00Z",
  "created_at": "2023-12-10T10:45:00Z"
}
```

### 23. Download File
**Request:**
```bash
curl -X GET http://localhost:8000/api/v1/files/{file_id}/download/ \
  -H "Authorization: Bearer <token>" \
  --output downloaded_file.jpg
```

**Expected Response:**
```
HTTP/1.1 200 OK
Content-Type: image/jpeg
Content-Length: 2048576
Content-Disposition: attachment; filename="iphone_photo.jpg"

[Binary file data]
```

---

## Moderation

### 24. Report Content
**Request:**
```bash
curl -X POST http://localhost:8000/api/v1/moderation/report/ \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "content_type": "message",
    "content_id": "550e8400-e29b-41d4-a716-446655440030",
    "reason": "Contains inappropriate language",
    "priority": "medium"
  }'
```

**Expected Response:**
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440060",
  "content_type": "message",
  "content_id": "550e8400-e29b-41d4-a716-446655440030",
  "reported_by": {
    "id": 2,
    "username": "janeseller"
  },
  "status": "pending",
  "priority": "medium",
  "reason": "Contains inappropriate language",
  "created_at": "2023-12-10T10:55:00Z"
}
```

### 25. Get Moderation Queue (Admin Only)
**Request:**
```bash
curl -X GET http://localhost:8000/api/v1/moderation/queue/ \
  -H "Authorization: Bearer <admin_token>" \
  -H "Content-Type: application/json"
```

**Expected Response:**
```json
{
  "count": 5,
  "next": null,
  "previous": null,
  "results": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440060",
      "content_type": "message",
      "content_id": "550e8400-e29b-41d4-a716-446655440030",
      "reported_by": {
        "id": 2,
        "username": "janeseller"
      },
      "assigned_to": null,
      "status": "pending",
      "priority": "medium",
      "reason": "Contains inappropriate language",
      "content_snapshot": {
        "message_content": "Hello! I am interested in the iPhone...",
        "sender": "johnbuyer"
      },
      "created_at": "2023-12-10T10:55:00Z"
    }
  ]
}
```

---

## Notifications

### 26. Get User Notifications
**Request:**
```bash
curl -X GET http://localhost:8000/api/v1/notifications/ \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json"
```

**Expected Response:**
```json
{
  "count": 8,
  "next": null,
  "previous": null,
  "results": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440070",
      "title": "New Message",
      "body": "You have a new message from janeseller",
      "status": "delivered",
      "priority": "normal",
      "related_message": "550e8400-e29b-41d4-a716-446655440031",
      "related_conversation": "550e8400-e29b-41d4-a716-446655440020",
      "scheduled_at": "2023-12-10T10:37:00Z",
      "delivered_at": "2023-12-10T10:37:05Z",
      "read_at": null,
      "expires_at": "2023-12-17T10:37:00Z",
      "created_at": "2023-12-10T10:37:00Z"
    }
  ]
}
```

### 27. Mark Notification as Read
**Request:**
```bash
curl -X POST http://localhost:8000/api/v1/notifications/{notification_id}/mark_read/ \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json"
```

**Expected Response:**
```json
{
  "status": "read",
  "read_at": "2023-12-10T11:00:00Z"
}
```

---

## Error Responses

### Authentication Error
```json
{
  "detail": "Authentication credentials were not provided."
}
```

### Permission Denied
```json
{
  "detail": "You do not have permission to perform this action."
}
```

### Validation Error
```json
{
  "content": [
    "This field is required."
  ],
  "conversation": [
    "Invalid pk \"invalid-uuid\" - object does not exist."
  ]
}
```

### Not Found Error
```json
{
  "detail": "Not found."
}
```

### Server Error
```json
{
  "detail": "A server error occurred."
}
```

---

## Testing Notes

1. **Authentication Required**: Most endpoints require valid authentication tokens
2. **UUID Format**: All IDs use UUID format (e.g., `550e8400-e29b-41d4-a716-446655440000`)
3. **Pagination**: List endpoints support pagination with `page` and `page_size` parameters
4. **Filtering**: Many endpoints support filtering via query parameters
5. **File Uploads**: Use `multipart/form-data` content type for file uploads
6. **Rate Limiting**: API may implement rate limiting for production use

## Status Codes

- `200 OK`: Successful GET, PUT, PATCH
- `201 Created`: Successful POST
- `204 No Content`: Successful DELETE
- `400 Bad Request`: Invalid request data
- `401 Unauthorized`: Authentication required
- `403 Forbidden`: Permission denied
- `404 Not Found`: Resource not found
- `429 Too Many Requests`: Rate limit exceeded
- `500 Internal Server Error`: Server error

---

## ACTUAL API RESPONSES (Live Testing)

### 1. API Root Response (VERIFIED ✓)
**Request:**
```bash
curl -X GET http://localhost:8001/
```

**Actual Response:**
```json
{"message": "BIDR Chat Service API", "version": "1.0.0", "status": "active", "endpoints": {"conversations": "/api/v1/chat/conversations/", "messages": "/api/v1/chat/messages/", "bidding": "/api/v1/chat/bidding/", "moderation": "/api/v1/chat/moderation/", "files": "/api/v1/chat/files/"}, "documentation": {"swagger": "/swagger/", "redoc": "/redoc/", "openapi": "/swagger.json"}}
```

### 2. Authentication Token (VERIFIED ✓)
**Request:**
```bash
curl -X POST http://localhost:8001/api/auth/token/ \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=admin&password=admin123"
```

**Actual Response:**
```json
{"token":"995be462d624cb27bc75e10feb04807ac34f5759"}
```

### 3. User Profiles Endpoint (VERIFIED ✓)
**Request:**
```bash
curl -X GET http://localhost:8001/api/v1/core/profiles/
```

**Actual Response (Sample):**
```json
{
  "count": 6,
  "next": null,
  "previous": null,
  "results": [
    {
      "id": "3cee6331-738e-4cb5-8d1b-085b32f05bf7",
      "user": {
        "id": 1,
        "username": "chatadmin",
        "email": "admin@bidr-chat.com",
        "first_name": "",
        "last_name": "",
        "date_joined": "2025-08-10T00:46:01.338267Z"
      },
      "role": "admin",
      "verification_status": "fully_verified",
      "display_name": "Chat Admin",
      "avatar": null,
      "bio": "BIDR Chat Service Administrator",
      "location": "",
      "allow_direct_messages": true,
      "show_online_status": true,
      "allow_read_receipts": true,
      "mask_personal_info": true,
      "company_name": "",
      "business_registration_number": "",
      "phone_number": "",
      "business_email": "",
      "website_url": "",
      "status": "active",
      "is_banned": false,
      "ban_reason": "",
      "ban_expires_at": null,
      "warning_count": 0,
      "total_conversations": 0,
      "total_messages_sent": 0,
      "average_response_time_minutes": 0,
      "reputation_score": "5.0",
      "last_seen": "2025-08-10T00:46:01.437034Z",
      "last_activity": "2025-08-10T00:46:01.437038Z",
      "is_online": false,
      "can_send_messages": true,
      "created_at": "2025-08-10T00:46:01.437124Z",
      "updated_at": "2025-08-10T00:46:01.437134Z"
    }
    // ... 5 more user profiles
  ]
}
```

### 4. System Configuration Endpoint (VERIFIED ✓)
**Request:**
```bash
curl -X GET http://localhost:8001/api/v1/core/config/
```

**Actual Response:**
```json
{
  "count": 3,
  "next": null,
  "previous": null,
  "results": [
    {
      "id": "36310d29-4a23-4893-8c9a-5c34e5b325e4",
      "category": "moderation",
      "key": "auto_moderation_enabled",
      "value": "true",
      "parsed_value": true,
      "description": "Enable automatic content moderation",
      "is_system_managed": false,
      "is_user_configurable": true,
      "created_at": "2025-08-10T00:48:54.151684Z",
      "updated_at": "2025-08-10T00:48:54.151704Z"
    },
    {
      "id": "415da77b-3e29-409e-9f6d-8cd2200eed5e",
      "category": "translation",
      "key": "default_provider",
      "value": "google",
      "parsed_value": "google",
      "description": "Default translation service provider",
      "is_system_managed": false,
      "is_user_configurable": true,
      "created_at": "2025-08-10T00:48:54.153120Z",
      "updated_at": "2025-08-10T00:48:54.153130Z"
    },
    {
      "id": "c9a07cb7-dd63-4caf-be80-a5062bd65e87",
      "category": "limits",
      "key": "max_message_length",
      "value": "5000",
      "parsed_value": 5000,
      "description": "Maximum message length in characters",
      "is_system_managed": false,
      "is_user_configurable": true,
      "created_at": "2025-08-10T00:48:54.154580Z",
      "updated_at": "2025-08-10T00:48:54.154592Z"
    }
  ]
}
```

### 5. Authenticated Request (VERIFIED ✓)
**Request:**
```bash
curl -X GET http://localhost:8001/api/v1/core/profiles/ \
  -H "Authorization: Token 995be462d624cb27bc75e10feb04807ac34f5759"
```

**Response:** Same as above profiles response

### 6. Current Available Endpoints
Based on live testing, currently working endpoints are:
- `GET /` - API root (✓ Working)
- `GET /api/` - API root (✓ Working) 
- `GET /admin/` - Django admin interface (✓ Working)
- `POST /api/auth/token/` - Authentication token (✓ Working)
- `GET /api/v1/core/profiles/` - User profiles (✓ Working)
- `GET /api/v1/core/config/` - System configuration (✓ Working)

### 3. Database Status
- Users in database: 6
- User profiles in database: 6
- Test users created: `testbuyer`, `testseller`

### 4. Server Status
- Running on: http://localhost:8001
- Django version: Latest
- Database: SQLite (development)
- Authentication: Required for most endpoints

### Next Steps for Full API Testing:
1. Set up authentication (Token-based or Session-based)
2. Create superuser account for admin access
3. Test authenticated endpoints with valid credentials
4. Implement remaining viewsets (conversations, messages, etc.)
5. Add comprehensive error handling and validation

---

*Last updated: August 10, 2025*
