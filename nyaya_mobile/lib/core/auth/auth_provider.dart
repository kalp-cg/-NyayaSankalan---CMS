// NyayaSankalan - Authentication Provider
// Manages authentication state with real API integration

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../types/enums.dart';
import '../types/models.dart';
import '../services/secure_storage_service.dart';
import '../network/api_client.dart';

// Auth state class
class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final String? error;
  final User? user;
  final UserRole? role;

  const AuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.error,
    this.user,
    this.role,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    String? error,
    User? user,
    UserRole? role,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      user: user ?? this.user,
      role: role ?? this.role,
    );
  }

  static const unauthenticated = AuthState();
}

// Auth notifier
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState.unauthenticated) {
    _checkAuthStatus();
  }

  final _apiClient = ApiClient();

  // Check if user is already logged in
  Future<void> _checkAuthStatus() async {
    final isLoggedIn = await SecureStorageService.isLoggedIn();
    if (isLoggedIn) {
      final userData = await SecureStorageService.getUserData();
      final role = _parseUserRole(userData['role']);
      state = AuthState(isAuthenticated: true, role: role);
    }
  }

  // Login with email and password
  Future<bool> login({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Debug: Print the API URL being used
      debugPrint('Connecting to: ${_apiClient.dio.options.baseUrl}/auth/login');

      final response = await _apiClient.dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        final token = data['token'];
        final userData = data['user'];

        // Save to secure storage
        await SecureStorageService.saveToken(token);
        await SecureStorageService.saveUserData(
          userId: userData['id'],
          role: userData['role'],
          email: userData['email'],
          name: userData['name'],
        );

        // Update state
        final user = User.fromJson(userData);
        state = AuthState(isAuthenticated: true, user: user, role: user.role);

        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response.data['error'] ?? 'Login failed',
        );
        return false;
      }
    } on DioException catch (e) {
      String errorMessage;

      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          errorMessage =
              'Connection timed out.\n\n'
              'Please check:\n'
              '1. Backend is running: cd backend && npm run dev\n'
              '2. Your IP address is correct in app_env.dart\n'
              '3. Port 5000 is not blocked by firewall\n\n'
              'Current URL: ${_apiClient.dio.options.baseUrl}';
          break;
        case DioExceptionType.connectionError:
          errorMessage =
              'Cannot connect to server.\n\n'
              'Please check:\n'
              '1. Backend is running on port 5000\n'
              '2. Correct IP in app_env.dart (use your computer IP, not localhost)\n'
              '3. Both devices are on same network\n\n'
              'Current URL: ${_apiClient.dio.options.baseUrl}\n\n'
              'To find your IP: run "hostname -I" in terminal';
          break;
        case DioExceptionType.badResponse:
          if (e.response?.statusCode == 401) {
            errorMessage = 'Invalid email or password';
          } else if (e.response?.statusCode == 400) {
            errorMessage =
                e.response?.data?['error']?.toString() ?? 'Invalid request';
          } else {
            errorMessage = 'Server error: ${e.response?.statusCode}';
          }
          break;
        default:
          errorMessage = 'Network error: ${e.message}';
      }

      debugPrint('❌ Login error: ${e.type} - ${e.message}');

      state = state.copyWith(isLoading: false, error: errorMessage);
      return false;
    } catch (e) {
      debugPrint('❌ Unexpected error: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Unexpected error: ${e.toString()}',
      );
      return false;
    }
  }

  // Register new user
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    required UserRole role,
    required String organizationId,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _apiClient.dio.post(
        '/auth/register',
        data: {
          'name': name,
          'email': email,
          'password': password,
          'phone': phone,
          'role': role.shortName,
          'organizationId': organizationId,
        },
      );

      if (response.statusCode == 201 && response.data['success'] == true) {
        state = state.copyWith(isLoading: false);
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response.data['error'] ?? 'Registration failed',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Network error: ${e.toString()}',
      );
      return false;
    }
  }

  // Get current user profile
  Future<void> fetchCurrentUser() async {
    try {
      final response = await _apiClient.dio.get('/auth/me');
      if (response.statusCode == 200 && response.data['success'] == true) {
        final user = User.fromJson(response.data['data']);
        state = state.copyWith(user: user);
      }
    } catch (e) {
      // Silently fail - user data not critical
    }
  }

  // Logout
  Future<void> logout() async {
    await SecureStorageService.clearUserData();
    state = AuthState.unauthenticated;
  }

  // Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  UserRole _parseUserRole(String? value) {
    final str = value?.toLowerCase() ?? '';
    return UserRole.values.firstWhere(
      (e) => e.name.toLowerCase() == str,
      orElse: () => UserRole.police,
    );
  }
}

// Provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

// Derived providers
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAuthenticated;
});

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authProvider).user;
});

final currentUserRoleProvider = Provider<UserRole?>((ref) {
  return ref.watch(authProvider).role;
});
