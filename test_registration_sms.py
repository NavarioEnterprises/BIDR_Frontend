#!/usr/bin/env python
"""
Test user registration with SMS OTP
"""
import os
import sys
import django
import random
import string

# Add authentication service to Python path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'authentication_service'))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'authentication_service.settings')

try:
    django.setup()
    
    from django.contrib.auth import get_user_model
    from user_profiles.models import UserProfile
    from otp.models import OTP
    
    # Import notifications service
    sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'notifications_service'))
    from sms_portal.services import SMSPortalService
    
    User = get_user_model()
    
    print("=== Creating Test Buyer Account with SMS OTP ===")
    
    # Test data
    username = f'test_buyer_{random.randint(1000, 9999)}'
    email = f'{username}@bidr.com'
    phone = '0683289404'
    
    # Check if user exists
    if User.objects.filter(username=username).exists():
        user = User.objects.get(username=username)
        print(f"User already exists: {username}")
    else:
        # Create user
        user = User.objects.create_user(
            username=username,
            email=email,
            password='TestPassword123!'
        )
        print(f"✅ User created: {username}")
    
    # Create/update profile
    profile, created = UserProfile.objects.update_or_create(
        user=user,
        defaults={
            'user_type': 'buyer',
            'phone_number': phone,
            'email_verified': False,
            'kyc_status': 'pending'
        }
    )
    print(f"✅ Profile {'created' if created else 'updated'}")
    
    # Generate OTP
    otp_code = ''.join(random.choices(string.digits, k=6))
    otp_instance = OTP.objects.create(user=user, otp=otp_code)
    print(f"✅ OTP generated: {otp_code}")
    
    # Send SMS OTP
    print(f"\n=== Sending OTP via SMS to {phone} ===")
    
    try:
        sms_service = SMSPortalService()
        success, message = sms_service.send_otp_sms(
            phone_number=phone,
            otp_code=otp_code,
            context={'username': username}
        )
        
        if success:
            print(f"✅ SMS OTP sent successfully!")
            print(f"Message ID: {message.external_message_id}")
            print(f"Status: {message.status}")
            print(f"\nUser Details:")
            print(f"- Username: {username}")
            print(f"- Email: {email}")
            print(f"- Phone: {phone}")
            print(f"- OTP Code: {otp_code}")
            print(f"- User ID: {user.id}")
        else:
            print(f"❌ Failed to send SMS OTP")
            print(f"Error: {message.error_message}")
    except Exception as e:
        print(f"❌ Error sending SMS: {str(e)}")
    
    print("\n=== Registration Complete ===")
    
except Exception as e:
    print(f"Error: {str(e)}")
    import traceback
    traceback.print_exc()