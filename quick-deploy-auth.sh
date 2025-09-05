#!/bin/bash

# Quick Deploy - Fast iteration for development
# Builds and deploys your local auth service in under 2 minutes

set -e

SERVICE_NAME="auth-service"
NAMESPACE="bidr"
IMAGE_NAME="quick-auth"
IMAGE_TAG="dev-$(date +%H%M%S)"

echo "🚀 Quick Deploy: Local Auth Service"
echo "=================================="

# Check if we're in the right directory
if [ ! -f "authentication_service/Dockerfile" ]; then
    echo "❌ Run this from BIDR_Backend directory"
    exit 1
fi

# Quick build
echo "🔨 Building..."
cd authentication_service
docker build -q -t ${IMAGE_NAME}:${IMAGE_TAG} . 
cd ..

# If using kind, load the image
if command -v kind &> /dev/null && kind get clusters &> /dev/null; then
    echo "📦 Loading to kind..."
    kind load docker-image ${IMAGE_NAME}:${IMAGE_TAG} > /dev/null
fi

# Update deployment
echo "🚢 Deploying..."
kubectl patch deployment ${SERVICE_NAME} -n ${NAMESPACE} -p="{\"spec\":{\"template\":{\"spec\":{\"containers\":[{\"name\":\"${SERVICE_NAME}\",\"image\":\"${IMAGE_NAME}:${IMAGE_TAG}\",\"imagePullPolicy\":\"Never\"}]}}}}"

# Wait for rollout
echo "⏳ Rolling out..."
kubectl rollout status deployment/${SERVICE_NAME} -n ${NAMESPACE} --timeout=120s

# Quick test
echo "🧪 Testing..."
kubectl wait --for=condition=ready pod -l app=${SERVICE_NAME} -n ${NAMESPACE} --timeout=60s > /dev/null

LB_IP=$(kubectl get service nginx-proxy -n ${NAMESPACE} -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
if [ -n "$LB_IP" ]; then
    curl -s -m 5 http://${LB_IP}/auth/ > /dev/null && echo "✅ Service is live at: http://${LB_IP}/auth/" || echo "⚠️  Service deployed but not responding yet"
    echo "🔗 Admin panel: http://${LB_IP}/auth/admin/"
else
    echo "✅ Service deployed successfully"
fi

echo "🎉 Quick deploy complete! Image: ${IMAGE_NAME}:${IMAGE_TAG}"