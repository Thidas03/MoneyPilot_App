import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/navigation/presentation/main_navigation_shell.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';

/// Centralized GoRouter provider for MoneyPilot.
/// Uses the exact route paths, shell structure, and navigator keys from the reference architecture.
final appRouterProvider = Provider<GoRouter>((ref) {
  final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'rootNav');

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/splash',
    routes: [
      // Splash Screen
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // Onboarding Walkthrough
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),

      // Auth Public Routes
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      // Profile Detail Route (Full screen push on root navigator)
      GoRoute(
        path: '/profile',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const ProfileScreen(),
      ),

      // Add Transaction Form (Full screen push on root navigator)
      GoRoute(
        path: '/transactions/add',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const _RoutePlaceholder(title: 'Add Transaction'),
      ),

      // Add Budget Form (Full screen push on root navigator)
      GoRoute(
        path: '/budgets/add',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const _RoutePlaceholder(title: 'Add Budget'),
      ),

      // Main Navigation Stateful Shell (Bottom Navigation Bar)
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainNavigationShell(navigationShell: navigationShell);
        },
        branches: [
          // Branch 0: Dashboard (Home)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dashboard',
                builder: (context, state) => const DashboardScreen(),
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

/// Reusable temporary placeholder widget used prior to full screen integration.
class _RoutePlaceholder extends StatelessWidget {
  const _RoutePlaceholder({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MoneyPilot')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'MoneyPilot',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                '$title coming soon',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
