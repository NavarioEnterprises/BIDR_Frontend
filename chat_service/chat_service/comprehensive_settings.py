"""
Django settings for BIDR Chat Service.

A comprehensive real-time messaging and negotiation platform that enables
secure communication between buyers and sellers with content moderation,
privacy protection, and dispute resolution capabilities.
"""

import os
from pathlib import Path
from datetime import timedelta

# Build paths inside the project like this: BASE_DIR / 'subdir'.
BASE_DIR = Path(__file__).resolve().parent.parent

# SECURITY WARNING: keep the secret key used in production secret!
SECRET_KEY = os.getenv('SECRET_KEY', 'django-insecure-chat-service-development-key-change-in-production')

# SECURITY WARNING: don't run with debug turned on in production!
DEBUG = os.getenv('DEBUG', 'True').lower() == 'true'

ALLOWED_HOSTS = os.getenv('ALLOWED_HOSTS', 'localhost,127.0.0.1,0.0.0.0,*').split(',')

# Application definition
DJANGO_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
]

THIRD_PARTY_APPS = [
    'rest_framework',
    'rest_framework_simplejwt',
    'rest_framework_simplejwt.token_blacklist',
    'corsheaders',
    'django_filters',
    'drf_yasg',
    'channels',
    'channels_redis',
    'django_extensions',
]

LOCAL_APPS = [
    'core',
    'conversations',
    'messaging',
    'moderation',
    'privacy_protection',
    'file_management',
    'notifications_service',
    'bidding',
    'dispute_resolution',
    'chat_logs',
    'authentication',
]

INSTALLED_APPS = DJANGO_APPS + THIRD_PARTY_APPS + LOCAL_APPS

MIDDLEWARE = [
    'corsheaders.middleware.CorsMiddleware',
    'django.middleware.security.SecurityMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
    # Chat Service Specific Middleware
    'chat_logs.middleware.ChatLoggingMiddleware',
    'moderation.middleware.ContentModerationMiddleware',
    'privacy_protection.middleware.PrivacyFilterMiddleware',
]

ROOT_URLCONF = 'chat_service.urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [BASE_DIR / 'templates'],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.debug',
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

WSGI_APPLICATION = 'chat_service.wsgi.application'
ASGI_APPLICATION = 'chat_service.asgi.application'

# Database
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': BASE_DIR / 'db.sqlite3',
    }
}

# Password validation
AUTH_PASSWORD_VALIDATORS = [
    {
        'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator',
    },
]

# Internationalization
LANGUAGE_CODE = 'en-us'
TIME_ZONE = 'UTC'
USE_I18N = True
USE_TZ = True

# Static files (CSS, JavaScript, Images)
STATIC_URL = 'static/'
STATIC_ROOT = BASE_DIR / 'staticfiles'
STATICFILES_DIRS = [
    BASE_DIR / 'static',
]

# Media files (Uploads)
MEDIA_URL = '/media/'
MEDIA_ROOT = BASE_DIR / 'media'

# Default primary key field type
DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'

# REST Framework Configuration
REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': [
        'rest_framework_simplejwt.authentication.JWTAuthentication',
        'rest_framework.authentication.SessionAuthentication',
    ],
    'DEFAULT_PERMISSION_CLASSES': [
        'rest_framework.permissions.AllowAny',  # For testing
    ],
    'DEFAULT_PAGINATION_CLASS': 'rest_framework.pagination.PageNumberPagination',
    'PAGE_SIZE': 50,
    'DEFAULT_FILTER_BACKENDS': [
        'django_filters.rest_framework.DjangoFilterBackend',
        'rest_framework.filters.SearchFilter',
        'rest_framework.filters.OrderingFilter',
    ],
    'DEFAULT_RENDERER_CLASSES': [
        'rest_framework.renderers.JSONRenderer',
        'rest_framework.renderers.BrowsableAPIRenderer',
    ],
    'DEFAULT_THROTTLE_CLASSES': [
        'rest_framework.throttling.AnonRateThrottle',
        'rest_framework.throttling.UserRateThrottle'
    ],
    'DEFAULT_THROTTLE_RATES': {
        'anon': '100/hour',
        'user': '1000/hour',
        'chat': '500/hour',
        'file_upload': '50/hour',
    },
    'EXCEPTION_HANDLER': 'core.exceptions.custom_exception_handler',
}

