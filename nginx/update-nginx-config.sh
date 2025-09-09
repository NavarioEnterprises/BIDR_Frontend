#!/bin/bash

# Script to update nginx-proxy configuration in Kubernetes
# This script creates a ConfigMap from the nginx configuration and updates the nginx-proxy deployment

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NGINX_CONF="$SCRIPT_DIR/nginx-k8s.conf"
NAMESPACE="bidr"

echo "=== BIDR Nginx Configuration Update Script ==="
echo "============================================="

# Check if nginx config file exists
if [ ! -f "$NGINX_CONF" ]; then
    echo "❌ Error: nginx-k8s.conf not found at $NGINX_CONF"
    exit 1
fi

echo "✅ Found nginx configuration at: $NGINX_CONF"

# Create ConfigMap from nginx configuration
echo ""
echo "📦 Creating ConfigMap from nginx configuration..."
kubectl create configmap nginx-proxy-config-updated \
    --from-file=default.conf="$NGINX_CONF" \
    --namespace="$NAMESPACE" \
    --dry-run=client -o yaml | kubectl apply -f -

if [ $? -ne 0 ]; then
    echo "❌ Failed to create ConfigMap"
    exit 1
fi

echo "✅ ConfigMap 'nginx-proxy-config-updated' created/updated successfully"

# Update the deployment to use the new ConfigMap
echo ""
echo "🔧 Updating nginx-proxy deployment to use new ConfigMap..."

# First, get the current deployment and update it
kubectl get deployment nginx-proxy -n "$NAMESPACE" -o yaml | \
    sed 's/nginx-proxy-config-fixed/nginx-proxy-config-updated/g' | \
    kubectl apply -f -

if [ $? -ne 0 ]; then
    echo "❌ Failed to update deployment"
    exit 1
fi

echo "✅ Deployment updated to use new ConfigMap"

# Restart nginx-proxy to apply changes
echo ""
echo "🔄 Restarting nginx-proxy deployment..."
kubectl rollout restart deployment nginx-proxy -n "$NAMESPACE"

if [ $? -ne 0 ]; then
    echo "❌ Failed to restart nginx-proxy"
    exit 1
fi

# Wait for rollout to complete
echo ""
echo "⏳ Waiting for nginx-proxy rollout to complete..."
kubectl rollout status deployment nginx-proxy -n "$NAMESPACE" --timeout=120s

if [ $? -ne 0 ]; then
    echo "⚠️  Rollout is taking longer than expected. You can check status with:"
    echo "   kubectl rollout status deployment nginx-proxy -n $NAMESPACE"
else
    echo "✅ Rollout completed successfully!"
fi

# Show pod status
echo ""
echo "📊 Current nginx-proxy pod status:"
kubectl get pods -n "$NAMESPACE" -l app=nginx-proxy

# Test endpoints
echo ""
echo "🧪 Testing service endpoints..."
echo ""
echo "Auth Service:"
curl -s -o /dev/null -w "  - http://20.241.197.87/auth/health/ - Status: %{http_code}\n" http://20.241.197.87/auth/health/
curl -s -o /dev/null -w "  - http://20.241.197.87/auth/admin/ - Status: %{http_code}\n" http://20.241.197.87/auth/admin/

echo ""
echo "Products Service:"
curl -s -o /dev/null -w "  - http://20.241.197.87/products/ - Status: %{http_code}\n" http://20.241.197.87/products/
curl -s -o /dev/null -w "  - http://20.241.197.87/products/admin/ - Status: %{http_code}\n" http://20.241.197.87/products/admin/

echo ""
echo "Reviews Service:"
curl -s -o /dev/null -w "  - http://20.241.197.87/reviews/ - Status: %{http_code}\n" http://20.241.197.87/reviews/
curl -s -o /dev/null -w "  - http://20.241.197.87/reviews/admin/ - Status: %{http_code}\n" http://20.241.197.87/reviews/admin/

echo ""
echo "✅ Nginx configuration update complete!"
echo ""
echo "📝 Summary of changes:"
echo "  - Each service now has its own admin route (e.g., /auth/admin/, /products/admin/, /reviews/admin/)"
echo "  - Admin redirects are properly handled for each service"
echo "  - API endpoints are available at both /api/v1/<service>/ and /<service>/api/"
echo "  - WebSocket support enabled for chat service"
echo ""
echo "🔍 To view nginx logs:"
echo "   kubectl logs -n $NAMESPACE deployment/nginx-proxy"
echo ""
echo "📋 To view current nginx configuration:"
echo "   kubectl exec -n $NAMESPACE deployment/nginx-proxy -- cat /etc/nginx/conf.d/default.conf"