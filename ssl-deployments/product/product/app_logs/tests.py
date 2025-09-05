# Set up Django environment if not already configured
import os
import django
from django.conf import settings

if not settings.configured:
    os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'product_management_service.settings')
    django.setup()

from django.test import TestCase, Client
from django.contrib.auth.models import User
from django.urls import reverse
from django.utils import timezone
from django.db import transaction
from unittest.mock import patch, MagicMock
from datetime import timedelta
import json
import time

from .models import (
    APIRequestLog, ApplicationLog, ProductRequestLog, 
    CategoryLog, PerformanceLog, ErrorLog,
    LogLevel, EventType
)
from .middleware import APILoggingMiddleware, PerformanceLoggingMiddleware


class APIRequestLogModelTest(TestCase):
    """Test cases for APIRequestLog model."""
    
    def setUp(self):
        self.user = User.objects.create_user(
            username='testuser',
            email='test@example.com',
            password='testpass123'
        )
    
    def test_create_api_request_log(self):
        """Test creating an API request log."""
        log = APIRequestLog.objects.create(
            method='GET',
            path='/api/test/',
            full_url='http://testserver/api/test/',
            status_code=200,
            duration_ms=50.5,
            user=self.user,
            ip_address='127.0.0.1',
            user_agent='Test Agent',
            request_body=json.dumps({'test': 'data'}),
            response_body=json.dumps({'result': 'success'}),
            query_params={'q': 'search'},
            headers={'Content-Type': 'application/json'}
        )
        
        self.assertEqual(log.method, 'GET')
        self.assertEqual(log.path, '/api/test/')
        self.assertEqual(log.status_code, 200)
        self.assertEqual(log.user, self.user)
        self.assertTrue(log.is_successful)
        self.assertFalse(log.is_client_error)
        self.assertFalse(log.is_server_error)
        self.assertEqual(log.duration_seconds, 0.0505)
    
    def test_status_code_properties(self):
        """Test status code classification properties."""
        # Test successful request
        success_log = APIRequestLog.objects.create(
            method='GET', path='/api/test/', full_url='http://test.com/api/test/',
            status_code=200, duration_ms=10
        )
        self.assertTrue(success_log.is_successful)
        
        # Test client error
        client_error_log = APIRequestLog.objects.create(
            method='GET', path='/api/test/', full_url='http://test.com/api/test/',
            status_code=404, duration_ms=10
        )
        self.assertTrue(client_error_log.is_client_error)
        
        # Test server error
        server_error_log = APIRequestLog.objects.create(
            method='GET', path='/api/test/', full_url='http://test.com/api/test/',
            status_code=500, duration_ms=10
        )
        self.assertTrue(server_error_log.is_server_error)
    
    def test_string_representation(self):
        """Test string representation of APIRequestLog."""
        log = APIRequestLog.objects.create(
            method='POST',
            path='/api/products/',
            full_url='http://testserver/api/products/',
            status_code=201,
            duration_ms=120.5
        )
        
        expected = f"POST /api/products/ - 201 ({log.timestamp})"
        self.assertEqual(str(log), expected)


class ApplicationLogModelTest(TestCase):
    """Test cases for ApplicationLog model."""
    
    def setUp(self):
        self.user = User.objects.create_user(
            username='testuser',
            email='test@example.com',
            password='testpass123'
        )
    
    def test_create_application_log(self):
        """Test creating an application log."""
        log = ApplicationLog.objects.create(
            level=LogLevel.INFO,
            event_type=EventType.USER_ACTION,
            message='User performed an action',
            category='user_management',
            subcategory='login',
            user=self.user,
            ip_address='127.0.0.1',
            context_data={'action': 'login', 'success': True},
            tags=['authentication', 'security']
        )
        
        self.assertEqual(log.level, LogLevel.INFO)
        self.assertEqual(log.event_type, EventType.USER_ACTION)
        self.assertEqual(log.category, 'user_management')
        self.assertEqual(log.user, self.user)
        self.assertEqual(log.context_data['action'], 'login')
        self.assertIn('authentication', log.tags)
    
    def test_string_representation(self):
        """Test string representation of ApplicationLog."""
        log = ApplicationLog.objects.create(
            level=LogLevel.ERROR,
            event_type=EventType.ERROR_EVENT,
            message='This is a very long error message that should be truncated',
            category='system_error'
        )
        
        expected = f"[ERROR] system_error: This is a very long error message that should be t..."
        self.assertEqual(str(log), expected)


