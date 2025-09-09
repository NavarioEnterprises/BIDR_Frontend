#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
ACR_NAME="bidrnparusdevregistry2024"
ACR_LOGIN_SERVER="${ACR_NAME}.azurecr.io"
AKS_CLUSTER="BIDR-dev-aks-cluster"
RESOURCE_GROUP="bidr-dev-k8s"
NAMESPACE="bidr"

# Services to deploy
SERVICES=(
    "authentication_service:auth-service:auth"
    "chat_service:chat-service:chat"
    "payment_service:payment-service:payment"
    "product_management_service:product-service:product"
    "notifications_service:notifications-service:notifications"
    "transactions_service:transactions-service:transactions"
    "resolution_service:resolution-service:resolution"
    "reviews_and_ratings:reviews-service:reviews"
)

echo -e "${BLUE}🚀 Starting BIDR Microservices Deployment${NC}"
echo -e "${BLUE}==============================================${NC}"
echo -e "ACR: ${ACR_LOGIN_SERVER}"
echo -e "AKS: ${AKS_CLUSTER}"
echo -e "Namespace: ${NAMESPACE}"
echo ""

# Function to print colored output
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️ $1${NC}"
}

# Go to project root
cd "$(dirname "$0")/.."

# Step 1: Login to ACR
print_info "Logging into Azure Container Registry..."
az acr login --name $ACR_NAME
print_status "Logged into ACR successfully"

# Step 2: Create namespace if it doesn't exist
print_info "Creating namespace..."
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -
print_status "Namespace created/verified"

# Step 3: Create ACR secret for pulling images
print_info "Creating ACR secret..."
kubectl delete secret acr-secret -n $NAMESPACE --ignore-not-found
kubectl create secret docker-registry acr-secret \
    --docker-server=${ACR_LOGIN_SERVER} \
    --docker-username=$(az acr credential show --name $ACR_NAME --query username -o tsv) \
    --docker-password=$(az acr credential show --name $ACR_NAME --query passwords[0].value -o tsv) \
    --namespace=$NAMESPACE
print_status "ACR secret created"

# Step 4: Create Azure Key Vault secrets in Kubernetes
print_info "Creating Kubernetes secrets from Azure Key Vault..."

# Get secrets from Key Vault
DJANGO_SECRET=$(az keyvault secret show --vault-name bidr-nparus-dev-vault --name django-secret-key --query value -o tsv)
DATABASE_PASSWORD=$(az keyvault secret show --vault-name bidr-nparus-dev-vault --name database-password --query value -o tsv)
DATABASE_USER=$(az keyvault secret show --vault-name bidr-nparus-dev-vault --name database-user --query value -o tsv)
REDIS_PASSWORD=$(az keyvault secret show --vault-name bidr-nparus-dev-vault --name redis-password --query value -o tsv)
EMAIL_HOST_USER=$(az keyvault secret show --vault-name bidr-nparus-dev-vault --name email-host-user --query value -o tsv)
EMAIL_HOST_PASSWORD=$(az keyvault secret show --vault-name bidr-nparus-dev-vault --name email-host-password --query value -o tsv)

