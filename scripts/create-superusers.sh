#!/bin/bash

# BIDR Backend Superuser Creation Script
# This script creates superusers for each Django service

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
NAMESPACE="bidr"

# Services and their Django settings modules
SERVICES=(
    "auth-service:authentication_service.settings"
    "chat-service:chat_service.settings"
    "payment-service:payment_service.settings"
    "resolution-service:resolution_service.settings"
    "product-service:product_management_service.settings"
    "notifications-service:notifications.settings"
    "transactions-service:transactions_service.settings"
    "reviews-service:reviews_and_ratings.settings"
)

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to generate random password
generate_password() {
    openssl rand -base64 12
}

# Function to create superuser for a service
create_superuser() {
    local service_name=$1
    local settings_module=$2
    
    print_status "Creating superuser for $service_name..."
    
    # Get first pod for the service
    local pod=$(kubectl get pods -n $NAMESPACE -l app=$service_name -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
    
    if [ -z "$pod" ]; then
        print_error "No pod found for service $service_name"
        return 1
    fi
    
    # Generate credentials
    local username="admin"
    local email="admin@bidr.local"
    local password=$(generate_password)
    
    # Create superuser
    print_status "Creating superuser in pod $pod..."
    
    kubectl exec -n $NAMESPACE $pod -- python manage.py shell << EOF || {
        print_error "Failed to create superuser for $service_name"
        return 1
    }
import os
os.environ.setdefault('DJANGO_SETTINGS_MODULE', '$settings_module')

import django
django.setup()

from django.contrib.auth import get_user_model

User = get_user_model()

# Check if superuser already exists
if User.objects.filter(username='$username').exists():
    print('Superuser $username already exists')
    user = User.objects.get(username='$username')
    user.set_password('$password')
    user.save()
    print('Password updated for existing superuser')
else:
    User.objects.create_superuser('$username', '$email', '$password')
    print('Superuser $username created successfully')
EOF
    
    if [ $? -eq 0 ]; then
        print_success "Superuser created for $service_name"
        echo "  Service:  $service_name"
        echo "  Username: $username"
        echo "  Email:    $email"
        echo "  Password: $password"
        echo "  Admin URL: http://[LOAD_BALANCER_IP]/admin/$(echo $service_name | cut -d'-' -f1)/"
        echo ""
        
        # Store credentials in a file
        echo "$service_name,$username,$email,$password" >> bidr-admin-credentials.csv
    fi
}

# Function to run database migrations
run_migrations() {
    local service_name=$1
    
    print_status "Running migrations for $service_name..."
    
    local pod=$(kubectl get pods -n $NAMESPACE -l app=$service_name -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
    
    if [ -z "$pod" ]; then
        print_error "No pod found for service $service_name"
        return 1
    fi
    
    kubectl exec -n $NAMESPACE $pod -- python manage.py migrate
    
    if [ $? -eq 0 ]; then
        print_success "Migrations completed for $service_name"
    else
        print_error "Migrations failed for $service_name"
    fi
}

# Main function
main() {
    echo "=========================================="
    echo "BIDR Backend Superuser Creation Script"
    echo "=========================================="
    
    # Check if kubectl is available
    if ! command -v kubectl >/dev/null 2>&1; then
        print_error "kubectl is required but not installed"
        exit 1
    fi
    
    # Check if namespace exists
    if ! kubectl get namespace $NAMESPACE >/dev/null 2>&1; then
        print_error "Namespace $NAMESPACE does not exist"
        exit 1
    fi
    
    # Create credentials file header
    echo "Service,Username,Email,Password" > bidr-admin-credentials.csv
    
    print_status "Found services in namespace $NAMESPACE:"
    kubectl get deployments -n $NAMESPACE -o name | sed 's/deployment.apps\///' | while read service; do
        echo "  - $service"
    done
    echo ""
    
    # Process each service
    for service_mapping in "${SERVICES[@]}"; do
        IFS=':' read -r service_name settings_module <<< "$service_mapping"
        
        # Check if deployment exists
        if kubectl get deployment $service_name -n $NAMESPACE >/dev/null 2>&1; then
            # Run migrations first
            run_migrations $service_name
            
            # Create superuser
            create_superuser $service_name $settings_module
        else
            print_warning "Deployment $service_name not found, skipping..."
        fi
    done
    
    print_success "Superuser creation completed!"
    print_status "Admin credentials saved to: bidr-admin-credentials.csv"
    
    # Display load balancer IP
    local lb_ip=$(kubectl get service bidr-loadbalancer -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "pending")
    
    if [ "$lb_ip" != "pending" ] && [ -n "$lb_ip" ]; then
        echo ""
        print_success "Access admin interfaces at:"
        echo "  Authentication: http://$lb_ip/admin/auth/"
        echo "  Chat:          http://$lb_ip/admin/chat/"
        echo "  Payment:       http://$lb_ip/admin/payment/"
        echo "  Resolution:    http://$lb_ip/admin/resolution/"
        echo "  Products:      http://$lb_ip/admin/products/"
        echo "  Notifications: http://$lb_ip/admin/notifications/"
        echo "  Transactions:  http://$lb_ip/admin/transactions/"
        echo "  Reviews:       http://$lb_ip/admin/reviews/"
    else
        print_warning "LoadBalancer IP is still pending. Get it with:"
        echo "kubectl get service bidr-loadbalancer -n $NAMESPACE"
    fi
}

# Run the script
main "$@"
