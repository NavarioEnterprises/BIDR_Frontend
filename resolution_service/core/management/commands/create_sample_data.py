from django.core.management.base import BaseCommand
from django.contrib.auth.models import User
from django.utils import timezone
from datetime import datetime, timedelta
from decimal import Decimal
import random

from core.models import UserProfile, SystemConfiguration, ServiceHealth, APIKey, TransactionReference
from reviews.models import Review, ReviewPhoto, ReviewResponse, ReviewHelpfulness, ReviewFlag, ReviewSummary
from returns.models import ReturnRequest, ReturnPhoto, ReturnShipping, ReturnEvaluation, ReturnPolicy
from disputes.models import (
    Dispute, DisputeMessage, DisputeEvidence, DisputeResolutionOffer,
    DisputeCategory, MediationSession, DisputeStatistics
)
from notifications_service.models import (
    NotificationTemplate, Notification, NotificationPreference,
    NotificationChannel, NotificationBatch
)
from logs.models import ActivityLog, SystemLog, APIRequestLog, SecurityLog


class Command(BaseCommand):
    help = 'Create sample data for testing the Resolution Service'

    def add_arguments(self, parser):
        parser.add_argument(
            '--clean',
            action='store_true',
            help='Clean existing data before creating sample data',
        )

    def handle(self, *args, **options):
        if options['clean']:
            self.stdout.write('Cleaning existing data...')
            self.clean_data()

        self.stdout.write('Creating sample data...')
        
        # Create users
        self.create_users()
        
        # Create core data
        self.create_core_data()
        
        # Create notification templates and preferences
        self.create_notification_data()
        
        # Create reviews data
        self.create_review_data()
        
        # Create returns data
        self.create_returns_data()
        
        # Create disputes data
        self.create_disputes_data()
        
        # Create logs data
        self.create_logs_data()

        self.stdout.write(
            self.style.SUCCESS('Successfully created sample data!')
        )

    def clean_data(self):
        """Clean existing data (except admin user)"""
        # Don't delete admin user, but clean other test users
        User.objects.filter(username__in=[
            'buyer_user', 'seller_user', 'mediator_user', 'test_user_1', 'test_user_2'
        ]).delete()

    def create_users(self):
        """Create test users"""
        self.stdout.write('Creating test users...')
        
        # Create buyer user
        self.buyer_user = User.objects.create_user(
            username='buyer_user',
            email='buyer@test.com',
            password='password123',
            first_name='John',
            last_name='Buyer'
        )
        
        # Create seller user
        self.seller_user = User.objects.create_user(
            username='seller_user',
            email='seller@test.com',
            password='password123',
            first_name='Jane',
            last_name='Seller'
        )
        
        # Create mediator user
        self.mediator_user = User.objects.create_user(
            username='mediator_user',
            email='mediator@test.com',
            password='password123',
            first_name='Mike',
            last_name='Mediator'
        )
        
        # Create additional test users
        self.test_users = []
        for i in range(1, 6):
            user = User.objects.create_user(
                username=f'test_user_{i}',
                email=f'test{i}@test.com',
                password='password123',
                first_name=f'Test{i}',
                last_name='User'
            )
            self.test_users.append(user)

    def create_core_data(self):
        """Create core application data"""
        self.stdout.write('Creating core data...')
        
        # Create user profiles
        UserProfile.objects.create(
            user=self.buyer_user,
            phone_number='+1234567890',
            is_verified=True,
            reputation_score=Decimal('4.5'),
            total_transactions=15,
            successful_transactions=14,
            dispute_count=1
        )
        
        UserProfile.objects.create(
            user=self.seller_user,
            phone_number='+0987654321',
            is_verified=True,
            reputation_score=Decimal('4.8'),
            total_transactions=25,
            successful_transactions=24,
            dispute_count=0
        )
        
        UserProfile.objects.create(
            user=self.mediator_user,
            phone_number='+1122334455',
            is_verified=True,
            reputation_score=Decimal('5.0'),
            total_transactions=0,
            successful_transactions=0,
            dispute_count=0
        )
        
        # Create system configurations
        SystemConfiguration.objects.create(
            key='max_return_days',
            value='30',
            description='Maximum days allowed for returns'
        )
        
        SystemConfiguration.objects.create(
            key='auto_escalate_disputes',
            value='true',
            description='Automatically escalate unresolved disputes'
        )
        
        SystemConfiguration.objects.create(
            key='review_moderation_enabled',
            value='true',
            description='Enable automatic review moderation'
        )
        
        # Create service health records
        ServiceHealth.objects.create(
            service_name='resolution_service',
            status='healthy',
            response_time=125.5
        )
        
        ServiceHealth.objects.create(
            service_name='notification_service',
            status='healthy',
            response_time=89.2
        )
        
        ServiceHealth.objects.create(
            service_name='external_email_service',
            status='warning',
            response_time=350.8,
            error_message='Slow response times detected'
        )
        
        # Create API keys
        APIKey.objects.create(
            name='Test API Key',
            key='test-api-key-12345',
            created_by=self.mediator_user,
            permissions=['read', 'write'],
            rate_limit=1000
        )
        
        APIKey.objects.create(
            name='Mobile API Key',
            key='mobile-api-key-67890',
            created_by=self.mediator_user,
            permissions=['read'],
            rate_limit=5000
        )
        
        # Create transaction references
        self.transactions = []
        for i in range(1, 11):
            transaction = TransactionReference.objects.create(
                transaction_id=f'TXN{2024000 + i}',
                service_name='payment_service',
                buyer_id=str(self.buyer_user.id),
                seller_id=str(self.seller_user.id),
                amount=Decimal(str(random.uniform(50.0, 500.0))),
                currency='USD',
                status=random.choice(['pending', 'completed', 'cancelled']),
                completed_at=timezone.now() - timedelta(days=random.randint(1, 30))
            )
            self.transactions.append(transaction)

    def create_notification_data(self):
        """Create notification-related data"""
        self.stdout.write('Creating notification data...')
        
        # Create notification templates
        NotificationTemplate.objects.create(
            name='Review Received',
            notification_type='review_received',
            subject_template='New Review on Your Transaction',
            body_template='You have received a new review for transaction {{transaction_id}}. Rating: {{rating}} stars.',
            send_email=True,
            send_push=True,
            priority='normal'
        )
        
        NotificationTemplate.objects.create(
            name='Return Request',
            notification_type='return_request_received',
            subject_template='New Return Request',
            body_template='A return request has been submitted for transaction {{transaction_id}}. Reason: {{reason}}',
            send_email=True,
            send_sms=False,
            send_push=True,
            priority='high'
        )
        
        NotificationTemplate.objects.create(
            name='Dispute Created',
            notification_type='dispute_created',
            subject_template='New Dispute Filed',
            body_template='A dispute has been filed for transaction {{transaction_id}}. Please respond within 72 hours.',
            send_email=True,
            send_push=True,
            priority='urgent'
        )
        
        # Create notification channels
        NotificationChannel.objects.create(
            name='SMTP Email',
            channel_type='email',
            config={'smtp_host': 'localhost', 'smtp_port': 587},
            is_active=True,
            rate_limit=100
        )
        
        NotificationChannel.objects.create(
            name='Push Notifications',
            channel_type='push',
            config={'provider': 'firebase', 'api_key': 'dummy_key'},
            is_active=True,
            rate_limit=1000
        )
        
        # Create notification preferences
        for user in [self.buyer_user, self.seller_user]:
            NotificationPreference.objects.create(
                user=user,
                email_enabled=True,
                push_enabled=True,
                sms_enabled=False,
                quiet_hours_enabled=True,
                type_preferences={
                    'review_received': {'email': True, 'push': True},
                    'return_request': {'email': True, 'push': True},
                    'dispute_created': {'email': True, 'push': True}
                }
            )

    def create_review_data(self):
        """Create review-related data"""
        self.stdout.write('Creating review data...')
        
        # Create reviews
        for i, transaction in enumerate(self.transactions[:5]):
            review = Review.objects.create(
                transaction=transaction,
                reviewer=self.buyer_user,
                reviewed_user=self.seller_user,
                rating=random.randint(3, 5),
                title=f'Great transaction #{i+1}',
                content=f'The seller was very helpful and the item was as described. Transaction {transaction.transaction_id} went smoothly.',
                communication_rating=random.randint(4, 5),
                product_quality_rating=random.randint(3, 5),
                delivery_rating=random.randint(3, 5),
                is_verified=True
            )
            
            # Create review response
            if random.choice([True, False]):
                ReviewResponse.objects.create(
                    review=review,
                    responder=self.seller_user,
                    content='Thank you for your review! We appreciate your business.'
                )
            
            # Create helpfulness votes
            for user in self.test_users[:3]:
                ReviewHelpfulness.objects.create(
                    review=review,
                    user=user,
                    is_helpful=random.choice([True, False])
                )
        
        # Create review summaries
        ReviewSummary.objects.create(
            user=self.buyer_user,
            reviews_given_count=5,
            avg_rating_given=Decimal('4.2'),
            reviews_received_count=0,
            avg_rating_received=Decimal('0.00')
        )
        
        ReviewSummary.objects.create(
            user=self.seller_user,
            reviews_given_count=0,
            avg_rating_given=Decimal('0.00'),
            reviews_received_count=5,
            avg_rating_received=Decimal('4.2'),
            five_star_count=2,
            four_star_count=2,
            three_star_count=1
        )

    def create_returns_data(self):
        """Create return-related data"""
        self.stdout.write('Creating returns data...')
        
        # Create return policy
        return_policy = ReturnPolicy.objects.create(
            name='Standard Return Policy',
            description='Standard 30-day return policy for all items',
            return_period_days=30,
            restocking_fee_percent=Decimal('5.00'),
            who_pays_shipping='buyer',
            requires_original_packaging=True,
            allows_used_items=True,
            applicable_categories=['electronics', 'clothing', 'books']
        )
        
        # Create return requests
        for transaction in self.transactions[5:8]:
            return_request = ReturnRequest.objects.create(
                transaction=transaction,
                buyer=self.buyer_user,
                seller=self.seller_user,
                reason='not_as_described',
                description='Item was not as described in the listing.',
                requested_outcome='full_refund',
                status='pending',
                return_deadline=timezone.now() + timedelta(days=25)
            )
            
            # Create return shipping info
            ReturnShipping.objects.create(
                return_request=return_request,
                return_address='123 Seller St, City, ST 12345',
                carrier='UPS',
                tracking_number=f'1Z999AA1{random.randint(100000000, 999999999)}',
                paid_by='buyer'
            )

    def create_disputes_data(self):
        """Create dispute-related data"""
        self.stdout.write('Creating disputes data...')
        
        # Create dispute categories
        DisputeCategory.objects.create(
            name='Item Not Received',
            description='Buyer claims they did not receive the item',
            auto_escalate_hours=72,
            requires_evidence=True,
            default_priority='high'
        )
        
        DisputeCategory.objects.create(
            name='Item Not as Described',
            description='Item received does not match the description',
            auto_escalate_hours=96,
            requires_evidence=True,
            default_priority='medium'
        )
        
        # Create disputes
        for transaction in self.transactions[8:10]:
            dispute = Dispute.objects.create(
                transaction=transaction,
                complainant=self.buyer_user,
                respondent=self.seller_user,
                dispute_type='not_as_described',
                subject='Item not matching description',
                description='The item I received does not match what was shown in the photos.',
                desired_resolution='I would like a full refund or replacement item.',
                status='open',
                priority='medium',
                disputed_amount=transaction.amount,
                auto_escalate_at=timezone.now() + timedelta(hours=72)
            )
            
            # Create dispute messages
            DisputeMessage.objects.create(
                dispute=dispute,
                sender=self.buyer_user,
                message='I received the item but it looks nothing like the photos. The quality is very poor.'
            )
            
            DisputeMessage.objects.create(
                dispute=dispute,
                sender=self.seller_user,
                message='I apologize for the issue. Can you please provide photos so I can see the problem?'
            )
            
            # Create resolution offer
            DisputeResolutionOffer.objects.create(
                dispute=dispute,
                offered_by=self.seller_user,
                offer_type='partial_refund',
                offer_amount=transaction.amount * Decimal('0.5'),
                description='I can offer a 50% refund for the inconvenience.',
                status='pending',
                expires_at=timezone.now() + timedelta(days=3)
            )
        
        # Create dispute statistics
        DisputeStatistics.objects.create(
            date=timezone.now().date(),
            total_disputes=2,
            new_disputes=2,
            resolved_disputes=0,
            escalated_disputes=0,
            partial_refunds=1,
            avg_resolution_time=0
        )

    def create_logs_data(self):
        """Create log-related data"""
        self.stdout.write('Creating logs data...')
        
        # Create activity logs
        activities = [
            ('User login', 'authentication', 'User logged in successfully'),
            ('Review created', 'review', 'User created a new review'),
            ('Return requested', 'return', 'User initiated a return request'),
            ('Dispute filed', 'dispute', 'User filed a dispute'),
            ('Notification sent', 'notification', 'Email notification sent'),
        ]
        
        for i, (action, category, description) in enumerate(activities):
            ActivityLog.objects.create(
                user=random.choice([self.buyer_user, self.seller_user]),
                action=action,
                category=category,
                description=description,
                ip_address='127.0.0.1',
                user_agent='Mozilla/5.0 (Test Browser)',
                request_method='POST',
                request_path=f'/api/v1/test/{i+1}/',
                success=True
            )
        
        # Create system logs
        SystemLog.objects.create(
            level='INFO',
            logger_name='django.request',
            message='Sample data creation completed successfully',
            module='management.commands.create_sample_data'
        )
        
        # Create API request logs
        for i in range(5):
            APIRequestLog.objects.create(
                method='GET',
                path=f'/api/v1/test/{i+1}/',
                status_code=200,
                processing_time=random.uniform(50, 200),
                ip_address='127.0.0.1',
                user_agent='Test Client',
                user=random.choice([self.buyer_user, self.seller_user])
            )
        
        # Create security logs
        SecurityLog.objects.create(
            event_type='login_success',
            user=self.buyer_user,
            ip_address='127.0.0.1',
            description='Successful login attempt',
            severity='low'
        )
        
        SecurityLog.objects.create(
            event_type='suspicious_activity',
            ip_address='192.168.1.100',
            description='Multiple failed login attempts detected',
            severity='medium'
        )
