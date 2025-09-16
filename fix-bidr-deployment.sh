#!/bin/bash

# Fix BIDR Deployment Issues Script
# This script fixes image registry issues and deployment configurations

echo "🔧 Fixing BIDR Deployment Issues..."

# Correct ACR registry
CORRECT_ACR="bidruatregwe2024.azurecr.io"
NAMESPACE="bidr"

echo "📋 Current deployment status:"
kubectl get pods -n $NAMESPACE

echo -e "\n🔄 Updating deployments with correct images..."

# Fix auth-service
kubectl set image deployment/auth-service auth-service=$CORRECT_ACR/bidr-authentication_service:latest -n $NAMESPACE

# Fix chat-service  
kubectl set image deployment/chat-service chat-service=$CORRECT_ACR/bidr-chat_service:latest -n $NAMESPACE

# Fix notifications-service
kubectl set image deployment/notifications-service notifications-service=$CORRECT_ACR/bidr-notifications_service:latest -n $NAMESPACE

# Fix payment-service
kubectl set image deployment/payment-service payment-service=$CORRECT_ACR/bidr-payment_service:latest -n $NAMESPACE

# Fix resolution-service
kubectl set image deployment/resolution-service resolution-service=$CORRECT_ACR/bidr-resolution_service:latest -n $NAMESPACE

# Fix transactions-service
kubectl set image deployment/transactions-service transactions-service=$CORRECT_ACR/bidr-transactions_service:latest -n $NAMESPACE

# Wait for rollout
echo -e "\n⏳ Waiting for rollouts to complete..."
kubectl rollout status deployment/auth-service -n $NAMESPACE --timeout=300s
kubectl rollout status deployment/chat-service -n $NAMESPACE --timeout=300s
kubectl rollout status deployment/notifications-service -n $NAMESPACE --timeout=300s
kubectl rollout status deployment/payment-service -n $NAMESPACE --timeout=300s
kubectl rollout status deployment/resolution-service -n $NAMESPACE --timeout=300s
kubectl rollout status deployment/transactions-service -n $NAMESPACE --timeout=300s

echo -e "\n📊 Updated deployment status:"
kubectl get pods -n $NAMESPACE

echo -e "\n🔍 Checking service endpoints..."
kubectl get svc -n $NAMESPACE

echo -e "\n✅ Deployment fixes applied!"
echo "🌐 Access your services at http://20.241.197.87/"