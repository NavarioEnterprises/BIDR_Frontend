# Dockerfile template for SSL-enabled BIDR services
# This creates a container with nginx SSL termination and the Django service

FROM python:3.11-slim

# Set environment variables
ENV PYTHONUNBUFFERED=1
ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies
RUN apt-get update && apt-get install -y \
    nginx \
    supervisor \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Create application directory
WORKDIR /app

# Copy service code
COPY reviews/ /app/

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Create SSL certificate directories
RUN mkdir -p /etc/ssl/certs/reviews /etc/ssl/private/reviews

# Copy SSL certificates
COPY ssl-certs/reviews/ /etc/ssl/certs/reviews/
COPY ssl-keys/reviews/ /etc/ssl/private/reviews/

# Set proper permissions for SSL certificates
RUN chmod 644 /etc/ssl/certs/reviews/fullchain.pem && \
    chmod 600 /etc/ssl/private/reviews/privkey.pem

# Copy nginx configuration
COPY nginx-reviews.conf /etc/nginx/sites-available/default

# Remove default nginx site
RUN rm -f /etc/nginx/sites-enabled/default && \
    ln -s /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default

# Create supervisor configuration
RUN echo "[supervisord]" > /etc/supervisor/conf.d/supervisord.conf && \
    echo "nodaemon=true" >> /etc/supervisor/conf.d/supervisord.conf && \
    echo "" >> /etc/supervisor/conf.d/supervisord.conf && \
    echo "[program:nginx]" >> /etc/supervisor/conf.d/supervisord.conf && \
    echo "command=nginx -g 'daemon off;'" >> /etc/supervisor/conf.d/supervisord.conf && \
    echo "autostart=true" >> /etc/supervisor/conf.d/supervisord.conf && \
    echo "autorestart=true" >> /etc/supervisor/conf.d/supervisord.conf && \
    echo "stderr_logfile=/var/log/nginx_error.log" >> /etc/supervisor/conf.d/supervisord.conf && \
    echo "stdout_logfile=/var/log/nginx_access.log" >> /etc/supervisor/conf.d/supervisord.conf && \
    echo "" >> /etc/supervisor/conf.d/supervisord.conf && \
    echo "[program:django]" >> /etc/supervisor/conf.d/supervisord.conf && \
    echo "command=gunicorn reviews.wsgi:application --bind 127.0.0.1:8007 --workers 4" >> /etc/supervisor/conf.d/supervisord.conf && \
    echo "directory=/app" >> /etc/supervisor/conf.d/supervisord.conf && \
    echo "autostart=true" >> /etc/supervisor/conf.d/supervisord.conf && \
    echo "autorestart=true" >> /etc/supervisor/conf.d/supervisord.conf && \
    echo "stderr_logfile=/var/log/django_error.log" >> /etc/supervisor/conf.d/supervisord.conf && \
    echo "stdout_logfile=/var/log/django_access.log" >> /etc/supervisor/conf.d/supervisord.conf

# Create log directory
RUN mkdir -p /var/log/nginx

# Expose HTTPS port
EXPOSE 443 80

# Health check
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
    CMD curl -f -k https://localhost/health/ || exit 1

# Start supervisor
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
