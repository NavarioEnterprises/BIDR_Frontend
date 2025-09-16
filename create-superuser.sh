#!/bin/bash

set -e

echo "🔧 Creating BIDR Superuser"

# Default credentials
EMAIL="admin@bidr.com"
PASSWORD="BIDRAdmin2025!"

# Allow custom credentials via arguments
if [ "$1" ]; then
    EMAIL="$1"
fi

if [ "$2" ]; then
    PASSWORD="$2"
fi

echo "📧 Email: $EMAIL"
echo "🔑 Password: $PASSWORD"
echo ""

# Check if kubectl is configured
if ! kubectl cluster-info &> /dev/null; then
    echo "❌ kubectl is not configured. Please ensure you're connected to the BIDR AKS cluster."
    exit 1
fi

# Check if the bidr namespace exists
if ! kubectl get namespace bidr &> /dev/null; then
    echo "❌ BIDR namespace doesn't exist. Please deploy the application first."
    exit 1
fi

# Create superuser in the container
echo "🚀 Creating superuser in the BIDR application..."

kubectl exec -it deployment/bidr-app -n bidr -- bash -c "
export DJANGO_SUPERUSER_EMAIL='$EMAIL'
export DJANGO_SUPERUSER_PASSWORD='$PASSWORD'
python manage.py createsuperuser --noinput --email $EMAIL 2>/dev/null || echo 'User may already exist, recreating...'
"

echo ""
echo "✅ Superuser created/updated successfully!"
echo ""
echo "🎉 BIDR Admin Credentials:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📧 Email:    $EMAIL"
echo "🔑 Password: $PASSWORD"
echo "🌐 Admin URL: http://20.66.69.82:8067/admin/"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "💡 Use these credentials to log into the Django admin interface"
echo ""
echo "🔍 To test the credentials:"
echo "   1. Open http://20.66.69.82:8067/admin/ in your browser"
echo "   2. Log in with the credentials above"
