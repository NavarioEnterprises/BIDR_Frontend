# Set up Django environment if not already configured
import os
import django
from django.conf import settings

if not settings.configured:
    os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'chat_service.settings')
    django.setup()

from django.test import TestCase

# Create your tests here.
