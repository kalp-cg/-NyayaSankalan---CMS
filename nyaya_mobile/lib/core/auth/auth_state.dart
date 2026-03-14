import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../types/enums.dart';

class AuthState {
  const AuthState({
    required this.isAuthenticated,
    this.role,
  });

  final bool isAuthenticated;
  final UserRole? role;

  AuthState copyWith({
    bool? isAuthenticated,
    UserRole? role,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      role: role ?? this.role,
    );
  }

  static const unauthenticated = AuthState(isAuthenticated: false);
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState.unauthenticated);

  void loginAs(UserRole role) {
    state = AuthState(isAuthenticated: true, role: role);
  }

  void logout() {
    state = AuthState.unauthenticated;
  }
}

final authProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) => AuthNotifier());