class ErrorLogModelTest(TestCase):
    """Test cases for ErrorLog model."""
    
    def setUp(self):
        self.user = User.objects.create_user(
            username='testuser',
            email='test@example.com',
            password='testpass123'
        )
    
    def test_create_error_log(self):
        """Test creating an error log."""
        log = ErrorLog.objects.create(
            error_type='ValueError',
            error_message='Invalid input provided',
            stack_trace='Traceback (most recent call last):\n  File "test.py"...',
            path='/api/test/',
            method='POST',
            user=self.user,
            ip_address='127.0.0.1',
            context_data={'input': 'invalid_data'},
            is_resolved=False
        )
        
        self.assertEqual(log.error_type, 'ValueError')
        self.assertEqual(log.error_message, 'Invalid input provided')
        self.assertEqual(log.user, self.user)
        self.assertFalse(log.is_resolved)
        self.assertIsNone(log.resolved_by)
        self.assertIsNone(log.resolved_at)
    
    def test_resolve_error(self):
        """Test resolving an error."""
        resolver = User.objects.create_user(
            username='resolver',
            email='resolver@example.com',
            password='resolverpass123'
        )
        
        log = ErrorLog.objects.create(
            error_type='TestError',
            error_message='Test error message',
            is_resolved=False
        )
        
        # Resolve the error
        log.is_resolved = True
        log.resolved_by = resolver
        log.resolved_at = timezone.now()
        log.resolution_notes = 'Fixed by updating configuration'
        log.save()
        
        self.assertTrue(log.is_resolved)
        self.assertEqual(log.resolved_by, resolver)
        self.assertIsNotNone(log.resolved_at)
        self.assertEqual(log.resolution_notes, 'Fixed by updating configuration')


class PerformanceLogModelTest(TestCase):
    """Test cases for PerformanceLog model."""
    
    def test_create_performance_log(self):
        """Test creating a performance log."""
        log = PerformanceLog.objects.create(
            metric_name='response_time',
            metric_value=2500.0,
            metric_unit='ms',
            operation='GET /api/slow-endpoint/',
            endpoint='/api/slow-endpoint/',
            threshold_exceeded=True,
            severity=LogLevel.WARNING,
            metadata={
                'memory_usage': 150.5,
                'cpu_usage': 80.2,
                'database_queries': 15
            }
        )
        
        self.assertEqual(log.metric_name, 'response_time')
        self.assertEqual(log.metric_value, 2500.0)
        self.assertEqual(log.metric_unit, 'ms')
        self.assertTrue(log.threshold_exceeded)
        self.assertEqual(log.metadata['memory_usage'], 150.5)
    
    def test_string_representation(self):
        """Test string representation of PerformanceLog."""
        log = PerformanceLog.objects.create(
            metric_name='response_time',
            metric_value=1500.5,
            metric_unit='ms',
            operation='POST /api/create-product/'
        )
        
        expected = "response_time: 1500.5 ms (POST /api/create-product/)"
        self.assertEqual(str(log), expected)


