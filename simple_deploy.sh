#!/usr/bin/env bash

set -e

# Configuration
REGISTRY="bidrnparusdevregistry2024.azurecr.io"
NAMESPACE="bidr"
LOAD_BALANCER_IP="20.164.134.31"

echo "🚀 Deploying BIDR microservices..."

# Deploy Payment Service
echo "Deploying Payment Service..."
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: payment-service
  namespace: bidr
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
      containers:
      - name: payment-service
        image: bidrnparusdevregistry2024.azurecr.io/payment-service:latest
        ports:
        - containerPort: 8000
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
      imagePullSecrets:
      - name: acr-secret
---
apiVersion: v1
kind: Service
metadata:
  name: payment-service
  namespace: bidr
  labels:
    app: payment-service
spec:
  selector:
    app: payment-service
  ports:
  - port: 8000
    targetPort: 8000
    protocol: TCP
  type: ClusterIP
EOF

# Deploy Product Service
echo "Deploying Product Service..."
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: product-service
  namespace: bidr
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
      containers:
      - name: product-service
        image: bidrnparusdevregistry2024.azurecr.io/product-service:latest
        ports:
        - containerPort: 8000
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
      imagePullSecrets:
      - name: acr-secret
---
apiVersion: v1
kind: Service
metadata:
  name: product-service
  namespace: bidr
  labels:
    app: product-service
spec:
  selector:
    app: product-service
  ports:
  - port: 8000
    targetPort: 8000
    protocol: TCP
  type: ClusterIP
EOF

# Deploy Notifications Service
echo "Deploying Notifications Service..."
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: notifications-service
  namespace: bidr
  labels:
    app: notifications-service
    service: notifications
spec:
  replicas: 2
  selector:
    matchLabels:
      app: notifications-service
  template:
    metadata:
      labels:
        app: notifications-service
        service: notifications
    spec:
      serviceAccountName: bidr-service-account
      containers:
      - name: notifications-service
        image: bidrnparusdevregistry2024.azurecr.io/notifications-service:latest
        ports:
        - containerPort: 8000
        env:
        - name: DEBUG
          value: "False"
        - name: DJANGO_SETTINGS_MODULE
          value: "notifications.settings"
        - name: SERVICE_NAME
          value: "notifications"
        - name: SECRET_KEY
          valueFrom:
            secretKeyRef:
              name: bidr-secrets
              key: DJANGO_SECRET_KEY
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: bidr-secrets
              key: NOTIFICATIONS_DATABASE_URL
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
      imagePullSecrets:
      - name: acr-secret
---
apiVersion: v1
kind: Service
metadata:
  name: notifications-service
  namespace: bidr
  labels:
    app: notifications-service
spec:
  selector:
    app: notifications-service
  ports:
  - port: 8000
    targetPort: 8000
    protocol: TCP
  type: ClusterIP
EOF

# Deploy Transactions Service
echo "Deploying Transactions Service..."
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: transactions-service
  namespace: bidr
  labels:
    app: transactions-service
    service: transactions
spec:
  replicas: 2
  selector:
    matchLabels:
      app: transactions-service
  template:
    metadata:
      labels:
        app: transactions-service
        service: transactions
    spec:
      serviceAccountName: bidr-service-account
      containers:
      - name: transactions-service
        image: bidrnparusdevregistry2024.azurecr.io/transactions-service:latest
        ports:
        - containerPort: 8000
        env:
        - name: DEBUG
          value: "False"
        - name: DJANGO_SETTINGS_MODULE
          value: "transactions_service.settings"
        - name: SERVICE_NAME
          value: "transactions"
        - name: SECRET_KEY
          valueFrom:
            secretKeyRef:
              name: bidr-secrets
              key: DJANGO_SECRET_KEY
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: bidr-secrets
              key: TRANSACTIONS_DATABASE_URL
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
      imagePullSecrets:
      - name: acr-secret
---
apiVersion: v1
kind: Service
metadata:
  name: transactions-service
  namespace: bidr
  labels:
    app: transactions-service
spec:
  selector:
    app: transactions-service
  ports:
  - port: 8000
    targetPort: 8000
    protocol: TCP
  type: ClusterIP
EOF

# Deploy Reviews Service
echo "Deploying Reviews Service..."
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: reviews-service
  namespace: bidr
  labels:
    app: reviews-service
    service: reviews
spec:
  replicas: 2
  selector:
    matchLabels:
      app: reviews-service
  template:
    metadata:
      labels:
        app: reviews-service
        service: reviews
    spec:
      serviceAccountName: bidr-service-account
      containers:
      - name: reviews-service
        image: bidrnparusdevregistry2024.azurecr.io/reviews-service:latest
        ports:
        - containerPort: 8000
        env:
        - name: DEBUG
          value: "False"
        - name: DJANGO_SETTINGS_MODULE
          value: "reviews_and_ratings.settings"
        - name: SERVICE_NAME
          value: "reviews"
        - name: SECRET_KEY
          valueFrom:
            secretKeyRef:
              name: bidr-secrets
              key: DJANGO_SECRET_KEY
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: bidr-secrets
              key: REVIEWS_DATABASE_URL
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
      imagePullSecrets:
      - name: acr-secret
---
apiVersion: v1
kind: Service
metadata:
  name: reviews-service
  namespace: bidr
  labels:
    app: reviews-service
spec:
  selector:
    app: reviews-service
  ports:
  - port: 8000
    targetPort: 8000
    protocol: TCP
  type: ClusterIP
EOF

# Deploy Resolution Service
echo "Deploying Resolution Service..."
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: resolution-service
  namespace: bidr
  labels:
    app: resolution-service
    service: resolution
