import 'package:flutter/foundation.dart';

/// Centralized API endpoint configuration for MoneyPilot.
/// The default baseUrl points to the local backend on port 5000.
/// Android emulators use `http://10.0.2.2:5000`, while web/desktop uses `http://127.0.0.1:5000`.
class ApiEndpoints {
  ApiEndpoints._();

  /// Default base URL dynamically resolved by platform.
  /// Can be overridden at runtime via [overrideBaseUrl].
  static String? _customBaseUrl;

  static String get baseUrl {
    if (_customBaseUrl != null && _customBaseUrl!.isNotEmpty) {
      return _customBaseUrl!;
    }
    if (kIsWeb) {
      return 'http://127.0.0.1:5000';
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        // Android emulator loopback alias
        return 'http://10.0.2.2:5000';
      case TargetPlatform.iOS:
      case TargetPlatform.windows:
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
      default:
        return 'http://127.0.0.1:5000';
    }
  }

  static void setBaseUrl(String newBaseUrl) {
    _customBaseUrl = newBaseUrl;
  }

  // --- Authentication ---
  static const String register = '/api/auth/register';
  static const String login = '/api/auth/login';
  static const String me = '/api/auth/me';

  // --- Transactions ---
  static const String transactions = '/api/transactions';
  static const String transactionStats = '/api/transactions/stats';
  static String transaction(String id) => '/api/transactions/$id';

  // --- Budgets ---
  static const String budgets = '/api/budgets';
  static String budget(String id) => '/api/budgets/$id';

  // --- Goals ---
  static const String goals = '/api/goals';
  static String goal(String id) => '/api/goals/$id';

  // --- Health Score ---
  static const String healthScore = '/api/health-score';

  // --- Reports ---
  static const String reports = '/api/reports';
}