class APILoggingMiddlewareTest(TestCase):
    """Test cases for APILoggingMiddleware."""
    
    def setUp(self):
        self.client = Client()
        self.user = User.objects.create_user(
            username='testuser',
            email='test@example.com',
            password='testpass123'
        )
        
        # Mock get_response for middleware
        self.get_response = MagicMock()
        self.middleware = APILoggingMiddleware(self.get_response)
    
    def test_should_log_request_api_path(self):
        """Test that API paths should be logged."""
        from django.http import HttpRequest, HttpResponse
        
        request = HttpRequest()
        request.path = '/api/v1/test/'
        response = HttpResponse(content_type='application/json')
        
        self.assertTrue(self.middleware._should_log_request(request, response))
    
    def test_should_not_log_static_files(self):
        """Test that static files should not be logged."""
        from django.http import HttpRequest, HttpResponse
        
        request = HttpRequest()
        request.path = '/static/css/style.css'
        response = HttpResponse()
        
        self.assertFalse(self.middleware._should_log_request(request, response))
    
    def test_should_not_log_health_checks(self):
        """Test that health check endpoints should not be logged."""
        from django.http import HttpRequest, HttpResponse
        
        request = HttpRequest()
        request.path = '/health/'
        response = HttpResponse()
        
        self.assertFalse(self.middleware._should_log_request(request, response))
    
    def test_get_client_ip_with_forwarded_for(self):
        """Test getting client IP with X-Forwarded-For header."""
        from django.http import HttpRequest
        
        request = HttpRequest()
        request.META['HTTP_X_FORWARDED_FOR'] = '192.168.1.100, 10.0.0.1'
        request.META['REMOTE_ADDR'] = '127.0.0.1'
        
        ip = self.middleware._get_client_ip(request)
        self.assertEqual(ip, '192.168.1.100')
    
    def test_get_client_ip_without_forwarded_for(self):
        """Test getting client IP without X-Forwarded-For header."""
        from django.http import HttpRequest
        
        request = HttpRequest()
        request.META['REMOTE_ADDR'] = '127.0.0.1'
        
        ip = self.middleware._get_client_ip(request)
        self.assertEqual(ip, '127.0.0.1')
    
    def test_get_filtered_headers(self):
        """Test filtering sensitive headers."""
        from django.http import HttpRequest
        
        request = HttpRequest()
        request.META.update({
            'HTTP_AUTHORIZATION': 'Bearer secret-token',
            'HTTP_CONTENT_TYPE': 'application/json',
            'HTTP_USER_AGENT': 'Test Agent',
            'HTTP_COOKIE': 'sessionid=secret',
            'REMOTE_ADDR': '127.0.0.1'
        })
        
        headers = self.middleware._get_filtered_headers(request)
        
        self.assertIn('Content-Type', headers)
        self.assertIn('User-Agent', headers)
        self.assertNotIn('Authorization', headers)
        self.assertNotIn('Cookie', headers)
    
    @patch('app_logs.middleware.APIRequestLog.objects.create')
    def test_log_api_request_success(self, mock_create):
        """Test successful API request logging."""
        from django.http import HttpRequest, HttpResponse
        
        request = HttpRequest()
        request.method = 'GET'
        request.path = '/api/test/'
        request.user = self.user
        request.GET = {'q': 'search'}
        request.META['REMOTE_ADDR'] = '127.0.0.1'
        request.META['HTTP_USER_AGENT'] = 'Test Agent'
        request._api_logging_start_time = time.time() - 0.1  # 100ms ago
        
        def mock_build_absolute_uri():
            return 'http://testserver/api/test/?q=search'
        
        request.build_absolute_uri = mock_build_absolute_uri
        
        response = HttpResponse('{"success": true}', content_type='application/json')
        response.status_code = 200
        
        self.middleware._log_api_request(request, response)
        
        mock_create.assert_called_once()
        call_kwargs = mock_create.call_args[1]
        
        self.assertEqual(call_kwargs['method'], 'GET')
        self.assertEqual(call_kwargs['path'], '/api/test/')
        self.assertEqual(call_kwargs['status_code'], 200)
        self.assertEqual(call_kwargs['user'], self.user)
        self.assertGreater(call_kwargs['duration_ms'], 90)  # Should be around 100ms


class PerformanceLoggingMiddlewareTest(TestCase):
    """Test cases for PerformanceLoggingMiddleware."""
    
    def setUp(self):
        # Mock get_response for middleware
        self.get_response = MagicMock()
        self.middleware = PerformanceLoggingMiddleware(self.get_response)
    
    @patch('app_logs.models.PerformanceLog.objects.create')
    def test_log_slow_request(self, mock_create):
        """Test logging of slow requests."""
        from django.http import HttpRequest, HttpResponse
        
        request = HttpRequest()
        request.method = 'GET'
        request.path = '/api/slow/'
        request.user = User.objects.create_user('testuser', 'test@test.com', 'pass')
        
        response = HttpResponse()
        response.status_code = 200
        
        # Simulate a slow request (3 seconds)
        self.middleware._log_slow_request(request, response, 3.0)
        
        mock_create.assert_called_once()
        call_kwargs = mock_create.call_args[1]
        
        self.assertEqual(call_kwargs['metric_name'], 'response_time')
        self.assertEqual(call_kwargs['metric_value'], 3000.0)  # 3 seconds in ms
        self.assertEqual(call_kwargs['metric_unit'], 'ms')
        self.assertTrue(call_kwargs['threshold_exceeded'])
        self.assertEqual(call_kwargs['severity'], 'WARNING')


