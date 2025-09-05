# BIDR Chat Service - Comprehensive Overview

## 🚀 Project Description

The **BIDR Chat Service** is a sophisticated, standalone microservice designed to handle real-time messaging, negotiation, and bidding between buyers and sellers on the BIDR marketplace platform. It provides secure, moderated communication with privacy protection and dispute resolution capabilities.

---

## 🎯 Key Features

### 🔥 Core Functionality
- **Real-time Messaging**: WebSocket-based instant messaging with delivery confirmations
- **Multi-Seller Bidding**: Competitive bidding system where sellers can bid lower than competitors
- **Privacy Protection**: Automatic masking of personal information (phone numbers, emails, addresses)
- **Content Moderation**: AI-powered profanity filtering and spam detection
- **File Sharing**: Secure file upload with virus scanning and thumbnails
- **Dispute Resolution**: Built-in escalation and moderation system

### 🛡️ Security & Privacy
- **Identity Masking**: Sellers and buyers remain anonymous until mutual agreement
- **Personal Information Protection**: Automatic detection and masking of sensitive data
- **Encrypted Communications**: End-to-end encryption for sensitive conversations
- **Moderation System**: Multi-level content moderation with automatic actions
- **Audit Logging**: Comprehensive logging for dispute resolution

### 📱 Advanced Features
- **Typing Indicators**: Real-time typing status
- **Read Receipts**: Message delivery and read confirmations  
- **Rich Media Support**: Images, PDFs, documents with preview
- **Message Translation**: Multi-language support
- **Mobile Responsive**: Optimized for mobile and desktop
- **Offline Support**: Message queuing and synchronization

---

## 🏗️ Architecture Overview

### Service Structure
```
chat_service/
├── chat_core/              # Core models and utilities
├── chat_conversations/     # Conversation management
├── chat_messaging/         # Real-time messaging
├── chat_moderation/        # Content moderation
├── privacy_guard/          # Privacy protection
├── file_handler/           # File management
├── chat_notifications/     # Notification system
├── bidding_engine/         # Bidding and negotiation
├── dispute_handler/        # Dispute resolution
└── activity_logs/          # Audit and logging
```

### Key Components

#### 🗣️ **Chat Conversations** (`chat_conversations/`)
- Conversation management and participant handling
- Multi-participant support with role-based access
- Conversation templates and automation
- Integration with product requests and quotes

#### 💬 **Messaging System** (`chat_messaging/`)
- Real-time message delivery via WebSocket
- Message types: text, rich text, system messages
- Message encryption and secure storage
- Message history and search capabilities

#### ⚖️ **Content Moderation** (`chat_moderation/`)
- Automated profanity filtering
- Spam and inappropriate content detection
- User warning and banning system
- Moderator dashboard and tools

#### 🔐 **Privacy Protection** (`privacy_guard/`)
- Personal information masking (phone, email, address)
- Identity reveal system with approvals
- Data anonymization and pseudonymization
- Privacy violation logging and alerts

#### 📄 **File Management** (`file_handler/`)
- Secure file upload and storage
- Image compression and thumbnail generation
- Virus scanning and content validation
- File sharing with access controls

#### 🏷️ **Bidding Engine** (`bidding_engine/`)
- Competitive bidding system
- Automatic bid notifications
- Bid history and tracking
- Price negotiation workflows

---

## 🔌 API Endpoints

### Core Chat Endpoints
```http
POST   /api/v1/chat/conversations          # Create conversation
GET    /api/v1/chat/conversations          # List conversations  
GET    /api/v1/chat/conversations/{id}     # Get conversation details
PUT    /api/v1/chat/conversations/{id}     # Update conversation
DELETE /api/v1/chat/conversations/{id}     # Archive conversation

POST   /api/v1/chat/messages               # Send message
GET    /api/v1/chat/messages               # Get messages
PUT    /api/v1/chat/messages/{id}          # Edit message
DELETE /api/v1/chat/messages/{id}          # Delete message
```

### Bidding System
```http
POST   /api/v1/bidding/bids                # Submit new bid
GET    /api/v1/bidding/bids                # Get bid history
PUT    /api/v1/bidding/bids/{id}           # Update bid
GET    /api/v1/bidding/competitions/{id}   # Get bidding competition
```

### File Management
```http
POST   /api/v1/files/upload               # Upload file
GET    /api/v1/files/{id}                 # Download file
GET    /api/v1/files/{id}/preview         # File preview
DELETE /api/v1/files/{id}                 # Delete file
```

### Moderation & Privacy
```http
POST   /api/v1/moderation/report          # Report content
GET    /api/v1/moderation/violations      # Get violations
PUT    /api/v1/moderation/actions/{id}    # Take moderation action

POST   /api/v1/privacy/reveal-request     # Request identity reveal
PUT    /api/v1/privacy/reveal-approve     # Approve reveal request
GET    /api/v1/privacy/masked-info        # Get masked information
```

---

## 🗂️ Database Schema

### Core Models

#### **UserProfile**
```python
- user: OneToOne(User)
- role: CharField (buyer/seller/moderator/admin)
- verification_status: CharField
- display_name: CharField
- avatar: ImageField
- privacy_settings: JSONField
- moderation_status: CharField
- reputation_score: DecimalField
- statistics: JSONField
```

