#!/bin/bash

# BIDR Authentication Service - Management Utility
# Quick access to common management tasks

set -e

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/auth-service-config.env"

if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
else
    echo "❌ Configuration file not found: $CONFIG_FILE"
    exit 1
fi

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

# Functions
show_usage() {
    echo -e "${CYAN}BIDR Authentication Service - Management Utility${NC}"
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo -e "${YELLOW}Available Commands:${NC}"
    echo "  deploy          - Deploy/redeploy the authentication service"
    echo "  logs            - View container logs"
    echo "  logs-follow     - Follow container logs in real-time"
    echo "  status          - Show container status"
    echo "  health          - Check backend health"
    echo "  restart         - Restart the container"
    echo "  test-login      - Test login endpoint"
    echo "  test-register   - Test registration endpoint"
    echo "  container-ip    - Get container IP address"
    echo "  delete          - Delete the container (be careful!)"
    echo ""
    echo -e "${BLUE}Examples:${NC}"
    echo "  $0 deploy       - Deploy the service"
    echo "  $0 logs         - View recent logs"
    echo "  $0 status       - Check if service is running"
    echo "  $0 health       - Check Application Gateway health"
}

deploy_service() {
    echo -e "${CYAN}🚀 Deploying Authentication Service...${NC}"
    "$SCRIPT_DIR/deploy-with-config.sh"
}

view_logs() {
    echo -e "${BLUE}📋 Viewing container logs...${NC}"
    az container logs --resource-group $RESOURCE_GROUP --name $CONTAINER_NAME
}

follow_logs() {
    echo -e "${BLUE}📋 Following container logs (Ctrl+C to stop)...${NC}"
    az container logs --resource-group $RESOURCE_GROUP --name $CONTAINER_NAME --follow
}

show_status() {
    echo -e "${BLUE}📊 Container Status:${NC}"
    az container show --resource-group $RESOURCE_GROUP --name $CONTAINER_NAME --query "{name:name,state:instanceView.state,ip:ipAddress.ip,fqdn:ipAddress.fqdn}" --output table
}

check_health() {
    echo -e "${BLUE}🏥 Checking Application Gateway backend health...${NC}"
    BACKEND_HEALTH=$(az network application-gateway show-backend-health \
        --name $APP_GATEWAY_NAME \
        --resource-group $RESOURCE_GROUP \
        --output json | \
        jq -r ".backendAddressPools[] | select(.backendAddressPool.id | contains(\"$BACKEND_POOL_NAME\")) | .backendHttpSettingsCollection[0].servers[0].health" 2>/dev/null || echo "Unknown")
    
    if [ "$BACKEND_HEALTH" = "Healthy" ]; then
        echo -e "${GREEN}✅ Backend Health: $BACKEND_HEALTH${NC}"
    else
        echo -e "${YELLOW}⚠️  Backend Health: $BACKEND_HEALTH${NC}"
    fi
    
    # Also check direct container access
    CONTAINER_IP=$(az container show --resource-group $RESOURCE_GROUP --name $CONTAINER_NAME --query "ipAddress.ip" --output tsv 2>/dev/null || echo "")
    if [ ! -z "$CONTAINER_IP" ]; then
        echo -e "${BLUE}🔍 Testing direct container access...${NC}"
        if curl -f -s "http://$CONTAINER_IP:$SERVICE_PORT/health/" > /dev/null 2>&1; then
            echo -e "${GREEN}✅ Container Health: Responsive${NC}"
        else
            echo -e "${YELLOW}⚠️  Container Health: Not responding${NC}"
        fi
    fi
}

restart_container() {
    echo -e "${YELLOW}🔄 Restarting container...${NC}"
    az container restart --resource-group $RESOURCE_GROUP --name $CONTAINER_NAME
    echo -e "${GREEN}✅ Container restart initiated${NC}"
    echo "Waiting 30 seconds for container to start..."
    sleep 30
    show_status
}

