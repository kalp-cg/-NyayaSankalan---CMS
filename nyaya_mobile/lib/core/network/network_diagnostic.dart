// NyayaSankalan - Network Diagnostic Tool
// Helps debug connection issues between mobile app and backend

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/app_env.dart';

class NetworkDiagnostic {
  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  /// Test all possible backend URLs and return the working one
  static Future<DiagnosticResult> findWorkingUrl() async {
    final urls = [AppEnv.apiBaseUrl, ...AppEnv.alternativeUrls];

    debugPrint('🔍 Testing ${urls.length} possible backend URLs...\n');

    for (final url in urls) {
      final result = await _testUrl(url);
      if (result.isWorking) {
        debugPrint('✅ FOUND WORKING URL: $url\n');
        return result;
      }
    }

    // None worked - return detailed error
    return DiagnosticResult(
      isWorking: false,
      url: AppEnv.apiBaseUrl,
      error:
          'No working backend URL found.\n\n'
          'Tried URLs:\n${urls.map((u) => '  - $u').join('\n')}\n\n'
          'Troubleshooting:\n'
          '1. Make sure backend is running: cd backend && npm run dev\n'
          '2. Check your computer IP: hostname -I\n'
          '3. Update app_env.dart with correct IP\n'
          '4. Ensure both devices are on same network\n'
          '5. Check firewall settings for port 5000',
    );
  }

  /// Test a specific URL
  static Future<DiagnosticResult> _testUrl(String baseUrl) async {
    try {
      // Strip /api suffix to hit the root /health endpoint
      final rootUrl = baseUrl.replaceAll(RegExp(r'/api$'), '');
      debugPrint('Testing: $rootUrl/health');

      final response = await _dio.get('$rootUrl/health');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>?;
        final status = data?['status'] ?? 'unknown';

        return DiagnosticResult(
          isWorking: true,
          url: baseUrl,
          message: 'Backend is healthy (status: $status)',
        );
      } else {
        return DiagnosticResult(
          isWorking: false,
          url: baseUrl,
          error: 'HTTP ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      String errorDetail;
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
          errorDetail = 'Connection timeout';
          break;
        case DioExceptionType.connectionError:
          errorDetail = 'Connection refused';
          break;
        case DioExceptionType.badResponse:
          errorDetail = 'Bad response: ${e.response?.statusCode}';
          break;
        default:
          errorDetail = e.message ?? 'Unknown error';
      }

      return DiagnosticResult(
        isWorking: false,
        url: baseUrl,
        error: errorDetail,
      );
    } catch (e) {
      return DiagnosticResult(
        isWorking: false,
        url: baseUrl,
        error: 'Exception: $e',
      );
    }
  }

  /// Get network configuration info
  static Map<String, String> getNetworkInfo() {
    return {
      'Current API URL': AppEnv.apiBaseUrl,
      'Platform': kIsWeb ? 'Web' : 'Mobile',
      'Alternative URLs': AppEnv.alternativeUrls.join(', '),
    };
  }
}

class DiagnosticResult {
  final bool isWorking;
  final String url;
  final String? message;
  final String? error;

  DiagnosticResult({
    required this.isWorking,
    required this.url,
    this.message,
    this.error,
  });
}