#### **Conversation**
```python
- title: CharField
- conversation_type: CharField
- participants: ManyToMany(User)
- product_request_id: UUIDField
- quote_id: UUIDField
- settings: JSONField
- privacy_settings: JSONField
- moderation_flags: JSONField
```

#### **Message**
```python
- conversation: ForeignKey(Conversation)
- sender: ForeignKey(User)
- content: TextField
- message_type: CharField
- attachments: ManyToMany(FileAttachment)
- moderation_status: CharField
- encryption_data: JSONField
```

#### **Bid**
```python
- conversation: ForeignKey(Conversation)
- bidder: ForeignKey(User)
- amount: DecimalField
- currency: CharField
- bid_type: CharField
- terms: JSONField
- status: CharField
```

---

## 🔧 Configuration

### Environment Variables
```bash
# Database
DB_NAME=bidr_chat_service
DB_USER=postgres
DB_PASSWORD=your_password
DB_HOST=localhost
DB_PORT=5432

# Redis (for WebSocket and caching)
REDIS_HOST=localhost
REDIS_PORT=6379

# External Services
PRODUCT_SERVICE_URL=http://localhost:8000/api/v1
PRODUCT_SERVICE_API_KEY=your_api_key

# Security
SECRET_KEY=your_secret_key
ENCRYPTION_KEY=your_encryption_key

# Content Moderation
PERSPECTIVE_API_KEY=your_perspective_api_key
ENABLE_AUTO_MODERATION=true

# File Storage
AWS_S3_BUCKET=your_s3_bucket
AWS_ACCESS_KEY_ID=your_access_key
AWS_SECRET_ACCESS_KEY=your_secret_key

# Notifications
SENDGRID_API_KEY=your_sendgrid_key
TWILIO_ACCOUNT_SID=your_twilio_sid
TWILIO_AUTH_TOKEN=your_twilio_token
```

---

## 🚀 Getting Started

### 1. Installation
```bash
# Clone the repository
cd BIDR_Backend/chat_service

# Install dependencies
pip install -r requirements.txt

# Setup database
python manage.py migrate

# Create superuser
python manage.py createsuperuser

# Run development server
python manage.py runserver 8001
```

### 2. Basic Usage

#### Create a Conversation
```python
import requests

response = requests.post('http://localhost:8001/api/v1/chat/conversations/', {
    'title': 'Gaming PC Discussion',
    'conversation_type': 'product_inquiry',
    'product_request_id': 'uuid-of-product-request',
    'participants': [buyer_id, seller_id]
})
```

#### Send a Message
```python
response = requests.post('http://localhost:8001/api/v1/chat/messages/', {
    'conversation_id': conversation_id,
    'content': 'Hi! I\'m interested in your gaming PC quote.',
    'message_type': 'text'
})
```

#### Submit a Bid
```python
response = requests.post('http://localhost:8001/api/v1/bidding/bids/', {
    'conversation_id': conversation_id,
    'amount': '29999.99',
    'currency': 'ZAR',
    'terms': {
        'delivery_time': '5-7 business days',
        'warranty': '2 years',
        'installation': 'included'
    }
})
```

---

## 🔗 Integration

### With Product Management Service
- Automatic conversation creation when quotes are submitted
- Sync product request and quote data
- Update quote status based on chat negotiations

### With User Management
- Single sign-on (SSO) integration
- User role and permission sync
- Profile data synchronization

### Real-time Updates
- WebSocket connections for instant messaging
- Push notifications for mobile apps
- Email notifications for offline users

---

## 📊 Monitoring & Analytics

### Metrics Tracked
- Message volume and response times
- Conversation conversion rates
- Bidding competition statistics
- Moderation action frequency
- User engagement metrics

### Logging
- All message activity with timestamps
- Moderation actions and violations
- File upload and access logs
- Security events and privacy breaches
- Performance and error logs

---

## 🛡️ Security Features

### Data Protection
- End-to-end encryption for sensitive conversations
- Personal information masking and anonymization
- Secure file storage with access controls
- Audit trails for compliance

### Content Safety
- Multi-level content moderation
- Automated spam and abuse detection
- User reporting and blocking system
- Moderator escalation workflows

---

## 📱 Mobile & Frontend Support

### WebSocket API
Real-time bidirectional communication for instant messaging, typing indicators, and live bidding updates.

### REST API
Comprehensive RESTful API for all chat functionality with proper authentication and rate limiting.

### File Upload
Secure file upload with progress tracking, virus scanning, and thumbnail generation.

---

## 🚦 Current Status

### ✅ Completed
- Core project structure and models
- Basic URL configuration
- Django admin setup
- Development environment configuration

### 🔄 In Progress
- API endpoint implementation
- WebSocket integration
- Content moderation system

### 📋 Planned
- Real-time bidding implementation
- Mobile app integration
- Advanced analytics dashboard
- Production deployment

---

## 🔧 Development

### Running Tests
```bash
python manage.py test
```

### Code Quality
```bash
flake8 .
black .
isort .
```

### Database Migrations
```bash
python manage.py makemigrations
python manage.py migrate
```

---

This comprehensive chat service provides a complete solution for secure, real-time communication between buyers and sellers with advanced features like competitive bidding, privacy protection, and content moderation. The modular architecture allows for easy scaling and integration with the broader BIDR marketplace platform.
