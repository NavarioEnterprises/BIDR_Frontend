#!/bin/bash

# Deploy Product Management Service to Azure App Service

set -e

# Load the deployment template
source deploy-service-template.sh

# Service-specific configuration
SERVICE_NAME="product"
SERVICE_DIR="../product_management_service"
SERVICE_PORT="8000"
DATABASE_NAME="products"

# Additional environment variables specific to product management service
ADDITIONAL_ENV_VARS="DJANGO_SETTINGS_MODULE=product_management_service.settings,USE_ENCRYPTION=True,ENABLE_ANALYTICS=True,CORS_ALLOW_ALL_ORIGINS=True"

# Deploy the service
deploy_bidr_service "$SERVICE_NAME" "$SERVICE_DIR" "$SERVICE_PORT" "$DATABASE_NAME" "$ADDITIONAL_ENV_VARS"

echo "Product Management Service deployment completed!"
echo "This service handles product requests, quotes, transactions, and categories."
