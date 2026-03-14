import 'package:flutter/foundation.dart';

class AppEnv {
  const AppEnv._();

  /// Base URL for the existing NyayaSankalan backend.
  ///
  /// IMPORTANT: Use your computer's IP address for testing on devices
  /// Find your IP: hostname -I
  ///
  /// For Web (Chrome): 'http://localhost:5000/api'
  /// For Android Emulator: 'http://10.0.2.2:5000/api'
  /// For Physical Device: 'http://YOUR_COMPUTER_IP:5000/api'
  ///
  /// NOTE: If you're getting connection timeouts on web, try these:
  /// 1. Use 'http://127.0.0.1:5000/api' instead of localhost
  /// 2. Use your computer's actual IP: 'http://10.12.252.37:5000/api'
  /// 3. Make sure backend is running: cd backend && npm run dev
  static String get apiBaseUrl {
    if (kIsWeb) {
      // Running on web (Chrome)
      // Try localhost first, if that fails use 127.0.0.1 or your IP
      return 'http://localhost:5000/api';
    }
    // For Android emulator
    return 'http://10.0.2.2:5000/api';
  }

  /// Alternative URLs to try if the default doesn't work
  static const List<String> alternativeUrls = [
    'http://127.0.0.1:5000/api',
    'http://10.12.252.30:5000/api', // Your computer's IP
    'http://localhost:5000/api',
  ];

  /// Set a custom API URL (useful for testing on physical devices)
  static String? _customUrl;

  static void setCustomUrl(String url) {
    _customUrl = url;
    debugPrint('🔧 Custom API URL set: $url');
  }

  static String get effectiveApiBaseUrl => _customUrl ?? apiBaseUrl;
}
