#!/bin/bash

# BIDR Backend Local Development Script
# This script runs the BIDR backend services locally using Docker Compose

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

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    local missing_commands=()
    
    if ! command_exists docker; then
        missing_commands+=("docker")
    fi
    
    if ! command_exists docker-compose; then
        missing_commands+=("docker-compose")
    fi
    
    if [ ${#missing_commands[@]} -ne 0 ]; then
        print_error "Missing required commands: ${missing_commands[*]}"
        print_error "Please install them and try again."
        exit 1
    fi
    
    print_success "All prerequisites found"
}

# Function to generate local environment file
create_env_file() {
    if [ ! -f ".env" ]; then
        print_status "Creating .env file..."
        cat > .env << 'EOF'
# BIDR Backend Local Development Environment

# Django Configuration
DEBUG=True
SECRET_KEY=your-local-development-secret-key-change-this-in-production
ALLOWED_HOSTS=localhost,127.0.0.1,0.0.0.0

# Database Configuration
DB_HOST=postgres
DB_PORT=5432
DB_NAME=bidr_db
DB_USER=bidruser
DB_PASSWORD=bidr_secure_password_2024

# Redis Configuration
REDIS_HOST=redis
REDIS_PORT=6379
REDIS_PASSWORD=bidr_redis_password_2024

# Email Configuration (for local testing)
EMAIL_BACKEND=django.core.mail.backends.console.EmailBackend
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_USE_TLS=True
EMAIL_HOST_USER=your-email@gmail.com
EMAIL_HOST_PASSWORD=your-app-password

# Payment Configuration (use test keys)
PAYSTACK_PUBLIC_KEY=pk_test_your_test_public_key
PAYSTACK_SECRET_KEY=sk_test_your_test_secret_key

# File Upload Configuration
MEDIA_URL=/media/
STATIC_URL=/static/
EOF
        print_success ".env file created"
    else
        print_warning ".env file already exists"
    fi
}

# Function to create admin users locally
create_local_superusers() {
    print_status "Creating superusers for local services..."
    
    local services=("auth-service" "chat-service" "payment-service" "resolution-service" "product-service" "notifications-service" "transactions-service" "reviews-service")
    
    # Create credentials file header
    echo "Service,Username,Email,Password" > bidr-local-admin-credentials.csv
    
    for service in "${services[@]}"; do
        print_status "Creating superuser for $service..."
        
        local username="admin"
        local email="admin@bidr.local"
        local password="admin123"
        
        # Try to create superuser in the running container
        if docker-compose -f docker-compose.full.yml exec -T $service python manage.py shell << EOF 2>/dev/null; then
import os
import django
django.setup()

from django.contrib.auth import get_user_model

User = get_user_model()

if User.objects.filter(username='$username').exists():
    print('Superuser $username already exists for $service')
    user = User.objects.get(username='$username')
    user.set_password('$password')
    user.save()
    print('Password updated for existing superuser')
else:
    try:
        User.objects.create_superuser('$username', '$email', '$password')
        print('Superuser $username created successfully for $service')
    except Exception as e:
        print(f'Error creating superuser for $service: {e}')
EOF
            print_success "Superuser created for $service"
            echo "$service,$username,$email,$password" >> bidr-local-admin-credentials.csv
        else
            print_warning "Failed to create superuser for $service (service might not be ready yet)"
        fi
    done
    
    print_success "Local superuser creation completed!"
    print_status "Credentials saved to: bidr-local-admin-credentials.csv"
}

# Function to show service URLs
show_service_urls() {
    print_success "BIDR services are running locally:"
    echo ""
    echo "🔐 Authentication Service: http://localhost:8001"
    echo "   Admin: http://localhost:8001/admin/"
    echo ""
    echo "💬 Chat Service: http://localhost:8002" 
    echo "   Admin: http://localhost:8002/admin/"
    echo ""
    echo "💳 Payment Service: http://localhost:8003"
    echo "   Admin: http://localhost:8003/admin/"
    echo ""
    echo "⚖️  Resolution Service: http://localhost:8004"
    echo "   Admin: http://localhost:8004/admin/"
    echo ""
    echo "📦 Product Service: http://localhost:8005"
    echo "   Admin: http://localhost:8005/admin/"
    echo ""
    echo "🔔 Notifications Service: http://localhost:8006"
    echo "   Admin: http://localhost:8006/admin/"
    echo ""
    echo "💸 Transactions Service: http://localhost:8007"
    echo "   Admin: http://localhost:8007/admin/"
    echo ""
    echo "⭐ Reviews Service: http://localhost:8008"
    echo "   Admin: http://localhost:8008/admin/"
    echo ""
    echo "🌐 API Gateway (NGINX): http://localhost"
    echo ""
    echo "📊 Monitoring:"
    echo "   Prometheus: http://localhost:9090"
    echo "   Grafana: http://localhost:3000"
    echo "   Grafana Login: admin / bidr_admin_password_2024"
    echo ""
    echo "🗄️  Database & Cache:"
    echo "   PostgreSQL: localhost:5432"
    echo "   Redis: localhost:6379"
}

# Function to run migrations
run_migrations() {
    print_status "Running database migrations..."
    
    local services=("auth-service" "chat-service" "payment-service" "resolution-service" "product-service" "notifications-service" "transactions-service" "reviews-service")
    
    for service in "${services[@]}"; do
        print_status "Running migrations for $service..."
        if docker-compose -f docker-compose.full.yml exec -T $service python manage.py migrate 2>/dev/null; then
            print_success "Migrations completed for $service"
        else
            print_warning "Migration failed for $service (service might not be ready yet)"
        fi
    done
    
    print_success "Migrations completed"
}

# Main function
main() {
    echo "=========================================="
    echo "BIDR Backend Local Development"
    echo "=========================================="
    
    check_prerequisites
    create_env_file
    
    case "${1:-up}" in
        "up"|"start")
            print_status "Starting BIDR services locally..."
            docker-compose -f docker-compose.full.yml up -d
            
            print_status "Waiting for services to start..."
            sleep 30
            
            run_migrations
            create_local_superusers
            show_service_urls
            
            print_success "All services started successfully!"
            print_status "Use 'docker-compose -f docker-compose.full.yml logs -f' to view logs"
            ;;
            
        "down"|"stop")
            print_status "Stopping BIDR services..."
            docker-compose -f docker-compose.full.yml down
            print_success "Services stopped"
            ;;
            
        "restart")
            print_status "Restarting BIDR services..."
            docker-compose -f docker-compose.full.yml down
            docker-compose -f docker-compose.full.yml up -d
            print_success "Services restarted"
            ;;
            
        "logs")
            docker-compose -f docker-compose.full.yml logs -f
            ;;
            
        "status")
            print_status "Service status:"
            docker-compose -f docker-compose.full.yml ps
            ;;
            
        "clean")
            print_warning "This will remove all containers, volumes, and data!"
            read -p "Are you sure? (y/N) " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                docker-compose -f docker-compose.full.yml down -v --remove-orphans
                docker system prune -f
                print_success "Cleanup completed"
            fi
            ;;
            
        "build")
            print_status "Building all service images..."
            docker-compose -f docker-compose.full.yml build --no-cache
            print_success "Build completed"
            ;;
            
        "shell")
            if [ -z "$2" ]; then
                print_error "Please specify a service name: $0 shell <service-name>"
                print_status "Available services: auth-service, chat-service, payment-service, etc."
                exit 1
            fi
            docker-compose -f docker-compose.full.yml exec "$2" /bin/bash
            ;;
            
        "help"|*)
            echo "Usage: $0 [command]"
            echo ""
            echo "Commands:"
            echo "  up|start    - Start all services (default)"
            echo "  down|stop   - Stop all services"
            echo "  restart     - Restart all services"
            echo "  logs        - Show logs for all services"
            echo "  status      - Show status of all services"
            echo "  build       - Build all service images"
            echo "  clean       - Clean up containers and volumes"
            echo "  shell <service> - Open shell in service container"
            echo "  help        - Show this help message"
            ;;
    esac
}

# Run the script
main "$@"
