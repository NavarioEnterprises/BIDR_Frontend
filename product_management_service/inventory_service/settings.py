"""
Django settings for BIDR Inventory Service.

A comprehensive inventory management system that handles product requests,
quotes, transactions, and ratings for the BIDR platform.
"""

import os
from pathlib import Path
from datetime import timedelta

# Build paths inside the project like this: BASE_DIR / 'subdir'.
BASE_DIR = Path(__file__).resolve().parent.parent

# SECURITY WARNING: keep the secret key used in production secret!
SECRET_KEY = os.getenv('SECRET_KEY', 'django-insecure-inventory-service-development-key-change-in-production')

# SECURITY WARNING: don't run with debug turned on in production!
DEBUG = os.getenv('DEBUG', 'True').lower() == 'true'

ALLOWED_HOSTS = os.getenv('ALLOWED_HOSTS', 'localhost,127.0.0.01,0.0.0.0').split(',')

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
    'mptt',
]

LOCAL_APPS = [
    'core',
    'categories',
    'products',
    'product_requests',
    'quotes',
    'transactions',
    'ratings',
    'analytics',
    'product_logs',
    'app_logs',
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

ROOT_URLCONF = 'product_management_service.urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [],
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

WSGI_APPLICATION = 'product_management_service.wsgi.application'


# Database
# https://docs.djangoproject.com/en/5.0/ref/settings/#databases

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': BASE_DIR / 'db.sqlite3',
    }
}


# Password validation
# https://docs.djangoproject.com/en/5.0/ref/settings/#auth-password-validators

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
# https://docs.djangoproject.com/en/5.0/topics/i18n/

LANGUAGE_CODE = 'en-us'

TIME_ZONE = 'UTC'

USE_I18N = True

USE_TZ = True


# Static files (CSS, JavaScript, Images)
# https://docs.djangoproject.com/en/5.0/howto/static-files/

STATIC_URL = 'static/'

# Default primary key field type
# https://docs.djangoproject.com/en/5.0/ref/settings/#default-auto-field

DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'

# Media files (Uploads)
MEDIA_URL = '/media/'
MEDIA_ROOT = BASE_DIR / 'media'

# Static files in production
STATIC_ROOT = BASE_DIR / 'staticfiles'
STATICFILES_DIRS = [
    BASE_DIR / 'static',
]

