#!/bin/bash

# Script to apply Django URL prefix configurations to all services
# This script updates Django services with proper URL prefix awareness

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
K8S_DIR="$(dirname "$SCRIPT_DIR")/k8s/overlays/uat"
NAMESPACE="bidr"

echo "=== BIDR Django URL Prefix Configuration Script ==="
echo "================================================="
echo ""

# Function to backup current deployments
backup_deployments() {
    echo "📥 Creating backup of current deployments..."
    BACKUP_DIR="$SCRIPT_DIR/backups/deployments-$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    
    kubectl get deployment product-management-service -n "$NAMESPACE" -o yaml > "$BACKUP_DIR/product-deployment.yaml"
    kubectl get deployment reviews-service -n "$NAMESPACE" -o yaml > "$BACKUP_DIR/reviews-deployment.yaml"
    
    echo "✅ Deployments backed up to: $BACKUP_DIR"
}

# Function to apply deployments
apply_deployments() {
    echo ""
    echo "🚀 Applying updated Django service deployments..."
    
    # Apply product management service
    echo "📦 Updating product management service..."
    kubectl apply -f "$K8S_DIR/product-django-real.yaml"
    if [ $? -eq 0 ]; then
        echo "✅ Product management service deployment updated"
    else
        echo "❌ Failed to update product management service"
        return 1
    fi
    
    # Apply reviews service
    echo "📦 Updating reviews service..."
    kubectl apply -f "$K8S_DIR/reviews-service-real.yaml"
    if [ $? -eq 0 ]; then
        echo "✅ Reviews service deployment updated"
    else
        echo "❌ Failed to update reviews service"
        return 1
    fi
}

# Function to apply nginx configuration
apply_nginx_config() {
    echo ""
    echo "🌐 Updating nginx configuration..."
    
    # Create ConfigMap from updated nginx config
    kubectl create configmap nginx-proxy-config-with-prefixes \
        --from-file=default.conf="$SCRIPT_DIR/nginx-k8s.conf" \
        --namespace="$NAMESPACE" \
        --dry-run=client -o yaml | kubectl apply -f -
    
    if [ $? -ne 0 ]; then
        echo "❌ Failed to create nginx ConfigMap"
        return 1
    fi
    
    # Update deployment to use new ConfigMap
    kubectl patch deployment nginx-proxy -n "$NAMESPACE" \
        -p '{"spec":{"template":{"spec":{"volumes":[{"name":"nginx-config","configMap":{"name":"nginx-proxy-config-with-prefixes"}}]}}}}'
    
    if [ $? -ne 0 ]; then
        echo "❌ Failed to update nginx deployment"
        return 1
    fi
    
    echo "✅ Nginx configuration updated"
}

# Function to restart services
restart_services() {
    echo ""
    echo "🔄 Restarting services to apply changes..."
    
    # Restart product management service
    echo "  - Restarting product management service..."
    kubectl rollout restart deployment product-management-service -n "$NAMESPACE"
    
    # Restart reviews service
    echo "  - Restarting reviews service..."
    kubectl rollout restart deployment reviews-service -n "$NAMESPACE"
    
    # Restart nginx proxy
    echo "  - Restarting nginx proxy..."
    kubectl rollout restart deployment nginx-proxy -n "$NAMESPACE"
}

# Function to wait for rollouts
wait_for_rollouts() {
    echo ""
    echo "⏳ Waiting for service rollouts to complete..."
    
    # Wait for product service
    echo "  - Waiting for product management service..."
    kubectl rollout status deployment product-management-service -n "$NAMESPACE" --timeout=300s
    
    # Wait for reviews service
    echo "  - Waiting for reviews service..."
    kubectl rollout status deployment reviews-service -n "$NAMESPACE" --timeout=300s
    
    # Wait for nginx
    echo "  - Waiting for nginx proxy..."
    kubectl rollout status deployment nginx-proxy -n "$NAMESPACE" --timeout=120s
    
    echo "✅ All rollouts completed"
}

# Function to test endpoints
test_endpoints() {
    echo ""
    echo "🧪 Testing Django admin interfaces with URL prefixes..."
    echo ""
    
    # Test products admin
    echo "Products Service:"
    PRODUCTS_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://20.241.197.87/products/admin/)
    echo "  - Admin: http://20.241.197.87/products/admin/ - Status: $PRODUCTS_STATUS"
    
    PRODUCTS_STATIC_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://20.241.197.87/products/static/admin/css/base.css)
    echo "  - Static: http://20.241.197.87/products/static/admin/css/base.css - Status: $PRODUCTS_STATIC_STATUS"
    
    # Test reviews admin
    echo ""
    echo "Reviews Service:"
    REVIEWS_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://20.241.197.87/reviews/admin/)
    echo "  - Admin: http://20.241.197.87/reviews/admin/ - Status: $REVIEWS_STATUS"
    
    REVIEWS_STATIC_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://20.241.197.87/reviews/static/admin/css/base.css)
    echo "  - Static: http://20.241.197.87/reviews/static/admin/css/base.css - Status: $REVIEWS_STATIC_STATUS"
    
    # Test auth admin (should still work)
    echo ""
    echo "Auth Service:"
    AUTH_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://20.241.197.87/auth/admin/)
    echo "  - Admin: http://20.241.197.87/auth/admin/ - Status: $AUTH_STATUS"
}

# Function to show Django settings summary
show_django_settings() {
    echo ""
    echo "📋 Django URL Prefix Settings Applied:"
    echo "======================================"
    echo ""
    echo "Products Service (/products/):"
    echo "  - FORCE_SCRIPT_NAME = '/products'"
    echo "  - USE_X_FORWARDED_HOST = True"
    echo "  - SECURE_PROXY_SSL_HEADER = ('HTTP_X_FORWARDED_PROTO', 'https')"
    echo "  - STATIC_URL = '/products/static/'"
    echo ""
    echo "Reviews Service (/reviews/):"
    echo "  - FORCE_SCRIPT_NAME = '/reviews'"
    echo "  - USE_X_FORWARDED_HOST = True"
    echo "  - SECURE_PROXY_SSL_HEADER = ('HTTP_X_FORWARDED_PROTO', 'https')"
    echo "  - STATIC_URL = '/reviews/static/'"
    echo ""
    echo "These settings ensure Django generates correct URLs when running behind"
    echo "a reverse proxy with path prefixes."
}

# Main execution
main() {
    echo "This script will:"
    echo "1. Backup current deployments"
    echo "2. Apply Django services with URL prefix configuration"
    echo "3. Update nginx configuration for static files"
    echo "4. Restart all affected services"
    echo "5. Test the endpoints"
    echo ""
    
    read -p "Continue? (y/N): " -r
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted by user"
        exit 1
    fi
    
    # Execute steps
    backup_deployments
    apply_deployments
    apply_nginx_config
    restart_services
    wait_for_rollouts
    test_endpoints
    show_django_settings
    
    echo ""
    echo "✅ Django URL prefix configuration completed successfully!"
    echo ""
    echo "🔍 To verify Django is generating correct URLs:"
    echo "   - Login to admin interfaces and check that links work correctly"
    echo "   - Verify CSS and JS files load properly"
    echo "   - Check that Django redirects maintain the correct URL prefix"
    echo ""
    echo "📊 To monitor services:"
    echo "   kubectl get pods -n $NAMESPACE"
    echo "   kubectl logs -n $NAMESPACE deployment/product-management-service"
    echo "   kubectl logs -n $NAMESPACE deployment/reviews-service"
}

# Run main function
main "$@"