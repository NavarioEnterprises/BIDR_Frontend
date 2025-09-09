"""
Test suite for chat_core app

Tests cover:
- User profile management
- System configuration
- Translation cache
- Content filter rules
- Moderation queue
- Language preferences
"""

import json
# Set up Django environment if not already configured
import os
import django
from django.conf import settings

if not settings.configured:
    os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'chat_service.settings')
    django.setup()

from django.test import TestCase
from django.contrib.auth.models import User
from django.utils import timezone
from django.core.exceptions import ValidationError
from rest_framework.test import APITestCase
from rest_framework import status
from .models import (
    UserProfile, SystemConfig, TranslationCache, ContentFilterRule,
    ModerationQueue, LanguagePreference, AuditLog
)


class UserProfileModelTest(TestCase):
    """Test UserProfile model functionality."""
    
    def setUp(self):
        """Set up test data."""
        self.user = User.objects.create_user(
            username='testuser',
            email='test@example.com',
            password='testpass123'
        )
    
    def test_create_user_profile(self):
        """Test creating a user profile."""
        profile = UserProfile.objects.create(
            user=self.user,
            role='buyer',
            display_name='Test User',
            bio='Test bio',
            verification_status='email_verified'
        )
        
        self.assertEqual(profile.user, self.user)
        self.assertEqual(profile.role, 'buyer')
        self.assertEqual(profile.get_display_name(), 'Test User')
        self.assertTrue(profile.can_send_messages())
    
    def test_user_profile_online_status(self):
        """Test online status calculation."""
        profile = UserProfile.objects.create(
            user=self.user,
            role='buyer',
            show_online_status=True
        )
        
        # Should be online (just created)
        self.assertTrue(profile.is_online())
        
        # Update last_seen to 10 minutes ago
        old_time = timezone.now() - timezone.timedelta(minutes=10)
        profile.last_seen = old_time
        profile.save()
        
        # Should be offline now
        self.assertFalse(profile.is_online())
    
    def test_banned_user_cannot_send_messages(self):
        """Test that banned users cannot send messages."""
        profile = UserProfile.objects.create(
            user=self.user,
            role='buyer',
            is_banned=True,
            ban_expires_at=timezone.now() + timezone.timedelta(days=1)
        )
        
        self.assertFalse(profile.can_send_messages())


class SystemConfigModelTest(TestCase):
    """Test SystemConfig model functionality."""
    
    def test_create_system_config(self):
        """Test creating system configuration."""
        config = SystemConfig.objects.create(
            category='translation',
            key='default_provider',
            value='google',
            description='Default translation service provider'
        )
        
        self.assertEqual(config.category, 'translation')
        self.assertEqual(config.key, 'default_provider')
        self.assertEqual(config.value, 'google')
    
    def test_get_config_method(self):
        """Test the get_config static method."""
        SystemConfig.objects.create(
            category='moderation',
            key='auto_enabled',
            value='true'
        )
        
        # Test existing config
        result = SystemConfig.get_config('moderation', 'auto_enabled')
        self.assertEqual(result, True)
        
        # Test non-existing config with default
        result = SystemConfig.get_config('missing', 'key', 'default_value')
        self.assertEqual(result, 'default_value')
    
    def test_json_config_parsing(self):
        """Test JSON configuration parsing."""
        config = SystemConfig.objects.create(
            category='features',
            key='enabled_features',
            value='["chat", "translation", "moderation"]'
        )
        
        # Test getting config with JSON parsing via get_config method
        parsed = SystemConfig.get_config('features', 'enabled_features')
        self.assertEqual(parsed, ['chat', 'translation', 'moderation'])


class TranslationCacheModelTest(TestCase):
    """Test TranslationCache model functionality."""
    
    def test_create_translation_cache(self):
        """Test creating translation cache entry."""
        cache_entry = TranslationCache.objects.create(
            source_text='Hello world',
            source_language='en',
            target_language='es',
            translated_text='Hola mundo',
            translation_service='google',
            confidence_score=0.95
        )
        
        self.assertEqual(cache_entry.source_text, 'Hello world')
        self.assertEqual(cache_entry.translated_text, 'Hola mundo')
        self.assertEqual(cache_entry.usage_count, 1)
