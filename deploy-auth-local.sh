#!/bin/bash

# Deploy Local Authentication Service to Kubernetes
# This script builds and deploys your local authentication service code

set -e  # Exit on any error

# Configuration
SERVICE_NAME="auth-service"
NAMESPACE="bidr"
IMAGE_NAME="local-auth-service"
IMAGE_TAG="$(date +%Y%m%d-%H%M%S)-$(git rev-parse --short HEAD 2>/dev/null || echo 'local')"
FULL_IMAGE_NAME="${IMAGE_NAME}:${IMAGE_TAG}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Deploying Local Authentication Service${NC}"
echo "================================================="

# Function to check command exists
check_command() {
    if ! command -v $1 &> /dev/null; then
        echo -e "${RED}❌ $1 is not installed or not in PATH${NC}"
        exit 1
    fi
}

# Check required tools
echo -e "${YELLOW}🔍 Checking required tools...${NC}"
check_command docker
check_command kubectl

# Check if we're in the right directory
if [ ! -f "authentication_service/Dockerfile" ]; then
    echo -e "${RED}❌ authentication_service/Dockerfile not found. Please run this script from the BIDR_Backend directory.${NC}"
    exit 1
fi

# Build the Docker image
echo -e "${YELLOW}🔨 Building Docker image...${NC}"
cd authentication_service
docker build -t ${FULL_IMAGE_NAME} .
cd ..

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Docker image built successfully: ${FULL_IMAGE_NAME}${NC}"
else
    echo -e "${RED}❌ Docker image build failed${NC}"
    exit 1
fi

# Create a temporary deployment file with the new image
echo -e "${YELLOW}📝 Creating deployment configuration...${NC}"
TEMP_DEPLOYMENT="/tmp/auth-service-local-$(date +%s).yaml"

cat > ${TEMP_DEPLOYMENT} << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${SERVICE_NAME}
  namespace: ${NAMESPACE}
  labels:
    app: ${SERVICE_NAME}
    service: auth
    version: local
spec:
  replicas: 1
  selector:
    matchLabels:
      app: ${SERVICE_NAME}
  template:
    metadata:
      labels:
        app: ${SERVICE_NAME}
        service: auth
        version: local
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "8000"
        prometheus.io/path: "/metrics"
    spec:
      serviceAccountName: bidr-service-account
      containers:
      - name: ${SERVICE_NAME}
        image: ${FULL_IMAGE_NAME}
        imagePullPolicy: Never  # Use local image
        ports:
        - containerPort: 8000
        env:
        - name: DEBUG
          value: "False"
        - name: DJANGO_SETTINGS_MODULE
          value: "authentication_service.settings"
        - name: SERVICE_NAME
          value: "auth"
        - name: SECRET_KEY
          valueFrom:
            secretKeyRef:
              name: bidr-secrets
              key: DJANGO_SECRET_KEY
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: bidr-secrets
              key: AUTH_DATABASE_URL
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
            cpu: "200m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /health/
            port: 8000
          initialDelaySeconds: 60
          periodSeconds: 30
          failureThreshold: 3
        readinessProbe:
          httpGet:
            path: /health/
            port: 8000
          initialDelaySeconds: 30
          periodSeconds: 15
          failureThreshold: 3
---
apiVersion: v1
kind: Service
metadata:
  name: ${SERVICE_NAME}
  namespace: ${NAMESPACE}
  labels:
    app: ${SERVICE_NAME}
spec:
  type: ClusterIP
  selector:
    app: ${SERVICE_NAME}
  ports:
  - port: 8001
    targetPort: 8000
    protocol: TCP
    name: http
EOF

# Deploy to Kubernetes
echo -e "${YELLOW}🚢 Deploying to Kubernetes...${NC}"

# Check if namespace exists
if ! kubectl get namespace ${NAMESPACE} &> /dev/null; then
    echo -e "${YELLOW}📦 Creating namespace ${NAMESPACE}...${NC}"
    kubectl create namespace ${NAMESPACE}
