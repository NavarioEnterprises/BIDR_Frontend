# BIDR Resolution Service

## Overview

The BIDR Resolution Service is a comprehensive post-transaction management system designed to handle reviews, returns, disputes, and notifications for the BIDR marketplace platform. This service manages all activities that occur after a transaction is completed, ensuring smooth resolution processes and customer satisfaction.

## Features

### 🌟 Core Features
- **Review Management**: Complete review and rating system with photos, responses, and moderation
- **Return Processing**: Full return workflow from initiation to completion
- **Dispute Resolution**: Comprehensive dispute handling with mediation and escalation
- **Notification System**: Multi-channel notification delivery with templates and preferences
- **Activity Logging**: Detailed logging of all system activities and security events
- **Health Monitoring**: Service health checks and performance monitoring

### 📝 Review System
- User reviews and ratings (1-5 stars)
- Review photos and documentation
- Review responses from sellers
- Helpfulness voting system
- Review flagging and moderation
- Review summaries and statistics

### 🔄 Return Processing
- Return request initiation with photo documentation
- Return approval/rejection workflow
- Shipping management and tracking
- Seller evaluation of returned items
- Automated refund processing
- Return policy management

### ⚖️ Dispute Resolution
- Multi-type dispute handling
- Evidence submission system
- Resolution offer management
- Escalation to admin review
- Mediation session scheduling
- Dispute statistics and analytics

### 🔔 Notification System
- Template-based notifications
- Multi-channel delivery (Email, SMS, Push, In-App)
- User preference management
- Batch notification processing
- Delivery tracking and analytics
- Queue management with retry logic

### 📊 Comprehensive Logging
- Activity logs for all user actions
- System logs for debugging
- API request logging
- Security event tracking
- Performance monitoring
- Error tracking and resolution

## Architecture

### Apps Structure

```
resolution_service/
├── core/                    # Core models and utilities
├── reviews/                 # Review management
├── returns/                 # Return processing
├── disputes/               # Dispute resolution
├── notifications/          # Notification system
├── logs/                   # Logging and monitoring
└── resolution_service/     # Main project settings
```

### Key Models

#### Core Models
- `UserProfile`: Extended user information
- `TransactionReference`: Reference to external transactions
- `SystemConfiguration`: System settings
- `ServiceHealth`: Health monitoring
- `APIKey`: API access management

#### Review Models
- `Review`: Main review entity with ratings
- `ReviewPhoto`: Photo attachments
- `ReviewResponse`: Seller responses
- `ReviewHelpfulness`: Voting system
- `ReviewFlag`: Content moderation
- `ReviewSummary`: User statistics

#### Return Models
- `ReturnRequest`: Return initiation
- `ReturnPhoto`: Documentation photos
- `ReturnShipping`: Shipping information
- `ReturnEvaluation`: Seller assessment
- `ReturnPolicy`: Return policies

#### Dispute Models
- `Dispute`: Main dispute entity
- `DisputeMessage`: Communication thread
- `DisputeEvidence`: File attachments
- `DisputeResolutionOffer`: Settlement offers
- `MediationSession`: Formal mediation

#### Notification Models
- `NotificationTemplate`: Message templates
- `Notification`: Individual notifications
- `NotificationPreference`: User settings
- `NotificationBatch`: Bulk sending
- `NotificationQueue`: Processing queue

## API Endpoints

### Core Endpoints
```
GET  /api/v1/core/health/                    # Health check
GET  /api/v1/core/service-info/              # Service information
GET  /api/v1/core/stats/                     # Service statistics
```

### Review Endpoints
```
GET  /api/v1/reviews/reviews/                # List reviews
POST /api/v1/reviews/reviews/                # Create review
GET  /api/v1/reviews/reviews/{id}/           # Get review
POST /api/v1/reviews/reviews/{id}/mark-helpful/  # Mark helpful
POST /api/v1/reviews/reviews/{id}/flag/      # Flag review
```

