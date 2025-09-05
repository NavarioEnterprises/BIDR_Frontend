#!/usr/bin/env python3
"""
Fix database schema issues for BIDR Product Management Service

This script addresses the missing 'is_flagged' and 'flags' columns in the product_request table
that are causing 500 errors when trying to fetch seller requests.
"""

import os
import sys
import django
import sqlite3
from pathlib import Path

# Add the project directory to the Python path
project_root = Path(__file__).parent
sys.path.append(str(project_root))

# Setup Django environment
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'product_management_service.settings')

try:
    django.setup()
    print("Django setup successful")
except Exception as e:
    print(f"Django setup failed: {e}")
    print("Falling back to direct database modification...")

def fix_sqlite_schema():
    """Fix the SQLite database schema directly"""
    db_path = project_root / 'db.sqlite3'
    
    if not db_path.exists():
        print(f"Database file not found at {db_path}")
        return False
    
    try:
        conn = sqlite3.connect(str(db_path))
        cursor = conn.cursor()
        
        # Check if is_flagged column exists
        cursor.execute("PRAGMA table_info(product_request)")
        columns = [column[1] for column in cursor.fetchall()]
        
        print(f"Current columns in product_request table: {columns}")
        
        if 'is_flagged' not in columns:
            print("Adding is_flagged column...")
            cursor.execute("""
                ALTER TABLE product_request 
                ADD COLUMN is_flagged BOOLEAN DEFAULT 0
            """)
            print("✓ is_flagged column added")
        else:
            print("✓ is_flagged column already exists")
        
        if 'flags' not in columns:
            print("Adding flags column...")
            cursor.execute("""
                ALTER TABLE product_request 
                ADD COLUMN flags TEXT DEFAULT '[]'
            """)
            print("✓ flags column added")
        else:
            print("✓ flags column already exists")
        
        # Update any NULL values to proper defaults
        cursor.execute("UPDATE product_request SET is_flagged = 0 WHERE is_flagged IS NULL")
        cursor.execute("UPDATE product_request SET flags = '[]' WHERE flags IS NULL OR flags = ''")
        
        conn.commit()
        conn.close()
        
        print("✅ Database schema fixed successfully!")
        return True
        
    except Exception as e:
        print(f"❌ Error fixing database schema: {e}")
        return False

def run_django_migration():
    """Try to run Django migrations"""
    try:
        from django.core.management import execute_from_command_line
        
        print("Attempting to run Django migrations...")
        execute_from_command_line(['manage.py', 'migrate'])
        print("✅ Django migrations completed successfully!")
        return True
        
    except Exception as e:
        print(f"❌ Django migrations failed: {e}")
        return False

def main():
    print("🔧 BIDR Product Management Service - Database Schema Fix")
    print("=" * 60)
    
    # Try Django migrations first
    migration_success = run_django_migration()
    
    if not migration_success:
        print("\nFalling back to direct database modification...")
        schema_success = fix_sqlite_schema()
        
        if not schema_success:
            print("\n❌ All fix attempts failed.")
            print("\n📝 Manual steps:")
            print("1. Run the SQL script: add_flag_fields.sql")
            print("2. Or manually add these columns to product_request table:")
            print("   - is_flagged BOOLEAN DEFAULT FALSE")
            print("   - flags TEXT DEFAULT '[]'")
            return 1
    
    print("\n🎉 Database schema is now fixed!")
    print("\n📋 Next steps:")
    print("1. Restart your Django development server")
    print("2. Test the API endpoints:")
    print("   - GET /api/v1/product-requests/requests/by_seller/?auth_user_uid=<seller_id>")
    print("   - GET /api/v1/quotes/quotes/by_seller/?auth_user_uid=<seller_id>")
    
    return 0

if __name__ == '__main__':
    sys.exit(main())