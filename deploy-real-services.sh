#!/bin/bash

# Deploy Real BIDR Services Script
# This script builds and deploys the actual Django applications

set -e

echo "🚀 Deploying Real BIDR Services"
echo "==============================="

# Configuration
ACR_NAME="bidrnparusuatregistry2024"
NAMESPACE="bidr"
SERVICES=(
    "authentication_service"
    "chat_service"
    "notifications_service"
    "payment_service"
    "product_management_service"
    "resolution_service"
    "reviews_and_ratings"
    "transactions_service"
)

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}📦 Step 1: Login to Azure Container Registry${NC}"
az acr login --name $ACR_NAME

echo -e "\n${YELLOW}🔨 Step 2: Build and Push Docker Images${NC}"

# Build authentication service with the production Dockerfile
echo -e "\n${GREEN}Building authentication_service...${NC}"
cd authentication_service

# Check if production Dockerfile exists, otherwise use the regular one
if [ -f "Dockerfile.production" ]; then
    echo "Using Dockerfile.production"
    docker build -t bidr-authentication_service:latest -f Dockerfile.production .
else
    echo "Using standard Dockerfile"
    docker build -t bidr-authentication_service:latest .
fi

# Tag and push
docker tag bidr-authentication_service:latest ${ACR_NAME}.azurecr.io/bidr-authentication_service:latest
docker push ${ACR_NAME}.azurecr.io/bidr-authentication_service:latest
echo -e "${GREEN}✓ Authentication service built and pushed${NC}"

cd ..

# Build other services
for service in "${SERVICES[@]:1}"; do
    if [ -d "$service" ] && [ -f "$service/Dockerfile" ]; then
        echo -e "\n${GREEN}Building $service...${NC}"
        docker build -t bidr-${service}:latest ${service}/
        docker tag bidr-${service}:latest ${ACR_NAME}.azurecr.io/bidr-${service}:latest
        docker push ${ACR_NAME}.azurecr.io/bidr-${service}:latest
        echo -e "${GREEN}✓ $service built and pushed${NC}"
    else
        echo -e "${YELLOW}⚠️  Skipping $service (no Dockerfile found)${NC}"
    fi
done

echo -e "\n${YELLOW}🚀 Step 3: Deploy to Kubernetes${NC}"

# First, ensure we have the proper secrets
echo "Checking database secrets..."
kubectl get secret bidr-secrets -n $NAMESPACE > /dev/null 2>&1 || {
    echo -e "${RED}✗ Database secrets not found!${NC}"
    echo "Creating default secrets (update with your actual values)..."
    kubectl create secret generic bidr-secrets -n $NAMESPACE \
        --from-literal=DATABASE_URL="postgresql://postgres:postgres123@postgres-service:5432/bidr_db" \
        --from-literal=POSTGRES_USER="postgres" \
        --from-literal=POSTGRES_PASSWORD="postgres123" \
        --from-literal=POSTGRES_DB="bidr_db" \
        --from-literal=SECRET_KEY="your-very-secret-key-change-this-in-production" \
        --dry-run=client -o yaml | kubectl apply -f -
}

# Apply the proper auth service configuration
echo -e "\n${GREEN}Deploying auth service with Django application...${NC}"
kubectl apply -f k8s/overlays/uat/auth-service-proper.yaml

# Update other service deployments to use proper images
echo -e "\n${GREEN}Updating other service deployments...${NC}"
for service in "${SERVICES[@]:1}"; do
    deployment_name="${service//_/-}"
    echo "Updating $deployment_name..."
    kubectl set image deployment/$deployment_name $deployment_name=${ACR_NAME}.azurecr.io/bidr-${service}:latest -n $NAMESPACE 2>/dev/null || echo "Deployment $deployment_name not found"
done

echo -e "\n${YELLOW}⏳ Step 4: Wait for Rollouts${NC}"
kubectl rollout status deployment/auth-service -n $NAMESPACE --timeout=300s

echo -e "\n${YELLOW}🔄 Step 5: Run Database Migrations${NC}"
# Wait for auth service to be ready
sleep 10

# Run migrations
echo "Running database migrations..."
kubectl exec deployment/auth-service -n $NAMESPACE -- python manage.py migrate --noinput || echo "Migration failed (database might not be ready)"

# Create superuser if needed
echo -e "\n${YELLOW}👤 Creating superuser (if needed)...${NC}"
kubectl exec deployment/auth-service -n $NAMESPACE -- python -c "
from django.contrib.auth import get_user_model
User = get_user_model()
if not User.objects.filter(username='admin').exists():
    User.objects.create_superuser('admin', 'admin@bidr.com', 'admin123')
    print('Superuser created: admin / admin123')
else:
    print('Superuser already exists')
" || echo "Could not create superuser automatically"

echo -e "\n${YELLOW}📊 Step 6: Check Deployment Status${NC}"
kubectl get pods -n $NAMESPACE | grep -E "(auth|chat|payment|product|notification|transaction|review|resolution)"

echo -e "\n${YELLOW}🧪 Step 7: Test Endpoints${NC}"
LOAD_BALANCER_IP="20.241.197.87"

# Test health endpoint
echo -n "Testing health endpoint... "
HEALTH_CHECK=$(curl -s -o /dev/null -w "%{http_code}" http://$LOAD_BALANCER_IP/auth/health/ --max-time 5)
if [ "$HEALTH_CHECK" = "200" ]; then
    echo -e "${GREEN}✓ Working${NC}"
else
    echo -e "${RED}✗ Failed (HTTP $HEALTH_CHECK)${NC}"
fi

# Test admin endpoint
echo -n "Testing admin endpoint... "
ADMIN_CHECK=$(curl -s -o /dev/null -w "%{http_code}" http://$LOAD_BALANCER_IP/auth/admin/ --max-time 5)
if [ "$ADMIN_CHECK" = "200" ] || [ "$ADMIN_CHECK" = "302" ]; then
    echo -e "${GREEN}✓ Working${NC}"
else
    echo -e "${RED}✗ Failed (HTTP $ADMIN_CHECK)${NC}"
fi

echo -e "\n${GREEN}✅ Deployment Complete!${NC}"
echo ""
echo "🌐 Access your services at:"
echo "  - Django Admin: http://$LOAD_BALANCER_IP/auth/admin/"
echo "  - API Documentation: http://$LOAD_BALANCER_IP/auth/swagger/"
echo "  - Health Check: http://$LOAD_BALANCER_IP/auth/health/"
echo ""
echo "🔑 Default Credentials:"
echo "  Username: admin"
echo "  Password: admin123"
echo ""
echo "⚠️  IMPORTANT: Change these credentials in production!"
echo ""
echo "📋 Useful Commands:"
echo "  View logs: kubectl logs -f deployment/auth-service -n $NAMESPACE"
echo "  Shell access: kubectl exec -it deployment/auth-service -n $NAMESPACE -- bash"
echo "  Check pods: kubectl get pods -n $NAMESPACE"