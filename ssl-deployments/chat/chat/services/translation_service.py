"""
Translation Service for BIDR Chat Service

Integrates with multiple translation providers:
- Google Cloud Translation
- Azure Translator
- AWS Translate

Features:
- Multi-provider fallback
- Translation caching
- Language detection
- Batch processing
- Rate limiting
"""

import requests
import json
import hashlib
import asyncio
import uuid
from typing import Dict, List, Optional, Tuple
from django.conf import settings
from django.core.cache import cache
from django.utils import timezone
from chat_core.models import TranslationCache, SystemConfig
import logging

logger = logging.getLogger(__name__)


class TranslationProvider:
    """Base class for translation providers."""
    
    def __init__(self, config: Dict):
        self.config = config
        self.name = self.__class__.__name__.lower().replace('provider', '')
    
    async def translate(self, text: str, target_language: str, source_language: str = None) -> Dict:
        """
        Translate text to target language.
        
        Returns:
            {
                'translated_text': str,
                'detected_source_language': str,
                'confidence': float,
                'provider': str
            }
        """
        raise NotImplementedError
    
    async def detect_language(self, text: str) -> Dict:
        """
        Detect the language of text.
        
        Returns:
            {
                'language': str,
                'confidence': float
            }
        """
        raise NotImplementedError
    
    def is_available(self) -> bool:
        """Check if the provider is available."""
        return True


class GoogleTranslateProvider(TranslationProvider):
    """Google Cloud Translation API provider."""
    
    def __init__(self, config: Dict):
        super().__init__(config)
        self.api_key = config.get('api_key')
        self.base_url = 'https://translation.googleapis.com/language/translate/v2'
        self.detect_url = 'https://translation.googleapis.com/language/translate/v2/detect'
    
    async def translate(self, text: str, target_language: str, source_language: str = None) -> Dict:
        """Translate using Google Translate API."""
        if not self.api_key:
            raise ValueError("Google Translate API key not configured")
        
        params = {
            'key': self.api_key,
            'q': text,
            'target': target_language,
        }
        
        if source_language:
            params['source'] = source_language
        
        try:
            response = requests.post(self.base_url, data=params, timeout=10)
            response.raise_for_status()
            
            data = response.json()
            translation = data['data']['translations'][0]
            
            return {
                'translated_text': translation['translatedText'],
                'detected_source_language': translation.get('detectedSourceLanguage', source_language),
                'confidence': 1.0,  # Google doesn't provide confidence scores
                'provider': 'google'
            }
            
        except Exception as e:
            logger.error(f"Google Translate error: {str(e)}")
            raise
    
    async def detect_language(self, text: str) -> Dict:
        """Detect language using Google API."""
        if not self.api_key:
            raise ValueError("Google Translate API key not configured")
        
        params = {
            'key': self.api_key,
            'q': text
        }
        
        try:
            response = requests.post(self.detect_url, data=params, timeout=10)
            response.raise_for_status()
            
            data = response.json()
            detection = data['data']['detections'][0][0]
            
            return {
                'language': detection['language'],
                'confidence': detection['confidence']
            }
            
        except Exception as e:
            logger.error(f"Google language detection error: {str(e)}")
            raise


