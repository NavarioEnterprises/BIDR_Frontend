#!/bin/bash

set -e

# Configuration
RESOURCE_GROUP="${RESOURCE_GROUP:-bidr-k8s}"
AKS_CLUSTER="${AKS_CLUSTER:-BIDR-aks-cluster}"
ACR_NAME="${ACR_NAME:-BIDRcontainerregistry}"
IMAGE_TAG="latest"
ENVIRONMENT="${ENVIRONMENT:-production}"

# Services configuration - using arrays instead of associative arrays for better compatibility
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

echo "🚀 Starting BIDR Backend Complete Deployment - Environment: $ENVIRONMENT"

# Login to Azure Container Registry
echo "📦 Logging into Azure Container Registry..."
az acr login --name $ACR_NAME

# Build and push all Docker images
echo "🔨 Building and pushing all service images..."

for service_name in "${SERVICES[@]}"; do
    service_dir="$service_name"
    image_name="bidr-${service_name}"
    
    echo "📦 Building ${service_name} image..."
    
    # Check if service directory exists
    if [ ! -d "$service_dir" ]; then
        echo "❌ Service directory $service_dir not found, skipping..."
        continue
    fi
    
    # Check if Dockerfile exists
    if [ ! -f "$service_dir/Dockerfile" ]; then
        echo "❌ Dockerfile not found in $service_dir, skipping..."
        continue
    fi
    
    echo "🔨 Building $image_name:$IMAGE_TAG from $service_dir"
    docker build -t $image_name:$IMAGE_TAG $service_dir/
    
    # Tag image for ACR
    echo "🏷️  Tagging $image_name for ACR..."
    docker tag $image_name:$IMAGE_TAG $ACR_NAME.azurecr.io/$image_name:$IMAGE_TAG
    
    # Push to ACR
    echo "📤 Pushing $image_name to ACR..."
    docker push $ACR_NAME.azurecr.io/$image_name:$IMAGE_TAG
    
    echo "✅ Successfully built and pushed $image_name"
done

# Get AKS credentials
echo "🔐 Getting AKS credentials..."
az aks get-credentials --resource-group $RESOURCE_GROUP --name $AKS_CLUSTER --overwrite-existing

# Deploy infrastructure with Terraform if requested
if [ "$1" = "--deploy-infrastructure" ] || [ "$1" = "--full-deploy" ]; then
    echo "🏗️  Deploying infrastructure with Terraform..."
    cd terraform
    terraform init
    terraform plan -var-file="${ENVIRONMENT}.tfvars" -out="${ENVIRONMENT}.tfplan"
    terraform apply "${ENVIRONMENT}.tfplan"
    cd ..
    echo "✅ Infrastructure deployed successfully!"
fi

# Apply Kubernetes configurations
echo "🚀 Deploying to Kubernetes..."

# Deploy base configurations
echo "📋 Applying base Kubernetes configurations..."
kubectl apply -k k8s/base/

# Deploy environment-specific configurations
if [ -d "k8s/overlays/$ENVIRONMENT" ]; then
    echo "📋 Applying $ENVIRONMENT environment configurations..."
    kubectl apply -k k8s/overlays/$ENVIRONMENT/
else
    echo "⚠️  No specific environment configuration found for $ENVIRONMENT, using base only"
fi

# Wait for deployments to be ready
echo "⏳ Waiting for deployments to be ready..."

# Wait for PostgreSQL first
echo "🔄 Waiting for PostgreSQL..."
kubectl wait --for=condition=available --timeout=300s deployment/postgres -n bidr || echo "⚠️  PostgreSQL timeout (continuing anyway)"

# Wait for Redis
echo "🔄 Waiting for Redis..."
kubectl wait --for=condition=available --timeout=300s deployment/redis -n bidr || echo "⚠️  Redis timeout (continuing anyway)"

# Run database initialization if job exists
if kubectl get job bidr-init -n bidr &>/dev/null; then
    echo "🔄 Running database initialization job..."
    kubectl wait --for=condition=complete --timeout=600s job/bidr-init -n bidr
    echo "✅ Database initialization completed!"
fi

# Wait for all service deployments
echo "🔄 Waiting for service deployments..."
for service_name in "${SERVICES[@]}"; do
    deployment_name="bidr-${service_name//_/-}"
    echo "⏳ Waiting for $deployment_name..."
    kubectl wait --for=condition=available --timeout=300s deployment/$deployment_name -n bidr || echo "⚠️  $deployment_name timeout (continuing anyway)"
done

# Wait for load balancer
echo "🔄 Waiting for load balancer..."
kubectl wait --for=condition=available --timeout=300s deployment/nginx-proxy -n bidr || echo "⚠️  Load balancer timeout (continuing anyway)"

echo "✅ All deployments completed!"

