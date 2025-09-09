"""
Simplified Django settings for BIDR Chat Service - Development Version
"""

import os
from pathlib import Path
from datetime import timedelta

BASE_DIR = Path(__file__).resolve().parent.parent

SECRET_KEY = 'django-insecure-chat-service-development-key-change-in-production'
DEBUG = True
ALLOWED_HOSTS = ['localhost', '127.0.0.1', '*']

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
    'corsheaders',
    'django_filters',
    'drf_yasg',
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

LANGUAGE_CODE = 'en-us'
TIME_ZONE = 'UTC'
USE_I18N = True
USE_TZ = True

STATIC_URL = 'static/'
STATIC_ROOT = BASE_DIR / 'staticfiles'
STATICFILES_DIRS = [BASE_DIR / 'static']

MEDIA_URL = '/media/'
MEDIA_ROOT = BASE_DIR / 'media'

DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'

# REST Framework Configuration
REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': [
        'rest_framework.authentication.SessionAuthentication',
    ],
    'DEFAULT_PERMISSION_CLASSES': [
        'rest_framework.permissions.AllowAny',
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
}

# CORS Configuration
CORS_ALLOW_ALL_ORIGINS = DEBUG
CORS_ALLOW_CREDENTIALS = True

# Swagger/OpenAPI Configuration
SWAGGER_SETTINGS = {
    'USE_SESSION_AUTH': False,
    'JSON_EDITOR': True,
    'OPERATIONS_SORTER': 'alpha',
    'TAGS_SORTER': 'alpha',
    'DOC_EXPANSION': 'none',
    'DEEP_LINKING': True,
}

# Chat Service Specific Settings
CHAT_SETTINGS = {
    'MAX_MESSAGE_LENGTH': 5000,
    'MAX_FILE_SIZE': 10 * 1024 * 1024,  # 10MB
    'ALLOWED_FILE_TYPES': [
        'image/jpeg', 'image/png', 'image/gif', 'image/webp',
        'application/pdf', 'text/plain'
    ],
    'MAX_FILES_PER_MESSAGE': 5,
    'MESSAGES_PER_MINUTE': 30,
    'ENABLE_TYPING_INDICATORS': True,
    'ENABLE_READ_RECEIPTS': True,
    'ENABLE_FILE_SHARING': True,
}

# Content Moderation Settings
MODERATION_SETTINGS = {
    'ENABLE_PROFANITY_FILTER': True,
    'ENABLE_SPAM_DETECTION': True,
    'ENABLE_PERSONAL_INFO_DETECTION': True,
    'MAX_WARNINGS_BEFORE_BAN': 3,
    'TEMPORARY_BAN_DURATION_HOURS': 24,
}

# Privacy Protection Settings
PRIVACY_SETTINGS = {
    'MASK_PHONE_NUMBERS': True,
    'MASK_EMAIL_ADDRESSES': True,
    'MASK_PHYSICAL_ADDRESSES': True,
    'MASK_PERSONAL_NAMES': True,
    'LOG_PRIVACY_VIOLATIONS': True,
}

# Bidding System Settings
BIDDING_SETTINGS = {
    'ENABLE_AUTOMATIC_BIDDING': True,
    'MIN_BID_DECREASE_PERCENTAGE': 5.0,
    'MAX_BID_DECREASE_PERCENTAGE': 50.0,
    'BIDDING_WINDOW_HOURS': 72,
    'ENABLE_BID_NOTIFICATIONS': True,
}

# External Services
EXTERNAL_SERVICES = {
    'PRODUCT_SERVICE_BASE_URL': 'http://localhost:8000/api/v1',
}
