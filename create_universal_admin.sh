#!/bin/bash

# Universal Admin User Creation Script
# Handles both email-based and username-based authentication

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
echo "Universal Admin User Creation Script"
echo "Email: admin@bidr.com"
echo "Password: AdminPassword123!"
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

email = "admin@bidr.com"
password = "AdminPassword123!"
username = "admin"

print(f"User model: {User}")
username_field = getattr(User, 'USERNAME_FIELD', 'username')
print(f"USERNAME_FIELD: {username_field}")

try:
    # Clean up any existing users
    if username_field == 'email':
        User.objects.filter(email=email).delete()
        print("Deleted existing email-based users")
    else:
        User.objects.filter(username=username).delete()
        print("Deleted existing username-based users")
    
    # Create the appropriate user based on authentication method
    if username_field == 'email':
        # Email-based authentication (like auth service)
        print("Creating email-based superuser...")
        
        # Check if we need additional required fields
        required_fields = getattr(User, 'REQUIRED_FIELDS', [])
        user_data = {
            'email': email,
            'password': password,
        }
        
        # Add required fields with defaults
        if 'first_name' in required_fields:
            user_data['first_name'] = 'Admin'
        if 'last_name' in required_fields:
            user_data['last_name'] = 'User'
        if 'phone_number' in required_fields:
            user_data['phone_number'] = '+1234567890'
        if 'role' in required_fields:
            user_data['role'] = 'administrator'
        
        user = User.objects.create_user(**user_data)
        
    else:
        # Username-based authentication (standard Django)
        print("Creating username-based superuser...")
        user = User.objects.create_superuser(
            username=username,
            email=email,
            password=password
        )
    
    # Ensure staff and superuser permissions
    user.is_staff = True
    user.is_superuser = True
    user.is_active = True
    user.save()
    
    print(f"✅ Admin user created successfully!")
    print(f"Login field ({username_field}): {getattr(user, username_field)}")
    print(f"Email: {user.email}")
    print(f"Is staff: {user.is_staff}")
    print(f"Is superuser: {user.is_superuser}")
    print(f"Is active: {user.is_active}")

except Exception as e:
    print(f"❌ Error creating user: {e}")
    import traceback
    traceback.print_exc()
EOF
    
    echo "✅ Admin user creation completed for $service"
done

echo ""
echo "=========================================="
echo "Universal Admin User Creation Completed!"
echo ""
echo "🔐 CREDENTIALS:"
echo ""
echo "FOR SERVICES USING EMAIL LOGIN (Auth Service):"
echo "  Email: admin@bidr.com"
echo "  Password: AdminPassword123!"
echo ""
echo "FOR SERVICES USING USERNAME LOGIN (Other Services):"
echo "  Username: admin"
echo "  Password: AdminPassword123!"
echo ""
echo "🌐 LOGIN URLs:"
echo "• Auth Service:         http://108.141.192.60/admin/ (use EMAIL)"
echo "• Chat Service:         http://108.141.192.60/chat/admin/ (use USERNAME)"
echo "• Payment Service:      http://108.141.192.60/payments/admin/ (use USERNAME)"
echo "• Product Service:      http://108.141.192.60/products/admin/ (use USERNAME)"
echo "• Notifications Service: http://108.141.192.60/notifications/admin/ (use USERNAME)"
echo "• Transactions Service: http://108.141.192.60/transactions/admin/ (use USERNAME)"
echo "• Reviews Service:      http://108.141.192.60/reviews/admin/ (use USERNAME)"
echo "• Resolution Service:   http://108.141.192.60/resolution/admin/ (use USERNAME)"
echo "=========================================="
