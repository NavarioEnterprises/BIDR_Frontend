#!/bin/bash

# Create simple admin users for all BIDR services
# Username: admin
# Password: AdminPassword123!
# Email: admin@bidr.com

NAMESPACE="bidr-uat"

services=(
    "auth-service"
    "chat-service"
    "payment-service"
    "product-management-service"
    "notifications-service"
    "transactions-service"
    "reviews-service"
    "resolution-service"
)

echo "=========================================="
echo "Creating Simple Admin Users for All Services"
echo "Username: admin"
echo "Password: AdminPassword123!"
echo "Email: admin@bidr.com"
echo "=========================================="

for service in "${services[@]}"; do
    echo ""
    echo "Creating admin user for $service..."
    
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
    
    kubectl exec -n $NAMESPACE $pod -- python manage.py shell << 'EOF'
from django.contrib.auth import get_user_model
User = get_user_model()

username = "admin"
password = "AdminPassword123!"
email = "admin@bidr.com"

try:
    if User.objects.filter(username=username).exists():
        user = User.objects.get(username=username)
        user.set_password(password)
        user.email = email
        user.is_staff = True
        user.is_superuser = True
        user.save()
        print(f"✅ Updated admin user")
    else:
        user = User.objects.create_superuser(
            username=username,
            email=email,
            password=password
        )
        user.is_staff = True
        user.is_superuser = True
        user.save()
        print(f"✅ Created admin user")
    
    print(f"Username: {user.username}")
    print(f"Email: {user.email}")
    print(f"Staff: {user.is_staff}")
    print(f"Superuser: {user.is_superuser}")
except Exception as e:
    print(f"❌ Error: {e}")
EOF
    
    if [ $? -eq 0 ]; then
        echo "✅ Admin user setup completed for $service"
    else
        echo "❌ Failed to create admin user for $service"
    fi
done

echo ""
echo "=========================================="
echo "Simple Admin User Creation Completed!"
echo ""
echo "🔐 CREDENTIALS TO USE:"
echo "Username: admin"
echo "Password: AdminPassword123!"
echo "Email: admin@bidr.com"
echo ""
echo "🌐 ADMIN PANEL URLs:"
echo "• Auth Service:         http://108.141.192.60/admin/"
echo "• Chat Service:         http://108.141.192.60/chat/admin/"
echo "• Payment Service:      http://108.141.192.60/payments/admin/"
echo "• Product Service:      http://108.141.192.60/products/admin/"
echo "• Notifications Service: http://108.141.192.60/notifications/admin/"
echo "• Transactions Service: http://108.141.192.60/transactions/admin/"
echo "• Reviews Service:      http://108.141.192.60/reviews/admin/"
echo "• Resolution Service:   http://108.141.192.60/resolution/admin/"
echo "=========================================="
