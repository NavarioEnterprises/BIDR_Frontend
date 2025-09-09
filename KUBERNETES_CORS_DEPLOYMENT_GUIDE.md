# Kubernetes CORS Fix Deployment Guide

## 🎯 Issue Summary

Your Flutter Web app is getting `ClientException: Failed to fetch` because the **Django API is running on Kubernetes** and needs the updated CORS configuration to be deployed to the cluster.

## ✅ What We've Done

### 1. Updated CORS Settings in Django
- Enhanced `product_management_service/settings.py` with comprehensive CORS configuration
- Added `CORSMixin` to `ProductRequestViewSet` 
- Set `CORS_ALLOW_ALL_ORIGINS = True` for development
- Added Flutter web ports (8080, 5000, 4200) to allowed origins

### 2. Created Kubernetes Deployment Script
- Built `deploy_product_service_cors_fix.sh` for automatic deployment
- Configured for your Azure Container Registry: `bidrnparusdevregistry2024.azurecr.io`
- Set up for your Kubernetes namespace: `bidr`
- Uses your load balancer IP: `108.141.192.60`

## 🚀 Deployment Instructions

### Step 1: Verify Prerequisites

Make sure you have the required tools installed:
```bash
# Check Docker
docker --version

# Check Azure CLI
az --version

# Check kubectl
kubectl version --client

# Check Kubernetes context
kubectl config current-context
```

### Step 2: Login to Azure

```bash
# Login to Azure (if not already logged in)
az login

# Verify you're in the correct subscription
az account show

# Login to Azure Container Registry
az acr login --name bidrnparusdevregistry2024
```

### Step 3: Deploy the CORS Fix

Navigate to your BIDR_Backend directory and run:

```bash
cd "/Users/thulanimoyo/MEGA downloads/new downloads/BIDR_Backend"
./deploy_product_service_cors_fix.sh
```

This script will:
1. ✅ Check prerequisites 
2. ✅ Login to Azure and ACR
3. ✅ Build Docker image with CORS fixes
4. ✅ Push image to Azure Container Registry
5. ✅ Update Kubernetes deployment
6. ✅ Wait for rollout completion
7. ✅ Verify deployment and test CORS
8. ✅ Show deployment summary

### Step 4: Verify CORS Fix

After deployment, test the CORS fix:

```bash
# Test CORS preflight request
curl -X OPTIONS \
  -H "Origin: http://localhost:8080" \
  -H "Access-Control-Request-Method: GET" \
  -v \
  http://108.141.192.60:8004/products/api/v1/product-requests/requests/

# Test actual API call
curl -X GET \
  -H "Origin: http://localhost:8080" \
  -H "Content-Type: application/json" \
  -v \
  http://108.141.192.60:8004/products/api/v1/product-requests/requests/
```

Expected CORS headers in response:
```
Access-Control-Allow-Origin: *
Access-Control-Allow-Methods: GET, POST, PUT, PATCH, DELETE, OPTIONS
Access-Control-Allow-Headers: accept, authorization, content-type, ...
```

## 🔧 Alternative Manual Deployment

If the script fails, you can deploy manually:

### Manual Option 1: Use Existing Deployment Scripts

Use one of your existing deployment scripts:

```bash
# Option A: Use the simple deployment script
./deploy_microservices_simple.sh

# Option B: Use the full deployment script  
./deploy_all_microservices.sh
```

### Manual Option 2: Step-by-Step Manual Deployment

```bash
# 1. Build and push Docker image
cd product_management_service
docker build -t bidrnparusdevregistry2024.azurecr.io/product-service:cors-fix .
docker push bidrnparusdevregistry2024.azurecr.io/product-service:cors-fix

# 2. Update Kubernetes deployment
kubectl patch deployment product-service -n bidr \
  -p '{"spec":{"template":{"spec":{"containers":[{"name":"product-service","image":"bidrnparusdevregistry2024.azurecr.io/product-service:cors-fix"}]}}}}'

# 3. Wait for rollout
kubectl rollout status deployment/product-service -n bidr

# 4. Check pods
kubectl get pods -n bidr -l app=product-service
```

## 🧪 Testing After Deployment

