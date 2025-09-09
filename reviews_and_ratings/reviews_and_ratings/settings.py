"""
Django settings for reviews_and_ratings project.
"""
import os
import sys
from pathlib import Path
from decouple import config

# Build paths inside the project like this: BASE_DIR / 'subdir'.
BASE_DIR = Path(__file__).resolve().parent.parent

# SECURITY WARNING: keep the secret key used in production secret!
SECRET_KEY = config('SECRET_KEY', default='django-insecure-reviews-key-change-in-production')

# SECURITY WARNING: don't run with debug turned on in production!
# Force DEBUG to False in containerized environments
DEBUG = config('DEBUG', default=False, cast=bool)
ALLOWED_HOSTS = config('ALLOWED_HOSTS', default='localhost,127.0.0.1').split(',')

# Allow all hosts for Kubernetes deployment
ALLOWED_HOSTS.append('*')

print(f"ALLOWED_HOSTS: {ALLOWED_HOSTS}")

# Add ngrok domains dynamically
if 'HTTP_HOST' in os.environ:
    http_host = os.environ['HTTP_HOST']
    if 'ngrok' in http_host and http_host not in ALLOWED_HOSTS:
        ALLOWED_HOSTS.append(http_host)


# Application definition

INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    
    # Third-party apps
    'rest_framework',
    'corsheaders',
    'django_prometheus',
    'django_filters',
    
    # Local apps
    'reviews',
    'ratings',
    'content',
    'rewards',
]

MIDDLEWARE = [
    'django_prometheus.middleware.PrometheusBeforeMiddleware',
    'corsheaders.middleware.CorsMiddleware',
    'django.middleware.security.SecurityMiddleware',
    'whitenoise.middleware.WhiteNoiseMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
    'django_prometheus.middleware.PrometheusAfterMiddleware',
]

ROOT_URLCONF = 'reviews_and_ratings.urls'

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

WSGI_APPLICATION = 'reviews_and_ratings.wsgi.application'


# Database
# Use PostgreSQL with credentials from environment variables
import dj_database_url

# Check if running in Kubernetes with mounted secrets
if os.path.exists('/etc/secrets/db'):
    # Read database credentials from Kubernetes secrets
    DATABASES = {
        'default': {
            'ENGINE': 'django.db.backends.postgresql',
            'NAME': os.environ.get('DB_NAME', 'bidr_reviews'),
            'USER': os.environ.get('DB_USER', 'bidruser'),
            'PASSWORD': os.environ.get('DB_PASSWORD'),
            'HOST': os.environ.get('DB_HOST', 'postgres-service'),
            'PORT': os.environ.get('DB_PORT', '5432'),
        }
    }
else:
    # Try to use PostgreSQL from DATABASE_URL, fallback to SQLite if unavailable
    try:
        DATABASES = {
            'default': dj_database_url.config(
                default=f'sqlite:///{BASE_DIR / "db.sqlite3"}',
                conn_max_age=600,
                conn_health_checks=False,  # Disable health checks for now
            )
        }
        # Test if PostgreSQL DATABASE_URL is configured and the engine is PostgreSQL
        if 'DATABASE_URL' in os.environ and DATABASES['default']['ENGINE'] == 'django.db.backends.postgresql':
            print(f"Using PostgreSQL database: {DATABASES['default']['HOST']}")
        else:
            print(f"Using SQLite database: {DATABASES['default']['NAME']}")
    except Exception as e:
        print(f"Database configuration error: {e}")
        # Fallback to SQLite
        DATABASES = {
            'default': {
                'ENGINE': 'django.db.backends.sqlite3',
                'NAME': BASE_DIR / 'db.sqlite3',
            }
        }
        print(f"Fallback to SQLite: {DATABASES['default']['NAME']}")


# Password validation
# https://docs.djangoproject.com/en/5.1/ref/settings/#auth-password-validators

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
# https://docs.djangoproject.com/en/5.1/topics/i18n/

LANGUAGE_CODE = 'en-us'

TIME_ZONE = 'UTC'

USE_I18N = True

USE_TZ = True


# Static files (CSS, JavaScript, Images)
STATIC_URL = '/static/'
STATIC_ROOT = os.path.join(BASE_DIR, 'staticfiles')
STATICFILES_DIRS = [
    os.path.join(BASE_DIR, "static"),
]

# WhiteNoise configuration for serving static files in production
if not DEBUG:
    STATICFILES_STORAGE = 'whitenoise.storage.CompressedManifestStaticFilesStorage'
    # Enable compression for better performance
    WHITENOISE_USE_FINDERS = True
    WHITENOISE_AUTOREFRESH = True

# Media files
MEDIA_URL = '/media/'
MEDIA_ROOT = os.path.join(BASE_DIR, 'media')

