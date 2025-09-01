# Seller Integration with Authentication Service

This document explains how the product management service has been modified to fetch seller details from the authentication service instead of relying on local user data.

## Overview

The product management service now communicates with the authentication service to:
1. Fetch seller details when `seller_id` is referenced
2. Validate seller existence before creating quotes
3. Enhance API responses with comprehensive seller information
4. Support both `seller_id` and `auth_user_uid` parameters for flexibility

## Components Added

### 1. Authentication Service Client (`core/auth_service.py`)

A comprehensive client for communicating with the authentication service:

```python
from core.auth_service import get_seller_details, validate_seller_exists

# Get seller details
seller_info = get_seller_details('seller-uuid')

# Validate seller exists
is_valid = validate_seller_exists('seller-uuid')

# Get basic info with fallbacks
basic_info = get_seller_basic_info('seller-uuid')
```

**Key Features:**
- Caching for performance (5-minute default)
- Error handling and fallbacks
- Bulk operations for multiple sellers
- Support for both seller_id and auth_user_uid

### 2. Enhanced Serializers (`quotes/serializers_with_seller.py`)

New serializers that include seller details from the authentication service:

- `QuoteListWithSellerSerializer` - List view with seller info
- `QuoteDetailWithSellerSerializer` - Detail view with seller info
- `QuoteCreateUpdateWithSellerSerializer` - Create/update with seller validation
- `BulkQuoteWithSellerSerializer` - Efficient bulk operations

**Response Format:**
```json
{
  "quote_id": "uuid",
  "seller_id": "seller-uuid",
  "total_amount": "100.00",
  "seller_details": {
    "seller_name": "ABC Company",
    "seller_email": "contact@abc.com",
    "vendor_id": "V12345678",
    "approval_status": "approved",
    "average_rating": 4.5,
    "is_verified": true
  }
}
```

### 3. Updated Quote Views

Enhanced `QuoteViewSet` with new endpoints:

**New Endpoints:**
- `GET /quotes/by_seller/?seller_id=uuid` - Get quotes by seller
- `GET /quotes/by_seller/?auth_user_uid=uuid` - Get quotes by auth user
- `GET /quotes/seller_summary/?seller_id=uuid` - Get seller quote statistics
- `POST /quotes/validate_seller/` - Validate seller existence

**Usage Examples:**

```bash
# Get quotes by seller ID
GET /quotes/by_seller/?seller_id=123e4567-e89b-12d3-a456-426614174000

# Get quotes by auth user UID
GET /quotes/by_seller/?auth_user_uid=987fcdeb-51a2-43d1-9f4b-123456789abc

# Get seller summary
GET /quotes/seller_summary/?seller_id=123e4567-e89b-12d3-a456-426614174000

# Validate seller
POST /quotes/validate_seller/
{
  "seller_id": "123e4567-e89b-12d3-a456-426614174000"
}
```

## Configuration

### Settings Required

Add to `product_management_service/settings.py`:

```python
# Authentication Service Configuration
AUTHENTICATION_SERVICE_URL = os.getenv(
    'AUTHENTICATION_SERVICE_URL', 
    'http://localhost:8001'
)
AUTH_SERVICE_TIMEOUT = int(os.getenv('AUTH_SERVICE_TIMEOUT', '10'))
AUTH_SERVICE_CACHE_TIMEOUT = int(os.getenv('AUTH_SERVICE_CACHE_TIMEOUT', '300'))
```

### Environment Variables

```bash
# .env file
AUTHENTICATION_SERVICE_URL=http://localhost:8001
AUTH_SERVICE_TIMEOUT=10
AUTH_SERVICE_CACHE_TIMEOUT=300
```

## API Response Changes

### Before (Local User Data)
```json
{
  "quote_id": "uuid",
  "seller_id": 123,
  "total_amount": "100.00"
}
```

### After (Authentication Service Integration)
```json
{
  "quote_id": "uuid",
  "seller_id": "seller-uuid",
  "total_amount": "100.00",
  "seller_details": {
    "seller_name": "ABC Company",
    "seller_email": "contact@abc.com",
    "vendor_id": "V12345678",
    "approval_status": "approved",
    "average_rating": 4.5,
    "is_verified": true
  }
}
```

## Error Handling

The system includes comprehensive error handling:

1. **Service Unavailable**: Falls back to showing seller_id without details
2. **Seller Not Found**: Returns basic info with fallback values
3. **Network Issues**: Cached data used when available
4. **Invalid IDs**: Proper validation and error messages

## Performance Considerations

### Caching Strategy
- Individual seller details cached for 5 minutes
- Bulk operations minimize API calls
- Cache keys: `seller_details:{seller_id}`

### Bulk Operations
```python
# Efficient: Single bulk request
seller_ids = ['uuid1', 'uuid2', 'uuid3']
sellers_data = get_multiple_sellers(seller_ids)

# Inefficient: Multiple individual requests
for seller_id in seller_ids:
    seller_data = get_seller_details(seller_id)
```

## Testing

### Unit Tests
```python
from core.auth_service import get_seller_details

def test_seller_details_retrieval():
    seller_data = get_seller_details('valid-uuid')
    assert seller_data is not None
    assert 'seller_name' in seller_data
```

### Integration Tests
```bash
# Test authentication service connectivity
curl http://localhost:8001/seller/profiles/

# Test quote endpoints with seller integration
curl "http://localhost:8000/quotes/by_seller/?seller_id=uuid"
```

## Migration Guide

### For Frontend Applications

1. **Update API Calls**: Use new endpoints that support both `seller_id` and `auth_user_uid`
2. **Handle Enhanced Responses**: Process the new `seller_details` field
3. **Error Handling**: Handle cases where seller service is unavailable

### For Other Services

1. **Seller ID Format**: Ensure you're using UUIDs instead of integer IDs
2. **Authentication Service Dependency**: Make sure authentication service is accessible
3. **Caching**: Consider implementing client-side caching for better performance

## Troubleshooting

### Common Issues

1. **"Seller not found" errors**
   - Check if seller exists in authentication service
   - Verify seller_id is a valid UUID
   - Check authentication service connectivity

2. **Performance issues**
   - Enable caching
   - Use bulk operations for multiple sellers
   - Monitor authentication service response times

3. **Empty seller_details**
   - Check authentication service logs
   - Verify API endpoint structure
   - Check network connectivity

### Debug Commands

```bash
# Test authentication service connectivity
curl http://localhost:8001/health/

# Check seller in authentication service
curl http://localhost:8001/seller/profiles/{seller_id}/

# Test quote service integration
curl "http://localhost:8000/quotes/validate_seller/" \
  -d '{"seller_id": "uuid"}' \
  -H "Content-Type: application/json"
```

## Future Enhancements

1. **Real-time Updates**: WebSocket integration for seller status changes
2. **Advanced Caching**: Redis integration for distributed caching
3. **Metrics**: Monitor authentication service call performance
4. **Fallback Service**: Local seller cache for high availability