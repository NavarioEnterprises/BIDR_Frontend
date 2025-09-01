from django.core.management.base import BaseCommand
from sms_portal.models import SMSTemplate, SMSPortalConfig


class Command(BaseCommand):
    help = 'Create default SMS templates and configuration'

    def handle(self, *args, **options):
        self.stdout.write('Creating default SMS templates and configuration...')
        
        # Create default SMS Portal configuration
        config, created = SMSPortalConfig.objects.get_or_create(
            name="SMS Portal",
            defaults={
                'api_url': 'https://rest.smsportal.com/v1',
                'api_key': '',  # To be filled in via admin or environment
                'api_secret': '',  # To be filled in via admin or environment
                'default_sender_id': 'BIDR',
                'is_active': False,  # Will be activated when API credentials are added
                'rate_limit_per_minute': 100,
            }
        )
        
        if created:
            self.stdout.write(
                self.style.SUCCESS(f'✓ Created SMS Portal configuration: {config.name}')
            )
        else:
            self.stdout.write(f'SMS Portal configuration already exists: {config.name}')
        
        # Create SMS templates
        templates = [
            {
                'name': 'otp_verification',
                'content': 'Your BIDR verification code is: {code}. Valid for 5 minutes. Do not share this code.',
                'message_type': 'otp',
            },
            {
                'name': 'otp_welcome',
                'content': 'Welcome to BIDR! Your verification code is: {code}. Use this to complete your registration.',
                'message_type': 'otp',
            },
            {
                'name': 'payment_success',
                'content': 'Payment successful! Amount: {amount}. Transaction ID: {transaction_id}. Thank you for using BIDR.',
                'message_type': 'notification',
            },
            {
                'name': 'payment_failed',
                'content': 'Payment failed for amount {amount}. Please try again or contact support. Transaction ID: {transaction_id}.',
                'message_type': 'alert',
            },
            {
                'name': 'order_update',
                'content': 'Order #{order_id} status updated to: {status}. {message}',
                'message_type': 'notification',
            },
            {
                'name': 'security_alert',
                'content': 'BIDR Security Alert: {message}. If this wasn\'t you, please secure your account immediately.',
                'message_type': 'alert',
            },
            {
                'name': 'account_locked',
                'content': 'Your BIDR account has been temporarily locked due to multiple failed login attempts. Please reset your password or contact support.',
                'message_type': 'alert',
            },
            {
                'name': 'password_reset',
                'content': 'Your BIDR password reset code is: {code}. Valid for 15 minutes.',
                'message_type': 'system',
            },
            {
                'name': 'welcome_message',
                'content': 'Welcome to BIDR! Your account has been successfully created. Start exploring our marketplace today.',
                'message_type': 'system',
            },
            {
                'name': 'review_received',
                'content': 'You have received a new review for {product_name}. Rating: {rating} stars. Check your dashboard for details.',
                'message_type': 'notification',
            },
            {
                'name': 'dispute_created',
                'content': 'A dispute has been created for order #{order_id}. Please provide additional information within 48 hours.',
                'message_type': 'alert',
            },
            {
                'name': 'system_maintenance',
                'content': 'BIDR will undergo maintenance on {date} from {start_time} to {end_time}. Some services may be temporarily unavailable.',
                'message_type': 'system',
            }
        ]
        
        created_count = 0
        updated_count = 0
        
        for template_data in templates:
            template, created = SMSTemplate.objects.get_or_create(
                name=template_data['name'],
                defaults=template_data
            )
            
            if created:
                created_count += 1
                self.stdout.write(
                    self.style.SUCCESS(f'✓ Created template: {template.name}')
                )
            else:
                # Update existing template if content is different
                if template.content != template_data['content']:
                    template.content = template_data['content']
                    template.message_type = template_data['message_type']
                    template.save()
                    updated_count += 1
                    self.stdout.write(
                        self.style.WARNING(f'Updated template: {template.name}')
                    )
                else:
                    self.stdout.write(f'Template already exists: {template.name}')
        
        # Summary
        self.stdout.write('\n' + '='*50)
        self.stdout.write(self.style.SUCCESS(f'SMS Templates Summary:'))
        self.stdout.write(self.style.SUCCESS(f'✓ Created: {created_count} templates'))
        self.stdout.write(self.style.SUCCESS(f'✓ Updated: {updated_count} templates'))
        self.stdout.write(self.style.SUCCESS(f'✓ Total: {SMSTemplate.objects.count()} templates'))
        
        # Instructions
        self.stdout.write('\n' + self.style.WARNING('Next steps:'))
        self.stdout.write('1. Add SMS Portal API credentials via Django admin or environment variables:')
        self.stdout.write('   - SMS_PORTAL_API_KEY')
        self.stdout.write('   - SMS_PORTAL_API_SECRET')
        self.stdout.write('2. Activate SMS Portal configuration in admin panel')
        self.stdout.write('3. Test SMS sending with: python manage.py test_sms_sending')
        
        self.stdout.write(self.style.SUCCESS('\nSMS templates and configuration setup complete!'))