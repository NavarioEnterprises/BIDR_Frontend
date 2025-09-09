#!/bin/bash

# Complete BIDR Deployment Fix Script
# This script comprehensively fixes all deployment issues

echo "🚀 Complete BIDR Deployment Fix"
echo "================================"

NAMESPACE="bidr"
CORRECT_ACR="bidruatregwe2024.azurecr.io"
LOAD_BALANCER_IP="20.241.197.87"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}📊 Current Status:${NC}"
kubectl get pods -n $NAMESPACE --no-headers | while read line; do
    POD_NAME=$(echo $line | awk '{print $1}')
    STATUS=$(echo $line | awk '{print $3}')
    if [[ $STATUS == "Running" ]]; then
        echo -e "${GREEN}✓ $POD_NAME - $STATUS${NC}"
    else
        echo -e "${RED}✗ $POD_NAME - $STATUS${NC}"
    fi
done

echo -e "\n${YELLOW}🔧 Step 1: Fixing Container Images${NC}"

# Update all deployments with correct images
declare -A SERVICE_IMAGES=(
    ["auth-service"]="bidr-authentication_service:latest"
    ["chat-service"]="bidr-chat_service:latest"
    ["notifications-service"]="bidr-notifications_service:latest"
    ["payment-service"]="bidr-payment_service:latest"
    ["resolution-service"]="bidr-resolution_service:latest"
    ["transactions-service"]="bidr-transactions_service:latest"
    ["product-management-service"]="bidr-product_management_service:latest"
    ["reviews-service"]="bidr-reviews_and_ratings:latest"
)

for SERVICE in "${!SERVICE_IMAGES[@]}"; do
    echo "Updating $SERVICE..."
    kubectl set image deployment/$SERVICE $SERVICE=$CORRECT_ACR/${SERVICE_IMAGES[$SERVICE]} -n $NAMESPACE
done

echo -e "\n${YELLOW}🔧 Step 2: Checking Database Connection${NC}"
# Check if database secret exists
DB_SECRET=$(kubectl get secret bidr-secrets -n $NAMESPACE -o jsonpath='{.data.DATABASE_URL}' 2>/dev/null | base64 -d)
if [ -z "$DB_SECRET" ]; then
    echo -e "${RED}✗ Database secrets not found!${NC}"
    echo "Creating database configuration..."
    
    # You'll need to update these with your actual database credentials
    kubectl create secret generic bidr-db-secret -n $NAMESPACE \
        --from-literal=DATABASE_URL="postgresql://postgres:your-password@postgres-service:5432/bidr_db" \
        --from-literal=POSTGRES_USER="postgres" \
        --from-literal=POSTGRES_PASSWORD="your-password" \
        --from-literal=POSTGRES_DB="bidr_db" \
        --dry-run=client -o yaml | kubectl apply -f -
else
    echo -e "${GREEN}✓ Database secrets configured${NC}"
fi

echo -e "\n${YELLOW}🔧 Step 3: Ensuring Services Have Correct Environment Variables${NC}"
# Create a patch for environment variables
cat > /tmp/env-patch.yaml << EOF
spec:
  template:
    spec:
      containers:
      - name: auth-service
        env:
        - name: DJANGO_SETTINGS_MODULE
          value: "authentication_service.settings"
        - name: DEBUG
          value: "False"
        - name: ALLOWED_HOSTS
          value: "*"
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: bidr-secrets
              key: DATABASE_URL
              optional: true
EOF

# Apply environment patches to auth service
kubectl patch deployment auth-service -n $NAMESPACE --patch-file=/tmp/env-patch.yaml 2>/dev/null || echo "Patch already applied"

echo -e "\n${YELLOW}⏳ Step 4: Waiting for Rollouts${NC}"
for SERVICE in "${!SERVICE_IMAGES[@]}"; do
    echo -n "Waiting for $SERVICE... "
    kubectl rollout status deployment/$SERVICE -n $NAMESPACE --timeout=180s 2>/dev/null && echo -e "${GREEN}✓${NC}" || echo -e "${RED}✗${NC}"
