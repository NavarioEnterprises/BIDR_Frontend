#!/bin/bash

# Optimize resource requests across all services to fix scheduling issues
# This reduces CPU/memory requests to allow pods to be scheduled on constrained cluster

set -e

echo "🔧 Optimizing resource requests to fix scheduling issues..."

# List of services to optimize
SERVICES=(
    "chat-service"
    "notifications-service"
    "payment-service"
    "product-management-service"
    "resolution-service"
    "reviews-service"
    "transactions-service"
)

# Function to optimize resources in a file
optimize_resources() {
    local file="$1"
    echo "   Optimizing resources in $file..."
    
    # Reduce CPU requests from 250m to 100m
    sed -i.bak 's|cpu: "250m"|cpu: "100m"|g' "$file"
    
    # Reduce memory requests from 256Mi to 128Mi  
    sed -i.bak 's|memory: "256Mi"|memory: "128Mi"|g' "$file"
    
    # Reduce CPU limits from 500m to 200m
    sed -i.bak 's|cpu: "500m"|cpu: "200m"|g' "$file"
    
    # Reduce memory limits from 512Mi to 256Mi
    sed -i.bak 's|memory: "512Mi"|memory: "256Mi"|g' "$file"
    
    # Reduce replicas from 2 to 1 to save resources
    sed -i.bak 's|replicas: 2|replicas: 1|g' "$file"
    
    # Clean up backup files
    rm -f "$file.bak"
    
    echo "   ✅ Optimized $file"
}

# Optimize UAT overlay services
echo "🎯 Optimizing UAT overlay services for constrained cluster..."
for service in "${SERVICES[@]}"; do
    file="k8s/overlays/uat/${service}.yaml"
    if [ -f "$file" ]; then
        optimize_resources "$file"
    else
        echo "   ⚠️  File not found: $file"
    fi
done

echo ""
echo "✅ Resource optimization completed!"
echo ""
echo "📋 Summary of changes:"
echo "   - CPU requests: 250m → 100m (60% reduction)"
echo "   - Memory requests: 256Mi → 128Mi (50% reduction)"
echo "   - CPU limits: 500m → 200m (60% reduction)"
echo "   - Memory limits: 512Mi → 256Mi (50% reduction)"
echo "   - Replicas: 2 → 1 (50% pod reduction)"
echo ""
echo "💡 This should resolve scheduling issues on resource-constrained cluster"
echo "🚀 Ready to apply: kubectl apply -k k8s/overlays/uat/"
