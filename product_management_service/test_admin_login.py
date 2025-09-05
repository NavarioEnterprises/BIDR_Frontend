#!/usr/bin/env python3
"""
Script to test Django admin login functionality
"""
import requests
import re
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry

# Configure session with retries
session = requests.Session()
retry = Retry(total=3, backoff_factor=0.3, status_forcelist=[500, 502, 503, 504])
adapter = HTTPAdapter(max_retries=retry)
session.mount('http://', adapter)
session.mount('https://', adapter)

def test_admin_login(base_url, username, password):
    """Test Django admin login"""
    login_url = f"{base_url}/admin/login/"
    
    print(f"Testing admin login at {login_url}")
    
    try:
        # Step 1: Get login page and extract CSRF token
        print("Step 1: Getting login page...")
        response = session.get(login_url, timeout=10)
        response.raise_for_status()
        
        # Extract CSRF token
        csrf_match = re.search(r'name="csrfmiddlewaretoken" value="([^"]+)"', response.text)
        if not csrf_match:
            print("ERROR: Could not find CSRF token in login page")
            return False
        
        csrf_token = csrf_match.group(1)
        print(f"Found CSRF token: {csrf_token[:20]}...")
        
        # Step 2: Attempt login
        print("Step 2: Attempting login...")
        login_data = {
            'username': username,
            'password': password,
            'csrfmiddlewaretoken': csrf_token,
            'next': '/admin/'
        }
        
        # Set headers
        headers = {
            'Referer': login_url,
            'X-CSRFToken': csrf_token,
            'Content-Type': 'application/x-www-form-urlencoded',
        }
        
        response = session.post(login_url, data=login_data, headers=headers, 
                              allow_redirects=False, timeout=10)
        
        print(f"Login response status: {response.status_code}")
        
        if response.status_code == 302:
            redirect_location = response.headers.get('Location', '')
            if '/admin/' in redirect_location and 'login' not in redirect_location:
                print("✅ LOGIN SUCCESSFUL!")
                print(f"Redirected to: {redirect_location}")
                return True
            else:
                print("❌ Login failed - redirected back to login page")
                print(f"Redirect location: {redirect_location}")
        elif response.status_code == 200:
            if 'errorlist' in response.text:
                print("❌ Login failed - credentials rejected")
                # Try to extract error message
                error_match = re.search(r'<ul class="errorlist[^>]*>.*?<li>(.*?)</li>', response.text)
                if error_match:
                    print(f"Error: {error_match.group(1)}")
            else:
                print("❌ Login failed - unknown error")
        else:
            print(f"❌ Unexpected response status: {response.status_code}")
            
    except requests.exceptions.RequestException as e:
        print(f"❌ Request failed: {e}")
        return False
    
    return False

if __name__ == "__main__":
    # Test with different credentials
    base_url = "http://localhost:8080"
    
    test_credentials = [
        ("admin", "admin123"),
        ("admin", "admin"),
        ("bidr_admin", "admin"),
        ("thulanimoyo", "admin"),
    ]
    
    print("=== Django Admin Login Test ===")
    
    for username, password in test_credentials:
        print(f"\n--- Testing {username}:{password} ---")
        success = test_admin_login(base_url, username, password)
        if success:
            break
        print("Waiting 2 seconds before next attempt...")
        import time
        time.sleep(2)