# Database connection strings
AUTH_DB_URL="postgresql://${DATABASE_USER}:${DATABASE_PASSWORD}@bidr-dev-aks-cluster-psql-server.postgres.database.azure.com:5432/auth_db?sslmode=require"
CHAT_DB_URL="postgresql://${DATABASE_USER}:${DATABASE_PASSWORD}@bidr-dev-aks-cluster-psql-server.postgres.database.azure.com:5432/chat_db?sslmode=require"
PAYMENT_DB_URL="postgresql://${DATABASE_USER}:${DATABASE_PASSWORD}@bidr-dev-aks-cluster-psql-server.postgres.database.azure.com:5432/payment_db?sslmode=require"
PRODUCT_DB_URL="postgresql://${DATABASE_USER}:${DATABASE_PASSWORD}@bidr-dev-aks-cluster-psql-server.postgres.database.azure.com:5432/product_db?sslmode=require"
NOTIFICATIONS_DB_URL="postgresql://${DATABASE_USER}:${DATABASE_PASSWORD}@bidr-dev-aks-cluster-psql-server.postgres.database.azure.com:5432/notifications_db?sslmode=require"
TRANSACTIONS_DB_URL="postgresql://${DATABASE_USER}:${DATABASE_PASSWORD}@bidr-dev-aks-cluster-psql-server.postgres.database.azure.com:5432/transactions_db?sslmode=require"
RESOLUTION_DB_URL="postgresql://${DATABASE_USER}:${DATABASE_PASSWORD}@bidr-dev-aks-cluster-psql-server.postgres.database.azure.com:5432/resolution_db?sslmode=require"
REVIEWS_DB_URL="postgresql://${DATABASE_USER}:${DATABASE_PASSWORD}@bidr-dev-aks-cluster-psql-server.postgres.database.azure.com:5432/reviews_db?sslmode=require"
REDIS_URL="rediss://:${REDIS_PASSWORD}@BIDR-dev-aks-cluster-redis.redis.cache.windows.net:6380"

# Create secret
kubectl delete secret bidr-secrets -n $NAMESPACE --ignore-not-found
kubectl create secret generic bidr-secrets -n $NAMESPACE \
    --from-literal=DJANGO_SECRET_KEY="$DJANGO_SECRET" \
    --from-literal=AUTH_DATABASE_URL="$AUTH_DB_URL" \
    --from-literal=CHAT_DATABASE_URL="$CHAT_DB_URL" \
    --from-literal=PAYMENT_DATABASE_URL="$PAYMENT_DB_URL" \
    --from-literal=PRODUCT_DATABASE_URL="$PRODUCT_DB_URL" \
    --from-literal=NOTIFICATIONS_DATABASE_URL="$NOTIFICATIONS_DB_URL" \
    --from-literal=TRANSACTIONS_DATABASE_URL="$TRANSACTIONS_DB_URL" \
    --from-literal=RESOLUTION_DATABASE_URL="$RESOLUTION_DB_URL" \
    --from-literal=REVIEWS_DATABASE_URL="$REVIEWS_DB_URL" \
    --from-literal=REDIS_URL="$REDIS_URL" \
    --from-literal=EMAIL_HOST_USER="$EMAIL_HOST_USER" \
    --from-literal=EMAIL_HOST_PASSWORD="$EMAIL_HOST_PASSWORD"

print_status "Kubernetes secrets created"

# Step 5: Build and push Docker images
print_info "Building and pushing Docker images..."

for service_config in "${SERVICES[@]}"; do
    IFS=':' read -r service_dir image_name service_key <<< "$service_config"
    
    print_info "Building $image_name from $service_dir..."
    
    if [ ! -d "$service_dir" ]; then
        print_error "Directory $service_dir does not exist, skipping..."
        continue
    fi
    
    cd "$service_dir"
    
    # Build the image
    docker build -t ${ACR_LOGIN_SERVER}/$image_name:latest . || {
        print_error "Failed to build $image_name"
        cd ..
        continue
    }
    
    # Push the image
    docker push ${ACR_LOGIN_SERVER}/$image_name:latest || {
        print_error "Failed to push $image_name"
        cd ..
        continue
    }
    
    print_status "Built and pushed $image_name"
    cd ..
done

# Step 6: Deploy services to Kubernetes
print_info "Deploying services to Kubernetes..."

# Create updated deployment YAML
cat > deployment/bidr-services.yaml << EOF
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: bidr-service-account
  namespace: ${NAMESPACE}
---
# Authentication Service
apiVersion: apps/v1
kind: Deployment
metadata:
  name: auth-service
  namespace: ${NAMESPACE}
  labels:
    app: auth-service
    service: authentication
