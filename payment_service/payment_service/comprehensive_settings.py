"""
Django settings for BIDR Payment Service.

A comprehensive payment processing service that handles secure transactions,
escrow management, PIN verification, and Paystack integration for the BIDR marketplace.
"""

import os
from pathlib import Path
from datetime import timedelta

# Build paths inside the project like this: BASE_DIR / 'subdir'.
BASE_DIR = Path(__file__).resolve().parent.parent

# SECURITY WARNING: keep the secret key used in production secret!
SECRET_KEY = os.getenv('SECRET_KEY', 'django-insecure-payment-service-development-key-change-in-production')

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
    'rest_framework.authtoken',
    'corsheaders',
    'django_filters',
]

LOCAL_APPS = [
    'core',
    'payments',
    'transactions',
    'escrow',
    'analytics',
    'logs',
    'notifications_service',
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

ROOT_URLCONF = 'payment_service.urls'

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

WSGI_APPLICATION = 'payment_service.wsgi.application'

# Database
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': BASE_DIR / 'payment_db.sqlite3',
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
        'rest_framework.authentication.TokenAuthentication',
        'rest_framework.authentication.SessionAuthentication',
    ],
    'DEFAULT_PERMISSION_CLASSES': [
        'rest_framework.permissions.IsAuthenticated',
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
        'payment': '500/hour',
        'transaction': '1000/hour',
    },
}

# CORS Configuration
CORS_ALLOWED_ORIGINS = [
    "http://localhost:3000",  # React app
    "http://127.0.0.1:3000",
    "http://localhost:8000",  # Chat service
    "http://127.0.0.1:8000",
    "http://localhost:8001",  # Chat service alt
    "http://127.0.0.1:8001",
    "http://localhost:8002",  # Payment service
    "http://127.0.0.1:8002",
]

CORS_ALLOW_CREDENTIALS = True

# For development only
if DEBUG:
    CORS_ALLOW_ALL_ORIGINS = True

# Paystack Configuration
PAYSTACK_PUBLIC_KEY = os.getenv('PAYSTACK_PUBLIC_KEY', 'pk_test_your_public_key_here')
PAYSTACK_SECRET_KEY = os.getenv('PAYSTACK_SECRET_KEY', 'sk_test_your_secret_key_here')
PAYSTACK_CALLBACK_URL = os.getenv('PAYSTACK_CALLBACK_URL', 'http://localhost:8002/api/v1/payments/paystack/callback/')

# SMS Configuration (for PIN delivery)
SMS_PROVIDER = os.getenv('SMS_PROVIDER', 'twilio')
SMS_API_KEY = os.getenv('SMS_API_KEY', '')
SMS_API_SECRET = os.getenv('SMS_API_SECRET', '')

# Email Configuration (for PIN delivery and notifications_service)
EMAIL_BACKEND = 'django.core.mail.backends.smtp.EmailBackend'
EMAIL_HOST = os.getenv('EMAIL_HOST', 'smtp.gmail.com')
EMAIL_PORT = int(os.getenv('EMAIL_PORT', '587'))
EMAIL_USE_TLS = os.getenv('EMAIL_USE_TLS', 'True').lower() == 'true'
EMAIL_HOST_USER = os.getenv('EMAIL_HOST_USER', '')
EMAIL_HOST_PASSWORD = os.getenv('EMAIL_HOST_PASSWORD', '')
DEFAULT_FROM_EMAIL = os.getenv('DEFAULT_FROM_EMAIL', 'noreply@bidr.com')

# Escrow Configuration
ESCROW_PERIODS = {
    'vehicle_parts': 7,     # days
    'electronics': 14,      # days
    'custom_high_value': 21, # days
    'default': 14,          # days
}

# Transaction Security
PIN_LENGTH = 6
PIN_EXPIRY_MINUTES = 30
MAX_PIN_ATTEMPTS = 3
TRANSACTION_TIMEOUT_HOURS = 24

# External Services URLs
CHAT_SERVICE_URL = os.getenv('CHAT_SERVICE_URL', 'http://localhost:8001')
USER_SERVICE_URL = os.getenv('USER_SERVICE_URL', 'http://localhost:8000')
NOTIFICATION_SERVICE_URL = os.getenv('NOTIFICATION_SERVICE_URL', 'http://localhost:8003')

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
    },
    'handlers': {
        'file': {
            'level': 'INFO',
            'class': 'logging.FileHandler',
            'filename': 'logs/payment_service.log',
            'formatter': 'verbose',
        },
        'console': {
            'level': 'INFO',
            'class': 'logging.StreamHandler',
            'formatter': 'verbose',
        },
        'transaction_file': {
            'level': 'INFO',
            'class': 'logging.FileHandler',
            'filename': 'logs/transactions.log',
            'formatter': 'verbose',
        },
    },
    'loggers': {
        'django': {
            'handlers': ['file', 'console'],
            'level': 'INFO',
            'propagate': True,
        },
        'payment_service': {
            'handlers': ['file', 'console'],
            'level': 'INFO',
            'propagate': True,
        },
        'transactions': {
            'handlers': ['transaction_file', 'console'],
            'level': 'INFO',
            'propagate': True,
        },
        'payments': {
            'handlers': ['file', 'console'],
            'level': 'INFO',
            'propagate': True,
        },
    },
}

# Security Settings
SECURE_TRANSACTION_SALT = os.getenv('SECURE_TRANSACTION_SALT', 'bidr-payment-service-salt')
ENCRYPTION_KEY = os.getenv('ENCRYPTION_KEY', 'payment-encryption-key-change-in-production')
