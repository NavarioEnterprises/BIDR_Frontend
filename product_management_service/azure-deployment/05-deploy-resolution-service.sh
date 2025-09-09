#!/bin/bash

# Deploy Resolution Service to Azure App Service

set -e

# Load the deployment template
source deploy-service-template.sh

# Service-specific configuration
SERVICE_NAME="resolution"
SERVICE_DIR="../resolution_service"
SERVICE_PORT="8005"
DATABASE_NAME="resolution"

# Additional environment variables specific to resolution service
ADDITIONAL_ENV_VARS="DJANGO_SETTINGS_MODULE=resolution_service.settings,ENABLE_AUTO_RESOLUTION=True,CORS_ALLOW_ALL_ORIGINS=True"

# Deploy the service
deploy_bidr_service "$SERVICE_NAME" "$SERVICE_DIR" "$SERVICE_PORT" "$DATABASE_NAME" "$ADDITIONAL_ENV_VARS"

echo "Resolution Service deployment completed!"
echo "This service handles dispute resolution, mediation, and conflict management."