class ModelManagersAndQuerysetsTest(TestCase):
    """Test custom managers and querysets for logging models."""
    
    def setUp(self):
        self.user = User.objects.create_user(
            username='testuser',
            email='test@example.com',
            password='testpass123'
        )
        
        # Create test data
        self.create_test_logs()
    
    def create_test_logs(self):
        """Create test log data."""
        # API Request Logs
        APIRequestLog.objects.create(
            method='GET', path='/api/success/', full_url='http://test.com/api/success/',
            status_code=200, duration_ms=50, user=self.user
        )
        APIRequestLog.objects.create(
            method='GET', path='/api/error/', full_url='http://test.com/api/error/',
            status_code=404, duration_ms=25
        )
        APIRequestLog.objects.create(
            method='POST', path='/api/server-error/', full_url='http://test.com/api/server-error/',
            status_code=500, duration_ms=200, user=self.user
        )
        
        # Error Logs
        ErrorLog.objects.create(
            error_type='ValueError', error_message='Test error 1',
            user=self.user, is_resolved=False
        )
        ErrorLog.objects.create(
            error_type='TypeError', error_message='Test error 2',
            is_resolved=True, resolved_by=self.user, resolved_at=timezone.now()
        )
        
        # Performance Logs
        PerformanceLog.objects.create(
            metric_name='response_time', metric_value=1500, metric_unit='ms',
            operation='GET /api/slow/', threshold_exceeded=False
        )
        PerformanceLog.objects.create(
            metric_name='response_time', metric_value=3000, metric_unit='ms',
            operation='POST /api/very-slow/', threshold_exceeded=True
        )
    
    def test_api_request_log_filtering(self):
        """Test filtering API request logs."""
        successful_requests = APIRequestLog.objects.filter(status_code__lt=400)
        self.assertEqual(successful_requests.count(), 1)
        
        error_requests = APIRequestLog.objects.filter(status_code__gte=400)
        self.assertEqual(error_requests.count(), 2)
        
        user_requests = APIRequestLog.objects.filter(user=self.user)
        self.assertEqual(user_requests.count(), 2)
    
    def test_error_log_filtering(self):
        """Test filtering error logs."""
        unresolved_errors = ErrorLog.objects.filter(is_resolved=False)
        self.assertEqual(unresolved_errors.count(), 1)
        
        resolved_errors = ErrorLog.objects.filter(is_resolved=True)
        self.assertEqual(resolved_errors.count(), 1)
        
        user_errors = ErrorLog.objects.filter(user=self.user)
        self.assertEqual(user_errors.count(), 1)
    
    def test_performance_log_filtering(self):
        """Test filtering performance logs."""
        slow_requests = PerformanceLog.objects.filter(threshold_exceeded=True)
        self.assertEqual(slow_requests.count(), 1)
        
        normal_requests = PerformanceLog.objects.filter(threshold_exceeded=False)
        self.assertEqual(normal_requests.count(), 1)


