#!/bin/sh
set -e

echo "=== Debugging Python Environment ==="
echo "Python version:"
python3 --version

echo "Pip list:"
pip list

echo "Checking for gunicorn:"
pip show gunicorn || echo "gunicorn not found in pip list"

echo "Checking PATH:"
echo $PATH

echo "Which python3:"
which python3

echo "Trying to find gunicorn:"
find /usr/local -name "gunicorn*" 2>/dev/null || echo "gunicorn executable not found"

echo "=== Starting Application ==="
python3 manage.py collectstatic --noinput

# Try different ways to run gunicorn
echo "Attempting to start gunicorn..."
if command -v gunicorn > /dev/null 2>&1; then
    echo "Using direct gunicorn command"
    exec gunicorn --bind 0.0.0.0:8000 --workers 4 bidr_project.wsgi:application --timeout 600
else
    echo "Using python -m gunicorn"
    exec python3 -m gunicorn --bind 0.0.0.0:8000 --workers 4 bidr_project.wsgi:application --timeout 600
fi
