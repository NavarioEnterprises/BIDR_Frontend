# Flutter Web CORS Solution Guide

## 🎯 Issue Summary

Flutter Web is getting `ClientException: Failed to fetch` when trying to access your Django API, even though Postman works fine. This is a **CORS (Cross-Origin Resource Sharing)** issue specific to web browsers.

## ✅ What We've Fixed

### 1. Enhanced Django CORS Settings

Updated `/product_management_service/product_management_service/settings.py` with comprehensive CORS configuration:

```python
# CORS Configuration for Flutter Web
CORS_ALLOWED_ORIGINS = [
    "http://localhost:3000",
    "http://127.0.0.1:3000",
    "http://localhost:3001",
    "http://127.0.0.1:3001",
    # Flutter web common ports
    "http://localhost:8080",
    "http://127.0.0.1:8080",
    "http://localhost:5000",
    "http://127.0.0.1:5000",
    "http://localhost:4200",
    "http://127.0.0.1:4200",
]

# Allow all origins in development (important for Flutter web)
CORS_ALLOW_ALL_ORIGINS = True  # Changed from DEBUG to True for testing

# Enable credentials
CORS_ALLOW_CREDENTIALS = True

# Allow all headers (important for Flutter web)
CORS_ALLOW_ALL_HEADERS = True

# Allow all methods
CORS_ALLOW_ALL_METHODS = True

# Additional CORS headers for Flutter web compatibility
CORS_ALLOWED_HEADERS = [
    'accept',
    'accept-encoding',
    'authorization',
    'content-type',
    'dnt',
    'origin',
    'user-agent',
    'x-csrftoken',
    'x-requested-with',
    'access-control-allow-origin',
    'access-control-allow-headers',
    'access-control-allow-methods',
]

# Expose headers that Flutter web might need
CORS_EXPOSE_HEADERS = [
    'content-type',
    'x-csrftoken',
]

# CSRF settings for API
CSRF_TRUSTED_ORIGINS = [
    "http://localhost:3000",
    "http://127.0.0.1:3000",
    "http://localhost:8080",
    "http://127.0.0.1:8080",
    "http://localhost:5000",
    "http://127.0.0.1:5000",
    "http://localhost:4200",
    "http://127.0.0.1:4200",
]

# Disable CSRF for API endpoints (since we're using DRF with token auth)
CSRF_USE_SESSIONS = False
CSRF_COOKIE_HTTPONLY = False
```

### 2. Added CORS Mixin to Views

Created `/core/cors_decorators.py` with a `CORSMixin` class and applied it to `ProductRequestViewSet` for additional CORS header management.

### 3. Test Verification

Created `test_flutter_cors.py` which confirms CORS is working correctly.

## 🚀 Required Actions

### Step 1: Restart Django Server

**IMPORTANT**: The Django server needs to be restarted to pick up the new settings:

```bash
# Stop the current Django server (Ctrl+C)
# Then restart it:
cd "product_management_service"
python manage.py runserver 0.0.0.0:8000
```

### Step 2: Update Flutter Web Code

Update your Flutter web code to ensure proper headers:

```dart
Future<void> _fetchProductRequests() async {
  setState(() {
    _isLoading = true;
    _error = null;
  });

  try {
    print('Attempting to fetch from: http://108.141.192.60/products/api/v1/product-requests/requests/');

    // Use a standard GET request instead of custom Request
    final response = await http.get(
      Uri.parse('http://108.141.192.60/products/api/v1/product-requests/requests/'),
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

      print('Parsed ${apiResponse.results.length} requests from API');

      // Clear existing requests
      GlobalVariables.combinedRequest.autoSparesRequest.clear();
      GlobalVariables.combinedRequest.rimTyreRequest.clear();
      GlobalVariables.combinedRequest.consumerElectronicsRequest.clear();

      setState(() {
        _productRequests = apiResponse.results;
        _isLoading = false;
      });

      // Populate GlobalVariables with API data
      for (var item in apiResponse.results) {
        _populateGlobalVariables(item);
      }

      print('Successfully loaded ${_productRequests.length} requests');
    } else {
      print('HTTP Error: ${response.statusCode} - ${response.reasonPhrase}');
      setState(() {
        _error = 'Failed to load requests: HTTP ${response.statusCode}\n${response.reasonPhrase ?? 'Unknown error'}';
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

### Step 3: Check Flutter Web Port

Find out what port your Flutter web is running on:

```bash
# When you run flutter run -d chrome, look for output like:
# "A web server started at http://localhost:8080"
flutter run -d chrome --web-port 8080
```

### Step 4: Verify CORS Test

After restarting the Django server, run our CORS test:

```bash
cd "BIDR_Backend"
python test_flutter_cors.py
```

## 🔧 Alternative Solutions

### Option 1: Flutter Web with --web-browser-flag

Run Flutter web with disabled web security (ONLY for development):

```bash
flutter run -d chrome --web-browser-flag="--disable-web-security"
```

### Option 2: Use Flutter Web Proxy

Add a proxy configuration to your Flutter web development:

```dart
// In your main.dart or http service
const String baseUrl = kDebugMode 
    ? 'http://localhost:8000'  // Local development
    : 'http://108.141.192.60'; // Production
```

### Option 3: Django Dev Server on Different Port

If the issue persists, try running Django on port 8000 with explicit host:

```bash
cd product_management_service
python manage.py runserver 0.0.0.0:8000
```

## 🧪 Testing the Fix

### Test 1: Direct Browser Test
Open your Flutter web browser and navigate to:
`http://108.141.192.60/products/api/v1/product-requests/requests/`

You should see JSON data.

### Test 2: Browser Console Test
In Flutter web's browser console, run:

```javascript
fetch('http://108.141.192.60/products/api/v1/product-requests/requests/')
  .then(response => response.json())
  .then(data => console.log(data))
  .catch(error => console.error('Error:', error));
```

### Test 3: Flutter Web Logs
Check Flutter web logs for CORS errors:
- Open browser Developer Tools (F12)
- Look in Console tab for CORS-related errors
- Check Network tab to see if preflight OPTIONS requests are successful

## 📋 Troubleshooting Checklist

- [ ] Django server restarted with new CORS settings
- [ ] Flutter web using correct URL with trailing slash
- [ ] Flutter web running on port 8080 or one of the configured ports
- [ ] Browser console shows no CORS errors
- [ ] Network tab shows successful OPTIONS preflight requests
- [ ] API returns 200 status in browser direct access

## 🎉 Expected Result

After implementing these changes and restarting the Django server, your Flutter web app should successfully fetch data from the API without CORS errors.

## 📞 If Still Not Working

If the issue persists after following all steps:

1. **Check Django logs** for any CORS-related errors
2. **Verify middleware order** - CORS middleware should be first
3. **Try a simple curl test** to confirm server is working
4. **Check if there's a reverse proxy** (nginx/apache) that might be stripping CORS headers

The key is that **Django server must be restarted** for the new CORS settings to take effect!
