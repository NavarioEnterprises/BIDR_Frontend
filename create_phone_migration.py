#!/usr/bin/env python
"""
Create a Django data migration to handle corrupted phone number encryption
"""
import os
import sys

# Add authentication service to Python path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'authentication_service'))

migration_content = '''
# Generated migration for phone number encryption fix
from django.db import migrations
import base64
import logging

logger = logging.getLogger(__name__)


def fix_corrupted_phone_encryption(apps, schema_editor):
    """Fix corrupted phone number encryption"""
    AppUser = apps.get_model('user', 'AppUser')
    
    corrupted_count = 0
    fixed_count = 0
    
    for user in AppUser.objects.all():
        if not user.phone_number:
            continue
            
        # Check if it's base64 encoded but corrupted
        try:
            # Try to decode as base64
            decoded = base64.urlsafe_b64decode(user.phone_number.encode())
            
            # If we get here, it's base64 encoded. Try to verify it's valid encrypted data
            # by checking if it looks like Fernet token structure
            if len(decoded) < 60:  # Fernet tokens are typically longer
                logger.warning(f"User {user.id}: Suspiciously short encrypted phone number")
                corrupted_count += 1
                # Mark for manual review - set a flag or log the user ID
                continue
                
            # Check if it starts with the Fernet version prefix
            if not decoded.startswith(b'\\x80'):  # Fernet version byte
                logger.warning(f"User {user.id}: Phone number doesn't have valid Fernet structure")
                corrupted_count += 1
                continue
                
            logger.info(f"User {user.id}: Phone number appears to be properly encrypted")
            
        except Exception:
            # Not base64 encoded - likely plain text, which is handled elsewhere
            continue
    
    logger.info(f"Phone encryption migration complete: {corrupted_count} corrupted entries found")


def reverse_fix_corrupted_phone_encryption(apps, schema_editor):
    """Reverse migration - no action needed"""
    pass


class Migration(migrations.Migration):
    
    dependencies = [
        ('user', '0002_auto_20241208_1000'),  # Replace with your latest migration
    ]
    
    operations = [
        migrations.RunPython(
            fix_corrupted_phone_encryption,
            reverse_fix_corrupted_phone_encryption,
        ),
    ]
'''

migration_dir = "/Users/thulanimoyo/MEGA downloads/new downloads/BIDR_Backend/authentication_service/user/migrations"

# Check if migrations directory exists
if not os.path.exists(migration_dir):
    print(f"Migrations directory not found: {migration_dir}")
    print("Please run this script from the correct directory or check the path.")
    sys.exit(1)

# Find the latest migration number
migration_files = [f for f in os.listdir(migration_dir) if f.startswith('0') and f.endswith('.py')]
if migration_files:
    latest_num = max([int(f.split('_')[0]) for f in migration_files if f.split('_')[0].isdigit()])
    new_num = f"{latest_num + 1:04d}"
else:
    new_num = "0001"

migration_filename = f"{new_num}_fix_phone_encryption.py"
migration_path = os.path.join(migration_dir, migration_filename)

try:
    with open(migration_path, 'w') as f:
        f.write(migration_content)
    
    print(f"✅ Migration created: {migration_path}")
    print(f"Migration file: {migration_filename}")
    print()
    print("To apply this migration, run:")
    print(f"cd authentication_service")
    print(f"python manage.py makemigrations")
    print(f"python manage.py migrate")
    print()
    print("This migration will:")
    print("- Identify corrupted encrypted phone numbers")
    print("- Log suspicious entries for manual review") 
    print("- Help track the extent of the corruption issue")
    
except Exception as e:
    print(f"❌ Failed to create migration: {str(e)}")