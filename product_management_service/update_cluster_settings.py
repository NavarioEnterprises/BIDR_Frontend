#!/usr/bin/env python3
"""
Script to update Django settings in the running Kubernetes pod
"""
import subprocess
import sys

def update_settings_in_pod():
    """Update settings.py in the running pod to use environment variables"""
    
    # The updated settings content
    settings_update = '''
# Database configuration - check environment variables first
import os

# Check if database environment variables are available (Kubernetes deployment)
if os.environ.get('DB_HOST') and os.environ.get('DB_NAME'):
    # Use PostgreSQL with environment variables from Kubernetes secrets
    DATABASES = {
        'default': {
            'ENGINE': 'django.db.backends.postgresql',
            'NAME': os.environ.get('DB_NAME', 'bidr_products'),
            'USER': os.environ.get('DB_USER', 'bidruser'),
            'PASSWORD': os.environ.get('DB_PASSWORD'),
            'HOST': os.environ.get('DB_HOST', 'postgres-service'),
            'PORT': os.environ.get('DB_PORT', '5432'),
            'OPTIONS': {
                'connect_timeout': 30,
            }
        }
    }
    print(f"✅ Using PostgreSQL database: {os.environ.get('DB_NAME')} at {os.environ.get('DB_HOST')}")
else:
    # Development/local setup - use SQLite
    DATABASES = {
        'default': {
            'ENGINE': 'django.db.backends.sqlite3',
            'NAME': BASE_DIR / 'db.sqlite3',
        }
    }
    print("ℹ️  Using local SQLite database")
'''
    
    # Create a temporary file with the settings update
    cmd = [
        'kubectl', 'exec', '-n', 'bidr', 
        'product-management-service-7d5b5bd7-qpgkz', '--',
        'python', '-c', f'''
import os
import re

settings_file = "/app/product_management_service/settings.py"

# Read the current settings
with open(settings_file, 'r') as f:
    content = f.read()

# Replace the database configuration section
pattern = r"# Check if running in Kubernetes with mounted secrets.*?    \\}\\}"
replacement = """# Check if database environment variables are available (Kubernetes deployment)
if os.environ.get('DB_HOST') and os.environ.get('DB_NAME'):
    # Use PostgreSQL with environment variables from Kubernetes secrets
    DATABASES = {{
        'default': {{
            'ENGINE': 'django.db.backends.postgresql',
            'NAME': os.environ.get('DB_NAME', 'bidr_products'),
            'USER': os.environ.get('DB_USER', 'bidruser'),
            'PASSWORD': os.environ.get('DB_PASSWORD'),
            'HOST': os.environ.get('DB_HOST', 'postgres-service'),
            'PORT': os.environ.get('DB_PORT', '5432'),
            'OPTIONS': {{
                'connect_timeout': 30,
            }}
        }}
    }}
    print(f"✅ Using PostgreSQL database: {{os.environ.get('DB_NAME')}} at {{os.environ.get('DB_HOST')}}")
else:
    # Development/local setup - use SQLite
    DATABASES = {{
        'default': {{
            'ENGINE': 'django.db.backends.sqlite3',
            'NAME': BASE_DIR / 'db.sqlite3',
        }}
    }}
    print("ℹ️  Using local SQLite database")"""

new_content = re.sub(pattern, replacement, content, flags=re.DOTALL)

# Write back to the file
with open(settings_file, 'w') as f:
    f.write(new_content)

print("Settings updated successfully!")
'''
    ]
    
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=30)
        if result.returncode == 0:
            print("✅ Settings updated in cluster pod")
            print(result.stdout)
        else:
            print("❌ Failed to update settings")
            print(result.stderr)
            return False
            
    except subprocess.TimeoutExpired:
        print("❌ Command timed out")
        return False
    except Exception as e:
        print(f"❌ Error: {e}")
        return False
        
    return True

if __name__ == "__main__":
    print("=== Updating Django settings in Kubernetes pod ===")
    success = update_settings_in_pod()
    sys.exit(0 if success else 1)
