"""
Tests for the analytics app
"""
from datetime import timedelta, datetime
from django.test import TestCase
from django.urls import reverse
from django.utils import timezone
from rest_framework import status
from rest_framework.test import APITestCase, APIClient

from user.models import AppUser
from .models import AuthenticationMetric, UserBehaviorAnalytics, SystemPerformanceMetric


class AuthenticationMetricModelTest(TestCase):
    """Test cases for AuthenticationMetric model"""
    
    def setUp(self):
        self.user = AppUser.objects.create_user(
            email='test@example.com',
            password='testpass123',
            first_name='John',
            last_name='Doe',
            phone_number='+1234567890',
            role='buyer'
        )
        
    def test_create_authentication_metric(self):
        """Test creating authentication metric"""
        now = timezone.now()
        metric = AuthenticationMetric.objects.create(
            name='login_attempts',
            category='authentication',
            metric_type='counter',
            value=10.0,
            unit='requests',
            period='hour',
            timestamp=now,
            period_start=now,
            period_end=now + timedelta(hours=1)
        )
        self.assertEqual(metric.name, 'login_attempts')
        self.assertEqual(metric.value, 10.0)
        self.assertEqual(metric.category, 'authentication')
        
    def test_authentication_metric_str_method(self):
        """Test AuthenticationMetric string representation"""
        now = timezone.now()
        metric = AuthenticationMetric.objects.create(
            name='failed_logins',
            category='security',
            metric_type='counter',
            value=5.0,
            unit='attempts',
            period='day',
            timestamp=now,
            period_start=now,
            period_end=now + timedelta(days=1)
        )
        expected_str = f"failed_logins: 5.0 attempts ({now})"
        self.assertEqual(str(metric), expected_str)


class UserBehaviorAnalyticsModelTest(TestCase):
    """Test cases for UserBehaviorAnalytics model"""
    
    def setUp(self):
        self.user = AppUser.objects.create_user(
            email='test@example.com',
            password='testpass123',
            first_name='John',
            last_name='Doe',
            phone_number='+1234567890',
            role='buyer'
        )
        
    def test_create_user_behavior_analytics(self):
        """Test creating user behavior analytics"""
        analytics = UserBehaviorAnalytics.objects.create(
            user=self.user,
            user_type='buyer',
            date=timezone.now().date(),
            login_count=10,
            successful_logins=8,
            failed_logins=2,
            session_count=5
        )
        self.assertEqual(analytics.user, self.user)
        self.assertEqual(analytics.login_count, 10)
        self.assertEqual(analytics.successful_logins, 8)
        
    def test_calculate_login_success_rate(self):
        """Test calculating login success rate"""
        analytics = UserBehaviorAnalytics.objects.create(
            user=self.user,
            user_type='buyer',
            date=timezone.now().date(),
            login_count=10,
            successful_logins=8,
            failed_logins=2
        )
        success_rate = analytics.calculate_login_success_rate()
        self.assertEqual(success_rate, 80.0)
        
    def test_calculate_login_success_rate_no_attempts(self):
        """Test success rate when no login attempts"""
        analytics = UserBehaviorAnalytics.objects.create(
            user=self.user,
            user_type='buyer',
            date=timezone.now().date(),
            login_count=0,
            successful_logins=0,
            failed_logins=0
        )
        success_rate = analytics.calculate_login_success_rate()
        self.assertEqual(success_rate, 0.0)


class SystemPerformanceMetricModelTest(TestCase):
    """Test cases for SystemPerformanceMetric model"""
    
    def test_create_system_performance_metric(self):
        """Test creating system performance metric"""
        now = timezone.now()
        metric = SystemPerformanceMetric.objects.create(
            metric_name='response_time',
            component='login_endpoint',
            response_time_avg=150.5,
            response_time_min=50.0,
            response_time_max=300.0,
            total_requests=100,
            successful_requests=95,
            failed_requests=5,
            error_rate=5.0,
            period='hour',
            timestamp=now,
            period_start=now,
            period_end=now + timedelta(hours=1)
        )
        self.assertEqual(metric.metric_name, 'response_time')
        self.assertEqual(metric.response_time_avg, 150.5)
        self.assertEqual(metric.total_requests, 100)
        
    def test_calculate_success_rate(self):
        """Test calculating success rate"""
        now = timezone.now()
        metric = SystemPerformanceMetric.objects.create(
            metric_name='api_performance',
            component='otp_service',
            response_time_avg=200.0,
            response_time_min=100.0,
            response_time_max=500.0,
            total_requests=100,
            successful_requests=90,
            failed_requests=10,
            error_rate=10.0,
            period='hour',
            timestamp=now,
            period_start=now,
            period_end=now + timedelta(hours=1)
        )
        success_rate = metric.calculate_success_rate()
        self.assertEqual(success_rate, 90.0)
