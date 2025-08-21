#!/usr/bin/env python
import os
import django
import secrets
import string
from datetime import datetime

# Setup Django environment
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'product_management_service.settings')
django.setup()

from django.contrib.auth.models import User

def generate_strong_password(length=12):
    """Generate a strong password with letters, digits and special characters."""
    characters = string.ascii_letters + string.digits + "!@#$%^&*"
    return ''.join(secrets.choice(characters) for _ in range(length))

def set_superuser_password():
    try:
        # Get the superuser
        user = User.objects.get(username='bidr_admin')
        
        # Generate a strong password
        password = generate_strong_password()
        
        # Set the password
        user.set_password(password)
        user.save()
        
        # Save credentials to file
        credentials_content = f"""BIDR Backend - Django Admin Credentials
Created: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}

Admin Panel URL: http://localhost:8000/admin/
Username: bidr_admin
Email: admin@bidr.com
Password: {password}

⚠️  IMPORTANT: Keep these credentials secure and delete this file after use!
⚠️  Change the password after first login for security.
"""
        
        with open('admin_credentials.txt', 'w') as f:
            f.write(credentials_content)
        
        print("✅ Superuser password set successfully!")
        print("📝 Credentials saved to admin_credentials.txt")
        print(f"🔐 Username: bidr_admin")
        print(f"🔐 Password: {password}")
        print("🌐 Admin URL: http://localhost:8000/admin/")
        
        return True
        
    except User.DoesNotExist:
        print("❌ Error: Superuser 'bidr_admin' not found!")
        return False
    except Exception as e:
        print(f"❌ Error setting password: {e}")
        return False

if __name__ == '__main__':
    set_superuser_password()
