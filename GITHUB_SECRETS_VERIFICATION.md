# 🔐 GitHub Repository Secrets Verification & Setup Guide

## 🚨 CRITICAL: Required Secrets for BIDR Backend Deployment

### 📍 GitHub Repository Settings Location
Go to: [https://github.com/NavarioEnterprises/BIDR_Backend/settings/secrets/actions](https://github.com/NavarioEnterprises/BIDR_Backend/settings/secrets/actions)

---

## ✅ Required Secrets Checklist

### 1. **AZURE_CREDENTIALS** (Used by: deploy.yml, dev-deploy.yml, infrastructure.yml)
```json
{
  "clientId": "e489c481-1f22-4ac5-8af3-6da2e297be97",
  "clientSecret": "EbF8Q~Jjtfx-6EMSK.JufKz_zrkU2WflkbGM-dq-",
  "subscriptionId": "51dd222b-9d63-476c-9069-cd3b2a87f6e6",
  "tenantId": "e786b992-a2df-4004-a9d7-97d97b3db868"
}
```

### 2. **ACR_USERNAME** (Used by: deploy.yml, dev-cicd.yml)
```
bidrnparusdevregistry2024
```

### 3. **ACR_PASSWORD** (Used by: deploy.yml, dev-cicd.yml)
```
3EVXNJ900i4VNYCZlonrE9SEsDiVHyT77tT3+TFYYf+ACRDREQen
```

### 4. **AZURE_CLIENT_ID** (Used by: uat-deploy.yml)
```
e489c481-1f22-4ac5-8af3-6da2e297be97
```

### 5. **AZURE_TENANT_ID** (Used by: uat-deploy.yml)
```
e786b992-a2df-4004-a9d7-97d97b3db868
```

### 6. **AZURE_SUBSCRIPTION_ID** (Used by: uat-deploy.yml)
```
51dd222b-9d63-476c-9069-cd3b2a87f6e6
```

---

## 🔍 Verification Commands

After adding secrets, verify Azure connectivity:

```bash
# Test Azure CLI login locally
az login --service-principal \
  --username "e489c481-1f22-4ac5-8af3-6da2e297be97" \
  --password "EbF8Q~Jjtfx-6EMSK.JufKz_zrkU2WflkbGM-dq-" \
  --tenant "e786b992-a2df-4004-a9d7-97d97b3db868"

# Test ACR access
az acr login --name bidrnparusdevregistry2024

# Test AKS access
az aks get-credentials --resource-group bidr-dev-k8s --name BIDR-dev-aks-cluster

# Check cluster connectivity
kubectl get nodes
kubectl get namespaces
```

---

## 🎯 Expected Workflow Behavior After Secrets Setup

### Main Branch Push (deploy.yml):
1. ✅ Detects changes in service folders
2. ✅ Builds Docker images for changed services
3. ✅ Pushes images to ACR: `bidrnparusdevregistry2024.azurecr.io`
4. ✅ Deploys to AKS cluster: `BIDR-dev-aks-cluster`
5. ✅ Updates services in `bidr` namespace
6. ✅ Runs health checks

### Infrastructure Changes (infrastructure.yml):
1. ✅ Validates Kubernetes manifests (excluding kustomization.yaml)
2. ✅ Applies base kustomization: `kubectl apply -k k8s/`
3. ✅ Deploys to `bidr` namespace
4. ✅ Waits for deployment readiness

---

## 🐛 Troubleshooting Common Issues

### Error: "Authentication failed"
- ✅ Verify `AZURE_CREDENTIALS` JSON format is correct
- ✅ Check service principal permissions
- ✅ Ensure no extra spaces or characters

### Error: "ACR login failed"
- ✅ Verify `ACR_USERNAME` matches exactly: `bidrnparusdevregistry2024`
- ✅ Check `ACR_PASSWORD` for correct characters
- ✅ Ensure ACR exists and is accessible

### Error: "AKS credentials failed"
- ✅ Verify cluster name: `BIDR-dev-aks-cluster`
- ✅ Check resource group: `bidr-dev-k8s`
- ✅ Ensure service principal has AKS permissions

### Error: "Namespace not found"
- ✅ Verify `bidr` namespace exists: `kubectl get namespaces`
- ✅ Create manually if missing: `kubectl apply -f k8s/namespace.yaml`

---

## 🚀 Step-by-Step Setup Instructions

### Step 1: Add Secrets to GitHub
1. Navigate to repository Settings → Secrets and variables → Actions
2. Click "New repository secret"
3. Add each secret from the list above
4. Ensure exact naming (case-sensitive)

### Step 2: Verify Current Environment
```bash
# Check current AKS cluster
kubectl config current-context

# Check available namespaces
kubectl get namespaces

# Verify bidr namespace exists
kubectl get pods -n bidr
```

### Step 3: Test Deployment
```bash
# Make a small change to trigger workflow
echo "# Updated $(date)" >> README.md
git add README.md
git commit -m "test: trigger workflow to verify secrets"
git push origin main
```

### Step 4: Monitor Workflow
- Go to Actions tab in GitHub repository
- Watch for successful workflow completion
- Check logs for any authentication issues

---

## 📊 Expected Service Deployment

After successful workflow run:

| Service | Image | Deployment | Status |
|---------|-------|------------|---------|
| Authentication | `bidrnparusdevregistry2024.azurecr.io/auth-service` | `auth-service` | ✅ Running |
| Chat | `bidrnparusdevregistry2024.azurecr.io/chat-service` | `chat-service` | ✅ Running |
| Payment | `bidrnparusdevregistry2024.azurecr.io/payment-service` | `payment-service` | ✅ Running |
| Product | `bidrnparusdevregistry2024.azurecr.io/product-service` | `product-management-service` | ✅ Running |
| Notifications | `bidrnparusdevregistry2024.azurecr.io/notifications-service` | `notifications-service` | ✅ Running |
| Transactions | `bidrnparusdevregistry2024.azurecr.io/transactions-service` | `transactions-service` | ✅ Running |
| Reviews | `bidrnparusdevregistry2024.azurecr.io/reviews-service` | `reviews-service` | ✅ Running |
| Resolution | `bidrnparusdevregistry2024.azurecr.io/resolution-service` | `resolution-service` | ✅ Running |

---

## 🌐 Access Points After Deployment

- **Load Balancer IP**: Check `kubectl get svc nginx-proxy -n bidr`
- **Health Endpoint**: `http://<LB_IP>/health`
- **Admin Interface**: `http://<LB_IP>/admin/`
- **Service Endpoints**: `http://<LB_IP>/<service-path>/`

---

## ⚡ Quick Fix Commands

```bash
# If secrets are missing, add them via GitHub CLI
gh secret set AZURE_CREDENTIALS --body '{"clientId":"...","clientSecret":"...","subscriptionId":"...","tenantId":"..."}'
gh secret set ACR_USERNAME --body 'bidrnparusdevregistry2024'
gh secret set ACR_PASSWORD --body '3EVXNJ900i4VNYCZlonrE9SEsDiVHyT77tT3+TFYYf+ACRDREQen'

# Re-run failed workflow
gh workflow run deploy.yml

# Check workflow status
gh run list --limit 5
```

---

**🎉 Once all secrets are properly configured, your BIDR Backend will deploy automatically on every push to main!**