test_login() {
    echo -e "${BLUE}🧪 Testing login endpoint...${NC}"
    echo "Attempting login with test credentials..."
    
    RESPONSE=$(curl -X POST "https://$PRODUCTION_DOMAIN${SERVICE_PATH}login/" \
        -H "Content-Type: application/json" \
        -d '{"email":"test@example.com","password":"Test1234!"}' \
        -k -s)
    
    echo -e "${CYAN}Response:${NC}"
    echo "$RESPONSE" | jq . 2>/dev/null || echo "$RESPONSE"
}

test_register() {
    echo -e "${BLUE}🧪 Testing registration endpoint...${NC}"
    
    # Generate unique email for testing
    TIMESTAMP=$(date +%s)
    TEST_EMAIL="test-$TIMESTAMP@example.com"
    
    echo "Attempting registration with email: $TEST_EMAIL"
    
    # Generate random phone number (compatible with macOS)
    RANDOM_NUM=$(od -An -N4 -tx4 < /dev/urandom | tr -d ' ' | cut -c1-9)
    PHONE_NUM="+27${RANDOM_NUM:0:9}"
    
    RESPONSE=$(curl -X POST "https://$PRODUCTION_DOMAIN${SERVICE_PATH}register/" \
        -H "Content-Type: application/json" \
        -d "{
            \"email\":\"$TEST_EMAIL\",
            \"password\":\"Test1234!\",
            \"confirm_password\":\"Test1234!\",
            \"first_name\":\"Test\",
            \"last_name\":\"User\",
            \"phone_number\":\"$PHONE_NUM\",
            \"role\":\"buyer\"
        }" \
        -k -s)
    
    echo -e "${CYAN}Response:${NC}"
    echo "$RESPONSE" | jq . 2>/dev/null || echo "$RESPONSE"
}

get_container_ip() {
    echo -e "${BLUE}🌐 Container Information:${NC}"
    CONTAINER_IP=$(az container show --resource-group $RESOURCE_GROUP --name $CONTAINER_NAME --query "ipAddress.ip" --output tsv 2>/dev/null || echo "")
    CONTAINER_FQDN=$(az container show --resource-group $RESOURCE_GROUP --name $CONTAINER_NAME --query "ipAddress.fqdn" --output tsv 2>/dev/null || echo "")
    
    if [ ! -z "$CONTAINER_IP" ]; then
        echo -e "${GREEN}IP Address: $CONTAINER_IP${NC}"
        echo -e "${GREEN}FQDN: $CONTAINER_FQDN${NC}"
        echo -e "${GREEN}Direct URL: http://$CONTAINER_IP:$SERVICE_PORT/${NC}"
        echo -e "${GREEN}Production URL: https://$PRODUCTION_DOMAIN$SERVICE_PATH${NC}"
    else
        echo -e "${RED}❌ Could not retrieve container information${NC}"
    fi
}

delete_container() {
    echo -e "${RED}⚠️  WARNING: This will delete the authentication service container!${NC}"
    echo -e "${RED}This action cannot be undone.${NC}"
    echo ""
    read -p "Are you sure you want to delete the container? (type 'YES' to confirm): " confirm
    
    if [ "$confirm" = "YES" ]; then
        echo -e "${YELLOW}🗑️  Deleting container...${NC}"
        az container delete --resource-group $RESOURCE_GROUP --name $CONTAINER_NAME --yes
        echo -e "${RED}✅ Container deleted${NC}"
    else
        echo -e "${BLUE}Operation cancelled${NC}"
    fi
}

# Main script logic
case "$1" in
    "deploy")
        deploy_service
        ;;
    "logs")
        view_logs
        ;;
    "logs-follow")
        follow_logs
        ;;
    "status")
        show_status
        ;;
    "health")
        check_health
        ;;
    "restart")
        restart_container
        ;;
    "test-login")
        test_login
        ;;
    "test-register")
        test_register
        ;;
    "container-ip")
        get_container_ip
        ;;
    "delete")
        delete_container
        ;;
    *)
        show_usage
        ;;
esac
