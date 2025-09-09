# BIDR Resolution Service API Documentation

## Overview

The BIDR Resolution Service provides a comprehensive API for managing post-transaction activities including reviews, returns, disputes, notifications, and system logging. This document provides detailed information about all available endpoints, request/response formats, and authentication requirements.

## Base URL

```
http://localhost:8003/api/v1/
```

## Authentication

Most endpoints require authentication. The service supports:
- **Session Authentication**: For web applications
- **Basic Authentication**: For simple API access
- **API Key Authentication**: For service-to-service communication

### API Keys
API keys can be managed through the admin interface or API endpoints. Include the API key in the header:
```
Authorization: Api-Key your-api-key-here
```

## Response Format

All API responses follow a consistent JSON format:

```json
{
  "results": [...],
  "count": 100,
  "next": "http://localhost:8003/api/v1/endpoint/?page=2",
  "previous": null
}
```

For single objects:
```json
{
  "id": 1,
  "field1": "value1",
  "field2": "value2",
  ...
}
```

## Error Handling

Error responses include appropriate HTTP status codes and descriptive error messages:

```json
{
  "detail": "Authentication credentials were not provided.",
  "error_code": "not_authenticated"
}
```

Common HTTP status codes:
- `200 OK`: Successful GET request
- `201 Created`: Successful POST request
- `400 Bad Request`: Invalid input data
- `401 Unauthorized`: Authentication required
- `403 Forbidden`: Insufficient permissions
- `404 Not Found`: Resource not found
- `500 Internal Server Error`: Server error

---

## Core Endpoints

### Health Check

Check the health status of the Resolution Service.

**Endpoint:** `GET /api/v1/core/health/`  
**Authentication:** Not required

**Response Example:**
```json
{
  "status": "healthy",
  "service": "resolution_service",
  "timestamp": "2025-08-10T02:46:01.741150Z",
  "version": "1.0.0"
}
```

### Service Information

Get detailed information about the Resolution Service capabilities.

**Endpoint:** `GET /api/v1/core/service-info/`  
**Authentication:** Not required

**Response Example:**
```json
{
  "service_name": "BIDR Resolution Service",
  "description": "Post-transaction resolution service for reviews, returns, and disputes",
  "version": "1.0.0",
  "features": [
    "Review Management",
    "Return Processing",
    "Dispute Resolution",
    "Notification System",
    "Activity Logging"
  ],
  "endpoints": {
    "reviews": "/api/v1/reviews/",
    "returns": "/api/v1/returns/",
    "disputes": "/api/v1/disputes/",
    "notifications": "/api/v1/notifications_service/",
    "logs": "/api/v1/logs/"
  }
}
```

### Service Statistics

Get service usage statistics and metrics.

**Endpoint:** `GET /api/v1/core/stats/`  
**Authentication:** Required

**Response Example:**
```json
{
  "users": 8,
  "transactions": 10,
  "active_api_keys": 2,
  "service_health": 2
}
```

### User Profiles

Manage extended user profile information.

**Endpoints:**
- `GET /api/v1/core/user-profiles/` - List user profiles
- `POST /api/v1/core/user-profiles/` - Create user profile
- `GET /api/v1/core/user-profiles/{id}/` - Get specific profile
- `PUT /api/v1/core/user-profiles/{id}/` - Update profile
- `DELETE /api/v1/core/user-profiles/{id}/` - Delete profile

**Authentication:** Required

**Profile Object:**
```json
{
  "id": 1,
  "user": 2,
  "phone_number": "+1234567890",
  "is_verified": true,
  "reputation_score": "4.50",
  "total_transactions": 15,
  "successful_transactions": 14,
  "dispute_count": 1,
  "success_rate": 93.33,
  "created_at": "2025-08-10T02:46:12.123Z",
  "updated_at": "2025-08-10T02:46:12.123Z"
}
```

### System Configuration

Manage system-wide configuration settings.

**Endpoints:**
- `GET /api/v1/core/system-config/` - List configurations
- `POST /api/v1/core/system-config/` - Create configuration
- `GET /api/v1/core/system-config/{id}/` - Get configuration
- `PUT /api/v1/core/system-config/{id}/` - Update configuration

**Authentication:** Required (Admin only)

**Configuration Object:**
```json
{
  "id": 1,
  "key": "max_return_days",
  "value": "30",
  "description": "Maximum days allowed for returns",
  "is_active": true,
  "created_at": "2025-08-10T02:46:12.123Z",
  "updated_at": "2025-08-10T02:46:12.123Z"
}
```

---

## Review Endpoints

### Reviews

