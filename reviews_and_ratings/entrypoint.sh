#!/bin/bash
set -e

echo "Starting Reviews and Ratings Service..."

# Wait a bit for any dependencies
sleep 2

# Run migrations
echo "Running database migrations..."
python manage.py makemigrations --noinput || echo "Make migrations failed, continuing..."
python manage.py migrate --noinput || echo "Migrations failed, continuing..."

# Collect static files
echo "Collecting static files..."
python manage.py collectstatic --noinput || echo "Static files collection failed, continuing..."

echo "Starting Gunicorn server..."
# Start gunicorn
exec gunicorn \
    --bind 0.0.0.0:8000 \
    --workers 3 \
    --worker-class sync \
    --worker-connections 1000 \
    --max-requests 1000 \
    --max-requests-jitter 100 \
    --timeout 30 \
    --keep-alive 5 \
    --log-level info \
    --access-logfile - \
    --error-logfile - \
    reviews_and_ratings.wsgi:application
