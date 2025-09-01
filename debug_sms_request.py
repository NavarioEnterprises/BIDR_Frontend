#!/usr/bin/env python
"""
Debug SMS request to see what's causing 400 error
"""
import requests
import json

def debug_sms_request():
    """Debug the SMS request"""
    
    print("=== Debugging SMS Request ===")
    
    # Test different payload formats
    payloads_to_test = [
        {
            "phone_number": "0683289404",
            "otp_code": "123456",
            "template_name": "otp_verification"
        },
        {
            "phone_number": "0683289404",
            "otp_code": "123456"
        },
        {
            "phone_number": "+27683289404",
            "otp_code": "123456",
            "template_name": "otp_verification"
        }
    ]
    
    endpoint = "http://localhost:8006/api/v1/sms/send/otp/"
    
    for i, payload in enumerate(payloads_to_test, 1):
        print(f"\n--- Test {i} ---")
        print(f"Payload: {json.dumps(payload, indent=2)}")
        
        try:
            response = requests.post(endpoint, json=payload, timeout=10)
            print(f"Status Code: {response.status_code}")
            print(f"Response Headers: {dict(response.headers)}")
            print(f"Response Text: {response.text}")
            
            if response.status_code == 200:
                print("✅ Success!")
                try:
                    json_response = response.json()
                    print(f"JSON Response: {json.dumps(json_response, indent=2)}")
                except:
                    pass
                return
            else:
                print("❌ Failed")
                
        except requests.exceptions.ConnectionError:
            print("❌ Connection Error: Service not running")
            return
        except Exception as e:
            print(f"❌ Error: {str(e)}")
    
    print("\n=== Debug Complete ===")

if __name__ == '__main__':
    debug_sms_request()