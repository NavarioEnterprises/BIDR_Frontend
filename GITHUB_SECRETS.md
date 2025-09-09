# 🔑 GitHub Repository Secrets Configuration

## 🚨 CRITICAL: Add these secrets to fix CI/CD authentication error

### 📍 Location: 
Go to: https://github.com/NavarioEnterprises/BIDR_Backend/settings/secrets/actions

## 🔐 Required Secrets:

### 1. ACR_USERNAME
```
bidrnparusdevregistry2024
```

### 2. ACR_PASSWORD
```
3EVXNJ900i4VNYCZlonrE9SEsDiVHyT77tT3+TFYYf+ACRDREQen
```

### 3. AZURE_CREDENTIALS
```json
{
  "clientId": "e489c481-1f22-4ac5-8af3-6da2e297be97",
  "clientSecret": "EbF8Q~Jjtfx-6EMSK.JufKz_zrkU2WflkbGM-dq-",
  "subscriptionId": "51dd222b-9d63-476c-9069-cd3b2a87f6e6",
  "tenantId": "e786b992-a2df-4004-a9d7-97d97b3db868"
}
```

## ✅ After adding secrets:

1. **Re-run the failed workflow** or push a new commit
2. **Pipeline will automatically**:
   - Build Docker images for all services
   - Push to Azure Container Registry
   - Deploy to AKS cluster (BIDR-dev-aks-cluster)
   - Update services in 'bidr' namespace

## 🔍 Verification Commands:

```bash
# Check ACR images
az acr repository show-tags --name bidrnparusdevregistry2024 --repository auth-service

# Check AKS pods
kubectl get pods -n bidr

# Test external access
curl http://4.221.172.198/
```

## 🎯 Expected Services to Deploy:
- authentication_service → auth-service
- chat_service → chat-service  
- payment_service → payment-service
- product_management_service → product-service
- notifications_service → notifications-service
- transactions_service → transactions-service
- reviews_service → reviews-service (needs module fix)
- resolution_service → resolution-service
