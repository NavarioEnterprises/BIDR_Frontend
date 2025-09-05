# Product Requests API Documentation

## Overview

The Product Requests API provides endpoints for managing product requests in the BIDR system. Users can create, view, update, and delete product requests, as well as interact with related features like messages and watchlists.

## Base URL

```
/api/v1/product-requests/
```

## Authentication

All endpoints require authentication via Bearer token:

```
Authorization: Bearer <your_token_here>
```

## Product Request Endpoints

### 1. List Product Requests

**GET** `/api/v1/product-requests/`

List all product requests with pagination, filtering, and search capabilities.

#### Query Parameters

| Parameter | Type | Description | Example |
|-----------|------|-------------|---------|
| `page` | integer | Page number for pagination | `?page=2` |
| `page_size` | integer | Number of items per page (default: 20) | `?page_size=10` |
| `category` | integer | Filter by category ID | `?category=1` |
| `urgency` | string | Filter by urgency level | `?urgency=high` |
| `status` | string | Filter by status | `?status=open` |
| `budget_min` | decimal | Filter by minimum budget | `?budget_min=100.00` |
| `budget_max` | decimal | Filter by maximum budget | `?budget_max=1000.00` |
| `created_after` | date | Filter requests created after date | `?created_after=2023-01-01` |
| `created_before` | date | Filter requests created before date | `?created_before=2023-12-31` |
| `search` | string | Search in title and description | `?search=smartphone` |
| `ordering` | string | Order results by field | `?ordering=-created_at` |

#### Response

```json
{
  "count": 50,
  "next": "http://api.example.com/product-requests/?page=3",
  "previous": "http://api.example.com/product-requests/?page=1",
  "results": [
    {
      "id": 1,
      "request_id": "PR-001",
      "user": 1,
      "category": 1,
      "title": "Looking for smartphones",
      "description": "Need 20 smartphones for office use",
      "quantity_needed": 20,
      "budget_min": "200.00",
      "budget_max": "500.00",
      "urgency": "medium",
      "status": "open",
      "created_at": "2023-10-01T10:00:00Z",
      "updated_at": "2023-10-01T10:00:00Z",
      "expires_at": "2023-11-01T10:00:00Z",
      "location": "Harare, Zimbabwe",
      "delivery_requirements": "Express delivery preferred",
      "additional_notes": "Prefer Android devices",
      "quote_count": 5,
      "consumer_electronics_specs": {
        "brand": "Samsung",
        "model": "Galaxy S21",
        "screen_size": "6.2 inches",
        "ram": "8GB",
        "storage": "128GB",
        "color": "Black"
      }
    }
  ]
}
```

### 2. Create Product Request

**POST** `/api/v1/product-requests/`

Create a new product request.

#### Request Body

```json
{
  "category": 1,
  "title": "Looking for laptops",
  "description": "Need 10 laptops for development team",
  "quantity_needed": 10,
  "budget_min": "800.00",
  "budget_max": "1200.00",
  "urgency": "high",
  "location": "Harare, Zimbabwe",
  "delivery_requirements": "Standard delivery",
  "additional_notes": "Prefer MacBooks or ThinkPads",
  "consumer_electronics_specs": {
    "brand": "Apple",
    "model": "MacBook Pro",
    "screen_size": "13 inches",
    "ram": "16GB",
    "storage": "512GB",
    "color": "Silver",
    "warranty_period": 12
  }
}
```

#### Response (201 Created)

```json
{
  "id": 2,
  "request_id": "PR-002",
  "user": 1,
  "category": 1,
  "title": "Looking for laptops",
  "description": "Need 10 laptops for development team",
  "quantity_needed": 10,
  "budget_min": "800.00",
  "budget_max": "1200.00",
  "urgency": "high",
  "status": "open",
  "created_at": "2023-10-01T11:00:00Z",
  "updated_at": "2023-10-01T11:00:00Z",
  "expires_at": "2023-11-01T11:00:00Z",
  "location": "Harare, Zimbabwe",
  "delivery_requirements": "Standard delivery",
  "additional_notes": "Prefer MacBooks or ThinkPads",
  "quote_count": 0,
  "consumer_electronics_specs": {
    "brand": "Apple",
    "model": "MacBook Pro",
    "screen_size": "13 inches",
    "ram": "16GB",
    "storage": "512GB",
    "color": "Silver",
    "warranty_period": 12
  }
}
```

### 3. Get Product Request Details

**GET** `/api/v1/product-requests/{id}/`

Retrieve details of a specific product request.

#### Response