fi

# Load Docker image into kind/minikube if needed
if docker ps --format "table {{.Names}}" | grep -q "kind\|minikube"; then
    echo -e "${YELLOW}🐳 Loading image into local Kubernetes cluster...${NC}"
    if command -v kind &> /dev/null && kind get clusters 2>/dev/null | grep -q "."; then
        kind load docker-image ${FULL_IMAGE_NAME}
    elif command -v minikube &> /dev/null && minikube status &> /dev/null; then
        minikube image load ${FULL_IMAGE_NAME}
    fi
fi

# Apply the deployment
kubectl apply -f ${TEMP_DEPLOYMENT}

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Deployment applied successfully${NC}"
else
    echo -e "${RED}❌ Deployment failed${NC}"
    exit 1
fi

# Wait for deployment to be ready
echo -e "${YELLOW}⏳ Waiting for deployment to be ready...${NC}"
kubectl wait --for=condition=available --timeout=300s deployment/${SERVICE_NAME} -n ${NAMESPACE}

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Deployment is ready!${NC}"
else
    echo -e "${RED}❌ Deployment failed to become ready${NC}"
    echo -e "${YELLOW}📋 Checking pod status...${NC}"
    kubectl get pods -n ${NAMESPACE} -l app=${SERVICE_NAME}
    kubectl describe pods -n ${NAMESPACE} -l app=${SERVICE_NAME}
    exit 1
fi

# Clean up temp file
rm -f ${TEMP_DEPLOYMENT}

# Show deployment status
echo -e "${BLUE}📊 Deployment Status:${NC}"
kubectl get pods -n ${NAMESPACE} -l app=${SERVICE_NAME}
echo ""
kubectl get services -n ${NAMESPACE} -l app=${SERVICE_NAME}

# Test the service
echo ""
echo -e "${YELLOW}🧪 Testing the service...${NC}"
SERVICE_IP=$(kubectl get service ${SERVICE_NAME} -n ${NAMESPACE} -o jsonpath='{.spec.clusterIP}')
echo "Service ClusterIP: ${SERVICE_IP}:8001"

# Test internal connectivity
kubectl run test-auth --image=curlimages/curl -i --rm --restart=Never -- curl -m 10 http://${SERVICE_NAME}.${NAMESPACE}.svc.cluster.local:8001/health/ 2>/dev/null && echo -e "${GREEN}✅ Internal service connectivity: OK${NC}" || echo -e "${RED}❌ Internal service connectivity: FAILED${NC}"

# Get load balancer info
echo ""
echo -e "${BLUE}🌐 Load Balancer Access:${NC}"
LB_IP=$(kubectl get service nginx-proxy -n ${NAMESPACE} -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "Not available")
if [ "$LB_IP" != "Not available" ] && [ "$LB_IP" != "" ]; then
    echo "Load Balancer IP: ${LB_IP}"
    echo "Auth Service URL: http://${LB_IP}/auth/"
    echo "Admin Panel URL: http://${LB_IP}/auth/admin/"
    
    # Test load balancer connectivity
    echo -e "${YELLOW}🧪 Testing load balancer connectivity...${NC}"
    curl -m 10 -s http://${LB_IP}/auth/ > /dev/null && echo -e "${GREEN}✅ Load balancer connectivity: OK${NC}" || echo -e "${RED}❌ Load balancer connectivity: FAILED${NC}"
else
    echo "Load balancer IP not available yet"
fi

echo ""
echo -e "${GREEN}🎉 Local Authentication Service Deployment Complete!${NC}"
echo "================================================="
echo -e "Image: ${FULL_IMAGE_NAME}"
echo -e "Namespace: ${NAMESPACE}"
echo -e "Service: ${SERVICE_NAME}"

# Show logs if requested
read -p "Would you like to see the service logs? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}📋 Service logs:${NC}"
    kubectl logs -n ${NAMESPACE} -l app=${SERVICE_NAME} --tail=50
fi