### Return Endpoints
```
GET  /api/v1/returns/return-requests/        # List returns
POST /api/v1/returns/return-requests/        # Create return
POST /api/v1/returns/return-requests/{id}/approve/  # Approve return
POST /api/v1/returns/return-requests/{id}/evaluate/ # Evaluate return
```

### Dispute Endpoints
```
GET  /api/v1/disputes/disputes/              # List disputes
POST /api/v1/disputes/disputes/              # Create dispute
POST /api/v1/disputes/disputes/{id}/escalate/   # Escalate dispute
POST /api/v1/disputes/disputes/{id}/resolve/    # Resolve dispute
```

### Notification Endpoints
```
POST /api/v1/notifications/send/             # Send notification
POST /api/v1/notifications/send-bulk/        # Send bulk notifications
GET  /api/v1/notifications/user/{id}/notifications/  # User notifications
```

### Log Endpoints
```
GET  /api/v1/logs/activity-logs/             # Activity logs
GET  /api/v1/logs/security-logs/             # Security logs
GET  /api/v1/logs/performance-logs/          # Performance metrics
```

## Installation & Setup

### Prerequisites
- Python 3.8+
- Django 5.0+
- PostgreSQL/SQLite
- Redis (for caching and queues)

### Installation Steps

1. **Clone and Setup**
   ```bash
   cd resolution_service
   pip install -r requirements.txt
   ```

2. **Environment Variables**
   ```bash
   export DJANGO_SECRET_KEY="your-secret-key"
   export DEBUG=True
   export ALLOWED_HOSTS="localhost,127.0.0.1"
   ```

3. **Database Setup**
   ```bash
   python manage.py makemigrations
   python manage.py migrate
   ```

4. **Create Superuser**
   ```bash
   python manage.py createsuperuser
   ```

5. **Start Server**
   ```bash
   python manage.py runserver 8003
   ```

### Required Dependencies
```
Django>=5.0.0
djangorestframework>=3.14.0
django-cors-headers>=4.0.0
django-filter>=23.0
Pillow>=10.0.0
```

## Configuration

### Resolution Service Settings

```python
# Review Settings
REVIEW_SETTINGS = {
    'MAX_RATING': 5,
    'MIN_RATING': 1,
    'ENABLE_REVIEW_PHOTOS': True,
    'MAX_PHOTOS_PER_REVIEW': 5,
    'REVIEW_COOLDOWN_HOURS': 24,
}

# Return Settings
RETURN_SETTINGS = {
    'DEFAULT_RETURN_PERIOD_DAYS': 30,
    'MAX_RETURN_PERIOD_DAYS': 90,
    'REQUIRE_RETURN_REASON': True,
    'REQUIRE_RETURN_PHOTOS': True,
    'MAX_RETURN_PHOTOS': 10,
}

# Dispute Settings
DISPUTE_SETTINGS = {
    'AUTO_ESCALATE_HOURS': 72,
    'MAX_DISPUTE_PHOTOS': 15,
    'ADMIN_REVIEW_TIMEOUT_HOURS': 168,
}

# Notification Settings
NOTIFICATION_SETTINGS = {
    'ENABLE_EMAIL_NOTIFICATIONS': True,
    'ENABLE_SMS_NOTIFICATIONS': False,
    'ENABLE_PUSH_NOTIFICATIONS': True,
    'BATCH_NOTIFICATIONS': True,
    'MAX_RETRIES': 3,
}
```

## Workflow Examples

### Review Process
1. Transaction completed
2. Both parties invited to leave reviews
3. Reviews submitted with ratings and photos
4. Reviews published and made visible
5. Other users can vote on helpfulness
6. Inappropriate reviews can be flagged
7. Review statistics updated

### Return Process
1. Buyer initiates return within deadline
2. Return request with photos and reason
3. Seller reviews and approves/rejects
4. If approved, return shipping arranged
5. Buyer ships item back to seller
6. Seller evaluates returned item condition
7. Refund processed based on evaluation
8. Return completed and recorded

### Dispute Resolution
1. Party files dispute with evidence
2. Respondent notified and can respond
3. Both parties can submit additional evidence
4. Resolution offers can be made and negotiated
5. If unresolved, escalated to admin
6. Admin mediates or makes final decision
7. Resolution implemented and dispute closed

