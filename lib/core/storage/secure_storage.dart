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

  static const String _goalsCachePrefix = 'moneypilot_cached_goals_';
  static const String _profileCachePrefix = 'moneypilot_cached_profile_';

  /// Save goals cache for a user.
  Future<void> saveGoalsCache(String userId, String jsonString) async {
    await _storage.write(key: '$_goalsCachePrefix$userId', value: jsonString);
  }

  /// Retrieve goals cache for a user.
  Future<String?> getGoalsCache(String userId) async {
    return await _storage.read(key: '$_goalsCachePrefix$userId');
  }

  /// Delete goals cache for a user.
  Future<void> clearGoalsCache(String userId) async {
    await _storage.delete(key: '$_goalsCachePrefix$userId');
  }

  static const String _remindersCachePrefix = 'moneypilot_cached_reminders_';

  /// Save profile cache for a user.
  Future<void> saveUserProfileCache(String userId, String jsonString) async {
    await _storage.write(key: '$_profileCachePrefix$userId', value: jsonString);
  }

  /// Retrieve profile cache for a user.
  Future<String?> getUserProfileCache(String userId) async {
    return await _storage.read(key: '$_profileCachePrefix$userId');
  }

  /// Delete profile cache for a user.
  Future<void> clearUserProfileCache(String userId) async {
    await _storage.delete(key: '$_profileCachePrefix$userId');
  }

  /// Save reminders cache for a user.
  Future<void> saveRemindersCache(String userId, String jsonString) async {
    await _storage.write(key: '$_remindersCachePrefix$userId', value: jsonString);
  }

  /// Retrieve reminders cache for a user.
  Future<String?> getRemindersCache(String userId) async {
    return await _storage.read(key: '$_remindersCachePrefix$userId');
  }

  /// Delete reminders cache for a user.
  Future<void> clearRemindersCache(String userId) async {
    await _storage.delete(key: '$_remindersCachePrefix$userId');
  }
}

/// Riverpod provider for [SecureStorageService].
final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});
