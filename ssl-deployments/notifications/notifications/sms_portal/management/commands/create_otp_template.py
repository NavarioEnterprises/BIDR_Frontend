from django.core.management.base import BaseCommand
from django.utils import timezone
from sms_portal.models import SMSTemplate


class Command(BaseCommand):
    help = 'Create OTP SMS template'

    def handle(self, *args, **kwargs):
        # Create or update OTP verification template
        template, created = SMSTemplate.objects.update_or_create(
            name='otp_verification',
            defaults={
                'message_type': 'otp',
                'content': 'Your BIDR verification code is: {code}. Valid for 5 minutes.',
                'description': 'Standard OTP verification message',
                'is_active': True,
                'sender_id': 'BIDR',
                'character_limit': 160
            }
        )
        
        if created:
            self.stdout.write(self.style.SUCCESS(f'Created OTP template: {template.name}'))
        else:
            self.stdout.write(self.style.SUCCESS(f'Updated OTP template: {template.name}'))
        
        # Create additional OTP templates
        templates = [
            {
                'name': 'otp_welcome',
                'content': 'Welcome to BIDR! Your verification code is: {code}. Valid for 5 minutes.',
                'description': 'Welcome OTP for new users'
            },
            {
                'name': 'password_reset',
                'content': 'Your BIDR password reset code is: {code}. Valid for 5 minutes. Do not share this code.',
                'description': 'Password reset OTP'
            }
        ]
        
        for template_data in templates:
            template, created = SMSTemplate.objects.update_or_create(
                name=template_data['name'],
                defaults={
                    'message_type': 'otp',
                    'content': template_data['content'],
                    'description': template_data['description'],
                    'is_active': True,
                    'sender_id': 'BIDR',
                    'character_limit': 160
                }
            )
            
            if created:
                self.stdout.write(self.style.SUCCESS(f'Created template: {template.name}'))
            else:
                self.stdout.write(self.style.SUCCESS(f'Updated template: {template.name}'))
        
        self.stdout.write(self.style.SUCCESS('OTP templates created successfully!'))