# JWT Configuration
SIMPLE_JWT = {
    'ACCESS_TOKEN_LIFETIME': timedelta(hours=1),
    'REFRESH_TOKEN_LIFETIME': timedelta(days=7),
    'ROTATE_REFRESH_TOKENS': True,
    'BLACKLIST_AFTER_ROTATION': True,
    'UPDATE_LAST_LOGIN': True,
    'ALGORITHM': 'HS256',
    'SIGNING_KEY': SECRET_KEY,
    'AUTH_HEADER_TYPES': ('Bearer',),
}

# Channels Configuration for WebSocket (using memory for development)
CHANNEL_LAYERS = {
    'default': {
        'BACKEND': 'channels.layers.InMemoryChannelLayer',
    },
}

# CORS Configuration
CORS_ALLOWED_ORIGINS = [
    "http://localhost:3000",
    "http://127.0.0.1:3000",
    "http://localhost:3001",
    "http://127.0.0.1:3001",
]

CORS_ALLOW_CREDENTIALS = True
CORS_ALLOW_ALL_ORIGINS = DEBUG

# Cache Configuration
CACHES = {
    'default': {
        'BACKEND': 'django.core.cache.backends.locmem.LocMemCache',
        'LOCATION': 'chat-service-cache',
    }
}

# Logging Configuration
LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'formatters': {
        'verbose': {
            'format': '{levelname} {asctime} {module} {process:d} {thread:d} {message}',
            'style': '{',
        },
        'simple': {
            'format': '{levelname} {message}',
            'style': '{',
        },
        'chat': {
            'format': '{asctime} [{levelname}] {name} - {message}',
            'style': '{',
        },
    },
    'handlers': {
        'console': {
            'level': 'INFO',
            'class': 'logging.StreamHandler',
            'formatter': 'simple'
        },
        'file': {
            'level': 'INFO',
            'class': 'logging.FileHandler',
            'filename': BASE_DIR / 'logs' / 'chat_service.log',
            'formatter': 'verbose',
        },
        'chat_file': {
            'level': 'INFO',
            'class': 'logging.FileHandler',
            'filename': BASE_DIR / 'logs' / 'chat_activity.log',
            'formatter': 'chat',
        },
        'moderation_file': {
            'level': 'WARNING',
            'class': 'logging.FileHandler',
            'filename': BASE_DIR / 'logs' / 'moderation.log',
            'formatter': 'verbose',
        },
    },
    'root': {
        'handlers': ['console'],
        'level': 'INFO',
    },
    'loggers': {
        'django': {
            'handlers': ['console', 'file'],
            'level': 'INFO',
            'propagate': False,
        },
        'chat_service': {
            'handlers': ['console', 'file'],
            'level': 'INFO',
            'propagate': False,
        },
        'chat_activity': {
            'handlers': ['chat_file'],
            'level': 'INFO',
            'propagate': False,
        },
        'moderation': {
            'handlers': ['moderation_file'],
            'level': 'WARNING',
            'propagate': False,
        },
    },
}

# Create logs directory if it doesn't exist
os.makedirs(BASE_DIR / 'logs', exist_ok=True)

# Swagger/OpenAPI Configuration
SWAGGER_SETTINGS = {
    'SECURITY_DEFINITIONS': {
        'Bearer': {
            'type': 'apiKey',
            'name': 'Authorization',
            'in': 'header'
        }
    },
    'USE_SESSION_AUTH': False,
    'JSON_EDITOR': True,
    'SUPPORTED_SUBMIT_METHODS': [
        'get', 'post', 'put', 'delete', 'patch'
    ],
    'OPERATIONS_SORTER': 'alpha',
    'TAGS_SORTER': 'alpha',
    'DOC_EXPANSION': 'none',
    'DEEP_LINKING': True,
}

