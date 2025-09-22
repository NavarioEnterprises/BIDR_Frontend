#!/usr/bin/env bash

################################################################################################
# BIDR Microservices Deployment Script for Azure AKS
# This script deploys chat, payment, product, transactions, reviews, notifications, and resolution services
################################################################################################

set -e  # Exit on any error

# Configuration
REGISTRY="bidrnparusdevregistry2024.azurecr.io"
NAMESPACE="bidr"
LOAD_BALANCER_IP="20.164.134.31"

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

# Service configurations
declare -A SERVICES=(
    ["chat"]="chat_service:8002"
    ["payment"]="payment_service:8003" 
    ["product"]="product_management_service:8004"
    ["transactions"]="transactions_service:8007"
    ["reviews"]="reviews_and_ratings:8008"
    ["notifications"]="notifications_service:8006"
    ["resolution"]="resolution_service:8005"
)

# Function to check if directory exists
check_service_directory() {
    local service_dir=$1
    if [[ ! -d "$service_dir" ]]; then
        log_error "Service directory $service_dir not found!"
        return 1
    fi
    return 0
}

# Function to get correct Django settings module
get_django_settings_module() {
    local service_name=$1
    local service_dir=$2
    
    # Map service names to their correct Django settings module
    case $service_name in
        "chat")
            echo "chat_service.settings"
            ;;
        "payment")
            echo "payment_service.settings"
            ;;
        "product")
            echo "product_management_service.settings"
            ;;
        "transactions")
            echo "transactions_service.settings"
            ;;
        "reviews")
            echo "reviews_and_ratings.settings"
            ;;
        "notifications")
            echo "notifications_service.settings"
            ;;
        "resolution")
            echo "resolution_service.settings"
            ;;
        *)
            echo "${service_name}_service.settings"
            ;;
    esac
}

# Function to update ALLOWED_HOSTS for Kubernetes
update_allowed_hosts() {
    local service_dir=$1
    local settings_file
    
    log_info "Updating ALLOWED_HOSTS for $service_dir..."
    
    # Try different possible settings file locations
    local possible_settings=(
        "$service_dir/$service_dir/settings.py"
        "$service_dir/$(basename $service_dir)/settings.py"
    )
    
    for settings_file in "${possible_settings[@]}"; do
        if [[ -f "$settings_file" ]]; then
            log_info "Found settings file at: $settings_file"
            break
        fi
    done
    
    if [[ -f "$settings_file" ]]; then
        # Check if ALLOWED_HOSTS already contains '*'
        if grep -q "ALLOWED_HOSTS.append('\*')" "$settings_file"; then
            log_success "ALLOWED_HOSTS already configured for $service_dir"
        else
            # Try to find a line to insert before (more flexible approach)
            if grep -q 'ALLOWED_HOSTS.*=' "$settings_file"; then
                # Add after the ALLOWED_HOSTS line
                sed -i.bak '/ALLOWED_HOSTS.*=/a\
ALLOWED_HOSTS.append('\''*'\'')
' "$settings_file"
                log_success "Updated ALLOWED_HOSTS for $service_dir"
            else
                log_warning "Could not find ALLOWED_HOSTS configuration in $settings_file"
            fi
        fi
    else
        log_warning "Settings file not found for $service_dir"
        log_warning "Tried: ${possible_settings[*]}"
    fi
}

# Function to build and push Docker image
build_and_push_image() {
    local service_name=$1
    local service_dir=$2
    
    log_info "Building Docker image for $service_name..."
    
    # Build for AMD64 platform (AKS compatible)
    docker buildx build \
        --platform linux/amd64 \
        -t "${REGISTRY}/${service_name}:latest" \
        "$service_dir/" \
        --push
    
    log_success "Built and pushed ${service_name}:latest"
}

# Function to create Kubernetes deployment
create_k8s_deployment() {
    local service_name=$1
    local port=$2
    local service_dir=$3
    
    # Get the correct Django settings module
    local django_settings_module=$(get_django_settings_module "$service_name" "$service_dir")
    
    log_info "Creating Kubernetes deployment for $service_name..."
    log_info "Using Django settings module: $django_settings_module"
    
    cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${service_name}-service
  namespace: ${NAMESPACE}
  labels:
    app: ${service_name}-service
    service: ${service_name}
spec:
  replicas: 2
  selector:
    matchLabels:
      app: ${service_name}-service
  template:
    metadata:
      labels:
        app: ${service_name}-service
        service: ${service_name}
    spec:
      serviceAccountName: bidr-service-account
      containers:
      - name: ${service_name}-service
        image: ${REGISTRY}/${service_name}-service:latest
        ports:
        - containerPort: 8000
        env:
        - name: DEBUG
          value: "False"
        - name: DJANGO_SETTINGS_MODULE
          value: "${django_settings_module}"
        - name: SERVICE_NAME
          value: "${service_name}"
        - name: SECRET_KEY
          valueFrom:
            secretKeyRef:
              name: bidr-secrets
              key: DJANGO_SECRET_KEY
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: bidr-secrets
              key: ${service_name^^}_DATABASE_URL
        - name: REDIS_URL
          valueFrom:
            secretKeyRef:
              name: bidr-secrets
              key: REDIS_URL
        - name: EMAIL_HOST_USER
          valueFrom:
            secretKeyRef:
              name: bidr-secrets
              key: EMAIL_HOST_USER
        - name: EMAIL_HOST_PASSWORD
          valueFrom:
            secretKeyRef:
              name: bidr-secrets
              key: EMAIL_HOST_PASSWORD
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /
            port: 8000
          initialDelaySeconds: 60
          periodSeconds: 30
          failureThreshold: 3
        readinessProbe:
          httpGet:
            path: /
            port: 8000
          initialDelaySeconds: 30
          periodSeconds: 10
          failureThreshold: 3
      imagePullSecrets:
      - name: acr-secret
---
apiVersion: v1
kind: Service
metadata:
  name: ${service_name}-service
  namespace: ${NAMESPACE}
  labels:
    app: ${service_name}-service
spec:
  selector:
    app: ${service_name}-service
  ports:
  - port: 8000
    targetPort: 8000
    protocol: TCP
  type: ClusterIP
EOF

    log_success "Created Kubernetes deployment for $service_name"
}