# REST Framework Configuration
REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': [
        'rest_framework.authentication.SessionAuthentication',
        'rest_framework.authentication.BasicAuthentication',
    ],
    'DEFAULT_PERMISSION_CLASSES': [
        'rest_framework.permissions.AllowAny',  # For development
    ],
    'DEFAULT_PAGINATION_CLASS': 'rest_framework.pagination.PageNumberPagination',
    'PAGE_SIZE': 20,
    'DEFAULT_RENDERER_CLASSES': [
        'rest_framework.renderers.JSONRenderer',
        'rest_framework.renderers.BrowsableAPIRenderer',
    ],
}

# CSRF Configuration for HTTPS behind proxy
# Note: Wildcards work in CSRF_TRUSTED_ORIGINS but being explicit is better
CSRF_TRUSTED_ORIGINS = [
    "https://reviews.bidr.co.za",
    "https://notifications.bidr.co.za",
    "https://api.bidr.co.za",
    "https://products-management.bidr.co.za",
    "https://chat-service.bidr.co.za",
    "https://bidr.co.za",
    "https://www.bidr.co.za",
    "https://*.azurecontainer.io",
    "http://localhost:8000",
    "http://127.0.0.1:8000",
]

# Session and Security Settings for HTTPS
SECURE_PROXY_SSL_HEADER = ('HTTP_X_FORWARDED_PROTO', 'https')

# HTTPS Security Settings (only in production)
if not DEBUG:
    SECURE_SSL_REDIRECT = False  # Application Gateway handles this
    SESSION_COOKIE_SECURE = True
    CSRF_COOKIE_SECURE = True
    SECURE_BROWSER_XSS_FILTER = True
    SECURE_CONTENT_TYPE_NOSNIFF = True

# CORS Configuration for Flutter Mobile Apps and Web Apps
# Flutter mobile apps need special handling for CORS
CORS_ALLOW_ALL_ORIGINS = True  # Allow all origins for mobile app compatibility
CORS_ALLOW_CREDENTIALS = True

# Specific origins for production security (can be used if needed)
CORS_ALLOWED_ORIGINS = [
    "https://reviews.bidr.co.za",
    "https://notifications.bidr.co.za",
    "https://api.bidr.co.za",
    "https://products-management.bidr.co.za",
    "https://chat-service.bidr.co.za",
    "https://bidr.co.za",
    "https://www.bidr.co.za",
    "http://localhost:3000",
    "http://127.0.0.1:3000",
    "http://localhost:8000",
    "http://127.0.0.1:8000",
]

# Explicitly allow common headers sent by Flutter HTTP client
CORS_ALLOW_HEADERS = [
    'accept',
    'accept-encoding',
    'authorization',
    'content-type',
    'dnt', 
    'origin',
    'user-agent',
    'x-csrftoken',
    'x-requested-with',
    'cache-control',
    'x-forwarded-for',
    'x-forwarded-proto',
]

CORS_ALLOW_METHODS = [
    'DELETE',
    'GET',
    'OPTIONS',
    'PATCH',
    'POST',
    'PUT',
]

# Enable preflight for all requests
CORS_PREFLIGHT_MAX_AGE = 86400

# Additional settings for Flutter compatibility
# Note: CORS_REPLACE_HTTPS_REFERER was removed in newer django-cors-headers versions

# Default primary key field type
# https://docs.djangoproject.com/en/5.1/ref/settings/#default-auto-field

DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'

# Allow all hosts for Kubernetes deployment
ALLOWED_HOSTS.append('*')

# Logging Configuration
# Create logs directory if it doesn't exist
LOGS_DIR = os.path.join(BASE_DIR, 'logs')
os.makedirs(LOGS_DIR, exist_ok=True)

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
        'console': {
            'class': 'logging.StreamHandler',
            'formatter': 'verbose' if DEBUG else 'simple',
        },
    },
    'loggers': {
        'django': {
            'handlers': ['console'],
            'level': 'INFO' if not DEBUG else 'DEBUG',
            'propagate': True,
        },
        'reviews_and_ratings': {
            'handlers': ['console'],
            'level': 'DEBUG',
            'propagate': False,
        },
    },
}

# Add file handler only if we can write to the logs directory
try:
    test_file = os.path.join(LOGS_DIR, 'test.log')
    with open(test_file, 'w') as f:
        f.write('test')
    os.remove(test_file)
    
    # Add file handler
    LOGGING['handlers']['file'] = {
        'class': 'logging.FileHandler',
        'filename': os.path.join(LOGS_DIR, 'reviews_service.log'),
        'formatter': 'verbose',
    }
    LOGGING['loggers']['reviews_and_ratings']['handlers'] = ['console', 'file']
except (OSError, IOError):
    # If we can't write to logs directory, just use console
    pass
