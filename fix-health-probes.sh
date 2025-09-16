#!/bin/bash

# Batch fix health probe configurations across all services
# This script updates all service YAML files to use proper health endpoints

set -e

echo "🔧 Fixing health probe configurations across all services..."

# List of services to fix
SERVICES=(
    "auth-service"
    "resolution-service" 
    "product-management-service"
    "reviews-service"
    "transactions-service"
)

# Function to fix probes in a file
fix_probes() {
    local file="$1"
    echo "   Fixing probes in $file..."
    
    # Replace path: / with path: /health/
    sed -i.bak 's|path: /|path: /health/|g' "$file"
    
    # Update timing configurations
    sed -i.bak 's|initialDelaySeconds: 60|initialDelaySeconds: 120|g' "$file"
    sed -i.bak 's|initialDelaySeconds: 30|initialDelaySeconds: 90|g' "$file"
    sed -i.bak 's|periodSeconds: 10|periodSeconds: 15|g' "$file"
    sed -i.bak 's|failureThreshold: 3|failureThreshold: 5|g' "$file"
    
    # Fix DEBUG mode to False
    sed -i.bak 's|value: "True"|value: "False"|g' "$file"
    
    # Clean up backup files
    rm -f "$file.bak"
    
    echo "   ✅ Fixed $file"
}

# Fix UAT overlay services
echo "🎯 Fixing UAT overlay services..."
for service in "${SERVICES[@]}"; do
    file="k8s/overlays/uat/${service}.yaml"
    if [ -f "$file" ]; then
        fix_probes "$file"
    else
        echo "   ⚠️  File not found: $file"
    fi
done

echo ""
echo "✅ Health probe fixes completed!"
echo ""
echo "📋 Summary of changes:"
echo "   - Updated probe paths from '/' to '/health/'"
echo "   - Increased initialDelaySeconds for better startup time"  
echo "   - Increased failureThreshold for more reliability"
echo "   - Set DEBUG=False for production"
echo ""
echo "🚀 Services are now ready for deployment with proper health checks!"
