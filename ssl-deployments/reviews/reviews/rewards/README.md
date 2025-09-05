# BIDR Rewards System

A comprehensive rewards and referral system for BIDR, designed to work with the reviews and ratings service. This system handles referral codes, reward points, tier levels, and reward campaigns.

## Features

- **Referral System**
  - Generate unique referral codes (e.g., BIDR12345678)
  - Track referral usage and rewards
  - Prevent duplicate referrals
  - Support for custom reward amounts

- **Points System**
  - Track user points balance
  - Support multiple transaction types
  - Record all points transactions
  - Maintain audit trail

- **Tier System**
  - 5 tier levels (Basic to Platinum)
  - Automatic tier progression
  - Configurable tier requirements
  - Display progress to next tier

- **Reward Campaigns**
  - Time-based campaigns
  - Multiple campaign types
  - Configurable rewards
  - Usage limits

## Architecture

### Models

1. **ReferralCode**
   - Tracks referral codes and their usage
   - Links to referring users via UUID
   - Configurable reward amounts

2. **Referral**
   - Records successful referrals
   - Links referrer and referee
   - Tracks reward distribution

3. **RewardTransaction**
   - Records all points transactions
   - Multiple transaction types
   - Full audit trail

4. **UserRewardsSummary**
   - Maintains user points balance
   - Tracks tier level and progress
   - Optimized for quick lookups

5. **RewardsCampaign**
   - Manages special promotions
   - Time-based activation
   - Configurable rewards

### Services

The `RewardsService` class handles core business logic:
- Award referral rewards
- Process points transactions
- Calculate tier levels
- Validate referral codes

### API

- Standard RESTful API endpoints
- Flutter-optimized endpoints
- Comprehensive documentation

See [API_ENDPOINTS.md](API_ENDPOINTS.md) for complete API documentation.

## Setup

1. **Environment**
   ```bash
   python -m venv venv
   source venv/bin/activate
   pip install -r requirements.txt
   ```

2. **Database**
   ```bash
   python manage.py migrate rewards
   ```

3. **Development Server**
   ```bash
   python manage.py runserver
   ```

## Testing

```bash
python manage.py test rewards
```

## Integration

### With User Service

The rewards system integrates with the authentication service using UUIDs:
- No direct User model dependency
- All user references via UUID
- Compatible with microservice architecture

### With Flutter App

Optimized endpoints for mobile integration:
- Consolidated dashboard data
- Efficient payload sizes
- Mobile-friendly responses

## Administration

The Django admin interface provides comprehensive management:
- View and manage referral codes
- Track referrals and rewards
- Monitor transactions
- Manage reward campaigns

Access via:
```
http://localhost:8000/admin/rewards/
```

## Point Sources

Points can be earned through:
1. **Referrals**
   - Default: 50 points for referrer
   - Default: 25 points for referee

2. **Reviews**
   - Writing reviews
   - Receiving likes
   - Quality bonuses

3. **Campaigns**
   - Special events
   - Limited-time bonuses
   - Custom rewards

4. **Rating Activities**
   - Rating products/services
   - Quality contributions

## Tier Benefits

1. **Basic** (Level 1)
   - Default features
   - Standard rewards

2. **Bronze** (Level 2)
   - 500+ points
   - +10% bonus points

3. **Silver** (Level 3)
   - 2,000+ points
   - +25% bonus points
   - Special badges

4. **Gold** (Level 4)
   - 5,000+ points
   - +50% bonus points
   - Priority support

5. **Platinum** (Level 5)
   - 10,000+ points
   - +100% bonus points
   - VIP benefits

## Caveats & Considerations

1. **Data Consistency**
   - Points are tracked with Decimal precision
   - All transactions are atomic
   - Full audit trail maintained

2. **Race Conditions**
   - Atomic transactions for points
   - Unique constraints on referrals
   - Double reward prevention

3. **Security**
   - Rate limiting recommended
   - Fraud detection needed
   - Access control required

4. **Performance**
   - Optimized database queries
   - Cached summary data
   - Efficient API responses

## Future Enhancements

1. **Analytics**
   - User engagement metrics
   - Referral performance
   - Campaign effectiveness

2. **Notifications**
   - Points earned alerts
   - Tier advancement
   - Campaign notifications

3. **API Enhancements**
   - Batch operations
   - Real-time updates
   - Enhanced filtering

4. **Admin Features**
   - Advanced reporting
   - Bulk operations
   - Campaign scheduling

## Contributing

1. Fork the repository
2. Create a feature branch
3. Write tests
4. Implement feature
5. Submit pull request

## License

[License details here]
