#!/bin/bash

# Simple UAT Deployment Script
# Deploys individual components to avoid kustomization conflicts

echo "🚀 Deploying BIDR UAT Environment..."

# Set namespace
NAMESPACE="bidr-uat"

# Ensure namespace exists
kubectl get namespace $NAMESPACE &>/dev/null || kubectl create namespace $NAMESPACE

cd "$(dirname "$0")" || exit 1

echo "📍 Working directory: $(pwd)"

# Deploy UAT-specific resources individually
echo "🔧 Deploying UAT configuration files..."

# Deploy secrets and configs
kubectl apply -f k8s/overlays/uat/secret.yaml -n $NAMESPACE
kubectl apply -f k8s/overlays/uat/configmap.yaml -n $NAMESPACE

# Deploy postgres
kubectl apply -f k8s/overlays/uat/postgres.yaml -n $NAMESPACE

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

# Wait for load balancer to be ready
echo "⏳ Waiting for deployments to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/nginx-load-balancer -n $NAMESPACE 2>/dev/null || echo "Load balancer not ready yet"

# Show status
echo "📊 Deployment Status:"
kubectl get pods -n $NAMESPACE
echo ""
kubectl get services -n $NAMESPACE
echo ""

# Get external IP
echo "🌐 Load Balancer External IP:"
EXTERNAL_IP=$(kubectl get service bidr-load-balancer -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
if [ -n "$EXTERNAL_IP" ] && [ "$EXTERNAL_IP" != "null" ]; then
    echo "External IP: $EXTERNAL_IP"
    echo ""
    echo "🔗 Service URLs:"
    echo "  - Health Check: http://$EXTERNAL_IP/health"
    echo "  - Auth: http://$EXTERNAL_IP/auth/"
    echo "  - Chat: http://$EXTERNAL_IP/chat/"
    echo "  - Payment: http://$EXTERNAL_IP/payment/"
    echo "  - Products: http://$EXTERNAL_IP/product/"
    echo "  - Notifications: http://$EXTERNAL_IP/notifications/"
    echo "  - Transactions: http://$EXTERNAL_IP/transactions/"
    echo "  - Reviews: http://$EXTERNAL_IP/reviews/"
    echo "  - Resolution: http://$EXTERNAL_IP/resolution/"
    
    # Test health endpoint
    echo ""
    echo "🏥 Testing health endpoint..."
    curl -f "http://$EXTERNAL_IP/health" 2>/dev/null && echo "" || echo "Health check not ready yet"
else
    echo "External IP not assigned yet. Run this to check:"
    echo "  kubectl get service bidr-load-balancer -n $NAMESPACE"
fi

echo ""
echo "✅ UAT deployment completed!"