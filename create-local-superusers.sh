#!/bin/bash

# BIDR Backend Local Superuser Creation Script
# This script creates superusers for each Django service running in Docker

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SERVICES=(
    "bidr-auth-service:authentication_service.settings"
    "bidr-chat-service:chat_service.settings"
    "bidr-payment-service:payment_service.settings"
    "bidr-resolution-service:resolution_service.settings"
    "bidr-product-service:product_management_service.settings"
    "bidr-notifications-service:notifications.settings"
    "bidr-transactions-service:transactions_service.settings"
    "bidr-reviews-service:reviews_and_ratings.settings"
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

# Function to create superuser for a service
create_superuser() {
    local container_name=$1
    local settings_module=$2
    
    print_status "Creating superuser for $container_name..."
    
    # Check if container is running
    if ! docker ps --format '{{.Names}}' | grep -q "^${container_name}$"; then
        print_error "Container $container_name is not running"
        return 1
    fi
    
    # Create superuser
    print_status "Creating superuser in container $container_name..."
    
    docker exec -i $container_name python manage.py shell <<EOF
import os
os.environ.setdefault('DJANGO_SETTINGS_MODULE', '$settings_module')

import django
django.setup()

from django.contrib.auth import get_user_model

User = get_user_model()

# Standard credentials for all services
username = 'admin'
email = 'admin@bidr.local'
password = 'bidr_admin_2024'

# Check if superuser already exists
if User.objects.filter(username=username).exists():
    print(f'Superuser {username} already exists')
    user = User.objects.get(username=username)
    user.set_password(password)
    user.save()
    print('Password updated for existing superuser')
else:
    User.objects.create_superuser(username, email, password)
    print(f'Superuser {username} created successfully')
EOF
    
    if [ $? -ne 0 ]; then
        print_error "Failed to create superuser for $container_name"
        return 1
    fi
    
    if [ $? -eq 0 ]; then
        print_success "Superuser created for $container_name"
        echo "  Container: $container_name"
        echo "  Username:  admin"
        echo "  Email:     admin@bidr.local"
        echo "  Password:  bidr_admin_2024"
        echo ""
    fi
}

# Function to run database migrations
run_migrations() {
    local container_name=$1
    
    print_status "Running migrations for $container_name..."
    
    if ! docker ps --format '{{.Names}}' | grep -q "^${container_name}$"; then
        print_error "Container $container_name is not running"
        return 1
    fi
    
    docker exec $container_name python manage.py migrate
    
    if [ $? -eq 0 ]; then
        print_success "Migrations completed for $container_name"
    else
        print_error "Migrations failed for $container_name"
    fi
}

# Main function
main() {
    echo "=========================================="
    echo "BIDR Backend Local Superuser Creation"
    echo "=========================================="
    
    # Check if Docker is running
    if ! docker ps >/dev/null 2>&1; then
        print_error "Docker is not running or not accessible"
        exit 1
    fi
    
    print_status "Found running containers:"
    docker ps --format 'table {{.Names}}\t{{.Status}}' | grep bidr-
    echo ""
    
    # Process each service
    for service_mapping in "${SERVICES[@]}"; do
        IFS=':' read -r container_name settings_module <<< "$service_mapping"
        
        # Check if container exists and is running
        if docker ps --format '{{.Names}}' | grep -q "^${container_name}$"; then
            # Run migrations first
            run_migrations $container_name
            
            # Create superuser
            create_superuser $container_name $settings_module
        else
            print_warning "Container $container_name not found or not running, skipping..."
        fi
    done
    
    print_success "Superuser creation completed!"
    echo ""
    echo "=========================================="
    echo "ACCESS INFORMATION"
    echo "=========================================="
    echo "Common Credentials for all services:"
    echo "  Username: admin"
    echo "  Email:    admin@bidr.local"
    echo "  Password: bidr_admin_2024"
    echo ""
    echo "Direct Service Admin URLs:"
    echo "  Authentication: http://localhost:8001/admin/"
    echo "  Chat:           http://localhost:8002/admin/"
    echo "  Payment:        http://localhost:8003/admin/"
    echo "  Resolution:     http://localhost:8004/admin/"
    echo "  Products:       http://localhost:8005/admin/"
    echo "  Notifications:  http://localhost:8006/admin/"
    echo "  Transactions:   http://localhost:8007/admin/"
    echo "  Reviews:        http://localhost:8008/admin/"
    echo ""
    echo "Via NGINX Gateway (when nginx container is running):"
    echo "  Authentication: http://localhost/admin/auth/"
    echo "  Chat:           http://localhost/admin/chat/"
    echo "  Payment:        http://localhost/admin/payment/"
    echo "  Resolution:     http://localhost/admin/resolution/"
    echo "  Products:       http://localhost/admin/products/"
    echo "  Notifications:  http://localhost/admin/notifications/"
    echo "  Transactions:   http://localhost/admin/transactions/"
    echo "  Reviews:        http://localhost/admin/reviews/"
    echo ""
    echo "Monitoring Services:"
    echo "  Grafana:    http://localhost:3000 (admin/bidr_admin_password_2024)"
    echo "  Prometheus: http://localhost:9090"
    echo ""
    echo "Database Access:"
    echo "  PostgreSQL: localhost:5432 (bidruser/bidr_secure_password_2024)"
    echo "  Redis:      localhost:6379 (password: bidr_redis_password_2024)"
    echo "=========================================="
}

# Run the script
main "$@"
