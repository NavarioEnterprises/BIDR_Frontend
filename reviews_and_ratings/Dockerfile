# Use Python 3.11 slim image
FROM python:3.11-slim

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV DJANGO_SETTINGS_MODULE=reviews_and_ratings.settings

# Set work directory
WORKDIR /app

# Install system dependencies
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        postgresql-client \
        build-essential \
        libpq-dev \
        curl \
        git \
    && rm -rf /var/lib/apt/lists/*

# Create a non-root user early
RUN adduser --disabled-password --gecos '' --uid 1000 appuser

# Copy common requirements
COPY services-requirements.txt /app/requirements.txt

RUN pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir -r requirements.txt

# Copy project to correct location
COPY . /app/reviews_and_ratings/

# Set working directory to reviews and ratings service
WORKDIR /app/reviews_and_ratings

# Copy and set up entrypoint script (do this before switching to non-root user)
COPY entrypoint.sh /app/reviews_and_ratings/entrypoint.sh
RUN chmod +x /app/reviews_and_ratings/entrypoint.sh

# Create necessary directories and set permissions
RUN mkdir -p /app/staticfiles /app/media /app/logs \
    && chown -R appuser:appuser /app

# Switch to non-root user
USER appuser

# Collect static files (skip if it fails in build)
RUN python manage.py collectstatic --noinput || echo "Static files collection skipped"

# Run migrations (safe to run multiple times)
RUN python manage.py migrate || echo "Migration failed, will retry at startup"

# Health check
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/health/ || exit 1

# Expose port
EXPOSE 8000

# Use entrypoint script
ENTRYPOINT ["/app/reviews_and_ratings/entrypoint.sh"]
