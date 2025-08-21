#!/bin/bash

# BIDR Backend Deployment Script
# This script builds Docker images and deploys to Azure Kubernetes Service

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
RESOURCE_GROUP="bidr-k8s"
ACR_NAME="bidrcontainerregistry"
AKS_CLUSTER_NAME="BIDR-aks-cluster"
NAMESPACE="bidr"

# Services to deploy
SERVICES=(
    "authentication_service:auth-service"
    "chat_service:chat-service" 
    "payment_service:payment-service"
    "resolution_service:resolution-service"
    "product_management_service:product-service"
    "notifications_service:notifications-service"
    "transactions_service:transactions-service"
    "reviews_and_ratings:reviews-service"
)

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    local missing_commands=()
    
    if ! command_exists docker; then
        missing_commands+=("docker")
    fi
    
    if ! command_exists az; then
        missing_commands+=("azure-cli")
    fi
    
    if ! command_exists kubectl; then
        missing_commands+=("kubectl")
    fi
    
    if [ ${#missing_commands[@]} -ne 0 ]; then
        print_error "Missing required commands: ${missing_commands[*]}"
        print_error "Please install them and try again."
        exit 1
    fi
    
    print_success "All prerequisites found"
}

# Login to Azure and ACR
azure_login() {
    print_status "Logging into Azure and ACR..."
    
    # Check if already logged in
    if ! az account show >/dev/null 2>&1; then
        print_status "Please login to Azure..."
        az login
    fi
    
    # Login to ACR
    az acr login --name $ACR_NAME
    print_success "Logged into Azure and ACR"
}

# Get AKS credentials
get_aks_credentials() {
    print_status "Getting AKS credentials..."
    az aks get-credentials --resource-group $RESOURCE_GROUP --name $AKS_CLUSTER_NAME --overwrite-existing
    print_success "AKS credentials configured"
}

# Build and push Docker images
build_and_push_images() {
    print_status "Building and pushing Docker images..."
    
    local acr_login_server=$(az acr show --name $ACR_NAME --resource-group $RESOURCE_GROUP --query "loginServer" --output tsv)
    
    for service_mapping in "${SERVICES[@]}"; do
        IFS=':' read -r service_dir image_name <<< "$service_mapping"
        
        if [ ! -d "$service_dir" ]; then
            print_warning "Directory $service_dir not found, skipping..."
            continue
        fi
        
        print_status "Building $image_name from $service_dir..."
        
        # Build the image
        docker build -t $image_name:latest $service_dir/
        
        # Tag for ACR
        docker tag $image_name:latest $acr_login_server/$image_name:latest
        docker tag $image_name:latest $acr_login_server/$image_name:$(git rev-parse --short HEAD)
        
        # Push to ACR
        print_status "Pushing $image_name to ACR..."
        docker push $acr_login_server/$image_name:latest
        docker push $acr_login_server/$image_name:$(git rev-parse --short HEAD)
        
        print_success "Successfully built and pushed $image_name"
    done
}

# Create namespace and apply RBAC
setup_kubernetes() {
    print_status "Setting up Kubernetes resources..."
    
    # Apply namespace and RBAC
    kubectl apply -f k8s/namespace-rbac.yaml
    
    # Create ACR secret if it doesn't exist
    if ! kubectl get secret acr-secret -n $NAMESPACE >/dev/null 2>&1; then
        print_status "Creating ACR secret..."
        
        local acr_username=$(az acr credential show --name $ACR_NAME --query "username" --output tsv)
        local acr_password=$(az acr credential show --name $ACR_NAME --query "passwords[0].value" --output tsv)
        local acr_login_server=$(az acr show --name $ACR_NAME --resource-group $RESOURCE_GROUP --query "loginServer" --output tsv)
        
        kubectl create secret docker-registry acr-secret \
            --docker-server=$acr_login_server \
            --docker-username=$acr_username \
            --docker-password=$acr_password \
            --namespace=$NAMESPACE
        
        print_success "ACR secret created"
    fi
}

# Deploy services
deploy_services() {
    print_status "Deploying services to Kubernetes..."
    
    # Apply secrets (you need to create bidr-secret first)
    if ! kubectl get secret bidr-secret -n $NAMESPACE >/dev/null 2>&1; then
        print_warning "bidr-secret not found. Creating template secret..."
        kubectl apply -f k8s/secret.yaml
    fi
    
    # Apply configmap
    if [ -f "k8s/configmap.yaml" ]; then
        kubectl apply -f k8s/configmap.yaml
    fi
    
    # Deploy all services
    kubectl apply -f k8s/all-services.yaml
    
    # Apply ingress
    kubectl apply -f k8s/ingress.yaml
    
    print_success "Services deployed to Kubernetes"
}

# Wait for deployments
wait_for_deployments() {
    print_status "Waiting for deployments to be ready..."
    
    local services=("auth-service" "chat-service" "payment-service" "resolution-service" "product-service" "notifications-service" "transactions-service" "reviews-service")
    
    for service in "${services[@]}"; do
        print_status "Waiting for $service to be ready..."
        kubectl wait --for=condition=available --timeout=300s deployment/$service -n $NAMESPACE
        print_success "$service is ready"
    done
}

# Get service URLs
get_service_urls() {
    print_status "Getting service URLs..."
    
    # Get LoadBalancer IP
    local lb_ip=$(kubectl get service bidr-loadbalancer -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "pending")
    
    if [ "$lb_ip" = "pending" ] || [ -z "$lb_ip" ]; then
        print_warning "LoadBalancer IP is still pending. Please check later with:"
        echo "kubectl get service bidr-loadbalancer -n $NAMESPACE"
    else
        print_success "BIDR API is available at: http://$lb_ip"
        echo ""
        echo "Service endpoints:"
        echo "  Authentication: http://$lb_ip/api/v1/auth/"
        echo "  Chat:          http://$lb_ip/api/v1/chat/"
        echo "  Payment:       http://$lb_ip/api/v1/payment/"
        echo "  Resolution:    http://$lb_ip/api/v1/resolution/"
        echo "  Products:      http://$lb_ip/api/v1/products/"
        echo "  Notifications: http://$lb_ip/api/v1/notifications/"
        echo "  Transactions:  http://$lb_ip/api/v1/transactions/"
        echo "  Reviews:       http://$lb_ip/api/v1/reviews/"
        echo ""
        echo "Admin interfaces:"
        echo "  Authentication Admin: http://$lb_ip/admin/auth/"
        echo "  Chat Admin:          http://$lb_ip/admin/chat/"
        echo "  Payment Admin:       http://$lb_ip/admin/payment/"
        echo "  And more..."
    fi
    
    print_success "Deployment completed successfully!"
}

# Main deployment function
main() {
    echo "=========================================="
    echo "BIDR Backend Deployment Script"
    echo "=========================================="
    
    check_prerequisites
    azure_login
    get_aks_credentials
    build_and_push_images
    setup_kubernetes
    deploy_services
    wait_for_deployments
    get_service_urls
}

# Run deployment
main "$@"
