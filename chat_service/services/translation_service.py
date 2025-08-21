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
                db_cached.save(update_fields=['usage_count', 'last_used'])\n                \n                result = {\n                    'translated_text': db_cached.translated_text,\n                    'detected_source_language': db_cached.source_language,\n                    'confidence': float(db_cached.confidence_score) if db_cached.confidence_score else 1.0,\n                    'provider': db_cached.translation_service,\n                    'from_cache': True\n                }\n                \n                # Cache in Django cache for faster access\n                cache.set(cache_key, result, self.cache_ttl)\n                return result\n            \n        except Exception as e:\n            logger.warning(f\"Cache retrieval error: {str(e)}\")\n        \n        return None\n    \n    def _cache_translation(self, text: str, source_lang: str, target_lang: str, result: Dict):\n        \"\"\"Cache translation result.\"\"\"\n        try:\n            # Cache in Django cache\n            cache_key = self._get_cache_key(text, source_lang, target_lang)\n            cache.set(cache_key, result, self.cache_ttl)\n            \n            # Cache in database\n            TranslationCache.objects.update_or_create(\n                source_text=text,\n                source_language=source_lang,\n                target_language=target_lang,\n                defaults={\n                    'translated_text': result['translated_text'],\n                    'translation_service': result['provider'],\n                    'confidence_score': result.get('confidence', 1.0),\n                    'usage_count': 1,\n                    'last_used': timezone.now()\n                }\n            )\n            \n        except Exception as e:\n            logger.warning(f\"Cache storage error: {str(e)}\")\n    \n    async def translate_text(self, text: str, target_language: str, source_language: str = None, user_preferences: Dict = None) -> Dict:\n        \"\"\"Translate text with caching and fallback.\"\"\"\n        if not text or not target_language:\n            raise ValueError(\"Text and target language are required\")\n        \n        # Detect source language if not provided\n        if not source_language:\n            try:\n                detection_result = await self.detect_language(text)\n                source_language = detection_result['language']\n            except:\n                source_language = 'auto'\n        \n        # Skip translation if source and target are the same\n        if source_language == target_language:\n            return {\n                'translated_text': text,\n                'detected_source_language': source_language,\n                'confidence': 1.0,\n                'provider': 'none',\n                'from_cache': False\n            }\n        \n        # Check cache first\n        cached_result = self._get_cached_translation(text, source_language, target_language)\n        if cached_result:\n            return cached_result\n        \n        # Get preferred provider order\n        provider_order = self._get_provider_order(user_preferences)\n        \n        # Try providers in order\n        last_error = None\n        for provider_name in provider_order:\n            if provider_name not in self.providers:\n                continue\n            \n            provider = self.providers[provider_name]\n            try:\n                result = await provider.translate(text, target_language, source_language)\n                result['from_cache'] = False\n                \n                # Cache successful translation\n                self._cache_translation(text, source_language, target_language, result)\n                \n                logger.info(f\"Translation successful using {provider_name}\")\n                return result\n                \n            except Exception as e:\n                logger.warning(f\"Translation failed with {provider_name}: {str(e)}\")\n                last_error = e\n                continue\n        \n        # All providers failed\n        if last_error:\n            raise last_error\n        else:\n            raise RuntimeError(\"No translation providers available\")\n    \n    async def detect_language(self, text: str) -> Dict:\n        \"\"\"Detect language of text.\"\"\"\n        if not text:\n            raise ValueError(\"Text is required for language detection\")\n        \n        # Try providers in order\n        for provider_name in [self.default_provider] + self.fallback_providers:\n            if provider_name not in self.providers:\n                continue\n            \n            provider = self.providers[provider_name]\n            try:\n                result = await provider.detect_language(text)\n                return result\n            except Exception as e:\n                logger.warning(f\"Language detection failed with {provider_name}: {str(e)}\")\n                continue\n        \n        # Fallback to English if detection fails\n        return {'language': 'en', 'confidence': 0.1}\n    \n    async def batch_translate(self, texts: List[str], target_language: str, source_language: str = None) -> List[Dict]:\n        \"\"\"Translate multiple texts efficiently.\"\"\"\n        results = []\n        \n        # Process in batches to avoid API limits\n        batch_size = 10\n        for i in range(0, len(texts), batch_size):\n            batch = texts[i:i + batch_size]\n            batch_results = await asyncio.gather(\n                *[self.translate_text(text, target_language, source_language) for text in batch],\n                return_exceptions=True\n            )\n            \n            for result in batch_results:\n                if isinstance(result, Exception):\n                    results.append({\n                        'error': str(result),\n                        'translated_text': '',\n                        'provider': 'error'\n                    })\n                else:\n                    results.append(result)\n        \n        return results\n    \n    def _get_provider_order(self, user_preferences: Dict = None) -> List[str]:\n        \"\"\"Get provider preference order.\"\"\"\n        if user_preferences and user_preferences.get('preferred_provider'):\n            preferred = user_preferences['preferred_provider']\n            if preferred in self.providers:\n                order = [preferred]\n                order.extend([p for p in [self.default_provider] + self.fallback_providers if p != preferred and p in self.providers])\n                return order\n        \n        # Default order\n        return [p for p in [self.default_provider] + self.fallback_providers if p in self.providers]\n    \n    def get_supported_languages(self) -> Dict[str, str]:\n        \"\"\"Get list of supported languages.\"\"\"\n        # Common languages supported by most providers\n        return {\n            'en': 'English',\n            'es': 'Spanish',\n            'fr': 'French',\n            'de': 'German',\n            'it': 'Italian',\n            'pt': 'Portuguese',\n            'ru': 'Russian',\n            'zh': 'Chinese (Simplified)',\n            'zh-tw': 'Chinese (Traditional)',\n            'ja': 'Japanese',\n            'ko': 'Korean',\n            'ar': 'Arabic',\n            'hi': 'Hindi',\n            'th': 'Thai',\n            'vi': 'Vietnamese',\n            'pl': 'Polish',\n            'nl': 'Dutch',\n            'sv': 'Swedish',\n            'da': 'Danish',\n            'no': 'Norwegian',\n            'fi': 'Finnish',\n            'tr': 'Turkish',\n            'he': 'Hebrew',\n        }\n    \n    def get_provider_status(self) -> Dict[str, bool]:\n        \"\"\"Get status of all providers.\"\"\"\n        status = {}\n        for name, provider in self.providers.items():\n            try:\n                status[name] = provider.is_available()\n            except:\n                status[name] = False\n        return status\n\n\n# Global translation service instance\n_translation_service = None\n\ndef get_translation_service() -> TranslationService:\n    \"\"\"Get the global translation service instance.\"\"\"\n    global _translation_service\n    if _translation_service is None:\n        _translation_service = TranslationService()\n    return _translation_service
