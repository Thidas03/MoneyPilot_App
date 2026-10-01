import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/storage/secure_storage.dart';
import '../../../core/supabase/supabase_service.dart';
import '../../auth/data/auth_repository.dart';
import '../domain/user_profile.dart';

/// Contract for accessing and updating user profile records in public.profiles.
abstract class ProfileRepository {
  /// Fetches a profile by user UUID.
  Future<UserProfile?> getProfile(String userId);

  /// Fetches the profile of the currently signed-in user.
  Future<UserProfile?> getCurrentUserProfile();

  /// Updates profile details such as full name and currency preferences.
  Future<UserProfile> updateProfile({
    required String userId,
    required String fullName,
    String? email,
    String? avatarUrl,
    String? currencyCode,
    String? currencySymbol,
  });
}

/// Unified profile repository utilizing Supabase PostgreSQL table public.profiles
/// when available, falling back to mock profile data in offline/test environments.
class SupabaseProfileRepository implements ProfileRepository {
  SupabaseProfileRepository({
    this.client,
    required this.authRepository,
    SecureStorageService? secureStorage,
  }) : secureStorage = secureStorage ?? SecureStorageService();

  final SupabaseClient? client;
  final AuthRepository authRepository;
  final SecureStorageService secureStorage;

  SupabaseClient? get _client => client;
  AuthRepository get _authRepository => authRepository;

  bool get isLiveSupabase => _client != null;

  UserProfile? _cachedProfile;

  @override
  Future<UserProfile?> getProfile(String userId) async {
    if (!isLiveSupabase) {
      if (_cachedProfile != null && _cachedProfile!.id == userId) {
        return _cachedProfile;
      }
      return UserProfile.mock.copyWith(id: userId);
    }

    try {
      final response = await _client!
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response == null) return null;
      return UserProfile.fromJson(response);
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('[ProfileRepository] Failed to fetch profile for $userId: $e');
        debugPrint(stackTrace.toString());
      }
      return null;
    }
  }

  @override
  Future<UserProfile?> getCurrentUserProfile() async {
    final user = _authRepository.getCurrentUser();
    if (user == null) {
      _cachedProfile = null;
      return null;
    }

    // Check secure storage cache for instant offline restore
    final cachedJson = await secureStorage.getUserProfileCache(user.id);
    if (cachedJson != null && cachedJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(cachedJson) as Map<String, dynamic>;
        _cachedProfile = UserProfile.fromJson(decoded);
      } catch (_) {}
    }

    if (!isLiveSupabase) {
      final metaName = (user.userMetadata?['full_name'] as String?)?.trim();
      final resolvedName = (metaName != null && metaName.isNotEmpty)
          ? metaName
          : (_cachedProfile?.fullName.isNotEmpty == true
              ? _cachedProfile!.fullName
              : (user.email?.split('@').first ?? 'User'));

      final fallback = (_cachedProfile ?? UserProfile.mock).copyWith(
        id: user.id,
        email: user.email ?? (_cachedProfile?.email ?? 'user@moneypilot.com'),
        fullName: resolvedName,
        flightBadge: 'Active Member',
      );
      _cachedProfile = fallback;
      await secureStorage.saveUserProfileCache(user.id, jsonEncode(fallback.toJson()));
      return fallback;
    }

    // Live Supabase query
    try {
      final profile = await getProfile(user.id);
      if (profile != null) {
        final metaName = (user.userMetadata?['full_name'] as String?)?.trim();
        final finalName = profile.fullName.isNotEmpty
            ? profile.fullName
            : (metaName ?? user.email?.split('@').first ?? 'User');
        final finalEmail = profile.email.isNotEmpty ? profile.email : (user.email ?? '');

        final resolved = profile.copyWith(
          fullName: finalName,
          email: finalEmail,
        );
        _cachedProfile = resolved;
        await secureStorage.saveUserProfileCache(user.id, jsonEncode(resolved.toJson()));
        return resolved;
      }

      // Profile record does not exist yet on Supabase — auto-provision from auth metadata
      final metaName = (user.userMetadata?['full_name'] as String?)?.trim();
      final defaultName = (metaName != null && metaName.isNotEmpty)
          ? metaName
          : (user.email?.split('@').first ?? 'User');

      final newProfile = UserProfile(
        id: user.id,
        email: user.email ?? '',
        fullName: defaultName,
        currencyCode: 'LKR',
        currencySymbol: 'Rs.',
        flightBadge: 'Active Member',
        createdAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
      );

      try {
        await _client!.from('profiles').upsert(newProfile.toJson());
      } catch (upsertError) {
        if (kDebugMode) {
          debugPrint('[ProfileRepository] Auto-provision profile error: $upsertError');
        }
      }

      _cachedProfile = newProfile;
      await secureStorage.saveUserProfileCache(user.id, jsonEncode(newProfile.toJson()));
      return newProfile;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ProfileRepository] Error getting current user profile: $e');
      }
      return _cachedProfile;
    }
  }

  @override
  Future<UserProfile> updateProfile({
    required String userId,
    required String fullName,
    String? email,
    String? avatarUrl,
    String? currencyCode,
    String? currencySymbol,
  }) async {
    final current = await getCurrentUserProfile() ?? UserProfile.mock;
    final updated = current.copyWith(
      id: userId,
      fullName: fullName.trim(),
      email: (email != null && email.isNotEmpty) ? email.trim() : current.email,
      avatarUrl: avatarUrl ?? current.avatarUrl,
      currencyCode: currencyCode ?? current.currencyCode,
      currencySymbol: currencySymbol ?? current.currencySymbol,
      updatedAt: DateTime.now().toUtc(),
    );

    if (isLiveSupabase && _client != null) {
      final payload = <String, dynamic>{
        'id': userId,
        'full_name': fullName.trim(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
        if (email != null && email.isNotEmpty) 'email': email.trim(),
        if (avatarUrl != null && avatarUrl.isNotEmpty) 'avatar_url': avatarUrl,
        if (currencyCode != null && currencyCode.isNotEmpty) 'currency_code': currencyCode,
        if (currencySymbol != null && currencySymbol.isNotEmpty) 'currency_symbol': currencySymbol,
      };

      try {
        await _client!.from('profiles').upsert(payload);
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[ProfileRepository] Failed to upsert profile in Supabase: $e');
        }
      }

      try {
        await _client!.auth.updateUser(
          UserAttributes(data: {'full_name': fullName.trim()}),
        );
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[ProfileRepository] Failed to update user metadata in Auth: $e');
        }
      }
    }

    _cachedProfile = updated;
    await secureStorage.saveUserProfileCache(userId, jsonEncode(updated.toJson()));
    return updated;
  }
}

