#!/usr/bin/env python
"""
Test SMS OTP sending via notifications service
"""
import requests
import json
import sys

def test_sms_otp(phone_number, notification_service_url='http://localhost:8006'):
    """Test sending OTP SMS"""
    print(f"\n=== Testing SMS OTP to {phone_number} ===")
    
    # Test endpoint
    sms_endpoint = f"{notification_service_url}/api/v1/sms/send/otp/"
    
    # OTP payload
    otp_payload = {
        'phone_number': phone_number,
        'otp_code': '123456',
        'template_name': 'otp_verification'
    }
    
    print(f"Endpoint: {sms_endpoint}")
    print(f"Payload: {json.dumps(otp_payload, indent=2)}")
    
    try:
        # Send request
        response = requests.post(sms_endpoint, json=otp_payload, timeout=10)
        
        print(f"\nStatus Code: {response.status_code}")
        
        if response.status_code == 200:
            print("✅ SMS sent successfully!")
            print(f"Response: {json.dumps(response.json(), indent=2)}")
        else:
            print("❌ Failed to send SMS")
            print(f"Error: {response.text}")
            
        return response.status_code == 200
        
    except requests.exceptions.ConnectionError:
        print("❌ Connection Error: Notification service is not running")
        print(f"Please ensure the notification service is running on {notification_service_url}")
        return False
    except Exception as e:
        print(f"❌ Unexpected error: {str(e)}")
        return False

def test_direct_sms(phone_number):
    """Test sending SMS directly using SMS Portal credentials"""
    print(f"\n=== Testing Direct SMS Portal to {phone_number} ===")
    
    import os
    import sys
    
    # Add notifications service to path
    sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'notifications_service'))
    
    try:
        os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'notifications.settings')
        import django
        django.setup()
        
        from sms_portal.services import SMSPortalService
        
        # Create SMS service
        sms_service = SMSPortalService()
        
        # Send OTP
        success, message = sms_service.send_otp_sms(
            phone_number=phone_number,
            otp_code='123456'
        )
        
        if success:
            print("✅ SMS sent successfully via direct SMS Portal!")
            print(f"Message ID: {message.external_message_id}")
        else:
            print("❌ Failed to send SMS")
            print(f"Error: {message.error_message}")
            
        return success
        
    except Exception as e:
        print(f"❌ Error: {str(e)}")
        return False

def main():
    """Main test function"""
    # Phone number to test (remove + if present)
    phone_number = '0683289404'
    
    print("SMS OTP Test Script")
    print("==================")
    
    # Test via notification service API
    api_success = test_sms_otp(phone_number)
    
    if not api_success:
        print("\nTrying direct SMS Portal connection...")
        # Try direct SMS Portal
        direct_success = test_direct_sms(phone_number)
        
        if direct_success:
            print("\n✅ Direct SMS Portal working! The issue is with the notification service.")
        else:
            print("\n❌ Both API and direct methods failed.")
    
    print("\n=== Test Complete ===")

if __name__ == '__main__':
    main()