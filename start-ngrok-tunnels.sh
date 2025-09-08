#!/bin/bash

# Bidr Microservices Ngrok Tunnel Script
# This script starts ngrok tunnels for all bidr microservices

echo "Starting ngrok tunnels for Bidr microservices..."

# Function to start ngrok tunnel in background
start_tunnel() {
    local port=$1
    local url=$2
    local service_name=$3
    
    echo "Starting $service_name on port $port -> $url"
    ngrok http --url="$url" --host-header="localhost:$port" $port &
    
    # Small delay to prevent overwhelming ngrok
    sleep 1
}

# Start all ngrok tunnels
start_tunnel 8001 "bidr-auth.ngrok.io" "Auth Service"
start_tunnel 8002 "bidr-chat.ngrok.io" "Chat Service"
start_tunnel 8003 "bidr-payment.ngrok.io" "Payment Service"
start_tunnel 8004 "bidr-resolution.ngrok.io" "Resolution Service"
start_tunnel 8005 "bidr-products.ngrok.io" "Products Service"
start_tunnel 8006 "bidr-notifications.ngrok.io" "Notifications Service"
start_tunnel 8007 "bidr-transactions.ngrok.io" "Transactions Service"
start_tunnel 8008 "bidr-reviews.ngrok.io" "Reviews Service"
start_tunnel 8009 "bidr-grafana.ngrok.io" "Grafana Service"
start_tunnel 8010 "bidr-prometheus.ngrok.io" "Prometheus Service"
start_tunnel 8011 "bidr.ngrok.io" "Main Bidr Service"
start_tunnel 8012 "piglet-funky-constantly.ngrok.app" "Piglet Service"

echo ""
echo "All ngrok tunnels started!"
echo ""
echo "Active ngrok tunnels started:"
echo "Auth Service:          http://localhost:8001/ -> https://bidr-auth.ngrok.io/"
echo "Chat Service:          http://localhost:8002/ -> https://bidr-chat.ngrok.io/"
echo "Products Service:      http://localhost:8005/ -> https://bidr-products.ngrok.io/"
echo "Main Bidr Service:     http://localhost:8011/ -> https://bidr.online/ (via bidr.ngrok.io)"
echo ""
echo "Services using bidr.online (no ngrok tunnels needed):"
echo "Payment Service:       https://bidr.online/payments/"
echo "Resolution Service:    https://bidr.online/resolution/"
echo "Notifications Service: https://bidr.online/notifications/"
echo "Transactions Service:  https://bidr.online/transactions/"
echo "Reviews Service:       https://bidr.online/reviews/"
echo "Grafana:              https://bidr.online/grafana/"
echo "Prometheus:           https://bidr.online/prometheus/"
echo ""
echo "Admin endpoints (all via bidr.online):"
echo "Auth Admin:           https://bidr.online/auth/admin/"
echo "Chat Admin:           https://bidr.online/chat/admin/"
echo "Payment Admin:        https://bidr.online/payments/admin/"
echo "Resolution Admin:     https://bidr.online/resolution/admin/"
echo "Products Admin:       https://bidr.online/products/admin/"
echo "Notifications Admin:  https://bidr.online/notifications/admin/"
echo "Transactions Admin:   https://bidr.online/transactions/admin/"
echo "Reviews Admin:        https://bidr.online/reviews/admin/"
echo ""
echo "To stop all tunnels, run: pkill -f ngrok"
echo "To view ngrok dashboard: http://localhost:4040"
echo ""
echo "Press Ctrl+C to stop this script (tunnels will continue running in background)"

# Keep script running
while true; do
    sleep 30
done