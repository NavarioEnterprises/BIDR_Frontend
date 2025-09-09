#!/usr/bin/env python
import os
import django
from django.conf import settings

# Setup Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'authentication_service.settings')
django.setup()

from django.contrib.auth import get_user_model

User = get_user_model()

email = 'thulanimoyo@example.com'
password = 'Navario@544'
first_name = 'Thulani'
last_name = 'Moyo'

try:
    # Try to get existing user
    user = User.objects.get(email=email)
    print(f"User with email {email} already exists.")
    
    # Update user to be superuser and set password
    user.is_staff = True
    user.is_superuser = True
    user.first_name = first_name
    user.last_name = last_name
    user.set_password(password)
    user.save()
    print(f"Updated existing user {email} to superuser with new password.")
    
except User.DoesNotExist:
    # Create new superuser
    user = User.objects.create_superuser(
        email=email,
        password=password,
        first_name=first_name,
        last_name=last_name
    )
    print(f"Created new superuser {email}")

print("Superuser setup complete!")
