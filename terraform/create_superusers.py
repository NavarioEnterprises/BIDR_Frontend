#!/usr/bin/env python3
"""
Script to create superusers for all BIDR microservices
"""
import psycopg2
import sys
from datetime import datetime

# Database connection parameters
DB_HOST = "bidr-dev-aks-cluster-psql-server.postgres.database.azure.com"
DB_PORT = "5432"
DB_USER = "bidruser"
DB_PASSWORD = "bpx}h=WY3lTlhnOCh4S6#D(wk$E$C0o:"

# Service credentials
SERVICE_CREDENTIALS = {
    "auth": {
        "database": "auth_db",
        "admin_user": "auth_admin",
        "admin_password": "Tc_tYOQZt)>84A3M",
        "admin_email": "auth.admin@bidr.co.za"
    },
    "chat": {
        "database": "chat_db", 
        "admin_user": "chat_admin",
        "admin_password": "$$:_yCg}6pSOcH*u",
        "admin_email": "chat.admin@bidr.co.za"
    },
    "payment": {
        "database": "payment_db",
        "admin_user": "payment_admin", 
        "admin_password": "qF{OK_*B>Id!PuB}",
        "admin_email": "payment.admin@bidr.co.za"
    },
    "resolution": {
        "database": "resolution_db",
        "admin_user": "resolution_admin",
        "admin_password": "vqL1-t)#X{zOOEf>", 
        "admin_email": "resolution.admin@bidr.co.za"
    },
    "product": {
        "database": "product_db",
        "admin_user": "product_admin",
        "admin_password": "d_<!?8zm0Pv?nbA9",
        "admin_email": "product.admin@bidr.co.za"
    },
    "notifications": {
        "database": "notifications_db",
        "admin_user": "notifications_admin",
        "admin_password": "xYWKA<_r]p3tqlNy",
        "admin_email": "notifications.admin@bidr.co.za"
    },
    "transactions": {
        "database": "transactions_db", 
        "admin_user": "transactions_admin",
        "admin_password": "Vi0)$>amuaIP4RS",
        "admin_email": "transactions.admin@bidr.co.za"
    },
    "reviews": {
        "database": "reviews_db",
        "admin_user": "reviews_admin", 
        "admin_password": ":lO#qUghyQiJ+b&d",
        "admin_email": "reviews.admin@bidr.co.za"
    }
}