class AzureTranslateProvider(TranslationProvider):
    """Azure Translator Text API provider."""
    
    def __init__(self, config: Dict):
        super().__init__(config)
        self.subscription_key = config.get('subscription_key')
        self.region = config.get('region', 'global')
        self.endpoint = config.get('endpoint', 'https://api.cognitive.microsofttranslator.com')
    
    async def translate(self, text: str, target_language: str, source_language: str = None) -> Dict:
        """Translate using Azure Translator API."""
        if not self.subscription_key:
            raise ValueError("Azure Translator subscription key not configured")
        
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
            'Content-type': 'application/json',
            'X-ClientTraceId': str(uuid.uuid4())
        }
        
        body = [{'text': text}]
        
        try:
            response = requests.post(
                self.endpoint + path,
                params=params,
                headers=headers,
                json=body,
                timeout=10
            )
            response.raise_for_status()
            
            data = response.json()[0]
            translation = data['translations'][0]
            
            detected_lang = data.get('detectedLanguage', {}).get('language', source_language)
            confidence = data.get('detectedLanguage', {}).get('score', 1.0)
            
            return {
                'translated_text': translation['text'],
                'detected_source_language': detected_lang,
                'confidence': confidence,
                'provider': 'azure'
            }
            
        except Exception as e:
            logger.error(f"Azure Translate error: {str(e)}")
            raise
    
    async def detect_language(self, text: str) -> Dict:
        """Detect language using Azure API."""
        if not self.subscription_key:
            raise ValueError("Azure Translator subscription key not configured")
        
        path = '/detect'
        params = {'api-version': '3.0'}
        
        headers = {
            'Ocp-Apim-Subscription-Key': self.subscription_key,
            'Ocp-Apim-Subscription-Region': self.region,
            'Content-type': 'application/json'
        }
        
        body = [{'text': text}]
        
        try:
            response = requests.post(
                self.endpoint + path,
                params=params,
                headers=headers,
                json=body,
                timeout=10
            )
            response.raise_for_status()
            
            data = response.json()[0]
            
            return {
                'language': data['language'],
                'confidence': data['score']
            }
            
        except Exception as e:
            logger.error(f"Azure language detection error: {str(e)}")
            raise


class AWSTranslateProvider(TranslationProvider):
    """AWS Translate service provider."""
    
    def __init__(self, config: Dict):
        super().__init__(config)
        self.access_key_id = config.get('access_key_id')
        self.secret_access_key = config.get('secret_access_key')
        self.region = config.get('region', 'us-east-1')
    
    async def translate(self, text: str, target_language: str, source_language: str = 'auto') -> Dict:
        """Translate using AWS Translate."""
        try:
            import boto3
            
            translate_client = boto3.client(
                'translate',
                aws_access_key_id=self.access_key_id,
                aws_secret_access_key=self.secret_access_key,
                region_name=self.region
            )
            
            response = translate_client.translate_text(
                Text=text,
                SourceLanguageCode=source_language,
                TargetLanguageCode=target_language
            )
            
            return {
                'translated_text': response['TranslatedText'],
                'detected_source_language': response['SourceLanguageCode'],
                'confidence': 1.0,  # AWS doesn't provide confidence scores
                'provider': 'aws'
            }
            
        except ImportError:
            logger.error("boto3 library not installed for AWS Translate")
            raise
        except Exception as e:
            logger.error(f"AWS Translate error: {str(e)}")
            raise
    
    async def detect_language(self, text: str) -> Dict:
        """Detect language using AWS Comprehend."""
        try:
            import boto3
            
            comprehend_client = boto3.client(
                'comprehend',
                aws_access_key_id=self.access_key_id,
                aws_secret_access_key=self.secret_access_key,
                region_name=self.region
            )
            
            response = comprehend_client.detect_dominant_language(Text=text)
            
            if response['Languages']:
                lang = response['Languages'][0]
                return {
                    'language': lang['LanguageCode'],
                    'confidence': lang['Score']
                }
            
            return {'language': 'en', 'confidence': 0.5}
            
        except ImportError:
            logger.error("boto3 library not installed for AWS Comprehend")
            raise
        except Exception as e:
            logger.error(f"AWS language detection error: {str(e)}")
            raise