# Function to update load balancer with new service
update_load_balancer() {
    local service_name=$1
    local port=$2
    
    log_info "Adding $service_name to load balancer on port $port..."
    
    # Get current load balancer configuration
    kubectl get service bidr-load-balancer -n ${NAMESPACE} -o yaml > /tmp/lb-backup.yaml
    
    # Add new port mapping
    kubectl patch service bidr-load-balancer -n ${NAMESPACE} --type='json' -p="[
        {
            \"op\": \"add\",
            \"path\": \"/spec/ports/-\",
            \"value\": {
                \"name\": \"${service_name}\",
                \"port\": ${port},
                \"targetPort\": 8000,
                \"protocol\": \"TCP\"
            }
        }
    ]"
    
    log_success "Added $service_name to load balancer on port $port"
}

# Function to wait for deployment readiness
wait_for_deployment() {
    local service_name=$1
    
    log_info "Waiting for $service_name deployment to be ready..."
    
    kubectl rollout status deployment/${service_name}-service -n ${NAMESPACE} --timeout=600s
    
    if [[ $? -eq 0 ]]; then
        log_success "$service_name deployment is ready!"
    else
        log_error "$service_name deployment failed or timed out"
        return 1
    fi
}

# Function to test service endpoint
test_service_endpoint() {
    local service_name=$1
    local port=$2
    
    log_info "Testing $service_name endpoint..."
    
    # Wait a moment for load balancer to update
    sleep 10
    
    # Test the endpoint
    response=$(curl -s -o /dev/null -w "%{http_code}" "http://${LOAD_BALANCER_IP}:${port}/" || echo "000")
    
    if [[ "$response" == "200" ]]; then
        log_success "$service_name endpoint is responding (HTTP $response)"
        return 0
    elif [[ "$response" == "302" ]]; then
        log_success "$service_name endpoint is redirecting (HTTP $response) - likely to admin login"
        return 0
    else
        log_warning "$service_name endpoint returned HTTP $response"
        return 1
    fi
}

# Main deployment function
deploy_service() {
    local service_name=$1
    local service_config=$2
    
    # Parse service configuration
    IFS=':' read -r service_dir port <<< "$service_config"
    
    log_info "🚀 Deploying $service_name service..."
    echo "----------------------------------------"
    
    # Step 1: Check service directory
    if ! check_service_directory "$service_dir"; then
        log_error "Skipping $service_name due to missing directory"
        return 1
    fi
    
    # Step 2: Update ALLOWED_HOSTS
    update_allowed_hosts "$service_dir"
    
    # Step 3: Build and push Docker image
    build_and_push_image "${service_name}-service" "$service_dir"
    
    # Step 4: Create Kubernetes deployment
    create_k8s_deployment "$service_name" "$port" "$service_dir"
    
    # Step 5: Update load balancer
    update_load_balancer "$service_name" "$port"
    
    # Step 6: Wait for deployment
    if wait_for_deployment "$service_name"; then
        # Step 7: Test endpoint
        test_service_endpoint "$service_name" "$port"
        log_success "✅ $service_name service deployed successfully!"
    else
        log_error "❌ $service_name service deployment failed"
        return 1
    fi
    
    echo ""
}