Manage user reviews and ratings.

**Endpoints:**
- `GET /api/v1/reviews/reviews/` - List reviews
- `POST /api/v1/reviews/reviews/` - Create review
- `GET /api/v1/reviews/reviews/{id}/` - Get specific review
- `PUT /api/v1/reviews/reviews/{id}/` - Update review
- `DELETE /api/v1/reviews/reviews/{id}/` - Delete review

**Authentication:** Required

**Review Object:**
```json
{
  "id": 1,
  "transaction": 1,
  "reviewer": 2,
  "reviewed_user": 3,
  "rating": 5,
  "title": "Great transaction #1",
  "content": "The seller was very helpful and the item was as described.",
  "communication_rating": 5,
  "product_quality_rating": 4,
  "delivery_rating": 5,
  "is_verified": true,
  "is_published": true,
  "is_flagged": false,
  "flag_reason": null,
  "created_at": "2025-08-10T02:46:12.123Z",
  "updated_at": "2025-08-10T02:46:12.123Z"
}
```

### Review Actions

**Mark Review as Helpful:**
- `POST /api/v1/reviews/reviews/{id}/mark-helpful/`
- Body: `{"is_helpful": true}`

**Flag Review:**
- `POST /api/v1/reviews/reviews/{id}/flag/`
- Body: `{"reason": "inappropriate", "details": "Contains offensive language"}`

**Get Transaction Reviews:**
- `GET /api/v1/reviews/transaction/{transaction_id}/reviews/`

**Get User Review Summary:**
- `GET /api/v1/reviews/user/{user_id}/review-summary/`

### Review Photos

Manage photos attached to reviews.

**Endpoints:**
- `GET /api/v1/reviews/review-photos/` - List review photos
- `POST /api/v1/reviews/review-photos/` - Upload review photo
- `DELETE /api/v1/reviews/review-photos/{id}/` - Delete photo

**Photo Object:**
```json
{
  "id": 1,
  "review": 1,
  "image": "/media/reviews/photos/review_1_photo.jpg",
  "caption": "Product packaging",
  "created_at": "2025-08-10T02:46:12.123Z"
}
```

---

## Return Endpoints

### Return Requests

Manage product return requests.

**Endpoints:**
- `GET /api/v1/returns/return-requests/` - List return requests
- `POST /api/v1/returns/return-requests/` - Create return request
- `GET /api/v1/returns/return-requests/{id}/` - Get return request
- `PUT /api/v1/returns/return-requests/{id}/` - Update return request

**Authentication:** Required

**Return Request Object:**
```json
{
  "id": 1,
  "transaction": 6,
  "buyer": 2,
  "seller": 3,
  "reason": "not_as_described",
  "description": "Item was not as described in the listing.",
  "requested_outcome": "full_refund",
  "status": "pending",
  "return_deadline": "2025-09-04T02:46:12.123Z",
  "refund_amount": null,
  "admin_notes": "",
  "created_at": "2025-08-10T02:46:12.123Z",
  "is_within_deadline": true
}
```

### Return Actions

**Approve Return:**
- `POST /api/v1/returns/return-requests/{id}/approve/`
- Body: `{"approval_notes": "Return approved as requested"}`

**Reject Return:**
- `POST /api/v1/returns/return-requests/{id}/reject/`
- Body: `{"rejection_reason": "Item shows signs of use beyond normal"}`

**Ship Return:**
- `POST /api/v1/returns/return-requests/{id}/ship/`
- Body: `{"tracking_number": "1Z999AA1234567890", "carrier": "UPS"}`

**Evaluate Return:**
- `POST /api/v1/returns/return-requests/{id}/evaluate/`
- Body: `{"condition_assessment": "excellent", "is_acceptable": true, "refund_percentage": 100}`

**Complete Return:**
- `POST /api/v1/returns/return-requests/{id}/complete/`
- Body: `{"final_notes": "Return processed successfully"}`

### Return Policies

Manage return policies for different product categories.

**Endpoints:**
- `GET /api/v1/returns/return-policies/` - List return policies
- `POST /api/v1/returns/return-policies/` - Create return policy
- `GET /api/v1/returns/return-policies/{id}/` - Get return policy

**Return Policy Object:**
```json
{
  "id": 1,
  "name": "Standard Return Policy",
  "description": "Standard 30-day return policy for all items",
  "return_period_days": 30,
  "restocking_fee_percent": "5.00",
  "who_pays_shipping": "buyer",
  "requires_original_packaging": true,
  "requires_tags_attached": false,
  "allows_used_items": true,
  "applicable_categories": ["electronics", "clothing", "books"],
  "is_active": true
}
```

