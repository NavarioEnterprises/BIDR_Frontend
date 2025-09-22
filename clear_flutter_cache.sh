#!/bin/bash

# Flutter Web Cache Clear Script
# This script clears various Flutter web caches and forces a fresh build

echo "🧹 Starting Flutter Web Cache Clearing Process..."
echo "================================================"

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if Flutter is installed
if ! command_exists flutter; then
    echo "❌ Error: Flutter is not installed or not in PATH"
    exit 1
fi

echo "📍 Current directory: $(pwd)"
echo ""

# 1. Clean Flutter build cache
echo "🗂️  Step 1: Cleaning Flutter build cache..."
flutter clean
echo "✅ Flutter clean completed"
echo ""

# 2. Clear pub cache (optional - comment out if you don't want to re-download packages)
echo "📦 Step 2: Clearing pub cache..."
flutter pub cache clean
echo "✅ Pub cache cleared"
echo ""

# 3. Get dependencies fresh
echo "🔄 Step 3: Getting fresh dependencies..."
flutter pub get
echo "✅ Dependencies refreshed"
echo ""

# 4. Clear system Flutter cache
echo "🧹 Step 4: Clearing system Flutter cache..."
# Clear Flutter's web compilation cache
if [ -d "$HOME/.flutter/web_sdk" ]; then
    rm -rf "$HOME/.flutter/web_sdk"
    echo "✅ Web SDK cache cleared"
fi

# Clear Dart compilation cache
if [ -d "$HOME/.dartServer" ]; then
    rm -rf "$HOME/.dartServer"
    echo "✅ Dart server cache cleared"
fi

# Clear Flutter tool cache
if [ -d "$HOME/.flutter/.download-cache" ]; then
    rm -rf "$HOME/.flutter/.download-cache"
    echo "✅ Download cache cleared"
fi
echo ""

# 5. Clear browser cache directories (optional)
echo "🌐 Step 5: Clearing browser cache (Chrome/Safari)..."
# Chrome cache (macOS)
if [ -d "$HOME/Library/Caches/Google/Chrome" ]; then
    echo "⚠️  Found Chrome cache directory. You may want to clear it manually."
fi

# Safari cache (macOS)
if [ -d "$HOME/Library/Caches/com.apple.Safari" ]; then
    echo "⚠️  Found Safari cache directory. You may want to clear it manually."
fi
echo ""

# 6. Build fresh web version
echo "🏗️  Step 6: Building fresh web version..."
flutter build web --web-renderer html --dart-define=FLUTTER_WEB_USE_SKIA=false --release
echo "✅ Fresh web build completed"
echo ""

# 7. Optional: Create a version timestamp file for cache busting
echo "📝 Step 7: Creating version timestamp for cache busting..."
echo "const BUILD_TIMESTAMP = '$(date +%s)';" > web/build_timestamp.js
echo "✅ Build timestamp created: $(date)"
echo ""

echo "🎉 Flutter Web Cache Clearing Complete!"
echo "================================================"
echo "✅ All caches cleared and fresh build created"
echo "💡 Tips for preventing cache issues:"
echo "   • Use hard refresh (Cmd+Shift+R / Ctrl+Shift+R) in browser"
echo "   • Open in incognito/private mode for testing"
echo "   • Clear browser data for your localhost/domain"
echo ""