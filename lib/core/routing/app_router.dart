import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/navigation/presentation/main_navigation_shell.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/transactions/domain/transaction_model.dart';
import '../../features/transactions/presentation/add_transaction_screen.dart';
import '../../features/transactions/presentation/transactions_screen.dart';
import '../../features/budgets/domain/budget_model.dart';
import '../../features/budgets/presentation/add_budget_screen.dart';
import '../../features/budgets/presentation/budgets_screen.dart';
import '../../features/goals/domain/goal_model.dart';
import '../../features/goals/presentation/add_goal_screen.dart';
import '../../features/goals/presentation/goal_detail_screen.dart';

import '../../features/goals/presentation/goals_screen.dart';
import '../../features/reminders/data/models/reminder_model.dart';
import '../../features/reminders/presentation/add_reminder_screen.dart';
import '../../features/reminders/presentation/reminders_screen.dart';
import '../../features/reports/presentation/reports_screen.dart';


/// Helper ChangeNotifier that notifies GoRouter on authentication stream events.
class _GoRouterRefreshStream extends ChangeNotifier {
  _GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

/// Centralized GoRouter provider for MoneyPilot.
/// Uses the exact route paths, shell structure, and navigator keys from the reference architecture.
final appRouterProvider = Provider<GoRouter>((ref) {
  final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'rootNav');
  final authRepository = ref.watch(authRepositoryProvider);

  final refreshStream = _GoRouterRefreshStream(authRepository.authStateChanges());
  ref.onDispose(refreshStream.dispose);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: refreshStream,
    redirect: (context, state) {
      final location = state.uri.path;

      // Allow splash and onboarding to proceed based on their internal timers & state
      if (location == '/splash' || location == '/onboarding') {
        return null;
      }

      final isAuthenticated = authRepository.isAuthenticated;
      final isAuthRoute = location == '/login' ||
          location == '/register' ||
          location == '/forgot-password';

      // Unauthenticated users attempting to access authenticated areas
      if (!isAuthenticated && !isAuthRoute) {
        return '/login';
      }

      // Authenticated users attempting to visit login/register
      if (isAuthenticated && (location == '/login' || location == '/register')) {
        return '/dashboard';
      }

      return null;
    },
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
        builder: (context, state) {
          final tx = state.extra as Transaction?;
          return AddTransactionScreen(existingTransaction: tx);
        },
      ),

      // Add Budget Form (Full screen push on root navigator)
      GoRoute(
        path: '/budgets/add',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return AddBudgetScreen(
            existingBudget: extra?['existingBudget'] as Budget?,
            initialCategory: extra?['category'] as String?,
            initialAmount: extra?['amount'] as double?,
            isOverallInitial: extra?['isOverall'] as bool? ?? false,
          );
        },
      ),

      // Add Goal Form (Full screen push on root navigator)
      GoRoute(
        path: '/goals/add',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final goal = state.extra as Goal?;
          return AddGoalScreen(existingGoal: goal);
        },
      ),

      // Goal Detail Screen (Full screen push on root navigator)
      GoRoute(
        path: '/goals/detail',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final queryId = state.uri.queryParameters['id'];
          final extraId = state.extra is String
              ? state.extra as String
              : (state.extra as Goal?)?.id;
          final goalId = queryId ?? extraId ?? '';
          return GoalDetailScreen(goalId: goalId);
        },
      ),
      GoRoute(
        path: '/goals/detail/:id',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final idParam = state.pathParameters['id'] ?? '';
          return GoalDetailScreen(goalId: idParam);
        },
      ),

      // Reminders list screen
      GoRoute(
        path: '/reminders',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const RemindersScreen(),
      ),

      // Add/Edit Reminder screen
      GoRoute(
        path: '/reminders/add',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final reminder = state.extra as Reminder?;
          return AddReminderScreen(existingReminder: reminder);
        },
      ),
      GoRoute(
        path: '/reminders/edit',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final reminder = state.extra as Reminder?;
          return AddReminderScreen(existingReminder: reminder);
        },
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
                builder: (context, state) => const TransactionsScreen(),
              ),
            ],
          ),

          // Branch 2: Budgets
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/budgets',
                builder: (context, state) => const BudgetsScreen(),
              ),
            ],
          ),

          // Branch 3: Goals
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/goals',
                builder: (context, state) => const GoalsScreen(),
              ),
            ],
          ),

          // Branch 4: Reports
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/reports',
                builder: (context, state) => const ReportsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

/// Reusable temporary placeholder widget used prior to full screen integration.
// ignore: unused_element
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
