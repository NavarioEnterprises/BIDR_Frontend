#!/bin/bash

echo "🔧 Rebuilding Auth Service with Missing Dependencies"
echo "=================================================="

ACR_NAME="bidrnparusuatregistry2024"

# Login to ACR
az acr login --name $ACR_NAME

# Build auth service for amd64 with updated requirements
echo "🔨 Building auth service with requests library..."
cd authentication_service

docker buildx build --platform linux/amd64 \
    -t bidr-authentication_service:fixed \
    -f Dockerfile.production . --load

docker tag bidr-authentication_service:fixed ${ACR_NAME}.azurecr.io/bidr-authentication_service:latest
docker push ${ACR_NAME}.azurecr.io/bidr-authentication_service:latest

echo "✅ Auth service rebuilt and pushed"

cd ..

echo "🔄 Rolling out updated image..."
kubectl rollout restart deployment/auth-service -n bidr
kubectl rollout status deployment/auth-service -n bidr --timeout=180s

echo "📊 Checking pods..."
kubectl get pods -n bidr | grep auth-service

echo "🧪 Testing endpoint..."
sleep 10
kubectl logs $(kubectl get pods -n bidr | grep auth-service | grep Running | awk '{print $1}' | head -1) -n bidr --tail=5