spec:
  replicas: 2
  selector:
    matchLabels:
      app: auth-service
  template:
    metadata:
      labels:
        app: auth-service
        service: authentication
    spec:
      serviceAccountName: bidr-service-account
      imagePullSecrets:
      - name: acr-secret
      containers:
      - name: auth-service
        image: ${ACR_LOGIN_SERVER}/auth-service:latest
        ports:
        - containerPort: 8000
          name: http
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
        readinessProbe:
          httpGet:
            path: /
            port: 8000
          initialDelaySeconds: 30
          periodSeconds: 10
---
apiVersion: v1
kind: Service
metadata:
  name: auth-service
  namespace: ${NAMESPACE}
  labels:
    app: auth-service
spec:
  selector:
    app: auth-service
  ports:
  - port: 8000
    targetPort: 8000
    name: http
  type: ClusterIP
---
# Chat Service
apiVersion: apps/v1
kind: Deployment
metadata:
  name: chat-service
  namespace: ${NAMESPACE}
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
      imagePullSecrets:
      - name: acr-secret
      containers:
      - name: chat-service
        image: ${ACR_LOGIN_SERVER}/chat-service:latest
        ports:
        - containerPort: 8000
          name: http
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
        readinessProbe:
          httpGet:
            path: /
            port: 8000
          initialDelaySeconds: 30
          periodSeconds: 10
---
apiVersion: v1
kind: Service
metadata:
  name: chat-service
  namespace: ${NAMESPACE}
  labels:
    app: chat-service
spec:
  selector:
    app: chat-service
  ports:
  - port: 8000
    targetPort: 8000
    name: http
  type: ClusterIP
---
# Payment Service
apiVersion: apps/v1
kind: Deployment
metadata:
  name: payment-service
  namespace: ${NAMESPACE}
  labels:
    app: payment-service
    service: payment
spec:
  replicas: 2
  selector:
    matchLabels:
      app: payment-service
  template:
    metadata:
      labels:
        app: payment-service
        service: payment
    spec:
      serviceAccountName: bidr-service-account
      imagePullSecrets:
      - name: acr-secret
      containers:
      - name: payment-service
        image: ${ACR_LOGIN_SERVER}/payment-service:latest
        ports:
        - containerPort: 8000
          name: http
        env:
        - name: DEBUG
          value: "False"
        - name: DJANGO_SETTINGS_MODULE
          value: "payment_service.settings"
        - name: SERVICE_NAME
          value: "payment"
        - name: SECRET_KEY
          valueFrom:
            secretKeyRef:
              name: bidr-secrets
              key: DJANGO_SECRET_KEY
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: bidr-secrets
              key: PAYMENT_DATABASE_URL
        - name: REDIS_URL
          valueFrom:
            secretKeyRef:
              name: bidr-secrets
              key: REDIS_URL
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
        readinessProbe:
          httpGet:
            path: /
            port: 8000
          initialDelaySeconds: 30
          periodSeconds: 10
---
apiVersion: v1
kind: Service
metadata:
  name: payment-service
  namespace: ${NAMESPACE}
  labels:
    app: payment-service
spec:
  selector:
    app: payment-service
  ports:
  - port: 8000
    targetPort: 8000
    name: http
  type: ClusterIP
---
# Product Service
apiVersion: apps/v1
kind: Deployment
metadata:
  name: product-service
  namespace: ${NAMESPACE}
  labels:
    app: product-service
    service: product