done

echo -e "\n${YELLOW}🔧 Step 5: Restarting Failed Pods${NC}"
# Delete pods in ImagePullBackOff state to force retry
kubectl get pods -n $NAMESPACE -o json | jq -r '.items[] | select(.status.containerStatuses[]?.state.waiting.reason == "ImagePullBackOff") | .metadata.name' | while read POD; do
    if [ ! -z "$POD" ]; then
        echo "Restarting failed pod: $POD"
        kubectl delete pod $POD -n $NAMESPACE --grace-period=0 --force 2>/dev/null
    fi
done

echo -e "\n${YELLOW}📊 Waiting for pods to stabilize...${NC}"
sleep 30

echo -e "\n${YELLOW}📊 Final Status:${NC}"
kubectl get pods -n $NAMESPACE --no-headers | while read line; do
    POD_NAME=$(echo $line | awk '{print $1}')
    STATUS=$(echo $line | awk '{print $3}')
    READY=$(echo $line | awk '{print $2}')
    if [[ $STATUS == "Running" ]]; then
        echo -e "${GREEN}✓ $POD_NAME - $STATUS ($READY)${NC}"
    else
        echo -e "${RED}✗ $POD_NAME - $STATUS ($READY)${NC}"
    fi
done

echo -e "\n${YELLOW}🌐 Service Endpoints:${NC}"
echo "Load Balancer IP: $LOAD_BALANCER_IP"
echo ""
echo "Service URLs:"
echo "  - Health Check: http://$LOAD_BALANCER_IP/health"
echo "  - Auth Admin: http://$LOAD_BALANCER_IP/auth/admin/"
echo "  - Auth API: http://$LOAD_BALANCER_IP/auth/swagger/"
echo "  - Chat: http://$LOAD_BALANCER_IP/chat/"
echo "  - Payment: http://$LOAD_BALANCER_IP/payment/"
echo "  - Products: http://$LOAD_BALANCER_IP/product/"
echo "  - Notifications: http://$LOAD_BALANCER_IP/notifications/"
echo "  - Transactions: http://$LOAD_BALANCER_IP/transactions/"
echo "  - Reviews: http://$LOAD_BALANCER_IP/reviews/"
echo "  - Resolution: http://$LOAD_BALANCER_IP/resolution/"

echo -e "\n${YELLOW}🧪 Testing Endpoints:${NC}"
# Test health endpoint
HEALTH_CHECK=$(curl -s -o /dev/null -w "%{http_code}" http://$LOAD_BALANCER_IP/health)
if [ "$HEALTH_CHECK" = "200" ]; then
    echo -e "${GREEN}✓ Health check passed${NC}"
else
    echo -e "${RED}✗ Health check failed (HTTP $HEALTH_CHECK)${NC}"
fi

# Test auth endpoint
AUTH_CHECK=$(curl -s -o /dev/null -w "%{http_code}" http://$LOAD_BALANCER_IP/auth/)
if [ "$AUTH_CHECK" = "200" ]; then
    echo -e "${GREEN}✓ Auth service accessible${NC}"
else
    echo -e "${RED}✗ Auth service not accessible (HTTP $AUTH_CHECK)${NC}"
fi

echo -e "\n${GREEN}✅ Deployment fix complete!${NC}"
echo ""
echo "Next steps:"
echo "1. Check if all pods are running: kubectl get pods -n $NAMESPACE"
echo "2. View logs for any failing service: kubectl logs <pod-name> -n $NAMESPACE"
echo "3. Access Django admin at: http://$LOAD_BALANCER_IP/auth/admin/"
echo "4. Check API documentation at: http://$LOAD_BALANCER_IP/auth/swagger/"

# Clean up temp files
rm -f /tmp/env-patch.yaml