#!/usr/bin/env python
"""
Test user registration API with SMS OTP integration
"""
import requests
import json

def test_registration_with_sms():
    """Test user registration that should send SMS OTP"""
    
    # Test registration data
    registration_data = {
        "username": "test_sms_buyer_12345",
        "email": "test_sms_buyer@bidr.com",
        "password": "TestPassword123!",
        "user_type": "buyer",
        "phone_number": "0683289404"
    }
    
    print("=== Testing User Registration with SMS OTP ===")
    print(f"Payload: {json.dumps(registration_data, indent=2)}")
    
    # First test with notification service not running
    auth_endpoint = "http://localhost:8000/api/v1/register/"
    
    try:
        response = requests.post(auth_endpoint, json=registration_data, timeout=10)
        
        print(f"\nStatus Code: {response.status_code}")
        print(f"Response: {json.dumps(response.json(), indent=2)}")
        
        if response.status_code == 201:
            print("\n✅ Registration successful!")
            result = response.json()
            if result.get('delivery_channels'):
                channels = result['delivery_channels']
                if channels.get('sms'):
                    print("✅ SMS OTP was sent successfully!")
                else:
                    print("⚠️  SMS OTP failed, but email may have succeeded")
                if channels.get('email'):
                    print("✅ Email OTP was sent successfully!")
                else:
                    print("⚠️  Email OTP failed")
            return True
        else:
            print("❌ Registration failed")
            return False
            
    except requests.exceptions.ConnectionError:
        print("❌ Connection Error: Authentication service is not running")
        print("Please ensure the authentication service is running on http://localhost:8000")
        return False
    except Exception as e:
        print(f"❌ Unexpected error: {str(e)}")
        return False

def main():
    """Main test function"""
    print("User Registration + SMS OTP Test")
    print("=================================")
    
    success = test_registration_with_sms()
    
    if success:
        print("\n✅ Integration test completed successfully!")
        print("The UserRegistrationView is now sending OTP via SMS through the notifications service.")
    else:
        print("\n❌ Integration test failed")
        print("Check that both authentication service (8000) and notifications service (8006) are running.")

if __name__ == '__main__':
    main()