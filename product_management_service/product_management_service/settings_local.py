"""
Local Django settings for connecting to cluster database
Load this with: python manage.py runserver --settings=product_management_service.settings_local
"""
import os
from pathlib import Path
from .settings import *

# Load environment variables from .env.cluster file (optional)
try:
    env_file = BASE_DIR.parent / '.env.cluster'
    if env_file.exists():
        from dotenv import load_dotenv
        load_dotenv(env_file)
except ImportError:
    # dotenv not available, rely on system environment variables
    pass

# Override database settings to use cluster database
if os.getenv('USE_CLUSTER_DB', 'False').lower() == 'true':
    DATABASES = {
        'default': {
            'ENGINE': 'django.db.backends.postgresql',
            'NAME': os.getenv('DB_NAME', 'bidr_products'),
            'USER': os.getenv('DB_USER', 'bidruser'),
            'PASSWORD': os.getenv('DB_PASSWORD'),
            'HOST': os.getenv('DB_HOST', 'localhost'),  # localhost because we're port-forwarding
            'PORT': os.getenv('DB_PORT', '5432'),
            'OPTIONS': {
                'connect_timeout': 30,
            }
        }
    }
    
    print(f"✅ Using cluster database: {os.getenv('DB_NAME')} at {os.getenv('DB_HOST')}:{os.getenv('DB_PORT')}")
else:
    print("ℹ️  Using local SQLite database")

# Ensure we can see database queries in debug mode
if DEBUG:
    LOGGING['loggers']['django.db.backends'] = {
        'handlers': ['console'],
        'level': 'INFO',
        'propagate': False,
    }
