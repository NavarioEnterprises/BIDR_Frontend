#!/bin/bash

# BIDR Django Superuser Creation Script for Kubernetes
# Creates superusers for all BIDR microservices

set -e

NAMESPACE="bidr-uat"

# Service credentials array
services="
auth-service:auth_admin:Tc_tYOQZt)>84A3M:auth.admin@bidr.co.za
chat-service:chat_admin:\$\$:_yCg}6pSOcH*u:chat.admin@bidr.co.za
payment-service:payment_admin:qF{OK_*B>Id!PuB}:payment.admin@bidr.co.za
resolution-service:resolution_admin:vqL1-t)#X{zOOEf>:resolution.admin@bidr.co.za
product-management-service:product_admin:d_<!?8zm0Pv?nbA9:product.admin@bidr.co.za
notifications-service:notifications_admin:xYWKA<_r]p3tqlNy:notifications.admin@bidr.co.za
transactions-service:transactions_admin:Vi0)\$>amuaIP4RS:transactions.admin@bidr.co.za
reviews-service:reviews_admin::lO#qUghyQiJ+b&d:reviews.admin@bidr.co.za
"

echo "=========================================="
echo "BIDR Django Superuser Creation Script"
echo "Namespace: $NAMESPACE"
echo "=========================================="

# Function to create superuser
create_superuser() {
    local service=$1
    local username=$2
    local password=$3
    local email=$4
    
    echo ""
    echo "Creating superuser for $service..."
    echo "Username: $username"
    echo "Email: $email"
    
    # Get pod name
    local pod=$(kubectl get pods -n $NAMESPACE -l app=$service --no-headers -o custom-columns=":metadata.name" | head -1)
    
    if [ -z "$pod" ]; then
        echo "❌ No running pod found for $service"
        return 1
    fi
    
    echo "Using pod: $pod"
    
    # Create superuser using Django shell
    kubectl exec -n $NAMESPACE $pod -- python manage.py shell << EOF
import os
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')

import django
django.setup()

from django.contrib.auth import get_user_model

User = get_user_model()

username = "$username"
email = "$email"
password = "$password"

if User.objects.filter(username=username).exists():
    print(f"✅ User '{username}' already exists")
    user = User.objects.get(username=username)
    # Update password in case it changed
    user.set_password(password)
    user.save()
    print(f"✅ Password updated for '{username}'")
else:
    user = User.objects.create_superuser(
        username=username,
        email=email,
        password=password
    )
    print(f"✅ Superuser '{username}' created successfully")

EOF
    
    if [ $? -eq 0 ]; then
        echo "✅ Superuser setup completed for $service"
    else
        echo "❌ Failed to create superuser for $service"
    fi
}

# Process each service
echo "$services" | while IFS=':' read -r service username password email; do
    if [ -n "$service" ]; then
        create_superuser "$service" "$username" "$password" "$email"
    fi
done

echo ""
echo "=========================================="
echo "Superuser creation process completed!"
echo ""
echo "Admin Panel URLs:"
echo "• Auth Service:         http://108.141.192.60/admin/"
echo "• Chat Service:         http://108.141.192.60/chat/admin/"
echo "• Payment Service:      http://108.141.192.60/payments/admin/"
echo "• Product Service:      http://108.141.192.60/products/admin/"
echo "• Notifications Service: http://108.141.192.60/notifications/admin/"
echo "• Transactions Service: http://108.141.192.60/transactions/admin/"
echo "• Reviews Service:      http://108.141.192.60/reviews/admin/"
echo "• Resolution Service:   http://108.141.192.60/resolution/admin/"
echo "=========================================="
