#!/usr/bin/env python3
"""
Django management command to create service-specific superuser
Place this in: <service>/management/commands/create_service_superuser.py
"""
import os
from django.contrib.auth import get_user_model
from django.core.management.base import BaseCommand
from django.db import IntegrityError

class Command(BaseCommand):
    help = 'Create superuser for the specific microservice'
    
    def add_arguments(self, parser):
        parser.add_argument(
            '--service',
            type=str,
            help='Service name (auth, chat, payment, etc.)',
        )
        parser.add_argument(
            '--force',
            action='store_true',
            help='Force create even if user exists (will update password)',
        )
    
    def handle(self, *args, **options):
        User = get_user_model()
        
        # Service-specific credentials (passwords from Azure Key Vault)
        credentials = {
            'auth': {
                'username': 'auth_admin',
                'password': 'Tc_tYOQZt)>84A3M',
                'email': 'auth.admin@bidr.co.za',
                'first_name': 'Auth',
                'last_name': 'Admin'
            },
            'chat': {
                'username': 'chat_admin',
                'password': '$$:_yCg}6pSOcH*u',
                'email': 'chat.admin@bidr.co.za',
                'first_name': 'Chat',
                'last_name': 'Admin'
            },
            'payment': {
                'username': 'payment_admin',
                'password': 'qF{OK_*B>Id!PuB}',
                'email': 'payment.admin@bidr.co.za',
                'first_name': 'Payment',
                'last_name': 'Admin'
            },
            'resolution': {
                'username': 'resolution_admin',
                'password': 'vqL1-t)#X{zOOEf>',
                'email': 'resolution.admin@bidr.co.za',
                'first_name': 'Resolution',
                'last_name': 'Admin'
            },
            'product': {
                'username': 'product_admin',
                'password': 'd_<!?8zm0Pv?nbA9',
                'email': 'product.admin@bidr.co.za',
                'first_name': 'Product',
                'last_name': 'Admin'
            },
            'notifications': {
                'username': 'notifications_admin',
                'password': 'xYWKA<_r]p3tqlNy',
                'email': 'notifications.admin@bidr.co.za',
                'first_name': 'Notifications',
                'last_name': 'Admin'
            },
            'transactions': {
                'username': 'transactions_admin',
                'password': 'Vi0)$>amuaIP4RS',
                'email': 'transactions.admin@bidr.co.za',
                'first_name': 'Transactions',
                'last_name': 'Admin'
            },
            'reviews': {
                'username': 'reviews_admin',
                'password': ':lO#qUghyQiJ+b&d',
                'email': 'reviews.admin@bidr.co.za',
                'first_name': 'Reviews',
                'last_name': 'Admin'
            }
        }
        
        # Get service name from argument or environment variable
        service_name = options.get('service') or os.environ.get('SERVICE_NAME')
        
        if not service_name:
            self.stdout.write(
                self.style.ERROR(
                    'Service name not provided. Use --service argument or set SERVICE_NAME environment variable'
                )
            )
            return
        
        if service_name not in credentials:
            self.stdout.write(
                self.style.ERROR(
                    f'Unknown service: {service_name}. Available services: {", ".join(credentials.keys())}'
                )
            )
            return
        
        creds = credentials[service_name]
        force = options.get('force', False)
        
        try:
            # Check if user already exists
            existing_user = User.objects.filter(username=creds['username']).first()
            
            if existing_user and not force:
                self.stdout.write(
                    self.style.WARNING(
                        f'Superuser {creds["username"]} already exists for {service_name} service. '
                        f'Use --force to update password.'
                    )
                )
                return
            
            if existing_user and force:
                # Update existing user
                existing_user.set_password(creds['password'])
                existing_user.email = creds['email']
                existing_user.first_name = creds['first_name']
                existing_user.last_name = creds['last_name']
                existing_user.is_superuser = True
                existing_user.is_staff = True
                existing_user.is_active = True
                existing_user.save()
                
                self.stdout.write(
                    self.style.SUCCESS(
                        f'Updated superuser {creds["username"]} for {service_name} service'
                    )
                )
            else:
                # Create new superuser
                User.objects.create_superuser(
                    username=creds['username'],
                    password=creds['password'],
                    email=creds['email'],
                    first_name=creds['first_name'],
                    last_name=creds['last_name']
                )
                
                self.stdout.write(
                    self.style.SUCCESS(
                        f'Created superuser {creds["username"]} for {service_name} service'
                    )
                )
            
            # Display login information
            self.stdout.write('')
            self.stdout.write(self.style.SUCCESS('=== SUPERUSER CREATED SUCCESSFULLY ==='))
            self.stdout.write(f'Service: {service_name.upper()}')
            self.stdout.write(f'Username: {creds["username"]}')
            self.stdout.write(f'Password: {creds["password"]}')
            self.stdout.write(f'Email: {creds["email"]}')
            self.stdout.write('')
            self.stdout.write('⚠️  SECURITY NOTE: Change this password after first login!')
            self.stdout.write('🔑 Password is also stored in Azure Key Vault')
            
        except IntegrityError as e:
            self.stdout.write(
                self.style.ERROR(
                    f'Error creating superuser: {str(e)}'
                )
            )
        except Exception as e:
            self.stdout.write(
                self.style.ERROR(
                    f'Unexpected error: {str(e)}'
                )
            )


"""
USAGE INSTRUCTIONS:
==================

1. Copy this file to each Django microservice at:
   <service>/management/commands/create_service_superuser.py

2. Run the command within each service:
   python manage.py create_service_superuser --service auth
   python manage.py create_service_superuser --service chat
   python manage.py create_service_superuser --service payment
   # ... etc for each service

3. Or set environment variable in deployment:
   export SERVICE_NAME=auth
   python manage.py create_service_superuser

4. In Kubernetes deployment:
   apiVersion: batch/v1
   kind: Job
   metadata:
     name: create-auth-superuser
   spec:
     template:
       spec:
         containers:
         - name: auth-service
           image: your-registry/auth-service:latest
           env:
           - name: SERVICE_NAME
             value: "auth"
           command: ["python", "manage.py", "create_service_superuser"]
         restartPolicy: OnFailure

5. To update existing superuser:
   python manage.py create_service_superuser --service auth --force
"""
