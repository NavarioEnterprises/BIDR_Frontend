#!/usr/bin/env bash

echo "🚀 Deploying working BIDR microservices..."

# Deploy Notifications Service (simple configuration)
echo "Deploying Notifications Service..."
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: notifications-service
  namespace: bidr
  labels:
    app: notifications-service
spec:
  replicas: 1
  selector:
    matchLabels:
      app: notifications-service
  template:
    metadata:
      labels:
        app: notifications-service
    spec:
      containers:
      - name: notifications-service
        image: bidrnparusdevregistry2024.azurecr.io/notifications-service:latest
        ports:
        - containerPort: 8000
        env:
        - name: DEBUG
          value: "True"
        - name: DJANGO_SETTINGS_MODULE
          value: "notifications.settings"
        - name: SECRET_KEY
          value: "django-insecure-temp-key-for-dev-12345"
        - name: ALLOWED_HOSTS
          value: "*"
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "200m"
        livenessProbe:
          httpGet:
            path: /
            port: 8000
          initialDelaySeconds: 120
          periodSeconds: 30
          failureThreshold: 5
        readinessProbe:
          httpGet:
            path: /
            port: 8000
          initialDelaySeconds: 60
          periodSeconds: 15
          failureThreshold: 5
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
  type: LoadBalancer
  selector:
    app: notifications-service
  ports:
  - port: 8006
    targetPort: 8000
    protocol: TCP
    name: http
EOF

# Deploy Payment Service (simple configuration)
echo "Deploying Payment Service..."
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: payment-service
  namespace: bidr
  labels:
    app: payment-service
spec:
  replicas: 1
  selector:
    matchLabels:
      app: payment-service
  template:
    metadata:
      labels:
        app: payment-service
    spec:
      containers:
      - name: payment-service
        image: bidrnparusdevregistry2024.azurecr.io/payment-service:latest
        ports:
        - containerPort: 8000
        env:
        - name: DEBUG
          value: "True"
        - name: DJANGO_SETTINGS_MODULE
          value: "payment_service.settings"
        - name: SECRET_KEY
          value: "django-insecure-temp-key-for-dev-12345"
        - name: ALLOWED_HOSTS
          value: "*"
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "200m"
        livenessProbe:
          httpGet:
            path: /
            port: 8000
          initialDelaySeconds: 120
          periodSeconds: 30
          failureThreshold: 5
        readinessProbe:
          httpGet:
            path: /
            port: 8000
          initialDelaySeconds: 60
          periodSeconds: 15
          failureThreshold: 5
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
  type: LoadBalancer
  selector:
    app: payment-service
  ports:
  - port: 8003
    targetPort: 8000
    protocol: TCP
    name: http
EOF

echo "⏳ Waiting for deployments to be ready..."
sleep 60

echo "📊 Checking deployment status..."
kubectl get pods -n bidr
kubectl get services -n bidr

echo ""
echo "✅ Working services deployed with simplified configurations!"
echo "🔧 These services now run in DEBUG mode without complex dependencies"
echo "📱 They should be accessible once LoadBalancer IPs are assigned"
