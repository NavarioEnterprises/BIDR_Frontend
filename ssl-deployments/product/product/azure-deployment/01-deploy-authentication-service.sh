#!/bin/bash

# Deploy Authentication Service to Azure App Service

set -e

# Load the deployment template
source deploy-service-template.sh

# Service-specific configuration
SERVICE_NAME="authentication"
SERVICE_DIR="../authentication_service"
SERVICE_PORT="8001"
DATABASE_NAME="authentication"

# Additional environment variables specific to authentication service
ADDITIONAL_ENV_VARS="DJANGO_SETTINGS_MODULE=authentication_service.settings,JWT_SECRET_KEY=$(openssl rand -base64 32),CORS_ALLOW_ALL_ORIGINS=True"

# Deploy the service
deploy_bidr_service "$SERVICE_NAME" "$SERVICE_DIR" "$SERVICE_PORT" "$DATABASE_NAME" "$ADDITIONAL_ENV_VARS"

echo "Authentication Service deployment completed!"
echo "This service handles user registration, login, and JWT token management."