---

## Dispute Endpoints

### Disputes

Manage disputes between buyers and sellers.

**Endpoints:**
- `GET /api/v1/disputes/disputes/` - List disputes
- `POST /api/v1/disputes/disputes/` - Create dispute
- `GET /api/v1/disputes/disputes/{id}/` - Get dispute details
- `PUT /api/v1/disputes/disputes/{id}/` - Update dispute

**Authentication:** Required

**Dispute Object:**
```json
{
  "id": 1,
  "transaction": 9,
  "return_request": null,
  "complainant": 2,
  "respondent": 3,
  "mediator": null,
  "dispute_type": "not_as_described",
  "subject": "Item not matching description",
  "description": "The item I received does not match what was shown in the photos.",
  "desired_resolution": "I would like a full refund or replacement item.",
  "status": "open",
  "priority": "medium",
  "disputed_amount": "123.45",
  "resolution_amount": null,
  "resolution_type": "",
  "resolution_notes": "",
  "created_at": "2025-08-10T02:46:12.123Z",
  "auto_escalate_at": "2025-08-13T02:46:12.123Z"
}
```

### Dispute Actions

**Escalate Dispute:**
- `POST /api/v1/disputes/disputes/{id}/escalate/`
- Body: `{"escalation_reason": "No response from seller after 72 hours"}`

**Resolve Dispute:**
- `POST /api/v1/disputes/disputes/{id}/resolve/`
- Body: `{"resolution_type": "partial_refund", "resolution_amount": "61.73", "resolution_notes": "50% refund agreed upon"}`

**Close Dispute:**
- `POST /api/v1/disputes/disputes/{id}/close/`
- Body: `{"closing_reason": "Resolved through mediation"}`

### Dispute Messages

Manage communication within disputes.

**Endpoints:**
- `GET /api/v1/disputes/dispute-messages/` - List messages
- `POST /api/v1/disputes/dispute-messages/` - Send message
- `GET /api/v1/disputes/disputes/{id}/messages/` - Get dispute messages

**Message Object:**
```json
{
  "id": 1,
  "dispute": 1,
  "sender": 2,
  "message": "I received the item but it looks nothing like the photos.",
  "is_internal": false,
  "is_resolution_offer": false,
  "read_by_complainant": true,
  "read_by_respondent": false,
  "read_by_admin": false,
  "created_at": "2025-08-10T02:46:12.123Z"
}
```

### Resolution Offers

Manage settlement offers during disputes.

**Endpoints:**
- `GET /api/v1/disputes/resolution-offers/` - List resolution offers
- `POST /api/v1/disputes/resolution-offers/` - Create offer
- `POST /api/v1/disputes/resolution-offers/{id}/accept/` - Accept offer
- `POST /api/v1/disputes/resolution-offers/{id}/reject/` - Reject offer

**Resolution Offer Object:**
```json
{
  "id": 1,
  "dispute": 1,
  "offered_by": 3,
  "offer_type": "partial_refund",
  "offer_amount": "61.73",
  "description": "I can offer a 50% refund for the inconvenience.",
  "terms_and_conditions": "",
  "status": "pending",
  "expires_at": "2025-08-13T02:46:12.123Z",
  "created_at": "2025-08-10T02:46:12.123Z",
  "responded_at": null
}
```

---

## Notification Endpoints

### Notifications

Manage user notifications across multiple channels.

**Endpoints:**
- `GET /api/v1/notifications/notifications/` - List notifications
- `POST /api/v1/notifications/send/` - Send single notification
- `POST /api/v1/notifications/send-bulk/` - Send bulk notifications
- `POST /api/v1/notifications/notifications/{id}/mark-read/` - Mark as read

**Authentication:** Required

**Notification Object:**
```json
{
  "id": 1,
  "recipient": 2,
  "template": 1,
  "notification_type": "review_received",
  "subject": "New Review on Your Transaction",
  "message": "You have received a new review for transaction TXN2024001. Rating: 5 stars.",
  "html_content": "",
  "is_read": false,
  "is_sent": true,
  "sent_at": "2025-08-10T02:46:12.123Z",
  "read_at": null,
  "email_sent": true,
  "push_sent": true,
  "priority": "normal",
  "data": {"transaction_id": "TXN2024001", "rating": 5},
  "retry_count": 0,
  "created_at": "2025-08-10T02:46:12.123Z"
}
```

### Notification Templates

Manage notification templates for different event types.

