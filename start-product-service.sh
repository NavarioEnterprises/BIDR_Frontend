#!/bin/bash

# Start Product Management Service with correct virtual environment
echo "🚀 Starting Product Management Service..."

cd "/Users/thulanimoyo/MEGA downloads/new downloads/BIDR_Backend/product_management_service"

# Activate the correct virtual environment
source venv/bin/activate

# Start the Django development server
echo "✅ Virtual environment activated"
echo "✅ Starting Django server on port 8002..."

python manage.py runserver 0.0.0.0:8002