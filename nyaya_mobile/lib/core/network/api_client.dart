import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/app_env.dart';
import '../services/secure_storage_service.dart';

class ApiClient {
  ApiClient._() : _dio = _createDio();

  static final ApiClient _instance = ApiClient._();

  factory ApiClient() => _instance;

  late final Dio _dio;

  Dio get dio => _dio;

  static Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: AppEnv.effectiveApiBaseUrl,
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
        sendTimeout: const Duration(seconds: 60),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add interceptors
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Debug: Print request details
          debugPrint('🌐 REQUEST: ${options.method} ${options.path}');
          debugPrint('📍 Base URL: ${options.baseUrl}');

          // Add auth token if available
          final token = await SecureStorageService.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
            debugPrint('🔑 Token added to request');
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          debugPrint(
            '✅ RESPONSE: ${response.statusCode} ${response.requestOptions.path}',
          );
          return handler.next(response);
        },
        onError: (error, handler) async {
          debugPrint('❌ ERROR: ${error.type} - ${error.message}');
          debugPrint(
            '📍 URL: ${error.requestOptions.baseUrl}${error.requestOptions.path}',
          );

          // Handle 401 - token expired
          if (error.response?.statusCode == 401) {
            await SecureStorageService.clearUserData();
            debugPrint('🔒 Token cleared due to 401');
          }
          return handler.next(error);
        },
      ),
    );

    return dio;
  }

  // Method to refresh dio instance (useful after login/logout)
  void refresh() {
    _dio.options.headers.remove('Authorization');
  }
}
