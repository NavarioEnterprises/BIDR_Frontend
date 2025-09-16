#!/bin/bash

echo "🎯 BIDR CI/CD Deployment Verification"
echo "====================================="
echo "⏰ $(date)"
echo ""

echo "📊 1. Pod Status:"
kubectl get pods -n bidr --no-headers | awk '{printf "%-40s %s %s %s\n", $1, $2, $3, $5}' | column -t

echo ""
echo "📦 2. Recent ACR Images:"
echo "auth-service:"
az acr repository show-tags --name bidrnparusdevregistry2024 --repository auth-service --orderby time_desc --top 3 --output table 2>/dev/null || echo "  (checking...)"

echo ""
echo "🌐 3. External Access Test:"
LB_IP="4.221.172.198"
echo "LoadBalancer IP: $LB_IP"
echo "Root endpoint: $(curl -s -o /dev/null -w '%{http_code}' http://$LB_IP/)"
echo "Products endpoint: $(curl -s -o /dev/null -w '%{http_code}' http://$LB_IP/products/)"
echo "Chat endpoint: $(curl -s -o /dev/null -w '%{http_code}' http://$LB_IP/chat/)"

echo ""
echo "🔄 4. Recent Deployment Events:"
kubectl get events -n bidr --sort-by='.lastTimestamp' --field-selector reason!=FailedMount | tail -5

