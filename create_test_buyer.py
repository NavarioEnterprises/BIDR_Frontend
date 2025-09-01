import os
import sys
import django
import requests
import json
import time

# Add authentication service to Python path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'authentication_service'))

# Setup Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'authentication_service.settings')

try:
    django.setup()
    
    from django.contrib.auth.models import User
    from user_profiles.models import UserProfile

    # Create test buyer user
    username = 'test_buyer_0683289404'
    
    # Check if user already exists
    if User.objects.filter(username=username).exists():
        user = User.objects.get(username=username)
        print(f'User already exists: {user.username}')
    else:
        user = User.objects.create_user(
            username=username,
            email='test_buyer@bidr.com',
            password='TestPassword123!'
        )
        print(f'User created: {user.username}')

    # Create or update user profile
    profile, created = UserProfile.objects.update_or_create(
        user=user,
        defaults={
            'user_type': 'buyer',
            'phone_number': '0683289404',
            'email_verified': False,
            'kyc_status': 'pending'
        }
    )

    print(f'Profile {"created" if created else "updated"}: {profile.user_type}')
    print(f'Phone: {profile.phone_number}')
    print(f'User ID: {user.id}')
    
except ImportError as e:
    print(f"Import error: {e}")
    print("Running without Django ORM, using API directly...")
    
    # Create account via API
    auth_api_url = "http://localhost:8000/api/v1/register/"
    
    payload = {
        "username": "test_buyer_0683289404",
        "email": "test_buyer@bidr.com",
        "password": "TestPassword123!",
        "user_type": "buyer",
        "phone_number": "0683289404"
    }
    
    try:
        response = requests.post(auth_api_url, json=payload)
        if response.status_code == 201:
            print("User created successfully via API!")
            print(f"Response: {response.json()}")
        else:
            print(f"Failed to create user: {response.status_code}")
            print(f"Response: {response.text}")
    except requests.exceptions.ConnectionError:
        print("Authentication service is not running on localhost:8000")
        print("Please start the authentication service first")

# Now send OTP via notification service
print("\n--- Sending OTP via SMS ---")

notification_api_url = "http://localhost:8006/api/v1/sms/send/otp/"

otp_payload = {
    "phone_number": "0683289404",
    "otp_code": "123456",
    "template_name": "otp_verification"
}

try:
    response = requests.post(notification_api_url, json=otp_payload)
    if response.status_code == 200:
        print("OTP sent successfully!")
        print(f"Response: {response.json()}")
    else:
        print(f"Failed to send OTP: {response.status_code}")
        print(f"Response: {response.text}")
except requests.exceptions.ConnectionError:
    print("Notification service is not running on localhost:8006")
    print("Please start the notification service first")