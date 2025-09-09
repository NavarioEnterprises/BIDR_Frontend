#!/bin/bash

# Deploy Reviews and Ratings Service to Azure App Service

set -e

# Load the deployment template
source deploy-service-template.sh

# Service-specific configuration
SERVICE_NAME="reviews"
SERVICE_DIR="../reviews_and_ratings"
SERVICE_PORT="8006"
DATABASE_NAME="reviews"

# Additional environment variables specific to reviews service
ADDITIONAL_ENV_VARS="DJANGO_SETTINGS_MODULE=reviews_and_ratings.settings,ENABLE_RATING_ANALYTICS=True,CORS_ALLOW_ALL_ORIGINS=True"

# Deploy the service
deploy_bidr_service "$SERVICE_NAME" "$SERVICE_DIR" "$SERVICE_PORT" "$DATABASE_NAME" "$ADDITIONAL_ENV_VARS"

echo "Reviews and Ratings Service deployment completed!"
echo "This service handles user reviews, ratings, and feedback management."
