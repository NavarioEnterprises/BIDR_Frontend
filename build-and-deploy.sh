#!/bin/bash

set -e

# Configuration
RESOURCE_GROUP="bidr-k8s"
AKS_CLUSTER="BIDR-aks-cluster"
ACR_NAME="BIDRcontainerregistry"
IMAGE_NAME="bidr-app"
IMAGE_TAG="latest"

echo "🚀 Starting BIDR Backend Deployment"

# Login to Azure Container Registry
echo "📦 Logging into Azure Container Registry..."
az acr login --name $ACR_NAME

# Build Docker image
echo "🔨 Building Docker image..."
docker build -t $IMAGE_NAME:$IMAGE_TAG .

# Tag image for ACR
echo "🏷️  Tagging image for ACR..."
docker tag $IMAGE_NAME:$IMAGE_TAG $ACR_NAME.azurecr.io/$IMAGE_NAME:$IMAGE_TAG

# Push to ACR
echo "📤 Pushing image to ACR..."
docker push $ACR_NAME.azurecr.io/$IMAGE_NAME:$IMAGE_TAG

# Get AKS credentials
echo "🔐 Getting AKS credentials..."
az aks get-credentials --resource-group $RESOURCE_GROUP --name $AKS_CLUSTER --overwrite-existing

# Deploy to Kubernetes
echo "🚀 Deploying to Kubernetes..."
kubectl apply -k k8s/

# Wait for deployment to be ready
echo "⏳ Waiting for deployment to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/postgres -n bidr
echo "✅ PostgreSQL is ready!"

# Wait for and run initialization job
echo "🔄 Running initialization job (makemigrations, migrations, superuser creation)..."
kubectl wait --for=condition=complete --timeout=300s job/bidr-init -n bidr
echo "✅ Initialization completed!"

# Now wait for the main application
kubectl wait --for=condition=available --timeout=300s deployment/bidr-app -n bidr
echo "✅ Application is ready!"

# Get service information
echo "📋 Getting service information..."
kubectl get services -n bidr

# Get superuser credentials
echo ""
echo "🔑 Retrieving superuser credentials..."
LOGS=$(kubectl logs job/bidr-init -n bidr 2>/dev/null || echo "")
USERNAME=$(echo "$LOGS" | grep "Username:" | awk '{print $2}' | head -1)
PASSWORD=$(echo "$LOGS" | grep "Password:" | awk '{print $2}' | head -1)
EMAIL=$(echo "$LOGS" | grep "Email:" | awk '{print $2}' | head -1)

echo "✅ Deployment completed successfully!"
echo ""
echo "🌐 Your BIDR application is available at:"
EXTERNAL_IP=$(kubectl get service bidr-service-lb -n bidr -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
if [ -n "$EXTERNAL_IP" ]; then
    echo "   Application: http://$EXTERNAL_IP:8067/"
    echo "   Admin:       http://$EXTERNAL_IP:8067/admin/"
else
    echo "   LoadBalancer IP not yet assigned. Please wait a few minutes and check:"
    echo "   kubectl get service bidr-service-lb -n bidr"
fi

if [ -n "$USERNAME" ] && [ -n "$PASSWORD" ]; then
    echo ""
    echo "🎉 Superuser Credentials:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "👤 Username: $USERNAME"
    echo "📧 Email:    $EMAIL"
    echo "🔑 Password: $PASSWORD"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "💡 Save these credentials securely!"
fi

echo ""
echo "📊 To check deployment status:"
echo "kubectl get pods -n bidr"
echo "kubectl get services -n bidr"
echo ""
echo "📝 To view logs:"
echo "kubectl logs -f deployment/bidr-app -n bidr"
echo ""
echo "🔑 To retrieve credentials later:"
echo "./get-superuser-credentials.sh"
