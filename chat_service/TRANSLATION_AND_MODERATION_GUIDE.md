# BIDR Chat Service: Translation & Content Moderation Guide

## Table of Contents
1. [Translation System](#translation-system)
2. [Content Moderation](#content-moderation)
3. [Privacy Protection](#privacy-protection)
4. [Implementation Guidelines](#implementation-guidelines)
5. [API Integration](#api-integration)
6. [Configuration](#configuration)

---

## Translation System

### Overview
The BIDR Chat Service includes a comprehensive multilingual translation system that supports real-time message translation, cached translations for performance, and multiple translation service providers.

### Key Features

#### 1. **Multi-Provider Translation Support**
```python
TRANSLATION_PROVIDERS = {
    'google': {
        'api_key': 'GOOGLE_TRANSLATE_API_KEY',
        'endpoint': 'https://translation.googleapis.com/language/translate/v2',
        'max_chars': 5000,
        'languages': ['en', 'es', 'fr', 'de', 'it', 'pt', 'ru', 'zh', 'ja', 'ar']
    },
    'azure': {
        'api_key': 'AZURE_TRANSLATOR_KEY',
        'endpoint': 'https://api.cognitive.microsofttranslator.com',
        'region': 'global',
        'max_chars': 10000,
    },
    'aws': {
        'access_key': 'AWS_ACCESS_KEY',
        'secret_key': 'AWS_SECRET_KEY',
        'region': 'us-east-1',
        'max_chars': 5000,
    }
}
```

#### 2. **Translation Caching System**
- **Performance**: Cache frequently translated content
- **Cost Optimization**: Reduce API calls by storing translations
- **Confidence Scoring**: Track translation quality metrics
- **Usage Analytics**: Monitor translation patterns

#### 3. **User Language Preferences**
```python
# User settings for translation
{
    "primary_language": "en",
    "secondary_languages": ["es", "fr"],
    "auto_translate_enabled": true,
    "translate_from_languages": ["*"],  # All languages
    "show_original_text": true,
    "translation_confidence_threshold": 0.85
}
```

### Implementation Strategy

#### 1. **Real-time Translation Workflow**
```python
class TranslationService:
    def translate_message(self, message, target_language, user_preferences):
        # 1. Check cache first
        cached = TranslationCache.objects.filter(
            source_text=message.content,
            source_language=message.detected_language,
            target_language=target_language
        ).first()
        
        if cached:
            cached.usage_count += 1
            cached.save()
            return cached.translated_text
        
        # 2. Detect source language if not provided
        if not message.detected_language:
            message.detected_language = self.detect_language(message.content)
        
        # 3. Call translation API
        translation = self.call_translation_api(
            text=message.content,
            source=message.detected_language,
            target=target_language
        )
        
        # 4. Cache the result
        TranslationCache.objects.create(
            source_text=message.content,
            source_language=message.detected_language,
            target_language=target_language,
            translated_text=translation['text'],
            confidence_score=translation['confidence'],
            translation_service=self.current_provider
        )
        
        return translation['text']
```

#### 2. **Language Detection**
- Use automatic language detection for incoming messages
- Support manual language specification
- Handle mixed-language messages
- Detect right-to-left languages (Arabic, Hebrew)

---

## Content Moderation

### Overview
Comprehensive content moderation system that protects users from harmful content while maintaining conversation flow and user experience.

### Moderation Categories

#### 1. **Profanity & Offensive Content**
```python
PROFANITY_RULES = {
    'levels': {
        'mild': {
            'action': 'mask',
            'replacement': '***',
            'notify_user': False
        },
        'moderate': {
            'action': 'flag',
            'replacement': '[CONTENT FILTERED]',
            'notify_user': True,
            'notify_moderator': True
        },
        'severe': {
            'action': 'block',
            'notify_user': True,
            'notify_moderator': True,
            'auto_warn': True
        }
    }
}
```

#### 2. **Personal Information Detection**
```python
PERSONAL_INFO_PATTERNS = {
    'phone_numbers': {
        'patterns': [
            r'\b\d{3}[-.]?\d{3}[-.]?\d{4}\b',  # US format
            r'\+\d{1,3}[-.]?\d{3,14}\b',       # International
        ],
        'action': 'mask',
        'replacement': '[PHONE REDACTED]'
    },
    'email_addresses': {
        'patterns': [
            r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b'
        ],
        'action': 'mask',
        'replacement': '[EMAIL REDACTED]'
    },
    'credit_cards': {
        'patterns': [
            r'\b4[0-9]{12}(?:[0-9]{3})?\b',    # Visa
            r'\b5[1-5][0-9]{14}\b',           # MasterCard
            r'\b3[47][0-9]{13}\b',            # American Express
        ],
        'action': 'block',
        'replacement': '[FINANCIAL INFO BLOCKED]'
    },
    'social_security': {
        'patterns': [
            r'\b\d{3}-\d{2}-\d{4}\b',         # SSN format
            r'\b\d{9}\b'                      # 9 consecutive digits
        ],
        'action': 'block',
        'alert_admin': True
    }
}
```

#### 3. **Spam & Scam Detection**
```python
SPAM_INDICATORS = {
    'repeated_messages': {
        'threshold': 3,  # Same message 3+ times
        'timeframe': 300,  # Within 5 minutes
        'action': 'rate_limit'
    },
    'excessive_caps': {
        'threshold': 0.7,  # 70% caps
        'min_length': 20,
        'action': 'flag'
    },
    'suspicious_links': {
        'whitelist_domains': ['bidr.com', 'trusted-domain.com'],
        'check_url_shorteners': True,
        'action': 'quarantine'
    },
    'financial_scams': {
        'keywords': ['urgent payment', 'wire transfer', 'bank details'],
        'action': 'escalate'
    }
}
```

### Moderation Workflow

#### 1. **Automatic Moderation Pipeline**
```python
class MessageModerationPipeline:
    def moderate_message(self, message):
        moderation_result = {
            'allowed': True,
            'actions': [],
            'confidence': 1.0,
            'flags': []
        }
        
        # 1. Profanity Check
        profanity_result = self.check_profanity(message.content)
        if profanity_result['found']:
            moderation_result['actions'].append({
                'type': 'profanity',
                'severity': profanity_result['severity'],
                'action': profanity_result['action']
            })
        
        # 2. Personal Info Check
        pii_result = self.check_personal_info(message.content)
        if pii_result['found']:
            moderation_result['actions'].append({
                'type': 'personal_info',
                'info_types': pii_result['types'],
                'masked_content': pii_result['masked_content']
            })
        
        # 3. Spam Detection
        spam_result = self.check_spam(message)
        if spam_result['is_spam']:
            moderation_result['actions'].append({
                'type': 'spam',
                'reason': spam_result['reason'],
                'action': 'rate_limit'
            })
        
        # 4. Apply Actions
        for action in moderation_result['actions']:
            self.apply_moderation_action(message, action)
        
        return moderation_result
```

#### 2. **Human Moderation Queue**
- Automatic escalation for high-risk content
- Review queue for moderators
- Appeal process for users
- Context-aware moderation decisions

---

## Privacy Protection

### Personal Information Masking

#### 1. **Real-time PII Detection**
```python
class PIIProtectionService:
    def scan_and_protect(self, content, user_settings):
        protected_content = content
        detections = []
        
        for pii_type, config in PERSONAL_INFO_PATTERNS.items():
            for pattern in config['patterns']:
                matches = re.finditer(pattern, protected_content, re.IGNORECASE)
                for match in matches:
                    # Log detection
                    detections.append({
                        'type': pii_type,
                        'original': match.group(),
                        'position': (match.start(), match.end())
                    })
                    
                    # Apply protection
                    if config['action'] == 'mask':
                        protected_content = protected_content.replace(
                            match.group(), 
                            config['replacement']
                        )
                    elif config['action'] == 'block':
                        return None, detections  # Block entire message
        
        return protected_content, detections
```

#### 2. **Context-Aware Protection**
- Business context detection (legitimate sharing)
- User consent mechanisms
- Granular privacy controls
- Audit logging for compliance

### Data Protection Features

#### 1. **Message Encryption**
```python
class MessageEncryption:
    def encrypt_message(self, content, conversation_key):
        # Use AES-256 encryption for message content
        encrypted_content = self.aes_encrypt(content, conversation_key)
        return {
            'encrypted_content': encrypted_content,
            'encryption_key_id': conversation_key.id,
            'encryption_method': 'AES-256-GCM'
        }
    
    def decrypt_message(self, encrypted_content, key_id):
        key = self.get_conversation_key(key_id)
        return self.aes_decrypt(encrypted_content, key)
```

#### 2. **Right to be Forgotten**
- Complete message deletion
- Cascade deletion of related data
- Anonymization of user references
- Compliance with GDPR/CCPA

---

## Implementation Guidelines

### 1. **Service Architecture**

```python
# services/moderation_service.py
class ModerationService:
    def __init__(self):
        self.profanity_filter = ProfanityFilter()
        self.pii_detector = PIIDetector()
        self.spam_detector = SpamDetector()
        self.translation_service = TranslationService()
    
    async def process_message(self, message_data, user_context):
        # Parallel processing for performance
        tasks = [
            self.moderate_content(message_data['content']),
            self.detect_language(message_data['content']),
            self.check_user_permissions(user_context),
        ]
        
        moderation_result, language, permissions = await asyncio.gather(*tasks)
        
        # Apply results
        processed_message = self.apply_moderation_results(
            message_data, moderation_result, language, permissions
        )
        
        return processed_message
```

### 2. **Configuration Management**

```python
# Configuration in settings.py
CHAT_MODERATION_CONFIG = {
    'enabled': True,
    'auto_moderation_threshold': 0.8,
    'human_review_threshold': 0.6,
    'languages_supported': ['en', 'es', 'fr', 'de', 'it', 'pt'],
    'pii_protection_enabled': True,
    'translation_cache_ttl': 86400,  # 24 hours
    'moderation_queue_auto_escalation': 3600,  # 1 hour
}

TRANSLATION_CONFIG = {
    'default_provider': 'google',
    'fallback_providers': ['azure', 'aws'],
    'cache_enabled': True,
    'batch_translation': True,
    'max_translation_length': 5000,
    'supported_languages': {
        'en': 'English',
        'es': 'Spanish',
        'fr': 'French',
        'de': 'German',
        'it': 'Italian',
        'pt': 'Portuguese',
        'ru': 'Russian',
        'zh': 'Chinese',
        'ja': 'Japanese',
        'ar': 'Arabic',
    }
}
```

### 3. **Database Optimization**

```sql
-- Indexes for efficient moderation queries
CREATE INDEX idx_messages_flagged ON chat_messaging_message (is_flagged, created_at);
CREATE INDEX idx_messages_moderation ON chat_messaging_message (is_auto_moderated, moderation_action);
CREATE INDEX idx_translation_cache ON chat_core_translationcache (source_language, target_language, source_text);
CREATE INDEX idx_audit_logs_severity ON chat_core_auditlog (severity, created_at);
```

---

## API Integration

### 1. **Translation APIs**

#### Google Cloud Translation
```python
from google.cloud import translate_v2 as translate

class GoogleTranslationProvider:
    def __init__(self, api_key):
        self.client = translate.Client(api_key=api_key)
    
    def translate(self, text, target_language, source_language=None):
        result = self.client.translate(
            text,
            target_language=target_language,
            source_language=source_language
        )
        
        return {
            'translated_text': result['translatedText'],
            'detected_source_language': result.get('detectedSourceLanguage'),
            'confidence': 1.0  # Google doesn't provide confidence scores
        }
```

#### Azure Translator
```python
import requests

class AzureTranslationProvider:
    def __init__(self, subscription_key, region):
        self.subscription_key = subscription_key
        self.region = region
        self.endpoint = 'https://api.cognitive.microsofttranslator.com'
    
    def translate(self, text, target_language, source_language=None):
        path = '/translate'
        params = {
            'api-version': '3.0',
            'to': target_language
        }
        if source_language:
            params['from'] = source_language
        
        headers = {
            'Ocp-Apim-Subscription-Key': self.subscription_key,
            'Ocp-Apim-Subscription-Region': self.region,
            'Content-type': 'application/json'
        }
        
        body = [{'text': text}]
        
        response = requests.post(
            self.endpoint + path,
            params=params,
            headers=headers,
            json=body
        )
        
        result = response.json()[0]
        return {
            'translated_text': result['translations'][0]['text'],
            'detected_source_language': result.get('detectedLanguage', {}).get('language'),
            'confidence': result.get('detectedLanguage', {}).get('score', 1.0)
        }
```

### 2. **Content Moderation APIs**

#### OpenAI Moderation
```python
import openai

class OpenAIModerationProvider:
    def __init__(self, api_key):
        openai.api_key = api_key
    
    def moderate_content(self, text):
        response = openai.Moderation.create(input=text)
        result = response['results'][0]
        
        return {
            'flagged': result['flagged'],
            'categories': {k: v for k, v in result['categories'].items() if v},
            'category_scores': result['category_scores']
        }
```

---

## Configuration

### Environment Variables
```bash
# Translation Services
GOOGLE_TRANSLATE_API_KEY=your_google_api_key
AZURE_TRANSLATOR_KEY=your_azure_key
AZURE_TRANSLATOR_REGION=your_azure_region
AWS_ACCESS_KEY_ID=your_aws_access_key
AWS_SECRET_ACCESS_KEY=your_aws_secret_key

# Content Moderation
OPENAI_API_KEY=your_openai_key
PERSPECTIVE_API_KEY=your_perspective_key

# Feature Flags
ENABLE_AUTO_TRANSLATION=true
ENABLE_CONTENT_MODERATION=true
ENABLE_PII_PROTECTION=true
ENABLE_SPAM_DETECTION=true

# Performance Settings
TRANSLATION_CACHE_SIZE=10000
MODERATION_QUEUE_SIZE=1000
MAX_MESSAGE_LENGTH=5000
```

### System Configuration
```python
# Initial system configurations to be created
INITIAL_SYSTEM_CONFIG = [
    # Translation settings
    {
        'category': 'translation',
        'key': 'default_provider',
        'value': 'google',
        'description': 'Default translation service provider'
    },
    {
        'category': 'translation',
        'key': 'supported_languages',
        'value': json.dumps(['en', 'es', 'fr', 'de', 'it', 'pt', 'ru', 'zh', 'ja', 'ar']),
        'description': 'List of supported translation languages'
    },
    
    # Moderation settings
    {
        'category': 'moderation',
        'key': 'auto_moderation_enabled',
        'value': 'true',
        'description': 'Enable automatic content moderation'
    },
    {
        'category': 'moderation',
        'key': 'profanity_filter_level',
        'value': 'moderate',
        'description': 'Profanity filter sensitivity level'
    },
    
    # Privacy settings
    {
        'category': 'privacy',
        'key': 'pii_protection_enabled',
        'value': 'true',
        'description': 'Enable personal information protection'
    },
    {
        'category': 'privacy',
        'key': 'auto_mask_pii',
        'value': 'true',
        'description': 'Automatically mask detected personal information'
    },
    
    # Performance limits
    {
        'category': 'limits',
        'key': 'max_message_length',
        'value': '5000',
        'description': 'Maximum message length in characters'
    },
    {
        'category': 'limits',
        'key': 'translation_cache_ttl',
        'value': '86400',
        'description': 'Translation cache time to live in seconds'
    }
]
```

---

## Best Practices

### 1. **Performance Optimization**
- Use caching extensively for translations
- Implement batch processing for bulk operations
- Use database indexes for frequent queries
- Consider Redis for real-time data

### 2. **User Experience**
- Provide clear feedback on moderation actions
- Allow users to report false positives
- Implement appeal processes
- Maintain conversation context

### 3. **Compliance & Privacy**
- Regular audit logs review
- Data retention policies
- User consent management
- Cross-border data transfer compliance

### 4. **Monitoring & Analytics**
- Track moderation accuracy
- Monitor translation quality
- User satisfaction metrics
- System performance monitoring

---

This comprehensive system provides robust translation and moderation capabilities while maintaining performance, user privacy, and regulatory compliance.
