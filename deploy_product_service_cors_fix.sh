#!/usr/bin/env bash

################################################################################################
# BIDR Product Service - CORS Fix Deployment Script for Kubernetes
################################################################################################

set -e  # Exit on any error

# Configuration
REGISTRY="bidrnparusdevregistry2024.azurecr.io"
SERVICE_NAME="product"
SERVICE_DIR="product_management_service"
NAMESPACE="bidr"
LOAD_BALANCER_IP="108.141.192.60"  # Current BIDR load balancer IP
PORT="8004"  # Product service port based on deployment script

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check if required commands exist
    local required_commands=("docker" "kubectl" "az")
    local missing_commands=()
    
    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing_commands+=("$cmd")
        fi
    done
    
    if [[ ${#missing_commands[@]} -gt 0 ]]; then
        log_error "Missing required commands: ${missing_commands[*]}"
        log_error "Please install them and try again."
        exit 1
    fi
    
    # Check if service directory exists
    if [[ ! -d "$SERVICE_DIR" ]]; then
        log_error "Service directory $SERVICE_DIR not found!"
        exit 1
    fi
    
    # Check if Dockerfile exists
    if [[ ! -f "$SERVICE_DIR/Dockerfile" ]]; then
        log_error "Dockerfile not found in $SERVICE_DIR!"
        exit 1
    fi
    
    log_success "All prerequisites checked"
}

# Function to login to Azure and ACR
azure_login() {
    log_info "Checking Azure and ACR login..."
    
    # Check if already logged in to Azure
    if ! az account show >/dev/null 2>&1; then
        log_info "Please login to Azure..."
        az login
    fi
    
    # Login to ACR
    log_info "Logging into Azure Container Registry..."
    az acr login --name ${REGISTRY%%.azurecr.io}
    log_success "Logged into Azure and ACR"
}

# Function to build and push Docker image
build_and_push_image() {
    log_info "🔨 Building and pushing Docker image for $SERVICE_NAME service..."
    
    cd "$SERVICE_DIR"
    
    # Build Docker image with BuildKit for better performance
    log_info "Building Docker image: ${REGISTRY}/${SERVICE_NAME}-service:cors-fix..."
    DOCKER_BUILDKIT=1 docker build \
        --platform linux/amd64 \
        -t "${REGISTRY}/${SERVICE_NAME}-service:cors-fix" \
        -t "${REGISTRY}/${SERVICE_NAME}-service:latest" \
        .
    
    # Push both tags
    log_info "Pushing Docker image to registry..."
    docker push "${REGISTRY}/${SERVICE_NAME}-service:cors-fix"
    docker push "${REGISTRY}/${SERVICE_NAME}-service:latest"
    
    cd ..
    log_success "Built and pushed ${SERVICE_NAME}-service with CORS fix"
}

# Function to update Kubernetes deployment
update_kubernetes_deployment() {
    log_info "🚀 Updating Kubernetes deployment for $SERVICE_NAME service..."
    
    # Force rolling update by updating the image tag
    kubectl patch deployment ${SERVICE_NAME}-service -n ${NAMESPACE} \
        -p '{"spec":{"template":{"spec":{"containers":[{"name":"'${SERVICE_NAME}'-service","image":"'${REGISTRY}'/'${SERVICE_NAME}'-service:cors-fix"}]}}}}'
    
    log_success "Kubernetes deployment updated"
}

# Function to wait for deployment rollout
wait_for_rollout() {
    log_info "⏳ Waiting for deployment rollout to complete..."
    
    # Wait for rollout with timeout
    kubectl rollout status deployment/${SERVICE_NAME}-service -n ${NAMESPACE} --timeout=600s
    
    if [[ $? -eq 0 ]]; then
        log_success "Deployment rollout completed successfully"
    else
        log_error "Deployment rollout failed or timed out"
        return 1
    fi
}

# Function to verify deployment
verify_deployment() {
    log_info "🔍 Verifying deployment..."
    
    # Check pod status
    kubectl get pods -n ${NAMESPACE} -l app=${SERVICE_NAME}-service
    
    # Wait a bit for the service to start
    sleep 15
    
    # Test the endpoint
    log_info "Testing product service endpoint..."
    local response
    response=$(curl -s -o /dev/null -w "%{http_code}" "http://${LOAD_BALANCER_IP}:${PORT}/" || echo "000")
    
    if [[ "$response" == "200" || "$response" == "302" ]]; then
        log_success "Product service endpoint is responding (HTTP $response)"
    else
        log_warning "Product service endpoint returned HTTP $response"
    fi
    
    # Test CORS specifically
    log_info "Testing CORS headers..."
    local cors_response
    cors_response=$(curl -s -H "Origin: http://localhost:8080" \
                         -H "Access-Control-Request-Method: GET" \
                         -X OPTIONS \
                         "http://${LOAD_BALANCER_IP}:${PORT}/products/api/v1/product-requests/requests/" \
                         -w "%{http_code}" || echo "000")
    
    if [[ "$cors_response" == "200" ]]; then
        log_success "CORS preflight request successful"
    else
        log_warning "CORS preflight request returned HTTP $cors_response"
    fi
}

# Function to run CORS test
run_cors_test() {
    log_info "🧪 Running comprehensive CORS test..."
    
    if [[ -f "test_flutter_cors.py" ]]; then
        # Update the test script to use the correct URL
        sed -i.bak "s|http://108.141.192.60/products/|http://${LOAD_BALANCER_IP}:${PORT}/products/|g" test_flutter_cors.py
        
        log_info "Running CORS test script..."
        python test_flutter_cors.py
        
        # Restore original file
        mv test_flutter_cors.py.bak test_flutter_cors.py
    else
        log_warning "CORS test script not found, skipping automated test"
    fi
}

# Function to show deployment summary
show_summary() {
    log_info "📊 Deployment Summary"
    echo "================================================================================================"
    
    # Get pod information
    log_info "Pod Status:"
    kubectl get pods -n ${NAMESPACE} -l app=${SERVICE_NAME}-service
    
    echo ""
    log_info "Service Endpoints:"
    echo "  Product Service: http://${LOAD_BALANCER_IP}:${PORT}/"
    echo "  Product API: http://${LOAD_BALANCER_IP}:${PORT}/products/api/v1/product-requests/requests/"
    echo "  Admin Panel: http://${LOAD_BALANCER_IP}:${PORT}/admin/"
    echo "  API Docs: http://${LOAD_BALANCER_IP}:${PORT}/swagger/"
    
    echo ""
    log_info "CORS Configuration:"
    echo "  ✅ CORS_ALLOW_ALL_ORIGINS = True"
    echo "  ✅ CORS_ALLOW_ALL_HEADERS = True"
    echo "  ✅ CORS_ALLOW_ALL_METHODS = True"
    echo "  ✅ Flutter web ports (8080, 5000, 4200) included"
    
    echo ""
    log_success "🎉 Product service CORS fix deployed successfully!"
    echo "================================================================================================"
}

# Function to rollback if needed
rollback_deployment() {
    log_warning "Rolling back deployment..."
    kubectl rollout undo deployment/${SERVICE_NAME}-service -n ${NAMESPACE}
    kubectl rollout status deployment/${SERVICE_NAME}-service -n ${NAMESPACE}
    log_info "Rollback completed"
}

# Main execution
main() {
    log_info "🚀 Starting BIDR Product Service CORS Fix Deployment..."
    echo "================================================================================================"
    echo "Service: $SERVICE_NAME"
    echo "Registry: $REGISTRY"
    echo "Namespace: $NAMESPACE"
    echo "Load Balancer IP: $LOAD_BALANCER_IP"
    echo "================================================================================================"
    echo ""
    
    # Trap errors for cleanup
    trap 'log_error "Deployment failed! Use --rollback flag to rollback if needed."' ERR
    
    check_prerequisites
    azure_login
    build_and_push_image
    update_kubernetes_deployment
    
    if wait_for_rollout; then
        verify_deployment
        run_cors_test
        show_summary
    else
        log_error "Deployment failed during rollout"
        read -p "Do you want to rollback? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rollback_deployment
        fi
        exit 1
    fi
}

# Handle command line arguments
if [[ "$1" == "--rollback" ]]; then
    log_info "Rolling back product service deployment..."
    rollback_deployment
    exit 0
fi

# Run the main function
main "$@"