class TranslationService:
    """Main translation service with caching and fallback providers."""
    
    def __init__(self):
        self.providers = {}
        self.default_provider = 'google'
        self.fallback_providers = ['azure', 'aws']
        self.cache_ttl = 86400 * 7  # 7 days
        
        # Initialize providers from settings
        self._initialize_providers()
    
    def _initialize_providers(self):
        """Initialize translation providers from configuration."""
        # Load from Django settings or system config
        provider_configs = getattr(settings, 'TRANSLATION_PROVIDERS', {})
        
        # Fallback to system config
        if not provider_configs:
            provider_configs = {
                'google': {
                    'api_key': SystemConfig.get_config('translation', 'google_api_key'),
                },
                'azure': {
                    'subscription_key': SystemConfig.get_config('translation', 'azure_key'),
                    'region': SystemConfig.get_config('translation', 'azure_region', 'global'),
                },
                'aws': {
                    'access_key_id': SystemConfig.get_config('translation', 'aws_access_key'),
                    'secret_access_key': SystemConfig.get_config('translation', 'aws_secret_key'),
                    'region': SystemConfig.get_config('translation', 'aws_region', 'us-east-1'),
                }
            }
        
        # Initialize available providers
        if provider_configs.get('google', {}).get('api_key'):
            self.providers['google'] = GoogleTranslateProvider(provider_configs['google'])
        
        if provider_configs.get('azure', {}).get('subscription_key'):
            self.providers['azure'] = AzureTranslateProvider(provider_configs['azure'])
        
        if provider_configs.get('aws', {}).get('access_key_id'):
            self.providers['aws'] = AWSTranslateProvider(provider_configs['aws'])
        
        logger.info(f"Initialized translation providers: {list(self.providers.keys())}")
    
    def _get_cache_key(self, text: str, source_lang: str, target_lang: str) -> str:
        """Generate cache key for translation."""
        content = f"{text}:{source_lang}:{target_lang}"
        return f"translation:{hashlib.md5(content.encode()).hexdigest()}"
    
    def _get_cached_translation(self, text: str, source_lang: str, target_lang: str) -> Optional[Dict]:
        """Get translation from cache."""
        try:
            # Check Django cache first
            cache_key = self._get_cache_key(text, source_lang, target_lang)
            cached = cache.get(cache_key)
            if cached:
                return cached
            
            # Check database cache
            db_cached = TranslationCache.objects.filter(
                source_text=text,
                source_language=source_lang,
                target_language=target_lang
            ).first()
            
            if db_cached:
                # Update usage count
                db_cached.usage_count += 1
                db_cached.last_used = timezone.now()
                db_cached.save(update_fields=['usage_count', 'last_used'])
                
                result = {
                    'translated_text': db_cached.translated_text,
                    'detected_source_language': db_cached.source_language,
                    'confidence': float(db_cached.confidence_score) if db_cached.confidence_score else 1.0,
                    'provider': db_cached.translation_service,
                    'from_cache': True
                }
                
                # Cache in Django cache for faster access
                cache.set(cache_key, result, self.cache_ttl)
                return result
            
        except Exception as e:
            logger.warning(f"Cache retrieval error: {str(e)}")
        
        return None
    
    def _cache_translation(self, text: str, source_lang: str, target_lang: str, result: Dict):
        """Cache translation result."""
        try:
            # Cache in Django cache
            cache_key = self._get_cache_key(text, source_lang, target_lang)
            cache.set(cache_key, result, self.cache_ttl)
            
            # Cache in database
            TranslationCache.objects.update_or_create(
                source_text=text,
                source_language=source_lang,
                target_language=target_lang,
                defaults={
                    'translated_text': result['translated_text'],
                    'translation_service': result['provider'],
                    'confidence_score': result.get('confidence', 1.0),
                    'usage_count': 1,
                    'last_used': timezone.now()
                }
            )
            
        except Exception as e:
            logger.warning(f"Cache storage error: {str(e)}")
    
    async def translate_text(self, text: str, target_language: str, source_language: str = None, user_preferences: Dict = None) -> Dict:
        """Translate text with caching and fallback."""
        if not text or not target_language:
            raise ValueError("Text and target language are required")
        
        # Detect source language if not provided
        if not source_language:
            try:
                detection_result = await self.detect_language(text)
                source_language = detection_result['language']
            except:
                source_language = 'auto'
        
        # Skip translation if source and target are the same
        if source_language == target_language:
            return {
                'translated_text': text,
                'detected_source_language': source_language,
                'confidence': 1.0,
                'provider': 'none',
                'from_cache': False
            }
        
        # Check cache first
        cached_result = self._get_cached_translation(text, source_language, target_language)
        if cached_result:
            return cached_result
        
        # Get preferred provider order
        provider_order = self._get_provider_order(user_preferences)
        
        # Try providers in order
        last_error = None
        for provider_name in provider_order:
            if provider_name not in self.providers:
                continue
            
            provider = self.providers[provider_name]
            try:
                result = await provider.translate(text, target_language, source_language)
                result['from_cache'] = False
                
                # Cache successful translation
                self._cache_translation(text, source_language, target_language, result)
                
                logger.info(f"Translation successful using {provider_name}")
                return result
                
            except Exception as e:
                logger.warning(f"Translation failed with {provider_name}: {str(e)}")
                last_error = e
                continue
        
        # All providers failed
        if last_error:
            raise last_error
        else:
            raise RuntimeError("No translation providers available")
    
    async def detect_language(self, text: str) -> Dict:
        """Detect language of text."""
        if not text:
            raise ValueError("Text is required for language detection")
        
        # Try providers in order
        for provider_name in [self.default_provider] + self.fallback_providers:
            if provider_name not in self.providers:
                continue
            
            provider = self.providers[provider_name]
            try:
                result = await provider.detect_language(text)
                return result
            except Exception as e:
                logger.warning(f"Language detection failed with {provider_name}: {str(e)}")
                continue
        
        # Fallback to English if detection fails
        return {'language': 'en', 'confidence': 0.1}
    
    async def batch_translate(self, texts: List[str], target_language: str, source_language: str = None) -> List[Dict]:
        """Translate multiple texts efficiently."""
        results = []
        
        # Process in batches to avoid API limits
        batch_size = 10
        for i in range(0, len(texts), batch_size):
            batch = texts[i:i + batch_size]
            batch_results = await asyncio.gather(
                *[self.translate_text(text, target_language, source_language) for text in batch],
                return_exceptions=True
            )
            
            for result in batch_results:
                if isinstance(result, Exception):
                    results.append({
                        'error': str(result),
                        'translated_text': '',
                        'provider': 'error'
                    })
                else:
                    results.append(result)
        
        return results
    
    def _get_provider_order(self, user_preferences: Dict = None) -> List[str]:
        """Get provider preference order."""
        if user_preferences and user_preferences.get('preferred_provider'):
            preferred = user_preferences['preferred_provider']
            if preferred in self.providers:
                order = [preferred]
                order.extend([p for p in [self.default_provider] + self.fallback_providers if p != preferred and p in self.providers])
                return order
        
        # Default order
        return [p for p in [self.default_provider] + self.fallback_providers if p in self.providers]
    
    def get_supported_languages(self) -> Dict[str, str]:
        """Get list of supported languages."""
        # Common languages supported by most providers
        return {
            'en': 'English',
            'es': 'Spanish',
            'fr': 'French',
            'de': 'German',
            'it': 'Italian',
            'pt': 'Portuguese',
            'ru': 'Russian',
            'zh': 'Chinese (Simplified)',
            'zh-tw': 'Chinese (Traditional)',
            'ja': 'Japanese',
            'ko': 'Korean',
            'ar': 'Arabic',
            'hi': 'Hindi',
            'th': 'Thai',
            'vi': 'Vietnamese',
            'pl': 'Polish',
            'nl': 'Dutch',
            'sv': 'Swedish',
            'da': 'Danish',
            'no': 'Norwegian',
            'fi': 'Finnish',
            'tr': 'Turkish',
            'he': 'Hebrew',
        }
    
    def get_provider_status(self) -> Dict[str, bool]:
        """Get status of all providers."""
        status = {}
        for name, provider in self.providers.items():
            try:
                status[name] = provider.is_available()
            except:
                status[name] = False
        return status


# Global translation service instance
_translation_service = None

def get_translation_service() -> TranslationService:
    """Get the global translation service instance."""
    global _translation_service
    if _translation_service is None:
        _translation_service = TranslationService()
    return _translation_service
