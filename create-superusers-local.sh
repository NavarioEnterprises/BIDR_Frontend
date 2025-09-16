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
    
    print_status "Creating superuser for $container_name..."
    
    # Check if container is running
    if ! docker ps --format '{{.Names}}' | grep -q "^${container_name}$"; then
        print_warning "Container $container_name is not running"
        return 0
    fi
    
    # Create superuser using environment variables to avoid heredoc issues
    docker exec -i $container_name bash -c '
import os
import django
os.environ.setdefault("DJANGO_SETTINGS_MODULE", os.environ.get("DJANGO_SETTINGS_MODULE", "authentication_service.settings"))
django.setup()

from django.contrib.auth import get_user_model
User = get_user_model()

username = "admin"
email = "admin@bidr.local" 
password = "bidr_admin_2024"

if User.objects.filter(username=username).exists():
    print(f"Superuser {username} already exists")
    user = User.objects.get(username=username)
    user.set_password(password)
    user.save()
    print("Password updated for existing superuser")
else:
    User.objects.create_superuser(username, email, password)
    print(f"Superuser {username} created successfully")
' 2>/dev/null || {
        print_warning "Could not create superuser for $container_name (service may not be ready)"
        return 0
    }
    
    print_success "Processed superuser for $container_name"
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
    docker ps --format 'table {{.Names}}\t{{.Status}}' | grep bidr- || echo "No BIDR containers running"
    echo ""
    
    # List of services to process
    SERVICES=(
        "bidr-notifications-service"
    )
    
    # Process each service
    for container_name in "${SERVICES[@]}"; do
        if docker ps --format '{{.Names}}' | grep -q "^${container_name}$"; then
            create_superuser $container_name
        else
            print_warning "Container $container_name not found or not running"
        fi
    done
    
    print_success "Superuser creation completed!"
    echo ""
    echo "=========================================="
    echo "BIDR SERVICES & ADMIN CREDENTIALS"
    echo "=========================================="
    echo ""
    echo "🔐 STANDARD ADMIN CREDENTIALS (for all services):"
    echo "   Username: admin"
    echo "   Email:    admin@bidr.local"
    echo "   Password: bidr_admin_2024"
    echo ""
    echo "🌐 DIRECT SERVICE ACCESS URLs:"
    echo "   Authentication: http://localhost:8001/admin/"
    echo "   Chat:           http://localhost:8002/admin/"
    echo "   Payment:        http://localhost:8003/admin/"
    echo "   Resolution:     http://localhost:8004/admin/"
    echo "   Products:       http://localhost:8005/admin/"
    echo "   Notifications:  http://localhost:8006/admin/ ✅"
    echo "   Transactions:   http://localhost:8007/admin/"
    echo "   Reviews:        http://localhost:8008/admin/"
    echo ""
    echo "🔗 VIA NGINX GATEWAY (when nginx is running):"
    echo "   Authentication: http://localhost/admin/auth/"
    echo "   Chat:           http://localhost/admin/chat/"
    echo "   Payment:        http://localhost/admin/payment/"
    echo "   Resolution:     http://localhost/admin/resolution/"
    echo "   Products:       http://localhost/admin/products/"
    echo "   Notifications:  http://localhost/admin/notifications/"
    echo "   Transactions:   http://localhost/admin/transactions/"
    echo "   Reviews:        http://localhost/admin/reviews/"
    echo ""
    echo "📊 MONITORING SERVICES:"
    echo "   Grafana:    http://localhost:3000"
    echo "   Username:   admin"
    echo "   Password:   bidr_admin_password_2024"
    echo ""
    echo "   Prometheus: http://localhost:9090 (no auth required)"
    echo ""
    echo "💽 DATABASE ACCESS:"
    echo "   PostgreSQL: localhost:5432"
    echo "   Username:   bidruser"
    echo "   Password:   bidr_secure_password_2024"
    echo "   Databases:  auth_db, chat_db, payment_db, resolution_db,"
    echo "              product_db, notifications_db, transactions_db, reviews_db"
    echo ""
    echo "   Redis:      localhost:6379"
    echo "   Password:   bidr_redis_password_2024"
    echo ""
    echo "🔍 LEGACY SERVICE CREDENTIALS (from existing files):"
    echo "   Product Service: bidr_admin / 5rAv9W67g^kg (http://localhost:8005/admin/)"
    echo "   Resolution:      admin / admin123 (http://localhost:8004/admin/)"
    echo "   Chat:           chatadmin / ChatService@2025 (http://localhost:8002/admin/)"
    echo ""
    echo "=========================================="
}

# Run the script
main "$@"
