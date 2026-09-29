import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure token persistence service using platform-native keychain / keystore.
class SecureStorageService {
  SecureStorageService([FlutterSecureStorage? storage])
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(),
              iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
            );

  final FlutterSecureStorage _storage;
  static const String _tokenKey = 'moneypilot_jwt_token';
  static const String _onboardingKey = 'moneypilot_has_seen_onboarding';

  /// Save JWT authentication token.
  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  /// Retrieve the stored JWT token. Returns null if not found.
  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  /// Delete the stored JWT token on logout or authorization failure.
  Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }

  /// Check whether a valid token exists in storage.
  Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// Check whether the user has already completed the onboarding flow.
  Future<bool> hasSeenOnboarding() async {
    final value = await _storage.read(key: _onboardingKey);
    return value == 'true';
  }

  /// Mark onboarding flow as completed.
  Future<void> completeOnboarding() async {
    await _storage.write(key: _onboardingKey, value: 'true');
  }

  /// Reset onboarding state (useful for replaying or testing).
  Future<void> resetOnboarding() async {
    await _storage.delete(key: _onboardingKey);
  }
}

/// Riverpod provider for [SecureStorageService].
final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});