**Endpoints:**
- `GET /api/v1/notifications/templates/` - List templates
- `POST /api/v1/notifications/templates/` - Create template
- `POST /api/v1/notifications/templates/test/{id}/` - Test template

**Template Object:**
```json
{
  "id": 1,
  "name": "Review Received",
  "notification_type": "review_received",
  "subject_template": "New Review on Your Transaction",
  "body_template": "You have received a new review for transaction {{transaction_id}}. Rating: {{rating}} stars.",
  "html_template": "",
  "send_email": true,
  "send_sms": false,
  "send_push": true,
  "send_in_app": true,
  "is_active": true,
  "priority": "normal",
  "created_at": "2025-08-10T02:46:12.123Z"
}
```

### User Notification Endpoints

**Get User Notifications:**
- `GET /api/v1/notifications/user/{user_id}/notifications/`

**Get Unread Count:**
- `GET /api/v1/notifications/user/{user_id}/unread-count/`

**Mark All as Read:**
- `POST /api/v1/notifications/notifications/mark-all-read/`

---

## Logging Endpoints

### Activity Logs

Track all user and system activities.

**Endpoints:**
- `GET /api/v1/logs/activity-logs/` - List activity logs
- `GET /api/v1/logs/activity/{user_id}/` - Get user activity

**Authentication:** Required (Admin for most endpoints)

**Activity Log Object:**
```json
{
  "id": 1,
  "user": 2,
  "action": "Review created",
  "category": "review",
  "description": "User created a new review",
  "ip_address": "127.0.0.1",
  "user_agent": "Mozilla/5.0 (Test Browser)",
  "request_method": "POST",
  "request_path": "/api/v1/test/1/",
  "metadata": {},
  "success": true,
  "error_message": "",
  "created_at": "2025-08-10T02:46:12.123Z"
}
```

### System Logs

Debug and monitoring logs for system operations.

**Endpoints:**
- `GET /api/v1/logs/system-logs/` - List system logs

**System Log Object:**
```json
{
  "id": 1,
  "level": "INFO",
  "logger_name": "django.request",
  "message": "Sample data creation completed successfully",
  "module": "management.commands.create_sample_data",
  "function": "",
  "line_number": null,
  "exception_type": "",
  "exception_message": "",
  "traceback": "",
  "extra_data": {},
  "created_at": "2025-08-10T02:46:12.123Z"
}
```

### Security Logs

Track security-related events and violations.

**Endpoints:**
- `GET /api/v1/logs/security-logs/` - List security logs
- `GET /api/v1/logs/security/suspicious/` - Get suspicious activities

**Security Log Object:**
```json
{
  "id": 1,
  "event_type": "login_success",
  "user": 2,
  "ip_address": "127.0.0.1",
  "user_agent": "",
  "description": "Successful login attempt",
  "severity": "low",
  "request_path": "",
  "additional_data": {},
  "is_investigated": false,
  "investigation_notes": "",
  "created_at": "2025-08-10T02:46:12.123Z"
}
```

### Performance & Error Logs

**Performance Logs:**
- `GET /api/v1/logs/performance-logs/` - List performance metrics
- `GET /api/v1/logs/performance/metrics/` - Get aggregated metrics

**Error Logs:**
- `GET /api/v1/logs/error-logs/` - List error logs
- `GET /api/v1/logs/errors/unresolved/` - Get unresolved errors

### Log Statistics

**Get Log Statistics:**
- `GET /api/v1/logs/stats/`

**Export Logs:**
- `POST /api/v1/logs/export/`
- Body: `{"start_date": "2025-08-01", "end_date": "2025-08-31", "log_types": ["activity", "security"]}`

---

## Query Parameters

Most list endpoints support common query parameters:

### Filtering
```
GET /api/v1/reviews/reviews/?rating=5
GET /api/v1/disputes/disputes/?status=open
GET /api/v1/notifications/notifications/?is_read=false
```

### Searching
```
GET /api/v1/reviews/reviews/?search=great%20product
GET /api/v1/disputes/disputes/?search=not%20as%20described
```

### Ordering
```
GET /api/v1/reviews/reviews/?ordering=-created_at
GET /api/v1/disputes/disputes/?ordering=priority,-created_at
```

### Pagination
```
GET /api/v1/reviews/reviews/?page=2&page_size=10
```

### Date Filtering
```
GET /api/v1/logs/activity-logs/?created_at__gte=2025-08-01
GET /api/v1/reviews/reviews/?created_at__range=2025-08-01,2025-08-31
```

---

## Sample API Calls

### Create a Review

