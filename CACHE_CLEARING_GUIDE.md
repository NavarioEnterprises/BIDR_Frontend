# Flutter Web Cache Clearing Guide

This guide provides multiple methods to clear Flutter web cache and ensure users always see the latest version.

## Quick Scripts

### 1. Full Cache Clear (Production)
```bash
./clear_flutter_cache.sh
```
- Comprehensive cache clearing
- Rebuilds entire application
- Clears all Flutter and browser caches

### 2. Development Cache Clear (Quick)
```bash
./dev_clear_cache.sh
```
- Quick cache clear for development
- Faster rebuild process
- Creates version timestamp

## Manual Browser Cache Clearing

### Chrome/Chromium
1. **Hard Refresh**: `Cmd+Shift+R` (Mac) / `Ctrl+Shift+R` (Windows/Linux)
2. **Developer Tools**: 
   - Open DevTools (`F12`)
   - Right-click refresh button
   - Select "Empty Cache and Hard Reload"
3. **Settings Method**:
   - Settings → Privacy and Security → Clear browsing data
   - Select "Cached images and files"

### Safari
1. **Hard Refresh**: `Cmd+Shift+R`
2. **Developer Menu**:
   - Enable Developer menu in Preferences
   - Develop → Empty Caches
3. **Manual Clear**:
   - Safari → Preferences → Privacy → Manage Website Data
   - Remove data for your localhost/domain

### Firefox
1. **Hard Refresh**: `Ctrl+F5` / `Cmd+Shift+R`
2. **Developer Tools**:
   - Open DevTools (`F12`)
   - Network tab → Settings gear → "Disable Cache"
3. **Manual Clear**:
   - Preferences → Privacy & Security → Clear Data

## Programmatic Solutions

### 1. Cache Control Headers
Added to `index.html`:
```html
<meta http-equiv="Cache-Control" content="no-cache, no-store, must-revalidate">
<meta http-equiv="Pragma" content="no-cache">
<meta http-equiv="Expires" content="0">
```

### 2. Service Worker Cache Clearing
Automatic service worker unregistration on page load (already added to index.html).

### 3. Version-based Cache Busting
Using timestamp-based versioning to force cache invalidation.

## Production Deployment Tips

### 1. Server Configuration
Add cache control headers on your web server:

#### Nginx
```nginx
location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
    add_header Cache-Control "public, max-age=31536000, immutable";
}

location /index.html {
    add_header Cache-Control "no-cache, no-store, must-revalidate";
}
```

#### Apache
```apache
# Cache assets for 1 year
<FilesMatch "\.(js|css|png|jpg|jpeg|gif|ico|svg)$">
    Header set Cache-Control "public, max-age=31536000, immutable"
</FilesMatch>

# Don't cache HTML
<FilesMatch "\.html$">
    Header set Cache-Control "no-cache, no-store, must-revalidate"
</FilesMatch>
```

### 2. Build with Version Hashing
Flutter automatically adds content hashes to built files, but you can enhance this:

```bash
flutter build web --dart-define=FLUTTER_WEB_BUILD_VERSION=$(date +%s)
```

## Testing Cache Clearing

### 1. Incognito/Private Mode
Always test in private browsing mode to ensure no cached data.

### 2. Network Tab
Use browser DevTools Network tab with "Disable cache" option enabled.

### 3. Different Browsers
Test across multiple browsers to ensure consistent behavior.

## Troubleshooting

### Cache Still Present?
1. Check if service workers are registered: `chrome://serviceworker-internals/`
2. Clear all site data: `chrome://settings/content/all`
3. Try different port: `flutter run -d chrome --web-port 8081`

### Build Issues?
1. Delete `build/` folder manually
2. Run `flutter doctor` to check for issues
3. Clear Dart analysis cache: `rm -rf .dart_tool/`

## Automation

### Git Pre-commit Hook
Add to `.git/hooks/pre-commit`:
```bash
#!/bin/bash
# Auto-increment version on commit
echo "window.BUILD_VERSION = '$(git rev-parse --short HEAD)';" > web/version.js
git add web/version.js
```

### CI/CD Integration
Include cache clearing in your deployment pipeline:
```yaml
- name: Clear Flutter Cache
  run: |
    flutter clean
    flutter pub get
    flutter build web --release
```

---

## Quick Reference Commands

```bash
# Full clean
flutter clean && flutter pub get && flutter build web

# Clear pub cache
flutter pub cache clean

# Clear all Flutter caches
rm -rf ~/.flutter/web_sdk ~/.dartServer ~/.flutter/.download-cache

# Hard browser refresh
# Chrome/Safari: Cmd+Shift+R (Mac) / Ctrl+Shift+R (Windows)
# Firefox: Ctrl+F5

# Test in private mode
# Chrome: Cmd+Shift+N (Mac) / Ctrl+Shift+N (Windows)
# Safari: Cmd+Shift+N
# Firefox: Cmd+Shift+P (Mac) / Ctrl+Shift+P (Windows)
```