### Notification Flow
1. Event triggers notification requirement
2. Template selected based on event type
3. User preferences checked for delivery channels
4. Notification queued for processing
5. Delivered via appropriate channels
6. Delivery status tracked and logged
7. Failed deliveries retried automatically

## Security Features

- **Authentication**: Session and token-based authentication
- **Authorization**: Role-based access control
- **Data Protection**: Sensitive data encryption
- **Activity Logging**: Comprehensive audit trail
- **Rate Limiting**: API rate limiting protection
- **Input Validation**: Strict input sanitization
- **File Upload Security**: Safe file handling

## Monitoring & Observability

### Health Checks
- Service availability monitoring
- Database connectivity checks
- External service dependencies
- Performance metrics tracking

### Logging Levels
- **DEBUG**: Development debugging information
- **INFO**: General operational information
- **WARNING**: Warning conditions
- **ERROR**: Error conditions requiring attention
- **CRITICAL**: Critical conditions requiring immediate action

### Metrics Tracked
- Response times
- Request volumes
- Error rates
- Queue depths
- Processing times
- Success rates

## Integration with Other Services

### Payment Service Integration
- Transaction status synchronization
- Refund processing coordination
- Payment dispute handling

### User Service Integration
- User profile synchronization
- Authentication token validation
- User preference management

### Product Service Integration
- Product information retrieval
- Return eligibility validation
- Product-specific policies

## Development Guidelines

### Code Standards
- Follow PEP 8 style guidelines
- Use type hints where appropriate
- Comprehensive docstrings
- Unit test coverage > 80%

### Database Guidelines
- Use migrations for schema changes
- Index frequently queried fields
- Use appropriate field types
- Implement soft deletes where needed

### API Guidelines
- RESTful endpoint design
- Consistent response formats
- Proper HTTP status codes
- Comprehensive error messages

## Testing

### Running Tests
```bash
python manage.py test
```

### Test Coverage
```bash
coverage run --source='.' manage.py test
coverage report
coverage html
```

### Test Categories
- Unit tests for models and utilities
- Integration tests for API endpoints
- Performance tests for critical paths
- Security tests for vulnerabilities

## Deployment

### Production Checklist
- [ ] Set DEBUG=False
- [ ] Configure production database
- [ ] Set up static file serving
- [ ] Configure logging
- [ ] Set up monitoring
- [ ] Configure backup strategy
- [ ] Set up SSL/TLS
- [ ] Configure rate limiting

### Environment Variables
```bash
DJANGO_SECRET_KEY=production-secret-key
DEBUG=False
ALLOWED_HOSTS=yourdomain.com
DATABASE_URL=postgresql://user:pass@host:port/db
REDIS_URL=redis://localhost:6379/0
```

## Performance Considerations

### Database Optimization
- Proper indexing strategy
- Query optimization
- Connection pooling
- Read replicas for scaling

### Caching Strategy
- Redis for session storage
- Cache frequently accessed data
- Cache invalidation policies

### Queue Management
- Background task processing
- Batch processing for notifications
- Queue monitoring and alerting

## Support & Maintenance

### Common Issues
- Database connection problems
- File upload issues
- Notification delivery failures
- Performance degradation

### Monitoring Alerts
- High error rates
- Slow response times
- Queue backlog
- Disk space issues

### Maintenance Tasks
- Regular database cleanup
- Log file rotation
- Performance monitoring
- Security updates

## API Documentation

Detailed API documentation is available at:
- Swagger UI: `http://localhost:8003/swagger/`
- ReDoc: `http://localhost:8003/redoc/`

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Update documentation
6. Submit a pull request

## License

This project is proprietary software developed for BIDR marketplace.

## Contact

For technical support or questions:
- Email: tech-support@bidr.com
- Slack: #resolution-service
- Documentation: https://docs.bidr.com/resolution-service

---

**Version**: 1.0.0  
**Last Updated**: August 2025  
**Service Status**: ✅ Active
