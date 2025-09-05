#!/bin/bash

# BIDR Services Status Check Script
# This script checks the status of all deployed services

echo "🔍 Checking BIDR Services Status..."

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
RESOURCE_GROUP="bidr-simple-rg"

# Service names
SERVICES=(
    "bidr-product-service:8000:📦 Product Management"
    "bidr-auth-service:8001:🔐 Authentication"
    "bidr-chat-service:8002:💬 Chat"
    "bidr-payment-service:8003:💳 Payment"
    "bidr-resolution-service:8004:⚖️ Resolution"
    "bidr-notifications-service:8005:🔔 Notifications"
    "bidr-transactions-service:8006:💰 Transactions"
    "bidr-reviews-service:8007:⭐ Reviews"
)

echo ""
echo "========================================="
echo "🌐 BIDR Platform Service Status"
echo "========================================="
echo ""

for SERVICE_CONFIG in "${SERVICES[@]}"; do
    IFS=':' read -r CONTAINER_NAME PORT DISPLAY_NAME <<< "$SERVICE_CONFIG"
    
    # Get container information
    CONTAINER_INFO=$(az container show \
        --resource-group $RESOURCE_GROUP \
        --name $CONTAINER_NAME \
        --query '{
            ip: ipAddress.ip,
            fqdn: ipAddress.fqdn,
            state: instanceView.state,
            provisioningState: provisioningState
        }' \
        --output json 2>/dev/null)
    
    if [ $? -eq 0 ] && [ "$CONTAINER_INFO" != "null" ]; then
        IP=$(echo $CONTAINER_INFO | jq -r '.ip // "N/A"')
        FQDN=$(echo $CONTAINER_INFO | jq -r '.fqdn // "N/A"')
        STATE=$(echo $CONTAINER_INFO | jq -r '.state // "Unknown"')
        PROVISIONING=$(echo $CONTAINER_INFO | jq -r '.provisioningState // "Unknown"')
        
        # Color code based on state
        if [ "$STATE" = "Running" ] && [ "$PROVISIONING" = "Succeeded" ]; then
            STATUS_COLOR=$GREEN
            STATUS_ICON="✅"
            SERVICE_URL="http://$FQDN:$PORT"
        else
            STATUS_COLOR=$YELLOW
            STATUS_ICON="⚠️"
            SERVICE_URL="http://$FQDN:$PORT (Not Ready)"
        fi
        
        echo -e "$DISPLAY_NAME Service:"
        echo -e "   Status: ${STATUS_COLOR}${STATUS_ICON} $STATE / $PROVISIONING${NC}"
        echo -e "   URL: $SERVICE_URL"
        echo -e "   Admin: http://$FQDN:$PORT/admin/"
        echo -e "   Health: http://$FQDN:$PORT/health/"
        echo -e "   IP: $IP"
        echo ""
    else
        echo -e "$DISPLAY_NAME Service:"
        echo -e "   Status: ${RED}❌ Not Deployed${NC}"
        echo ""
    fi
done

echo "========================================="

# Generate Environment Configuration
echo ""
echo "🎯 Environment Configuration (Dart/Flutter):"
echo ""
echo "EnvironmentType.uat: EnvironmentConfig("
echo "  // Service URLs"

for SERVICE_CONFIG in "${SERVICES[@]}"; do
    IFS=':' read -r CONTAINER_NAME PORT DISPLAY_NAME <<< "$SERVICE_CONFIG"
    
    CONTAINER_INFO=$(az container show \
        --resource-group $RESOURCE_GROUP \
        --name $CONTAINER_NAME \
        --query 'ipAddress.fqdn' \
        --output tsv 2>/dev/null)
    
    if [ $? -eq 0 ] && [ "$CONTAINER_INFO" != "null" ] && [ -n "$CONTAINER_INFO" ]; then
        case $CONTAINER_NAME in
            "bidr-auth-service") echo "  authServiceUrl: \"http://$CONTAINER_INFO:$PORT/\"," ;;
            "bidr-chat-service") echo "  chatServiceUrl: \"http://$CONTAINER_INFO:$PORT/\"," ;;
            "bidr-payment-service") echo "  paymentServiceUrl: \"http://$CONTAINER_INFO:$PORT/\"," ;;
            "bidr-resolution-service") echo "  resolutionServiceUrl: \"http://$CONTAINER_INFO:$PORT/\"," ;;
            "bidr-notifications-service") echo "  notificationsServiceUrl: \"http://$CONTAINER_INFO:$PORT/\"," ;;
            "bidr-transactions-service") echo "  transactionsServiceUrl: \"http://$CONTAINER_INFO:$PORT/\"," ;;
            "bidr-reviews-service") echo "  reviewsServiceUrl: \"http://$CONTAINER_INFO:$PORT/\"," ;;
            "bidr-product-service") echo "  productsServiceUrl: \"http://$CONTAINER_INFO:$PORT/\"," ;;
        esac
    fi
done

echo ""
echo "  // Admin URLs"

for SERVICE_CONFIG in "${SERVICES[@]}"; do
    IFS=':' read -r CONTAINER_NAME PORT DISPLAY_NAME <<< "$SERVICE_CONFIG"
    
    CONTAINER_INFO=$(az container show \
        --resource-group $RESOURCE_GROUP \
        --name $CONTAINER_NAME \
        --query 'ipAddress.fqdn' \
        --output tsv 2>/dev/null)
    
    if [ $? -eq 0 ] && [ "$CONTAINER_INFO" != "null" ] && [ -n "$CONTAINER_INFO" ]; then
        case $CONTAINER_NAME in
            "bidr-auth-service") echo "  authAdminUrl: \"http://$CONTAINER_INFO:$PORT/admin/\"," ;;
            "bidr-chat-service") echo "  chatAdminUrl: \"http://$CONTAINER_INFO:$PORT/admin/\"," ;;
            "bidr-payment-service") echo "  paymentAdminUrl: \"http://$CONTAINER_INFO:$PORT/admin/\"," ;;
            "bidr-resolution-service") echo "  resolutionAdminUrl: \"http://$CONTAINER_INFO:$PORT/admin/\"," ;;
            "bidr-notifications-service") echo "  notificationsAdminUrl: \"http://$CONTAINER_INFO:$PORT/admin/\"," ;;
            "bidr-transactions-service") echo "  transactionsAdminUrl: \"http://$CONTAINER_INFO:$PORT/admin/\"," ;;
            "bidr-reviews-service") echo "  reviewsAdminUrl: \"http://$CONTAINER_INFO:$PORT/admin/\"," ;;
            "bidr-product-service") echo "  productsAdminUrl: \"http://$CONTAINER_INFO:$PORT/admin/\"," ;;
        esac
    fi
done

echo "),"

echo ""
echo "🎯 Quick Health Check Commands:"
echo ""

for SERVICE_CONFIG in "${SERVICES[@]}"; do
    IFS=':' read -r CONTAINER_NAME PORT DISPLAY_NAME <<< "$SERVICE_CONFIG"
    
    CONTAINER_INFO=$(az container show \
        --resource-group $RESOURCE_GROUP \
        --name $CONTAINER_NAME \
        --query 'ipAddress.fqdn' \
        --output tsv 2>/dev/null)
    
    if [ $? -eq 0 ] && [ "$CONTAINER_INFO" != "null" ] && [ -n "$CONTAINER_INFO" ]; then
        echo "curl http://$CONTAINER_INFO:$PORT/health/"
    fi
done

echo ""
echo "========================================="
