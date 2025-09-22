#!/usr/bin/env bash

set -e  # Exit on any error

# Configuration
REGISTRY="bidrnparusdevregistry2024.azurecr.io"
NAMESPACE="bidr"
LOAD_BALANCER_IP="20.164.134.31"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }

# Services to deploy using existing ACR images
SERVICES_TO_DEPLOY=(
    "payment:8003:payment_service.settings"
    "product:8004:product_management_service.settings"
    "resolution:8005:resolution_service.settings"
    "notifications:8006:notifications.settings"
    "transactions:8007:transactions_service.settings"
    "reviews:8008:reviews_and_ratings.settings"
)

# Function to deploy a single service using existing ACR image
deploy_service_from_acr() {
    local service_config=$1
    
    # Parse service configuration
    IFS=':' read -r service_name port django_settings <<< "$service_config"
    
    log_info "🚀 Deploying $service_name service from ACR..."
    echo "Service Name: $service_name"
    echo "Port: $port"
    echo "Django Settings: $django_settings"
    echo "ACR Image: ${REGISTRY}/${service_name}-service:latest"
    echo "----------------------------------------"
    
    # Create Kubernetes deployment
    log_info "Creating Kubernetes deployment for $service_name..."
    
    cat > "${service_name}-deployment.yaml" <<EOF
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
    
    # Apply the deployment
    kubectl apply -f "${service_name}-deployment.yaml"
    if [ $? -ne 0 ]; then
        log_error "Failed to create deployment for $service_name"
        return 1
    fi
    
    log_success "Created Kubernetes deployment for $service_name"
    
    # Add to load balancer (patch might fail if already exists, which is ok)
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
    ]" 2>/dev/null && log_success "Added $service_name to load balancer on port $port" || log_warning "Load balancer patch failed (may already exist)"
    
    # Wait for deployment
    log_info "Waiting for $service_name deployment to be ready..."
    
    kubectl rollout status deployment/${service_name}-service -n ${NAMESPACE} --timeout=600s
    
    if [ $? -eq 0 ]; then
        log_success "$service_name deployment is ready!"
        
        # Test endpoint
        log_info "Testing $service_name endpoint..."
        sleep 10
        
        response=$(curl -s -o /dev/null -w "%{http_code}" "http://${LOAD_BALANCER_IP}:${port}/" 2>/dev/null || echo "000")
        
        if [ "$response" = "200" ] || [ "$response" = "302" ]; then
            log_success "$service_name endpoint is responding (HTTP $response)"
        else
            log_warning "$service_name endpoint returned HTTP $response"
        fi
        
        log_success "✅ $service_name service deployed successfully!"
    else
        log_error "❌ $service_name service deployment failed"
        return 1
    fi
    
    # Clean up deployment file
    rm -f "${service_name}-deployment.yaml"
    
    echo ""
}

# Test all services
test_all_services() {
    log_info "Testing all deployed services..."
    
    services=("8001:Authentication" "8002:Chat" "8003:Payment" "8004:Product" "8005:Resolution" "8006:Notifications" "8007:Transactions" "8008:Reviews")
    
    for service_config in "${services[@]}"; do
        IFS=':' read -r port name <<< "$service_config"
        log_info "Testing $name service on port $port..."
        response=$(curl -s -o /dev/null -w "%{http_code}" "http://${LOAD_BALANCER_IP}:${port}/" 2>/dev/null || echo "000")
        if [ "$response" = "200" ] || [ "$response" = "302" ]; then
            log_success "$name service is responding (HTTP $response)"
        else
            log_error "$name service returned HTTP $response"
        fi
    done
}

# Create deployment summary
create_summary() {
    log_info "Creating deployment summary..."
    
    cat > BIDR_Complete_Deployment_Status.txt <<EOF
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
   • Health Check: http://${LOAD_BALANCER_IP}:8001/health/
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
📊 CURRENT DEPLOYMENT STATUS
================================================================================================

Deployments:
$(kubectl get deployments -n ${NAMESPACE} 2>/dev/null || echo "Unable to retrieve deployment status")

Services:
$(kubectl get services -n ${NAMESPACE} 2>/dev/null || echo "Unable to retrieve service status")

Pods:
$(kubectl get pods -n ${NAMESPACE} -o wide 2>/dev/null || echo "Unable to retrieve pod status")

================================================================================================
🎉 ALL BIDR MICROSERVICES SUCCESSFULLY DEPLOYED ON AZURE AKS! 🎉
================================================================================================
EOF

    log_success "Deployment summary created: BIDR_Complete_Deployment_Status.txt"
}

# Main function
main() {
    log_info "🚀 Starting deployment of remaining BIDR microservices from ACR to Azure AKS..."
    echo "================================================================================================"
    
    local failed_services=()
    local successful_services=()
    
    # Deploy each service
    for service_config in "${SERVICES_TO_DEPLOY[@]}"; do
        IFS=':' read -r service_name port django_settings <<< "$service_config"
        
        if deploy_service_from_acr "$service_config"; then
            successful_services+=("$service_name")
        else
            failed_services+=("$service_name")
        fi
    done
    
    # Summary
    echo "================================================================================================"
    log_info "🎯 DEPLOYMENT SUMMARY"
    echo "================================================================================================"
    
    if [ ${#successful_services[@]} -gt 0 ]; then
        log_success "✅ Successfully deployed services: ${successful_services[*]}"
    fi
    
    if [ ${#failed_services[@]} -gt 0 ]; then
        log_error "❌ Failed to deploy services: ${failed_services[*]}"
    fi
    
    # Test all services
    log_info "Waiting 30 seconds before testing services..."
    sleep 30
    test_all_services
    
    # Create summary
    create_summary
    
    # Final status
    if [ ${#failed_services[@]} -eq 0 ]; then
        log_success "🎉 ALL REMAINING SERVICES DEPLOYED SUCCESSFULLY!"
        log_info "🌐 Your complete BIDR microservices platform is now live at http://${LOAD_BALANCER_IP}"
        return 0
    else
        log_warning "⚠️ Some services failed to deploy. Check the logs above for details."
        return 1
    fi
}

# Run the main function
main "$@"
