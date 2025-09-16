#!/bin/bash

# Update services to use PostgreSQL

echo "Updating services to use PostgreSQL..."

# Create patch files for all services
cat > k8s/overlays/uat/reviews-postgres-patch.yaml << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: reviews-service
  namespace: bidr
spec:
  template:
    spec:
      containers:
      - name: reviews-service
        envFrom:
        - secretRef:
            name: reviews-db-secret
EOF

cat > k8s/overlays/uat/chat-postgres-patch.yaml << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: chat-service
  namespace: bidr
spec:
  template:
    spec:
      containers:
      - name: chat-service
        envFrom:
        - secretRef:
            name: chat-db-secret
EOF

cat > k8s/overlays/uat/notifications-postgres-patch.yaml << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: notifications-service
  namespace: bidr
spec:
  template:
    spec:
      containers:
      - name: notifications-service
        envFrom:
        - secretRef:
            name: notifications-db-secret
EOF

cat > k8s/overlays/uat/payment-postgres-patch.yaml << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: payment-service
  namespace: bidr
spec:
  template:
    spec:
      containers:
      - name: payment-service
        envFrom:
        - secretRef:
            name: payment-db-secret
EOF

cat > k8s/overlays/uat/resolution-postgres-patch.yaml << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: resolution-service
  namespace: bidr
spec:
  template:
    spec:
      containers:
      - name: resolution-service
        envFrom:
        - secretRef:
            name: resolution-db-secret
EOF

# Apply patches
echo "Applying database configuration patches..."
kubectl patch deployment reviews-service -n bidr --patch-file k8s/overlays/uat/reviews-postgres-patch.yaml
kubectl patch deployment chat-service -n bidr --patch-file k8s/overlays/uat/chat-postgres-patch.yaml
kubectl patch deployment notifications-service -n bidr --patch-file k8s/overlays/uat/notifications-postgres-patch.yaml
kubectl patch deployment payment-service -n bidr --patch-file k8s/overlays/uat/payment-postgres-patch.yaml
kubectl patch deployment resolution-service -n bidr --patch-file k8s/overlays/uat/resolution-postgres-patch.yaml

echo "Waiting for rollouts to complete..."
kubectl rollout status deployment auth-service -n bidr
kubectl rollout status deployment product-management-service -n bidr
kubectl rollout status deployment reviews-service -n bidr
kubectl rollout status deployment chat-service -n bidr
kubectl rollout status deployment notifications-service -n bidr
kubectl rollout status deployment payment-service -n bidr
kubectl rollout status deployment resolution-service -n bidr

echo "All services updated with PostgreSQL configuration!"