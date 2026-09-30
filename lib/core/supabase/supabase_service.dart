import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_config.dart';

/// Service responsible for managing the Supabase client connection lifecycle.
class SupabaseService {
  SupabaseService._();
  static final SupabaseService instance = SupabaseService._();

  bool _isInitialized = false;

  /// Whether Supabase was successfully initialized with a live client.
  bool get isInitialized => _isInitialized;

  /// Returns the underlying [SupabaseClient], or null if not yet initialized.
  SupabaseClient? get client {
    if (!_isInitialized) return null;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  /// Initializes Supabase if credentials are provided in [SupabaseConfig].
  /// In offline/test environments, gracefully completes without throwing.
  Future<void> initialize() async {
    if (_isInitialized) return;

    if (!SupabaseConfig.isConfigured) {
      if (kDebugMode) {
        debugPrint(
          '[SupabaseService] No live Supabase credentials detected. '
          'Application will run using in-memory/mock data providers.',
        );
      }
      return;
    }

    try {
      await Supabase.initialize(
        url: SupabaseConfig.url,
        // ignore: deprecated_member_use
        anonKey: SupabaseConfig.publishableKey,
        debug: kDebugMode,
      );
      _isInitialized = true;
      if (kDebugMode) {
        debugPrint(
          '[SupabaseService] Supabase client initialized successfully '
          'for URL: ${SupabaseConfig.url}',
        );
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('[SupabaseService] Error initializing Supabase: $e');
        debugPrint(stackTrace.toString());
      }
      // Do not crash the app so mock UI continues working
      _isInitialized = false;
    }
  }

  /// Resets initialization state (useful in test teardown).
  @visibleForTesting
  void resetForTesting() {
    _isInitialized = false;
  }
}

/// Riverpod provider exposing whether live Supabase is active.
final isSupabaseActiveProvider = Provider<bool>((ref) {
  return SupabaseService.instance.isInitialized;
});

/// Riverpod provider for injecting the [SupabaseClient] throughout features.
final supabaseClientProvider = Provider<SupabaseClient?>((ref) {
  return SupabaseService.instance.client;
});
