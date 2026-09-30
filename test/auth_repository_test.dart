import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneypilot/core/storage/secure_storage.dart';
import 'package:moneypilot/features/auth/data/auth_repository.dart';
import 'package:moneypilot/features/auth/presentation/auth_controller.dart';
import 'package:moneypilot/features/profile/data/profile_repository.dart';
import 'package:moneypilot/features/profile/domain/user_profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SecureStorageService secureStorage;
  late SupabaseAuthRepository authRepository;
  late SupabaseProfileRepository profileRepository;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    secureStorage = SecureStorageService();
    authRepository = SupabaseAuthRepository(
      client: null, // Offline / test mock mode
      secureStorage: secureStorage,
    );
    profileRepository = SupabaseProfileRepository(
      client: null,
      authRepository: authRepository,
    );
  });

  group('SupabaseAuthRepository unit tests', () {
    test('Initial unauthenticated state', () {
      expect(authRepository.isAuthenticated, isFalse);
      expect(authRepository.getCurrentUser(), isNull);
      expect(authRepository.getCurrentSession(), isNull);
    });

    test('signUp creates user, session, stores token, and updates state', () async {
      final response = await authRepository.signUp(
        email: 'captain@moneypilot.com',
        password: 'securePassword123',
        fullName: 'Captain Kirk',
      );

      expect(response.user, isNotNull);
      expect(response.user?.email, equals('captain@moneypilot.com'));
      expect(response.user?.userMetadata?['full_name'], equals('Captain Kirk'));
      expect(response.session, isNotNull);
      expect(authRepository.isAuthenticated, isTrue);
      expect(await secureStorage.hasToken(), isTrue);
      expect(await secureStorage.getToken(), equals('mock-jwt-token-moneypilot'));
    });

    test('signIn authenticates, stores token, and emits signedIn state', () async {
      final authEvents = <AuthChangeEvent>[];
      final subscription = authRepository.authStateChanges().listen((state) {
        authEvents.add(state.event);
      });

      final response = await authRepository.signIn(
        email: 'pilot@moneypilot.com',
        password: 'password123',
      );

      expect(response.session, isNotNull);
      expect(authRepository.isAuthenticated, isTrue);
      expect(authRepository.getCurrentUser()?.email, equals('pilot@moneypilot.com'));
      expect(await secureStorage.hasToken(), isTrue);

      await Future.delayed(const Duration(milliseconds: 10));
      expect(authEvents.contains(AuthChangeEvent.signedIn), isTrue);

      await subscription.cancel();
    });

    test('signOut clears user, session, deletes token, and emits signedOut', () async {
      await authRepository.signIn(
        email: 'pilot@moneypilot.com',
        password: 'password123',
      );
      expect(authRepository.isAuthenticated, isTrue);

      final authEvents = <AuthChangeEvent>[];
      final subscription = authRepository.authStateChanges().listen((state) {
        authEvents.add(state.event);
      });

      await authRepository.signOut();

      expect(authRepository.isAuthenticated, isFalse);
      expect(authRepository.getCurrentUser(), isNull);
      expect(authRepository.getCurrentSession(), isNull);
      expect(await secureStorage.hasToken(), isFalse);

      await Future.delayed(const Duration(milliseconds: 10));
      expect(authEvents.contains(AuthChangeEvent.signedOut), isTrue);

      await subscription.cancel();
    });

    test('restoreMockSession recovers authenticated state from token', () async {
      expect(authRepository.isAuthenticated, isFalse);
      authRepository.restoreMockSession();
      expect(authRepository.isAuthenticated, isTrue);
      expect(authRepository.getCurrentUser(), isNotNull);
      expect(authRepository.getCurrentSession(), isNotNull);
    });

    test('resetPassword succeeds gracefully', () async {
      expect(
        () async => await authRepository.resetPassword('pilot@moneypilot.com'),
        returnsNormally,
      );
    });
  });

  group('SupabaseProfileRepository unit tests', () {
    test('getProfile returns UserProfile with matching ID in mock mode', () async {
      final profile = await profileRepository.getProfile('test-pilot-123');
      expect(profile, isNotNull);
      expect(profile?.id, equals('test-pilot-123'));
      expect(profile?.currencyCode, equals('LKR'));
      expect(profile?.currencySymbol, equals('Rs.'));
    });

    test('getCurrentUserProfile returns profile matching signed-in user', () async {
      await authRepository.signUp(
        email: 'officer@moneypilot.com',
        password: 'password123',
        fullName: 'First Officer Spock',
      );

      final profile = await profileRepository.getCurrentUserProfile();
      expect(profile, isNotNull);
      expect(profile?.email, equals('officer@moneypilot.com'));
      expect(profile?.fullName, equals('First Officer Spock'));
    });
  });

  group('formatAuthError unit tests', () {
    test('formats invalid login credentials into user-friendly message', () {
      const exception = AuthException('Invalid login credentials');
      expect(
        formatAuthError(exception),
        equals('Invalid email or password. Please check your credentials.'),
      );
    });

    test('formats existing user message', () {
      const exception = AuthException('User already registered');
      expect(
        formatAuthError(exception),
        equals('An account with this email already exists. Try logging in instead.'),
      );
    });

    test('formats weak password message', () {
      const exception = AuthException('Password should be at least 6 characters');
      expect(
        formatAuthError(exception),
        equals('Password is too weak. Please choose a more secure password.'),
      );
    });

    test('formats rate limit message', () {
      const exception = AuthException('Rate limit exceeded: too many requests');
      expect(
        formatAuthError(exception),
        equals('Too many login attempts. Please wait a moment and try again.'),
      );
    });

    test('formats network / socket exception message', () {
      const exception = SocketException('Failed host lookup');
      expect(
        formatAuthError(exception),
        equals('Unable to reach the server. Please check your internet connection.'),
      );
    });

    test('formats unexpected error fallback', () {
      final exception = Exception('Unknown internal error');
      expect(
        formatAuthError(exception),
        equals('An unexpected authentication error occurred. Please try again.'),
      );
    });
  });

  group('UserProfile model tests', () {
    test('JSON serialization roundtrip', () {
      final profile = UserProfile(
        id: 'usr-123',
        email: 'test@moneypilot.com',
        fullName: 'Jane Pilot',
        avatarUrl: 'https://example.com/avatar.png',
        currencyCode: 'USD',
        currencySymbol: '\$',
        flightBadge: 'Senior Captain',
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 2),
      );

      final json = profile.toJson();
      final reconstructed = UserProfile.fromJson(json);

      expect(reconstructed.id, equals('usr-123'));
      expect(reconstructed.email, equals('test@moneypilot.com'));
      expect(reconstructed.fullName, equals('Jane Pilot'));
      expect(reconstructed.avatarUrl, equals('https://example.com/avatar.png'));
      expect(reconstructed.currencyCode, equals('USD'));
      expect(reconstructed.currencySymbol, equals('\$'));
      expect(reconstructed.flightBadge, equals('Senior Captain'));
    });
  });
}
