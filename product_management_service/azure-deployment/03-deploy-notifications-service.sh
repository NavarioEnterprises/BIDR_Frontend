#!/bin/bash

# Deploy Notifications Service to Azure App Service

set -e

# Load the deployment template
source deploy-service-template.sh

# Service-specific configuration
SERVICE_NAME="notifications"
SERVICE_DIR="../notifications_service"
SERVICE_PORT="8003"
DATABASE_NAME="notifications"

# Additional environment variables specific to notifications service
ADDITIONAL_ENV_VARS="DJANGO_SETTINGS_MODULE=notifications_service.settings,ENABLE_PUSH_NOTIFICATIONS=True,ENABLE_EMAIL_NOTIFICATIONS=True,CORS_ALLOW_ALL_ORIGINS=True"

# Deploy the service
deploy_bidr_service "$SERVICE_NAME" "$SERVICE_DIR" "$SERVICE_PORT" "$DATABASE_NAME" "$ADDITIONAL_ENV_VARS"

echo "Notifications Service deployment completed!"
echo "This service handles push notifications, email notifications, and SMS."