# Chat Service Specific Settings
CHAT_SETTINGS = {
    # Message Configuration
    'MAX_MESSAGE_LENGTH': 5000,
    'MAX_FILE_SIZE': 10 * 1024 * 1024,  # 10MB
    'ALLOWED_FILE_TYPES': [
        'image/jpeg', 'image/png', 'image/gif', 'image/webp',
        'application/pdf', 'text/plain', 'application/msword',
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
    ],
    'MAX_FILES_PER_MESSAGE': 5,
    
    # Rate Limiting
    'MESSAGES_PER_MINUTE': 30,
    'FILES_PER_HOUR': 20,
    'CONVERSATIONS_PER_DAY': 50,
    
    # Chat Features
    'ENABLE_TYPING_INDICATORS': True,
    'ENABLE_READ_RECEIPTS': True,
    'ENABLE_FILE_SHARING': True,
    'ENABLE_RICH_TEXT': True,
    'ENABLE_EMOJI': True,
    'ENABLE_TRANSLATIONS': True,
    
    # Auto Archive Settings
    'AUTO_ARCHIVE_AFTER_DAYS': 30,
    'DELETE_ARCHIVED_AFTER_DAYS': 365,
    
    # WebSocket Settings
    'WEBSOCKET_HEARTBEAT_INTERVAL': 30,
    'CONNECTION_TIMEOUT': 300,
}

# Content Moderation Settings
MODERATION_SETTINGS = {
    'ENABLE_PROFANITY_FILTER': True,
    'ENABLE_SPAM_DETECTION': True,
    'ENABLE_PERSONAL_INFO_DETECTION': True,
    'AUTO_MODERATE': True,
    'QUARANTINE_SUSPICIOUS_MESSAGES': True,
    'PROFANITY_SEVERITY_LEVELS': ['mild', 'moderate', 'severe'],
    'MAX_WARNINGS_BEFORE_BAN': 3,
    'TEMPORARY_BAN_DURATION_HOURS': 24,
    'MODERATOR_REVIEW_REQUIRED_THRESHOLD': 0.8,
}

# Privacy Protection Settings
PRIVACY_SETTINGS = {
    'MASK_PHONE_NUMBERS': True,
    'MASK_EMAIL_ADDRESSES': True,
    'MASK_PHYSICAL_ADDRESSES': True,
    'MASK_PERSONAL_NAMES': True,
    'ALLOW_IDENTITY_REVEAL_AFTER_AGREEMENT': True,
    'IDENTITY_REVEAL_REQUIRES_MODERATOR': False,
    'LOG_PRIVACY_VIOLATIONS': True,
}

# File Management Settings
FILE_SETTINGS = {
    'ENABLE_VIRUS_SCANNING': False,  # Disabled for development
    'ENABLE_IMAGE_COMPRESSION': True,
    'THUMBNAIL_SIZES': [(150, 150), (300, 300), (600, 600)],
    'WATERMARK_IMAGES': False,
    'STORAGE_BACKEND': 'local',
}

# External Services Integration
EXTERNAL_SERVICES = {
    # Product Management Service
    'PRODUCT_SERVICE_BASE_URL': os.getenv('PRODUCT_SERVICE_URL', 'http://localhost:8000/api'),
    'PRODUCT_SERVICE_API_KEY': os.getenv('PRODUCT_SERVICE_API_KEY', ''),
}

# Notification Settings
NOTIFICATION_SETTINGS = {
    'ENABLE_EMAIL_NOTIFICATIONS': False,  # Disabled for development
    'ENABLE_SMS_NOTIFICATIONS': False,
    'ENABLE_PUSH_NOTIFICATIONS': False,
    'ENABLE_WEBSOCKET_NOTIFICATIONS': True,
    'EMAIL_NOTIFICATION_DELAY_MINUTES': 5,
    'BATCH_NOTIFICATIONS': True,
}

# Bidding System Settings
BIDDING_SETTINGS = {
    'ENABLE_AUTOMATIC_BIDDING': True,
    'MIN_BID_DECREASE_PERCENTAGE': 5.0,
    'MAX_BID_DECREASE_PERCENTAGE': 50.0,
    'BIDDING_WINDOW_HOURS': 72,
    'ENABLE_BID_NOTIFICATIONS': True,
    'REQUIRE_DEPOSIT_FOR_BIDDING': False,
}

# Security Settings
SECURITY_SETTINGS = {
    'ENCRYPT_MESSAGES_AT_REST': False,  # Disabled for development
    'ENCRYPT_FILES_AT_REST': False,
    'ENABLE_MESSAGE_DELETION': True,
    'MESSAGE_RETENTION_DAYS': 365,
    'AUDIT_LOG_RETENTION_YEARS': 7,
    'REQUIRE_2FA_FOR_MODERATORS': False,  # Disabled for development
    'SESSION_TIMEOUT_MINUTES': 60,
}
