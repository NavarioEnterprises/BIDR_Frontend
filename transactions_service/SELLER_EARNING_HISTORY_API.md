# Seller Earning History API Documentation

## Overview

The Seller Earning History API endpoint provides sellers with access to their earning history from successful transactions. This endpoint returns payment transactions with status `CAPTURED`, `RELEASED`, or `PAID`, representing successful payments where the seller has earned money.

## Endpoint Details

- **URL**: `/api/v1/payment-transactions/seller-earnings/`
- **Method**: `GET`
- **Authentication**: Required (Bearer token)
- **Authorization**: Sellers (own data) and Administrators (all data)

## Authentication & Authorization

### Required Headers
```
Authorization: Bearer <your-auth-token>
Content-Type: application/json
```

### Access Control
- **Sellers**: Can only access their own earning history
- **Administrators**: Can access earning history for all sellers
- **Other roles**: Access denied (403 Forbidden)

## Query Parameters

All query parameters are optional:

| Parameter | Type | Description | Example |
|-----------|------|-------------|---------|
| `start_date` | string | Filter earnings from this date (YYYY-MM-DD) | `2024-01-01` |
| `end_date` | string | Filter earnings to this date (YYYY-MM-DD) | `2024-12-31` |
| `status` | string | Filter by payment status (`CAPTURED`, `RELEASED`, `PAID`) | `RELEASED` |
| `seller_id` | string | Filter by seller ID (Admin only) | `uuid-string` |

## Response Format

### Successful Response (200 OK)

```json
{
    "count": 25,
    "next": "http://api.example.com/api/v1/payment-transactions/seller-earnings/?page=2",
    "previous": null,
    "results": [
        {
            "payment_id": "123e4567-e89b-12d3-a456-426614174000",
            "transaction_id": "987fcdeb-51a2-43d5-b789-123456789abc",
            "amount": "150.00",
            "currency": "USD",
            "order_date": "2024-01-15T10:30:00Z",
            "status": "RELEASED",
            "earnings_status": "Earnings Released",
            "buyer_info": {
                "buyer_id": "buyer-uuid-here",
                "username": "buyer123",
                "email": "buyer@example.com"
            },
            "product_info": {
                "quote_id": "quote-uuid-here",
                "amount": "150.00",
                "currency": "USD"
            },
            "actual_release_date": "2024-01-20T14:15:00Z",
            "created_at": "2024-01-15T10:30:00Z"
        }
    ]
}
```

### Response Fields

| Field | Type | Description |
|-------|------|-------------|
| `payment_id` | string | Unique payment identifier |
| `transaction_id` | string | Associated transaction ID |
| `amount` | string | Earning amount (decimal as string) |
| `currency` | string | Currency code (ISO 4217) |
| `order_date` | string | Original order/transaction creation date (ISO 8601) |
| `status` | string | Payment status (`CAPTURED`, `RELEASED`, `PAID`) |
| `earnings_status` | string | User-friendly status description |
| `buyer_info` | object | Buyer information |
| `buyer_info.buyer_id` | string | Buyer's unique identifier |
| `buyer_info.username` | string | Buyer's username |
| `buyer_info.email` | string | Buyer's email address |
| `product_info` | object | Product/service information |
| `product_info.quote_id` | string | Quote/product unique identifier |
| `product_info.amount` | string | Original quote amount |
| `product_info.currency` | string | Quote currency |
| `actual_release_date` | string | When earnings were actually released (ISO 8601) |
| `created_at` | string | Payment creation timestamp (ISO 8601) |

## Example Requests

### 1. Basic Request (Seller accessing own data)
```bash
curl -X GET \
  "https://api.bidr.co.za/api/v1/payment-transactions/seller-earnings/" \
  -H "Authorization: Bearer your-seller-token" \
  -H "Content-Type: application/json"
```

### 2. Filter by Date Range
```bash
curl -X GET \
  "https://api.bidr.co.za/api/v1/payment-transactions/seller-earnings/?start_date=2024-01-01&end_date=2024-12-31" \
  -H "Authorization: Bearer your-seller-token" \
  -H "Content-Type: application/json"
```

### 3. Filter by Payment Status
```bash
curl -X GET \
  "https://api.bidr.co.za/api/v1/payment-transactions/seller-earnings/?status=RELEASED" \
  -H "Authorization: Bearer your-seller-token" \
  -H "Content-Type: application/json"
```

### 4. Admin Request for Specific Seller
```bash
curl -X GET \
  "https://api.bidr.co.za/api/v1/payment-transactions/seller-earnings/?seller_id=seller-uuid-here" \
  -H "Authorization: Bearer your-admin-token" \
  -H "Content-Type: application/json"
```

## Error Responses

### 401 Unauthorized
```json
{
    "detail": "Authentication credentials were not provided."
}
```

### 403 Forbidden
```json
{
    "detail": "Only sellers and administrators can access earning history"
}
```

### 400 Bad Request
```json
{
    "detail": "Invalid date format. Use YYYY-MM-DD."
}
```

## Pagination

The API uses cursor-based pagination with the following parameters:
- `count`: Total number of records
- `next`: URL for the next page (null if last page)
- `previous`: URL for the previous page (null if first page)
- `results`: Array of earning records

## Payment Status Meanings

| Status | Description |
|--------|-------------|
| `CAPTURED` | Payment has been successfully captured from buyer but not yet released to seller |
| `RELEASED` | Payment has been released to seller (seller earnings are available) |
| `PAID` | Payment transaction completed successfully |

## Use Cases

### 1. Dashboard Earnings Summary
Fetch recent earnings for dashboard display:
```
GET /api/v1/payment-transactions/seller-earnings/?start_date=2024-01-01
```

### 2. Monthly Earnings Report  
Get earnings for a specific month:
```
GET /api/v1/payment-transactions/seller-earnings/?start_date=2024-01-01&end_date=2024-01-31
```

### 3. Released Earnings Only
Show only earnings that have been released:
```
GET /api/v1/payment-transactions/seller-earnings/?status=RELEASED
```

### 4. Admin Analytics
Admins can analyze specific seller performance:
```
GET /api/v1/payment-transactions/seller-earnings/?seller_id=uuid&start_date=2024-01-01
```

## Integration Notes

1. **Caching**: Consider implementing client-side caching for better performance
2. **Rate Limiting**: The endpoint is subject to standard API rate limits
3. **Pagination**: Always handle paginated responses for better UX
4. **Error Handling**: Implement proper error handling for network issues and API errors
5. **Security**: Always use HTTPS and secure token storage

## Related Endpoints

- `/api/v1/payment-transactions/` - All payment transactions
- `/api/v1/payment-transactions/pending-release/` - Payments pending release (Admin only)
- `/api/v1/payment-transactions/{id}/` - Specific payment transaction details

## Support

For technical support or questions about this API endpoint, please contact the BIDR development team or refer to the general API documentation.