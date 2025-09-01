# SMS Portal Integration for BIDR Backend

This document describes the SMS Portal integration implemented for the BIDR Backend services, providing comprehensive SMS messaging capabilities with tracking, analytics, and multi-channel notification support.

## Overview

The SMS integration includes:
- **SMS Portal API Integration**: Direct integration with SMS Portal for sending SMS messages
- **Multi-channel Notifications**: Support for both Email and SMS delivery
- **OTP Support**: Enhanced OTP delivery via SMS and Email
- **Message Tracking**: Complete tracking of SMS delivery status and costs
- **Usage Analytics**: Detailed SMS usage statistics and reporting
- **Template System**: Reusable SMS templates for different message types

## Architecture

### Services Structure

```
notifications_service/
├── sms_portal/                    # New SMS Portal integration app
│   ├── models.py                  # SMS models (Config, Message, Stats, Templates)
│   ├── services.py                # SMS service classes
│   ├── views.py                   # API endpoints
│   ├── admin.py                   # Django admin interface
│   └── management/commands/       # Management commands
│       ├── create_sms_templates.py
│       └── test_sms_sending.py
├── system_notifications/
│   └── services.py                # Enhanced notification service
└── ...

authentication_service/
├── otp/
│   ├── services.py                # OTP delivery service
│   ├── multi_channel_views.py     # Multi-channel OTP endpoints
│   └── views.py                   # Enhanced OTP views
└── ...
```

## Setup and Configuration

### 1. Environment Variables

Add these environment variables to your configuration:

```bash
# SMS Portal Configuration
SMS_PORTAL_API_URL=https://rest.smsportal.com/v1
SMS_PORTAL_API_KEY=your_api_key_here
SMS_PORTAL_API_SECRET=your_api_secret_here
SMS_PORTAL_SENDER_ID=BIDR

# Notification Service Configuration
NOTIFICATION_SERVICE_URL=http://localhost:8001

# Email Configuration (update)
DEFAULT_FROM_EMAIL=noreply@bidr.com
```

### 2. Database Migration

Run migrations for the notifications service:

```bash
cd notifications_service/
python manage.py migrate
```

### 3. Create Default Templates and Configuration

```bash
# Create SMS templates and configuration
python manage.py create_sms_templates

# Test SMS sending (optional)
python manage.py test_sms_sending --phone "+1234567890" --dry-run
```

### 4. Admin Configuration

1. Access Django Admin for notifications service
2. Navigate to "SMS Portal" section
3. Update the SMS Portal configuration with your API credentials
4. Activate the configuration by setting `is_active = True`

## API Endpoints

### Notifications Service

#### SMS Portal Endpoints
- `POST /api/v1/sms/send/` - Send single SMS
- `POST /api/v1/sms/send/otp/` - Send OTP SMS with template
- `POST /api/v1/sms/send/bulk/` - Send bulk SMS
- `GET /api/v1/sms/messages/` - List SMS messages with filtering
- `GET /api/v1/sms/stats/` - SMS usage statistics
- `GET /api/v1/sms/dashboard/` - SMS dashboard stats
- `GET /api/v1/sms/templates/` - SMS templates management

#### Enhanced Notification Endpoints
- `POST /api/v1/notifications/send/` - Multi-channel notification
- `POST /api/v1/notifications/send/otp/` - Multi-channel OTP
- `POST /api/v1/notifications/bulk-send/` - Bulk notifications

### Authentication Service

#### Enhanced OTP Endpoints
- `POST /api/v1/otp/send/` - Multi-channel OTP sending
- `POST /api/v1/otp/status/` - Check delivery channels
- `POST /api/v1/otp/resend/` - Resend with SMS support
- `POST /api/v1/otp/verify/` - OTP verification

## Usage Examples

### 1. Send Single SMS

```python
import requests

# Direct SMS sending
response = requests.post('http://localhost:8001/api/v1/sms/send/', json={
    'phone_number': '+1234567890',
    'message': 'Your order has been confirmed!',
    'message_type': 'notification',
    'sender_id': 'BIDR'
})
```

### 2. Send OTP via Multiple Channels

```python
# Multi-channel OTP (Email + SMS)
response = requests.post('http://localhost:8001/api/v1/notifications/send/otp/', json={
    'recipient_id': 'user-uuid',
    'otp_code': '123456',
    'recipient_email': 'user@example.com',
    'recipient_phone': '+1234567890',
    'channels': ['email', 'sms']
})
```

### 3. Send Multi-channel Notification

```python
# Send notification via both Email and SMS
response = requests.post('http://localhost:8001/api/v1/notifications/send/', json={
    'recipient_id': 'user-uuid',
    'type': 'payment_success',
    'subject': 'Payment Successful',
    'message': 'Your payment of $50.00 has been processed successfully.',
    'channels': ['email', 'sms', 'in_app'],
    'recipient_email': 'user@example.com',
    'recipient_phone': '+1234567890',
    'context': {
        'amount': '$50.00',
        'transaction_id': 'TXN123456'
    }
})
```

### 4. Authentication Service OTP

```python
# Enhanced OTP with fallback support
response = requests.post('http://localhost:8000/api/v1/otp/send/', json={
    'email': 'user@example.com',
    'phone': '+1234567890',
    'channels': ['sms', 'email'],
    'force_create': false
})
```

### 5. Bulk SMS Sending

```python
# Send bulk SMS
response = requests.post('http://localhost:8001/api/v1/sms/send/bulk/', json={
    'recipients': ['+1234567890', '+0987654321'],
    'message': 'System maintenance scheduled for tonight.',
    'message_type': 'system',
    'template_name': 'system_maintenance',
    'context': {
        'date': '2025-01-01',
        'start_time': '02:00',
        'end_time': '04:00'
    }
})
```

