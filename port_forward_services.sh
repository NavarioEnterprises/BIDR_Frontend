#!/usr/bin/env bash

echo "🚀 Setting up port forwarding for BIDR services..."
echo "This will make services accessible on localhost"

# Kill any existing port forwards
pkill -f "kubectl.*port-forward" 2>/dev/null || true
sleep 2

echo "Setting up port forwards..."

# Port forward for each service (in background)
kubectl port-forward service/auth-service 8001:8001 -n bidr &
kubectl port-forward service/chat-service 8002:8000 -n bidr &
kubectl port-forward service/payment-service 8003:8000 -n bidr &
kubectl port-forward service/notifications-service 8006:8000 -n bidr &

# Wait for port forwards to establish
sleep 5

echo ""
echo "✅ Port forwarding active! Services now accessible at:"
echo ""
echo "🔐 Authentication Service: http://localhost:8001/admin/"
echo "💬 Chat Service: http://localhost:8002/admin/"  
echo "💳 Payment Service: http://localhost:8003/admin/"
echo "🔔 Notifications Service: http://localhost:8006/admin/"
echo ""
echo "🔑 Login credentials for ALL services:"
echo "   Email: admin@bidr.local"
echo "   Password: BidrAdmin2024!"
echo ""
echo "⚠️  Keep this terminal open to maintain the connections!"
echo "⚠️  Press Ctrl+C to stop port forwarding"

# Keep script running
wait
