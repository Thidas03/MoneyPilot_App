import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/storage/secure_storage.dart';
import '../../../core/supabase/supabase_service.dart';

/// Contract defining authentication operations for MoneyPilot.
abstract class AuthRepository {
  /// Signs up a new user with email, password, and metadata (full_name).
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
  });

  /// Signs in an existing user with email and password.
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  });

  /// Signs out the currently authenticated user.
  Future<void> signOut();

  /// Requests a password reset email for [email].
  Future<void> resetPassword(String email);

  /// Returns the current authenticated [User] or null if not signed in.
  User? getCurrentUser();

  /// Returns the current active [Session] or null if unauthenticated.
  Session? getCurrentSession();

  /// Stream of authentication state changes.
  Stream<AuthState> authStateChanges();

  /// Returns whether a user session is actively authenticated.
  bool get isAuthenticated;
}

/// Unified authentication repository that uses live Supabase Auth when available,
/// and falls back to a clean in-memory mock implementation in offline/test environments.
class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository({
    this.client,
    required this.secureStorage,
  }) {
    final liveClient = client;
    if (liveClient != null) {
      liveClient.auth.onAuthStateChange.listen((data) async {
        final session = data.session;
        if (session != null) {
          await secureStorage.saveToken(session.accessToken);
        } else if (data.event == AuthChangeEvent.signedOut) {
          await secureStorage.deleteToken();
        }
      });
    }
  }

  final SupabaseClient? client;
  final SecureStorageService secureStorage;

  SupabaseClient? get _client => client;
  SecureStorageService get _secureStorage => secureStorage;

  // In-memory mock session state when Supabase is not active
  User? _mockUser;
  Session? _mockSession;
  final StreamController<AuthState> _mockAuthStateController =
      StreamController<AuthState>.broadcast();

  bool get isLiveSupabase => _client != null;

  @override
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    if (isLiveSupabase) {
      final response = await _client!.auth.signUp(
        email: email.trim(),
        password: password,
        data: {'full_name': fullName.trim()},
      );
      if (response.session != null) {
        await _secureStorage.saveToken(response.session!.accessToken);
      }
      return response;
    }

    // Mock fallback: create mock user & session
    final mockUserJson = {
      'id': 'mock-pilot-001',
      'app_metadata': {'provider': 'email'},
      'user_metadata': {'full_name': fullName.trim()},
      'aud': 'authenticated',
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'email': email.trim(),
    };
    final user = User.fromJson(mockUserJson);
    final session = Session.fromJson({
      'access_token': 'mock-jwt-token-moneypilot',
      'token_type': 'bearer',
      'user': mockUserJson,
    });

    _mockUser = user;
    _mockSession = session;
    await _secureStorage.saveToken('mock-jwt-token-moneypilot');
    if (session != null) {
      _mockAuthStateController.add(AuthState(AuthChangeEvent.signedIn, session));
    }

    return AuthResponse(session: session, user: user);
  }

  @override
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    if (isLiveSupabase) {
      final response = await _client!.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      if (response.session != null) {
        await _secureStorage.saveToken(response.session!.accessToken);
      }
      return response;
    }

    // Mock fallback
    final mockUserJson = {
      'id': 'mock-pilot-001',
      'app_metadata': {'provider': 'email'},
      'user_metadata': {'full_name': 'Chief Pilot'},
      'aud': 'authenticated',
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'email': email.trim(),
    };
    final user = User.fromJson(mockUserJson);
    final session = Session.fromJson({
      'access_token': 'mock-jwt-token-moneypilot',
      'token_type': 'bearer',
      'user': mockUserJson,
    });

    _mockUser = user;
    _mockSession = session;
    await _secureStorage.saveToken('mock-jwt-token-moneypilot');
    if (session != null) {
      _mockAuthStateController.add(AuthState(AuthChangeEvent.signedIn, session));
    }

    return AuthResponse(session: session, user: user);
  }

  @override
  Future<void> signOut() async {
    if (isLiveSupabase) {
      await _client!.auth.signOut();
    } else {
      _mockUser = null;
      _mockSession = null;
      _mockAuthStateController.add(const AuthState(AuthChangeEvent.signedOut, null));
    }
    await _secureStorage.deleteToken();
  }

  @override
  Future<void> resetPassword(String email) async {
    if (isLiveSupabase) {
      await _client!.auth.resetPasswordForEmail(email.trim());
    } else {
      // Mock fallback: simulate network latency
      await Future.delayed(const Duration(milliseconds: 200));
    }
  }

  @override
  User? getCurrentUser() {
    if (isLiveSupabase) {
      return _client!.auth.currentUser;
    }
    return _mockUser;
  }

  @override
  Session? getCurrentSession() {
    if (isLiveSupabase) {
      return _client!.auth.currentSession;
    }
    return _mockSession;
  }

  @override
  Stream<AuthState> authStateChanges() {
    if (isLiveSupabase) {
      return _client!.auth.onAuthStateChange;
    }
    return _mockAuthStateController.stream;
  }

  @override
  bool get isAuthenticated {
    if (isLiveSupabase) {
      return _client!.auth.currentSession != null;
    }
    return _mockSession != null;
  }

  /// Restores a mock session when a token is detected in local storage.
  void restoreMockSession() {
    if (_client != null) return;
    final mockUserJson = {
      'id': 'mock-pilot-001',
      'app_metadata': {'provider': 'email'},
      'user_metadata': {'full_name': 'Chief Pilot'},
      'aud': 'authenticated',
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'email': 'pilot@moneypilot.com',
    };
    _mockUser = User.fromJson(mockUserJson);
    _mockSession = Session.fromJson({
      'access_token': 'mock-jwt-token-moneypilot',
      'token_type': 'bearer',
      'user': mockUserJson,
    });
    _mockAuthStateController.add(AuthState(AuthChangeEvent.signedIn, _mockSession));
  }

  @visibleForTesting
  void setMockSessionForTesting({User? user, Session? session}) {
    _mockUser = user;
    _mockSession = session;
    if (session != null) {
      _mockAuthStateController.add(AuthState(AuthChangeEvent.signedIn, session));
    } else {
      _mockAuthStateController.add(const AuthState(AuthChangeEvent.signedOut, null));
    }
  }
}

/// Provider for [AuthRepository].
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final secureStorage = ref.watch(secureStorageProvider);
  return SupabaseAuthRepository(
    client: client,
    secureStorage: secureStorage,
  );
});

/// Stream provider for listening to live auth state changes.
final authStateChangesProvider = StreamProvider<AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return repository.authStateChanges();
});

/// Provider for currently authenticated user.
final currentUserProvider = Provider<User?>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  ref.watch(authStateChangesProvider);
  return repository.getCurrentUser();
});

/// Provider for authentication status boolean.
final isAuthenticatedProvider = Provider<bool>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  ref.watch(authStateChangesProvider);
  return repository.isAuthenticated;
});
