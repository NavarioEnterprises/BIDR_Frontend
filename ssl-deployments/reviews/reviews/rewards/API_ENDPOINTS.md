# BIDR Rewards API Endpoints

This document outlines all the API endpoints available in the BIDR rewards system.

## Base URLs

- **Reviews & Ratings Service**: `/reviews/`  
- **Rewards Service**: `/rewards/`

## Flutter-Optimized Endpoints

These endpoints are specifically designed for the Flutter mobile app:

### 1. Get Rewards Dashboard
**GET** `/rewards/api/flutter/dashboard/`

Get complete rewards dashboard data for a user.

**Parameters:**
- `user_uuid` (required): UUID of the user

**Response:**
```json
{
  "summary": {
    "user_uuid": "uuid",
    "current_points_balance": 150.00,
    "total_points_earned": 200.00,
    "total_points_spent": 50.00,
    "tier_level": 2,
    "tier_name": "Bronze",
    "points_to_next_tier": 350,
    "is_active": true
  },
  "referral_code": {
    "code": "BIDR12345678",
    "referral_url": "https://bidr.co.za/referral?code=BIDR12345678",
    "total_uses": 5,
    "referrer_reward_amount": 50.00,
    "referee_reward_amount": 25.00
  },
  "recent_transactions": [
    {
      "id": "uuid",
      "transaction_type": "REFERRAL_BONUS",
      "points_amount": 50.00,
      "description": "Referral reward for inviting user",
      "created_at": "2024-01-01T10:00:00Z",
      "status": "COMPLETED"
    }
  ],
  "active_campaigns": [
    {
      "id": "uuid",
      "name": "Double Points Weekend",
      "description": "Earn double points on all activities",
      "reward_points": 100.00,
      "starts_at": "2024-01-01T00:00:00Z",
      "ends_at": "2024-01-03T23:59:59Z"
    }
  ]
}
```

### 2. Process Referral
**POST** `/rewards/api/flutter/process-referral/`

Process a new user signup via referral code.

**Request Body:**
```json
{
  "referral_code": "BIDR12345678",
  "user_uuid": "new-user-uuid"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Referral processed successfully! You both earned points!",
  "referrer_reward": 50.00,
  "referee_reward": 25.00,
  "referral_id": "uuid"
}
```

### 3. Validate Referral Code
**GET** `/rewards/api/flutter/validate-code/`

Validate a referral code before processing signup.

**Parameters:**
- `code` (required): The referral code to validate

**Response:**
```json
{
  "valid": true,
  "referrer_reward": 50.00,
  "referee_reward": 25.00,
  "message": "Valid referral code! You will earn 25.00 points when you sign up!"
}
```

### 4. Get My Referral Code
**GET** `/rewards/api/flutter/my-code/`

Get or create a user's referral code.

**Parameters:**
- `user_uuid` (required): UUID of the user

**Response:**
```json
{
  "code": "BIDR12345678",
  "referral_url": "https://bidr.co.za/referral?code=BIDR12345678",
  "total_uses": 5,
  "referrer_reward_amount": 50.00,
  "referee_reward_amount": 25.00,
  "status": "ACTIVE"
}
```

### 5. Get My Referrals
**GET** `/rewards/api/flutter/my-referrals/`

Get referrals made by a user.

**Parameters:**
- `user_uuid` (required): UUID of the user

**Response:** Paginated list of referrals

### 6. Get My Transactions
**GET** `/rewards/api/flutter/my-transactions/`

Get reward transactions for a user.

**Parameters:**
- `user_uuid` (required): UUID of the user

**Response:** Paginated list of transactions

### 7. Get My Rewards Summary
**GET** `/rewards/api/flutter/my-summary/`

Get rewards summary for a user.

**Parameters:**
- `user_uuid` (required): UUID of the user

**Response:**
```json
{
  "user_uuid": "uuid",
  "current_points_balance": 150.00,
  "total_points_earned": 200.00,
  "total_points_spent": 50.00,
  "tier_level": 2,
  "is_active": true
}
```

