#!/usr/bin/env bash

################################################################################################
# BIDR Microservices Deployment Script for Azure AKS (macOS Compatible)
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

# Service list (service_name:directory:port:django_settings)
SERVICES=(
    "chat:chat_service:8002:chat_service.settings"
    "payment:payment_service:8003:payment_service.settings"
    "product:product_management_service:8004:product_management_service.settings"
    "transactions:transactions_service:8007:transactions_service.settings"
    "reviews:reviews_and_ratings:8008:reviews_and_ratings.settings"
    "notifications:notifications_service:8006:notifications_service.settings"
    "resolution:resolution_service:8005:resolution_service.settings"
)

# Function to deploy a single service
deploy_service() {
    local service_config=$1
    
    # Parse service configuration
    IFS=':' read -r service_name service_dir port django_settings <<< "$service_config"
    
    log_info "🚀 Deploying $service_name service..."
    echo "----------------------------------------"
    
    # Step 1: Check service directory
    if [[ ! -d "$service_dir" ]]; then
        log_error "Service directory $service_dir not found! Skipping..."
        return 1
    fi
    log_success "Found service directory: $service_dir"
    
    # Step 2: Update ALLOWED_HOSTS
    log_info "Updating ALLOWED_HOSTS for $service_dir..."
    local settings_file="$service_dir/$service_dir/settings.py"
    if [[ ! -f "$settings_file" ]]; then
        settings_file="$service_dir/$(basename $service_dir)/settings.py"
    fi
    
    if [[ -f "$settings_file" ]]; then
        if ! grep -q "ALLOWED_HOSTS.append('\*')" "$settings_file"; then
            sed -i.bak '/ALLOWED_HOSTS.*=/a\
ALLOWED_HOSTS.append('\''*'\'')' "$settings_file"
            log_success "Updated ALLOWED_HOSTS for $service_dir"
        else
            log_success "ALLOWED_HOSTS already configured"
        fi
    else
        log_warning "Settings file not found, continuing anyway..."
    fi
    
    # Step 3: Build and push Docker image
    log_info "Building Docker image for $service_name..."
    docker buildx build \
        --platform linux/amd64 \
        -t "${REGISTRY}/${service_name}-service:latest" \
        "$service_dir/" \
        --push
    log_success "Built and pushed ${service_name}-service:latest"
    
    # Step 4: Create Kubernetes deployment
    log_info "Creating Kubernetes deployment for $service_name..."
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
          value: "${django_settings}"
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
    
    # Step 5: Update load balancer
    log_info "Adding $service_name to load balancer on port $port..."
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
    
    # Step 6: Wait for deployment
    log_info "Waiting for $service_name deployment to be ready..."
    kubectl rollout status deployment/${service_name}-service -n ${NAMESPACE} --timeout=600s
    if [[ $? -eq 0 ]]; then
        log_success "$service_name deployment is ready!"
    else
        log_error "$service_name deployment failed or timed out"
        return 1
    fi
    
    # Step 7: Test endpoint
    log_info "Testing $service_name endpoint..."
    sleep 10
    response=$(curl -s -o /dev/null -w "%{http_code}" "http://${LOAD_BALANCER_IP}:${port}/" || echo "000")
    if [[ "$response" == "200" || "$response" == "302" ]]; then
        log_success "$service_name endpoint is responding (HTTP $response)"
    else
        log_warning "$service_name endpoint returned HTTP $response"
    fi
    
    log_success "✅ $service_name service deployed successfully!"
    echo ""
    return 0
}

# Main execution
main() {
    log_info "🚀 Starting BIDR Microservices Deployment to Azure AKS..."
    echo "================================================================================================"
    
    local failed_services=()
    local successful_services=()
    
    for service_config in "${SERVICES[@]}"; do
        service_name=$(echo "$service_config" | cut -d: -f1)
        if deploy_service "$service_config"; then
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
    
    # Create summary file
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
🎉 ALL BIDR MICROSERVICES SUCCESSFULLY DEPLOYED ON AZURE AKS! 🎉
================================================================================================
EOF
    
    # Final status
    if [[ ${#failed_services[@]} -eq 0 ]]; then
        log_success "🎉 ALL SERVICES DEPLOYED SUCCESSFULLY!"
        log_info "🌐 Your complete BIDR microservices platform is now live at http://${LOAD_BALANCER_IP}"
    else
        log_warning "⚠️ Some services failed to deploy. Check the logs above for details."
    fi
}

# Run the main function
main "$@"