## SMS Templates

### Default Templates

The system comes with pre-configured templates:

1. **otp_verification** - Standard OTP message
2. **otp_welcome** - Welcome OTP for new users
3. **payment_success** - Payment confirmation
4. **payment_failed** - Payment failure alert
5. **order_update** - Order status updates
6. **security_alert** - Security notifications
7. **account_locked** - Account lockout notification
8. **password_reset** - Password reset OTP
9. **welcome_message** - Welcome message
10. **review_received** - New review notification
11. **dispute_created** - Dispute creation alert
12. **system_maintenance** - Maintenance notifications

### Template Usage

Templates use Python string formatting with placeholders:

```python
# Template content example
"Your BIDR verification code is: {code}. Valid for 5 minutes."

# Context data
context = {'code': '123456'}

# Rendered message
"Your BIDR verification code is: 123456. Valid for 5 minutes."
```

## Monitoring and Analytics

### SMS Usage Statistics

The system tracks:
- Total messages sent/delivered/failed
- Delivery rates and success rates
- Cost tracking and credit usage
- Message type breakdown
- Daily/monthly usage patterns

### Dashboard Metrics

Access dashboard statistics:

```python
# Get dashboard stats for last 30 days
response = requests.get('http://localhost:8001/api/v1/sms/dashboard/?days=30')

# Response includes:
{
    "total_messages": 1250,
    "sent_messages": 1200,
    "failed_messages": 50,
    "delivered_messages": 1180,
    "success_rate": 96.0,
    "delivery_rate": 98.3,
    "total_cost": 125.50,
    "message_type_breakdown": {
        "otp": 800,
        "notification": 300,
        "alert": 100,
        "system": 50
    },
    "daily_activity": {...}
}
```

## Error Handling and Resilience

### Fallback Mechanisms

1. **Multi-channel Fallback**: If SMS fails, email is attempted
2. **Service Fallback**: Direct SMS sending if notification service is unavailable
3. **Retry Logic**: Automatic retry for failed messages
4. **Queue Management**: Message queuing for high-volume sending

### Error Codes

Common error scenarios:
- `INSUFFICIENT_CREDITS`: SMS Portal account balance low
- `INVALID_PHONE`: Invalid phone number format
- `RATE_LIMIT_EXCEEDED`: Too many messages sent
- `NETWORK_ERROR`: Network connectivity issues
- `API_ERROR`: SMS Portal API errors

## Security Considerations

### API Credentials
- Store SMS Portal credentials securely using environment variables
- Rotate API keys regularly
- Monitor API usage for unusual activity

### Phone Number Validation
- Validate phone numbers before sending
- Implement rate limiting per phone number
- Sanitize phone numbers (remove special characters)

### Message Content
- Sanitize message content to prevent injection
- Implement character limits
- Filter inappropriate content

## Performance Optimization

### Rate Limiting
- Respect SMS Portal rate limits (100 messages/minute by default)
- Implement internal rate limiting
- Use bulk sending for high-volume operations

### Caching
- Cache SMS Portal configuration
- Cache frequently used templates
- Implement delivery status caching

### Database Optimization
- Index frequently queried fields
- Archive old SMS messages
- Optimize queries for analytics

## Testing

### Unit Tests
```bash
# Run SMS integration tests
cd notifications_service/
python manage.py test sms_portal

cd authentication_service/
python manage.py test otp
```

### Manual Testing
```bash
# Test SMS sending
python manage.py test_sms_sending --phone "+1234567890" --template otp_verification

# Test with dry run
python manage.py test_sms_sending --phone "+1234567890" --dry-run
```

## Troubleshooting

### Common Issues

1. **SMS Not Sending**
   - Check API credentials
   - Verify SMS Portal account balance
   - Check phone number format
   - Review error logs

2. **High Failure Rate**
   - Validate phone numbers
   - Check message content length
   - Verify sender ID configuration
   - Review SMS Portal status

3. **Slow Performance**
   - Check rate limiting configuration
   - Optimize database queries
   - Review bulk sending implementation

### Debugging

Enable verbose logging:

```python
LOGGING = {
    'loggers': {
        'sms_portal': {
            'level': 'DEBUG',
            'handlers': ['console', 'file'],
            'propagate': True,
        },
        'otp': {
            'level': 'DEBUG',
            'handlers': ['console', 'file'],
            'propagate': True,
        },
    }
}
```

## Migration from Email-only

### Gradual Rollout
1. Start with OTP SMS for new users
2. Add SMS as optional channel for existing users
3. Implement user preferences for channel selection
4. Monitor delivery rates and user feedback

### Backward Compatibility
- All existing email functionality remains unchanged
- SMS is additive, not replacement
- Users can opt-in to SMS notifications

## Cost Management

### Cost Monitoring
- Track SMS costs per message type
- Set up alerts for high usage
- Implement budget controls

### Optimization Strategies
- Use templates to reduce message length
- Implement smart routing (cheaper providers for bulk)
- Cache delivery status to reduce API calls
- Batch messages where possible

## Support and Maintenance

### Regular Tasks
- Monitor SMS delivery rates
- Update templates as needed
- Review and archive old messages
- Update SMS Portal credentials
- Monitor account balance

### Health Checks
- Implement SMS service health endpoints
- Monitor API response times
- Track error rates and patterns
- Set up alerting for service issues

This completes the SMS Portal integration for BIDR Backend. The system provides robust, scalable SMS messaging with comprehensive tracking, analytics, and multi-channel support.