```bash
curl -X POST http://localhost:8003/api/v1/reviews/reviews/ \
  -H "Content-Type: application/json" \
  -H "Authorization: Basic YWRtaW46YWRtaW4xMjM=" \
  -d '{
    "transaction": 1,
    "reviewer": 2,
    "reviewed_user": 3,
    "rating": 5,
    "title": "Excellent service",
    "content": "The transaction was smooth and the seller was very responsive.",
    "communication_rating": 5,
    "product_quality_rating": 5,
    "delivery_rating": 4
  }'
```

### File a Dispute

```bash
curl -X POST http://localhost:8003/api/v1/disputes/disputes/ \
  -H "Content-Type: application/json" \
  -H "Authorization: Basic YWRtaW46YWRtaW4xMjM=" \
  -d '{
    "transaction": 1,
    "complainant": 2,
    "respondent": 3,
    "dispute_type": "not_as_described",
    "subject": "Product quality issue",
    "description": "The item received has quality issues not mentioned in description.",
    "desired_resolution": "Full refund or replacement",
    "priority": "medium",
    "disputed_amount": "199.99"
  }'
```

### Send Notification

```bash
curl -X POST http://localhost:8003/api/v1/notifications/send/ \
  -H "Content-Type: application/json" \
  -H "Authorization: Basic YWRtaW46YWRtaW4xMjM=" \
  -d '{
    "recipient": 2,
    "notification_type": "custom",
    "subject": "Important Update",
    "message": "Your return request has been processed.",
    "priority": "high"
  }'
```

---

## Error Codes

| Error Code | Description | HTTP Status |
|------------|-------------|-------------|
| `not_authenticated` | Authentication credentials not provided | 401 |
| `permission_denied` | Insufficient permissions | 403 |
| `not_found` | Resource not found | 404 |
| `validation_error` | Invalid input data | 400 |
| `rate_limit_exceeded` | API rate limit exceeded | 429 |
| `server_error` | Internal server error | 500 |

---

## Rate Limits

- **Default Rate Limit**: 1000 requests per hour per API key
- **Anonymous Users**: 100 requests per hour per IP address
- **Authenticated Users**: 5000 requests per hour per user

Rate limit headers are included in responses:
```
X-RateLimit-Limit: 1000
X-RateLimit-Remaining: 999
X-RateLimit-Reset: 1691640000
```

---

## Webhooks

The Resolution Service can send webhooks for important events:

### Webhook Events
- `review.created`
- `review.updated` 
- `return.requested`
- `return.approved`
- `return.completed`
- `dispute.created`
- `dispute.escalated`
- `dispute.resolved`

### Webhook Payload Example
```json
{
  "event": "review.created",
  "timestamp": "2025-08-10T02:46:12.123Z",
  "data": {
    "id": 1,
    "transaction_id": "TXN2024001",
    "reviewer_id": 2,
    "rating": 5,
    "title": "Great product"
  }
}
```

---

## SDK and Integration

### Python SDK Example

```python
import requests

class ResolutionServiceClient:
    def __init__(self, base_url, api_key):
        self.base_url = base_url
        self.headers = {
            'Authorization': f'Api-Key {api_key}',
            'Content-Type': 'application/json'
        }
    
    def create_review(self, review_data):
        response = requests.post(
            f'{self.base_url}/reviews/reviews/',
            json=review_data,
            headers=self.headers
        )
        return response.json()
    
    def get_user_reviews(self, user_id):
        response = requests.get(
            f'{self.base_url}/reviews/user/{user_id}/review-summary/',
            headers=self.headers
        )
        return response.json()

# Usage
client = ResolutionServiceClient(
    'http://localhost:8003/api/v1',
    'test-api-key-12345'
)

review = client.create_review({
    'transaction': 1,
    'reviewer': 2,
    'reviewed_user': 3,
    'rating': 5,
    'title': 'Great experience',
    'content': 'Smooth transaction'
})
```

---

## Testing

### Sample Test Data

The service includes sample data that can be created using:

```bash
python manage.py create_sample_data
```

This creates:
- 8 test users (including admin, buyer, seller, mediator)
- 10 transaction references
- 5 reviews with photos and responses
- 3 return requests with shipping info
- 2 disputes with messages and offers
- Multiple notification templates and logs

### Test Credentials

See `credentials.txt` for complete test account information.

---

## Support

For API support and questions:
- **Documentation**: This document
- **Health Check**: `GET /api/v1/core/health/`
- **Service Status**: `GET /api/v1/core/service-info/`
- **Admin Panel**: http://localhost:8003/admin/

---

**API Version**: 1.0  
**Last Updated**: August 2025  
**Service Status**: ✅ Active and Ready for Integration
