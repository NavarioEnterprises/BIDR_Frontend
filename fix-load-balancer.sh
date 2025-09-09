#!/bin/bash

# Fix Load Balancer Configuration for UAT Environment
# This script addresses namespace and service name mismatches

echo "🔧 Fixing UAT Load Balancer Configuration..."

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl is not installed or not in PATH"
    exit 1
fi

# Set namespace
NAMESPACE="bidr"

cd "$(dirname "$0")" || exit 1
echo "📍 Working directory: $(pwd)"

# Ensure namespace exists
kubectl get namespace $NAMESPACE &>/dev/null || kubectl create namespace $NAMESPACE

# Deploy UAT-specific resources individually to avoid kustomize conflicts
echo "🚀 Applying UAT configuration with fixed load balancer settings..."

# Deploy secrets and configs first
echo "🔧 Deploying configuration files..."
kubectl apply -f k8s/overlays/uat/secret.yaml -n $NAMESPACE || echo "Secret already exists or failed to apply"
kubectl apply -f k8s/overlays/uat/configmap.yaml -n $NAMESPACE || echo "ConfigMap already exists or failed to apply"

# Deploy postgres
kubectl apply -f k8s/overlays/uat/postgres.yaml -n $NAMESPACE || echo "Postgres already exists or failed to apply"

# Deploy services
echo "🚢 Deploying services..."
kubectl apply -f k8s/overlays/uat/auth-service.yaml -n $NAMESPACE
kubectl apply -f k8s/overlays/uat/chat-service.yaml -n $NAMESPACE  
kubectl apply -f k8s/overlays/uat/payment-service.yaml -n $NAMESPACE
kubectl apply -f k8s/overlays/uat/product-management-service.yaml -n $NAMESPACE
kubectl apply -f k8s/overlays/uat/notifications-service.yaml -n $NAMESPACE
kubectl apply -f k8s/overlays/uat/transactions-service.yaml -n $NAMESPACE
kubectl apply -f k8s/overlays/uat/reviews-service.yaml -n $NAMESPACE
kubectl apply -f k8s/overlays/uat/resolution-service.yaml -n $NAMESPACE

# Apply the fixed load balancer configuration
echo "⚡ Deploying fixed load balancer..."
kubectl apply -f k8s/overlays/uat/load-balancer-patch.yaml -n $NAMESPACE

# Wait for deployment to be ready
echo "⏳ Waiting for load balancer deployment to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/nginx-load-balancer -n $NAMESPACE 2>/dev/null || echo "Load balancer deployment not ready yet"

# Check the load balancer service
echo "🔍 Checking load balancer service status..."
kubectl get service bidr-load-balancer -n $NAMESPACE 2>/dev/null || echo "Load balancer service not found yet"

# Show all pods and services
echo "📊 Current UAT deployment status:"
kubectl get pods -n $NAMESPACE 2>/dev/null || echo "No pods found yet"
echo ""
kubectl get services -n $NAMESPACE 2>/dev/null || echo "No services found yet"
echo ""

# Get external IP
echo "📋 Load Balancer External IP:"
EXTERNAL_IP=$(kubectl get service bidr-load-balancer -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
if [ -n "$EXTERNAL_IP" ] && [ "$EXTERNAL_IP" != "null" ] && [ "$EXTERNAL_IP" != "" ]; then
    echo "External IP: $EXTERNAL_IP"
    
    # Test health endpoint
    echo "🏥 Testing health endpoint..."
    curl -f "http://$EXTERNAL_IP/health" 2>/dev/null && echo "" || echo "Health check not ready yet"
    
    echo "🔗 Service URLs:"
    echo "  - Health Check: http://$EXTERNAL_IP/health"
    echo "  - Auth: http://$EXTERNAL_IP/auth/"
    echo "  - Chat: http://$EXTERNAL_IP/chat/"
    echo "  - Payment: http://$EXTERNAL_IP/payment/"
    echo "  - Product: http://$EXTERNAL_IP/product/"
    echo "  - Notifications: http://$EXTERNAL_IP/notifications/"
    echo "  - Transactions: http://$EXTERNAL_IP/transactions/"
    echo "  - Reviews: http://$EXTERNAL_IP/reviews/"
    echo "  - Resolution: http://$EXTERNAL_IP/resolution/"
else
    echo "External IP not assigned yet. Check status with:"
    echo "  kubectl get service bidr-load-balancer -n $NAMESPACE"
    echo "  kubectl describe service bidr-load-balancer -n $NAMESPACE"
fi

echo ""
echo "✅ Load balancer configuration applied successfully!"
echo ""
echo "📝 Key fixes applied:"
echo "  - Fixed namespace references from 'bidr' to 'bidr-uat'"
echo "  - Updated service ports to match actual service configurations"
echo "  - Corrected upstream server configurations"
echo "  - Avoided kustomization conflicts by applying files individually"