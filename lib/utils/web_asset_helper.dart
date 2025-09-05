import 'package:flutter/foundation.dart';

class WebAssetHelper {
  /// Ensures proper asset loading on all web platforms including macOS Safari
  static String getAssetPath(String assetPath) {
    if (kIsWeb) {
      // For web platforms, ensure proper asset path resolution
      if (assetPath.startsWith('lib/')) {
        // Remove 'lib/' prefix for web builds
        return 'assets/${assetPath.substring(4)}';
      }
      if (assetPath.startsWith('assets/')) {
        return assetPath;
      }
      return 'assets/$assetPath';
    }
    return assetPath;
  }
  
  /// Force reload assets for Safari compatibility
  static String getCacheBypassAsset(String assetPath) {
    if (kIsWeb) {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final processedPath = getAssetPath(assetPath);
      return '$processedPath?v=$timestamp';
    }
    return assetPath;
  }
}