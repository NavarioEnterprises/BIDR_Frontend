# Quote Seller ID Migration Guide

This guide explains how the quote service now handles both local User IDs and authentication service seller UUIDs.

## Problem

The quote submission was failing with:
```
{"error":{"code":"validation_error","message":"Validation failed","details":{"seller_id":["Invalid pk \"50\" - object does not exist."]}}}
```

This happened because:
1. The Quote model expects `seller_id` to be a ForeignKey to the local User model
2. But we want to support seller UUIDs from the authentication service
3. The frontend is sending integer IDs (like `50`) that don't exist in the local User table

## Solution

We've implemented a hybrid approach that accepts both:
1. **Integer IDs** - For backward compatibility with existing local users
2. **UUID strings** - For sellers from the authentication service

### Components Added

#### 1. Hybrid Serializer Field (`quotes/serializers_hybrid.py`)

```python
class HybridSellerField(serializers.Field):
    # Accepts both integer User IDs and UUID strings
    # Validates sellers exist in either local DB or auth service
```

#### 2. Updated Quote Serializer

The `QuoteCreateUpdateHybridSerializer` now:
- Accepts both formats for `seller_id`
- Validates seller existence
- Creates placeholder User records for auth service sellers (temporary solution)
- Returns seller details in the response

## Usage Examples

### 1. Submit Quote with Local User ID

```json
POST /api/v1/quotes/quotes/
{
    "request_id": "6e3b88ae-85c6-44b0-85b3-efbd24f32aa2",
    "seller_id": 50,  // Integer ID
    "total_amount": 100.00,
    "currency": "ZAR",
    "estimated_delivery_days": 7
}
```

### 2. Submit Quote with Auth Service Seller UUID

```json
POST /api/v1/quotes/quotes/
{
    "request_id": "6e3b88ae-85c6-44b0-85b3-efbd24f32aa2",
    "seller_id": "123e4567-e89b-12d3-a456-426614174000",  // UUID string
    "total_amount": 100.00,
    "currency": "ZAR",
    "estimated_delivery_days": 7
}
```

### 3. Response with Seller Details

```json
{
    "quote_id": "...",
    "seller_id": 50,  // or UUID
    "seller_details": {
        "seller_name": "ABC Company",
        "seller_email": "contact@abc.com",
        "vendor_id": "V12345678",
        "approval_status": "approved",
        "is_verified": true
    },
    ...
}
```

## How It Works

1. **Input Validation**:
   - Try to parse as integer → Look up in User table
   - Try to parse as UUID → Validate with auth service
   - Invalid format → Return validation error

2. **Storage** (Temporary):
   - For local users: Store as ForeignKey (existing behavior)
   - For auth service sellers: Create placeholder User with username `seller_{uuid}`

3. **Retrieval**:
   - Local users: Return user details
   - Auth service sellers: Fetch details from auth service API

## Migration Path

### Phase 1 (Current) - Hybrid Support
- Both integer IDs and UUIDs accepted
- Placeholder User records for auth service sellers
- No database schema changes required

### Phase 2 (Future) - Model Update
1. Add new `seller_uuid` field to Quote model
2. Migrate existing data
3. Update serializers to use new field
4. Remove placeholder User records

### Phase 3 (Final) - Full Migration
1. Remove old `seller_id` ForeignKey
2. Rename `seller_uuid` to `seller_id`
3. Update all references

## Error Handling

### Common Errors and Solutions

1. **"Invalid pk '50' - object does not exist"**
   - Cause: User ID 50 doesn't exist in local database
   - Solution: Either create the user or use auth service UUID

2. **"Seller with UUID ... not found in authentication service"**
   - Cause: UUID doesn't exist in auth service
   - Solution: Verify seller is registered in auth service

3. **"Invalid seller ID format"**
   - Cause: Value is neither valid integer nor UUID
   - Solution: Check the seller_id format

## Testing

### Test with curl

```bash
# Test with integer ID
curl -X POST http://localhost:8000/api/v1/quotes/quotes/ \
  -H "Content-Type: application/json" \
  -d '{
    "request_id": "6e3b88ae-85c6-44b0-85b3-efbd24f32aa2",
    "seller_id": 1,
    "total_amount": 100,
    "currency": "ZAR"
  }'

# Test with UUID
curl -X POST http://localhost:8000/api/v1/quotes/quotes/ \
  -H "Content-Type: application/json" \
  -d '{
    "request_id": "6e3b88ae-85c6-44b0-85b3-efbd24f32aa2",
    "seller_id": "123e4567-e89b-12d3-a456-426614174000",
    "total_amount": 100,
    "currency": "ZAR"
  }'
```

## Frontend Updates Required

1. **Seller ID Format**:
   - Can continue sending integer IDs for existing users
   - Should send UUID strings for auth service sellers

2. **Error Handling**:
   - Handle validation errors for invalid seller IDs
   - Show appropriate messages for missing sellers

3. **Response Processing**:
   - Use `seller_details` field for display
   - Don't rely on `seller_id` format

## Configuration

Ensure these settings are configured:

```python
# Authentication Service URL
AUTHENTICATION_SERVICE_URL = 'http://localhost:8001'
```

## Notes

- This is a transitional solution to maintain backward compatibility
- Placeholder User records are marked with `is_active=False`
- The username pattern `seller_{uuid}` identifies auth service sellers
- Full model migration should be planned for production