/// Riverpod provider for [ProfileRepository].
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final authRepository = ref.watch(authRepositoryProvider);
  final secureStorage = ref.watch(secureStorageProvider);
  return SupabaseProfileRepository(
    client: client,
    authRepository: authRepository,
    secureStorage: secureStorage,
  );
});

/// Riverpod Notifier for reactive profile state and updates.
class ProfileNotifier extends AsyncNotifier<UserProfile?> {
  @override
  Future<UserProfile?> build() async {
    ref.watch(authStateChangesProvider);
    ref.watch(currentUserProvider);
    final repository = ref.watch(profileRepositoryProvider);
    return await repository.getCurrentUserProfile();
  }

  /// Updates profile details in Supabase and local cache.
  Future<bool> updateProfile({
    required String fullName,
    String? currencyCode,
    String? currencySymbol,
  }) async {
    try {
      final repository = ref.read(profileRepositoryProvider);
      final authUser = ref.read(currentUserProvider);
      final current = state.value;
      final userId = authUser?.id ?? current?.id ?? 'mock-user-001';

      final updated = await repository.updateProfile(
        userId: userId,
        fullName: fullName,
        currencyCode: currencyCode,
        currencySymbol: currencySymbol,
      );
      state = AsyncData(updated);
      return true;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[ProfileNotifier] Update failed: $e');
      }
      state = AsyncError(e, st);
      return false;
    }
  }

  void refresh() {
    ref.invalidateSelf();
  }
}

/// Riverpod notifier provider managing reactive [UserProfile].
final profileNotifierProvider =
    AsyncNotifierProvider<ProfileNotifier, UserProfile?>(() {
  return ProfileNotifier();
});

/// Backward-compatible provider supplying the current user's profile.
final currentUserProfileProvider = Provider<AsyncValue<UserProfile?>>((ref) {
  return ref.watch(profileNotifierProvider);
});
