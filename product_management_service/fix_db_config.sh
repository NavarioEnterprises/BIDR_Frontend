#!/bin/bash

# Get the current pod name
POD_NAME=$(kubectl get pods -n bidr -l app=product-management-service -o jsonpath='{.items[0].metadata.name}')

echo "Fixing database configuration in pod: $POD_NAME"

# Update the database configuration
kubectl exec -n bidr $POD_NAME -- sed -i "s|if os.path.exists('/etc/secrets/db'):|if os.environ.get('DB_HOST') and os.environ.get('DB_NAME'):|g" /app/product_management_service/settings.py

echo "Database configuration updated. Restarting pod..."

# Restart the pod
kubectl delete pod $POD_NAME -n bidr

echo "Pod restarted. Waiting for new pod to be ready..."

# Wait for new pod to be ready
kubectl wait --for=condition=ready pod -l app=product-management-service -n bidr --timeout=120s

# Get the new pod name
NEW_POD_NAME=$(kubectl get pods -n bidr -l app=product-management-service -o jsonpath='{.items[0].metadata.name}')

echo "New pod ready: $NEW_POD_NAME"

# Apply the fix to the new pod
kubectl exec -n bidr $NEW_POD_NAME -- sed -i "s|if os.path.exists('/etc/secrets/db'):|if os.environ.get('DB_HOST') and os.environ.get('DB_NAME'):|g" /app/product_management_service/settings.py

echo "Database configuration fixed in new pod"

# Verify the configuration
echo "Verifying database configuration..."
kubectl exec -n bidr $NEW_POD_NAME -- python manage.py shell -c "
from django.conf import settings
print(f'Database ENGINE: {settings.DATABASES[\"default\"][\"ENGINE\"]}')
if 'HOST' in settings.DATABASES['default']:
    print(f'Database HOST: {settings.DATABASES[\"default\"][\"HOST\"]}')
    print(f'Database NAME: {settings.DATABASES[\"default\"][\"NAME\"]}')
    print('✅ PostgreSQL configuration active!')
else:
    print('❌ Still using SQLite')
"