class LoggingIntegrationTest(TestCase):
    """Integration tests for the logging system."""
    
    def setUp(self):
        self.client = Client()
        self.user = User.objects.create_user(
            username='testuser',
            email='test@example.com',
            password='testpass123'
        )
    
    def test_api_request_logging_integration(self):
        """Test that API requests are actually logged by middleware."""
        # Clear any existing logs
        APIRequestLog.objects.all().delete()
        ApplicationLog.objects.all().delete()
        
        # Make a request that should be logged
        self.client.force_login(self.user)
        response = self.client.get('/product-requests/requests/')
        
        # Check that the API request was logged
        api_logs = APIRequestLog.objects.all()
        self.assertGreater(api_logs.count(), 0)
        
        # Check the first API log entry
        api_log = api_logs.first()
        self.assertEqual(api_log.method, 'GET')
        self.assertEqual(api_log.path, '/product-requests/requests/')
        self.assertEqual(api_log.user, self.user)
        self.assertIsNotNone(api_log.duration_ms)
        self.assertIsNotNone(api_log.timestamp)
        
        # Check that the Application log was also created
        app_logs = ApplicationLog.objects.all()
        self.assertGreater(app_logs.count(), 0)
        
        # Check the first Application log entry
        app_log = app_logs.first()
        self.assertEqual(app_log.category, 'product_requests')
        self.assertEqual(app_log.subcategory, 'list_requests')
        self.assertEqual(app_log.user, self.user)
        self.assertEqual(app_log.event_type, EventType.API_REQUEST)
        self.assertIn('Successful GET request', app_log.message)
        self.assertIsNotNone(app_log.context_data)
        
        # Verify context data contains expected fields
        context = app_log.context_data
        self.assertEqual(context['method'], 'GET')
        self.assertEqual(context['path'], '/product-requests/requests/')
        self.assertEqual(context['status_code'], 200)
        self.assertIn('response_time_ms', context)
        self.assertEqual(context['username'], self.user.username)
        self.assertEqual(context['user_id'], self.user.id)
    
    def test_error_logging_integration(self):
        """Test that errors are logged when exceptions occur."""
        # This would require a view that raises an exception
        # For now, we'll test direct error logging
        
        # Clear any existing error logs
        ErrorLog.objects.all().delete()
        
        # Create an error log directly
        ErrorLog.objects.create(
            error_type='TestError',
            error_message='Integration test error',
            path='/api/test/',
            method='GET',
            user=self.user
        )
        
        # Verify the error was logged
        errors = ErrorLog.objects.all()
        self.assertEqual(errors.count(), 1)
        
        error = errors.first()
        self.assertEqual(error.error_type, 'TestError')
        self.assertEqual(error.user, self.user)
    
    def test_manual_logging_utilities(self):
        """Test the manual logging utility functions."""
        from .utils import (
            log_user_action, log_authentication_event, log_product_request_event,
            log_category_event, log_data_change, log_system_event
        )
        
        # Clear existing logs
        ApplicationLog.objects.all().delete()
        ProductRequestLog.objects.all().delete()
        CategoryLog.objects.all().delete()
        
        # Test user action logging
        log_user_action(
            user=self.user,
            action='profile_update',
            message='User updated profile',
            field='email',
            old_value='old@test.com',
            new_value='new@test.com'
        )
        
        # Test authentication event logging
        log_authentication_event(
            user=self.user,
            event_type='login',
            success=True,
            ip_address='192.168.1.100',
            user_agent='Test Browser'
        )
        
        # Test product request event logging
        log_product_request_event(
            product_request_id='12345',
            action='created',
            user=self.user,
            details={'title': 'Test Product', 'category': 'Electronics'}
        )
        
        # Test category event logging  
        log_category_event(
            category_id=1,
            event='accessed',
            user=self.user,
            event_data={'search_term': 'electronics'}
        )
        
        # Test data change logging
        log_data_change(
            model_name='Product',
            object_id=123,
            change_type='update',
            user=self.user,
            old_values={'name': 'Old Name', 'price': 100},
            new_values={'name': 'New Name', 'price': 150}
        )
        
        # Test system event logging
        log_system_event(
            event_type='maintenance_start',
            message='System maintenance started',
            scheduled_time='2024-01-01 02:00:00'
        )
        
        # Verify ApplicationLog entries were created (some functions create ApplicationLog, others create specialized logs)
        app_logs = ApplicationLog.objects.all().order_by('timestamp')
        self.assertGreaterEqual(app_logs.count(), 4)  # user_action, auth, data_change, system_event
        
        # Verify ProductRequestLog entry
        pr_logs = ProductRequestLog.objects.all()
        self.assertEqual(pr_logs.count(), 1)
        pr_log = pr_logs.first()
        self.assertEqual(pr_log.action, 'created')
        self.assertEqual(pr_log.user, self.user)
        self.assertEqual(pr_log.product_request_id, '12345')
        
        # Verify CategoryLog entry
        cat_logs = CategoryLog.objects.all()
        self.assertEqual(cat_logs.count(), 1)
        cat_log = cat_logs.first()
        self.assertEqual(cat_log.event, 'accessed')
        self.assertEqual(cat_log.user, self.user)
        self.assertEqual(cat_log.category_id, 1)
        
        # Verify specific ApplicationLog entries
        user_action_log = app_logs.filter(event_type=EventType.USER_ACTION).first()
        self.assertIsNotNone(user_action_log)
        self.assertEqual(user_action_log.user, self.user)
        self.assertEqual(user_action_log.category, 'user_action')
        self.assertIn('profile', user_action_log.message)
        
        auth_log = app_logs.filter(event_type=EventType.AUTHENTICATION).first()
        self.assertIsNotNone(auth_log)
        self.assertEqual(auth_log.user, self.user)
        self.assertEqual(auth_log.ip_address, '192.168.1.100')
        
        data_change_log = app_logs.filter(event_type=EventType.DATA_CHANGE).first()
        self.assertIsNotNone(data_change_log)
        self.assertEqual(data_change_log.user, self.user)
        self.assertIn('Product', data_change_log.message)
        
        system_log = app_logs.filter(event_type=EventType.SYSTEM_EVENT).first()
        self.assertIsNotNone(system_log)
        self.assertIn('maintenance', system_log.message)
    
    def test_application_logger_context_manager(self):
        """Test the ApplicationLogger context manager."""
        from .utils import ApplicationLogger
        
        # Clear existing logs
        ApplicationLog.objects.all().delete()
        
        # Use the context manager
        with ApplicationLogger(
            user=self.user,
            category='test_operations',
            ip_address='127.0.0.1'
        ) as logger:
            logger.info('Starting test operation')
            logger.warning('This is a warning during operation')
            logger.error('This is an error during operation')
        
        # Verify logs were created
        app_logs = ApplicationLog.objects.all().order_by('timestamp')
        self.assertEqual(app_logs.count(), 3)
        
        # Check individual log entries
        info_log = app_logs.filter(level=LogLevel.INFO).first()
        self.assertIsNotNone(info_log)
        self.assertEqual(info_log.category, 'test_operations')
        self.assertEqual(info_log.user, self.user)
        self.assertIn('Starting test operation', info_log.message)
        
        warning_log = app_logs.filter(level=LogLevel.WARNING).first()
        self.assertIsNotNone(warning_log)
        self.assertIn('warning during operation', warning_log.message)
        
        error_log = app_logs.filter(level=LogLevel.ERROR).first()
        self.assertIsNotNone(error_log)
        self.assertIn('error during operation', error_log.message)


