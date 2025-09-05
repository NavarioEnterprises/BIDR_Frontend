#!/bin/bash

# BIDR notifications Service Update Script
set -e
echo "🔄 Updating BIDR notifications Service..."

RESOURCE_GROUP="bidr-simple-rg"
REGISTRY_NAME="bidrsimpleregistry"
CONTAINER_NAME="bidr-notifications-service"
IMAGE_NAME="bidr-notifications-service"
notifications_8005=8005

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
notifications_DIR="$(dirname "$SCRIPT_DIR")/notifications_service"

if [ ! -d "$notifications_DIR" ]; then
    echo "❌ notifications service directory not found at: $notifications_DIR"
    exit 1
fi

cd "$notifications_DIR"
echo "Changed to notifications service directory"

TIMESTAMP=$(date +%s)
NEW_TAG="v$TIMESTAMP"

echo "Step 1: Building new Docker image with tag: $NEW_TAG..."
az acr build --registry $REGISTRY_NAME --image "${IMAGE_NAME}:${NEW_TAG}" --image "${IMAGE_NAME}:latest" .

echo "Step 2: Stopping existing container..."
az container delete --resource-group $RESOURCE_GROUP --name $CONTAINER_NAME --yes --no-wait 2>/dev/null || echo "No existing container to delete"
sleep 10

echo "Step 3: Getting registry credentials..."
REGISTRY_SERVER="${REGISTRY_NAME}.azurecr.io"
REGISTRY_USERNAME=$(az acr credential show --name $REGISTRY_NAME --query username --output tsv)
REGISTRY_PASSWORD=$(az acr credential show --name $REGISTRY_NAME --query passwords[0].value --output tsv)

echo "Step 4: Deploying updated container..."
DNS_LABEL="bidr-notifications-$(date +%s)"
SECRET_KEY=$(python3 -c "import secrets; print(secrets.token_urlsafe(32))")
JWT_SECRET_KEY=$(python3 -c "import secrets; print(secrets.token_urlsafe(32))")

az container create \
    --resource-group $RESOURCE_GROUP \
    --name $CONTAINER_NAME \
    --image "${REGISTRY_SERVER}/${IMAGE_NAME}:latest" \
    --registry-login-server $REGISTRY_SERVER \
    --registry-username $REGISTRY_USERNAME \
    --registry-password $REGISTRY_PASSWORD \
    --dns-name-label $DNS_LABEL \
    --ports $notifications_8005 \
    --cpu 1 \
    --memory 1.5 \
    --restart-policy OnFailure \
    --os-type Linux \
    --environment-variables \
        SECRET_KEY="$SECRET_KEY" \
        DEBUG=False \
        ALLOWED_HOSTS="*" \
        DJANGO_SETTINGS_MODULE=notifications_service.settings \
        JWT_SECRET_KEY="$JWT_SECRET_KEY" \
        CORS_ALLOW_ALL_ORIGINS=True \
    --no-wait

echo "✅ Container deployment initiated"

echo "Step 5: Waiting for deployment..."
sleep 30

NEW_CONTAINER_INFO=$(az container show \
    --resource-group $RESOURCE_GROUP \
    --name $CONTAINER_NAME \
    --query '{ip: ipAddress.ip, fqdn: ipAddress.fqdn, state: instanceView.state}' \
    --output json)

NEW_FQDN=$(echo $NEW_CONTAINER_INFO | jq -r '.fqdn // "N/A"')
CONTAINER_STATE=$(echo $NEW_CONTAINER_INFO | jq -r '.state // "Unknown"')

echo "🎉 notifications Service Updated!"
echo "Image Tag: $NEW_TAG"
echo "Container State: $CONTAINER_STATE"
echo "Service URL: http://${NEW_FQDN}:${notifications_8005}"
echo "🎯 Health Check: curl http://${NEW_FQDN}:${notifications_8005}/health/"
