#!/bin/bash

# Quick script to fix admin passwords for all BIDR services

NAMESPACE="bidr-uat"
PASSWORD="AdminPassword123!"

services=(
    "chat-service"
    "payment-service"
    "product-management-service"
    "notifications-service"
    "transactions-service"
    "reviews-service"
    "resolution-service"
)

echo "=========================================="
echo "Fixing admin passwords for all services"
echo "Password: $PASSWORD"
echo "=========================================="

for service in "${services[@]}"; do
    echo ""
    echo "Fixing admin password for $service..."
    
    # Get the running pod
    pod=$(kubectl get pods -n $NAMESPACE -l app=$service --no-headers -o custom-columns=":metadata.name" | grep Running | head -1)
    if [ -z "$pod" ]; then
        pod=$(kubectl get pods -n $NAMESPACE -l app=$service --no-headers -o custom-columns=":metadata.name" | head -1)
    fi
    
    if [ -z "$pod" ]; then
        echo "❌ No pod found for $service"
        continue
    fi
    
    echo "Using pod: $pod"
    
    # Update admin password
    kubectl exec -n $NAMESPACE $pod -- python -c "
import os
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
import django
django.setup()
from django.contrib.auth import get_user_model

User = get_user_model()

try:
    # Get or create admin user
    if User.objects.filter(username='admin').exists():
        user = User.objects.get(username='admin')
        print('Found existing admin user')
    else:
        user = User.objects.create_superuser(
            username='admin',
            email='admin@bidr.com',
            password='$PASSWORD'
        )
        print('Created new admin user')
    
    # Ensure correct settings
    user.set_password('$PASSWORD')
    user.is_staff = True
    user.is_superuser = True
    user.is_active = True
    user.save()
    
    # Verify password
    is_valid = user.check_password('$PASSWORD')
    print(f'✅ Password updated and verified: {is_valid}')
    
except Exception as e:
    print(f'❌ Error: {e}')
"
    
    echo "✅ Admin password fixed for $service"
done

echo ""
echo "=========================================="
echo "Admin Password Fix Completed!"
echo ""
echo "🔐 CREDENTIALS FOR ALL SERVICES:"
echo "Username: admin"
echo "Password: $PASSWORD"
echo ""
echo "🌐 TEST URLs:"
echo "• Chat Service:         http://108.141.192.60/chat/admin/"
echo "• Payment Service:      http://108.141.192.60/payments/admin/"
echo "• Product Service:      http://108.141.192.60/products/admin/"
echo "• Notifications Service: http://108.141.192.60/notifications/admin/"
echo "• Transactions Service: http://108.141.192.60/transactions/admin/"
echo "• Reviews Service:      http://108.141.192.60/reviews/admin/"
echo "• Resolution Service:   http://108.141.192.60/resolution/admin/"
echo "=========================================="
