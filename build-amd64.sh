#!/bin/bash

# Build AMD64 images for AKS deployment

echo "🔧 Building AMD64 Images for AKS"
echo "================================"

ACR_NAME="bidrnparusuatregistry2024"

# Login to ACR
echo "📦 Logging into ACR..."
az acr login --name $ACR_NAME

# Build and push auth service for amd64
echo "🔨 Building auth service for linux/amd64..."
cd authentication_service

docker buildx build --platform linux/amd64 \
    -t bidr-authentication_service:amd64 \
    -f Dockerfile.production . --load

docker tag bidr-authentication_service:amd64 ${ACR_NAME}.azurecr.io/bidr-authentication_service:latest
docker push ${ACR_NAME}.azurecr.io/bidr-authentication_service:latest

echo "✅ Auth service AMD64 build complete"

cd ..

echo ""
echo "🚀 Now updating Kubernetes deployment..."
kubectl set image deployment/auth-service auth-service=${ACR_NAME}.azurecr.io/bidr-authentication_service:latest -n bidr

echo ""
echo "⏳ Waiting for rollout..."
kubectl rollout status deployment/auth-service -n bidr --timeout=180s

echo ""
echo "📊 Checking pods..."
kubectl get pods -n bidr | grep auth-service