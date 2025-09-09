#!/usr/bin/env bash

echo "🚀 Creating individual LoadBalancer services for each BIDR microservice..."

# Update Authentication Service to LoadBalancer
kubectl patch service auth-service -n bidr -p='{"spec":{"type":"LoadBalancer","ports":[{"port":8001,"targetPort":8000,"protocol":"TCP","name":"http"}]}}'

# Update Chat Service to LoadBalancer  
kubectl patch service chat-service -n bidr -p='{"spec":{"type":"LoadBalancer","ports":[{"port":8002,"targetPort":8000,"protocol":"TCP","name":"http"}]}}'

# Update Payment Service to LoadBalancer
kubectl patch service payment-service -n bidr -p='{"spec":{"type":"LoadBalancer","ports":[{"port":8003,"targetPort":8000,"protocol":"TCP","name":"http"}]}}'

# Update Product Service to LoadBalancer
kubectl patch service product-service -n bidr -p='{"spec":{"type":"LoadBalancer","ports":[{"port":8004,"targetPort":8000,"protocol":"TCP","name":"http"}]}}'

# Update Resolution Service to LoadBalancer
kubectl patch service resolution-service -n bidr -p='{"spec":{"type":"LoadBalancer","ports":[{"port":8005,"targetPort":8000,"protocol":"TCP","name":"http"}]}}'

# Update Notifications Service to LoadBalancer
kubectl patch service notifications-service -n bidr -p='{"spec":{"type":"LoadBalancer","ports":[{"port":8006,"targetPort":8000,"protocol":"TCP","name":"http"}]}}'

# Update Transactions Service to LoadBalancer
kubectl patch service transactions-service -n bidr -p='{"spec":{"type":"LoadBalancer","ports":[{"port":8007,"targetPort":8000,"protocol":"TCP","name":"http"}]}}'

# Update Reviews Service to LoadBalancer
kubectl patch service reviews-service -n bidr -p='{"spec":{"type":"LoadBalancer","ports":[{"port":8008,"targetPort":8000,"protocol":"TCP","name":"http"}]}}'

echo "⏳ Waiting for LoadBalancer IPs to be assigned..."
sleep 30

echo "📊 Checking LoadBalancer status..."
kubectl get services -n bidr -o wide

echo ""
echo "🎉 Individual LoadBalancers created!"
echo "Note: It may take a few minutes for Azure to assign external IPs to all services."
