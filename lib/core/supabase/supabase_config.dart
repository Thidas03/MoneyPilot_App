import 'package:flutter/foundation.dart';

/// Centralized configuration for Supabase client connection.
/// Reads credentials passed via `--dart-define` or `--dart-define-from-file=.env`.
class SupabaseConfig {
  SupabaseConfig._();

  static const String _envUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  static const String _envAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  static String? _customUrl;
  static String? _customAnonKey;

  /// Supabase project URL (e.g. `https://xyzcompany.supabase.co`).
  static String get url => _customUrl ?? _envUrl;

  /// Supabase client publishable/anon key.
  static String get anonKey => _customAnonKey ?? _envAnonKey;

  /// Alias for [anonKey] matching the latest Supabase SDK conventions.
  static String get publishableKey => anonKey;

  /// Returns true only if valid non-placeholder credentials are provided.
  static bool get isConfigured {
    final trimmedUrl = url.trim();
    final trimmedKey = anonKey.trim();
    return trimmedUrl.isNotEmpty &&
        trimmedKey.isNotEmpty &&
        !trimmedUrl.contains('your-project-id') &&
        !trimmedKey.contains('your-anon-publishable-key');
  }

  /// Programmatically set credentials (e.g., for test environments or runtime overrides).
  static void setCredentials({required String url, required String anonKey}) {
    _customUrl = url;
    _customAnonKey = anonKey;
  }

  /// Clears any programmatically set credentials.
  static void reset() {
    _customUrl = null;
    _customAnonKey = null;
  }

  /// Safe masked representation for logging.
  static String get maskedAnonKey {
    if (anonKey.isEmpty) return '(empty)';
    if (anonKey.length <= 10) return '***';
    return '${anonKey.substring(0, 6)}...${anonKey.substring(anonKey.length - 4)}';
  }

  /// Prints sanitized configuration summary to debug console.
  static void debugPrintConfig() {
    if (kDebugMode) {
      debugPrint('[SupabaseConfig] Configured: $isConfigured');
      debugPrint('[SupabaseConfig] URL: ${url.isEmpty ? "(not set)" : url}');
      debugPrint('[SupabaseConfig] AnonKey: $maskedAnonKey');
    }
  }
}
