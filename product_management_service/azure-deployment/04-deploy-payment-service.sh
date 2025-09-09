#!/bin/bash

# Deploy Payment Service to Azure App Service

set -e

# Load the deployment template
source deploy-service-template.sh

# Service-specific configuration
SERVICE_NAME="payment"
SERVICE_DIR="../payment_service"
SERVICE_PORT="8004"
DATABASE_NAME="payments"

# Additional environment variables specific to payment service
ADDITIONAL_ENV_VARS="DJANGO_SETTINGS_MODULE=payment_service.settings,ENABLE_STRIPE=True,ENABLE_PAYPAL=True,CORS_ALLOW_ALL_ORIGINS=True"

# Deploy the service
deploy_bidr_service "$SERVICE_NAME" "$SERVICE_DIR" "$SERVICE_PORT" "$DATABASE_NAME" "$ADDITIONAL_ENV_VARS"

echo "Payment Service deployment completed!"
echo "This service handles payment processing, refunds, and payment methods."
