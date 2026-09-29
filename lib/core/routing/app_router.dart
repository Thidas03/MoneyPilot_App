import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// Centralized GoRouter provider for MoneyPilot.
/// Uses the exact route paths, shell structure, and navigator keys from the reference architecture.
/// Feature screen builders use placeholder views during Phase 3 until feature screens are ported in Phase 4.
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    routes: [
      // Splash Screen
      GoRoute(
        path: '/splash',
        builder: (context, state) => const _RoutePlaceholder(title: 'Splash'),
      ),

      // Onboarding Walkthrough
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const _RoutePlaceholder(title: 'Onboarding'),
      ),

      // Auth Public Routes
      GoRoute(
        path: '/login',
        builder: (context, state) => const _RoutePlaceholder(title: 'Login'),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const _RoutePlaceholder(title: 'Register'),
      ),

      // Profile Detail Route (Full screen push on root navigator)
      GoRoute(
        path: '/profile',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const _RoutePlaceholder(title: 'Profile'),
      ),

      // Add Transaction Form (Full screen push on root navigator)
      GoRoute(
        path: '/transactions/add',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const _RoutePlaceholder(title: 'Add Transaction'),
      ),

      // Add Budget Form (Full screen push on root navigator)
      GoRoute(
        path: '/budgets/add',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const _RoutePlaceholder(title: 'Add Budget'),
      ),

      // Main Navigation Stateful Shell (Bottom Navigation Bar)
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return Scaffold(
            body: navigationShell,
            bottomNavigationBar: NavigationBar(
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: (index) => navigationShell.goBranch(index),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard),
                  label: 'Dashboard',
                ),
                NavigationDestination(
                  icon: Icon(Icons.receipt_long_outlined),
                  selectedIcon: Icon(Icons.receipt_long),
                  label: 'Transactions',
                ),
                NavigationDestination(
                  icon: Icon(Icons.pie_chart_outline),
                  selectedIcon: Icon(Icons.pie_chart),
                  label: 'Budgets',
                ),
                NavigationDestination(
                  icon: Icon(Icons.flag_outlined),
                  selectedIcon: Icon(Icons.flag),
                  label: 'Goals',
                ),
                NavigationDestination(
                  icon: Icon(Icons.bar_chart_outlined),
                  selectedIcon: Icon(Icons.bar_chart),
                  label: 'Reports',
                ),
              ],
            ),
          );
        },
        branches: [
          // Branch 0: Dashboard (Home)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dashboard',
                builder: (context, state) => const _RoutePlaceholder(title: 'Dashboard'),
              ),
            ],
          ),

          // Branch 1: Transactions
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/transactions',
                builder: (context, state) => const _RoutePlaceholder(title: 'Transactions'),
              ),
            ],
          ),

          // Branch 2: Budgets
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/budgets',
                builder: (context, state) => const _RoutePlaceholder(title: 'Budgets'),
              ),
            ],
          ),

          // Branch 3: Goals
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/goals',
                builder: (context, state) => const _RoutePlaceholder(title: 'Goals'),
              ),
            ],
          ),

          // Branch 4: Reports
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/reports',
                builder: (context, state) => const _RoutePlaceholder(title: 'Reports'),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

/// Temporary placeholder widget used prior to Phase 4 screen integration.
class _RoutePlaceholder extends StatelessWidget {
  const _RoutePlaceholder({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
    );
  }
}
