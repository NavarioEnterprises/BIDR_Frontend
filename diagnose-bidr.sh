#!/bin/bash

# BIDR Deployment Diagnostic Script
# This script helps diagnose specific issues with your deployment

echo "🔍 BIDR Deployment Diagnostics"
echo "=============================="

NAMESPACE="bidr"
LOAD_BALANCER_IP="20.241.197.87"

# Function to check pod details
check_pod() {
    local POD_NAME=$1
    echo -e "\n📋 Checking $POD_NAME:"
    
    # Get pod status
    STATUS=$(kubectl get pod $POD_NAME -n $NAMESPACE -o jsonpath='{.status.phase}' 2>/dev/null)
    echo "  Status: $STATUS"
    
    # Check container statuses
    kubectl get pod $POD_NAME -n $NAMESPACE -o json 2>/dev/null | jq -r '.status.containerStatuses[]? | "  Container: \(.name) - \(.state | keys[0])"'
    
    # Get recent events
    echo "  Recent Events:"
    kubectl describe pod $POD_NAME -n $NAMESPACE 2>/dev/null | grep -A 5 "Events:" | tail -n 5 | sed 's/^/    /'
    
    # Check logs if running
    if [ "$STATUS" = "Running" ]; then
        echo "  Recent Logs:"
        kubectl logs $POD_NAME -n $NAMESPACE --tail=5 2>/dev/null | sed 's/^/    /'
    fi
}

echo -e "\n🏥 1. Checking Pod Health:"
echo "=========================="
kubectl get pods -n $NAMESPACE -o wide

echo -e "\n🔐 2. Checking Secrets:"
echo "======================"
kubectl get secrets -n $NAMESPACE | grep -v "default-token"

echo -e "\n📦 3. Checking Image Pull Issues:"
echo "================================"
FAILING_PODS=$(kubectl get pods -n $NAMESPACE -o json | jq -r '.items[] | select(.status.containerStatuses[]?.state.waiting.reason == "ImagePullBackOff" or .status.containerStatuses[]?.state.waiting.reason == "ErrImagePull") | .metadata.name')

if [ -z "$FAILING_PODS" ]; then
    echo "✓ No image pull issues detected"
else
    echo "✗ Pods with image pull issues:"
    for POD in $FAILING_PODS; do
        check_pod $POD
    done
fi

echo -e "\n🗄️ 4. Checking Database Connectivity:"
echo "===================================="
# Check if postgres is running
PG_POD=$(kubectl get pods -n $NAMESPACE -l app=postgres -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ ! -z "$PG_POD" ]; then
    echo "PostgreSQL pod: $PG_POD"
    kubectl exec $PG_POD -n $NAMESPACE -- psql -U postgres -c "\\l" 2>/dev/null | grep bidr || echo "✗ No bidr database found"
else
    echo "✗ PostgreSQL pod not found"
fi

echo -e "\n🌐 5. Checking Service Endpoints:"
echo "================================"
for SERVICE in auth chat payment product notifications transactions reviews resolution; do
    ENDPOINTS=$(kubectl get endpoints ${SERVICE}-service -n $NAMESPACE -o jsonpath='{.subsets[*].addresses[*].ip}' 2>/dev/null)
    if [ -z "$ENDPOINTS" ]; then
        echo "✗ ${SERVICE}-service: No endpoints"
    else
        echo "✓ ${SERVICE}-service: $ENDPOINTS"
    fi
done

echo -e "\n🔧 6. Checking ConfigMaps:"
echo "========================"
kubectl get configmaps -n $NAMESPACE | grep -v "kube-root-ca.crt"

echo -e "\n🌐 7. Testing External Access:"
echo "============================="
echo "Testing Load Balancer IP: $LOAD_BALANCER_IP"

# Test each endpoint
declare -A ENDPOINTS=(
    ["Health"]="/health"
    ["Auth API"]="/auth/"
    ["Auth Admin"]="/auth/admin/"
    ["Auth Swagger"]="/auth/swagger/"
)

for NAME in "${!ENDPOINTS[@]}"; do
    URL="http://$LOAD_BALANCER_IP${ENDPOINTS[$NAME]}"
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$URL" --max-time 5)
    if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "301" ] || [ "$HTTP_CODE" = "302" ]; then
        echo "✓ $NAME: HTTP $HTTP_CODE"
    else
        echo "✗ $NAME: HTTP $HTTP_CODE"
    fi
done

echo -e "\n📊 8. Resource Usage:"
echo "==================="
kubectl top pods -n $NAMESPACE 2>/dev/null || echo "Metrics server not available"

echo -e "\n🔍 9. Checking for CrashLooping Pods:"
echo "===================================="
CRASH_PODS=$(kubectl get pods -n $NAMESPACE -o json | jq -r '.items[] | select(.status.containerStatuses[]?.restartCount > 3) | .metadata.name')
if [ -z "$CRASH_PODS" ]; then
    echo "✓ No pods are crash looping"
else
    echo "✗ Pods with high restart counts:"
    for POD in $CRASH_PODS; do
        RESTARTS=$(kubectl get pod $POD -n $NAMESPACE -o jsonpath='{.status.containerStatuses[0].restartCount}')
        echo "  - $POD: $RESTARTS restarts"
    done
fi

echo -e "\n💡 Recommendations:"
echo "=================="
echo "1. For ImagePullBackOff errors: Check ACR authentication and image names"
echo "2. For CrashLooping pods: Check logs with: kubectl logs <pod-name> -n $NAMESPACE --previous"
echo "3. For 500 errors: Check service logs and database connectivity"
echo "4. For missing endpoints: Ensure pods are running and ready"

echo -e "\n✅ Diagnostic complete!"