### 8. Get Leaderboard
**GET** `/rewards/api/flutter/leaderboard/`

Get top users by points balance.

**Parameters:**
- `limit` (optional): Number of users to return (default: 10, max: 100)

**Response:** List of user summaries ordered by points balance

### 9. Get Active Campaigns
**GET** `/rewards/api/flutter/active-campaigns/`

Get currently active reward campaigns.

**Response:** List of active campaigns

## Standard REST API Endpoints

### Referral Codes
- **GET** `/rewards/api/referral-codes/` - List referral codes
- **POST** `/rewards/api/referral-codes/` - Create referral code
- **GET** `/rewards/api/referral-codes/{id}/` - Get specific referral code
- **PUT** `/rewards/api/referral-codes/{id}/` - Update referral code
- **POST** `/rewards/api/referral-codes/{id}/regenerate/` - Regenerate code

### Referrals
- **GET** `/rewards/api/referrals/` - List referrals
- **POST** `/rewards/api/referrals/` - Create referral
- **GET** `/rewards/api/referrals/{id}/` - Get specific referral
- **POST** `/rewards/api/referrals/process_referral/` - Process new referral

### Transactions
- **GET** `/rewards/api/transactions/` - List reward transactions
- **GET** `/rewards/api/transactions/{id}/` - Get specific transaction

### User Summaries
- **GET** `/rewards/api/summaries/` - List user reward summaries
- **GET** `/rewards/api/summaries/{user_uuid}/` - Get specific user summary

### Campaigns
- **GET** `/rewards/api/campaigns/` - List reward campaigns
- **GET** `/rewards/api/campaigns/{id}/` - Get specific campaign

## Error Responses

All endpoints return consistent error responses:

```json
{
  "error": "Error message description"
}
```

Common HTTP status codes:
- `200` - Success
- `201` - Created
- `400` - Bad Request (missing parameters, validation errors)
- `403` - Forbidden (permission denied)
- `404` - Not Found
- `500` - Internal Server Error

## Authentication

Currently, all endpoints use `AllowAny` permission for development. In production, implement proper authentication and authorization.

## Integration with Flutter App

The Flutter app should primarily use the `/rewards/api/flutter/` endpoints as they are optimized for mobile usage:

1. **App Launch**: Call `/flutter/dashboard/` to get complete user rewards data
2. **Share Referral**: Use `/flutter/my-code/` to get the user's referral code and URL
3. **New User Signup**: Call `/flutter/validate-code/` to validate referral codes, then `/flutter/process-referral/` after successful registration
4. **Rewards History**: Use `/flutter/my-transactions/` for transaction history
5. **Leaderboard**: Use `/flutter/leaderboard/` for competitive features

## Models Overview

### ReferralCode
- Generates unique codes like "BIDR12345678"
- Tracks usage statistics and reward amounts
- Supports expiration and usage limits

### Referral
- Links referrer and referee
- Tracks reward distribution
- Prevents duplicate referrals

### RewardTransaction
- Records all points transactions
- Supports various transaction types
- Maintains audit trail

### UserRewardsSummary
- Caches user points balance and tier level
- Updated automatically via signals
- Optimized for quick lookups

### RewardsCampaign
- Manages special promotions
- Time-based activation
- Configurable rewards and limits

## Tier System

Users are automatically assigned to tiers based on total points earned:

1. **Basic** (Level 1): 0+ points
2. **Bronze** (Level 2): 500+ points
3. **Silver** (Level 3): 2,000+ points
4. **Gold** (Level 4): 5,000+ points
5. **Platinum** (Level 5): 10,000+ points

## Default Reward Amounts

- **Referrer Bonus**: 50 points
- **Referee Bonus**: 25 points
- **Review Bonus**: TBD (configurable)
- **Rating Bonus**: TBD (configurable)

These can be customized per referral code or campaign.
