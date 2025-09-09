#!/usr/bin/env python
"""
Simple SMS test using direct SMS Portal API
"""
import requests
from urllib.parse import urlencode

def send_sms_portal(phone_number, message):
    """Send SMS using SMS Portal API directly"""
    
    # SMS Portal credentials
    username = 'cb3fe3f5-99c9-4ca2-89de-4af71abdc41b'
    password = 'b5849253-76d8-4875-90de-c89cc9253b55'
    endpoint = 'https://api.smsportal.com/api5/http5.aspx'
    
    # Prepare parameters
    params = {
        'Type': 'sendparam',
        'Username': username,
        'Password': password,
        'Numto': phone_number.replace('+', ''),  # Remove + prefix
        'Data1': message,
        'customerID': 'BIDR'
    }
    
    # Send request
    print(f"Sending SMS to {phone_number}...")
    print(f"Message: {message}")
    
    try:
        response = requests.get(endpoint, params=params, timeout=30)
        
        print(f"\nStatus Code: {response.status_code}")
        print(f"Response: {response.text}")
        
        if response.status_code == 200 and not response.text.startswith('ERR'):
            print("\n✅ SMS sent successfully!")
            print(f"Message ID: {response.text}")
            return True
        else:
            print("\n❌ Failed to send SMS")
            return False
            
    except Exception as e:
        print(f"\n❌ Error: {str(e)}")
        return False

def main():
    """Main test"""
    phone_number = '0683289404'
    otp_code = '123456'
    message = f'Your BIDR verification code is: {otp_code}. Valid for 5 minutes.'
    
    print("=== SMS Portal Direct Test ===")
    print(f"Phone: {phone_number}")
    print("")
    
    success = send_sms_portal(phone_number, message)
    
    if success:
        print(f"\n✅ Test completed successfully!")
        print(f"OTP {otp_code} has been sent to {phone_number}")
    else:
        print(f"\n❌ Test failed")

if __name__ == '__main__':
    main()