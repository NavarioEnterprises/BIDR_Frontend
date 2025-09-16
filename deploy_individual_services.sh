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
NC='\033[0m' # No Color

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Deploy chat service
deploy_chat_service() {
    log_info "🚀 Deploying chat service..."
    
    # Create deployment YAML
    cat > chat-deployment.yaml <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: chat-service
  namespace: bidr
  labels:
    app: chat-service
    service: chat
spec:
  replicas: 2
  selector:
    matchLabels:
      app: chat-service
  template:
    metadata:
      labels:
        app: chat-service
        service: chat
    spec:
      serviceAccountName: bidr-service-account
      containers:
      - name: chat-service
        image: ${REGISTRY}/chat-service:latest
        ports:
        - containerPort: 8000
        env:
        - name: DEBUG
          value: "False"
        - name: DJANGO_SETTINGS_MODULE
          value: "chat_service.settings"
        - name: SERVICE_NAME
          value: "chat"
        - name: SECRET_KEY
          valueFrom:
            secretKeyRef:
              name: bidr-secrets
              key: DJANGO_SECRET_KEY
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: bidr-secrets
              key: CHAT_DATABASE_URL
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
  name: chat-service
  namespace: bidr
  labels:
    app: chat-service
spec:
  selector:
    app: chat-service
  ports:
  - port: 8000
    targetPort: 8000
    protocol: TCP
  type: ClusterIP
EOF

    kubectl apply -f chat-deployment.yaml
    log_success "Created chat service deployment"
    
    # Add to load balancer
    kubectl patch service bidr-load-balancer -n bidr --type='json' -p='[
        {
            "op": "add",
            "path": "/spec/ports/-",
            "value": {
                "name": "chat",
                "port": 8002,
                "targetPort": 8000,
                "protocol": "TCP"
            }
        }
    ]'
    log_success "Added chat to load balancer on port 8002"
    
    # Wait for deployment
    kubectl rollout status deployment/chat-service -n bidr --timeout=600s
    if [[ $? -eq 0 ]]; then
        log_success "Chat service deployed successfully!"
    else
        log_error "Chat service deployment failed"
        return 1
    fi
}

# Test if services are working
test_services() {
    log_info "Testing deployed services..."
    
    services=(
        "8001:auth"
        "8002:chat"
    )
    
    for service_config in "${services[@]}"; do
        IFS=':' read -r port name <<< "$service_config"
        log_info "Testing $name service on port $port..."
        response=$(curl -s -o /dev/null -w "%{http_code}" "http://${LOAD_BALANCER_IP}:${port}/" || echo "000")
        if [[ "$response" == "200" || "$response" == "302" ]]; then
            log_success "$name service is responding (HTTP $response)"
        else
            log_error "$name service returned HTTP $response"
        fi
    done
}

# Main function
main() {
    log_info "🚀 Deploying BIDR microservices to Azure AKS..."
    
    # Deploy chat service first
    deploy_chat_service
    
    # Test services
    sleep 30  # Wait for services to be ready
    test_services
    
    log_success "🎉 Deployment completed!"
    log_info "🌐 Services available at:"
    log_info "   • Authentication: http://${LOAD_BALANCER_IP}:8001/"
    log_info "   • Chat: http://${LOAD_BALANCER_IP}:8002/"
}

main "$@"