spec:
  replicas: 2
  selector:
    matchLabels:
      app: product-service
  template:
    metadata:
      labels:
        app: product-service
        service: product
    spec:
      serviceAccountName: bidr-service-account
      imagePullSecrets:
      - name: acr-secret
      containers:
      - name: product-service
        image: ${ACR_LOGIN_SERVER}/product-service:latest
        ports:
        - containerPort: 8000
          name: http
        env:
        - name: DEBUG
          value: "False"
        - name: DJANGO_SETTINGS_MODULE
          value: "product_management_service.settings"
        - name: SERVICE_NAME
          value: "product"
        - name: SECRET_KEY
          valueFrom:
            secretKeyRef:
              name: bidr-secrets
              key: DJANGO_SECRET_KEY
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: bidr-secrets
              key: PRODUCT_DATABASE_URL
        - name: REDIS_URL
          valueFrom:
            secretKeyRef:
              name: bidr-secrets
              key: REDIS_URL
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
        readinessProbe:
          httpGet:
            path: /
            port: 8000
          initialDelaySeconds: 30
          periodSeconds: 10
---
apiVersion: v1
kind: Service
metadata:
  name: product-service
  namespace: ${NAMESPACE}
  labels:
    app: product-service
spec:
  selector:
    app: product-service
  ports:
  - port: 8000
    targetPort: 8000
    name: http
  type: ClusterIP
---
# Load Balancer Service for External Access
apiVersion: v1
kind: Service
metadata:
  name: bidr-load-balancer
  namespace: ${NAMESPACE}
  labels:
    app: bidr-load-balancer
spec:
  type: LoadBalancer
  selector:
    service: authentication  # Will route to auth service by default
  ports:
  - name: auth
    port: 8001
    targetPort: 8000
    protocol: TCP
  - name: chat
    port: 8002
    targetPort: 8000
    protocol: TCP
  - name: payment
    port: 8003
    targetPort: 8000
    protocol: TCP
  - name: product
    port: 8004
    targetPort: 8000
    protocol: TCP
  loadBalancerSourceRanges:
  - 0.0.0.0/0
EOF

# Apply the deployment
kubectl apply -f deployment/bidr-services.yaml

print_status "Services deployed to Kubernetes"

# Step 7: Wait for deployments to be ready
print_info "Waiting for deployments to be ready..."

services=("auth-service" "chat-service" "payment-service" "product-service")
for service in "${services[@]}"; do
    kubectl wait --for=condition=available --timeout=300s deployment/$service -n $NAMESPACE || {
        print_warning "Timeout waiting for $service to be ready"
    }
done

# Step 8: Get service URLs
print_info "Getting service URLs..."

# Wait for load balancer IP
echo "Waiting for load balancer IP..."
sleep 30

EXTERNAL_IP=""
while [ -z "$EXTERNAL_IP" ]; do
    echo "Waiting for external IP..."
    EXTERNAL_IP=$(kubectl get service bidr-load-balancer -n $NAMESPACE --template="{{range .status.loadBalancer.ingress}}{{.ip}}{{end}}")
    [ -z "$EXTERNAL_IP" ] && sleep 10
done

print_status "External IP obtained: $EXTERNAL_IP"

# Create service URLs file
cat > deployment/BIDR_Service_URLs_and_Credentials.txt << EOF
===============================================================================
                    BIDR MICROSERVICES - DEPLOYMENT COMPLETE
===============================================================================
Deployment Date: $(date)
Environment: Development
Kubernetes Cluster: ${AKS_CLUSTER}
Namespace: ${NAMESPACE}
External IP: ${EXTERNAL_IP}

SERVICE URLS
===============================================================================
🔐 Authentication Service
URL: http://${EXTERNAL_IP}:8001/
Admin URL: http://${EXTERNAL_IP}:8001/admin/
Health Check: http://${EXTERNAL_IP}:8001/health/
API Endpoint: http://${EXTERNAL_IP}:8001/api/v1/

🔐 Chat Service  
URL: http://${EXTERNAL_IP}:8002/
Admin URL: http://${EXTERNAL_IP}:8002/admin/
Health Check: http://${EXTERNAL_IP}:8002/health/
API Endpoint: http://${EXTERNAL_IP}:8002/api/v1/

🔐 Payment Service
URL: http://${EXTERNAL_IP}:8003/
Admin URL: http://${EXTERNAL_IP}:8003/admin/
Health Check: http://${EXTERNAL_IP}:8003/health/
API Endpoint: http://${EXTERNAL_IP}:8003/api/v1/

