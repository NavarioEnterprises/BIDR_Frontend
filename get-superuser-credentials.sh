#!/bin/bash

set -e

echo "🔍 Retrieving BIDR Superuser Credentials"
echo ""

# Check if kubectl is configured
if ! kubectl cluster-info &> /dev/null; then
    echo "❌ kubectl is not configured. Please ensure you're connected to the BIDR AKS cluster."
    exit 1
fi

# Check if the bidr namespace exists
if ! kubectl get namespace bidr &> /dev/null; then
    echo "❌ BIDR namespace doesn't exist. Please deploy the application first."
    exit 1
fi

# Check if init job exists and get its status
JOB_STATUS=$(kubectl get job bidr-init -n bidr -o jsonpath='{.status.conditions[0].type}' 2>/dev/null || echo "NotFound")

if [ "$JOB_STATUS" = "NotFound" ]; then
    echo "❌ Initialization job not found. Running initialization..."
    
    # Apply the initialization job
    kubectl apply -f k8s/init-job.yaml
    
    echo "⏳ Waiting for initialization job to complete..."
    kubectl wait --for=condition=complete --timeout=300s job/bidr-init -n bidr
    
elif [ "$JOB_STATUS" = "Complete" ]; then
    echo "✅ Initialization job already completed"
else
    echo "⏳ Waiting for initialization job to complete..."
    kubectl wait --for=condition=complete --timeout=300s job/bidr-init -n bidr
fi

# Get the job logs to extract credentials
echo ""
echo "📋 Retrieving superuser credentials from initialization logs..."

LOGS=$(kubectl logs job/bidr-init -n bidr 2>/dev/null || echo "")

if [ -z "$LOGS" ]; then
    echo "❌ Could not retrieve initialization logs"
    exit 1
fi

# Extract username and password from logs
USERNAME=$(echo "$LOGS" | grep "Username:" | awk '{print $2}' | head -1)
EMAIL=$(echo "$LOGS" | grep "Email:" | awk '{print $2}' | head -1)
PASSWORD_LINE=$(echo "$LOGS" | grep "Password:" | head -1)
PASSWORD=$(echo "$PASSWORD_LINE" | awk '{print $2}')

if [ -n "$USERNAME" ] && [ -n "$PASSWORD" ]; then
    echo ""
    echo "🎉 BIDR Superuser Credentials:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "👤 Username: $USERNAME"
    echo "📧 Email:    $EMAIL"
    echo "🔑 Password: $PASSWORD"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "🌐 Admin URL: http://20.66.69.82:8067/admin/"
    echo ""
    echo "💡 Save these credentials securely!"
else
    echo "❌ Could not extract credentials from logs"
    echo "📋 Full logs:"
    echo "$LOGS"
fi

# Additional information
echo ""
echo "📊 Deployment Status:"
kubectl get pods -n bidr
echo ""
kubectl get services -n bidr
