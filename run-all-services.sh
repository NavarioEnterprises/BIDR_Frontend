#!/bin/bash

# BIDR Backend - Local Services Startup Script
# This script stops any existing processes on the required ports and starts all microservices locally
# Includes virtual environment setup and requirements installation

set -e

echo "🚀 Starting BIDR Backend Services Locally..."

# Define service ports
AUTH_PORT=8001
CHAT_PORT=8002
PAYMENT_PORT=8003
RESOLUTION_PORT=8004
PRODUCTS_PORT=8005
NOTIFICATIONS_PORT=8006
TRANSACTIONS_PORT=8007
REVIEWS_PORT=8008

# Function to kill process on port
kill_port() {
    local port=$1
    local pid=$(lsof -ti:$port 2>/dev/null || true)
    if [ ! -z "$pid" ]; then
        echo "🛑 Stopping process on port $port (PID: $pid)"
        kill -9 $pid 2>/dev/null || true
        sleep 2
    else
        echo "✅ Port $port is free"
    fi
}

# Function to setup virtual environment and install requirements
setup_venv() {
    local service_name=$1
    local service_dir=$2
    
    echo "🔧 Setting up virtual environment for $service_name..."
    
    # Create venv if it doesn't exist
    if [ ! -d "venv" ]; then
        echo "📦 Creating virtual environment for $service_name..."
        python3 -m venv venv
    else
        echo "✅ Virtual environment already exists for $service_name"
    fi
    
    # Activate venv
    source venv/bin/activate
    
    # Upgrade pip
    pip install --upgrade pip --quiet
    
    # Find and install requirements
    local requirements_installed=false
    
    # Try requirements.txt first
    if [ -f "requirements.txt" ]; then
        echo "📋 Installing requirements.txt for $service_name..."
        pip install -r requirements.txt --quiet
        requirements_installed=true
    fi
    
    # Try services-requirements.txt if requirements.txt wasn't found
    if [ "$requirements_installed" = false ] && [ -f "services-requirements.txt" ]; then
        echo "📋 Installing services-requirements.txt for $service_name..."
        pip install -r services-requirements.txt --quiet
        requirements_installed=true
    fi
    
    # Install both if both exist
    if [ "$requirements_installed" = true ] && [ -f "services-requirements.txt" ] && [ -f "requirements.txt" ]; then
        echo "📋 Installing additional services-requirements.txt for $service_name..."
        pip install -r services-requirements.txt --quiet
    fi
    
    if [ "$requirements_installed" = false ]; then
        echo "⚠️  No requirements file found for $service_name, installing Django..."
        pip install django djangorestframework --quiet
    fi
    
    echo "✅ Environment setup complete for $service_name"
}

# Function to start Django service
start_service() {
    local service_name=$1
    local service_dir=$2
    local port=$3
    
    echo "🔄 Starting $service_name on port $port..."
    
    if [ ! -d "$service_dir" ]; then
        echo "❌ Directory $service_dir not found!"
        return 1
    fi
    
    cd "$service_dir"
    
    # Check if manage.py exists
    if [ ! -f "manage.py" ]; then
        echo "❌ manage.py not found in $service_dir"
        cd ..
        return 1
    fi
    
    # Setup virtual environment and requirements
    setup_venv "$service_name" "$service_dir"
    
    # Run migrations if needed
    echo "🔄 Running migrations for $service_name..."
    python manage.py migrate --noinput > /dev/null 2>&1 || echo "⚠️  Migration issues for $service_name (continuing anyway)"
    
    # Start the service in background
    python manage.py runserver 0.0.0.0:$port > "../${service_name}_service.log" 2>&1 &
    local service_pid=$!
    
    echo "✅ $service_name started on port $port (PID: $service_pid)"
    
    # Deactivate venv and return to parent directory
    deactivate 2>/dev/null || true
    cd ..
}

# Stop all processes on required ports
echo "🧹 Cleaning up existing processes..."
kill_port $AUTH_PORT
kill_port $CHAT_PORT
kill_port $PAYMENT_PORT
kill_port $RESOLUTION_PORT
kill_port $PRODUCTS_PORT
kill_port $NOTIFICATIONS_PORT
kill_port $TRANSACTIONS_PORT
kill_port $REVIEWS_PORT

# Wait a moment for ports to be freed
sleep 3

# Start all services
echo "🚀 Starting all services..."

start_service "Authentication" "authentication_service" $AUTH_PORT
start_service "Chat" "chat_service" $CHAT_PORT
start_service "Payment" "payment_service" $PAYMENT_PORT
start_service "Resolution" "resolution_service" $RESOLUTION_PORT
start_service "Products" "product_management_service" $PRODUCTS_PORT
start_service "Notifications" "notifications_service" $NOTIFICATIONS_PORT
start_service "Transactions" "transactions_service" $TRANSACTIONS_PORT
start_service "Reviews" "reviews_and_ratings" $REVIEWS_PORT

# Wait for services to start
echo "⏳ Waiting for services to initialize..."
sleep 10

# Check service health
echo "🔍 Checking service health..."
check_service() {
    local service_name=$1
    local port=$2
    local response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:$port/ 2>/dev/null || echo "000")
    if [ "$response" != "000" ]; then
        echo "✅ $service_name is responding on port $port"
    else
        echo "❌ $service_name is not responding on port $port"
    fi
}

check_service "Authentication" $AUTH_PORT
check_service "Chat" $CHAT_PORT
check_service "Payment" $PAYMENT_PORT
check_service "Resolution" $RESOLUTION_PORT
check_service "Products" $PRODUCTS_PORT
check_service "Notifications" $NOTIFICATIONS_PORT
check_service "Transactions" $TRANSACTIONS_PORT
check_service "Reviews" $REVIEWS_PORT

echo ""
echo "🎉 All services have been started!"
echo ""
echo "📋 Service URLs:"
echo "   Authentication: http://localhost:$AUTH_PORT/"
echo "   Chat:          http://localhost:$CHAT_PORT/"
echo "   Payment:       http://localhost:$PAYMENT_PORT/"
echo "   Resolution:    http://localhost:$RESOLUTION_PORT/"
echo "   Products:      http://localhost:$PRODUCTS_PORT/"
echo "   Notifications: http://localhost:$NOTIFICATIONS_PORT/"
echo "   Transactions:  http://localhost:$TRANSACTIONS_PORT/"
echo "   Reviews:       http://localhost:$REVIEWS_PORT/"
echo ""
echo "📝 Logs are available in the following files:"
echo "   Authentication: authentication_service.log"
echo "   Chat:          chat_service.log"
echo "   Payment:       payment_service.log"
echo "   Resolution:    resolution_service.log"
echo "   Products:      product_management_service.log"
echo "   Notifications: notifications_service.log"
echo "   Transactions:  transactions_service.log"
echo "   Reviews:       reviews_and_ratings.log"
echo ""
echo "🛑 To stop all services, run: ./stop-all-services.sh"
echo ""
echo "💡 Use 'tail -f *.log' to monitor all service logs in real-time"