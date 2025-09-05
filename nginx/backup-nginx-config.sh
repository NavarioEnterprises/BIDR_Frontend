#!/bin/bash

# Script to backup current nginx configuration from Kubernetes

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$SCRIPT_DIR/backups"
NAMESPACE="bidr"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

echo "=== BIDR Nginx Configuration Backup Script ==="
echo "============================================="

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

echo "📁 Backup directory: $BACKUP_DIR"

# Get current ConfigMap
echo ""
echo "📥 Backing up current nginx ConfigMap..."
kubectl get configmap nginx-proxy-config-fixed -n "$NAMESPACE" -o yaml > "$BACKUP_DIR/nginx-configmap-$TIMESTAMP.yaml" 2>/dev/null

if [ $? -eq 0 ]; then
    echo "✅ ConfigMap backed up to: nginx-configmap-$TIMESTAMP.yaml"
else
    echo "⚠️  Could not find nginx-proxy-config-fixed ConfigMap, trying nginx-proxy-config-updated..."
    kubectl get configmap nginx-proxy-config-updated -n "$NAMESPACE" -o yaml > "$BACKUP_DIR/nginx-configmap-$TIMESTAMP.yaml" 2>/dev/null
    if [ $? -eq 0 ]; then
        echo "✅ ConfigMap backed up to: nginx-configmap-$TIMESTAMP.yaml"
    else
        echo "❌ No nginx ConfigMap found to backup"
    fi
fi

# Extract actual nginx config from the pod
echo ""
echo "📥 Extracting current nginx configuration from running pod..."
kubectl exec -n "$NAMESPACE" deployment/nginx-proxy -- cat /etc/nginx/conf.d/default.conf > "$BACKUP_DIR/nginx-default-conf-$TIMESTAMP.conf" 2>/dev/null

if [ $? -eq 0 ]; then
    echo "✅ Nginx config backed up to: nginx-default-conf-$TIMESTAMP.conf"
else
    echo "❌ Could not extract nginx config from pod"
fi

# Backup deployment configuration
echo ""
echo "📥 Backing up nginx-proxy deployment configuration..."
kubectl get deployment nginx-proxy -n "$NAMESPACE" -o yaml > "$BACKUP_DIR/nginx-deployment-$TIMESTAMP.yaml"

if [ $? -eq 0 ]; then
    echo "✅ Deployment backed up to: nginx-deployment-$TIMESTAMP.yaml"
else
    echo "❌ Could not backup deployment configuration"
fi

echo ""
echo "✅ Backup complete!"
echo ""
echo "📋 Backup files created in: $BACKUP_DIR"
ls -la "$BACKUP_DIR" | grep "$TIMESTAMP"

echo ""
echo "💡 To restore from backup:"
echo "   kubectl apply -f $BACKUP_DIR/nginx-configmap-$TIMESTAMP.yaml"
echo "   kubectl apply -f $BACKUP_DIR/nginx-deployment-$TIMESTAMP.yaml"
echo "   kubectl rollout restart deployment nginx-proxy -n $NAMESPACE"