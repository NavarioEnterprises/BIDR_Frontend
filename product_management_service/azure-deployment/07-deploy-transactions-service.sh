#!/bin/bash

# Deploy Transactions Service to Azure App Service

set -e

# Load the deployment template
source deploy-service-template.sh

# Service-specific configuration
SERVICE_NAME="transactions"
SERVICE_DIR="../transactions_service"
SERVICE_PORT="8007"
DATABASE_NAME="transactions"

# Additional environment variables specific to transactions service
ADDITIONAL_ENV_VARS="DJANGO_SETTINGS_MODULE=transactions_service.settings,ENABLE_TRANSACTION_LOGGING=True,CORS_ALLOW_ALL_ORIGINS=True"

# Deploy the service
deploy_bidr_service "$SERVICE_NAME" "$SERVICE_DIR" "$SERVICE_PORT" "$DATABASE_NAME" "$ADDITIONAL_ENV_VARS"

echo "Transactions Service deployment completed!"
echo "This service handles transaction processing, escrow, and financial records."
