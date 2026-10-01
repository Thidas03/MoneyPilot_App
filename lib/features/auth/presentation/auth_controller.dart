import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/auth_repository.dart';

/// Formats technical authentication exceptions into friendly messages for pilots.
String formatAuthError(Object error) {
  if (error is AuthException) {
    final msg = error.message.toLowerCase();
    if (msg.contains('invalid login credentials') ||
        msg.contains('invalid_credentials') ||
        msg.contains('invalid grant')) {
      return 'Invalid email or password. Please check your credentials.';
    }
    if (msg.contains('user already registered') ||
        msg.contains('already exists') ||
        msg.contains('email address already taken')) {
      return 'An account with this email already exists. Try logging in instead.';
    }
    if (msg.contains('weak password') || msg.contains('password should be')) {
      return 'Password is too weak. Please choose a more secure password.';
    }
    if (msg.contains('rate limit') || msg.contains('too many requests')) {
      return 'Too many login attempts. Please wait a moment and try again.';
    }
    if (msg.contains('email not confirmed')) {
      return 'Please verify your email address before logging in.';
    }
    if (msg.contains('socketexception') ||
        msg.contains('failed host lookup') ||
        msg.contains('no address associated') ||
        msg.contains('clientexception')) {
      return 'Unable to reach the server. Please check your internet connection or restart the emulator.';
    }
    return error.message;
  }

  final errStr = error.toString().toLowerCase();
  if (error is SocketException ||
      errStr.contains('socketexception') ||
      errStr.contains('failed host lookup') ||
      errStr.contains('connection refused') ||
      errStr.contains('network is unreachable')) {
    return 'Unable to reach the server. Please check your internet connection.';
  }

  return 'An unexpected authentication error occurred. Please try again.';
}

/// Riverpod Notifier for managing authentication state and actions.
class AuthController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  AuthRepository get _authRepository => ref.read(authRepositoryProvider);

  /// Signs in with email and password.
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _authRepository.signIn(
        email: email,
        password: password,
      );
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(formatAuthError(e), st);
      return false;
    }
  }

  /// Registers a new user account.
  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _authRepository.signUp(
        email: email,
        password: password,
        fullName: fullName,
      );
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(formatAuthError(e), st);
      return false;
    }
  }

  /// Requests password reset email.
  Future<bool> resetPassword(String email) async {
    state = const AsyncValue.loading();
    try {
      await _authRepository.resetPassword(email);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(formatAuthError(e), st);
      return false;
    }
  }

  /// Signs out of current session.
  Future<void> signOut() async {
    state = const AsyncValue.loading();
    try {
      await _authRepository.signOut();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(formatAuthError(e), st);
    }
  }
}

/// Riverpod provider for [AuthController].
final authControllerProvider =
    NotifierProvider<AuthController, AsyncValue<void>>(() {
  return AuthController();
});
