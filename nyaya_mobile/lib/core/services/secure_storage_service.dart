// NyayaSankalan - Secure Storage Service
// Handles JWT tokens and sensitive data securely

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accountName: 'nyaya_sankalan',
    ),
  );

  static const _tokenKey = 'jwt_token';
  static const _userIdKey = 'user_id';
  static const _userRoleKey = 'user_role';
  static const _userEmailKey = 'user_email';
  static const _userNameKey = 'user_name';

  // Token operations
  static Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  static Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }

  // User data operations
  static Future<void> saveUserData({
    required String userId,
    required String role,
    required String email,
    required String name,
  }) async {
    await Future.wait([
      _storage.write(key: _userIdKey, value: userId),
      _storage.write(key: _userRoleKey, value: role),
      _storage.write(key: _userEmailKey, value: email),
      _storage.write(key: _userNameKey, value: name),
    ]);
  }

  static Future<Map<String, String?>> getUserData() async {
    final results = await Future.wait([
      _storage.read(key: _userIdKey),
      _storage.read(key: _userRoleKey),
      _storage.read(key: _userEmailKey),
      _storage.read(key: _userNameKey),
    ]);

    return {
      'userId': results[0],
      'role': results[1],
      'email': results[2],
      'name': results[3],
    };
  }

  static Future<void> clearUserData() async {
    await _storage.deleteAll();
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
