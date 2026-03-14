// NyayaSankalan - Dashboard Shell
// Main app shell with bottom navigation based on user role

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_provider.dart';
import '../../../core/types/enums.dart';
import '../../cases/presentation/case_list_screen.dart';
import '../../cases/presentation/fir_list_screen.dart';
import '../../ai/presentation/ai_features_screen.dart';
import '../../notifications/presentation/notifications_screen.dart';
import '../../profile/presentation/profile_screen.dart';

class DashboardShell extends ConsumerStatefulWidget {
  const DashboardShell({super.key});

  @override
  ConsumerState<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends ConsumerState<DashboardShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(currentUserRoleProvider);

    if (role == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final navigationItems = _getNavigationItems(role);
    final screens = _getScreens(role);

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: navigationItems,
      ),
    );
  }

  List<NavigationDestination> _getNavigationItems(UserRole role) {
    switch (role) {
      case UserRole.police:
        return const [
          NavigationDestination(
            icon: Icon(Icons.folder_outlined),
            selectedIcon: Icon(Icons.folder),
            label: 'My Cases',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment),
            label: 'FIRs',
          ),
          NavigationDestination(
            icon: Icon(Icons.smart_toy_outlined),
            selectedIcon: Icon(Icons.smart_toy),
            label: 'AI Tools',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications),
            label: 'Alerts',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ];
      case UserRole.sho:
        return const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_outlined),
            selectedIcon: Icon(Icons.folder),
            label: 'Cases',
          ),
          NavigationDestination(
            icon: Icon(Icons.smart_toy_outlined),
            selectedIcon: Icon(Icons.smart_toy),
            label: 'AI Tools',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications),
            label: 'Alerts',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ];
      case UserRole.courtClerk:
        return const [
          NavigationDestination(
            icon: Icon(Icons.gavel_outlined),
            selectedIcon: Icon(Icons.gavel),
            label: 'Court',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_outlined),
            selectedIcon: Icon(Icons.folder),
            label: 'Cases',
          ),
          NavigationDestination(
            icon: Icon(Icons.smart_toy_outlined),
            selectedIcon: Icon(Icons.smart_toy),
            label: 'AI Tools',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications),
            label: 'Alerts',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ];
      case UserRole.judge:
        return const [
          NavigationDestination(
            icon: Icon(Icons.balance_outlined),
            selectedIcon: Icon(Icons.balance),
            label: 'Bench',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_outlined),
            selectedIcon: Icon(Icons.folder),
            label: 'Cases',
          ),
          NavigationDestination(
            icon: Icon(Icons.smart_toy_outlined),
            selectedIcon: Icon(Icons.smart_toy),
            label: 'AI Tools',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications),
            label: 'Alerts',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ];
    }
  }

  List<Widget> _getScreens(UserRole role) {
    switch (role) {
      case UserRole.police:
        return [
          const CaseListScreen(role: UserRole.police),
          const FIRListScreen(),
          const AIFeaturesScreen(),
          const NotificationsScreen(),
          const ProfileScreen(),
        ];
      case UserRole.sho:
        return [
          const SHODashboardScreen(),
          const CaseListScreen(role: UserRole.sho),
          const AIFeaturesScreen(),
          const NotificationsScreen(),
          const ProfileScreen(),
        ];
      case UserRole.courtClerk:
        return [
          const CourtOperationsScreen(),
          const CaseListScreen(role: UserRole.courtClerk),
          const AIFeaturesScreen(),
          const NotificationsScreen(),
          const ProfileScreen(),
        ];
      case UserRole.judge:
        return [
          const JudgeBenchScreen(),
          const CaseListScreen(role: UserRole.judge),
          const AIFeaturesScreen(),
          const NotificationsScreen(),
          const ProfileScreen(),
        ];
    }
  }
}

// Placeholder screens - will be implemented separately
class SHODashboardScreen extends StatelessWidget {
  const SHODashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SHO Dashboard'),
      ),
      body: const Center(
        child: Text('SHO Dashboard - Coming Soon'),
      ),
    );
  }
}

class CourtOperationsScreen extends StatelessWidget {
  const CourtOperationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Court Operations'),
      ),
      body: const Center(
        child: Text('Court Operations - Coming Soon'),
      ),
    );
  }
}

class JudgeBenchScreen extends StatelessWidget {
  const JudgeBenchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Judge Bench'),
      ),
      body: const Center(
        child: Text('Judge Bench - Coming Soon'),
      ),
    );
  }
}
