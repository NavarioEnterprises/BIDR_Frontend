#!/bin/bash

# Get the current pod name
POD_NAME=$(kubectl get pods -n bidr -l app=product-management-service -o jsonpath='{.items[0].metadata.name}')

echo "Setting up final cluster configuration for pod: $POD_NAME"

# 1. Copy our updated settings file
echo "1. Copying updated settings..."
kubectl cp product_management_service/settings.py bidr/$POD_NAME:/app/product_management_service/settings.py

# 2. Fix the database configuration
echo "2. Fixing database configuration..."
kubectl exec -n bidr $POD_NAME -- sed -i "s|if os.path.exists('/etc/secrets/db'):|if os.environ.get('DB_HOST') and os.environ.get('DB_NAME'):|g" /app/product_management_service/settings.py

# 3. Verify configuration
echo "3. Verifying database configuration..."
kubectl exec -n bidr $POD_NAME -- python manage.py shell -c "
from django.conf import settings
print('=== Database Configuration ===')
print(f'ENGINE: {settings.DATABASES[\"default\"][\"ENGINE\"]}')
if 'HOST' in settings.DATABASES['default']:
    print(f'HOST: {settings.DATABASES[\"default\"][\"HOST\"]}')
    print(f'NAME: {settings.DATABASES[\"default\"][\"NAME\"]}')
    print('✅ PostgreSQL configuration active!')
else:
    print('❌ Still using SQLite')

print('\n=== CSRF Configuration ===')
print(f'CSRF_USE_SESSIONS: {settings.CSRF_USE_SESSIONS}')
print(f'CSRF_COOKIE_HTTPONLY: {settings.CSRF_COOKIE_HTTPONLY}')
"

echo "4. Configuration complete!"
