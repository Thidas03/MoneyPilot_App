import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_service.dart';
import '../../auth/data/auth_repository.dart';
import '../domain/user_profile.dart';

/// Contract for accessing user profile records in public.profiles.
abstract class ProfileRepository {
  /// Fetches a profile by user UUID.
  Future<UserProfile?> getProfile(String userId);

  /// Fetches the profile of the currently signed-in user.
  Future<UserProfile?> getCurrentUserProfile();
}

/// Unified profile repository utilizing Supabase PostgreSQL table public.profiles
/// when available, falling back to mock profile data in offline/test environments.
class SupabaseProfileRepository implements ProfileRepository {
  SupabaseProfileRepository({
    this.client,
    required this.authRepository,
  });

  final SupabaseClient? client;
  final AuthRepository authRepository;

  SupabaseClient? get _client => client;
  AuthRepository get _authRepository => authRepository;

  bool get isLiveSupabase => _client != null;

  @override
  Future<UserProfile?> getProfile(String userId) async {
    if (!isLiveSupabase) {
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
    if (user == null) return null;

    if (!isLiveSupabase) {
      final metaName = user.userMetadata?['full_name'] as String?;
      return UserProfile.mock.copyWith(
        id: user.id,
        email: user.email ?? UserProfile.mock.email,
        fullName: (metaName != null && metaName.isNotEmpty) ? metaName : UserProfile.mock.fullName,
      );
    }

    return await getProfile(user.id);
  }
}

/// Riverpod provider for [ProfileRepository].
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final authRepository = ref.watch(authRepositoryProvider);
  return SupabaseProfileRepository(
    client: client,
    authRepository: authRepository,
  );
});

/// FutureProvider supplying the current user's profile.
final currentUserProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final repository = ref.watch(profileRepositoryProvider);
  // Re-fetch whenever auth state changes
  ref.watch(authStateChangesProvider);
  return await repository.getCurrentUserProfile();
});