spec:
  replicas: 2
  selector:
    matchLabels:
      app: resolution-service
  template:
    metadata:
      labels:
        app: resolution-service
        service: resolution
    spec:
      serviceAccountName: bidr-service-account
      containers:
      - name: resolution-service
        image: bidrnparusdevregistry2024.azurecr.io/resolution-service:latest
        ports:
        - containerPort: 8000
        env:
        - name: DEBUG
          value: "False"
        - name: DJANGO_SETTINGS_MODULE
          value: "resolution_service.settings"
        - name: SERVICE_NAME
          value: "resolution"
        - name: SECRET_KEY
          valueFrom:
            secretKeyRef:
              name: bidr-secrets
              key: DJANGO_SECRET_KEY
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: bidr-secrets
              key: RESOLUTION_DATABASE_URL
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
      imagePullSecrets:
      - name: acr-secret
---
apiVersion: v1
kind: Service
metadata:
  name: resolution-service
  namespace: bidr
  labels:
    app: resolution-service
spec:
  selector:
    app: resolution-service
  ports:
  - port: 8000
    targetPort: 8000
    protocol: TCP
  type: ClusterIP
EOF

# Now add services to load balancer
echo "Adding services to load balancer..."

# Add payment service to load balancer
kubectl patch service bidr-load-balancer -n bidr --type='json' -p='[
    {
        "op": "add",
        "path": "/spec/ports/-",
        "value": {
            "name": "payment",
            "port": 8003,
            "targetPort": 8000,
            "protocol": "TCP"
        }
    }
]' 2>/dev/null || echo "Payment service port may already exist"

# Add product service to load balancer
kubectl patch service bidr-load-balancer -n bidr --type='json' -p='[
    {
        "op": "add",
        "path": "/spec/ports/-",
        "value": {
            "name": "product",
            "port": 8004,
            "targetPort": 8000,
            "protocol": "TCP"
        }
    }
]' 2>/dev/null || echo "Product service port may already exist"

# Add resolution service to load balancer
kubectl patch service bidr-load-balancer -n bidr --type='json' -p='[
    {
        "op": "add",
        "path": "/spec/ports/-",
        "value": {
            "name": "resolution",
            "port": 8005,
            "targetPort": 8000,
            "protocol": "TCP"
        }
    }
]' 2>/dev/null || echo "Resolution service port may already exist"

# Add notifications service to load balancer
kubectl patch service bidr-load-balancer -n bidr --type='json' -p='[
    {
        "op": "add",
        "path": "/spec/ports/-",
        "value": {
            "name": "notifications",
            "port": 8006,
            "targetPort": 8000,
            "protocol": "TCP"
        }
    }
]' 2>/dev/null || echo "Notifications service port may already exist"

# Add transactions service to load balancer
kubectl patch service bidr-load-balancer -n bidr --type='json' -p='[
    {
        "op": "add",
        "path": "/spec/ports/-",
        "value": {
            "name": "transactions",
            "port": 8007,
            "targetPort": 8000,
            "protocol": "TCP"
        }
    }
]' 2>/dev/null || echo "Transactions service port may already exist"

# Add reviews service to load balancer
kubectl patch service bidr-load-balancer -n bidr --type='json' -p='[
    {
        "op": "add",
        "path": "/spec/ports/-",
        "value": {
            "name": "reviews",
            "port": 8008,
            "targetPort": 8000,
            "protocol": "TCP"
        }
    }
]' 2>/dev/null || echo "Reviews service port may already exist"

echo "Waiting for deployments to be ready..."
kubectl rollout status deployment/payment-service -n bidr --timeout=300s
kubectl rollout status deployment/product-service -n bidr --timeout=300s
kubectl rollout status deployment/notifications-service -n bidr --timeout=300s
kubectl rollout status deployment/transactions-service -n bidr --timeout=300s
kubectl rollout status deployment/reviews-service -n bidr --timeout=300s
kubectl rollout status deployment/resolution-service -n bidr --timeout=300s

echo ""
echo "🎉 All services deployed!"
echo ""
echo "Testing services..."

# Test services
services=("8001:Authentication" "8002:Chat" "8003:Payment" "8004:Product" "8005:Resolution" "8006:Notifications" "8007:Transactions" "8008:Reviews")

for service_config in "${services[@]}"; do
    IFS=':' read -r port name <<< "$service_config"
    echo "Testing $name service on port $port..."
    response=$(curl -s -o /dev/null -w "%{http_code}" "http://${LOAD_BALANCER_IP}:${port}/" 2>/dev/null || echo "000")
    if [ "$response" = "200" ] || [ "$response" = "302" ]; then
        echo "✅ $name service is responding (HTTP $response)"
    else
        echo "❌ $name service returned HTTP $response"
    fi
done

echo ""
echo "🚀 BIDR Microservices Deployment Complete!"
echo ""
echo "Service URLs:"
echo "• Authentication: http://${LOAD_BALANCER_IP}:8001/"
echo "• Chat: http://${LOAD_BALANCER_IP}:8002/"
echo "• Payment: http://${LOAD_BALANCER_IP}:8003/"
echo "• Product: http://${LOAD_BALANCER_IP}:8004/"
echo "• Resolution: http://${LOAD_BALANCER_IP}:8005/"
echo "• Notifications: http://${LOAD_BALANCER_IP}:8006/"
echo "• Transactions: http://${LOAD_BALANCER_IP}:8007/"
echo "• Reviews: http://${LOAD_BALANCER_IP}:8008/"
echo ""
echo "Admin credentials (all services):"
echo "• Username: admin"
echo "• Email: admin@bidr.local" 
echo "• Password: bidr_admin_2024"
