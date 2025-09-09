#!/usr/bin/env python
"""
Simple script to create a superuser for BIDR backend
"""
import os
import sys
import django

# Setup Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'bidr_project.settings')
django.setup()

from django.contrib.auth import get_user_model

User = get_user_model()

def create_superuser():
    email = "admin@bidr.com"
    password = "BIDRAdmin2025!"
    
    # Delete existing user if exists
    if User.objects.filter(email=email).exists():
        User.objects.filter(email=email).delete()
        print(f"Deleted existing user with email: {email}")
    
    # Create new superuser
    user = User.objects.create_superuser(
        email=email,
        password=password
    )
    
    print("✅ Superuser created successfully!")
    print(f"📧 Email:    {email}")
    print(f"🔑 Password: {password}")
    print(f"🌐 Admin URL: http://20.66.69.82:8067/admin/")
    print("💡 Use these credentials to log into the admin interface")

if __name__ == "__main__":
    create_superuser()