### Test 1: Direct API Access
Open browser and navigate to:
```
http://108.141.192.60:8004/products/api/v1/product-requests/requests/
```

### Test 2: Flutter Web Browser Console Test
In your Flutter web app's browser console:
```javascript
fetch('http://108.141.192.60:8004/products/api/v1/product-requests/requests/', {
  method: 'GET',
  headers: {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  }
})
.then(response => response.json())
.then(data => console.log('Success:', data))
.catch(error => console.error('Error:', error));
```

### Test 3: Update Your Flutter Web Code

```dart
Future<void> _fetchProductRequests() async {
  setState(() {
    _isLoading = true;
    _error = null;
  });

  try {
    print('Attempting to fetch from: http://108.141.192.60:8004/products/api/v1/product-requests/requests/');

    final response = await http.get(
      Uri.parse('http://108.141.192.60:8004/products/api/v1/product-requests/requests/'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    print('Response status: ${response.statusCode}');
    print('Response headers: ${response.headers}');

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      final apiResponse = ProductRequestApiResponse.fromJson(jsonData);

      setState(() {
        _productRequests = apiResponse.results;
        _isLoading = false;
      });

      print('Successfully loaded ${_productRequests.length} requests');
    } else {
      setState(() {
        _error = 'Failed to load requests: HTTP ${response.statusCode}';
        _isLoading = false;
      });
    }
  } catch (e) {
    print('Exception occurred: $e');
    setState(() {
      _error = 'Network Error: $e';
      _isLoading = false;
    });
  }
}
```

## 🔍 Troubleshooting

### Issue: Script Fails at Prerequisites
**Solution:**
```bash
# Install missing tools
# For macOS:
brew install azure-cli
brew install kubectl
brew install docker

# For Ubuntu/Debian:
apt-get install azure-cli kubectl docker.io
```

### Issue: Azure Login Failed
**Solution:**
```bash
# Clear Azure cache and re-login
az logout
az login --use-device-code
```

### Issue: Cannot Connect to Kubernetes
**Solution:**
```bash
# Get AKS credentials
az aks get-credentials --resource-group bidr-dev-k8s --name BIDR-dev-aks-cluster --overwrite-existing

# Verify connection
kubectl get pods -n bidr
```

### Issue: Docker Build Fails
**Solution:**
```bash
# Check Docker daemon
docker info

# Clean up Docker
docker system prune -f

# Try building manually
cd product_management_service
docker build -t test-image .
```

### Issue: Deployment Rollback Needed
**Solution:**
```bash
# Use the rollback flag
./deploy_product_service_cors_fix.sh --rollback

# Or rollback manually
kubectl rollout undo deployment/product-service -n bidr
```

## 📋 Expected Results

After successful deployment:

✅ **API Endpoints Available:**
- Product Service: http://108.141.192.60:8004/
- Product API: http://108.141.192.60:8004/products/api/v1/product-requests/requests/
- Admin Panel: http://108.141.192.60:8004/admin/
- API Docs: http://108.141.192.60:8004/swagger/

✅ **CORS Headers Present:**
- `Access-Control-Allow-Origin: *`
- `Access-Control-Allow-Methods: GET, POST, PUT, PATCH, DELETE, OPTIONS`
- `Access-Control-Allow-Headers: accept, authorization, content-type, ...`

✅ **Flutter Web Working:**
- No more `ClientException: Failed to fetch` errors
- Successful API responses with data

## 🎉 Success Verification

Your Flutter web app should now be able to successfully fetch data from the API without CORS errors!

## 📞 If You Need Help

If the deployment fails or CORS issues persist:

1. **Check deployment logs:**
   ```bash
   kubectl logs -n bidr deployment/product-service
   ```

2. **Check pod status:**
   ```bash
   kubectl get pods -n bidr -l app=product-service
   kubectl describe pod -n bidr [POD_NAME]
   ```

3. **Verify CORS headers:**
   ```bash
   curl -I -H "Origin: http://localhost:8080" http://108.141.192.60:8004/products/api/v1/product-requests/requests/
   ```

The key is that your **Kubernetes deployment needs to be updated** with the new CORS configuration for the changes to take effect!
