#!/bin/bash

# Development Cache Clear Script for Flutter Web
# Quick script for development use

echo "🚀 Quick Development Cache Clear..."

# Quick Flutter clean and build
flutter clean
flutter pub get
flutter build web --web-renderer html --dart-define=FLUTTER_WEB_USE_SKIA=false

# Create cache-busting version
echo "window.APP_VERSION = '$(date +%s)';" > web/version.js

echo "✅ Development cache cleared! Use Cmd+Shift+R to hard refresh browser."