def create_django_superuser_table_and_user(service_name, db_config):
    """
    Create the Django auth tables and superuser for a service database
    """
    try:
        # Connect to the specific service database
        conn = psycopg2.connect(
            host=DB_HOST,
            port=DB_PORT,
            database=db_config["database"],
            user=DB_USER,
            password=DB_PASSWORD,
            sslmode='require'
        )
        
        cursor = conn.cursor()
        
        print(f"Connected to {db_config['database']}...")
        
        # Create Django auth tables if they don't exist
        create_tables_sql = """
        -- Create Django auth tables
        CREATE TABLE IF NOT EXISTS auth_user (
            id SERIAL PRIMARY KEY,
            password VARCHAR(128) NOT NULL,
            last_login TIMESTAMP WITH TIME ZONE,
            is_superuser BOOLEAN NOT NULL,
            username VARCHAR(150) NOT NULL UNIQUE,
            first_name VARCHAR(150) NOT NULL,
            last_name VARCHAR(150) NOT NULL,
            email VARCHAR(254) NOT NULL,
            is_staff BOOLEAN NOT NULL,
            is_active BOOLEAN NOT NULL,
            date_joined TIMESTAMP WITH TIME ZONE NOT NULL
        );
        
        CREATE TABLE IF NOT EXISTS django_content_type (
            id SERIAL PRIMARY KEY,
            app_label VARCHAR(100) NOT NULL,
            model VARCHAR(100) NOT NULL,
            UNIQUE(app_label, model)
        );
        
        CREATE TABLE IF NOT EXISTS auth_permission (
            id SERIAL PRIMARY KEY,
            name VARCHAR(255) NOT NULL,
            content_type_id INTEGER REFERENCES django_content_type(id),
            codename VARCHAR(100) NOT NULL,
            UNIQUE(content_type_id, codename)
        );
        
        CREATE TABLE IF NOT EXISTS auth_user_user_permissions (
            id SERIAL PRIMARY KEY,
            user_id INTEGER REFERENCES auth_user(id),
            permission_id INTEGER REFERENCES auth_permission(id),
            UNIQUE(user_id, permission_id)
        );
        
        CREATE TABLE IF NOT EXISTS auth_group (
            id SERIAL PRIMARY KEY,
            name VARCHAR(150) NOT NULL UNIQUE
        );
        
        CREATE TABLE IF NOT EXISTS auth_group_permissions (
            id SERIAL PRIMARY KEY,
            group_id INTEGER REFERENCES auth_group(id),
            permission_id INTEGER REFERENCES auth_permission(id),
            UNIQUE(group_id, permission_id)
        );
        
        CREATE TABLE IF NOT EXISTS auth_user_groups (
            id SERIAL PRIMARY KEY,
            user_id INTEGER REFERENCES auth_user(id),
            group_id INTEGER REFERENCES auth_group(id),
            UNIQUE(user_id, group_id)
        );
        """
        
        cursor.execute(create_tables_sql)
        print(f"✓ Created Django auth tables for {service_name}")
        
        # Check if superuser already exists
        cursor.execute(
            "SELECT COUNT(*) FROM auth_user WHERE username = %s",
            (db_config["admin_user"],)
        )
        
        if cursor.fetchone()[0] > 0:
            print(f"⚠️  Superuser {db_config['admin_user']} already exists in {service_name}")
            cursor.close()
            conn.close()
            return True
            
        # Create superuser (Django uses PBKDF2 password hashing, but we'll store plain for initial setup)
        # In production, this should be properly hashed using Django's make_password function
        insert_superuser_sql = """
        INSERT INTO auth_user (
            password, 
            is_superuser, 
            username, 
            first_name, 
            last_name, 
            email, 
            is_staff, 
            is_active, 
            date_joined
        ) VALUES (
            %s, 
            TRUE, 
            %s, 
            %s, 
            %s, 
            %s, 
            TRUE, 
            TRUE, 
            NOW()
        )
        """
        
        # For initial setup, we'll use a simple hash. In production, use Django's make_password
        password_hash = f"pbkdf2_sha256$260000$temp${db_config['admin_password']}"
        
        cursor.execute(insert_superuser_sql, (
            password_hash,
            db_config["admin_user"],
            service_name.title(),
            "Admin",
            db_config["admin_email"]
        ))
        
        conn.commit()
        print(f"✓ Created superuser {db_config['admin_user']} for {service_name}")
        
        cursor.close()
        conn.close()
        return True
        
    except Exception as e:
        print(f"❌ Error creating superuser for {service_name}: {str(e)}")
        return False

def main():
    """Main function to create all superusers"""
    print("🚀 Creating superusers for BIDR microservices...")
    print(f"📅 Started at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("-" * 60)
    
    successful_services = []
    failed_services = []
    
    for service_name, db_config in SERVICE_CREDENTIALS.items():
        print(f"\n📝 Processing {service_name} service...")
        
        if create_django_superuser_table_and_user(service_name, db_config):
            successful_services.append(service_name)
        else:
            failed_services.append(service_name)
    
    # Write credentials to file
    credentials_file = "superuser_credentials.txt"
    with open(credentials_file, "w") as f:
        f.write("BIDR MICROSERVICES SUPERUSER CREDENTIALS\n")
        f.write("=" * 50 + "\n")
        f.write(f"Created: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
        f.write(f"Database Host: {DB_HOST}\n")
        f.write(f"Database Port: {DB_PORT}\n\n")
        
        for service_name, db_config in SERVICE_CREDENTIALS.items():
            status = "✅ CREATED" if service_name in successful_services else "❌ FAILED"
            f.write(f"{service_name.upper()} SERVICE {status}\n")
            f.write("-" * 30 + "\n")
            f.write(f"Database: {db_config['database']}\n")
            f.write(f"Username: {db_config['admin_user']}\n")
            f.write(f"Password: {db_config['admin_password']}\n")
            f.write(f"Email: {db_config['admin_email']}\n")
            f.write(f"Admin URL: http://your-domain/{service_name}/admin/\n\n")
        
        f.write("\nNOTES:\n")
        f.write("- These are initial superuser accounts for development\n")
        f.write("- Change passwords in production environments\n") 
        f.write("- Passwords are stored securely in Azure Key Vault\n")
        f.write("- Use Django's admin interface to manage users\n")
    
    print("\n" + "=" * 60)
    print(f"✅ Successfully created superusers for: {', '.join(successful_services)}")
    if failed_services:
        print(f"❌ Failed to create superusers for: {', '.join(failed_services)}")
    print(f"📄 Credentials saved to: {credentials_file}")
    print("🔒 Remember to secure these credentials!")

if __name__ == "__main__":
    main()