```json
{
  "id": 1,
  "request_id": "PR-001",
  "user": 1,
  "category": 1,
  "title": "Looking for smartphones",
  "description": "Need 20 smartphones for office use",
  "quantity_needed": 20,
  "budget_min": "200.00",
  "budget_max": "500.00",
  "urgency": "medium",
  "status": "open",
  "created_at": "2023-10-01T10:00:00Z",
  "updated_at": "2023-10-01T10:00:00Z",
  "expires_at": "2023-11-01T10:00:00Z",
  "location": "Harare, Zimbabwe",
  "delivery_requirements": "Express delivery preferred",
  "additional_notes": "Prefer Android devices",
  "quote_count": 5,
  "consumer_electronics_specs": {
    "brand": "Samsung",
    "model": "Galaxy S21",
    "screen_size": "6.2 inches",
    "ram": "8GB",
    "storage": "128GB",
    "color": "Black"
  }
}
```

### 4. Update Product Request

**PUT/PATCH** `/api/v1/product-requests/{id}/`

Update a product request (only the owner can update).

#### Request Body (PATCH)

```json
{
  "title": "Updated title",
  "urgency": "high",
  "additional_notes": "Updated requirements"
}
```

#### Response (200 OK)

```json
{
  "id": 1,
  "request_id": "PR-001",
  "user": 1,
  "category": 1,
  "title": "Updated title",
  "description": "Need 20 smartphones for office use",
  "quantity_needed": 20,
  "budget_min": "200.00",
  "budget_max": "500.00",
  "urgency": "high",
  "status": "open",
  "created_at": "2023-10-01T10:00:00Z",
  "updated_at": "2023-10-01T12:00:00Z",
  "expires_at": "2023-11-01T10:00:00Z",
  "location": "Harare, Zimbabwe",
  "delivery_requirements": "Express delivery preferred",
  "additional_notes": "Updated requirements",
  "quote_count": 5
}
```

### 5. Delete Product Request

**DELETE** `/api/v1/product-requests/{id}/`

Delete a product request (only the owner can delete).

#### Response (204 No Content)

No response body.

### 6. Close Product Request

**POST** `/api/v1/product-requests/{id}/close/`

Close a product request (only the owner can close).

#### Response (200 OK)

```json
{
  "message": "Product request closed successfully",
  "status": "closed"
}
```

### 7. My Product Requests

**GET** `/api/v1/product-requests/my-requests/`

Get the current user's product requests.

#### Response

```json
{
  "count": 3,
  "next": null,
  "previous": null,
  "results": [
    {
      "id": 1,
      "request_id": "PR-001",
      "user": 1,
      "category": 1,
      "title": "Looking for smartphones",
      "description": "Need 20 smartphones for office use",
      "quantity_needed": 20,
      "budget_min": "200.00",
      "budget_max": "500.00",
      "urgency": "medium",
      "status": "open",
      "created_at": "2023-10-01T10:00:00Z",
      "updated_at": "2023-10-01T10:00:00Z",
      "quote_count": 5
    }
  ]
}
```

## Product Request Messages

### 8. List Messages

**GET** `/api/v1/product-request-messages/`

List messages for product requests.

#### Query Parameters

| Parameter | Type | Description | Example |
|-----------|------|-------------|---------|
| `product_request` | integer | Filter by product request ID | `?product_request=1` |

#### Response

```json
{
  "count": 10,
  "next": null,
  "previous": null,
  "results": [
    {
      "id": 1,
      "product_request": 1,
      "sender": 2,
      "message": "I can provide these smartphones at competitive prices",
      "created_at": "2023-10-01T11:30:00Z",
      "is_read": false
    }
  ]
}
```

### 9. Create Message

**POST** `/api/v1/product-request-messages/`

Send a message for a product request.

#### Request Body

```json
{
  "product_request": 1,
  "message": "What are the payment terms?"
}
```

#### Response (201 Created)

```json
{
  "id": 2,
  "product_request": 1,
  "sender": 1,
  "message": "What are the payment terms?",
  "created_at": "2023-10-01T12:00:00Z",
  "is_read": false
}
```

## Product Request Watchlist

### 10. List Watchlist

**GET** `/api/v1/product-request-watchlist/`

List the current user's watchlisted product requests.

#### Response

```json
{
  "count": 5,
  "next": null,
  "previous": null,
  "results": [
    {
      "id": 1,
      "user": 1,
      "product_request": 2,
      "created_at": "2023-10-01T13:00:00Z"
    }
  ]
}
```

### 11. Add to Watchlist

**POST** `/api/v1/product-request-watchlist/`

Add a product request to the user's watchlist.

#### Request Body

```json
{
  "product_request": 2
}
```

#### Response (201 Created)

