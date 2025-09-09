#!/usr/bin/env bash

echo "🔧 Updating deployments to use shared database..."

# Update payment service deployment
kubectl patch deployment payment-service -n bidr -p='{"spec":{"template":{"spec":{"containers":[{"name":"payment-service","env":[{"name":"DATABASE_URL","valueFrom":{"secretKeyRef":{"name":"bidr-secrets","key":"AUTH_DATABASE_URL"}}}]}]}}}}'

# Update product service deployment
kubectl patch deployment product-service -n bidr -p='{"spec":{"template":{"spec":{"containers":[{"name":"product-service","env":[{"name":"DATABASE_URL","valueFrom":{"secretKeyRef":{"name":"bidr-secrets","key":"AUTH_DATABASE_URL"}}}]}]}}}}'

# Update notifications service deployment
kubectl patch deployment notifications-service -n bidr -p='{"spec":{"template":{"spec":{"containers":[{"name":"notifications-service","env":[{"name":"DATABASE_URL","valueFrom":{"secretKeyRef":{"name":"bidr-secrets","key":"AUTH_DATABASE_URL"}}}]}]}}}}'

# Update transactions service deployment
kubectl patch deployment transactions-service -n bidr -p='{"spec":{"template":{"spec":{"containers":[{"name":"transactions-service","env":[{"name":"DATABASE_URL","valueFrom":{"secretKeyRef":{"name":"bidr-secrets","key":"AUTH_DATABASE_URL"}}}]}]}}}}'

# Update reviews service deployment
kubectl patch deployment reviews-service -n bidr -p='{"spec":{"template":{"spec":{"containers":[{"name":"reviews-service","env":[{"name":"DATABASE_URL","valueFrom":{"secretKeyRef":{"name":"bidr-secrets","key":"AUTH_DATABASE_URL"}}}]}]}}}}'

# Update resolution service deployment
kubectl patch deployment resolution-service -n bidr -p='{"spec":{"template":{"spec":{"containers":[{"name":"resolution-service","env":[{"name":"DATABASE_URL","valueFrom":{"secretKeyRef":{"name":"bidr-secrets","key":"AUTH_DATABASE_URL"}}}]}]}}}}'

echo "✅ All deployments updated to use shared database"
echo "⏳ Waiting for deployments to restart..."

# Wait for rollouts to complete
kubectl rollout status deployment/payment-service -n bidr --timeout=300s
kubectl rollout status deployment/product-service -n bidr --timeout=300s
kubectl rollout status deployment/notifications-service -n bidr --timeout=300s
kubectl rollout status deployment/transactions-service -n bidr --timeout=300s
kubectl rollout status deployment/reviews-service -n bidr --timeout=300s
kubectl rollout status deployment/resolution-service -n bidr --timeout=300s

echo "🎉 All services should now be running!"
