#!/bin/bash

# Deploy Chat Service to Azure App Service

set -e

# Load the deployment template
source deploy-service-template.sh

# Service-specific configuration
SERVICE_NAME="chat"
SERVICE_DIR="../chat_service"
SERVICE_PORT="8008"
DATABASE_NAME="chat"

# Additional environment variables specific to chat service
ADDITIONAL_ENV_VARS="DJANGO_SETTINGS_MODULE=chat_service.settings,ENABLE_REALTIME_CHAT=True,CORS_ALLOW_ALL_ORIGINS=True"

# Deploy the service
deploy_bidr_service "$SERVICE_NAME" "$SERVICE_DIR" "$SERVICE_PORT" "$DATABASE_NAME" "$ADDITIONAL_ENV_VARS"

echo "Chat Service deployment completed!"
echo "This service handles real-time messaging, chat rooms, and communication."