```json
{
  "id": 2,
  "user": 1,
  "product_request": 2,
  "created_at": "2023-10-01T13:30:00Z"
}
```

### 12. Remove from Watchlist

**DELETE** `/api/v1/product-request-watchlist/{id}/`

Remove a product request from the user's watchlist.

#### Response (204 No Content)

No response body.

## Category-Specific Specifications

### Consumer Electronics

When creating/updating a consumer electronics product request, include the `consumer_electronics_specs` field:

```json
{
  "consumer_electronics_specs": {
    "brand": "Apple",
    "model": "iPhone 14",
    "screen_size": "6.1 inches",
    "ram": "6GB",
    "storage": "256GB",
    "color": "Blue",
    "warranty_period": 12,
    "energy_rating": "A+",
    "connectivity": "WiFi, Bluetooth, 5G"
  }
}
```

### Vehicle Spares

When creating/updating a vehicle spares product request, include the `vehicle_spares_specs` field:

```json
{
  "vehicle_spares_specs": {
    "vehicle_make": "Toyota",
    "vehicle_model": "Camry",
    "vehicle_year": 2020,
    "part_number": "BP-12345",
    "oem_part": true,
    "compatibility": "Toyota Camry 2018-2022",
    "condition": "new",
    "warranty_months": 12
  }
}
```

### Vehicle Tyres & Rims

When creating/updating a vehicle tyres & rims product request, include the `vehicle_tyres_rims_specs` field:

```json
{
  "vehicle_tyres_rims_specs": {
    "tyre_size": "225/60R16",
    "rim_size": "16 inches",
    "tyre_brand": "Michelin",
    "rim_material": "Alloy",
    "load_rating": "H",
    "speed_rating": "91",
    "season": "all_season",
    "runflat": false
  }
}
```

## Error Responses

### 400 Bad Request

```json
{
  "error": "Validation failed",
  "details": {
    "title": ["This field is required."],
    "budget_min": ["Ensure this value is greater than 0."]
  }
}
```

### 401 Unauthorized

```json
{
  "error": "Authentication required",
  "message": "You must be authenticated to access this resource."
}
```

### 403 Forbidden

```json
{
  "error": "Permission denied",
  "message": "You do not have permission to perform this action."
}
```

### 404 Not Found

```json
{
  "error": "Not found",
  "message": "Product request not found."
}
```

## Status Codes

| Code | Status | Description |
|------|--------|-------------|
| 200 | OK | Request successful |
| 201 | Created | Resource created successfully |
| 204 | No Content | Resource deleted successfully |
| 400 | Bad Request | Invalid request data |
| 401 | Unauthorized | Authentication required |
| 403 | Forbidden | Permission denied |
| 404 | Not Found | Resource not found |
| 500 | Internal Server Error | Server error |

## Rate Limiting

API requests are rate limited to:
- 1000 requests per hour for authenticated users
- 100 requests per hour for unauthenticated users

When rate limits are exceeded, the API returns a `429 Too Many Requests` status code with retry information in the headers.

## Examples

### Create a Complete Consumer Electronics Request

```bash
curl -X POST \
  'http://localhost:8000/api/v1/product-requests/' \
  -H 'Authorization: Bearer your_token_here' \
  -H 'Content-Type: application/json' \
  -d '{
    "category": 1,
    "title": "Office Smartphones Needed",
    "description": "We need 25 smartphones for our sales team. Preference for Android devices with good battery life.",
    "quantity_needed": 25,
    "budget_min": "250.00",
    "budget_max": "450.00",
    "urgency": "medium",
    "location": "Harare, Zimbabwe",
    "delivery_requirements": "Standard delivery acceptable",
    "additional_notes": "Bulk discount expected. Need invoice for accounting.",
    "consumer_electronics_specs": {
      "brand": "Samsung",
      "model": "Galaxy A54",
      "screen_size": "6.4 inches",
      "ram": "8GB",
      "storage": "256GB",
      "color": "Black",
      "warranty_period": 24,
      "connectivity": "WiFi, Bluetooth, 4G/5G"
    }
  }'
```

### Search for Product Requests

```bash
curl -X GET \
  'http://localhost:8000/api/v1/product-requests/?search=smartphone&urgency=high&ordering=-created_at' \
  -H 'Authorization: Bearer your_token_here'
```

### Get My Product Requests

```bash
curl -X GET \
  'http://localhost:8000/api/v1/product-requests/my-requests/' \
  -H 'Authorization: Bearer your_token_here'
```

This API provides comprehensive functionality for managing product requests in the BIDR system, supporting all major operations including creation, retrieval, updating, deletion, and related features like messaging and watchlists.
