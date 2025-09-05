#!/bin/bash

# Flutter Web Deployment Script with macOS Compatibility Fixes
echo "Building Flutter web with macOS compatibility..."

# Clean and build
flutter clean
flutter pub get
flutter build web --release --base-href="/bidr/" --no-tree-shake-icons --no-wasm-dry-run

# Copy .htaccess to build directory for proper MIME types
cp web/.htaccess build/web/

# Create a simple server test script
cat > build/web/test_server.py << 'EOF'
#!/usr/bin/env python3
import http.server
import socketserver
from pathlib import Path
import mimetypes

# Add proper MIME types for all image formats
mimetypes.add_type('image/png', '.png')
mimetypes.add_type('image/jpeg', '.jpg')
mimetypes.add_type('image/jpeg', '.jpeg')
mimetypes.add_type('image/gif', '.gif')
mimetypes.add_type('image/webp', '.webp')
mimetypes.add_type('image/svg+xml', '.svg')
mimetypes.add_type('image/avif', '.avif')

class CustomHTTPRequestHandler(http.server.SimpleHTTPRequestHandler):
    def guess_type(self, path):
        """Return a type of the file, using our custom MIME types."""
        mimetype, encoding = mimetypes.guess_type(path)
        return mimetype, encoding
    
    def end_headers(self):
        # Add CORS headers for all responses
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        
        # Add cache control for assets
        if any(self.path.endswith(ext) for ext in ['.png', '.jpg', '.jpeg', '.gif', '.webp', '.svg']):
            self.send_header('Cache-Control', 'public, max-age=31536000')
        
        super().end_headers()

PORT = 8080
Handler = CustomHTTPRequestHandler

with socketserver.TCPServer(("", PORT), Handler) as httpd:
    print(f"Server running at http://localhost:{PORT}")
    print("Test this on your macOS to verify image loading")
    httpd.serve_forever()
EOF

chmod +x build/web/test_server.py

echo "Build complete!"
echo ""
echo "Deploy the contents of build/web/ to your web server."
echo "Make sure your web server:"
echo "1. Serves proper MIME types for images"
echo "2. Includes CORS headers for asset requests"
echo "3. Has cache control headers for performance"
echo ""
echo "To test locally on macOS, run:"
echo "  cd build/web && python3 test_server.py"