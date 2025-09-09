from django.core.management.base import BaseCommand, CommandError
from sms_portal.services import SMSPortalService
from sms_portal.models import SMSPortalConfig


class Command(BaseCommand):
    help = 'Test SMS sending functionality'

    def add_arguments(self, parser):
        parser.add_argument(
            '--phone',
            type=str,
            required=True,
            help='Phone number to send test SMS to'
        )
        parser.add_argument(
            '--message',
            type=str,
            default='Test message from BIDR. SMS integration is working!',
            help='Message to send (optional)'
        )
        parser.add_argument(
            '--template',
            type=str,
            help='Template name to use (optional)'
        )
        parser.add_argument(
            '--dry-run',
            action='store_true',
            help='Perform a dry run without actually sending SMS'
        )

    def handle(self, *args, **options):
        phone_number = options['phone']
        message = options['message']
        template_name = options.get('template')
        dry_run = options['dry_run']
        
        self.stdout.write('Testing SMS sending functionality...\n')
        
        # Check SMS Portal configuration
        try:
            config = SMSPortalConfig.objects.get(name="SMS Portal", is_active=True)
            self.stdout.write(f'✓ SMS Portal configuration found: {config.name}')
            self.stdout.write(f'  - API URL: {config.api_url}')
            self.stdout.write(f'  - Sender ID: {config.default_sender_id}')
            self.stdout.write(f'  - Rate limit: {config.rate_limit_per_minute}/min')
        except SMSPortalConfig.DoesNotExist:
            raise CommandError(
                'SMS Portal configuration not found or not active. '
                'Run: python manage.py create_sms_templates'
            )
        
        if not config.api_key or not config.api_secret:
            raise CommandError(
                'SMS Portal API credentials not configured. '
                'Please set SMS_PORTAL_API_KEY and SMS_PORTAL_API_SECRET environment variables '
                'or update the configuration in Django admin.'
            )
        
        # Initialize SMS service
        try:
            sms_service = SMSPortalService()
            self.stdout.write('✓ SMS service initialized successfully')
        except Exception as e:
            raise CommandError(f'Failed to initialize SMS service: {str(e)}')
        
        # Test account balance
        self.stdout.write('\n--- Account Balance ---')
        balance_info = sms_service.get_account_balance()
        if balance_info:
            self.stdout.write(f'✓ Account balance retrieved: {balance_info}')
        else:
            self.stdout.write(self.style.WARNING('⚠ Could not retrieve account balance'))
        
        # Prepare message
        if template_name:
            from sms_portal.models import SMSTemplate
            try:
                template = SMSTemplate.objects.get(name=template_name, is_active=True)
                context = {
                    'code': '123456',
                    'amount': '$50.00',
                    'transaction_id': 'TXN123456',
                    'order_id': 'ORDER123',
                    'status': 'confirmed',
                    'message': 'Your order is ready',
                    'product_name': 'Test Product',
                    'rating': '5',
                    'date': '2025-01-01',
                    'start_time': '02:00',
                    'end_time': '04:00'
                }
                message = template.render_content(context)
                self.stdout.write(f'✓ Using template: {template_name}')
            except SMSTemplate.DoesNotExist:
                raise CommandError(f'Template "{template_name}" not found or not active')
        
        self.stdout.write(f'\n--- Test Message Details ---')
        self.stdout.write(f'Phone: {phone_number}')
        self.stdout.write(f'Message: {message}')
        self.stdout.write(f'Message length: {len(message)} characters')
        
        if dry_run:
            self.stdout.write(self.style.SUCCESS('\nDRY RUN - Message not sent'))
            return
        
        # Send SMS
        self.stdout.write('\n--- Sending SMS ---')
        try:
            if template_name:
                success, sms_message = sms_service.send_otp_sms(
                    phone_number=phone_number,
                    otp_code='123456',
                    template_name=template_name
                )
            else:
                success, sms_message = sms_service.send_sms(
                    phone_number=phone_number,
                    message=message,
                    message_type='system'
                )
            
            if success:
                self.stdout.write(self.style.SUCCESS(f'✓ SMS sent successfully!'))
                self.stdout.write(f'  - SMS ID: {sms_message.id}')
                self.stdout.write(f'  - External ID: {sms_message.external_message_id}')
                self.stdout.write(f'  - Status: {sms_message.status}')
                if sms_message.cost:
                    self.stdout.write(f'  - Cost: {sms_message.cost}')
                
                # Check status after a moment
                import time
                time.sleep(2)
                
                self.stdout.write('\n--- Checking Message Status ---')
                if sms_message.external_message_id:
                    status_info = sms_service.check_message_status(sms_message.external_message_id)
                    if status_info:
                        self.stdout.write(f'✓ Status: {status_info}')
                    else:
                        self.stdout.write('⚠ Could not retrieve message status')
            else:
                self.stdout.write(self.style.ERROR(f'✗ Failed to send SMS'))
                self.stdout.write(f'  - Error: {sms_message.error_message}')
                self.stdout.write(f'  - Error code: {sms_message.error_code}')
        
        except Exception as e:
            raise CommandError(f'Error sending SMS: {str(e)}')
        
        # Usage statistics
        self.stdout.write('\n--- Usage Statistics ---')
        from sms_portal.models import SMSUsageStats
        from django.utils import timezone
        
        today = timezone.now().date()
        stats = SMSUsageStats.objects.filter(date=today).first()
        
        if stats:
            self.stdout.write(f'Today\'s SMS usage:')
            self.stdout.write(f'  - Total sent: {stats.total_sent}')
            self.stdout.write(f'  - Total delivered: {stats.total_delivered}')
            self.stdout.write(f'  - Total failed: {stats.total_failed}')
            self.stdout.write(f'  - Delivery rate: {stats.delivery_rate:.1f}%')
            self.stdout.write(f'  - Total cost: {stats.total_cost}')
        else:
            self.stdout.write('No usage statistics available for today')
        
        self.stdout.write(self.style.SUCCESS('\nSMS test completed!'))