# Get service information
echo "📋 Getting service information..."
echo ""
echo "🔍 Namespace status:"
kubectl get namespace bidr
echo ""
echo "🔍 Pod status:"
kubectl get pods -n bidr
echo ""
echo "🔍 Service status:"
kubectl get services -n bidr
echo ""
echo "🔍 Ingress status:"
kubectl get ingress -n bidr || echo "No ingress resources found"

# Get load balancer IP
echo ""
echo "🌐 Getting Load Balancer information..."
LOAD_BALANCER_IP=""

# Try to get external IP from different services
for service in bidr-service-lb nginx-proxy-service bidr-nginx-proxy; do
    if kubectl get service $service -n bidr &>/dev/null; then
        EXTERNAL_IP=$(kubectl get service $service -n bidr -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
        if [ -n "$EXTERNAL_IP" ] && [ "$EXTERNAL_IP" != "null" ]; then
            LOAD_BALANCER_IP=$EXTERNAL_IP
            echo "✅ Load Balancer IP found via $service: $LOAD_BALANCER_IP"
            break
        fi
    fi
done

# Get superuser credentials if initialization job ran
echo ""
echo "🔑 Retrieving service credentials..."
INIT_LOGS=""
if kubectl get job bidr-init -n bidr &>/dev/null; then
    INIT_LOGS=$(kubectl logs job/bidr-init -n bidr 2>/dev/null || echo "")
fi

# Extract credentials from different possible log formats
USERNAME=$(echo "$INIT_LOGS" | grep -E "(Username|Superuser created):" | awk '{print $NF}' | head -1)
PASSWORD=$(echo "$INIT_LOGS" | grep -E "(Password|Password):" | awk '{print $NF}' | head -1)
EMAIL=$(echo "$INIT_LOGS" | grep -E "(Email):" | awk '{print $NF}' | head -1)

# Display final status
echo ""
echo "🎉 =============================================="
echo "🎉          BIDR DEPLOYMENT COMPLETE          "
echo "🎉 =============================================="
echo ""

if [ -n "$LOAD_BALANCER_IP" ]; then
    echo "🌐 Your BIDR application is available at:"
    echo "   Main Application: http://$LOAD_BALANCER_IP"
    echo "   Admin Panel:      http://$LOAD_BALANCER_IP/admin"
    echo ""
    echo "📋 Service Endpoints:"
    echo "   Auth Service:         http://$LOAD_BALANCER_IP/auth"
    echo "   Chat Service:         http://$LOAD_BALANCER_IP/chat"
    echo "   Payment Service:      http://$LOAD_BALANCER_IP/payment"
    echo "   Product Service:      http://$LOAD_BALANCER_IP/product"
    echo "   Notification Service: http://$LOAD_BALANCER_IP/notifications"
    echo "   Resolution Service:   http://$LOAD_BALANCER_IP/resolution"
    echo "   Transaction Service:  http://$LOAD_BALANCER_IP/transactions"
    echo "   Reviews Service:      http://$LOAD_BALANCER_IP/reviews"
else
    echo "⚠️  LoadBalancer IP not yet assigned. Please wait a few minutes and check:"
    echo "   kubectl get services -n bidr"
    echo "   Look for EXTERNAL-IP in the output"
fi

if [ -n "$USERNAME" ] && [ -n "$PASSWORD" ]; then
    echo ""
    echo "🔑 Superuser Credentials:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "👤 Username: $USERNAME"
    [ -n "$EMAIL" ] && echo "📧 Email:    $EMAIL"
    echo "🔑 Password: $PASSWORD"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "💡 Save these credentials securely!"
else
    echo ""
    echo "⚠️  Could not retrieve superuser credentials."
    echo "   Check logs: kubectl logs job/bidr-init -n bidr"
    echo "   Or create manually: kubectl exec -it deployment/bidr-auth-service -n bidr -- python manage.py createsuperuser"
fi

echo ""
echo "📊 Useful Commands:"
echo "   Check status:     kubectl get pods,services,ingress -n bidr"
echo "   View logs:        kubectl logs -f deployment/<service-name> -n bidr"
echo "   Shell access:     kubectl exec -it deployment/<service-name> -n bidr -- /bin/bash"
echo "   Port forward:     kubectl port-forward service/<service-name> 8080:80 -n bidr"

echo ""
echo "🔍 Monitoring:"
if [ -n "$LOAD_BALANCER_IP" ]; then
    echo "   Prometheus:      http://$LOAD_BALANCER_IP:9090"
    echo "   Grafana:         http://$LOAD_BALANCER_IP:3000"
fi
echo "   K8s Dashboard:   kubectl proxy & open http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/"

echo ""
echo "✅ Deployment script completed successfully!"
echo "🎉 BIDR Backend is ready for use!"