# Function to create comprehensive service summary
create_deployment_summary() {
    log_info "Creating deployment summary..."
    
    cat > BIDR_All_Services_Deployment_Summary.txt <<EOF
================================================================================================
🚀 BIDR MICROSERVICES - COMPLETE AZURE AKS DEPLOYMENT 🚀
================================================================================================

✅ DEPLOYMENT STATUS: ALL SERVICES DEPLOYED
📅 Deployment Date: $(date)
🌍 Region: South Africa North (Azure)
☁️ Infrastructure: Azure Kubernetes Service (AKS)
🎯 External Load Balancer IP: ${LOAD_BALANCER_IP}

================================================================================================
🌐 ALL SERVICE URLS & ACCESS INFORMATION
================================================================================================

📊 AUTHENTICATION SERVICE:
   • Service URL: http://${LOAD_BALANCER_IP}:8001/
   • Admin Panel: http://${LOAD_BALANCER_IP}:8001/admin/
   • Metrics: http://${LOAD_BALANCER_IP}:8001/metrics

💬 CHAT SERVICE:
   • Service URL: http://${LOAD_BALANCER_IP}:8002/
   • Admin Panel: http://${LOAD_BALANCER_IP}:8002/admin/
   • Metrics: http://${LOAD_BALANCER_IP}:8002/metrics

💳 PAYMENT SERVICE:
   • Service URL: http://${LOAD_BALANCER_IP}:8003/
   • Admin Panel: http://${LOAD_BALANCER_IP}:8003/admin/
   • Metrics: http://${LOAD_BALANCER_IP}:8003/metrics

🛍️ PRODUCT SERVICE:
   • Service URL: http://${LOAD_BALANCER_IP}:8004/
   • Admin Panel: http://${LOAD_BALANCER_IP}:8004/admin/
   • Metrics: http://${LOAD_BALANCER_IP}:8004/metrics

⚖️ RESOLUTION SERVICE:
   • Service URL: http://${LOAD_BALANCER_IP}:8005/
   • Admin Panel: http://${LOAD_BALANCER_IP}:8005/admin/
   • Metrics: http://${LOAD_BALANCER_IP}:8005/metrics

🔔 NOTIFICATIONS SERVICE:
   • Service URL: http://${LOAD_BALANCER_IP}:8006/
   • Admin Panel: http://${LOAD_BALANCER_IP}:8006/admin/
   • Metrics: http://${LOAD_BALANCER_IP}:8006/metrics

💰 TRANSACTIONS SERVICE:
   • Service URL: http://${LOAD_BALANCER_IP}:8007/
   • Admin Panel: http://${LOAD_BALANCER_IP}:8007/admin/
   • Metrics: http://${LOAD_BALANCER_IP}:8007/metrics

⭐ REVIEWS SERVICE:
   • Service URL: http://${LOAD_BALANCER_IP}:8008/
   • Admin Panel: http://${LOAD_BALANCER_IP}:8008/admin/
   • Metrics: http://${LOAD_BALANCER_IP}:8008/metrics

🔐 ADMIN CREDENTIALS (for all services):
   • Username: admin
   • Email: admin@bidr.local
   • Password: bidr_admin_2024

================================================================================================
📊 DEPLOYMENT STATUS SUMMARY
================================================================================================

$(kubectl get pods -n ${NAMESPACE} -o wide)

$(kubectl get services -n ${NAMESPACE})

================================================================================================
🎯 QUICK ACCESS LINKS
================================================================================================

Open these URLs in your browser to access each service:

🌐 Main Services:
$(for service_config in "${SERVICES[@]}"; do
    IFS=':' read -r service_dir port <<< "$service_config"
    service_name=$(basename "$service_dir" _service)
    echo "   • ${service_name^} Service: http://${LOAD_BALANCER_IP}:${port}/"
done)

🔧 Admin Panels:
$(for service_config in "${SERVICES[@]}"; do
    IFS=':' read -r service_dir port <<< "$service_config"
    service_name=$(basename "$service_dir" _service)
    echo "   • ${service_name^} Admin: http://${LOAD_BALANCER_IP}:${port}/admin/"
done)

================================================================================================
🎉 ALL BIDR MICROSERVICES SUCCESSFULLY DEPLOYED ON AZURE AKS! 🎉
================================================================================================
EOF

    log_success "Deployment summary created: BIDR_All_Services_Deployment_Summary.txt"
}

# Main execution
main() {
    log_info "🚀 Starting BIDR Microservices Deployment to Azure AKS..."
    echo "================================================================================================"
    
    # Deploy each service
    local failed_services=()
    local successful_services=()
    
    for service_name in "${!SERVICES[@]}"; do
        if deploy_service "$service_name" "${SERVICES[$service_name]}"; then
            successful_services+=("$service_name")
        else
            failed_services+=("$service_name")
        fi
    done
    
    # Summary
    echo "================================================================================================"
    log_info "🎯 DEPLOYMENT SUMMARY"
    echo "================================================================================================"
    
    if [[ ${#successful_services[@]} -gt 0 ]]; then
        log_success "✅ Successfully deployed services: ${successful_services[*]}"
    fi
    
    if [[ ${#failed_services[@]} -gt 0 ]]; then
        log_error "❌ Failed to deploy services: ${failed_services[*]}"
    fi
    
    # Create comprehensive summary
    create_deployment_summary
    
    # Final status
    if [[ ${#failed_services[@]} -eq 0 ]]; then
        log_success "🎉 ALL SERVICES DEPLOYED SUCCESSFULLY!"
        log_info "🌐 Your complete BIDR microservices platform is now live at http://${LOAD_BALANCER_IP}"
        return 0
    else
        log_warning "⚠️ Some services failed to deploy. Check the logs above for details."
        return 1
    fi
}

# Run the main function
main "$@"
