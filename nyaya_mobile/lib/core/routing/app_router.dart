import 'package:flutter/material.dart';

import '../../features/auth/presentation/login_screen.dart';
import '../../features/dashboard/presentation/dashboard_shell.dart';
import '../../features/public_cases/presentation/public_resolved_cases_screen.dart';
import '../auth/auth_provider.dart';

class AppRoutes {
  const AppRoutes._();

  static const String login = '/login';
  static const String home = '/home';
  static const String publicResolvedCases = '/public-resolved-cases';
  static const String caseDetail = '/case-detail';
  static const String firDetail = '/fir-detail';
  static const String registerFIR = '/register-fir';
  static const String aiChat = '/ai-chat';
  static const String aiOCR = '/ai-ocr';
  static const String search = '/search';
}

Route<dynamic> onGenerateRoute(RouteSettings settings, AuthState authState) {
  Widget page;

  // If not authenticated, only allow login and public routes
  if (!authState.isAuthenticated) {
    switch (settings.name) {
      case AppRoutes.publicResolvedCases:
        page = const PublicResolvedCasesScreen();
        break;
      case AppRoutes.login:
      default:
        page = const LoginScreen();
        break;
    }
    return MaterialPageRoute<void>(
      builder: (_) => page,
      settings: settings,
    );
  }

  // Authenticated routes
  switch (settings.name) {
    case AppRoutes.login:
      // Redirect to home if already logged in
      page = const DashboardShell();
      break;
    case AppRoutes.publicResolvedCases:
      page = const PublicResolvedCasesScreen();
      break;
    case AppRoutes.home:
    default:
      page = const DashboardShell();
      break;
  }

  return MaterialPageRoute<void>(
    builder: (_) => page,
    settings: settings,
  );
}