class LogRetentionAndCleanupTest(TestCase):
    """Test log retention and cleanup functionality."""
    
    def setUp(self):
        self.user = User.objects.create_user(
            username='testuser',
            email='test@example.com',
            password='testpass123'
        )
    
    def test_old_log_cleanup(self):
        """Test cleanup of old log entries."""
        # Create old logs (91 days ago)
        old_timestamp = timezone.now() - timedelta(days=91)
        
        old_log = APIRequestLog.objects.create(
            method='GET', path='/api/old/', full_url='http://test.com/api/old/',
            status_code=200, duration_ms=50
        )
        old_log.timestamp = old_timestamp
        old_log.save()
        
        # Create recent log
        recent_log = APIRequestLog.objects.create(
            method='GET', path='/api/recent/', full_url='http://test.com/api/recent/',
            status_code=200, duration_ms=50
        )
        
        # Verify both logs exist
        self.assertEqual(APIRequestLog.objects.count(), 2)
        
        # Simulate cleanup (90 days retention)
        cutoff_date = timezone.now() - timedelta(days=90)
        APIRequestLog.objects.filter(timestamp__lt=cutoff_date).delete()
        
        # Verify old log was deleted
        self.assertEqual(APIRequestLog.objects.count(), 1)
        self.assertTrue(APIRequestLog.objects.filter(id=recent_log.id).exists())
        self.assertFalse(APIRequestLog.objects.filter(id=old_log.id).exists())