🔐 Product Service
URL: http://${EXTERNAL_IP}:8004/
Admin URL: http://${EXTERNAL_IP}:8004/admin/
Health Check: http://${EXTERNAL_IP}:8004/health/
API Endpoint: http://${EXTERNAL_IP}:8004/api/v1/

ADMIN CREDENTIALS
===============================================================================
🔐 AUTH SERVICE ADMIN
------------------------------
Username: auth_admin
Password: Tc_tYOQZt)>84A3M
Email: auth.admin@bidr.co.za
Login URL: http://${EXTERNAL_IP}:8001/admin/

🔐 CHAT SERVICE ADMIN
------------------------------
Username: chat_admin
Password: $$:_yCg}6pSOcH*u
Email: chat.admin@bidr.co.za
Login URL: http://${EXTERNAL_IP}:8002/admin/

🔐 PAYMENT SERVICE ADMIN
------------------------------
Username: payment_admin
Password: qF{OK_*B>Id!PuB}
Email: payment.admin@bidr.co.za
Login URL: http://${EXTERNAL_IP}:8003/admin/

🔐 PRODUCT SERVICE ADMIN
------------------------------
Username: product_admin
Password: d_<!?8zm0Pv?nbA9
Email: product.admin@bidr.co.za
Login URL: http://${EXTERNAL_IP}:8004/admin/

KUBERNETES COMMANDS
===============================================================================
# View all pods
kubectl get pods -n ${NAMESPACE}

# View services
kubectl get services -n ${NAMESPACE}

# Check logs for a specific service
kubectl logs -f deployment/auth-service -n ${NAMESPACE}
kubectl logs -f deployment/chat-service -n ${NAMESPACE}
kubectl logs -f deployment/payment-service -n ${NAMESPACE}
kubectl logs -f deployment/product-service -n ${NAMESPACE}

# Scale a service
kubectl scale deployment auth-service --replicas=3 -n ${NAMESPACE}

# Restart a deployment
kubectl rollout restart deployment/auth-service -n ${NAMESPACE}

DATABASE INFORMATION
===============================================================================
Host: bidr-dev-aks-cluster-psql-server.postgres.database.azure.com
Port: 5432
Master User: bidruser
Databases: auth_db, chat_db, payment_db, product_db, notifications_db, transactions_db, resolution_db, reviews_db

Redis Cache: BIDR-dev-aks-cluster-redis.redis.cache.windows.net:6380

NEXT STEPS
===============================================================================
1. Test the service endpoints above
2. Create superusers using Django admin interface
3. Configure domain name and SSL certificates
4. Set up monitoring and logging
5. Configure CI/CD pipelines

SECURITY NOTES
===============================================================================
⚠️  Important Security Considerations:
- Change default passwords after initial setup
- Configure proper SSL/TLS certificates
- Set up proper firewall rules
- Enable monitoring and alerting
- Regularly update and patch services

===============================================================================
                              END OF DOCUMENT
===============================================================================
EOF

print_status "Service URLs and credentials saved to deployment/BIDR_Service_URLs_and_Credentials.txt"

echo ""
echo -e "${GREEN}🎉 DEPLOYMENT COMPLETE! 🎉${NC}"
echo -e "${GREEN}================================${NC}"
echo -e "External IP: ${EXTERNAL_IP}"
echo -e "Services deployed: auth, chat, payment, product"
echo -e "Check the deployment/BIDR_Service_URLs_and_Credentials.txt file for complete details"
echo ""
echo -e "${BLUE}Test your services:${NC}"
echo -e "curl http://${EXTERNAL_IP}:8001/health/"
echo -e "curl http://${EXTERNAL_IP}:8002/health/"
echo -e "curl http://${EXTERNAL_IP}:8003/health/"
echo -e "curl http://${EXTERNAL_IP}:8004/health/"