# REST Framework Configuration
REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': [
        'rest_framework_simplejwt.authentication.JWTAuthentication',
        'rest_framework.authentication.SessionAuthentication',
    ],
    'DEFAULT_PERMISSION_CLASSES': [
        'rest_framework.permissions.IsAuthenticated',
    ],
    'DEFAULT_PAGINATION_CLASS': 'rest_framework.pagination.PageNumberPagination',
    'PAGE_SIZE': 20,
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
        'user': '1000/hour'
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
    'VERIFYING_KEY': None,
    'AUDIENCE': None,
    'ISSUER': None,
    'JWK_URL': None,
    'LEEWAY': 0,
    'AUTH_HEADER_TYPES': ('Bearer',),
    'AUTH_HEADER_NAME': 'HTTP_AUTHORIZATION',
    'USER_ID_FIELD': 'id',
    'USER_ID_CLAIM': 'user_id',
    'USER_AUTHENTICATION_RULE': 'rest_framework_simplejwt.authentication.default_user_authentication_rule',
    'AUTH_TOKEN_CLASSES': ('rest_framework_simplejwt.tokens.AccessToken',),
    'TOKEN_TYPE_CLAIM': 'token_type',
    'TOKEN_USER_CLASS': 'rest_framework_simplejwt.models.TokenUser',
    'JTI_CLAIM': 'jti',
    'SLIDING_TOKEN_REFRESH_EXP_CLAIM': 'refresh_exp',
    'SLIDING_TOKEN_LIFETIME': timedelta(minutes=5),
    'SLIDING_TOKEN_REFRESH_LIFETIME': timedelta(days=1),
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
        'LOCATION': 'inventory-service-cache',
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
    },
    'filters': {
        'require_debug_true': {
            '()': 'django.utils.log.RequireDebugTrue',
        },
    },
    'handlers': {
        'console': {
            'level': 'INFO',
            'filters': ['require_debug_true'],
            'class': 'logging.StreamHandler',
            'formatter': 'simple'
        },
        'file': {
            'level': 'INFO',
            'class': 'logging.FileHandler',
            'filename': BASE_DIR / 'logs' / 'product_management_service.log',
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
        'product_management_service': {
            'handlers': ['console', 'file'],
            'level': 'INFO',
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
        'get',
        'post',
        'put',
        'delete',
        'patch'
    ],
    'OPERATIONS_SORTER': 'alpha',
    'TAGS_SORTER': 'alpha',
    'DOC_EXPANSION': 'none',
    'DEEP_LINKING': True,
    'SHOW_EXTENSIONS': True,
    'DEFAULT_MODEL_RENDERING': 'model',
}

REDOC_SETTINGS = {
    'LAZY_RENDERING': False,
}

# Application specific settings
INVENTORY_SETTINGS = {
    'MAX_REQUEST_IMAGES': 10,
    'MAX_QUOTE_ITEMS': 50,
    'DEFAULT_REQUEST_EXPIRY_DAYS': 30,
    'DEFAULT_QUOTE_VALIDITY_DAYS': 7,
    'PLATFORM_FEE_PERCENTAGE': 5.0,
    'MAX_SEARCH_RADIUS_KM': 100,
    'DEFAULT_SEARCH_RADIUS_KM': 50,
    'ENABLE_GEOLOCATION': True,
    'ENABLE_NOTIFICATIONS': True,
    'AUTO_EXPIRE_REQUESTS': True,
    'AUTO_EXPIRE_QUOTES': True,
}

# Encryption Settings
ENCRYPTION_SETTINGS = {
    'ENCRYPTION_KEY': os.getenv('ENCRYPTION_KEY', 'dev-key-change-in-production-32-chars'),
    'HASH_ALGORITHM': 'pbkdf2_sha256',
    'HASH_ITERATIONS': 100000,
    'ENCRYPTED_FIELDS_CACHE_TIMEOUT': 300,  # 5 minutes
    'USE_ENCRYPTION': os.getenv('USE_ENCRYPTION', 'True').lower() == 'true',
}

# API Integration Settings
API_INTEGRATION_SETTINGS = {
    'SELLER_SERVICE_BASE_URL': os.getenv('SELLER_SERVICE_BASE_URL', 'http://localhost:8001/api'),
    'AUTHENTICATION_SERVICE_BASE_URL': os.getenv('AUTH_SERVICE_BASE_URL', 'http://localhost:8002/api'),
    'NOTIFICATION_SERVICE_BASE_URL': os.getenv('NOTIFICATION_SERVICE_BASE_URL', 'http://localhost:8003/api'),
    'API_TIMEOUT': int(os.getenv('API_TIMEOUT', '30')),
    'API_RETRY_ATTEMPTS': int(os.getenv('API_RETRY_ATTEMPTS', '3')),
    'API_RETRY_DELAY': float(os.getenv('API_RETRY_DELAY', '1.0')),
    'CACHE_TIMEOUT': int(os.getenv('API_CACHE_TIMEOUT', '300')),  # 5 minutes
    'USE_API_CACHE': os.getenv('USE_API_CACHE', 'True').lower() == 'true',
    'API_KEY': os.getenv('BIDR_API_KEY', 'dev-api-key-change-in-production'),
}

# Analytics Settings
ANALYTICS_SETTINGS = {
    'ENABLE_ANALYTICS': os.getenv('ENABLE_ANALYTICS', 'True').lower() == 'true',
    'ANALYTICS_BATCH_SIZE': int(os.getenv('ANALYTICS_BATCH_SIZE', '100')),
    'ANALYTICS_PROCESSING_INTERVAL': int(os.getenv('ANALYTICS_PROCESSING_INTERVAL', '3600')),  # 1 hour
    'RETENTION_DAYS': {
        'PRODUCT_ACCESS_LOGS': int(os.getenv('PRODUCT_ACCESS_LOG_RETENTION', '90')),
        'PRODUCT_CHANGE_LOGS': int(os.getenv('PRODUCT_CHANGE_LOG_RETENTION', '365')),
        'BULK_OPERATION_LOGS': int(os.getenv('BULK_OPERATION_LOG_RETENTION', '30')),
        'ANALYTICS_DATA': int(os.getenv('ANALYTICS_DATA_RETENTION', '730')),  # 2 years
    },
}

# Product Logging Settings
PRODUCT_LOGGING_SETTINGS = {
    'ENABLE_CHANGE_LOGGING': os.getenv('ENABLE_CHANGE_LOGGING', 'True').lower() == 'true',
    'ENABLE_ACCESS_LOGGING': os.getenv('ENABLE_ACCESS_LOGGING', 'True').lower() == 'true',
    'LOG_SENSITIVE_FIELDS': os.getenv('LOG_SENSITIVE_FIELDS', 'False').lower() == 'true',
    'EXCLUDED_FIELDS': [
        'created_at', 'updated_at', 'deleted_at', 'metadata'
    ],
    'BULK_OPERATION_BATCH_SIZE': int(os.getenv('BULK_OPERATION_BATCH_SIZE', '1000')),
}
